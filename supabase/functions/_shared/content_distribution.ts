import { createHash } from 'node:crypto';
import baseline from './internal_baseline_source.json' with {type:'json'};

export const ADOPTION = 'internal-baseline-adoption-v1';
const ADOPTION_NOTICE = 'Übernimmt den bereits verwendeten internen Bestand. Damit bestätigst du keine neue sprachliche Gesamtprüfung.';

export const MAX_PACK = 256 * 1024 * 1024;
export const FILES = ['content.sqlite','pack.json','registry.json','history_inventory.json',
  'editorial_reviews.json','provenance.json','finalization_report.json','content.manifest.json','reader_report.json'];
const SHA = /^[0-9a-f]{64}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const PROFILE_SHA = '59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf';
export class DistributionError extends Error {
  constructor(public code: string, public status = 422) { super(code); }
}
export function requireThat(value: unknown, code: string, status = 422): asserts value {
  if (!value) throw new DistributionError(code,status);
}
export function canonical(value: unknown): string {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return '['+value.map(canonical).join(',')+']';
  return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+canonical((value as Record<string,unknown>)[k])).join(',')+'}';
}
export function digest(value: unknown): string { return createHash('sha256').update(canonical(value)).digest('hex'); }
export type Json = Record<string, any>;
export type Descriptor = {sha256:string;size_bytes:number};
export function validateStart(data: Json) {
  requireThat(UUID.test(data.request_id),'REQUEST_ID');
  requireThat(data.lang==='en' && data.channel==='internal','SCOPE_UNSUPPORTED');
  requireThat(Number.isSafeInteger(data.expected_generation)&&data.expected_generation>=0,'GENERATION_INVALID');
  requireThat(data.expected_generation===0 ? data.parent_manifest_sha256===null&&data.parent_release_id===null :
    SHA.test(data.parent_manifest_sha256)&&UUID.test(data.parent_release_id),'PARENT_INVALID');
  const m=data.manifest;
  requireThat(m?.publication_kind===undefined||m.publication_kind===ADOPTION,'PUBLICATION_KIND');
  if(m?.publication_kind===ADOPTION)requireThat(data.expected_generation===0&&
    data.parent_release_id===null&&data.parent_manifest_sha256===null&&m.parent_release_id===null,'ADOPTION_FIRST_ONLY');
  requireThat(m?.format===2&&m.lang===data.lang&&m.schema_version===5&&m.translation_lang==='de'&&
    m.profile_id==='en-legacy-v1'&&m.profile_sha256===PROFILE_SHA&&m.internal_test_pack===true&&
    m.min_reader_version===5&&canonical(m.required_features)===canonical(['immutable-contexts-v1']), 'MANIFEST_INCOMPATIBLE');
  requireThat(typeof m.version==='string'&&/^[A-Za-z0-9._-]{1,100}$/.test(m.version),'VERSION_INVALID');
  requireThat(data.objects&&canonical(Object.keys(data.objects).sort())===canonical([...FILES].sort()),'OBJECT_SET_INVALID');
  for(const name of FILES){
    const d=data.objects[name];
    requireThat(SHA.test(d?.sha256)&&Number.isSafeInteger(d.size_bytes)&&d.size_bytes>0&&
      d.size_bytes <= (name==='content.sqlite'?MAX_PACK:64*1024*1024),'OBJECT_LIMIT');
  }
  requireThat(m.sha256===data.objects['content.sqlite'].sha256&&m.size_bytes===data.objects['content.sqlite'].size_bytes&&
    m.pack_json_sha256===data.objects['pack.json'].sha256,'MANIFEST_HASH_MISMATCH');
}

