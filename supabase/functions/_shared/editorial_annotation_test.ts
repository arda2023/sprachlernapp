import {annotationInput,annotationOutput,editorialHandler,expandAnnotation,applyReview,bindProviderAnnotation,CONTRACT} from './editorial_annotation.ts';
function assert(v:unknown):asserts v {if(!v)throw Error('assertion failed');}
const input=()=>({lang:'es',items:[{id:'synthetic-1',text:'Ana lee.',translation_de:'Ana liest.',tokens:[
  {idx:0,surface:'Ana',start_pos:0,end_pos:3},{idx:1,surface:'lee',start_pos:4,end_pos:7}]}]});
const output=()=>({items:[{id:'synthetic-1',tokens:[{idx:0,surface:'Ana',lemma:'Ana',pos:'PROPN',gloss_de:'Ana',context_gloss_de:'Ana'},
  {idx:1,surface:'lee',lemma:'leer',pos:'VERB',gloss_de:'lesen',context_gloss_de:'liest'}]}]});
const compact=(value:any)=>({items:value.items.map((i:any)=>({id:i.id,tokens:i.tokens.map((t:any)=>[t.idx,t.surface,t.lemma,t.pos,t.gloss_de,t.context_gloss_de])}))});
const providerCompact=(value:any)=>({items:value.items.map((i:any)=>({id:i.id,tokens:i.tokens.map((t:any)=>[t.idx,t.lemma,t.pos,t.gloss_de,t.context_gloss_de])}))});
function invalid(fn:()=>unknown){let failed=false;try{fn();}catch{failed=true;}assert(failed);}
Deno.test('input binds complete exact codepoint word-token coverage and bounded scope',()=>{
  annotationInput(input());
  for(const mutate of [
    (x:any)=>x.lang='en',(x:any)=>x.items=Array(9).fill(x.items[0]),
    (x:any)=>x.items[0].tokens.pop(),(x:any)=>x.items[0].tokens[1].start_pos=3,
    (x:any)=>x.items[0].tokens[1].idx=0,(x:any)=>x.items[0].tokens[1].surface='reads',
    (x:any)=>x.url='https://other.invalid',(x:any)=>x.items[0].text='Ana\nlee.',
  ]){const x=input();mutate(x);invalid(()=>annotationInput(x));}
  const astral=input();astral.items[0].text='😀 Ana lee.';
  for(const t of astral.items[0].tokens){t.start_pos+=2;t.end_pos+=2;}annotationInput(astral);
});
Deno.test('output rejects omitted tokens, reordered IDs, invalid POS and blank or extra annotations',()=>{
  annotationOutput(input(),output());
  for(const mutate of [
    (x:any)=>x.items[0].tokens.pop(),(x:any)=>x.items[0].id='other',
    (x:any)=>x.items[0].tokens[1].idx=7,(x:any)=>x.items[0].tokens[1].surface='other',(x:any)=>x.items[0].tokens[1].pos='verb',
    (x:any)=>x.items[0].tokens[1].context_gloss_de=' ',(x:any)=>x.items[0].tokens[1].context_gloss_de='-',(x:any)=>x.items[0].tokens[1].secret='extra',
  ]){const x=output();mutate(x);invalid(()=>annotationOutput(input(),x));}
});
Deno.test('only exact administrative key can trigger provider, errors never disclose credentials',async()=>{
  let calls=0;const handle=editorialHandler('admin-secret','provider-secret',()=>{calls++;throw Error('provider-secret');});
  for(const auth of [undefined,'Bearer anon','Bearer user-jwt','Bearer admin-secret-extra']){
    const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:auth?{Authorization:auth}:{},body:JSON.stringify(input())}));
    assert(r.status===403&&(await r.json()).code==='ADMIN_REQUIRED');
  }
  assert(calls===0);
  const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin-secret'},body:JSON.stringify(input())}));
  assert(r.status===502);assert(!JSON.stringify(await r.json()).includes('secret'));assert(Number(calls)===1);
});
Deno.test('bounded JSON and invalid inputs reject before provider; no automatic retries',async()=>{
  let calls=0;const handle=editorialHandler('admin','api',async()=>{calls++;return new Response('provider-secret',{status:429});});
  for(const body of ['x'.repeat(65537),'not JSON',JSON.stringify({...input(),lang:'qaa'})]){
    const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body}));
    assert([413,422].includes(r.status));
  }
  assert(calls===0);
  const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
  assert(r.status===429&&(await r.json()).code==='PROVIDER_RATE_LIMIT');assert(Number(calls)===1);
});
Deno.test('fixed provider receives exact input and structured schema, validated usage returned',async()=>{
  let calls=0;const handle=editorialHandler('admin','api',async(url,init)=>{calls++;
    assert(url==='https://api.anthropic.com/v1/messages'&&init?.redirect==='error');
    const body=JSON.parse(String(init?.body));assert(body.model==='claude-haiku-5-5'&&body.max_tokens===8000);
    assert(JSON.parse(body.messages[0].content).input.items[0].text==='Ana lee.'&&body.output_config.format.type==='json_schema');
    return Response.json({model:body.model,stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?providerCompact(output()):{checked_ids:['synthetic-1'],corrections:[]})}],usage:{input_tokens:20,output_tokens:30}});
  });
  const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
  assert(r.status===200&&r.headers.get('Cache-Control')==='no-store');const result=await r.json();
  assert(result.contract===CONTRACT&&result.input_sha256.length===64&&result.usage.output_tokens===60&&result.review_passes===2&&result.items[0].tokens[1].context_gloss_de==='liest');
});
Deno.test('temporary admin credential requires independent secret AND project-scoped service JWT claims',async()=>{
  let calls=0;const handle=editorialHandler('other-server-key','provider-key',async()=>{calls++;return new Response('',{status:429});},{secret:'temporary-secret',projectRef:'project'});
  const jwt=(role:string,ref='project',exp=9999999999)=>'header.'+btoa(JSON.stringify({role,ref,exp,iss:'supabase'}))+'.signature';
  for(const [token,extra] of [[jwt('anon'),'temporary-secret'],[jwt('authenticated'),'temporary-secret'],[jwt('service_role','foreign'),'temporary-secret'],[jwt('service_role','project',1),'temporary-secret'],[jwt('service_role'),'wrong-secret']]){
    const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer '+token,'X-Editorial-Admin':extra},body:JSON.stringify(input())}));assert(r.status===403);
  }
  assert(calls===0);
  const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer '+jwt('service_role'),'X-Editorial-Admin':'temporary-secret'},body:JSON.stringify(input())}));
  assert(r.status===429&&Number(calls)===1);
});
Deno.test('pure numbers may remain unannotated under the alphabetic token contract',()=>{
  const x=input();x.items[0].text='Ana lee 2010.';annotationInput(x);
});
Deno.test('na varanda regression binds each surface and a separate reviewer corrects shifted semantics',async()=>{
  const text='Tomamos café na varanda todas as manhãs.';
  const surfaces=['Tomamos','café','na','varanda','todas','as','manhãs'];let start=0;
  const tokens=surfaces.map((surface,idx)=>{const start_pos=text.indexOf(surface,start);start=start_pos+surface.length;return {idx,surface,start_pos,end_pos:start};});
  const source={lang:'pt-BR',items:[{id:'alltag-zuhause:6',text,translation_de:'Wir frühstücken jeden Morgen auf dem Balkon.',tokens}]};
  const lexical=[['tomar','VERB','nehmen','frühstücken'],['café','NOUN','Kaffee','Kaffee'],['em','ADP','in','auf dem'],
    ['varanda','NOUN','Balkon','Balkon'],['todo','DET','jeder','jeden'],['o','DET','bestimmter Artikel','die'],['manhã','NOUN','Morgen','Morgen']];
  const corrected={items:[{id:source.items[0].id,tokens:tokens.map((t,i)=>({idx:t.idx,surface:t.surface,lemma:lexical[i][0],pos:lexical[i][1],gloss_de:lexical[i][2],context_gloss_de:lexical[i][3]}))}]};
  const first=structuredClone(corrected);first.items[0].tokens[3].lemma='o';first.items[0].tokens[3].pos='DET';
  const shifted=structuredClone(corrected);shifted.items[0].tokens[3].surface='o';invalid(()=>annotationOutput(source,shifted));
  let calls=0;const handle=editorialHandler('admin','api',async(_url,init)=>{
    calls++;const request=JSON.parse(String(init?.body));const payload=JSON.parse(request.messages[0].content);assert(!JSON.stringify(payload).includes('translation_de'));
    assert(payload.input.items[0].tokens[2].surface==='na');
    if(calls===2){assert(payload.first_annotation.items[0].tokens[3][1]==='o');assert(request.system.includes('independent second editorial reviewer'));}
    return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?providerCompact(first):{checked_ids:[source.items[0].id],corrections:[{id:source.items[0].id,tokens:[providerCompact(corrected).items[0].tokens[3]]}]})}],usage:{input_tokens:100,output_tokens:200}});
  });
  const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(source)}));
  const result=await response.json();assert(response.status===200&&calls===2&&result.review_passes===2);
  assert(result.items[0].tokens[3].surface==='varanda'&&result.items[0].tokens[3].lemma==='varanda'&&result.items[0].tokens[3].pos==='NOUN');
  assert(result.usage.input_tokens===200&&result.usage.output_tokens===400);
});
Deno.test('partial usage and only bounded allowlisted quota headers survive a second-pass rate limit',async()=>{
  let calls=0;const handle=editorialHandler('admin','api',async()=>{
    if(++calls===1)return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?providerCompact(output()):{checked_ids:['synthetic-1'],corrections:[]})}],usage:{input_tokens:17,output_tokens:23}});
    return new Response('provider-secret',{status:429,headers:{'retry-after':'12','anthropic-ratelimit-requests-limit':'50',
      'anthropic-ratelimit-requests-remaining':'0','anthropic-ratelimit-requests-reset':'2026-10-27T20:00:00Z',
      'anthropic-ratelimit-tokens-reset':'secret-value','x-api-key':'provider-secret','set-cookie':'secret-cookie'}});
  });
  const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
  const value=await r.json();assert(r.status===429&&value.retry_after_seconds===12&&value.usage.input_tokens===17&&value.usage.output_tokens===23);
  assert(value.provider_calls===2&&value.known_usage_calls===2&&value.usage_complete===true);
  assert(value.rate_limits['requests-remaining']===0&&!JSON.stringify(value).includes('secret'));
});

