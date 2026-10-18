import {DistributionBackend,DistributionError,handler,validateStart,verifyBundle,digest,FILES,ADOPTION} from './content_distribution.ts';
import {createHash} from 'node:crypto';
function assert(value:unknown,message='assertion failed'):asserts value{if(!value)throw new Error(message);}
async function rejects(action:()=>unknown,code:string){try{await action();}catch(e){assert(e instanceof DistributionError&&e.code===code,`expected ${code}, got ${e}`);return;}throw new Error('expected rejection '+code);}
const id='11111111-1111-4111-8111-111111111111';
const actor='22222222-2222-4222-8222-222222222222';
const fixture=()=>Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(name=>[name,JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/private_release/'+name,import.meta.url)))]));
Deno.test('bounded canonical hashing preserves canonical bytes including Unicode and large fields',()=>{
  // Independent old canonical implementation remains the compatibility oracle.
  const old=(value:any):string=>value===null||typeof value!=='object'?JSON.stringify(value):
    Array.isArray(value)?'['+value.map(old).join(',')+']':
    '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+old(value[k])).join(',')+'}';
  for(const value of [null,true,123,-0,1.25,{},[],{z:'ä → 𐐀 😀 \\ \n',a:[1,null,false]},
    {payload:'😀x'.repeat(12000),nested:Array.from({length:1000},(_,i)=>({z:i,a:'é'}))}]){
    assert(digest(value)===createHash('sha256').update(old(value)).digest('hex'));
  }
});
Deno.test('streamed JSON validates split UTF-8, size and byte hash before accepting content',async()=>{
  const bytes=new TextEncoder().encode('{"text":"ä → 😀"}');
  const descriptor={sha256:createHash('sha256').update(bytes).digest('hex'),size_bytes:bytes.length};
  const backend=new DistributionBackend('https://synthetic.invalid','unused',async()=>new Response(new ReadableStream({
    start(controller){for(const byte of bytes)controller.enqueue(Uint8Array.of(byte));controller.close();}
  })));
  assert((await backend.object(id,'pack.json',descriptor,true)).text==='ä → 😀');
  await rejects(()=>backend.object(id,'pack.json',{...descriptor,sha256:'0'.repeat(64)},true),'OBJECT_HASH');
  await rejects(()=>backend.object(id,'pack.json',{...descriptor,size_bytes:1},true),'OBJECT_SIZE');
  const invalid=new DistributionBackend('https://synthetic.invalid','unused',async()=>new Response(Uint8Array.of(255)));
  await rejects(()=>invalid.object(id,'pack.json',{sha256:'0'.repeat(64),size_bytes:1},true),'OBJECT_JSON');
});
Deno.test('finalize requires JSON object before accessing an existing normal or adoption upload',async()=>{
  for(const kind of [undefined,'internal-baseline-adoption-v1']){
    let uploadReads=0,checked=0;
    class ExistingUpload extends DistributionBackend {
      override async actor(){return actor;}
      override async publisher(){}
      override async upload(uploadId:string,owner:string){
        assert(uploadId===id&&owner===actor);uploadReads++;
        return {id,owner_id:actor,status:'uploading',expires_at:'2099-01-01T00:00:00Z',
          draft_manifest:{publication_kind:kind},verified_objects:{},objects:{'content.sqlite':{sha256:'0'.repeat(64),size_bytes:1}}};
      }
      override async patch(){return [];}
      override async json(path:string,_method?:string,body?:any){
        assert(path.endsWith('/content_verification_transition'));
        const run={id,verifier:'native-v2',stage:'F0',revision:1,lease:actor,
          expires_at:'2099-01-01T00:00:00Z',stages:['F0','M'],results:{},state:'verifying'};
        if(body.p_op==='finish')run.results={F0:body.p_input.result};
        return run;
      }
      override async object(_id:string,name:string){assert(name==='content.sqlite');checked++;}
    }
    const backend=new ExistingUpload('https://synthetic.invalid','unused',()=>{throw new Error('Network forbidden');});
    const handle=handler('publish',backend),url='https://synthetic.invalid/content-publish/'+id+'/finalize';
    const empty=await handle(new Request(url,{method:'POST'}));
    assert(empty.status===400&&(await empty.json()).code==='REQUEST_FAILED');
    assert(uploadReads===0&&checked===0);
    for(const body of ['null','[]']){
      const invalid=await handle(new Request(url,{method:'POST',body}));
      assert(invalid.status===422&&(await invalid.json()).code==='REQUEST_OBJECT');
    }
    const valid=await handle(new Request(url,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}));
    const result=await valid.json();assert(valid.status===200&&result.status==='verifying');
    assert(Number(uploadReads)===1&&Number(checked)===1&&result.processed===1&&result.total===2);
  }
});
Deno.test('no JWT, invalid JWT and absent publisher are rejected before publication',async()=>{
  let reads=0;
  const backend=new DistributionBackend('https://synthetic.invalid','server-only',async(url)=>{reads++;return String(url).endsWith('/auth/v1/user')?Response.json({id:actor}):Response.json([]);});
  const handle=handler('publish',backend);
  assert((await handle(new Request('https://synthetic.invalid/content-publish/start',{method:'POST',body:'{}'}))).status===401);assert(reads===0);
  assert((await handle(new Request('https://synthetic.invalid/content-publish/start',{method:'POST',headers:{Authorization:'Bearer synthetic'},body:'{}'}))).status===403);
  const bad=new DistributionBackend('https://synthetic.invalid','server-only',async()=>new Response('',{status:401}));
  assert((await handler('release',bad)(new Request('https://synthetic.invalid/content-release?lang=en&channel=internal',{headers:{Authorization:'Bearer expired'}}))).status===401);
});
Deno.test('reader allowlist is scoped to requested language; no private metadata anonymously',async()=>{
  const paths:string[]=[];
  const backend=new DistributionBackend('https://synthetic.invalid','server-only',async(url)=>{paths.push(String(url));return String(url).endsWith('/auth/v1/user')?Response.json({id:actor}):Response.json([]);});
  const result=await handler('release',backend)(new Request('https://synthetic.invalid/content-release?lang=qaa&channel=internal',{headers:{Authorization:'Bearer synthetic'}}));
  assert(result.status===403);assert(paths.some(p=>p.includes('lang=eq.qaa')));assert(!paths.some(p=>p.includes('content_channels')));
});
Deno.test('actual synthetic export attestation, manifest and editorial hash are verified',async()=>{
  const files=fixture();
  class FixtureBackend extends DistributionBackend {
    override async object(_id:string,name:string){return structuredClone(files[name]);}
  }
  const backend=new FixtureBackend('https://synthetic.invalid','server-only');
  const u={id,lang:'en',channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,draft_manifest:files['content.manifest.json'],objects:{},created_at:'2026-10-16T00:00:00Z'};
  const manifest=await verifyBundle(backend,u);assert(manifest.release_id===id&&manifest.generation===1&&manifest.local_only===undefined);
  files['editorial_reviews.json'][0].payload_sha256='0'.repeat(64);
  await rejects(()=>verifyBundle(backend,u),'REVIEW_UNBOUND');
});
Deno.test('streamed storage objects reject missing, excessive and incorrect bytes',async()=>{
  const bytes=new TextEncoder().encode('synthetic');
  const backend=new DistributionBackend('https://synthetic.invalid','server-only',async()=>new Response(bytes));
  await rejects(()=>backend.object(id,'content.sqlite',{sha256:'0'.repeat(64),size_bytes:bytes.length}),'OBJECT_HASH');
  await rejects(()=>backend.object(id,'content.sqlite',{sha256:'0'.repeat(64),size_bytes:1}),'OBJECT_SIZE');
  await rejects(()=>backend.object('../x','content.sqlite',{sha256:'0'.repeat(64),size_bytes:1}),'OBJECT_KEY');
});
Deno.test('manifest scope, parent CAS and immutable complete object set are mandatory',async()=>{
  const m=fixture()['content.manifest.json'];
  const objects=Object.fromEntries(FILES.map(name=>[name,{sha256:'0'.repeat(64),size_bytes:1}]));
  objects['content.sqlite']={sha256:m.sha256,size_bytes:m.size_bytes};objects['pack.json']={sha256:m.pack_json_sha256,size_bytes:1};
  const valid={request_id:id,lang:'en',channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,manifest:m,objects};
  validateStart(valid);
  await rejects(()=>validateStart({...valid,lang:'qaa'}),'SCOPE_UNSUPPORTED');
  await rejects(()=>validateStart({...valid,expected_generation:1}),'PARENT_INVALID');
  await rejects(()=>validateStart({...valid,manifest:{...m,profile_id:'unknown'}}),'MANIFEST_INCOMPATIBLE');
  await rejects(()=>validateStart({...valid,objects:{...objects,'unexpected.json':objects['pack.json']}}),'OBJECT_SET_INVALID');
  assert(digest({b:2,a:1})===digest({a:1,b:2}));
});

