#!/usr/bin/env python3
"""Isolated AVO-121 image/browser/recovery fixture. Never uses production paths.

Requires explicit candidate images. Creates only uniquely named test resources,
loopback host publication and a private TemporaryDirectory; removes them on exit.
"""
import argparse
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import socket
import ssl
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent.parent

def run(args, **kwargs):
    return subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=kwargs.pop('timeout', 30), **kwargs).stdout.decode()

def docker(*args, **kwargs):
    return run(['docker', *args], **kwargs).strip()

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sync-image', required=True)
    p.add_argument('--web-image', required=True)
    p.add_argument('--browser', action='store_true')
    args = p.parse_args()
    for image in [args.sync_image, args.web_image]:
        if not image.startswith('avodah-avo121-test-'):
            p.error('only explicitly tagged avodah-avo121-test-* candidates are accepted')
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix='avo121-qualification-') as temp:
        root = Path(temp)
        for name in ['config', 'data', 'tls', 'config/pairing', 'backups']:
            (root / name).mkdir(mode=0o700)
        (root / 'config/node-id').write_text('synthetic-server')
        (root / 'config/config.json').write_text('{"categoryChips":{"Working":["synthetic"]}}')
        (root / 'config/pairing/code').touch(mode=0o600)
        run(['openssl','req','-x509','-newkey','rsa:2048','-nodes','-days','1',
             '-subj','/CN=localhost','-addext','subjectAltName=DNS:localhost,IP:127.0.0.1',
             '-keyout',str(root/'tls/key.pem'),'-out',str(root/'tls/cert.pem')])
        public = run(['openssl','x509','-in',str(root/'tls/cert.pem'),'-pubkey','-noout'])
        der = subprocess.run(['openssl','pkey','-pubin','-outform','DER'],input=public.encode(),
                             stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout
        spki = base64.b64encode(hashlib.sha256(der).digest()).decode()
        with socket.socket() as s:
            s.bind(('127.0.0.1',0)); port=s.getsockname()[1]
        origin = f'https://localhost:{port}'
        context = ssl.create_default_context(cafile=str(root/'tls/cert.pem'))
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),
                                            urllib.request.HTTPSHandler(context=context))
        def request(path, method='GET', headers=None, body=None):
            payload = None if body is None else json.dumps(body).encode()
            req = urllib.request.Request(origin+path,data=payload,method=method,
                headers={'Content-Type':'application/json',**(headers or {})})
            try:
                with opener.open(req,timeout=4) as response:
                    return response.status, response.read(), dict(response.headers)
            except urllib.error.HTTPError as error:
                return error.code, error.read(), dict(error.headers)
        name = f'avo121-qualification-{os.getpid()}'
        containers = []
        network = None
        report = {'fixture':'disposable synthetic only','source':docker('image','inspect',args.sync_image,
                  '--format','{{index .Config.Labels "org.opencontainers.image.revision"}}'),
                  'sync_image':docker('image','inspect',args.sync_image,'--format','{{.Id}}'),
                  'web_image':docker('image','inspect',args.web_image,'--format','{{.Id}}')}
        def launch(label, image, options, command=()):
            ident = docker('run','-d','--name',f'{name}-{label}','--cpus','1','--memory','512m',
                '--pids-limit','128','--cap-drop','ALL','--security-opt','no-new-privileges',
                *options,image,*command)
            containers.append(ident)
            return ident
        def probe(ident, url, expected=200):
            value = docker('exec',ident,'curl','--noproxy','*','--silent','--max-time','3',
                           '-o','/dev/null','-w','%{http_code}',url)
            assert int(value) == expected
        try:
            network = docker('network','create','--internal',name)
            sync = launch('sync',args.sync_image,[
                '--network',name,'-p',f'127.0.0.1:{port}:18443',
                '--user',f'{os.getuid()}:{os.getgid()}',
                '-v',f'{root}/config:/config','-v',f'{root}/data:/data',
                '-e','XDG_STATE_HOME=/data/state','-e','HOME=/tmp',
                '-e','SYNC_HOST=127.0.0.1','-e','SYNC_PORT=19847','-e','JIRA_ENABLED=false',
                '-e',f'SYNC_ALLOWED_ORIGINS={origin}',
                '-e','PAIRING_CODE_FILE=/config/pairing/code','-e','AGENT_API_URL=http://127.0.0.1:19999'])
            web = launch('web',args.web_image,['--cap-add','NET_BIND_SERVICE','--network',f'container:{sync}',
                '--user',f'{os.getuid()}:{os.getgid()}',
                '-e','XDG_CONFIG_HOME=/tmp/config','-e','XDG_DATA_HOME=/tmp/data',
                '-e','WEB_HOST=127.0.0.1','-e','WEB_PORT=18080'])
            fixture = root/'gateway.Caddyfile'
            fixture.write_text('''{
 admin off
 auto_https off
}
https://:18443 {
 tls /fixture-tls/cert.pem /fixture-tls/key.pem
 handle /_fixture/ready {
  rewrite * /ready
  reverse_proxy 127.0.0.1:19847
 }
 handle /avodah/api/* {
  uri strip_prefix /avodah
  reverse_proxy 127.0.0.1:19847
 }
 handle_path /avodah/* {
  reverse_proxy 127.0.0.1:18080
 }
}
http://127.0.0.1:19999 {
 header Content-Type application/json
 respond `{"error":"synthetic PA denial"}` 403
}
''')
            launch('gateway',args.web_image,['--cap-add','NET_BIND_SERVICE','--network',f'container:{sync}',
                '--user',f'{os.getuid()}:{os.getgid()}',
                '-e','XDG_CONFIG_HOME=/tmp/config','-e','XDG_DATA_HOME=/tmp/data',
                '-v',f'{root}/tls:/fixture-tls:ro','-v',f'{fixture}:/fixture.Caddyfile:ro',
                '--entrypoint','caddy'],['run','--config','/fixture.Caddyfile','--adapter','caddyfile'])
            deadline = time.monotonic()+30
            while True:
                try:
                    if request('/_fixture/ready')[0] == 200: break
                except (OSError,urllib.error.URLError): pass
                if time.monotonic()>deadline: raise AssertionError('fixture startup failed')
                time.sleep(.2)
            probe(sync,'http://127.0.0.1:19847/ready')
            probe(sync,'http://127.0.0.1:18080/sqlite3.wasm')
            # Peer network access must fail even though same-namespace loopback works.
            address = docker('inspect',sync,'--format',f'{{{{(index .NetworkSettings.Networks "{name}").IPAddress}}}}')
            for backend in [19847,18080,2019]:
                result = subprocess.run(['docker','run','--rm','--network',name,'--entrypoint','curl',
                    args.sync_image,'--noproxy','*','--silent','--max-time','2',f'http://{address}:{backend}/'],
                    stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=10)
                assert result.returncode != 0, f'Backend {backend} reachable on nonloopback'
            report['loopback_peer_negatives'] = True
            for path,methods in {'/api/config/categories':['GET'],
                '/api/config/category-chips':['GET','POST','DELETE'],
                '/api/sync/deltas':['GET','POST'], '/api/test':['GET','POST','PUT','PATCH','DELETE']}.items():
                for method in methods:
                    assert request('/avodah'+path,method,body={} if method!='GET' else None)[0] == 403
            report['https_unpaired_matrix'] = True
            status,_,headers = request('/avodah/sqlite3.wasm')
            assert status == 200 and headers.get('Content-Type') == 'application/wasm'
            assert headers.get('Cross-Origin-Opener-Policy') == 'same-origin'
            assert headers.get('Cross-Origin-Embedder-Policy') == 'require-corp'
            assert request('/avodah/api/sync/status',headers={'Origin':'https://hostile.invalid'})[0] == 403
            report['wasm_isolation_origin'] = True
            if args.browser:
                try:
                    browser = json.loads(run(['node',str(ROOT/'tool/qualify_browser.mjs'),origin,
                        str(root/'config/pairing/code'),str(root/'profile'),spki],timeout=110))
                except subprocess.CalledProcessError as error:
                    Path('/tmp/avo121-browser-debug.log').write_bytes(error.stderr)
                    raise
                credentials = browser.pop('credentials')
                report['browser'] = browser
                auth = {'X-Av-Node-Id':credentials['node'],'X-Av-Pair-Token':credentials['token']}
                assert request('/avodah/api/sync/pair',headers=auth)[0] == 200
                assert request('/avodah/api/test',headers=auth)[0] == 403
                # Quiesce only the synthetic server, then qualify restored identity/auth.
                docker('stop','--time','5',sync)
                spec = importlib.util.spec_from_file_location('backup',ROOT/'tool/private_backup.py')
                recovery = importlib.util.module_from_spec(spec);spec.loader.exec_module(recovery)
                start = time.monotonic()
                generation = recovery.backup(root/'data',root/'config',root/'backups',report['source'],quiesced=True)
                schema = recovery.verify(generation)['schema']
                restored = root/'restored'
                recovery.restore(generation,restored,schema)
                assert (restored/'node-id').read_text() == 'synthetic-server'
                clone = launch('restore',args.sync_image,['--network','none',
                    '--user',f'{os.getuid()}:{os.getgid()}',
                    '-v',f'{restored}:/data','-v',f'{restored}:/config',
                    '-e','XDG_STATE_HOME=/data/state','-e','HOME=/tmp',
                    '-e','SYNC_PORT=19847','-e','JIRA_ENABLED=false'])
                time.sleep(1)
                config = f'url = "http://127.0.0.1:19847/api/sync/pair"\nheader = "X-Av-Node-Id: {credentials["node"]}"\nheader = "X-Av-Pair-Token: {credentials["token"]}"\nfail\nsilent\nmax-time = 3\n'
                value = docker('exec','-i',clone,'curl','--noproxy','*','--config','-',input=config.encode())
                assert json.loads(value)['paired'] is True
                report['isolated_restore_authenticated'] = True
                report['restore_seconds'] = round(time.monotonic()-start,3)
                docker('start',sync);time.sleep(.5)
                assert request('/avodah/api/sync/pair','DELETE',headers=auth)[0] == 200
                assert request('/avodah/api/config/categories',headers=auth)[0] == 403
                report['revoked_https_denied'] = True
            # Optional dependency denial did not fail the core, stopped sync does.
            assert request('/_fixture/ready')[0] == 200
            docker('stop','--time','5',sync)
            start=time.monotonic(); assert request('/_fixture/ready')[0] == 502
            report['stopped_backend_detection_seconds']=round(time.monotonic()-start,3)
            report['cleanup'] = 'exact fixture resources removed in finally'
        except Exception:
            # Fixture-only sanitized process logs; the server code channel is
            # a separate private file, never stdout/stderr. No live container IDs.
            with open('/tmp/avo121-fixture-debug.log','w') as debug:
                for ident in containers:
                    value = subprocess.run(['docker','logs','--tail','20',ident],
                        stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=10)
                    debug.write(value.stdout.decode(errors='replace'))
            raise
        finally:
            for ident in reversed(containers):
                subprocess.run(['docker','rm','-f',ident],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=15)
            if network:
                subprocess.run(['docker','network','rm',network],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=15)
        print(json.dumps(report,sort_keys=True,indent=2))

if __name__ == '__main__':
    try: main()
    except Exception as error:
        # No command stderr/stdout, profile contents, codes or credentials in logs.
        print(json.dumps({'passed':False,'error_type':type(error).__name__,
                          'message':str(error) if isinstance(error, AssertionError) else 'Fixture failed; inspect test stage privately'}))
        raise SystemExit(1)