Deno.test('compact output and sparse review require exact checked IDs and unique bound corrections',()=>{
  const x=input(),first=output(),tuple=compact(first).items[0].tokens[1];
  assert(expandAnnotation(x,compact(first)).items[0].tokens[1].lemma==='leer');
  const review=()=>({checked_ids:['synthetic-1'],corrections:[{id:'synthetic-1',tokens:[tuple]}]});
  applyReview(x,first,review());
  for(const mutate of [
    (r:any)=>r.checked_ids=[],(r:any)=>r.checked_ids=['other'],(r:any)=>r.checked_ids.push('synthetic-1'),
    (r:any)=>r.corrections[0].id='other',(r:any)=>r.corrections.push(r.corrections[0]),
    (r:any)=>r.corrections[0].tokens.push(tuple),(r:any)=>r.corrections[0].tokens[0][0]=9,
    (r:any)=>r.corrections[0].tokens[0][1]='other',(r:any)=>r.corrections[0].tokens[0].pop(),
    (r:any)=>r.corrections[0].tokens[0][3]='invalid',
  ]){const r=structuredClone(review());mutate(r);invalid(()=>applyReview(x,first,r));}
  const wrong=compact(first);wrong.items[0].tokens[0][0]='0';invalid(()=>expandAnnotation(x,wrong));
});

