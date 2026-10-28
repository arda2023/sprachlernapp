// Auth, PostgREST and Storage transport are local fixtures. Catalog and pack bytes
// are exact read-only downloads; no production quota/job/RLS mutations occur.
const catalogs=JSON.parse(await Deno.readTextFile('/work/catalogs.json'));

let scenario='',pending=false,ready:any;
const counts={storage:{},auth:0,release:0,model:0,claim:0,finish:0};
Deno.serve({port:9000},async req=>{
 const p=new URL(req.url).pathname;
 if(p==='/configure'){scenario=(await req.json()).scenario;return Response.json({ok:true});}
 if(p==='/health')return Response.json({ready:true});
 if(p==='/counts')return Response.json(counts);
 if(p==='/auth/v1/user'){counts.auth++;return Response.json({id:'12345678-1234-4234-8234-123456789abc',is_anonymous:false});}
 if(p==='/rest/v1/rpc/personal_learning_release'){
  counts.release++;const b=await req.json(),r=catalogs.find(r=>r.release_id===b.p_release&&r.lang===b.p_lang&&r.manifest_sha256===b.p_manifest);
  return Response.json(r?{status:'ok',release:r}:{status:'invalid'});
 }
 if(p==='/rest/v1/rpc/claim_personal_learning'){counts.claim++;if(ready)return Response.json({status:'hit',response:ready});if(scenario&&pending)return Response.json({status:'uncertain'});pending=true;return Response.json({status:'claimed',ticket:crypto.randomUUID()});}
 if(p==='/rest/v1/rpc/finish_personal_learning'){counts.finish++;if(scenario==='storage-failure')return Response.json({stored:false});if(scenario)ready=(await req.json()).p_response;return Response.json({stored:true});}
 if(p.startsWith('/storage/v1/object/authenticated/content-private/')){
  const id=p.split('/').at(-2),r=catalogs.find(r=>r.release_id===id);if(!r)return new Response('',{status:404});
  counts.storage[id]=(counts.storage[id]??0)+1;
  const file=await Deno.open('/work/'+r.lang+'-pack.json');return new Response(file.readable);
 }
 if(p==='/synthetic-anthropic'){
  counts.model++;const body=await req.json(),t=JSON.parse(body.messages[0].content);
  const answer={reuse_id:null,lemma:t.form,pos:'NOUN',definition_de:'Synthetischer Testgegenstand.',gloss_de:'Kugel',form_detail:'Substantiv',function:null,sentence:t.text,translation_de:'Sie legt eine Kugel auf den Tisch.',start:t.start,reason:'original',reason_detail:'Synthetische Antwort, kein Qualitätsnachweis.',distinctions:{},cache_use:{word:false,sentence:false},cache_note:'Keine Cacheteile.'};
  if(scenario==='provider-failure')return Response.json({error:{type:'invalid_request_error'}},{status:400});
  if(scenario==='validation-failure')answer.start=0;
  return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(answer)}],usage:{input_tokens:1,output_tokens:1}});
 }
 if(p==='/run'){
  try{
   const workerPromise=EdgeRuntime.userWorkers.create({servicePath:'/work/worker',memoryLimitMb:256,workerTimeoutMs:150000,cpuTimeSoftLimitMs:1000,cpuTimeHardLimitMs:2000,noModuleCache:false,forceCreate:false,envVars:[['SUPABASE_URL','https://synthetic.invalid'],['SUPABASE_SERVICE_ROLE_KEY','synthetic'],['ANTHROPIC_API_KEY','synthetic-never-sent-to-provider']]});
   return await (await workerPromise).fetch(req);
  }catch{return Response.json({error:'LOCAL_WORKER_ABORT'},{status:546});}
 }
 return new Response('',{status:404});
});
