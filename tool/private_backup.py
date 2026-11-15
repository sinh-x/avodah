#!/usr/bin/env python3
"""Explicit-path private recovery. No scheduling, network, or live overwrite.

The operator must quiesce config/identity writers for backup. SQLite backup API
provides the consistent database snapshot, including paired-device material.
"""
import argparse
from contextlib import closing
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import stat
import tempfile

CONFIG = {'config.json', 'config.toml', 'node-id', 'jira-credentials.json'}
REQUIRED = {'avodah.db', 'node-id', 'manifest.json'}


def private_dir(path):
    if path.is_symlink():
        raise ValueError('symlink directory rejected')
    path.mkdir(mode=0o700, parents=False, exist_ok=True)
    if path.stat().st_mode & 0o077 or path.stat().st_uid != os.geteuid():
        raise ValueError('destination must already be private and owned by this operator')


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for data in iter(lambda: f.read(1024 * 1024), b''):
            h.update(data)
    return h.hexdigest()


def check_db(path):
    with closing(sqlite3.connect(path.resolve().as_uri() + '?mode=ro&immutable=1', uri=True)) as db:
        if db.execute('PRAGMA quick_check').fetchall() != [('ok',)]:
            raise ValueError('integrity failure')
        return db.execute('PRAGMA user_version').fetchone()[0]


def verify(generation):
    if generation.is_symlink():
        raise ValueError('symlink rejected')
    if generation.stat().st_mode & 0o077 or generation.stat().st_uid != os.geteuid():
        raise ValueError('generation directory must be private')
    manifest_path = generation / 'manifest.json'
    if manifest_path.is_symlink() or manifest_path.stat().st_mode & 0o077:
        raise ValueError('manifest must be private and not a symlink')
    manifest = json.loads(manifest_path.read_text())
    files = manifest['files']
    if manifest['format'] != 1 or not REQUIRED.issubset(set(files) | {'manifest.json'}):
        raise ValueError('incomplete recovery set')
    if not set(files).issubset(CONFIG | {'avodah.db'}):
        raise ValueError('unexpected recovery member')
    if {p.name for p in generation.iterdir()} != set(files) | {'manifest.json'}:
        raise ValueError('unexpected inventory')
    for name, expected in files.items():
        p = generation / name
        if p.is_symlink() or not p.is_file() or p.stat().st_mode & 0o077 or digest(p) != expected:
            raise ValueError('invalid private recovery member')
    if not (generation / 'node-id').read_bytes().strip():
        raise ValueError('missing node identity')
    if check_db(generation / 'avodah.db') != manifest['schema']:
        raise ValueError('schema mismatch')
    return manifest


def backup(data, config, destination, revision, quiesced=False, apply_retention=False):
    if not quiesced:
        raise ValueError('config/identity writers must be quiesced explicitly')
    paths = tuple(map(Path, (data, config, destination)))
    if any(p.is_symlink() for p in paths):
        raise ValueError('symlink source/destination directory rejected')
    data, config, destination = (p.resolve() for p in paths)
    if destination.is_relative_to(data) or destination.is_relative_to(config):
        raise ValueError('backup destination must be outside source storage')
    private_dir(destination)
    fd = os.open(destination / '.backup.lock', os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'r+') as lock:
        metadata = os.fstat(lock.fileno())
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_mode & 0o077 or metadata.st_uid != os.geteuid():
            raise ValueError('invalid private backup lock')
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        stage = Path(tempfile.mkdtemp(prefix='.pending-', dir=destination))
        try:
            source = data / 'avodah.db'
            if source.is_symlink() or not source.is_file():
                raise ValueError('source database unavailable')
            with closing(sqlite3.connect(source.as_uri() + '?mode=ro', uri=True)) as src:
                with closing(sqlite3.connect(stage / 'avodah.db')) as target:
                    src.backup(target)
                    target.execute('PRAGMA journal_mode=DELETE')
            os.chmod(stage / 'avodah.db', 0o600)
            for name in CONFIG:
                path = config / name
                if path.is_symlink():
                    raise ValueError('symlink config rejected')
                if not path.exists():
                    continue
                before = (path.stat().st_mtime_ns, path.stat().st_size)
                shutil.copyfile(path, stage / name)
                os.chmod(stage / name, 0o600)
                if before != (path.stat().st_mtime_ns, path.stat().st_size):
                    raise ValueError('configuration changed during snapshot')
            manifest = {'format': 1, 'source_revision': revision,
                        'created': dt.datetime.now(dt.timezone.utc).isoformat(),
                        'schema': check_db(stage / 'avodah.db'),
                        'files': {p.name: digest(p) for p in stage.iterdir()}}
            (stage / 'manifest.json').write_text(json.dumps(manifest, sort_keys=True))
            os.chmod(stage / 'manifest.json', 0o600)
            verify(stage)
            for path in stage.iterdir():
                with path.open('rb') as f:
                    os.fsync(f.fileno())
            name = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
            fd = os.open(stage, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
            stage.rename(destination / name)
            fd = os.open(destination, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
            if apply_retention:
                retain(destination)
            return destination / name
        except BaseException:
            shutil.rmtree(stage, ignore_errors=True)
            raise


def restore(generation, destination, expected_schema):
    generation, destination = Path(generation), Path(destination)
    manifest = verify(generation)
    if manifest['schema'] != expected_schema:
        raise ValueError('candidate schema not explicitly compatible')
    # Never replace existing data, even an empty directory.
    destination.mkdir(mode=0o700, parents=False, exist_ok=False)
    try:
        for name in manifest['files']:
            shutil.copyfile(generation / name, destination / name)
            os.chmod(destination / name, 0o600)
        if check_db(destination / 'avodah.db') != expected_schema:
            raise ValueError('restored schema mismatch')
    except BaseException:
        shutil.rmtree(destination)
        raise


def retain(destination):
    """Keep seven distinct UTC days plus four distinct ISO weeks, verified only.

    Call only after a new successful backup. Invalid generations abort deletion.
    """
    generations = sorted((p for p in Path(destination).iterdir()
                          if p.is_dir() and not p.name.startswith('.')), reverse=True)
    metadata = sorted(((p, dt.datetime.fromisoformat(verify(p)['created']))
                       for p in generations), key=lambda item: item[1], reverse=True)
    days, weeks, keep = set(), set(), set()
    for p, date in metadata:
        day, week = date.date(), date.isocalendar()[:2]
        if day not in days and len(days) < 7:
            days.add(day)
            keep.add(p)
        if week not in weeks and len(weeks) < 4:
            weeks.add(week)
            keep.add(p)
    for p, _ in metadata:
        if p not in keep:
            shutil.rmtree(p)


def main():
    os.umask(0o077)
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest='action', required=True)
    b = sub.add_parser('backup')
    for name in ['data', 'config', 'destination', 'revision']:
        b.add_argument('--' + name, required=True)
    b.add_argument('--quiesced', action='store_true')
    b.add_argument('--apply-retention', action='store_true')
    r = sub.add_parser('restore')
    r.add_argument('--generation', required=True)
    r.add_argument('--destination', required=True)
    r.add_argument('--expected-schema', required=True, type=int)
    args = vars(p.parse_args())
    action = args.pop('action')
    try:
        if action == 'backup':
            backup(**args)
        else:
            restore(**args)
        print('Private recovery operation verified')
    except Exception:
        # No paths, SQL, identity or payloads in scheduler logs.
        p.exit(1, 'Private recovery operation failed; inspect privately\n')


if __name__ == '__main__':
    main()
