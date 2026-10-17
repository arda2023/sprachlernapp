"""Measure the exact content-publish entrypoint locally, never a cloud PASS.

Uses the existing real-bundle fixture adapter (synthetic Auth/Storage/PostgREST),
but removes the instrumented publish wrapper. Fresh and reusable worker runs
use the unchanged entrypoint and its environment-based backend construction.
No cloud requests, retries of failed finalizations, uploads or publications.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
import uuid
from pathlib import Path

from check_content_edge_resources import EVENTS, MAIN, ROOT, command, request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, required=True)
    parser.add_argument('--functions', type=Path, default=ROOT/'supabase/functions')
    args = parser.parse_args()
    source, functions = args.bundle.resolve(), args.functions.resolve()
    names = ['content.sqlite', 'pack.json', 'registry.json', 'history_inventory.json',
             'editorial_reviews.json', 'provenance.json', 'finalization_report.json',
             'content.manifest.json', 'reader_report.json']
    hashes = {n: hashlib.sha256((source/n).read_bytes()).hexdigest() for n in names}
    image = 'public.ecr.aws/supabase/edge-runtime:v1.77.1'
    command('docker', 'image', 'inspect', image)
    root = ROOT/'build/content_edge_handler_resources'/uuid.uuid4().hex
    (root/'bundle').mkdir(parents=True)
    for name in names:
        shutil.copyfile(source/name, root/'bundle'/name)
    for name in ['content-publish/index.ts', '_shared/content_distribution.ts',
                 '_shared/internal_baseline_source.json']:
        target = root/'functions'/name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(functions/name, target)
    manifest = json.loads((source/'content.manifest.json').read_text(encoding='utf8'))
    upload = {'id': '11111111-1111-4111-8111-111111111111', 'lang': 'en',
              'channel': 'internal', 'expected_generation': 0,
              'parent_release_id': None, 'parent_manifest_sha256': None,
              'draft_manifest': manifest, 'created_at': '2026-10-16T00:00:00Z', 'objects': {}}
    (root/'upload.json').write_text(json.dumps(upload), encoding='utf8')
    (root/'events').mkdir()
    (root/'events/index.ts').write_text(EVENTS, encoding='utf8')
    (root/'main').mkdir()
    # Retain only the established fixture routes. The worker receives the actual
    # incoming /content-publish/<id>/finalize request and its original streamRid.
    assert MAIN.count(" if(p==='/run'){") == 1
    fixture = MAIN.split(" if(p==='/run'){")[0]
    route = r'''
 if(p.startsWith('/content-publish/')){
  try{
   const worker=await EdgeRuntime.userWorkers.create({
    servicePath:'/work/functions/content-publish',memoryLimitMb:256,
    workerTimeoutMs:150000,cpuTimeSoftLimitMs:1000,cpuTimeHardLimitMs:2000,
    noModuleCache:false,forceCreate:FRESH,
    envVars:[['SUPABASE_URL','http://localhost:9000'],['SUPABASE_SERVICE_ROLE_KEY','synthetic']]
   });
   return await worker.fetch(req);
  }catch{return Response.json({code:'LOCAL_WORKER_ABORT'},{status:546});}
 }
 return new Response('',{status:404});
});
'''
    container = 'sprachapp-handler-resource-'+uuid.uuid4().hex[:8]
    summaries = {}
    try:
        for policy in ['oneshot', 'per_worker']:
            code = fixture + route.replace('FRESH', 'true' if policy == 'oneshot' else 'false')
            (root/'main/index.ts').write_text(code, encoding='utf8')
            command('docker', 'run', '-d', '--pull', 'never', '--name', container,
                    '--publish', '127.0.0.1:54999:9000', '--mount',
                    f'type=bind,source={root},target=/work,readonly', image,
                    'start', '--main-service', '/work/main', '--event-worker',
                    '/work/events', '--policy', policy)
            calls = []
            try:
                for _ in range(30):
                    try:
                        if request('/health')[0] == 200:
                            break
                    except OSError:
                        time.sleep(.1)
                # The fixture validates the bearer shape in the real actor()
                # function; it deliberately does not emulate GoTrue JWT checks.
                import urllib.request
                import urllib.error
                for index in range(10):
                    req = urllib.request.Request(
                        'http://127.0.0.1:54999/content-publish/'+upload['id']+'/finalize',
                        data=b'{}', headers={'Authorization': 'Bearer synthetic',
                                            'Content-Type': 'application/json'})
                    start = time.monotonic()
                    try:
                        with urllib.request.urlopen(req, timeout=30) as response:
                            status, data = response.status, json.load(response)
                    except urllib.error.HTTPError as error:
                        status, data = error.code, json.load(error)
                    row = {'call': index+1, 'http_status': status,
                           'wall_ms': round((time.monotonic()-start)*1000, 1),
                           'state': data.get('status'), 'code': data.get('code')}
                    calls.append(row)
                    print(policy, json.dumps(row), flush=True)
                    if status != 200:
                        break
            finally:
                command('docker', 'stop', container)
                logs = command('docker', 'logs', container)
                command('docker', 'rm', container)
            events = []
            for line in logs.splitlines():
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if event.get('event_type') in ['Boot', 'Shutdown']:
                    events.append(event)
            summaries[policy] = {'calls': calls, 'events': events}
            (root/(policy+'.log')).write_text(logs, encoding='utf8')
            print(policy, 'shutdowns:', json.dumps([
                e['event'] for e in events if e['event_type'] == 'Shutdown']), flush=True)
        assert hashes == {n: hashlib.sha256((source/n).read_bytes()).hexdigest() for n in names}
        (root/'results.json').write_text(json.dumps({
            'image': image, 'limits': {'memory_mib': 256, 'cpu_soft_ms': 1000,
                                      'cpu_hard_ms': 2000, 'wall_ms': 150000},
            'synthetic_backends': True, 'cloud_pass': False,
            'bundle_hashes': hashes, 'runs': summaries}, indent=2), encoding='utf8')
        print('Bundle unchanged. Results:', root, flush=True)
        assert all(len(s['calls']) == 10 and s['calls'][-1]['state'] == 'ready'
                   for s in summaries.values()), 'Local handler resource failure; inspect evidence'
    finally:
        subprocess.run(['docker', 'rm', '-f', container], capture_output=True)


if __name__ == '__main__':
    main()
