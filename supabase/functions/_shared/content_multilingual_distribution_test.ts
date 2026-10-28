import {PROFILES,FILES,DistributionBackend,DistributionError,validateStart,supportedProfile,compatibleParentProfile,digest} from './content_distribution.ts';
import {verifyStage} from './content_verification_steps.ts';
function assert(value:unknown):asserts value {if(!value)throw Error('assertion failed');}
async function rejects(action:()=>unknown,code:string){try{await action();}catch(e){assert(e instanceof DistributionError&&e.code===code);return;}throw Error('expected '+code);}
const id='11111111-1111-4111-8111-111111111111';
const load=()=>Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(n=>[n,JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/private_release/'+n,import.meta.url)))]));
Deno.test('all new profiles admit exact internal manifests and reject foreign or altered profiles',async()=>{
  for(const lang of ['pt-BR','nb','it','es']){
    const p=PROFILES[lang],m={...load()['content.manifest.json'],lang,profile_id:p.id,profile_sha256:p.sha256,parent_release_id:null};
    const objects=Object.fromEntries(FILES.map(n=>[n,{sha256:'0'.repeat(64),size_bytes:1}]));
    objects['content.sqlite']={sha256:m.sha256,size_bytes:m.size_bytes};objects['pack.json'].sha256=m.pack_json_sha256;
    const input={request_id:id,lang,channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,manifest:m,objects};
    validateStart(input);
    await rejects(()=>validateStart({...input,channel:'public'}),'SCOPE_UNSUPPORTED');
    await rejects(()=>validateStart({...input,manifest:{...m,profile_sha256:'0'.repeat(64)}}),'MANIFEST_INCOMPATIBLE');
    await rejects(()=>validateStart({...input,manifest:{...m,profile_id:PROFILES.en.id,profile_sha256:PROFILES.en.sha256}}),'MANIFEST_INCOMPATIBLE');
    await rejects(()=>validateStart({...input,manifest:{...m,publication_kind:'internal-baseline-adoption-v1'}}),'ADOPTION_FIRST_ONLY');
  }
});
Deno.test('historical Portuguese profile is retained and migration is only forwards',()=>{
  const old={profile_id:'pt-BR-editorial-v1',profile_sha256:'7c59364c0d1ef562ee5a6a679b7d895e0ebec6bf2ad47d8eae56afdcba87fe32'};
  const next={profile_id:PROFILES['pt-BR'].id,profile_sha256:PROFILES['pt-BR'].sha256};
  assert(supportedProfile('pt-BR',old));assert(compatibleParentProfile('pt-BR',old,next));
  assert(!compatibleParentProfile('pt-BR',next,old));assert(!supportedProfile('pt',old));
  assert(!compatibleParentProfile('pt-BR',{...old,profile_sha256:'0'.repeat(64)},next));
});
Deno.test('new profile reviews bind truthful AI scope, payload and profile without human approval',async()=>{
  for(const lang of ['pt-BR','nb','it','es']){
    const files=load(),p=PROFILES[lang],m=files['content.manifest.json'];
    Object.assign(m,{lang,profile_id:p.id,profile_sha256:p.sha256});
    files['history_inventory.json'].lang=lang;m.history_inventory_sha256=digest(files['history_inventory.json']);
    const review=files['editorial_reviews.json'][0];
    Object.assign(review,{profile_sha256:p.sha256,editorial_policy:'ai-editorial-reviewed-v1',human_review:false,
      user_requested_private_device_test:true,reviewer:'Codex AI editorial review'});
    const rebind=()=>m.editorial_reviews_sha256=digest(files['editorial_reviews.json']);rebind();
    class Fixture extends DistributionBackend {override async object(_id:string,name:string){return structuredClone(files[name]);}}
    const backend=new Fixture('https://synthetic.invalid','unused',()=>{throw Error('network forbidden');});
    const u={id,lang,draft_manifest:m,objects:{}};
    await verifyStage(backend,u,'M',{});
    for(const [key,value] of Object.entries({profile_sha256:'0'.repeat(64),editorial_policy:'manual-'+p.id,human_review:true,user_requested_private_device_test:false,reviewer:''})){
      const old=review[key];review[key]=value;rebind();
      await rejects(()=>verifyStage(backend,u,'M',{}),'REVIEW_PROFILE_UNBOUND');review[key]=old;rebind();
    }
    const old=review.payload_sha256;review.payload_sha256='0'.repeat(64);rebind();
    await rejects(()=>verifyStage(backend,u,'M',{}),'REVIEW_UNBOUND');review.payload_sha256=old;
  }
});