Deno.test('model diagnostics name only the failed phase and static check, never token content',async()=>{
  for(const review of [false,true]){
    let calls=0;
    const handle=editorialHandler('admin','api',async()=>{
      calls++;
      const bad=output();bad.items[0].tokens[1].idx=99;bad.items[0].tokens[1].lemma='private-provider-content';
      const value=calls===1?providerCompact(review?output():bad):{checked_ids:['synthetic-1'],corrections:providerCompact(bad).items};
      return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(value)}],usage:{input_tokens:12,output_tokens:15}});
    });
    const r=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
    const value=await r.json();assert(r.status===502&&value.code==='MODEL_INVALID');
    assert(value.diagnostic.phase===(review?'review':'first'));
    assert(value.diagnostic.check===(review?'REVIEW_TOKEN_IDX':'TOKEN_IDX'));
    assert(!JSON.stringify(value).includes('private-provider-content')&&value.usage_complete===true);
  }
});

Deno.test('idx-bound provider output preserves multiword surfaces and source punctuation through both passes',async()=>{
  const source={lang:'nb',items:[{id:'verbalphrasen:52',text:'Vi vil sette pris på jul.',translation_de:'Wir werden Weihnachten schätzen.',tokens:[
    {idx:0,surface:'Vi',start_pos:0,end_pos:2},{idx:1,surface:'vil',start_pos:3,end_pos:6},
    {idx:2,surface:'sette pris på',start_pos:7,end_pos:20},{idx:4,surface:'jul.',start_pos:21,end_pos:25}]}]};
  annotationInput(source);
  const first={items:[{id:source.items[0].id,tokens:[
    [0,'vi','PRON','wir','wir'],[1,'ville','AUX','wollen','werden'],
    [2,'sette pris på','VERB','schätzen','schätzen'],[4,'jul','NOUN','Juli','Juli']]}]};
  // Source has noncontiguous indices: no positional reconstruction is permitted.
  let calls=0;const handle=editorialHandler('admin','api',async(_url,init)=>{
    calls++;const body=JSON.parse(String(init?.body));const payload=JSON.parse(body.messages[0].content);
    assert(body.system.includes('five-element array [idx,lemma,pos,gloss_de,context_gloss_de]'));
    if(calls===2){assert(payload.first_annotation.items[0].tokens[3][0]===4&&payload.first_annotation.items[0].tokens[3].length===5);}
    return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?first:
      {checked_ids:[source.items[0].id],corrections:[{id:source.items[0].id,tokens:[[4,'jul','NOUN','Weihnachten','Weihnachten']]}]})}],usage:{input_tokens:20,output_tokens:30}});
  });
  const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(source)}));
  const result=await response.json();assert(response.status===200&&calls===2&&result.contract===CONTRACT);
  assert(result.items[0].tokens[2].surface==='sette pris på'&&result.items[0].tokens[3].surface==='jul.');
  assert(result.items[0].tokens[3].idx===4&&result.items[0].tokens[3].gloss_de==='Weihnachten');
  const bound=()=>bindProviderAnnotation(source,structuredClone(first),false);
  expandAnnotation(source,bound());
  for(const mutate of [
    (x:any)=>x.items[0].tokens.pop(),(x:any)=>x.items[0].tokens.reverse(),
    (x:any)=>x.items[0].tokens[3][0]=3,(x:any)=>x.items[0].tokens[3][0]='4',
    (x:any)=>x.items[0].tokens.push(x.items[0].tokens[3]),
    (x:any)=>x.items[0].tokens[2].splice(1,0,'sette pris på'),
    (x:any)=>x.items[0].id='foreign',
  ]){const x=structuredClone(first);mutate(x);invalid(()=>expandAnnotation(source,bindProviderAnnotation(source,x,false)));}
  for(const tokens of [
    [[3,'jul','NOUN','Weihnachten','Weihnachten']],
    [[4,'jul','NOUN','Weihnachten','Weihnachten'],[4,'jul','NOUN','Weihnachten','Weihnachten']],
    [[4,'jul.','jul','NOUN','Weihnachten','Weihnachten']],
  ]){invalid(()=>applyReview(source,expandAnnotation(source,bound()),bindProviderAnnotation(source,{checked_ids:[source.items[0].id],corrections:[{id:source.items[0].id,tokens}]},true)));}
});