Deno.test('baseline adoption only admits English internal generation zero and known kind',async()=>{
  const m={...fixture()['content.manifest.json'],publication_kind:ADOPTION,parent_release_id:null};
  const objects=Object.fromEntries(FILES.map(name=>[name,{sha256:'0'.repeat(64),size_bytes:1}]));
  objects['content.sqlite']={sha256:m.sha256,size_bytes:m.size_bytes};objects['pack.json']={sha256:m.pack_json_sha256,size_bytes:1};
  const valid={request_id:id,lang:'en',channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,manifest:m,objects};
  validateStart(valid);
  await rejects(()=>validateStart({...valid,expected_generation:1,parent_release_id:actor,parent_manifest_sha256:'0'.repeat(64)}),'ADOPTION_FIRST_ONLY');
  await rejects(()=>validateStart({...valid,parent_release_id:actor}),'PARENT_INVALID');
  await rejects(()=>validateStart({...valid,manifest:{...m,publication_kind:'skip-review'}}),'PUBLICATION_KIND');
  await rejects(()=>validateStart({...valid,lang:'de'}),'SCOPE_UNSUPPORTED');
  await rejects(()=>validateStart({...valid,channel:'public'}),'SCOPE_UNSUPPORTED');
  await rejects(()=>validateStart({...valid,manifest:{...m,internal_test_pack:false}}),'MANIFEST_INCOMPATIBLE');
  class Occupied extends DistributionBackend {
    override async actor(){return actor;}
    override async publisher(){}
    override async json(path:string){assert(path.includes('content_channels'));return [{generation:1,release_id:actor,manifest_sha256:'0'.repeat(64)}];}
  }
  const response=await handler('publish',new Occupied('https://synthetic.invalid','test'))(new Request(
    'https://synthetic.invalid/content-publish/start',{method:'POST',body:JSON.stringify(valid)}));
  assert(response.status===409&&(await response.json()).code==='ADOPTION_CHANNEL_OCCUPIED');
});

