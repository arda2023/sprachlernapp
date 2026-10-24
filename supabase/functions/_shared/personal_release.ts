import { createHash } from 'node:crypto';
import { TranslationError } from './runtime_translation.ts';
type Json = Record<string, any>;
function requireValue(v:unknown):asserts v { if(!v) throw new TranslationError('REFERENCE_INVALID',422); }
// Same frozen NFC + U+001F + SHA256/16-byte contract as sprachpipe.ids.
export function contentId(table:string,...keys:string[]):string {
  requireValue(keys.every(k=>typeof k==='string'));
  return createHash('sha256').update([table,...keys.map(k=>k.normalize('NFC'))].join('\x1f')).digest('hex').slice(0,32);
}
export function releaseCards(pack:Json):Json[] {
  requireValue(['en','pt-BR'].includes(pack.lang)&&Array.isArray(pack.cards)&&Array.isArray(pack.senses)&&Array.isArray(pack.lemmas));
  const lemmas=new Map(pack.lemmas.map((l:Json)=>[l.ref,{...l,id:contentId('lemmas',pack.lang,l.lemma,l.pos)}]));
  const senses=new Map(pack.senses.map((s:Json)=>{const l=lemmas.get(s.lemma) as Json;requireValue(l);return [s.ref,{...s,l,id:contentId('senses',l.id,s.sense_key)}];}));
  const functions=new Map<string,string>();
  for(const f of pack.form_targets??[])if(!f.removed_in){requireValue(!functions.has(f.card));functions.set(f.card,f.function);}
  const result=pack.cards.map((c:Json)=>{
    const s=senses.get(c.sense) as Json;requireValue(s);
    const id=c.identity_function==null?contentId('cards',pack.lang,c.form,s.id):contentId('form_cards',pack.lang,c.form,s.id,c.identity_function);
    return {id,form:c.form,lang:pack.lang,lemma:s.l.lemma,pos:s.l.pos,sense_id:s.id,
      function:functions.get(c.ref)??c.identity_function??null,
      definition_de:s.definition_de??s.gloss_de,gloss_de:c.translation_de??s.gloss_de,
      form_detail:c.form_label_de??'',retired:!!(c.removed_in||s.removed_in||s.l.removed_in)};
  });
  requireValue(new Set(result.map((c:Json)=>c.id)).size===result.length);
  return result;
}
// Stores only a compact immutable reference projection, never user text.
// Auth/reader scope and catalog equality are checked BEFORE every cache access.
export class PersonalReleaseCache {
  private entries=new Map<string,Promise<Json[]>>();
  async candidates(url:string,key:string,row:Json,fetcher:typeof fetch,signal:AbortSignal):Promise<Json[]> {
    const d=row.objects?.['pack.json'];
    requireValue(/^[a-f0-9]{64}$/.test(d?.sha256)&&d.sha256===row.manifest?.pack_json_sha256&&Number.isSafeInteger(d.size_bytes)&&d.size_bytes>0&&d.size_bytes<=64*1024*1024);
    const identity=[url,row.release_id,row.manifest_sha256,d.sha256].join(':');
    const prior=this.entries.get(identity);if(prior)return prior;
    while(this.entries.size>=2)this.entries.delete(this.entries.keys().next().value!);
    const pending=(async()=>{
      const response=await fetcher(`${url}/storage/v1/object/authenticated/content-private/${row.release_id}/pack.json`,{headers:{apikey:key,Authorization:'Bearer '+key},signal,redirect:'error'});
      requireValue(response.ok&&response.body);
      const reader=response.body!.getReader(),hash=createHash('sha256'),decoder=new TextDecoder('utf-8',{fatal:true});let size=0,source='';
      const abort=()=>{void reader.cancel().catch(()=>{});};signal.addEventListener('abort',abort,{once:true});
      try {while(true){signal.throwIfAborted();const r=await reader.read();signal.throwIfAborted();if(r.done)break;
        size+=r.value.length;requireValue(size<=d.size_bytes);hash.update(r.value);source+=decoder.decode(r.value,{stream:true});}
        source+=decoder.decode();requireValue(size===d.size_bytes&&hash.digest('hex')===d.sha256);
        const pack=JSON.parse(source);requireValue(pack.lang===row.lang&&pack.release?.version===row.manifest.version&&pack.release?.schema_version===5);
        return releaseCards(pack);
      } finally {signal.removeEventListener('abort',abort);void reader.cancel().catch(()=>{});reader.releaseLock();}
    })();this.entries.set(identity,pending);
    try{return await pending;}catch(e){if(this.entries.get(identity)===pending)this.entries.delete(identity);throw e;}
  }
}
