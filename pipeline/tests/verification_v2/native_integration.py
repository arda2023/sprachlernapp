"""Full native-v2 integration in the dedicated sprachapp_native_v2 local stack.

Never targets the user's sprachapp stack or any cloud URL. Cleans only this
dedicated test database and nonce-owned Storage/users. Requires Docker/CLI.
"""
import argparse
import concurrent.futures
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import uuid

from local_probe import Local, command, ROOT, HERE, FILES, IMAGE
from check_content_edge_resources import EVENTS

STACK = ROOT/'build/native_verification/stack'
DB = 'supabase_db_sprachapp_native_v2'


def sql(text):
    return command('docker','exec','-i',DB,'psql','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-At',input=text)


def digest(value):
    return hashlib.sha256(json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()


class Dedicated(Local):
    def __init__(self):
        assert 'project_id = "sprachapp_native_v2"' in (STACK/'supabase/config.toml').read_text()
        cfg=json.loads(command(shutil.which('supabase'),'status','--workdir',str(STACK),'-o','json'))
        assert cfg['API_URL']=='http://127.0.0.1:55421'
        self.url=cfg['API_URL'];self.secret=cfg['SERVICE_ROLE_KEY'];self.anon=cfg['ANON_KEY'];self.count=0


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--bundle',type=Path,required=True)
    parser.add_argument('--flows-only',action='store_true',help='Repeat resource/parent flows after a guard change; negative evidence is a separate full run')
    args=parser.parse_args();source=args.bundle.resolve()
    original={n:hashlib.sha256((source/n).read_bytes()).hexdigest() for n in FILES}
    local=Dedicated();nonce=uuid.uuid4().hex;root=ROOT/'build/native_verification'/nonce;root.mkdir()
    for name in ['content-publish/index.ts','_shared/content_distribution.ts','_shared/content_verification_steps.ts','_shared/internal_baseline_source.json']:
        out=root/'functions'/name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'supabase/functions'/name,out)
    for name,code in [('main',(HERE/'main.ts').read_text()),('probe',(HERE/'native_worker.ts').read_text()),('events',EVENTS)]:
        (root/name).mkdir();(root/name/'index.ts').write_text(code,encoding='utf8')
    (root/'oracle').mkdir();(root/'oracle/content_distribution.ts').write_bytes(subprocess.check_output(['git','show','fe6e7ad:supabase/functions/_shared/content_distribution.ts'],cwd=ROOT))
    shutil.copyfile(ROOT/'supabase/functions/_shared/internal_baseline_source.json',root/'oracle/internal_baseline_source.json')
    container='native-v2-'+nonce[:10];users=[];keys=[];evidence={'local_only':True,'cloud_pass':False,'original_hashes':original,'policies':[],'checks':[]}
    start=time.monotonic()

    def expect(status,expected,label):
        if status not in expected:raise AssertionError(label+' HTTP '+str(status))

    def user():
        email='native-'+uuid.uuid4().hex+'@example.test';password=uuid.uuid4().hex+'Aa1!'
        status,u=local.http('POST','/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True});expect(status,[200,201],'user');users.append(u['id'])
        status,session=local.http('POST','/auth/v1/token?grant_type=password',{'email':email,'password':password},key=local.anon);expect(status,[200],'login')
        expect(local.http('POST','/rest/v1/content_publishers',{'user_id':u['id']})[0],[201],'publisher')
        return u['id'],session['access_token']

    def edge(method,path,body=None,token=None,headers=None):
        return local.http(method,path,body,token=token or access,key=local.anon,port=54998,headers=headers)

    def rpc(uid,op,data):
        response=local.http('POST','/rest/v1/rpc/content_verification_transition',{'p_actor':actor,'p_upload':uid,'p_op':op,'p_input':data})
        if response[0]==400:assert response[1].get('code')=='PV409',response[1].get('code')
        return response

    def launch(policy):
        env=dict(os.environ,SUPABASE_SERVICE_ROLE_KEY=local.secret,PROBE_MODE='probe',PROBE_POLICY=policy,PROBE_RPC='unused')
        command('docker','run','-d','--pull','never','--name',container,'--network','supabase_network_sprachapp_native_v2',
            '--publish','127.0.0.1:54998:9000','--mount',f'type=bind,source={root},target=/work,readonly',
            '-e','SUPABASE_SERVICE_ROLE_KEY','-e','PROBE_MODE','-e','PROBE_POLICY','-e','PROBE_RPC',IMAGE,
            'start','--main-service','/work/main','--event-worker','/work/events','--policy',policy,env=env)
        for _ in range(40):
            try:
                if edge('GET','/health')[0]==200:return
            except OSError:pass
            time.sleep(.1)
        raise AssertionError('gateway')

    def stop(label):
        command('docker','stop',container);logs=command('docker','logs',container);command('docker','rm',container)
        (root/(label+'.log')).write_text(logs,encoding='utf8')
        events=[]
        for line in logs.splitlines():
            try:v=json.loads(line)
            except ValueError:continue
            if v.get('event_type') in ['Boot','Shutdown','UncaughtException']:events.append(v)
        return events

    def fixture(directory,generation=0,parent=None,expired=False):
        manifest=json.loads((directory/'content.manifest.json').read_text(encoding='utf8'))
        objects={n:{'sha256':hashlib.sha256((directory/n).read_bytes()).hexdigest(),'size_bytes':(directory/n).stat().st_size} for n in FILES}
        body={'request_id':str(uuid.uuid4()),'lang':'en','channel':'internal','expected_generation':generation,
              'parent_release_id':parent['manifest']['release_id'] if parent else None,'parent_manifest_sha256':parent['manifest_sha256'] if parent else None,
              'manifest':manifest,'objects':objects}
        if expired:
            uid=str(uuid.uuid4());record={k:v for k,v in body.items() if k!='manifest'}
            record.update(id=uid,owner_id=actor,draft_manifest=manifest,expires_at='2000-01-01T00:00:00Z')
            expect(local.http('POST','/rest/v1/content_release_uploads',record)[0],[201],'expired fixture')
            uploads={}
            for name in FILES:
                status,signed=local.http('POST','/storage/v1/object/upload/sign/content-private/'+uid+'/'+name,{'upsert':False});expect(status,[200],'sign fixture');uploads[name]=signed['url']
        else:
            status,value=edge('POST','/content-publish/start',body);expect(status,[200],'start');uid=value['upload_id'];uploads=value['uploads']
        for name,path in uploads.items():
            expect(local.http('PUT','/storage/v1'+path,(directory/name).read_bytes())[0],[200],'local upload');keys.append(uid+'/'+name)
        return uid,body

    def drive(uid,label):
        status,oracle=edge('POST','/oracle',{'upload_id':uid});expect(status,[200],'old validator oracle')
        records=[]
        for _ in range(16):
            status,before=edge('GET','/content-publish/'+uid);expect(status,[200],'status')
            phase=before['next_stage'];begin=time.monotonic()
            cpu=int(command('docker','exec',container,'cat','/sys/fs/cgroup/cpu.stat').split('usage_usec ')[1].split()[0])
            status,result=edge('POST','/content-publish/'+uid+'/finalize',{})
            endcpu=int(command('docker','exec',container,'cat','/sys/fs/cgroup/cpu.stat').split('usage_usec ')[1].split()[0])
            expect(status,[200],'finalize '+str(phase));assert result['processed']==before['processed']+1
            row={'phase':phase,'status':result['status'],'processed':result['processed'],'total':result['total'],
                 'wall_ms':round((time.monotonic()-begin)*1000,1),'container_cpu_ms':round((endcpu-cpu)/1000,1)}
            records.append(row);print(label,json.dumps(row),flush=True)
            if result['status']=='ready':break
        assert result['status']=='ready'
        status,rows=local.http('GET','/rest/v1/content_release_uploads?id=eq.'+uid);expect(status,[200],'read ready')
        assert rows[0]['manifest']==oracle,'old/new complete manifest differs'
        assert rows[0]['manifest_sha256']==digest(oracle),'final hash differs'
        return records,result

    def publish(uid,body):
        request={'request_id':str(uuid.uuid4()),'expected_generation':body['expected_generation'],'expected_manifest_sha256':body['parent_manifest_sha256']}
        status,result=edge('POST','/content-publish/'+uid+'/commit',request);expect(status,[200],'publish')
        assert edge('POST','/content-publish/'+uid+'/commit',request)==(status,result),'commit retry'
        return result

    def following(parent,number):
        directory=root/('normal-'+str(number));directory.mkdir()
        for name in FILES:shutil.copyfile(source/name,directory/name)
        pack=json.loads((directory/'pack.json').read_text(encoding='utf8'));pack['release']['version']='native_local_followup_'+str(number)
        manifest=json.loads((directory/'content.manifest.json').read_text(encoding='utf8'))
        manifest.pop('publication_kind',None);manifest.pop('adoption_sha256',None);manifest['version']=pack['release']['version']
        report=json.loads((directory/'finalization_report.json').read_text(encoding='utf8'));report.pop('adoption_sha256',None)
        v=report['validation'];v.update(editorial='approved',content_sha256=digest(pack),base_sha256=parent['manifest']['pack_canonical_sha256']);v.pop('sha256',None);v['sha256']=digest(v)
        reviews=[{'decision':'approved','payload_sha256':v['content_sha256'],'note':'SYNTHETIC LOCAL TEST ONLY; no human review claimed'}]
        manifest['editorial_reviews_sha256']=digest(reviews)
        for name,value in [('pack.json',pack),('editorial_reviews.json',reviews),('finalization_report.json',report),('provenance.json',[])]:
            (directory/name).write_text(json.dumps(value,ensure_ascii=False,separators=(',',':')),encoding='utf8')
        manifest['pack_json_sha256']=hashlib.sha256((directory/'pack.json').read_bytes()).hexdigest()
        (directory/'content.manifest.json').write_text(json.dumps(manifest),encoding='utf8')
        return directory

    try:
        # Only this dedicated, otherwise empty test project is accepted.
        assert local.http('GET','/rest/v1/content_release_catalog?select=release_id')[1]==[]
        actor,access=user();outsider,other=user()
        for policy in ['oneshot','per_worker']:
            launch(policy)
            try:
                uid,body=fixture(source)
                expect(edge('POST','/content-publish/'+uid+'/finalize',{},token=other)[0],[403],'wrong owner')
                expect(edge('POST','/content-publish/'+uid+'/commit',{'request_id':str(uuid.uuid4()),'expected_generation':0,'expected_manifest_sha256':None})[0],[503,409],'incomplete commit')
                first,_=drive(uid,policy+' adoption');parent=publish(uid,body)
                normal=following(parent,len(evidence['policies'])*2+1)
                child,childbody=fixture(normal,1,parent)
                second,state=drive(child,policy+' normal');assert state['not_required']==['P_content'] and state['total']==13
                published=publish(child,childbody)
                if policy=='oneshot' and not args.flows_only:
                    resumed_dir=following(published,100)
                    expired,expired_body=fixture(resumed_dir,2,published,expired=True)
                    expect(edge('POST','/content-publish/'+expired+'/finalize',{})[0],[409],'expired finalize')
                    assert edge('POST','/content-publish/start',expired_body)[1]['uploads']=={},'expired start unexpectedly issued URLs'
                    expect(edge('POST','/content-publish/'+expired+'/resume',{})[0],[409],'resume consent')
                    resume={'accepted':True,'scope':'resume-same-upload-native-v2','request_id':str(uuid.uuid4())}
                    status,resumed=edge('POST','/content-publish/'+expired+'/resume',resume);expect(status,[200],'resume')
                    assert edge('POST','/content-publish/'+expired+'/resume',resume)[1]==resumed
                    denied=local.http('POST','/rest/v1/rpc/content_verification_transition',
                        {'p_actor':actor,'p_upload':expired,'p_op':'claim','p_input':{}},token=access,key=local.anon)[0]
                    expect(denied,[401,403,404],'client RPC write blocked')
                    expect(local.http('PATCH','/rest/v1/content_verification_runs?id=eq.'+resumed['run_id'],{'state':'complete'})[0],[401,403],'service direct run write blocked')
                    with concurrent.futures.ThreadPoolExecutor(2) as pool:
                        claims=list(pool.map(lambda _:rpc(expired,'claim',{}),range(2)))
                    assert sorted(s for s,_ in claims)==[200,400]
                    old=next(v for s,v in claims if s==200)
                    def finish_data(run,stage,result):
                        return {'run_id':run['id'],'lease':run['lease'],'revision':run['revision'],'stage':stage,
                                'result':result,'result_sha256':digest(result)}
                    # Deterministic lease-expiry fixture; actual worker crash below uses real expiry.
                    sql("update public.content_verification_runs set lease_until=clock_timestamp()-interval '1 second' where id='"+old['id']+"';")
                    status,new=rpc(expired,'claim',{});expect(status,[200],'reclaim')
                    result={'name':'content.sqlite',**expired_body['objects']['content.sqlite']}
                    expect(rpc(expired,'finish',finish_data(old,'F0',result))[0],[400],'stale lease')
                    data=finish_data(new,'F0',result);status,finished=rpc(expired,'finish',data);expect(status,[200],'finish')
                    assert rpc(expired,'finish',data)==(status,finished),'lost response idempotence'
                    expect(rpc(expired,'finish',{**data,'result':{'changed':True}})[0],[400],'changed retry')
                    sql("update public.content_verification_runs set identity=identity||'{\"probe\":true}' where id='"+new['id']+"';")
                    expect(edge('GET','/content-publish/'+expired)[0],[409],'identity change')
                    sql("update public.content_verification_runs set identity=identity-'probe' where id='"+new['id']+"';")
                    expect(local.http('DELETE','/rest/v1/content_publishers?user_id=eq.'+actor)[0],[204],'revoke')
                    expect(edge('GET','/content-publish/'+expired)[0],[403],'revoked publisher')
                    expect(local.http('POST','/rest/v1/content_publishers',{'user_id':actor})[0],[201],'restore test right')
                    expect(edge('POST','/content-publish/'+expired+'/finalize',{},headers={'x-local-abort-after-claim':'yes'})[0],[546],'actual worker abort')
                    assert edge('GET','/content-publish/'+expired)[1]['processed']==1
                    aborted=local.http('GET','/rest/v1/content_verification_runs?id=eq.'+new['id'])[1][0]
                    deadline=datetime.fromisoformat(aborted['lease_until']).timestamp()
                    print('Actual abort: no progress; waiting for the configured 90-second lease, no finalize retry.',flush=True)
                    while time.time()<=deadline+.1:time.sleep(.25)
                    expect(edge('POST','/content-publish/'+expired+'/finalize',{})[0],[200],'recover after real expiry')
                    expect(rpc(expired,'finish',finish_data(aborted,'F1',{'name':'pack.json',**expired_body['objects']['pack.json']}))[0],[400],'aborted old worker finish')
                    # Explicit new run invalidates all previous results and identifiers.
                    resume['request_id']=str(uuid.uuid4())
                    status,newrun=edge('POST','/content-publish/'+expired+'/resume',resume);expect(status,[200],'new run')
                    assert newrun['run_id']!=resumed['run_id'] and newrun['processed']==0
                    expect(rpc(expired,'finish',data)[0],[400],'old run cannot finish new run')
                    third,_=drive(expired,'expired upload resumed')
                    sql("update public.content_verification_runs set expires_at=clock_timestamp()-interval '1 second' where id='"+newrun['run_id']+"';")
                    assert edge('GET','/content-publish/'+expired)[1]['status']=='resume_required'
                    expect(edge('POST','/content-publish/'+expired+'/commit',{'request_id':str(uuid.uuid4()),'expected_generation':2,'expected_manifest_sha256':published['manifest_sha256']})[0],[409,503],'expired ready cannot commit')
                    resume['request_id']=str(uuid.uuid4());expect(edge('POST','/content-publish/'+expired+'/resume',resume)[0],[200],'resume completed expired run')
                    drive(expired,'expired ready reverified');publish(expired,expired_body)
                    assert local.http('GET','/rest/v1/content_release_uploads?id=eq.'+expired)[1][0]['expires_at'].startswith('2000-01-01')
                    # A fully checked competing child of the old actual parent cannot win CAS.
                    sibling,sibling_body=fixture(normal,1,parent);drive(sibling,'stale channel sibling')
                    expect(edge('POST','/content-publish/'+sibling+'/commit',{'request_id':str(uuid.uuid4()),'expected_generation':1,'expected_manifest_sha256':parent['manifest_sha256']})[0],[409],'generation/parent CAS')
                    evidence['checks']+=['explicit audited same-upload resume; original expiry unchanged','no upload URLs for expired upload',
                        'client RPC and direct run writes denied','concurrent claims: one winner','stale lease and changed retry rejected',
                        'lost finish response idempotent','identity mutation rejected','rights revocation checked',
                        'actual CPU abort: HTTP546/no progress; real 90-second lease expiry recovery','old run finish rejected after resume',
                        'expired completed run cannot commit; explicit resume/reverify/publish succeeds','actual competing child loses generation/parent CAS']
                metrics=edge('GET','/metrics')[1]
                evidence['policies'].append({'policy':policy,'adoption':first,'normal':second,'metrics':metrics,'normal_parent_actual':parent['manifest']['release_id'],
                                             'normal_release_actual':published['manifest']['release_id']})
            finally:
                events=stop(policy)
                if evidence['policies']:evidence['policies'][-1]['events']=events
            # Only dedicated fixtures: no change to the user's existing local project.
            sql('truncate public.content_verification_runs,public.content_release_catalog,public.content_channels,public.content_publish_audit,public.content_release_uploads cascade;')
        evidence['checks']+=['old/new manifests equal for adoption and real parent followup in both policies','explicit isolated publish and idempotent retry','wrong owner rejected','incomplete publish rejected','normal P_content explicitly not required']
        assert original=={n:hashlib.sha256((source/n).read_bytes()).hexdigest() for n in FILES}
    finally:
        subprocess.run(['docker','rm','-f',container],capture_output=True)
        sql('truncate public.content_verification_runs,public.content_release_catalog,public.content_channels,public.content_publish_audit,public.content_release_uploads cascade;')
        for key in keys:expect(local.http('DELETE','/storage/v1/object/content-private',{'prefixes':[key]})[0],[200],'cleanup object')
        for user_id in users:
            local.http('DELETE','/rest/v1/content_publishers?user_id=eq.'+user_id)
            expect(local.http('DELETE','/auth/v1/admin/users/'+user_id)[0],[200],'cleanup user')
        evidence.update(elapsed_seconds=round(time.monotonic()-start,2),driver_requests=local.count)
        (root/'results.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
        print('Dedicated fixtures cleaned; evidence:',root,flush=True)


if __name__=='__main__':main()