Deno.test('explicit required indices reach the provider and omitted first-pass tokens still fail closed',async()=>{
  let calls=0;const handle=editorialHandler('admin','api',async(_url,init)=>{
    calls++;const body=JSON.parse(String(init?.body));const source=JSON.parse(body.messages[0].content).input.items[0];
    assert(source.required_token_count===2&&JSON.stringify(source.required_indices)==='[0,1]');
    assert(body.system.includes('apostrophized article fragments')&&body.system.includes('every supplied idx must appear'));
    const value=providerCompact(output());value.items[0].tokens.pop();
    return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(value)}],usage:{input_tokens:20,output_tokens:30}});
  });
  const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
  const result=await response.json();assert(response.status===502&&calls===1&&result.code==='MODEL_INVALID');
  assert(result.diagnostic.phase==='first'&&result.diagnostic.check==='TOKEN_COUNT'&&!('items' in result));
});

Deno.test('provider failures expose only bounded status and allowlisted type or documented credit category',async()=>{
  const credit='Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.';
  for(const [status,type,message,expected] of [
    [400,'invalid_request_error',credit,'INSUFFICIENT_CREDITS'],[401,'authentication_error','provider-secret','authentication_error'],
    [402,'billing_error','provider-secret','billing_error'],[529,'overloaded_error','provider-secret','overloaded_error'],
    [500,'provider-secret','provider-secret','UNCLASSIFIED'],
  ] as const){
    const handle=editorialHandler('admin','api',async()=>Response.json({error:{type,message},request_id:'provider-secret'},{status}));
    const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
    const result=await response.json();assert(response.status===502&&result.code==='MODEL_FAILED');
    assert(result.provider_status===status&&result.provider_error===expected&&!JSON.stringify(result).includes('provider-secret'));
    assert(!JSON.stringify(result).includes(credit)&&!('items' in result));
  }
});

