"""Opt-in local feasibility experiment. Never connects to a cloud endpoint.

Requires the existing local Supabase stack and installed Edge Runtime image.
Creates/removes only nonce-owned users, upload mirrors, objects, and SQL probes.
No publication, production migration, parser/hash implementation, or editor write.
Exit 0 means experiments completed, not resource targets or immutability passed.
"""
import argparse
import base64
import concurrent.futures
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from check_content_edge_resources import EVENTS

FILES = ['content.sqlite', 'pack.json', 'registry.json', 'history_inventory.json',
         'editorial_reviews.json', 'provenance.json', 'finalization_report.json',
         'content.manifest.json', 'reader_report.json']
IMAGE = 'public.ecr.aws/supabase/edge-runtime:v1.77.1'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args):
        raise RuntimeError('Redirect refused')


def command(*args, input=None, env=None):
    result = subprocess.run(list(args), input=input, text=True, encoding='utf8',
                            capture_output=True, env=env)
    if result.returncode:
        # Never expose subprocess environments or credential-bearing URLs.
        raise RuntimeError('Local command failed: '+args[0]+' exit '+str(result.returncode))
    return result.stdout


class Local:
    def __init__(self):
        settings = json.loads(command(shutil.which('supabase'), 'status', '-o', 'json'))
        assert settings['API_URL'] == 'http://127.0.0.1:54321', 'Loopback stack required'
        self.url = settings['API_URL']
        self.secret, self.anon = settings['SERVICE_ROLE_KEY'], settings['ANON_KEY']
        self.count = 0

    def http(self, method, path, data=None, token=None, key=None, port=None, raw=False, headers=None):
        assert path.startswith('/') and not path.startswith('//')
        base = self.url if port is None else 'http://127.0.0.1:'+str(port)
        head = {'apikey': key or self.secret, 'Authorization': 'Bearer '+(token or self.secret),
                'Content-Type': 'application/octet-stream' if isinstance(data, bytes) else 'application/json'}
        head.update(headers or {})
        body = data if isinstance(data, bytes) or data is None else json.dumps(data).encode()
        req = urllib.request.Request(base+path, data=body, method=method, headers=head)
        self.count += 1
        try:
            with urllib.request.build_opener(NoRedirect()).open(req, timeout=45) as r:
                payload = r.read()
                return r.status, payload if raw else json.loads(payload) if payload else None
        except urllib.error.HTTPError as e:
            # Error payload stays in memory; only status and bounded known fields are reported.
            try:
                value = json.loads(e.read(16384))
            except ValueError:
                value = {}
            return e.code, {'code': value.get('code', value.get('error'))}


