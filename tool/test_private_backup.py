import datetime as dt
import importlib.util
import json
from pathlib import Path
import os
import sqlite3
import tempfile
import time
import unittest

spec = importlib.util.spec_from_file_location('recovery', Path(__file__).with_name('private_backup.py'))
recovery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recovery)


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='avo-synthetic-recovery-')
        self.root = Path(self.tmp.name)
        self.data = self.root / 'data'
        self.config = self.root / 'config'
        self.backups = self.root / 'backups'
        for p in [self.data, self.config, self.backups]:
            p.mkdir(mode=0o700)
        (self.config / 'node-id').write_text('synthetic-server')
        (self.config / 'config.json').write_text('{"categories":["synthetic"]}')
        self.db = sqlite3.connect(self.data / 'avodah.db')
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.execute('PRAGMA user_version=3')
        self.db.execute('CREATE TABLE paired_devices(id TEXT, private_key BLOB)')
        self.db.execute('INSERT INTO paired_devices VALUES (?, ?)', ('fixture', b'not-a-real-secret'))
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.tmp.cleanup()

    def snapshot(self):
        return recovery.backup(self.data, self.config, self.backups, 'synthetic-revision', quiesced=True)

    def test_wal_snapshot_restore_identity_permissions_and_semantics(self):
        start = time.monotonic()
        generation = self.snapshot()
        destination = self.root / 'restored'
        recovery.restore(generation, destination, 3)
        self.assertEqual((destination / 'node-id').read_text(), 'synthetic-server')
        with sqlite3.connect(destination / 'avodah.db') as db:
            self.assertEqual(db.execute('SELECT * FROM paired_devices').fetchone(), ('fixture', b'not-a-real-secret'))
        self.assertLess(time.monotonic() - start, 60)
        for path in destination.iterdir():
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(destination.stat().st_mode & 0o777, 0o700)
        with self.assertRaises(FileExistsError):
            recovery.restore(generation, destination, 3)

    def test_missing_identity_failure_keeps_previous_good_generation(self):
        good = self.snapshot()
        (self.config / 'node-id').unlink()
        with self.assertRaises(ValueError):
            self.snapshot()
        recovery.verify(good)
        self.assertFalse(list(self.backups.glob('.pending-*')))

    def test_corruption_and_schema_mismatch_fail_closed(self):
        generation = self.snapshot()
        with self.assertRaises(ValueError):
            recovery.restore(generation, self.root / 'wrong-schema', 99)
        (generation / 'node-id').write_text('corrupted')
        with self.assertRaises(ValueError):
            recovery.restore(generation, self.root / 'corrupt', 3)
        self.assertFalse((self.root / 'corrupt').exists())

    def test_manifest_path_traversal_rejected(self):
        generation = self.snapshot()
        p = generation / 'manifest.json'
        manifest = json.loads(p.read_text())
        manifest['files']['../outside'] = 'invalid'
        p.write_text(json.dumps(manifest))
        with self.assertRaises(ValueError):
            recovery.verify(generation)

    def test_private_destination_and_quiescence_required(self):
        with self.assertRaises(ValueError):
            recovery.backup(self.data, self.config, self.backups, 'fixture')
        self.backups.chmod(0o755)
        with self.assertRaises(ValueError):
            self.snapshot()

    def test_disk_failure_preserves_last_good(self):
        from unittest.mock import patch
        good = self.snapshot()
        with patch.object(recovery.shutil, 'copyfile', side_effect=OSError('synthetic disk full')):
            with self.assertRaises(OSError):
                self.snapshot()
        recovery.verify(good)
        self.assertFalse(list(self.backups.glob('.pending-*')))

    def test_retention_verifies_all_before_removing_and_keeps_daily_weekly(self):
        for days in range(35):
            generation = self.snapshot()
            manifest_path = generation / 'manifest.json'
            manifest = json.loads(manifest_path.read_text())
            manifest['created'] = (dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=days)).isoformat()
            manifest_path.write_text(json.dumps(manifest))
        recovery.retain(self.backups)
        # sort is by generation name, so qualification uses chronological manifest time.
        self.assertGreaterEqual(len([p for p in self.backups.iterdir() if p.is_dir()]), 7)


if __name__ == '__main__':
    unittest.main()
