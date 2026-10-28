import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {PersonalReleaseCache,releaseCards,contentId} from './personal_release.ts';
const pack={lang:'en',release:{version:'old',schema_version:5},lemmas:[{ref:'go',lemma:'go',pos:'VERB'}],senses:[{ref:'motion',lemma:'go',sense_key:'motion',gloss_de:'gehen'}],cards:[{ref:'went',form:'went',sense:'motion',translation_de:'ging'}],form_targets:[{card:'went',function:'past'}]};
test('immutable release projection preserves legacy ID and explicit form function',()=>{
 const c=releaseCards(pack)[0];
 const sense=contentId('senses',contentId('lemmas','en','go','VERB'),'motion');
 assert.equal(c.id,contentId('cards','en','went',sense));assert.equal(c.function,'past');
 assert.notEqual(c.id,releaseCards({...pack,cards:[{...pack.cards[0],identity_function:'past'}]})[0].id);
 assert.equal(releaseCards({...pack,cards:[{...pack.cards[0],removed_in:'new'}]})[0].retired,true);
});
test('older immutable release uses its own artifact, hashes checked once and projection reused',async()=>{
 const bytes=JSON.stringify(pack),sha=createHash('sha256').update(bytes).digest('hex');
 const row={release_id:'12345678-1234-4234-8234-123456789abc',lang:'en',manifest_sha256:'a'.repeat(64),manifest:{version:'old',pack_json_sha256:sha},objects:{'pack.json':{sha256:sha,size_bytes:Buffer.byteLength(bytes)}}};
 let downloads=0;const fetcher:typeof fetch=async(url)=>{downloads++;assert.match(String(url),/12345678-1234-4234-8234-123456789abc\/pack.json$/);return new Response(bytes);};
 const cache=new PersonalReleaseCache(),signal=new AbortController().signal;
 const a=await cache.candidates('https://synthetic.invalid','synthetic',row,fetcher,signal);
 assert.deepEqual(await cache.candidates('https://synthetic.invalid','synthetic',row,fetcher,signal),a);assert.equal(downloads,1);
 await assert.rejects(new PersonalReleaseCache().candidates('https://synthetic.invalid','synthetic',row,async()=>new Response(bytes.replace('went','sent')),signal));
 await assert.rejects(cache.candidates('https://synthetic.invalid','synthetic',{...row,objects:{'pack.json':{sha256:'f'.repeat(64),size_bytes:bytes.length}}},fetcher,signal));
});