Deno.test('multiword polite formulas use an allowed lexical POS and retain the strict v3 binding',async()=>{
  const formulas=[['Que te mejores','gute Besserung'],['Con permiso','mit Verlaub'],['Faltaría más','aber selbstverständlich'],['Ni hablar','kommt nicht infrage']];
  const source={lang:'es',items:formulas.map(([surface,translation_de],i)=>({id:'formula-'+i,text:surface+'.',translation_de:translation_de+'.',tokens:[{idx:0,surface,start_pos:0,end_pos:surface.length}]}))};
  const first={items:source.items.map((item,i)=>({id:item.id,tokens:[[0,formulas[i][0].toLowerCase(),'INTJ',formulas[i][1],formulas[i][1]]]}))};
  let calls=0;const handle=editorialHandler('admin','api',async(_url,init)=>{
    calls++;const body=JSON.parse(String(init?.body));
    assert(body.system.includes('Allowed pos values are ONLY ADJ, ADP, ADV, AUX, CCONJ, DET, INTJ, NOUN, NUM, PART, PRON, PROPN, SCONJ, VERB'));
    assert(body.system.includes('A multiword lexical span is not X')&&body.system.includes('que te mejores (gute Besserung)'));
    assert(body.system.includes('Markierung des belebten Objekts')&&body.system.includes('copias del formulario')&&body.system.includes('nos ha atendido con amabilidad'));
    return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?first:{checked_ids:source.items.map(i=>i.id),corrections:[]})}],usage:{input_tokens:30,output_tokens:40}});
  });
  const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(source)}));
  const result=await response.json();assert(response.status===200&&calls===2&&result.contract===CONTRACT);
  for(let i=0;i<formulas.length;i++)assert(result.items[i].tokens.length===1&&result.items[i].tokens[0].surface===formulas[i][0]&&result.items[i].tokens[0].pos==='INTJ');
});

