// Explicit local integration check: first run the real isolated build documented
// in docs/content-editor-initial-release.md. Never reads an editor user workspace.
import {DistributionBackend,DistributionError,verifyBundle,FILES,canonical} from './content_distribution.ts';

let result:any;
try{result=JSON.parse(Deno.readTextFileSync(new URL('../../../build/baseline_adoption/real-result.json',import.meta.url)));}
catch(e){if(!(e instanceof Deno.errors.NotFound))throw e;}
if(result&&result.synthetic_confirmation_only!==true)throw new Error('Isolated synthetic receipt required');
const files=result?Object.fromEntries(FILES.filter(n=>n.endsWith('.json')).map(name=>
  [name,JSON.parse(Deno.readTextFileSync(result.bundle+'/'+name))])):{};
const integration=(name:string,fn:()=>Promise<void>)=>Deno.test({name,fn,ignore:!result});
const id='11111111-1111-4111-8111-111111111111';
function assert(value:unknown):asserts value{if(!value)throw new Error('assertion failed');}
class Local extends DistributionBackend {
  occupied=false;
  constructor(){super('https://synthetic.invalid','unused',()=>{throw new Error('Network forbidden');});}
  override async object(_id:string,name:string){return structuredClone(files[name]);}
  override async json(path:string){assert(path.includes('content_channels'));return this.occupied?[{generation:1}]:[];}
}
const upload=()=>({id,lang:'en',channel:'internal',expected_generation:0,parent_release_id:null,
  parent_manifest_sha256:null,draft_manifest:files['content.manifest.json'],objects:result.objects,created_at:'2026-10-16T00:00:00Z'});
async function rejects(action:()=>unknown,code:string){
  try{await action();}catch(e){assert(e instanceof DistributionError&&e.code===code);return;}
  throw new Error('expected '+code);
}
integration('real source adoption verifies without a draft review; no network',async()=>{
  const final=await verifyBundle(new Local(),upload());
  assert(final.generation===1&&final.parent_release_id===null&&final.publication_kind==='internal-baseline-adoption-v1');
  assert(files['editorial_reviews.json'].length===0);
  assert(Object.keys(files['finalization_report.json'].sqlite_counts).length===23);
});
integration('source evidence, confirmation, findings, content and SQLite tampering are blocked',async()=>{
  const original=structuredClone(files);
  async function mutate(change:()=>void,code:string){
    try{change();await rejects(()=>verifyBundle(new Local(),upload()),code);}
    finally{for(const name of Object.keys(files))files[name]=structuredClone(original[name]);}
  }
  await mutate(()=>{files['provenance.json']=[];},'ADOPTION_INVALID');
  await mutate(()=>{files['provenance.json'][0].source.pack_bytes_sha256='0'.repeat(64);},'ADOPTION_INVALID');
  await mutate(()=>{files['provenance.json'][0].open_findings=[];},'ADOPTION_INVALID');
  await mutate(()=>{files['provenance.json'][0].confirmation.accepted=false;},'ADOPTION_CONFIRMATION');
  await mutate(()=>{files['pack.json'].cards[0].translation_de='injected';},'ADOPTION_CONTENT_CHANGED');
  await mutate(()=>{files['pack.json'].sentence_tokens[0].context_gloss_de='injected';},'ADOPTION_CONTENT_CHANGED');
  await mutate(()=>{files['content.manifest.json'].sha256='0'.repeat(64);},'ADOPTION_CONTENT_CHANGED');
  await mutate(()=>{files['editorial_reviews.json']=[{decision:'approved'}];},'REVIEW_UNBOUND');
  assert(canonical(files)===canonical(original));
});
integration('real adoption cannot finalize on occupied channel or changed parents',async()=>{
  const backend=new Local();backend.occupied=true;
  await rejects(()=>verifyBundle(backend,upload()),'ADOPTION_CHANNEL_OCCUPIED');
  await rejects(()=>verifyBundle(new Local(),{...upload(),expected_generation:1}),'ADOPTION_FIRST_ONLY');
  await rejects(()=>verifyBundle(new Local(),{...upload(),parent_release_id:id}),'ADOPTION_FIRST_ONLY');
});
