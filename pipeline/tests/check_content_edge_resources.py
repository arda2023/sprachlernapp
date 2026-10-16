"""Compare real bundle finalization in an isolated, bounded local Edge Runtime.

Uses only an already installed Docker image, immutable local input copies and
synthetic local Auth/Storage/DB adapters. No cloud calls, uploads or publication.
The old implementation is read from Git; no source, bundle or anchor is changed.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

MAIN = r'''import {createHash} from 'node:crypto';
const names=['content.sqlite','pack.json','registry.json','history_inventory.json','editorial_reviews.json','provenance.json','finalization_report.json','content.manifest.json','reader_report.json'];
const root='/work/bundle/';
const metrics=[];
const u=JSON.parse(await Deno.readTextFile('/work/upload.json'));
for(const name of names){const h=createHash('sha256'),f=await Deno.open(root+name);let size=0;for await(const chunk of f.readable){h.update(chunk);size+=chunk.length;}u.objects[name]={sha256:h.digest('hex'),size_bytes:size};}
u.status='uploading';u.expires_at='2099-01-01T00:00:00Z';u.owner_id='22222222-2222-4222-8222-222222222222';u.verified_objects={};
Deno.serve({port:9000},async req=>{
 const url=new URL(req.url),p=url.pathname;
 if(p==='/health')return Response.json({ready:true});
 if(p==='/metadata')return Response.json(u);
 if(p==='/metric'&&req.method==='POST'){const m=await req.json();metrics.push(m);console.log(JSON.stringify(m));return Response.json({ok:true});}
 if(p==='/metrics')return Response.json(metrics);
 if(p==='/auth/v1/user')return Response.json({id:u.owner_id});
 if(p.startsWith('/rest/v1/content_publishers'))return Response.json([{user_id:u.owner_id}]);
 if(p.startsWith('/rest/v1/content_channels'))return Response.json([]);
 if(p.startsWith('/rest/v1/content_release_uploads')){if(req.method==='PATCH')Object.assign(u,await req.json());return Response.json([u]);}
 if(p.startsWith('/storage/v1/object/authenticated/content-private/')){const n=p.split('/').pop();if(!names.includes(n))return new Response('',{status:404});const f=await Deno.open(root+n);return new Response(f.readable);}
 if(p==='/reset'){u.status='uploading';u.verified_objects={};delete u.manifest;return Response.json({ok:true});}
 if(p==='/run'){
  try{const worker=await EdgeRuntime.userWorkers.create({servicePath:'/work/worker',memoryLimitMb:256,workerTimeoutMs:150000,cpuTimeSoftLimitMs:2000,cpuTimeHardLimitMs:2000,noModuleCache:false,envVars:[],forceCreate:true});return await worker.fetch(req);}
  catch(e){return Response.json({error:String(e)},{status:546});}
 }
 return new Response('',{status:404});
});
'''

WORKER = r'''import {DistributionBackend,verifyBundle,publish,digest} from '../after.ts';

const backend=new DistributionBackend('http://localhost:9000','synthetic');
async function metric(phase,start,cpu){await fetch('http://localhost:9000/metric',{method:'POST',body:JSON.stringify({metric:phase,elapsed_ms:performance.now()-start,memory:Deno.memoryUsage()})});}
Deno.serve(async req=>{
 const phase=new URL(req.url).searchParams.get('phase')||'bundle',u=await req.json();
 const start=performance.now();let cpu;
 await metric('begin:'+phase,start,cpu);
 const original=backend.object.bind(backend);
 backend.object=async(...args)=>{const t=performance.now();const value=await original(...args);await metric('read:'+args[1],t);return value;};
 try{
  let result;
  if(phase==='bundle')result=await verifyBundle(backend,u);
  else if(phase==='finalize')result=await publish(backend,new Request('http://localhost/content-publish/'+u.id+'/finalize',{method:'POST',headers:{Authorization:'Bearer synthetic'},body:'{}'}));
  else if(phase==='pack')result={hash:digest(await backend.object(u.id,'pack.json',u.objects['pack.json'],true))};
  else if(phase==='sqlite') {await backend.object(u.id,'content.sqlite',u.objects['content.sqlite']);result={ok:true};}
  else throw new Error('Unsupported phase');
  await metric(phase,start,cpu);return Response.json({ok:true,phase,result});
 }catch(e){await metric(phase+':error',start,cpu);return Response.json({code:e.code??'ERROR',error:String(e)},{status:422});}
});
'''

EVENTS = r'''const manager=new globalThis.EventManager();
for await(const event of manager){
  if(event&&event.event_type!=='Log')console.log(JSON.stringify(event));
}
'''

def command(*args):
    return subprocess.run(list(args),capture_output=True,text=True,check=True).stdout


def request(path,data=None):
    req=urllib.request.Request('http://127.0.0.1:54999'+path,
        data=None if data is None else json.dumps(data).encode(),
        headers={'Content-Type':'application/json'},method='GET' if data is None else 'POST')
    try:
        with urllib.request.urlopen(req,timeout=30) as response:return response.status,json.load(response)
    except urllib.error.HTTPError as error:return error.code,json.load(error)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle',type=Path,required=True)
    parser.add_argument('--before-ref',default='0670076')
    args=parser.parse_args();source=args.bundle.resolve()
    files=['content.sqlite','pack.json','registry.json','history_inventory.json','editorial_reviews.json',
           'provenance.json','finalization_report.json','content.manifest.json','reader_report.json']
    original={n:hashlib.sha256((source/n).read_bytes()).hexdigest() for n in files}
    image='public.ecr.aws/supabase/edge-runtime:v1.77.1'
    command('docker','image','inspect',image)  # Fail rather than pull/install.
    root=ROOT/'build/content_edge_resources'/uuid.uuid4().hex
    (root/'bundle').mkdir(parents=True)
    for name in files:shutil.copyfile(source/name,root/'bundle'/name)
    for name,code in [('main',MAIN),('events',EVENTS)]:
        (root/name).mkdir();(root/name/'index.ts').write_text(code,encoding='utf-8')
    (root/'worker').mkdir()
    (root/'before.ts').write_text(command('git','-C',str(ROOT),'show',args.before_ref+':supabase/functions/_shared/content_distribution.ts'),encoding='utf-8')
    shutil.copyfile(ROOT/'supabase/functions/_shared/content_distribution.ts',root/'after.ts')
    shutil.copyfile(ROOT/'supabase/functions/_shared/internal_baseline_source.json',root/'internal_baseline_source.json')
    manifest=json.loads((source/'content.manifest.json').read_text(encoding='utf-8'))
    upload={'id':'11111111-1111-4111-8111-111111111111','lang':'en','channel':'internal',
            'expected_generation':0,'parent_release_id':None,'parent_manifest_sha256':None,
            'draft_manifest':manifest,'created_at':'2026-10-16T00:00:00Z','objects':{}}
    (root/'upload.json').write_text(json.dumps(upload),encoding='utf-8')
    container='sprachapp-resource-'+uuid.uuid4().hex[:8]
    summaries={}
    try:
        for label in ('before','after'):
            (root/'worker/index.ts').write_text(WORKER.replace('../after.ts','../'+label+'.ts'),encoding='utf-8')
            command('docker','run','-d','--pull','never','--name',container,
                '--publish','127.0.0.1:54999:9000','--mount',f'type=bind,source={root},target=/work,readonly',
                image,'start','--main-service','/work/main','--event-worker','/work/events','--policy','oneshot')
            try:
                for _ in range(30):
                    try:
                        if request('/health')[0]==200:break
                    except OSError:time.sleep(.1)
                results=[]
                for index in range(10):
                    _,metadata=request('/metadata')
                    start=time.monotonic();status,response=request('/run?phase=finalize',metadata)
                    result={'call':index+1,'http_status':status,'wall_ms':round((time.monotonic()-start)*1000,1),
                            'state':response.get('result',{}).get('status'),'error':response.get('error')}
                    results.append(result);print(label,json.dumps(result),flush=True)
                    if status!=200:break  # Never automatically retry a failed phase.
                _,metrics=request('/metrics')
            finally:
                command('docker','stop',container)
                logs=command('docker','logs',container)
                command('docker','rm',container)
            events=[]
            for line in logs.splitlines():
                try:event=json.loads(line)
                except ValueError:continue
                if event.get('event_type')=='Shutdown':events.append(event['event'])
            summary={'calls':results,'metrics':metrics,'shutdowns':events,
                     'largest_phase_sample_bytes':max(m['memory']['heapUsed']+m['memory']['external'] for m in metrics)}
            summaries[label]=summary
            (root/(label+'.json')).write_text(json.dumps(summary,indent=2),encoding='utf-8')
            (root/(label+'.log')).write_text(logs,encoding='utf-8')
            print(label,'last shutdown:',json.dumps(events[-1] if events else None),flush=True)
        assert summaries['before']['calls'][-1]['http_status']==546,'Expected old resource failure not reproduced'
        assert summaries['after']['calls'][-1]['state']=='ready','Optimized local verification did not complete'
        assert original=={n:hashlib.sha256((source/n).read_bytes()).hexdigest() for n in files}
        print('Real bundle preserved; local verification passed at 256 MiB / 2000ms CPU. Artifacts:',root)
    finally:
        # Only the uniquely named test container may be removed on failure.
        subprocess.run(['docker','rm','-f',container],capture_output=True)


if __name__=='__main__':main()