// Fetch is injected for isolated HTTP tests. Production uses native TLS fetch.
export class DistributionBackend {
  constructor(public url:string, private key:string, public fetcher:typeof fetch=fetch) {
    const u=new URL(url);requireThat(u.protocol==='https:'||(['127.0.0.1','localhost','kong'].includes(u.hostname)&&u.protocol==='http:'),'SERVER_CONFIG',503);
  }
  async request(path:string, method='GET', body?:unknown, bearer?:string):Promise<Response> {
    return await this.fetcher(this.url+path,{method,headers:{apikey:this.key,Authorization:'Bearer '+(bearer||this.key),
      'Content-Type':'application/json',Prefer:'return=representation'},body:body===undefined?undefined:JSON.stringify(body),redirect:'error'});
  }
  async json(path:string,method='GET',body?:unknown):Promise<any> {
    const response=await this.request(path,method,body);
    if(!response.ok){
      let code='';try{code=(await response.json()).code;}catch{ /* redact remote detail */ }
      throw new DistributionError(['40001','23505'].includes(code)?'CONFLICT':'BACKEND_UNAVAILABLE',['40001','23505'].includes(code)?409:503);
    }
    return await response.json();
  }
  async actor(request:Request):Promise<string> {
    const header=request.headers.get('Authorization');requireThat(header!==null&&header.startsWith('Bearer '),'AUTH_REQUIRED',401);
    const response=await this.request('/auth/v1/user','GET',undefined,header.slice(7));
    requireThat(response.ok,'AUTH_REQUIRED',401);const user=await response.json();requireThat(UUID.test(user.id),'AUTH_REQUIRED',401);return user.id;
  }
  async publisher(actor:string){const rows=await this.json('/rest/v1/content_publishers?user_id=eq.'+actor+'&select=user_id');requireThat(rows.length===1,'PUBLISHER_REQUIRED',403);}
  async reader(actor:string,lang:string,channel:string){
    requireThat(/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/.test(lang)&&channel==='internal','SCOPE_INVALID');
    const rows=await this.json(`/rest/v1/content_readers?user_id=eq.${actor}&lang=eq.${encodeURIComponent(lang)}&channel=eq.${channel}&select=user_id`);
    requireThat(rows.length===1,'READER_REQUIRED',403);
  }
  async upload(id:string,actor:string):Promise<Json>{
    requireThat(UUID.test(id),'UPLOAD_ID');const rows=await this.json('/rest/v1/content_release_uploads?id=eq.'+id);
    requireThat(rows.length===1&&rows[0].owner_id===actor,'UPLOAD_FORBIDDEN',403);return rows[0];
  }
  async patch(id:string,values:Json,status?:string){
    return await this.json('/rest/v1/content_release_uploads?id=eq.'+id+(status?'&status=eq.'+status:''),'PATCH',values);
  }
  async object(id:string,name:string,descriptor:Descriptor,read=false):Promise<any> {
    requireThat(UUID.test(id)&&FILES.includes(name),'OBJECT_KEY');
    const response=await this.request(`/storage/v1/object/authenticated/content-private/${id}/${name}`);
    requireThat(response.ok&&response.body,'OBJECT_MISSING',409);
    const hash=createHash('sha256'), chunks:Uint8Array[]=[];let size=0;
    for await(const chunk of response.body){
      size+=chunk.byteLength;requireThat(size<=descriptor.size_bytes&&size<=MAX_PACK,'OBJECT_SIZE');hash.update(chunk);
      if(read){requireThat(size<=64*1024*1024,'JSON_LIMIT');chunks.push(chunk);}
    }
    requireThat(size===descriptor.size_bytes&&hash.digest('hex')===descriptor.sha256,'OBJECT_HASH');
    if(read){const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
      try{return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));}catch{throw new DistributionError('OBJECT_JSON');}}
  }
}

export async function verifyBundle(backend:DistributionBackend,u:Json):Promise<Json>{
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
  requireThat(digest(reviews)===m.editorial_reviews_sha256&&digest(inventory)===m.history_inventory_sha256&&digest(registry)===m.registry_sha256,'SIDECAR_HASH');
  requireThat(inventory.lang===u.lang&&inventory.format_version===1&&inventory.tables,'HISTORY_INVALID');
  const pack=await read('pack.json');
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
    const content=structuredClone(pack);delete content.release.created_at;
    requireThat(digest(content)===baseline.converted_content_sha256&&
      pack.release.created_at===baseline.converted_created_at&&m.sha256===baseline.converted_sqlite_sha256&&
      m.size_bytes===baseline.converted_sqlite_size,'ADOPTION_CONTENT_CHANGED');
    await requireEmptyBaselineChannel(backend);
  }
  requireThat(pack.lang===u.lang&&pack.release?.version===m.version&&pack.release?.schema_version===m.schema_version&&
    pack.word_registry?.sha256===m.registry_sha256,'PACK_SCOPE');
  if(v.coverage?.expected!==undefined)requireThat(v.coverage.expected===v.coverage.processed&&!v.coverage.conflicting_refs?.length,'INCOMPLETE_DELIVERY');
  if(u.parent_release_id){
    const rows=await backend.json('/rest/v1/content_release_catalog?release_id=eq.'+u.parent_release_id);
    requireThat(rows.length===1&&rows[0].lang===u.lang&&rows[0].channel===u.channel&&
      rows[0].manifest_sha256===u.parent_manifest_sha256,'PARENT_CHANGED',409);
    const parent=rows[0];
    requireThat(v.base_sha256===parent.manifest.pack_canonical_sha256,'PARENT_CONTENT_CHANGED',409);
    requireThat(pack.word_registry?.snapshot?.words,'REGISTRY_INVALID');
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
  const final={...m,local_only:undefined,pack_canonical_sha256:digest(pack),release_id:u.id,channel:u.channel,generation:u.expected_generation+1,
    parent_release_id:u.parent_release_id,parent_manifest_sha256:u.parent_manifest_sha256,created_at:u.created_at};
  delete final.local_only;return final;
}

