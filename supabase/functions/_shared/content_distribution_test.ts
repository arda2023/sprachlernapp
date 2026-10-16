import {DistributionBackend,DistributionError,handler,validateStart,verifyBundle,digest,FILES,ADOPTION} from './content_distribution.ts';
function assert(value:unknown,message='assertion failed'):asserts value{if(!value)throw new Error(message);}
async function rejects(action:()=>unknown,code:string){try{await action();}catch(e){assert(e instanceof DistributionError&&e.code===code,`expected ${code}, got ${e}`);return;}throw new Error('expected rejection '+code);}
const id='11111111-1111-4111-8111-111111111111';
const actor='22222222-2222-4222-8222-222222222222';
const fixture=()=>Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(name=>[name,JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/private_release/'+name,import.meta.url)))]));
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
