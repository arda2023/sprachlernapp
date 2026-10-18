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

Deno.test('real synthetic BR first and followup bundles retain scope, profile review and history',async()=>{
  const load=(version:string)=>Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(n=>[n,JSON.parse(Deno.readTextFileSync(new URL('../../../test/fixtures/portuguese_release/'+version+'/'+n,import.meta.url)))]));
  const first=load('first'),second=load('second');
  const nextId='33333333-3333-4333-8333-333333333333';
  class BR extends DistributionBackend {
    parent:any; current=first;
    constructor(){super('https://synthetic.invalid','test',()=>{throw Error('network forbidden');});}
    override async object(objectId:string,name:string){return structuredClone((objectId===id?first:this.current)[name]);}
    override async json(){return this.parent?[this.parent]:[];}
  }
  const b=new BR();const u:any={...upload(),lang:'pt-BR',draft_manifest:first['content.manifest.json']};
  async function stages(u:any){const r:any={};for(const stage of ['M','P_full','H','A'])r[stage]=await verifyStage(b,u,stage,r);return r;}
  const r=await stages(u),m=r.A.manifest;
  assert(m.generation===1&&m.parent_release_id===null&&m.lang==='pt-BR');
  b.parent={release_id:id,lang:'pt-BR',channel:'internal',manifest_sha256:r.A.manifest_sha256,manifest:m,objects:{}};
  b.current=second;
  const next={...u,id:nextId,expected_generation:1,parent_release_id:id,parent_manifest_sha256:r.A.manifest_sha256,draft_manifest:second['content.manifest.json']};
  const follow=await stages(next);assert(follow.A.manifest.generation===2&&follow.A.manifest.parent_release_id===id);
  async function reject(code:string,action:()=>Promise<unknown>){try{await action();}catch(e){assert(e instanceof DistributionError&&e.code===code);return;}throw Error('expected '+code);}
  b.parent.lang='en';await reject('PARENT_CHANGED',()=>stages(next));b.parent.lang='pt-BR';
  const profile=b.parent.manifest.profile_sha256;b.parent.manifest.profile_sha256='0'.repeat(64);
  await reject('PARENT_PROFILE_CHANGED',()=>stages(next));b.parent.manifest.profile_sha256=profile;
  const review=second['editorial_reviews.json'][0];const old=review.profile_sha256;review.profile_sha256='0'.repeat(64);
  await reject('REVIEW_PROFILE_UNBOUND',()=>stages(next));review.profile_sha256=old;
  const table=Object.keys(first['history_inventory.json'].tables).find(t=>Object.keys(first['history_inventory.json'].tables[t]).length)!;
  const key=Object.keys(first['history_inventory.json'].tables[table])[0];delete second['history_inventory.json'].tables[table][key];
  // Rebind the sidecar so the append-only history check, not the byte check, rejects it.
  second['content.manifest.json'].history_inventory_sha256=digest(second['history_inventory.json']);
  await reject('HISTORY_LOSS',()=>stages(next));
});