async function requireEmptyBaselineChannel(backend:DistributionBackend){
  const rows=await backend.json('/rest/v1/content_channels?lang=eq.en&channel=eq.internal');
  requireThat(rows.length===0||(rows.length===1&&rows[0].generation===0&&
    rows[0].release_id===null&&rows[0].manifest_sha256===null),'ADOPTION_CHANNEL_OCCUPIED',409);
}

export async function publish(backend:DistributionBackend,request:Request):Promise<Json>{
  const actor=await backend.actor(request);await backend.publisher(actor);
  const parts=new URL(request.url).pathname.split('/');const index=parts.indexOf('content-publish');const tail=parts.slice(index+1);
  if(request.method==='GET'&&tail[0]==='channel'){
    const lang=new URL(request.url).searchParams.get('lang');requireThat(lang==='en','PROFILE_UNSUPPORTED');
    const rows=await backend.json('/rest/v1/content_channels?lang=eq.en&channel=eq.internal');
    if(!rows.length||!rows[0].release_id)return {generation:0,release_id:null,manifest_sha256:null,manifest:null};
    const catalog=await backend.json('/rest/v1/content_release_catalog?release_id=eq.'+rows[0].release_id);
    requireThat(catalog.length===1,'CATALOG_INVALID',503);return {...rows[0],manifest:catalog[0].manifest};
  }
  if(request.method==='GET'&&tail.length===1){const u=await backend.upload(tail[0],actor);return {upload_id:u.id,status:u.status,failure_code:u.failure_code,verified:Object.keys(u.verified_objects??{})};}
  requireThat(request.method==='POST','METHOD',405);
  const chunks:Uint8Array[]=[];let length=0;
  if(request.body)for await(const chunk of request.body){length+=chunk.length;requireThat(length<=1024*1024,'REQUEST_LIMIT',413);chunks.push(chunk);}
  const bytes=new Uint8Array(length);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
  const data=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
  requireThat(data!==null&&typeof data==='object'&&!Array.isArray(data),'REQUEST_OBJECT');
  if(tail[0]==='start'){
    validateStart(data);
    if(data.manifest.publication_kind===ADOPTION)await requireEmptyBaselineChannel(backend);
    let rows=await backend.json(`/rest/v1/content_release_uploads?owner_id=eq.${actor}&request_id=eq.${data.request_id}`);
    let u=rows[0];
    if(!u){
      const record={id:crypto.randomUUID(),owner_id:actor,request_id:data.request_id,lang:data.lang,channel:data.channel,
        expected_generation:data.expected_generation,parent_manifest_sha256:data.parent_manifest_sha256,parent_release_id:data.parent_release_id,
        draft_manifest:data.manifest,objects:data.objects};
      try{rows=await backend.json('/rest/v1/content_release_uploads','POST',record);u=rows[0];}
      catch(e){if(!(e instanceof DistributionError)||e.status!==409)throw e;u=(await backend.json(`/rest/v1/content_release_uploads?owner_id=eq.${actor}&request_id=eq.${data.request_id}`))[0];}
    }
    requireThat(u&&canonical(u.objects)===canonical(data.objects)&&canonical(u.draft_manifest)===canonical(data.manifest)&&
      u.expected_generation===data.expected_generation&&u.parent_manifest_sha256===data.parent_manifest_sha256&&
      u.parent_release_id===data.parent_release_id&&u.lang===data.lang&&u.channel===data.channel,'REQUEST_CONFLICT',409);
    const uploads:Json={};
    if(['uploading','verifying'].includes(u.status))for(const name of FILES){
      if(u.verified_objects?.[name])continue;
      // upsert false is essential: outstanding upload tokens must never overwrite verified bytes.
      const signed=await backend.json(`/storage/v1/object/upload/sign/content-private/${u.id}/${name}`,'POST',{upsert:false});
      uploads[name]=signed.url;
    }
    return {upload_id:u.id,status:u.status,uploads};
  }
  const u=await backend.upload(tail[0],actor);
  if(tail[1]==='finalize'){
    if(['ready','published'].includes(u.status))return {upload_id:u.id,status:u.status};
    requireThat(u.status!=='failed'&&Date.parse(u.expires_at)>Date.now(),'UPLOAD_EXPIRED',409);
    // One object per call: verified progress survives function deadline/retry.
    const verified={...(u.verified_objects??{})};const next=FILES.find(name=>!verified[name]);
    if(next){
      await backend.patch(u.id,{status:'verifying'});
      await backend.object(u.id,next,u.objects[next]);verified[next]=u.objects[next];
      await backend.patch(u.id,{verified_objects:verified});
      return {upload_id:u.id,status:'verifying',verified:Object.keys(verified)};
    }
    try{
      const manifest=await verifyBundle(backend,u);
      await backend.patch(u.id,{status:'ready',manifest,manifest_sha256:digest(manifest)},'verifying');
      return {upload_id:u.id,status:'ready'};
    }catch(e){if(e instanceof DistributionError&&e.status===422)await backend.patch(u.id,{status:'failed',failure_code:e.code});throw e;}
  }
  if(tail[1]==='commit'){
    requireThat(UUID.test(data.request_id),'REQUEST_ID');
    if(u.draft_manifest?.publication_kind===ADOPTION){
      requireThat(u.expected_generation===0&&u.parent_release_id===null&&u.parent_manifest_sha256===null&&
        data.expected_generation===0&&data.expected_manifest_sha256===null,'ADOPTION_FIRST_ONLY');
      // A completed retry is resolved by the existing audit request ID in SQL.
      // The SQL transaction locks the channel and checks generation AND parents.
      if(u.status!=='published')await requireEmptyBaselineChannel(backend);
    }
    return await backend.json('/rest/v1/rpc/publish_content_release','POST',{upload_id:u.id,
      expected_generation:data.expected_generation,expected_manifest_sha256:data.expected_manifest_sha256,
      request_id:data.request_id,verified_actor_id:actor});
  }
  throw new DistributionError('NOT_FOUND',404);
}