Deno.test('unsupported lexical POS remain rejected in both passes after explicit prompt guidance',async()=>{
  for(const review of [false,true])for(const pos of ['X','PUNCT','SYM']){
    let calls=0;const handle=editorialHandler('admin','api',async()=>{
      calls++;const bad=providerCompact(output());bad.items[0].tokens[1][2]=pos;
      const value=calls===1?(review?providerCompact(output()):bad):{checked_ids:['synthetic-1'],corrections:bad.items};
      return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(value)}],usage:{input_tokens:12,output_tokens:15}});
    });
    const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(input())}));
    const result=await response.json();assert(response.status===502&&result.code==='MODEL_INVALID'&&!('items' in result));
    assert(result.diagnostic.check==='TOKEN_POS'&&result.diagnostic.phase===(review?'review':'first')&&calls===(review?2:1));
  }
});

Deno.test('function-word dictionary and context glosses cannot be blank or punctuation in either pass',async()=>{
  const sentence='El museo cierra los lunes.';const surfaces=['El','museo','cierra','los','lunes'];let start=0;
  const source={lang:'es',items:[{id:'function-words',text:sentence,translation_de:'Das Museum schließt montags.',tokens:surfaces.map((surface,idx)=>{const start_pos=sentence.indexOf(surface,start);start=start_pos+surface.length;return {idx,surface,start_pos,end_pos:start};})}]};
  const first={items:[{id:'function-words',tokens:[[0,'el','DET','der, die, das','das'],[1,'museo','NOUN','Museum','Museum'],[2,'cerrar','VERB','schließen','schließt'],[3,'el','DET','die','den'],[4,'lunes','NOUN','Montag','Montagen']]}]};
  for(const review of [false,true])for(const [field,check] of [[3,'TOKEN_GLOSS'],[4,'TOKEN_CONTEXT_GLOSS']] as const)for(const invalidGloss of ['', '-']){
    let calls=0;const handle=editorialHandler('admin','api',async()=>{
      calls++;const bad=structuredClone(first);bad.items[0].tokens[3][field]=invalidGloss;
      const value=calls===1?(review?first:bad):{checked_ids:['function-words'],corrections:[{id:'function-words',tokens:[bad.items[0].tokens[3]]}]};
      return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(value)}],usage:{input_tokens:12,output_tokens:15}});
    });
    const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(source)}));
    const result=await response.json();assert(response.status===502&&result.code==='MODEL_INVALID'&&!('items' in result));
    assert(result.diagnostic.check===check&&result.diagnostic.phase===(review?'review':'first')&&calls===(review?2:1));
  }
});

Deno.test('a wish inside Espero is a lexical verb span rather than a standalone interjection',async()=>{
  const source={lang:'es',items:[{id:'wish-clause',text:'Espero que te mejores pronto.',translation_de:'Ich hoffe, dass du bald gesund wirst.',tokens:[
    {idx:0,surface:'Espero',start_pos:0,end_pos:6},{idx:1,surface:'que te mejores',start_pos:7,end_pos:21},{idx:2,surface:'pronto',start_pos:22,end_pos:28}]}]};
  const first={items:[{id:'wish-clause',tokens:[[0,'esperar','VERB','hoffen','hoffe'],[1,'mejorarse','VERB','gesund werden','gesund wirst'],[2,'pronto','ADV','bald','bald']]}]};
  let calls=0;const handle=editorialHandler('admin','api',async(_url,init)=>{
    calls++;const body=JSON.parse(String(init?.body));
    assert(body.system.includes('que te mejores in Espero que te mejores pronto is VERB with lemma mejorarse'));
    assert(body.system.includes('it is not an INTJ in that subordinate clause'));
    return Response.json({model:'claude-haiku-5-5',stop_reason:'end_turn',content:[{type:'text',text:JSON.stringify(calls===1?first:{checked_ids:['wish-clause'],corrections:[]})}],usage:{input_tokens:30,output_tokens:40}});
  });
  const response=await handle(new Request('https://synthetic.invalid',{method:'POST',headers:{Authorization:'Bearer admin'},body:JSON.stringify(source)}));
  const result=await response.json();assert(response.status===200&&calls===2&&result.contract===CONTRACT);
  assert(result.items[0].tokens[1].surface==='que te mejores'&&result.items[0].tokens[1].lemma==='mejorarse'&&result.items[0].tokens[1].pos==='VERB');
});