Deno.test('BR allowlist and publisher channel are exact and independent; reader grant is separate',async()=>{
  const m=JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/portuguese_release/first/content.manifest.json',import.meta.url)));
  const objects=Object.fromEntries(FILES.map(name=>[name,{sha256:'0'.repeat(64),size_bytes:1}]));
  objects['content.sqlite']={sha256:m.sha256,size_bytes:m.size_bytes};objects['pack.json']={sha256:m.pack_json_sha256,size_bytes:1};
  const valid={request_id:id,lang:'pt-BR',channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,manifest:m,objects};
  validateStart(valid);
  for(const lang of ['pt','pt-PT','pt-br','constructor'])await rejects(()=>validateStart({...valid,lang}),'SCOPE_UNSUPPORTED');
  await rejects(()=>validateStart({...valid,manifest:{...m,profile_id:'en-legacy-v1'}}),'MANIFEST_INCOMPATIBLE');
  await rejects(()=>validateStart({...valid,manifest:{...m,profile_sha256:'0'.repeat(64)}}),'MANIFEST_INCOMPATIBLE');
  await rejects(()=>validateStart({...valid,manifest:{...m,publication_kind:ADOPTION}}),'ADOPTION_FIRST_ONLY');
  const paths:string[]=[];
  class Channels extends DistributionBackend {
    override async actor(){return actor;}
    override async publisher(){}
    override async json(path:string){paths.push(path);return [];}
  }
  const b=new Channels('https://synthetic.invalid','unused',()=>{throw Error('network forbidden');});
  const result=await handler('publish',b)(new Request('https://synthetic.invalid/content-publish/channel?lang=pt-BR'));
  assert(result.status===200&&(await result.json()).generation===0);
  assert(paths[0].includes('lang=eq.pt-BR')&&!paths[0].includes('lang=eq.en'));
  const reader=await handler('release',b)(new Request('https://synthetic.invalid/content-release?lang=pt-BR&channel=internal'));
  assert(reader.status===403&&(await reader.json()).code==='READER_REQUIRED');
});

Deno.test('BR publication retains explicit resume, run lease and commit CAS forwarding',async()=>{
  const calls:any[]=[];let conflict=false;
  class Guarded extends DistributionBackend {
    override async actor(){return actor;}
    override async publisher(){}
    override async upload(){return {id,lang:'pt-BR',channel:'internal',status:'verifying',expected_generation:1,
      parent_release_id:actor,parent_manifest_sha256:'a'.repeat(64),draft_manifest:{},objects:{}};}
    override async json(path:string,_method?:string,body?:any){
      calls.push({path,body});
      if(path.endsWith('/publish_content_release')){
        assert(body.upload_id===id&&body.verified_actor_id===actor&&body.expected_generation===1&&body.expected_manifest_sha256==='a'.repeat(64));
        if(conflict)throw new DistributionError('CONFLICT',409);
        return {generation:2};
      }
      assert(path.endsWith('/content_verification_transition')&&body.p_actor===actor&&body.p_upload===id);
      const run={id:actor,verifier:'native-v2',stage:'F0',revision:7,lease:id,state:'verifying',results:{},expires_at:'2099-01-01T00:00:00Z'};
      if(body.p_op==='finish')assert(body.p_input.run_id===actor&&body.p_input.lease===id&&body.p_input.revision===7&&body.p_input.stage==='F0');
      return run;
    }
    override async object(){}
  }
  const b=new Guarded('https://synthetic.invalid','unused',()=>{throw Error('network forbidden');});
  const call=(action:string,data:any)=>handler('publish',b)(new Request('https://synthetic.invalid/content-publish/'+id+'/'+action,{method:'POST',body:JSON.stringify(data)}));
  assert((await call('resume',{})).status===409&&calls.length===0);
  assert((await call('resume',{accepted:true,scope:'resume-same-upload-native-v2',request_id:id})).status===200);
  assert((await call('finalize',{})).status===200);
  const data={expected_generation:1,expected_manifest_sha256:'a'.repeat(64),request_id:id};
  assert((await call('commit',data)).status===200);conflict=true;
  assert((await call('commit',data)).status===409);
});
