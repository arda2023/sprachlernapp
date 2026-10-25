// Actual PostgreSQL RPCs + production handler, synthetic auth/pack/model only.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {PersonalLearningBackend,personalHandler} from '../supabase/functions/_shared/personal_learning.ts';
export async function retryProbe(db) {
 const actor='2c100000-0000-4000-8000-000000000001';
 await db.exec(`insert into auth.users(id,email) values('${actor}','probe@example.test'); insert into public.content_readers(user_id,channel,lang) values('${actor}','internal','en');`);
 const pack=JSON.stringify({lang:'en',release:{version:'1',schema_version:5},lemmas:[],senses:[],cards:[]});
 const hash=createHash('sha256').update(pack).digest('hex');
 const release={release_id:'12345678-1234-4234-8234-123456789abc',manifest_sha256:'a'.repeat(64),sqlite_sha256:'b'.repeat(64)};
 const input={release,hints:{},blocked:[],contract:2,consent:1,lang:'en',text:'The hamster sleeps in its cage.',form:'hamster',start:4,end:11,candidates:[],local_candidates:[]};
 const answer={distinctions:{},cache_use:{word:false,sentence:false},cache_note:'Keine Cacheteile.',reuse_id:null,lemma:'hamster',pos:'NOUN',definition_de:'Ein kleines Nagetier.',gloss_de:'kleines Nagetier',form_detail:'Substantiv',function:null,sentence:input.text,translation_de:'Das kleine Nagetier schläft in seinem Käfig.',start:4,reason:'original',reason_detail:'Original geeignet.'};
 let models=0,valid=false,loseFinish=false;
 const keys=[];
 const fetcher=async(url,init)=>{
  const p=String(url),b=init?.body?JSON.parse(init.body):null;
  if(p.endsWith('/auth/v1/user'))return Response.json({id:actor,is_anonymous:false});
  if(p.endsWith('/personal_learning_release'))return Response.json({status:'ok',release:{...release,lang:'en',manifest:{sha256:release.sqlite_sha256,version:'1',pack_json_sha256:hash},objects:{'pack.json':{sha256:hash,size_bytes:Buffer.byteLength(pack)}}}});
  if(p.includes('/storage/v1/'))return new Response(pack);
  if(p.includes('/rpc/')){
   const name=p.split('/').at(-1);
   assert.ok(['claim_personal_learning','fail_personal_learning','finish_personal_learning'].includes(name));
   if(name==='claim_personal_learning')keys.push(b.p_key);
   const vals=Object.values(b).map(v=>typeof v==='object'&&v!==null?JSON.stringify(v):v);
   const args=Object.keys(b).map((k,i)=>`${k} => $${i+1}`).join(',');
   const result=(await db.query(`select public.${name}(${args}) as result`,vals)).rows[0].result;
   if(name==='finish_personal_learning'&&loseFinish){loseFinish=false;throw Error('synthetic connection loss after commit');}
   return Response.json(result);
  }
  assert.equal(p,'https://api.anthropic.com/v1/messages');models++;
  return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify({...answer,translation_de:valid?answer.translation_de:'Der Hamster schläft.'})}],usage:{input_tokens:40,output_tokens:80}});
 };
 const handler=personalHandler(new PersonalLearningBackend('https://synthetic.invalid','fixture','fixture',fetcher),()=>{});
 const run=async(v=input)=>{const r=await handler(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer fixture'},body:JSON.stringify(v)}));return {status:r.status,body:await r.json()};};
 const failed=await run();assert.equal(failed.status,502);assert.equal(failed.body.error,'ANSWER_LEAK');assert.ok(failed.body.retry_ticket);assert.equal(models,1);
 const check=await run();assert.equal(check.status,409);assert.equal(models,1);
 valid=true;loseFinish=true;
 const replies=await Promise.all(Array.from({length:8},()=>run({...input,retry_ticket:failed.body.retry_ticket})));
 assert.equal(models,2);assert.ok(replies.some(r=>r.status===503));
 const recovered=await run({...input,retry_ticket:failed.body.retry_ticket});assert.equal(recovered.status,200);assert.deepEqual(recovered.body,answer);assert.equal(models,2);
 assert.equal(new Set(keys).size,1); // Attempt control is not part of the request identity.
 assert.equal((await db.query('select count(*)::int n from app.personal_learning_jobs where user_id=$1 and state=\'ready\'',[actor])).rows[0].n,1);
 console.log('PASS production handler + SQL: failure → explicit retry; 8 concurrent requests; lost commit response → cached recovery; exactly 2 model stubs total');
}
