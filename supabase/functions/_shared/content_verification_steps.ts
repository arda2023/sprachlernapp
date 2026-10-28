// One shared implementation for both the reference wrapper and durable stages.
import {ADOPTION, ADOPTION_NOTICE, FILES, supportedProfile, compatibleParentProfile, DistributionBackend, Json, canonical, digest, requireThat, requireEmptyBaselineChannel} from './content_distribution.ts';
import baseline from './internal_baseline_source.json' with {type:'json'};
export const VERIFIER = 'native-v2';
const SHA=/^[0-9a-f]{64}$/;
export function verificationStages(u:Json):string[]{return [...FILES.map((_,i)=>'F'+i),'M','P_full',...(u.draft_manifest.publication_kind===ADOPTION?['P_content']:[]),'H','A'];}
export function finalManifest(u:Json,results:Json):Json {
  requireThat(results.P_full?.sha256&&results.M&&results.H,'VERIFICATION_INCOMPLETE',409);
  if(u.draft_manifest.publication_kind===ADOPTION)requireThat(results.P_content?.checked===true,'VERIFICATION_INCOMPLETE',409);
  const final={...u.draft_manifest,pack_canonical_sha256:results.P_full.sha256,release_id:u.id,channel:u.channel,generation:u.expected_generation+1,
    parent_release_id:u.parent_release_id,parent_manifest_sha256:u.parent_manifest_sha256,created_at:u.created_at};
  delete final.local_only;return final;
}
export async function verifyStage(backend:DistributionBackend,u:Json,stage:string,results:Json):Promise<Json>{
  const read=(name:string)=>backend.object(u.id,name,u.objects[name],true);
  if(/^F[0-8]$/.test(stage)){const name=FILES[Number(stage.slice(1))];await backend.object(u.id,name,u.objects[name]);return {name,...u.objects[name]};}
  if(stage==='M')return await verifyMetadata(backend,u);
  if(stage==='P_full'){
    const pack=await read('pack.json'),m=u.draft_manifest;
  requireThat(pack.lang===u.lang&&pack.release?.version===m.version&&pack.release?.schema_version===m.schema_version&&
    pack.word_registry?.sha256===m.registry_sha256,'PACK_SCOPE');
    return {sha256:digest(pack),has_registry_words:!!pack.word_registry?.snapshot?.words};
  }
  if(stage==='P_content'){
    requireThat(u.draft_manifest.publication_kind===ADOPTION,'VERIFICATION_STAGE',409);
    const pack=await read('pack.json'),m=u.draft_manifest;
    // Only one small metadata object differs; every content row stays bound.
    const content={...pack,release:{...pack.release}};delete content.release.created_at;
    requireThat(digest(content)===baseline.converted_content_sha256&&
      pack.release.created_at===baseline.converted_created_at&&m.sha256===baseline.converted_sqlite_sha256&&
      m.size_bytes===baseline.converted_sqlite_size,'ADOPTION_CONTENT_CHANGED');
    await requireEmptyBaselineChannel(backend);
    return {checked:true};
  }
  if(stage==='H'){
    const v=results.M;requireThat(v,'VERIFICATION_INCOMPLETE',409);
    const registry=await read('registry.json'),inventory=await read('history_inventory.json');
  if(u.parent_release_id){
    const rows=await backend.json('/rest/v1/content_release_catalog?release_id=eq.'+u.parent_release_id);
    requireThat(rows.length===1&&rows[0].lang===u.lang&&rows[0].channel===u.channel&&
      rows[0].manifest_sha256===u.parent_manifest_sha256,'PARENT_CHANGED',409);
    const parent=rows[0];
    if(u.lang!=='en')requireThat(compatibleParentProfile(u.lang,parent.manifest,u.draft_manifest),'PARENT_PROFILE_CHANGED',409);
    requireThat(v.base_sha256===parent.manifest.pack_canonical_sha256,'PARENT_CONTENT_CHANGED',409);
    requireThat(results.P_full.has_registry_words,'REGISTRY_INVALID');
    const oldRegistry=await backend.object(parent.release_id,'registry.json',parent.objects['registry.json'],true);
    requireThat(Array.isArray(oldRegistry.words)&&Array.isArray(registry.words),'REGISTRY_INVALID');
    const newWords=new Map(registry.words.map((w:Json)=>[w.lang+'|'+w.form_norm,w]));
    requireThat(newWords.size===registry.words.length,'REGISTRY_INVALID');
    for(const word of oldRegistry.words)requireThat(canonical(newWords.get(word.lang+'|'+word.form_norm))===canonical(word),'REGISTRY_HISTORY_LOSS');
    const old=await backend.object(parent.release_id,'history_inventory.json',parent.objects['history_inventory.json'],true);
    for(const [table,entries] of Object.entries(old.tables) as [string,Record<string,string>][]){
      for(const [id,hash] of Object.entries(entries)){
        requireThat(inventory.tables[table]?.[id],'HISTORY_LOSS');
        if(['sentences','sentence_tokens','card_sentences','story_context_corrections'].includes(table))requireThat(inventory.tables[table][id]===hash,'CONTEXT_HISTORY_LOSS');
      }
    }
    const snapshots=new Set((inventory.story_source_snapshots??[]).map(canonical));
    for(const source of old.story_source_snapshots??[])requireThat(snapshots.has(canonical(source)),'STORY_HISTORY_LOSS');
  }
    return {checked:true};
  }
  requireThat(stage==='A','VERIFICATION_STAGE',409);
  if(u.draft_manifest.publication_kind===ADOPTION)await requireEmptyBaselineChannel(backend);
  const manifest=finalManifest(u,results);return {manifest,manifest_sha256:digest(manifest)};
}
async function verifyMetadata(backend:DistributionBackend,u:Json):Promise<Json>{
  const read=(name:string)=>backend.object(u.id,name,u.objects[name],true);
  const m=await read('content.manifest.json');requireThat(canonical(m)===canonical(u.draft_manifest),'MANIFEST_CHANGED');
  const report=await read('finalization_report.json'), reviews=await read('editorial_reviews.json');
  const inventory=await read('history_inventory.json'), registry=await read('registry.json');
  const v=report.validation;
  requireThat(m.publication_kind===undefined||m.publication_kind===ADOPTION,'PUBLICATION_KIND');
  const adoption=m.publication_kind===ADOPTION;
  requireThat(report.status==='ok'&&report.history_superset===true&&report.internal_test_pack===true&&
    v?.technical==='valid'&&v.editorial===(adoption?'existing-evidence-only':'approved')&&SHA.test(v.content_sha256)&&
    Array.isArray(v.findings)&&!v.findings.some((f:Json)=>f.severity==='error'),'ATTESTATION_INVALID');
  const unsigned={...v};delete unsigned.sha256;requireThat(digest(unsigned)===v.sha256,'VALIDATION_HASH');
  requireThat(Array.isArray(reviews)&&(adoption?reviews.length===0:reviews.some((r:Json)=>r.decision==='approved'&&r.payload_sha256===v.content_sha256)),'REVIEW_UNBOUND');
  if(u.lang!=='en')requireThat(supportedProfile(u.lang,m)&&reviews.some((r:Json)=>r.decision==='approved'&&
    r.payload_sha256===v.content_sha256&&r.profile_sha256===m.profile_sha256&&
    (m.profile_id==='pt-BR-editorial-v1'?r.editorial_policy==='manual-pt-BR-editorial-v1':
      r.editorial_policy==='ai-editorial-reviewed-v1'&&r.human_review===false&&
      r.user_requested_private_device_test===true&&typeof r.reviewer==='string'&&r.reviewer.trim().length>0)),'REVIEW_PROFILE_UNBOUND');
  requireThat(digest(reviews)===m.editorial_reviews_sha256&&digest(inventory)===m.history_inventory_sha256&&digest(registry)===m.registry_sha256,'SIDECAR_HASH');
  requireThat(inventory.lang===u.lang&&inventory.format_version===1&&inventory.tables,'HISTORY_INVALID');
  if(adoption){
    requireThat(u.lang==='en'&&u.channel==='internal'&&u.expected_generation===0&&
      u.parent_release_id===null&&u.parent_manifest_sha256===null&&m.parent_release_id===null&&
      m.internal_test_pack===true,'ADOPTION_FIRST_ONLY');
    const provenance=await read('provenance.json');
    requireThat(Array.isArray(provenance)&&provenance.length===1,'ADOPTION_INVALID');
    const receipt=provenance[0], expected:Json={kind:ADOPTION,source:baseline.source,version:baseline.version,
      counts:baseline.counts,existing_evidence:baseline.existing_evidence,open_findings:baseline.open_findings,
      notice:ADOPTION_NOTICE,cloud_state:'not_checked'};
    expected.sha256=digest(expected);
    const unsignedReceipt={...receipt};delete unsignedReceipt.confirmation;
    requireThat(canonical(unsignedReceipt)===canonical(expected),'ADOPTION_INVALID');
    const c=receipt.confirmation;
    requireThat(c&&canonical(Object.keys(c).sort())===canonical(['accepted','at','scope'])&&
      c.accepted===true&&c.scope===ADOPTION&&typeof c.at==='string'&&
      /(?:Z|[+-]\d{2}:\d{2})$/.test(c.at)&&Number.isFinite(Date.parse(c.at)),'ADOPTION_CONFIRMATION');
    requireThat(digest(receipt)===m.adoption_sha256&&m.adoption_sha256===report.adoption_sha256&&
      v.content_sha256===baseline.converted_content_sha256&&v.base_sha256===baseline.source.pack_canonical_sha256&&
      canonical(v.findings)==='[]'&&canonical(report.sqlite_counts)===canonical(baseline.counts),'ADOPTION_INVALID');
  }
  if(v.coverage?.expected!==undefined)requireThat(v.coverage.expected===v.coverage.processed&&!v.coverage.conflicting_refs?.length,'INCOMPLETE_DELIVERY');
  return {base_sha256:v.base_sha256??null,adoption};
}
