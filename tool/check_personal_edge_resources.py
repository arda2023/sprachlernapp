"""Full create-learning-card in bounded Supabase Edge Runtime. No cloud calls.
Input directory contains exact private <lang>-catalog.json / <lang>-pack.json.
Copies immutable source from --ref, and mounts only explicit fixture files.
The probe never mounts exported SQLite, account data or credentials.
"""
import argparse, concurrent.futures, hashlib, json, os, pathlib, subprocess, tempfile, time, urllib.request, urllib.error
ROOT=pathlib.Path(__file__).resolve().parents[1]
IMAGE='public.ecr.aws/supabase/edge-runtime:v1.77.1'
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--private-input',type=pathlib.Path,required=True);p.add_argument('--output',type=pathlib.Path,required=True);p.add_argument('--context',default='colima-sprachapp-2c');p.add_argument('--ref',default='90673bb');a=p.parse_args()
 os.umask(0o077);a.output.mkdir(parents=True,exist_ok=True)
 def docker(*args):return subprocess.run(['docker','--context',a.context,*args],capture_output=True,text=True,check=True).stdout
 image=json.loads(docker('image','inspect',IMAGE))[0]
 catalogs=[]
 for lang in ['en','pt-BR']:
  row=json.loads((a.private_input/(lang+'-catalog.json')).read_text());data=(a.private_input/(lang+'-pack.json')).read_bytes();assert hashlib.sha256(data).hexdigest()==row['objects']['pack.json']['sha256'];catalogs.append(row)
 with tempfile.TemporaryDirectory(prefix='2c-edge-',dir=pathlib.Path.home()/'Library/Caches') as temporary:
  work=pathlib.Path(temporary)
  for row in catalogs:(work/(row['lang']+'-pack.json')).write_bytes((a.private_input/(row['lang']+'-pack.json')).read_bytes())
  (work/'catalogs.json').write_text(json.dumps(catalogs))
  for name in ['main','events','worker']:
   (work/name).mkdir();(work/name/'index.ts').write_bytes((ROOT/'tool/personal_edge_probe'/(name+'.ts')).read_bytes())
  files=['create-learning-card/index.ts','_shared/personal_learning.ts','_shared/personal_release.ts','_shared/personal_sentence.ts','_shared/runtime_translation.ts']
  sources={}
  for name in files:
   path='supabase/functions/'+name;data=subprocess.check_output(['git','show',a.ref+':'+path],cwd=ROOT);dest=work/'functions'/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data);sources[path]=hashlib.sha256(data).hexdigest()
  def request(path,payload=None):
   req=urllib.request.Request('http://127.0.0.1:54998'+path,data=None if payload is None else json.dumps(payload).encode(),headers={'Content-Type':'application/json','Authorization':'Bearer synthetic'})
   start=time.monotonic()
   try:
    with urllib.request.urlopen(req,timeout=35) as r:status,data=r.status,json.load(r)
   except urllib.error.HTTPError as e:status,data=e.code,json.load(e)
   return {'status':status,'wall_ms':round(1000*(time.monotonic()-start),1),'error':data.get('error')}
  def body(lang,index):
   r=next(r for r in catalogs if r['lang']==lang);text=('She puts a zorb on the table.' if lang=='en' else 'Ela coloca um zorb na mesa.')+' '+str(index)
   start=text.index('zorb');return {'contract':2,'consent':1,'lang':lang,'text':text,'form':'zorb','start':start,'end':start+4,'candidates':[],'local_candidates':[],'blocked':[],'hints':{},'release':{'release_id':r['release_id'],'manifest_sha256':r['manifest_sha256'],'sqlite_sha256':r['manifest']['sha256']}}
  results=[]
  for scenario in ['cold-en','warm-en','second-language','parallel-cold-en','parallel-cold-two-languages']:
   container='sprachapp-2c-'+scenario
   docker('run','-d','--name',container,'--pull','never','--publish','127.0.0.1:54998:9000','--mount',f'type=bind,source={work},target=/work,readonly',IMAGE,'start','--main-service','/work/main','--event-worker','/work/events','--policy','per_worker')
   calls=[]
   try:
    for _ in range(60):
     try:
      if request('/health')['status']==200:break
     except OSError:time.sleep(.1)
    if scenario.startswith('parallel'):
     langs=['en']*8 if scenario=='parallel-cold-en' else ['en','pt-BR']*4
     with concurrent.futures.ThreadPoolExecutor(8) as executor:calls=list(executor.map(lambda pair:request('/run',body(*pair)),[(lang,i) for i,lang in enumerate(langs)]))
    else:
     langs={'cold-en':['en'],'warm-en':['en','en'],'second-language':['en','pt-BR','en']}[scenario]
     calls=[request('/run',body(lang,i)) for i,lang in enumerate(langs)]
    counts=json.loads(urllib.request.urlopen('http://127.0.0.1:54998/counts').read())
    # Kernel high-water for ENTIRE runtime container, not mislabeled isolate heap.
    peak=docker('exec',container,'cat','/sys/fs/cgroup/memory.peak').strip()
    process_status=docker('exec',container,'cat','/proc/1/status')
    rss_peak=next(int(line.split()[1])*1024 for line in process_status.splitlines() if line.startswith('VmHWM:'))
   finally:
    docker('stop',container);logs=docker('logs',container);docker('rm',container)
   events=[];metrics=[]
   for line in logs.splitlines():
    try:v=json.loads(line)
    except ValueError:continue
    if v.get('event_type') and v['event_type']!='Log':events.append(v)
    if v.get('event_type')=='Log':
     try:
      message=v.get('event',{}).get('msg','');m=json.loads(message)
      if m.get('probe'):metrics.append(m)
     except (ValueError,TypeError):pass
    if v.get('probe'):metrics.append(v)
   row={'scenario':scenario,'calls':calls,'counts':counts,'runtime_process_rss_peak_bytes':rss_peak,'container_memory_peak_bytes':int(peak),'events':events,'metrics':metrics}
   results.append(row);(a.output/(scenario+'.log')).write_text(logs);print(json.dumps(row),flush=True)
  summary={'ref':a.ref,'image_id':image['Id'],'architecture':image['Architecture'],'limits':{'memory_mb':256,'cpu_soft_ms':1000,'cpu_hard_ms':2000,'wall_ms':150000},'sources':sources,'artifacts':[{ 'lang':r['lang'],'release_id':r['release_id'],'pack':r['objects']['pack.json']} for r in catalogs],'simulated_services':['GoTrue response','PostgREST release/claim/finish (no SQL/RLS)','Storage transport (exact published bytes)','Anthropic response; zero provider traffic'],'gateway_jwt_simulated':True,'cloud_pass':False,'runs':results}
  (a.output/'results.json').write_text(json.dumps(summary,indent=2))
if __name__=='__main__':main()