def sql(statement):
    return command('docker', 'exec', '-i', 'supabase_db_sprachapp', 'psql', '-U',
                   'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-At', input=statement)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, required=True)
    parser.add_argument('--state-only', action='store_true', help='Only repeat changed state tests; no resource rerun')
    parser.add_argument('--storage-only', action='store_true', help='Only run Storage counterexamples')
    parser.add_argument('--streaming', action='store_true', help='Add established parser experiments to real-service run')
    args = parser.parse_args()
    source = args.bundle.resolve()
    original = {n: hashlib.sha256((source/n).read_bytes()).hexdigest() for n in FILES}
    objects = {n: {'sha256': original[n], 'size_bytes': (source/n).stat().st_size} for n in FILES}
    manifest = json.loads((source/'content.manifest.json').read_text(encoding='utf8'))
    nonce = uuid.uuid4().hex
    root = ROOT/'build/verification_v2'/nonce
    root.mkdir(parents=True)
    rpc, schema = 'v2_probe_'+nonce, 'v2_probe_'+nonce
    local = Local()
    assert local.http('GET', '/rest/v1/content_channels?select=generation,release_id')[1] in ([],), 'Baseline requires an empty local channel'
    command('docker', 'image', 'inspect', IMAGE)
    for name in ['content-publish/index.ts', '_shared/content_distribution.ts', '_shared/internal_baseline_source.json']:
        dest = root/'functions'/name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT/'supabase/functions'/name, dest)
    for name, code in [('main', (HERE/'main.ts').read_text()),
                       ('probe', (HERE/'worker.ts').read_text()), ('events', EVENTS)]:
        (root/name).mkdir()
        (root/name/'index.ts').write_text(code, encoding='utf8')
    # probe imports ../functions, relative to /work/probe/index.ts.
    stream_code = (HERE/'stream_pack_probe.ts').read_text(encoding='utf8')
    stream_code = stream_code.replace("'stream-json/Parser'", "'npm:stream-json@1.9.1/Parser.js'")
    stream_code = stream_code.replace("'stream-json/Assembler'", "'npm:stream-json@1.9.1/Assembler.js'")
    (root/'probe/stream_pack_probe.ts').write_text(stream_code, encoding='utf8')
    users, uploads, stored_keys = [], [], []
    container = 'sprachapp-v2-'+nonce[:10]
    results = {'local_only': True, 'cloud_pass': False, 'image': IMAGE,
               'limits': {'memory_mib': 256, 'cpu_soft_ms': 1000, 'cpu_hard_ms': 2000, 'wall_ms': 150000},
               'original_hashes': original, 'resources': [], 'storage': [], 'state': []}
    begin = time.monotonic()
    schema_created = False

    def expect(status, expected, label):
        assert status in expected, label+' HTTP '+str(status)

    def grant(actor, allowed):
        method = 'POST' if allowed else 'DELETE'
        path = '/rest/v1/content_publishers'+('' if allowed else '?user_id=eq.'+actor)
        expect(local.http(method, path, {'user_id': actor} if allowed else None)[0], [201, 204], 'publisher grant fixture')

    def make_user():
        email, password = 'v2-'+uuid.uuid4().hex+'@example.test', uuid.uuid4().hex+'-Aa1!'
        status, user = local.http('POST', '/auth/v1/admin/users', {'email': email, 'password': password, 'email_confirm': True})
        expect(status, [200, 201], 'create local user')
        users.append(user['id'])
        status, session = local.http('POST', '/auth/v1/token?grant_type=password', {'email': email, 'password': password}, key=local.anon)
        expect(status, [200], 'local password login')
        grant(user['id'], True)
        return user['id'], session['access_token']

    def start_container(mode, policy):
        env = dict(os.environ, SUPABASE_SERVICE_ROLE_KEY=local.secret, PROBE_RPC=rpc,
                   PROBE_MODE=mode, PROBE_POLICY=policy)
        command('docker', 'run', '-d', '--pull', 'never', '--name', container,
                '--network', 'supabase_network_sprachapp', '--publish', '127.0.0.1:54999:9000',
                '--mount', f'type=bind,source={root},target=/work,readonly',
                '-e', 'SUPABASE_SERVICE_ROLE_KEY', '-e', 'PROBE_RPC', '-e', 'PROBE_MODE', '-e', 'PROBE_POLICY',
                IMAGE, 'start', '--main-service', '/work/main', '--event-worker', '/work/events', '--policy', policy, env=env)
        for _ in range(30):
            try:
                if local.http('GET', '/health', port=54999)[0] == 200:
                    return
            except OSError:
                time.sleep(.1)
        raise AssertionError('Local gateway unavailable')

    def stop_container(label):
        command('docker', 'stop', container)
        logs = command('docker', 'logs', container)
        command('docker', 'rm', container)
        (root/(label+'.log')).write_text(logs, encoding='utf8')
        events = []
        for line in logs.splitlines():
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get('event_type') in ['Boot', 'Shutdown']:
                events.append(e)
        return events

    def cgroup_cpu():
        text = command('docker', 'exec', container, 'cat', '/sys/fs/cgroup/cpu.stat')
        return int(next(x.split()[1] for x in text.splitlines() if x.startswith('usage_usec ')))

    def measured(path, data, token, label):
        cpu, start = cgroup_cpu(), time.monotonic()
        status, value = local.http('POST', path, data, token=token, key=local.anon, port=54999)
        row = {'step': label, 'http_status': status, 'wall_ms': round((time.monotonic()-start)*1000, 1),
               'container_cpu_ms': round((cgroup_cpu()-cpu)/1000, 1), 'status': value.get('status'),
               'code': value.get('code')}
        print(json.dumps(row), flush=True)
        return row, value

    try:
        actor, token = make_user()
        outsider, other_token = make_user()
        sql((HERE/'state.sql').read_text().replace('__SCHEMA__', schema).replace('__RPC__', rpc))
        schema_created = True
        # Storage attack probes use tiny isolated objects; never mutate bundle mirrors.
        for scope in ['upload', 'parent']:
            key = str(uuid.uuid4())+'/pack.json'
            status, signed = local.http('POST', '/storage/v1/object/upload/sign/content-private/'+key, {'upsert': False})
            expect(status, [200], 'sign local test object')
            signed_path = '/storage/v1'+signed['url']
            encoded = urllib.parse.parse_qs(urllib.parse.urlsplit(signed_path).query)['token'][0].split('.')[1]
            claims = json.loads(base64.urlsafe_b64decode(encoded+'='*((-len(encoded))%4)))
            # Only the duration is retained; never the token, URL, or secret.
            ttl = claims['exp']-claims['iat']
            status, _ = local.http('PUT', signed_path, b'original')
            expect(status, [200], 'signed initial insert'); stored_keys.append(key)
            dup = local.http('PUT', signed_path, b'old-token-overwrite')[0]
            upsert_attempt = local.http('PUT', signed_path, b'old-token-upsert', headers={'x-upsert':'true'})[0]
            client_update = local.http('PUT', '/storage/v1/object/content-private/'+key, b'user-write', token=token, key=local.anon)[0]
            client_delete, deleted_rows = local.http('DELETE', '/storage/v1/object/content-private', {'prefixes':[key]}, token=token, key=local.anon)
            # Storage DELETE may return HTTP200 with zero visible/deleted rows.
            # Verify bytes, rather than interpreting that status as permission.
            assert deleted_rows == []
            assert local.http('GET', '/storage/v1/object/authenticated/content-private/'+key, raw=True)[1] == b'original'
            admin_update = local.http('PUT', '/storage/v1/object/content-private/'+key, b'replaced')[0]
            expect(admin_update, [200], 'service update counterexample')
            assert local.http('GET', '/storage/v1/object/authenticated/content-private/'+key, raw=True)[1] == b'replaced'
            deleted = local.http('DELETE', '/storage/v1/object/content-private', {'prefixes': [key]})[0]
            recreated = local.http('PUT', signed_path, b'recreated')[0]
            assert dup >= 400 and upsert_attempt >= 400 and client_update >= 400 and deleted == 200 and recreated == 200
            results['storage'].append({'scope': scope, 'old_token_overwrite': dup, 'user_update': client_update,
                                       'signed_upload_ttl_seconds':ttl,
                                       'old_token_upsert_header':upsert_attempt, 'user_delete_status':client_delete, 'user_delete_changed_bytes':False,
                                       'service_update': admin_update, 'service_delete': deleted, 'old_token_recreate': recreated,
                                       'immutability_proved': False})
        print('Storage: nonprivileged replacement denied; privileged update/delete and old-token recreation succeed.', flush=True)
        if args.storage_only:
            assert original == {n: hashlib.sha256((source/n).read_bytes()).hexdigest() for n in FILES}
            results['bundle_unchanged'] = True
            return

        # Actual start/finalize handler, local Auth, real storage and Postgres.
        for policy in ([] if args.state_only else ['oneshot', 'per_worker']):
            start_container('original', policy)
            calls = []
            try:
                data = {'request_id': str(uuid.uuid4()), 'lang': 'en', 'channel': 'internal',
                        'expected_generation': 0, 'parent_release_id': None, 'parent_manifest_sha256': None,
                        'manifest': manifest, 'objects': objects}
                status, started = local.http('POST', '/content-publish/start', data, token=token, key=local.anon, port=54999)
                expect(status, [200], 'original authenticated start')
                uid = started['upload_id']; uploads.append(uid)
                # No publication: incomplete commit must reject before files/checks.
                status, _ = local.http('POST', '/content-publish/'+uid+'/commit', {'request_id': str(uuid.uuid4()),
                                      'expected_generation': 0, 'expected_manifest_sha256': None}, token=token, key=local.anon, port=54999)
                assert status >= 400
                for name in FILES:
                    path = '/storage/v1'+started['uploads'][name]
                    status, _ = local.http('PUT', path, (source/name).read_bytes())
                    expect(status, [200], 'local bundle mirror'); stored_keys.append(uid+'/'+name)
                for i in range(10):
                    row, _ = measured('/content-publish/'+uid+'/finalize', {}, token, 'original:'+policy+':'+str(i+1))
                    calls.append(row)
                    if row['http_status'] != 200:
                        break
            finally:
                events = stop_container('original-'+policy)
            results['resources'].append({'mode': 'original', 'policy': policy, 'calls': calls,
                                         'events': events, 'bundle_bytes': sum(x['size_bytes'] for x in objects.values()),
                                         'last_verification_read_bytes': sum(objects[n]['size_bytes'] for n in FILES if n not in ['content.sqlite', 'reader_report.json'])})
        if not uploads:
            uid = str(uuid.uuid4())
            fixture = {'id': uid, 'request_id': str(uuid.uuid4()), 'owner_id': actor,
                       'lang': 'en', 'channel': 'internal', 'expected_generation': 0,
                       'parent_release_id': None, 'parent_manifest_sha256': None,
                       'draft_manifest': manifest, 'objects': objects}
            expect(local.http('POST', '/rest/v1/content_release_uploads', fixture)[0], [201], 'state-only metadata fixture')
            uploads.append(uid)
        uid = uploads[0]
        # Separate existing semantic boundaries; no generic parser or checkpoint hash.
        for policy in ([] if args.state_only else ['oneshot', 'per_worker']):
            start_container('probe', policy)
            calls = []
            try:
                phases = [('file', n) for n in FILES] + [(n, None) for n in
                    ['sidecars', 'pack_parse', 'pack_full_hash', 'pack_content_hash', 'pack_structure', 'pack_both_hashes', 'history']]
                if args.streaming:
                    phases += [(n,None) for n in ['stream_tokens','stream_parse','stream_both_hashes']]
                for phase, name in phases:
                    row, value = measured('/probe', {'upload_id': uid, 'phase': phase, 'name': name}, token, phase+(':'+name if name else ''))
                    calls.append(row)
                    if row['http_status'] != 200:
                        if args.streaming and phase.startswith('stream_'):
                            # Diagnostic failures are evidence, never a passed verification.
                            continue
                        break
                    if 'full' in value:
                        assert value['full'] == '0bce823cbe7f6e1abeb114489a3536659b9bca6ed3ec451fa5692924465bda64'
                    if 'content' in value:
                        assert value['content'] == 'aa2eaf04dceed03c3941dfefc18f09dbc0d5318fd53958a024636e6ac6295a23'
                metrics = local.http('GET', '/metrics', port=54999)[1]
            finally:
                events = stop_container('phases-'+policy)
            results['resources'].append({'mode': 'phase-probes', 'policy': policy, 'calls': calls, 'metrics': metrics, 'events': events})

        start_container('probe', 'per_worker')
        try:
            def state(op, values=None, who=token):
                return local.http('POST', '/probe', {'upload_id': uid, 'phase': 'state', 'op': op,
                                                   'input': values or {}}, token=who, key=local.anon, port=54999)
            expect(state('start', who='invalid')[0], [401], 'invalid auth')
            expect(state('start', who=other_token)[0], [403], 'wrong owner')
            status, run = state('start'); expect(status, [200], 'state start')
            ident = {'run_id': run['run_id'], 'verifier': 'probe-v1'}
            expect(state('status', {**ident, 'verifier': 'wrong'})[0], [409], 'verifier mismatch')
            expect(state('finish', ident)[0], [409], 'no result without acquired lease')
            with concurrent.futures.ThreadPoolExecutor(2) as pool:
                race = list(pool.map(lambda _: state('claim', {**ident, 'revision': 0}), range(2)))
            assert sorted(s for s, _ in race) == [200, 409]
            old = next(v for s, v in race if s == 200)
            assert state('status', ident)[1]['step'] == 0
            # Simulated abrupt worker death: no finish; wait for the real DB lease clock.
            time.sleep(2.1)
            status, claim = state('claim', {**ident, 'revision': old['revision']}); expect(status, [200], 'lease takeover')
            expect(state('finish', {**ident, **old, 'result': {'diagnostic': 'old'}})[0], [409], 'stale finish')
            finish = {**ident, **claim, 'result': {'diagnostic_only': True}}
            status, accepted = state('finish', finish); expect(status, [200], 'finish')
            assert accepted['step'] == 1 and state('finish', finish)[1] == accepted
            expect(state('finish', {**finish, 'result': {'changed': True}})[0], [409], 'changed retry')
            expect(state('abort_after_claim', {**ident, 'revision':accepted['revision']})[0], [546], 'actual worker abort')
            status, after_abort=state('status',ident);expect(status,[200],'status after worker death')
            assert after_abort['step']==1 and after_abort['revision']==accepted['revision']+1
            # The hard CPU abort itself normally outlasts the 2s lease. Wait only
            # for any remaining lease time, never retry a failed work invocation.
            time.sleep(2.1)
            expect(state('claim',{**ident,'revision':after_abort['revision']})[0],[200],'claim after actual abort')
            grant(actor, False)
            expect(state('status', ident)[0], [403], 'revoked right')
            grant(actor, True)
            expect(state('complete', ident)[0], [409], 'unsealed cannot complete')
            # Expire only the nonce-owned prototype run; original upload expiry stays untouched.
            original_expiry = local.http('GET', '/rest/v1/content_release_uploads?id=eq.'+uid+'&select=expires_at')[1]
            sql(f"update {schema}.runs set expires_at=clock_timestamp()-interval '1 second' where id='{run['run_id']}';")
            expect(state('status', ident)[0], [409], 'expired run')
            # Existing backend maps SQL 42501 to a redacted 503; the denial is
            # intentional, not a new production error-mapping change.
            expect(state('resume', ident)[0], [503], 'resume requires explicit acceptance')
            expect(state('status', ident)[0], [409], 'denial must preserve expired state')
            resume = {**ident, 'accepted': True, 'scope': 'resume-same-upload-probe-v1', 'request_id': str(uuid.uuid4())}
            status, resumed = state('resume', resume); expect(status, [200], 'explicit resume')
            assert resumed['run_id'] == run['run_id'] and resumed['step'] == 0
            assert state('resume', resume)[1] == resumed
            assert original_expiry == local.http('GET', '/rest/v1/content_release_uploads?id=eq.'+uid+'&select=expires_at')[1]
            # An actually expired upload is a separate fixture, inserted expired;
            # never rewrite an existing upload's guarded expires_at.
            expired_id = str(uuid.uuid4())
            fixture = {'id': expired_id, 'request_id': str(uuid.uuid4()), 'owner_id': actor,
                       'lang': 'en', 'channel': 'internal', 'expected_generation': 0,
                       'parent_release_id': None, 'parent_manifest_sha256': None,
                       'draft_manifest': manifest, 'objects': objects, 'expires_at': '2000-01-01T00:00:00Z'}
            expect(local.http('POST', '/rest/v1/content_release_uploads', fixture)[0], [201], 'expired fixture')
            uploads.append(expired_id)
            active_id = uid
            uid = expired_id
            expect(state('start')[0], [409], 'expired upload cannot start')
            explicit = {'accepted': True, 'scope': 'resume-same-upload-probe-v1', 'request_id': str(uuid.uuid4())}
            expect(state('resume_start', {})[0], [503], 'expired upload needs explicit resume')
            status, expired_run = state('resume_start', explicit)
            expect(status, [200], 'explicit resume on expired upload')
            assert state('resume_start', explicit)[1] == expired_run
            assert local.http('GET', '/rest/v1/content_release_uploads?id=eq.'+uid+'&select=expires_at')[1][0]['expires_at'].startswith('2000-01-01')
            expect(state('complete', {'run_id': expired_run['run_id'], 'verifier': 'probe-v1'})[0], [409], 'resumed unsealed cannot complete')
            uid = active_id
            assert local.http('GET', '/rest/v1/content_release_catalog?select=release_id')[1] == []
            results['state'] = ['invalid JWT rejected', 'wrong owner rejected', 'verifier mismatch rejected',
                'two claims: one winner', 'no finish: zero progress', 'expired lease reclaimed',
                'stale result rejected', 'lost response retry idempotent', 'changed retry rejected',
                'actual CPU worker abort after durable claim: HTTP546, no extra progress, reclaim succeeds',
                'right revocation rejected', 'unsealed completion rejected', 'expired run rejected',
                'explicit audited resume: same upload, reset diagnostic progress, original expiry unchanged',
                'expired upload: ordinary start denied, explicit resume_start idempotent, guarded expiry unchanged',
                'catalog empty']
            print('State probes: '+str(len(results['state']))+' passed; no publication.', flush=True)
        finally:
            results['state_events']=stop_container('state')
        start_container('original','oneshot')
        try:
            status,_=local.http('POST','/content-publish/'+expired_id+'/finalize',{},token=token,key=local.anon,port=54999)
            expect(status,[409],'original handler still rejects expired upload after prototype resume')
            results['state'].append('original handler still rejects expired upload after diagnostic resume')
        finally:
            stop_container('expired-original')
        assert original == {n: hashlib.sha256((source/n).read_bytes()).hexdigest() for n in FILES}
        results['elapsed_seconds'] = round(time.monotonic()-begin, 2)
        results['driver_http_requests'] = local.count
        results['bundle_unchanged'] = True
    finally:
        subprocess.run(['docker', 'rm', '-f', container], capture_output=True)
        if schema_created:
            sql(f'drop function public.{rpc}(uuid,uuid,text,jsonb); drop schema {schema} cascade; notify pgrst,\'reload schema\';')
        for key in stored_keys:
            expect(local.http('DELETE', '/storage/v1/object/content-private', {'prefixes': [key]})[0], [200], 'cleanup own object')
        for uid in uploads:
            expect(local.http('DELETE', '/rest/v1/content_release_uploads?id=eq.'+uid)[0], [204], 'cleanup own upload')
        for user in users:
            grant(user, False)
            expect(local.http('DELETE', '/auth/v1/admin/users/'+user)[0], [200], 'cleanup own user')
        results['total_seconds_including_cleanup'] = round(time.monotonic()-begin, 2)
        results['total_driver_http_requests_including_cleanup'] = local.count
        results['cleanup_complete'] = True
        (root/'results.json').write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
        print('Own fixtures removed. Evidence:', root, flush=True)


if __name__ == '__main__':
    main()