export async function release(backend:DistributionBackend,request:Request):Promise<Json>{
  const actor=await backend.actor(request),url=new URL(request.url);
  if(request.method==='GET'){
    const lang=url.searchParams.get('lang')??'',channel=url.searchParams.get('channel')??'';
    await backend.reader(actor,lang,channel);
    const generation=Number(url.searchParams.get('generation')??'0');requireThat(Number.isSafeInteger(generation)&&generation>=0,'GENERATION_INVALID');
    const rows=await backend.json(`/rest/v1/content_channels?lang=eq.${encodeURIComponent(lang)}&channel=eq.${channel}`);
    if(!rows.length||rows[0].generation<=generation)return {update:null};
    const catalog=await backend.json('/rest/v1/content_release_catalog?release_id=eq.'+rows[0].release_id);
    requireThat(catalog.length===1,'CATALOG_INVALID',503);
    return {update:{manifest:catalog[0].manifest,manifest_sha256:catalog[0].manifest_sha256,objects:catalog[0].objects}};
  }
  const parts=url.pathname.split('/'),index=parts.indexOf('content-release'),id=parts[index+1];
  requireThat(request.method==='POST'&&UUID.test(id)&&parts[index+2]==='download','NOT_FOUND',404);
  const rows=await backend.json('/rest/v1/content_release_catalog?release_id=eq.'+id);requireThat(rows.length===1,'NOT_FOUND',404);
  const r=rows[0];await backend.reader(actor,r.lang,r.channel);
  const urls:Json={};for(const name of ['content.sqlite','history_inventory.json']){
    const signed=await backend.json(`/storage/v1/object/sign/content-private/${id}/${name}`,'POST',{expiresIn:120});urls[name]=signed.signedURL;
  }
  return {manifest_sha256:r.manifest_sha256,urls};
}
export function handler(kind:'publish'|'release',backend:DistributionBackend){
  return async(request:Request)=>{
    try{return Response.json(await (kind==='publish'?publish:release)(backend,request),{headers:{'Cache-Control':'no-store'}});}
    catch(e){const known=e instanceof DistributionError;return Response.json({code:known?e.code:'REQUEST_FAILED'},
      {status:known?e.status:400,headers:{'Cache-Control':'no-store'}});}
  };
}
