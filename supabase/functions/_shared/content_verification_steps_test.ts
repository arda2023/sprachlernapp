import {DistributionBackend,DistributionError,FILES,digest,verificationStatus} from './content_distribution.ts';
import {verificationStages,verifyStage,finalManifest} from './content_verification_steps.ts';
function assert(v:unknown):asserts v{if(!v)throw Error('assertion failed');}
const id='11111111-1111-4111-8111-111111111111';
const files=Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(n=>[n,JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/private_release/'+n,import.meta.url)))]));
const upload=()=>({id,lang:'en',channel:'internal',expected_generation:0,parent_release_id:null,parent_manifest_sha256:null,
  draft_manifest:structuredClone(files['content.manifest.json']),objects:{},created_at:'2026-10-18T00:00:00Z'});
class Fixture extends DistributionBackend {
  reads:string[]=[];
  constructor(){super('https://synthetic.invalid','test',()=>{throw Error('network forbidden');});}
  override async object(_id:string,name:string){this.reads.push(name);return structuredClone(files[name]);}
}
Deno.test('native stages use one pack read, normal content hash is not required, completion reads no objects',async()=>{
  const u=upload(),b=new Fixture(),results:any={};
  assert(verificationStages(u).length===13&&!verificationStages(u).includes('P_content'));
  results.M=await verifyStage(b,u,'M',results);assert(!b.reads.includes('pack.json'));
  b.reads=[];results.P_full=await verifyStage(b,u,'P_full',results);assert(b.reads.join()==='pack.json');
  b.reads=[];results.H=await verifyStage(b,u,'H',results);assert(b.reads.join()==='registry.json,history_inventory.json');
  b.reads=[];const final=await verifyStage(b,u,'A',results);assert(b.reads.length===0);
  assert(final.manifest_sha256===digest(final.manifest)&&final.manifest.pack_canonical_sha256===digest(files['pack.json']));
  try{await verifyStage(b,u,'P_content',results);throw Error('accepted');}catch(e){assert(e instanceof DistributionError&&e.code==='VERIFICATION_STAGE');}
});
Deno.test('metadata-only completion rejects missing required results',()=>{
  for(const results of [{},{M:{},P_full:{sha256:'a'}},{M:{},H:{}}]){
    try{finalManifest(upload(),results);throw Error('accepted');}catch(e){assert(e instanceof DistributionError&&e.code==='VERIFICATION_INCOMPLETE');}
  }
  const adoption=upload();adoption.draft_manifest.publication_kind='internal-baseline-adoption-v1';
  try{finalManifest(adoption,{M:{},H:{},P_full:{sha256:'a'}});throw Error('accepted');}catch(e){assert(e instanceof DistributionError&&e.code==='VERIFICATION_INCOMPLETE');}
});
Deno.test('status contains server progress and marks expiry even after completion',()=>{
  const u=upload();
  const expired=verificationStatus(u,{state:'complete',stages:['M','A'],results:{M:{},A:{}},expires_at:'2000-01-01T00:00:00Z'});
  assert(expired.status==='resume_required'&&expired.processed===2&&expired.total===2);
  const active=verificationStatus(u,{state:'verifying',stages:['F0','M'],results:{F0:{}},expires_at:'2099-01-01T00:00:00Z'});
  assert(active.processed===1&&active.next_stage==='M'&&active.not_required[0]==='P_content');
  assert(!('results' in active)&&!('lease' in active));
});
