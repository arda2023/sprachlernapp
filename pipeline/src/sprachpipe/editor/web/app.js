'use strict';
const $ = id => document.getElementById(id);
const state = {lang:'en',languages:[],draft:null,etag:null,deck:null,cursor:0,total:0,page:'content',detail:null,dirty:false,job:null};
let tokenRequest=0;
let viewWrites=Promise.resolve();
let lastView='';
async function rememberView(){
  if(!state.workspaceId||state.restoring)return;
  const selection={lang:state.lang,draft_id:state.draft?.draft_id||null,deck:state.deck,page:state.page};
  const signature=JSON.stringify(selection);if(signature===lastView)return;
  try{sessionStorage.setItem('editor-view:'+state.workspaceId,signature);}catch(_){}
  const pending=viewWrites.catch(()=>{}).then(()=>post('/workspace-view',{selection}));viewWrites=pending;
  await pending;lastView=signature;
}
const labels = {base:'Bestand',open:'Offen',valid:'Gültig',invalid:'Blockiert',unsupported:'Profil fehlt',approved:'Bestätigt'};
function el(tag,text,attrs={}) { const node=document.createElement(tag); if(text!==null&&text!==undefined) node.textContent=text; for(const [k,v] of Object.entries(attrs)) {if(k==='class')node.className=v;else node.setAttribute(k,v);} return node; }
function button(text,fn,cls='') {const b=el('button',text,{type:'button',class:cls});b.addEventListener('click',act(fn));return b;}
function clear(node){node.replaceChildren();return node;}
function error(e){$('notice').hidden=false;clear($('notice')).append(el('span',e.message||String(e)),button('Schließen',()=>{$('notice').hidden=true;}));if(e.code==='DRAFT_CHANGED')$('notice').append(button('Aktuellen Stand laden',()=>loadDraft(state.draft.draft_id)));}
function act(fn){return async event=>{try{await fn(event);}catch(e){error(e);}};}
async function api(path,{method='GET',body,match=false}={}) {
  const headers={};if(method==='POST'){headers['X-CSRF-Token']=state.csrf;headers['Idempotency-Key']=crypto.randomUUID();if(!(body instanceof FormData))headers['Content-Type']='application/json';}
  if(match)headers['If-Match']=state.etag;
  const response=await fetch('/api/v1'+path,{method,headers,body:method==='POST'?(body instanceof FormData?body:JSON.stringify(body||{})):undefined,credentials:'same-origin'});
  const data=await response.json();if(!response.ok){const e=new Error(data.message||'Lokaler Vorgang fehlgeschlagen.');e.code=data.code;throw e;}
  if(response.headers.get('ETag')&&data.draft_id){state.etag=response.headers.get('ETag');state.draft=data;}
  return data;
}
const post=(path,body={},match=false)=>api(path,{method:'POST',body,match});
function field(parent,label,value='',type='text',id){const wrap=el('div',null,{class:'field'});const input=el(type==='textarea'?'textarea':type==='select'?'select':'input',null,{id:id||'f-'+crypto.randomUUID()});if(type!=='textarea'&&type!=='select')input.type=type;input.value=value??'';wrap.append(el('label',label,{for:input.id}),input);parent.append(wrap);return input;}
function option(select,value,label){const o=el('option',label);o.value=value;select.append(o);}
async function modal(title,build,submit='Übernehmen'){
  $('modal-title').textContent=title;$('modal-submit').textContent=submit;clear($('modal-body'));
  const read=build($('modal-body'));$('modal').returnValue='cancel';$('modal').showModal();
  return await new Promise(resolve=>$('modal').addEventListener('close',()=>resolve($('modal').returnValue==='ok'?read():null),{once:true}));
}
function saved(){state.dirty=false;const selected=$('draft-select').selectedOptions[0];if(selected&&selected.value)selected.textContent=`Entwurf ${state.draft.created_at.slice(0,10)} · ${state.draft.target_refs.length} Ziele · R${state.draft.revision}`;$('draft-state').textContent='Gespeichert · Revision '+state.draft.revision;$('discard').hidden=false;$('detail-state').textContent='Im Entwurf gespeichert';renderValidation();}
async function refreshLanguages(){state.languages=await api('/languages');clear($('language'));for(const l of state.languages)option($('language'),l.lang,l.display_name+(l.profile?'':' · Entwurf'));$('language').value=state.lang;const current=state.languages.find(l=>l.lang===state.lang);$('profile-warning').hidden=!!current?.profile;$('profile-warning').textContent='Sprachentwurf: Noch kein geprüftes Sprachprofil. Inhalte können bearbeitet und gespeichert werden; Tokenisierung und Release-Freigabe sind nicht verfügbar.';}
async function refreshDrafts(){const drafts=await api('/drafts');clear($('draft-select'));option($('draft-select'),'','Bestand · schreibgeschützt');for(const d of drafts.filter(d=>d.lang===state.lang&&d.state!=='discarded'))option($('draft-select'),d.draft_id,`Entwurf ${d.created_at.slice(0,10)} · ${d.target_refs.length} Ziele · R${d.revision}`);$('draft-select').value=state.draft?.draft_id||'';}
async function loadDraft(id){state.detail=null;state.dirty=false;$('detail').hidden=true;if(id){await api('/drafts/'+id);saved();}else{state.draft=null;state.etag=null;$('discard').hidden=true;$('draft-state').textContent='Original bleibt erhalten';}await refreshDrafts();await catalog();renderValidation();}
async function ensureDraft(){if(!state.draft){await post('/drafts',{lang:state.lang,deck_ref:state.deck});await refreshDrafts();saved();}return state.draft;}
async function catalog(){
  const query=new URLSearchParams({lang:state.lang,q:$('search').value,cursor:state.cursor,limit:50,status:$('status-filter').value});if(state.draft)query.set('draft_id',state.draft.draft_id);if(state.deck)query.set('deck',state.deck);
  const result=await api('/catalog?'+query);state.total=result.total;state.decks=result.decks;
  clear($('decks')).append(button('Alle Lernziele',async()=>{state.deck=null;state.cursor=0;await catalog();},!state.deck?'selected':''));
  for(const d of result.decks.filter(d=>!d.removed_in))$('decks').append(button(d.title_de||d.ref,async()=>{state.deck=d.ref;state.cursor=0;await catalog();},state.deck===d.ref?'selected':''));
  clear($('mobile-deck'));option($('mobile-deck'),'','Alle Lernziele');for(const d of result.decks.filter(d=>!d.removed_in))option($('mobile-deck'),d.ref,d.title_de);$('mobile-deck').value=state.deck||'';
  $('page-title').textContent=result.decks.find(d=>d.ref===state.deck)?.title_de||'Alle Lernziele';
  $('catalog-summary').textContent=`${result.total.toLocaleString('de-DE')} Lernziele · ${state.languages.find(l=>l.lang===state.lang)?.display_name||state.lang} → Deutsch`;
  clear($('targets'));
  for(const item of result.items){
    const row=el('tr');row.append(el('td',item.form||'Noch kein Zielwort'));
    for(const [key,value] of [['translation_de',item.translation_de],['text',item.text],['sentence_translation_de',item.sentence_translation_de]]){
      const td=el('td');const cell=el('span',value||'Angabe fehlt',{class:'cell-edit',tabindex:'0','aria-label':`${item.form||'Aufgabe'}: ${key==='translation_de'?'Lösungshinweis':key==='text'?'Übungssatz':'Satzübersetzung'}`});
      cell.contentEditable=state.draft?'plaintext-only':'false';
      cell.addEventListener('dblclick',act(()=>openTarget(item.ref)));
      cell.addEventListener('keydown',act(async event=>{if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();if(!state.draft)await openTarget(item.ref);else cell.blur();}}));
      cell.addEventListener('blur',act(async()=>{if(!state.draft||cell.textContent===(value||'Angabe fehlt'))return;const view=await api(`/drafts/${state.draft.draft_id}/target?ref=${encodeURIComponent(item.ref)}`);if(key==='translation_de')view.card.translation_de=cell.textContent;else if(key==='text'){view.context.text=cell.textContent;view.context.gap={};view.context.tokens.forEach(t=>{if(t.is_word)t.binding_status='unresolved';});}else view.context.translation_de=cell.textContent;await saveTarget(view);await catalog();}));td.append(cell);row.append(td);
    }
    const status=el('td');for(const [name,value] of [['Technisch',item.technical],['Redaktionell',item.editorial]])status.append(el('small',name,{class:'status-label'}),el('span',labels[value],{class:'status '+value}));row.append(status);
    const end=el('td');const b=button('↗',()=>openTarget(item.ref),'row-open');b.setAttribute('aria-label',`${item.form||'Aufgabe'} bearbeiten`);end.append(b);row.append(end);$('targets').append(row);
  }
  if(!result.items.length){const row=el('tr');row.append(el('td','Hier gibt es noch keine passenden Lernziele.',{colspan:'6',class:'empty'}));$('targets').append(row);}
  $('range').textContent=result.total?`${state.cursor+1}–${Math.min(state.cursor+50,result.total)} von ${result.total}`:'Keine Ergebnisse';$('previous').disabled=state.cursor===0;$('next').disabled=state.cursor+50>=result.total;
  await rememberView();
}
async function saveTarget(view){if(view.story_source){await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'correct_story_context',lang:state.lang,target_ref:view.ref,expect:view.expect,payload:view.context}]},true);saved();return;}await post(`/drafts/${state.draft.draft_id}/target`,{ref:view.ref,form:view.card.form,deck_ref:view.owner_deck,translation_de:view.card.translation_de,sense:view.card.sense,context:view.context},true);saved();}
async function openTarget(ref){await ensureDraft();state.detail=await api(`/drafts/${state.draft.draft_id}/target?ref=${encodeURIComponent(ref)}`);state.dirty=false;renderDetail();$('detail').hidden=false;$('close-detail').focus();}
function markDirty(){state.dirty=true;$('detail-state').textContent='Änderungen noch nicht gespeichert';}
function renderDetail(){
  const view=state.detail,c=view.context;const body=clear($('detail-body'));$('detail-title').textContent=view.card.form||'Neue Aufgabe';
  if(!view.before){
    const form=field(body,'Zielwort oder Ausdruck',view.card.form,'text','target-form');
    form.addEventListener('input',()=>{view.card.form=form.value;c.gap={};view.card.sense=null;markDirty();});
    const deck=field(body,'Besitzstapel',view.owner_deck,'select','target-deck');option(deck,'','Stapel auswählen');for(const d of state.decks||[])option(deck,d.ref,d.title_de);deck.value=view.owner_deck||state.deck||'';view.owner_deck=deck.value;
    deck.addEventListener('change',()=>{view.owner_deck=deck.value;markDirty();});
  }
  const hint=field(body,'Deutscher Lösungshinweis',view.card.translation_de,'text','solution-hint');hint.readOnly=!!view.story_source;hint.addEventListener('input',()=>{view.card.translation_de=hint.value;markDirty();renderPreview();});
  const text=field(body,'Übungssatz',c.text,'textarea','sentence-text');text.addEventListener('input',()=>{c.text=text.value;c.gap={};c.tokens.forEach(t=>{if(t.is_word)t.binding_status='unresolved';});markDirty();renderTokens();renderPreview();});
  text.parentElement.append(el('small','Zielwort oder zusammenhängenden Ausdruck im Satz markieren. Nach Textänderungen Wortbindungen neu prüfen.'));
  const actions=el('div',null,{class:'inline-actions'});actions.append(button('Auswahl als Lücke + neu annotieren',async()=>{
    const result=await post(`/drafts/${state.draft.draft_id}/tokenize`,{text:text.value,form:view.card.form,selection:[text.selectionStart,text.selectionEnd]},true);
    const oldTarget=c.tokens.find(t=>t.card===view.ref);c.text=result.text;text.value=result.text;c.tokens=result.tokens;c.gap=result.gap;
    for(const t of c.tokens){if(t.start_pos===c.gap.start_pos&&t.end_pos===c.gap.end_pos){t.card=view.ref;if(oldTarget?.form_target)t.form_target=oldTarget.form_target;}}
    markDirty();renderTokens();renderPreview();
  }),button('Wörter neu annotieren',async()=>{const result=await post(`/drafts/${state.draft.draft_id}/tokenize`,{text:text.value},true);c.tokens=result.tokens;markDirty();renderTokens();}));body.append(actions);
  const translation=field(body,'Deutsche Satzübersetzung',c.translation_de,'textarea','sentence-translation');translation.addEventListener('input',()=>{c.translation_de=translation.value;markDirty();renderPreview();});
  body.append(el('h3','Wortbedeutungen im Kontext'),el('p','Jedes Wort öffnen und seine Bedeutung und Übersetzung prüfen. Gelb markierte Bindungen sind noch offen.',{class:'hint'}),el('div',null,{id:'token-row',class:'token-row'}),el('div',null,{id:'token-editor'}));
  const alternatives=field(body,'Gültige Alternativen · eine pro Zeile',(c.valid_alternatives||[]).join('\n'),'textarea','alternatives');alternatives.readOnly=!!view.story_source;alternatives.addEventListener('input',()=>{c.valid_alternatives=alternatives.value.split('\n').map(s=>s.trim()).filter(Boolean);markDirty();renderAlternatives();});
  alternatives.parentElement.append(el('small','Nur ausdrücklich passende Antworten aufnehmen. Die vollständigen eingesetzten Sätze unten prüfen. Leer bedeutet: keine Alternativen vorgesehen.'));
  body.append(el('div',null,{id:'alternative-preview',class:'alternatives'}),el('h3','Lernvorschau'),el('div',null,{id:'learning-preview',class:'preview'}));
  const before=el('details',null,{class:'before'});before.append(el('summary','Vorher / Nachher vergleichen'));if(view.before)before.append(el('p','Bisheriger Hinweis: '+(view.before.card||view.card).translation_de),el('p',view.before.context.text),el('p',view.before.context.translation_de));else before.append(el('p','Neue Aufgabe, noch nicht im Bestand.'));body.append(before);
  if(view.before&&!view.story_source)body.append(button('Aufgabe zurückstellen …',()=>retireTarget(view),'retire quiet'));
  renderTokens();renderAlternatives();renderPreview();$('detail-state').textContent='Entwurf geöffnet · Revision '+state.draft.revision;
}
function renderTokens(){tokenRequest++;if(!$('token-row'))return;clear($('token-row'));for(const token of state.detail.context.tokens||[]){if(!token.is_word&&!token.lemma&&!/[\p{L}]/u.test(token.surface)){$('token-row').append(el('span',token.surface));continue;}$('token-row').append(button(token.surface,()=>editToken(token),'token '+(token.binding_status||'unresolved')));}clear($('token-editor'));}
async function editToken(token){
  const request=++tokenRequest,detail=state.detail;
  const node=clear($('token-editor'));node.className='token-editor';node.append(el('h3',`„${token.surface}“ im Satz`));
  const candidates=await api(`/drafts/${state.draft.draft_id}/vocabulary?surface=${encodeURIComponent(token.surface)}`);
  if(request!==tokenRequest||state.detail!==detail||!node.isConnected)return;
  const select=field(node,'Bedeutung ausdrücklich auswählen','','select','token-sense');option(select,'','Bedeutung auswählen …');for(const c of candidates)option(select,c.sense.ref,`${c.lemma.lemma} · ${c.lemma.pos} · ${c.sense.definition_de||c.sense.gloss_de}`);select.value=token.sense||'';
  const context=field(node,'Übersetzung nur in diesem Kontext',token.context_gloss_de,'text','token-gloss');
  const shared=el('p','',{class:'hint'});node.append(shared);
  function describe(){const c=candidates.find(c=>c.sense.ref===select.value);shared.textContent=c?`Formglosse: ${c.form.gloss_de} · Geteilte Bedeutungsglosse: ${c.sense.gloss_de}`:'Keine geprüfte Formglosse vorhanden.';}
  describe();select.addEventListener('change',describe);
  const actions=el('div',null,{class:'inline-actions'});actions.append(button('Bindung bestätigen',()=>{const selected=candidates.find(c=>c.sense.ref===select.value);if(!selected||!context.value.trim())throw new Error('Bedeutung und Kontextübersetzung angeben.');token.sense=selected.sense.ref;token.lemma=selected.lemma.ref;token.context_gloss_de=context.value;token.binding_status='confirmed';token.is_word=true;if(!state.detail.before&&token.start_pos===state.detail.context.gap?.start_pos&&token.end_pos===state.detail.context.gap?.end_pos)state.detail.card.sense=token.sense;markDirty();renderTokens();renderPreview();}),button('Neue Bedeutung anlegen …',async()=>{await newMeaning(token,candidates);await editToken(token);}));
  if(candidates.length)actions.append(button('Geteilte Bedeutungsglosse ändern …',()=>sharedGloss(candidates.find(c=>c.sense.ref===select.value))),button('Geteilte Formglosse ändern …',()=>sharedGloss(candidates.find(c=>c.sense.ref===select.value),'dictionary_forms')));node.append(actions);
}
async function newMeaning(token,candidates){
  const data=await modal('Neue Bedeutung ausdrücklich anlegen',box=>{
    box.append(el('p','Die neue Bedeutung erhält eine eigene Identität. Eine vorhandene Bedeutung wird dadurch nicht überschrieben.'));
    const lemmaChoice=field(box,'Lemma verwenden','','select');option(lemmaChoice,'','Neues Lemma');for(const c of candidates)if(![...lemmaChoice.options].some(o=>o.value===c.lemma.ref))option(lemmaChoice,c.lemma.ref,c.lemma.lemma+' · '+c.lemma.pos);
    if(candidates.length)lemmaChoice.value=candidates[0].lemma.ref;
    const lemma=field(box,'Grundform für neues Lemma',token.surface),pos=field(box,'Wortart für neues Lemma','','select');for(const p of ['NOUN','VERB','ADJ','ADV','PRON','DET','ADP','AUX','CCONJ','SCONJ','PART','NUM','INTJ'])option(pos,p,p);
    const definition=field(box,'Bedeutungsdefinition auf Deutsch','','textarea'),gloss=field(box,'Geteilte Bedeutungsglosse',''),formGloss=field(box,'Formglosse für „'+token.surface+'“','');
    return()=>({lemma_ref:lemmaChoice.value,lemma:lemma.value,pos:pos.value,definition:definition.value,gloss:gloss.value,formGloss:formGloss.value});
  },'Bedeutung im Entwurf anlegen');if(!data)return;
  if(!data.definition.trim()||!data.gloss.trim()||!data.formGloss.trim())throw new Error('Definition, Bedeutungs- und Formglosse ausfüllen.');
  const id=crypto.randomUUID(),lemmaRef=data.lemma_ref||'lemma:'+id,senseRef='sense:'+id;
  await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'add_vocabulary',target_ref:id,lang:state.lang,expect:{absent:true},payload:{lemmas:data.lemma_ref?[]:[{ref:lemmaRef,lemma:data.lemma,pos:data.pos}],senses:[{ref:senseRef,lemma:lemmaRef,sense_key:data.lemma+'#'+id,gloss_de:data.gloss,definition_de:data.definition}],dictionary_forms:[{form:token.surface,sense:senseRef,gloss_de:data.formGloss,rank:0}]}}]},true);saved();token.sense=senseRef;token.lemma=lemmaRef;token.context_gloss_de=data.formGloss;token.binding_status='suggested';markDirty();
}
async function sharedGloss(candidate,table='senses'){if(!candidate)throw new Error('Zuerst eine Bedeutung auswählen.');const ref=table==='senses'?candidate.sense.ref:candidate.form_ref;const impact=await api(`/drafts/${state.draft.draft_id}/impact?kind=gloss&table=${table}&ref=${encodeURIComponent(ref)}`);const data=await modal(table==='senses'?'Geteilte Bedeutungsglosse ändern':'Geteilte Formglosse ändern',box=>{box.append(el('p',`${impact.sentence_refs.length} vorhandene Satzkontexte verwenden diese Bedeutung. Historische Kontextübersetzungen bleiben gespeichert. Aktive Kontextänderungen müssen einzeln bestätigt werden.`));const input=field(box,'Neue geteilte Glosse',impact.row.gloss_de);return()=>({gloss:input.value});},'Auswirkungen bestätigen');if(!data)return;await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'set_shared_gloss',lang:state.lang,target_ref:ref,expect:{impact_sha256:impact.sha256},payload:{table,gloss_de:data.gloss,confirmed:true}}]},true);saved();}
function renderPreview(){const node=$('learning-preview');if(!node)return;clear(node);const v=state.detail,c=v.context,points=Array.from(c.text||''),start=c.gap?.start_pos,end=c.gap?.end_pos;if(Number.isInteger(start)&&Number.isInteger(end)){node.append(document.createTextNode(points.slice(0,start).join('')),el('span',v.card.translation_de||'Hinweis fehlt',{class:'gap'}),document.createTextNode(points.slice(end).join('')));}else node.append(el('span',c.text||'Noch kein Übungssatz'));node.append(el('small',c.translation_de||'Deutsche Satzübersetzung fehlt'));if(!Number.isInteger(start))node.append(el('small','Ziellücke noch auswählen.'));const words=el('div',null,{class:'preview-glosses'});for(const t of c.tokens||[])if(t.is_word||t.sense)words.append(el('small',`${t.surface} → ${t.context_gloss_de||'Übersetzung fehlt'}`));node.append(words);}
function renderAlternatives(){const node=$('alternative-preview');if(!node)return;clear(node);const c=state.detail.context,p=Array.from(c.text||'');for(const a of c.valid_alternatives||[])node.append(el('p',Number.isInteger(c.gap?.start_pos)?p.slice(0,c.gap.start_pos).join('')+a+p.slice(c.gap.end_pos).join(''):'Zuerst eine Lücke wählen.'));}
async function retireTarget(view){if(view.story_source)throw new Error('Storyherkünfte werden nicht als globale Aufgabe zurückgestellt.');const impact=await api(`/drafts/${state.draft.draft_id}/impact?kind=retire&ref=${encodeURIComponent(view.ref)}`);const answer=await modal('Aufgabe zurückstellen',box=>{box.append(el('p',`${impact.members.length} Mitglieder in der Lerngruppe, ${impact.shared_contexts.length} geteilte Aufgabenbindungen und ${impact.story_contexts.length} Storybindungen.`));if(impact.members.length>1)box.append(el('p','Fehlende Entscheidung: gültigen Gruppenkopf für die übrigen Mitglieder festlegen.'));if(impact.shared_contexts.length||impact.story_contexts.length)box.append(el('p','Fehlende Entscheidung: aktive geteilte Token- und Storybindungen zuerst korrigieren.'));box.append(el('p','Historische Sätze und Lernidentitäten werden erhalten. Die technische Prüfung kontrolliert alle abhängigen Bindungen.'));return()=>true;},'Rückstellung vormerken');if(!answer)return;await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'retire_target',lang:state.lang,target_ref:view.ref,expect:{...view.before.expect,impact_sha256:impact.sha256},payload:{confirmed:true}}]},true);saved();$('detail').hidden=true;await catalog();}
function renderValidation(){const validation=state.draft?.validation;$('validation-panel').hidden=!validation;if(!validation)return;$('validation-status').textContent=`Technisch: ${labels[validation.technical]} · Redaktionell: ${labels[validation.editorial]}`;clear($('findings'));if(!validation.findings.length)$('findings').append(el('p','Keine technischen Blocker. Die redaktionelle Entscheidung bleibt separat.',{class:'hint'}));for(const finding of validation.findings){const row=el('div',null,{class:'finding'}),body=el('div');body.append(el('strong',finding.message),el('small',`${finding.code} · ${finding.location?.record_ref||''} ${finding.location?.field||''}`));if(finding.location?.record_ref)body.append(button('Aufgabe öffnen',()=>openTarget(finding.location.record_ref)));row.append(el('span',null,{class:'severity'}),body);$('findings').append(row);}}
async function watchJob(job,onDone){state.job=job.job_id;$('job-bar').hidden=false;try{while(true){const current=await api('/jobs/'+job.job_id);$('job-message').textContent=current.message+(current.total!==null?` · ${current.processed}/${current.total}`:'');if(current.state==='succeeded'){if(onDone)await onDone(current.result);return current.result;}if(['failed','cancelled','interrupted'].includes(current.state))throw new Error(current.error?.message||current.message);await new Promise(resolve=>setTimeout(resolve,700));}}finally{state.job=null;$('job-bar').hidden=true;}}
async function validate(){await ensureDraft();if(state.dirty)throw new Error('Detailänderungen zuerst speichern.');const job=await post(`/drafts/${state.draft.draft_id}/validate`,{},true);await watchJob(job,async result=>{state.draft=result.draft;state.etag=result.etag;saved();await catalog();$('validation-panel').scrollIntoView({block:'nearest'});});}
async function review(){if(!state.draft?.validation)throw new Error('Den Entwurf zuerst technisch prüfen.');const diff=await api(`/drafts/${state.draft.draft_id}/diff`);const data=await modal('Redaktionell bestätigen',box=>{box.append(el('p',`${state.draft.target_refs.length} Lernziele und ${state.draft.operations.filter(o=>o.kind==='correct_story_context').length} Storykontexte: Satz, deutsche Übersetzung, Lücke, Wortbedeutungen, Kontextglossen und vollständige Alternativsätze prüfen. Diese Bestätigung gilt für den aktuellen Inhalt.`));const name=field(box,'Prüfperson',''),reason=field(box,'Prüfnotiz','','textarea');return()=>({reviewer:name.value,reason:reason.value,payload_sha256:diff.content_sha256});},'Prüfung bestätigen');if(!data)return;await post(`/drafts/${state.draft.draft_id}/reviews`,data,true);saved();await catalog();}
function download(id){const a=el('a',null,{href:'/api/v1/artifacts/'+id,download:''});document.body.append(a);a.click();a.remove();}
async function exportDraft(){await ensureDraft();const data=await modal('Entwurf exportieren',box=>{const type=field(box,'Exportformat','','select');option(type,'zip','Redaktionelles ZIP · vollständiger Austausch');option(type,'xlsx','Redaktionelle XLSX-Tabelle');option(type,'json','Kanonische JSON-Lieferung');option(type,'release','Neue lokale Releaseversion · mit Dart-Prüfung');const version=field(box,'Versionslabel für Release','editor-'+new Date().toISOString().slice(0,10));box.append(el('p','Ein Release ersetzt kein App-Asset. Es benötigt eine gültige technische Prüfung und eine lokale redaktionelle Bestätigung.'));return()=>({type:type.value,version:version.value});},'Export starten');if(!data)return;if(data.type==='release'){const job=await post(`/drafts/${state.draft.draft_id}/releases`,{version:data.version,validation_sha256:state.draft.validation?.sha256},true);await watchJob(job,async result=>{download(result.artifact_id);await showPage('releases');});}else{const result=await post(`/drafts/${state.draft.draft_id}/exchange`,{format:data.type},true);download(result.artifact_id);}}
async function showPage(page){state.page=page;for(const p of ['content','imports','releases'])$(p+'-page').hidden=p!==page;document.querySelectorAll('[data-page]').forEach(b=>b.classList.toggle('active',b.dataset.page===page));$('breadcrumb').textContent='Redaktion / '+({content:'Inhalte',imports:'Lieferungen',releases:'Versionen'}[page]);if(page==='releases')await releases();await rememberView();}
async function releases(){const records=await api('/releases'),auth=await api('/publisher');clear($('release-list'));await publisherControls($('release-list'));if(state.lang==='en')$('release-list').append(button('Vorhandenes App-Pack als erste interne Version übernehmen',adoptBaseline));for(const r of records.filter(r=>r.lang===state.lang)){const card=el('article',null,{class:'release-card'}),text=el('div'),actions=el('div',null,{class:'inline-actions'});text.append(el('h2',r.version),el('p',(r.publication_kind==='internal-baseline-adoption-v1'?'Interne Bestandsübernahme · keine neue Sprachprüfung · ':'Geprüftes lokales Bundle · ')+ 'Schema 5 · '+r.created_at.slice(0,10)));if(r.publication?.upload_id&&auth.signed_in){try{r.publication=await api(`/releases/${r.release_id}/publication`);}catch(error){r.publication={...r.publication,last_error:{message:error.message}};}}const publication=r.publication;const names={uploading:'Upload begonnen',uploaded:'Hochgeladen · serverseitige Prüfung fehlt',verifying:'Serverprüfung unterbrochen oder noch offen · Prüfung fortsetzen',resume_required:'Prüflauf abgelaufen oder fehlgeschlagen · Wiederaufnahme bestätigen',ready:'Servergeprüft · Veröffentlichung ausstehend',published:'Privat veröffentlicht'};text.append(el('p',publication?(names[publication.status]||publication.status):'Lokal vorbereitet · noch nicht hochgeladen'));if(Number.isInteger(publication?.processed))text.append(el('p',`Serverfortschritt: ${publication.processed} / ${publication.total}${publication.next_stage?' · Nächste Stufe: '+publication.next_stage:''}`));if(publication?.last_error)text.append(el('p','Fehlgeschlagen: '+publication.last_error.message));for(const [phase,label] of [['upload','1 · Privat hochladen'],['finalize','2 · Serverprüfung'],['commit','3 · Veröffentlichen']]){const b=button(phase==='finalize'&&publication?.status==='verifying'?'2 · Prüfung fortsetzen':label,async()=>{if(phase==='commit'){const yes=await modal('Version privat veröffentlichen',box=>{box.append(el('p',`${r.version} wird nach erfolgreicher Versionsprüfung für freigegebene Leser verfügbar. Bereits laufende Übungen bleiben unverändert.`));return()=>true;},'Jetzt veröffentlichen');if(!yes)return;}try{await watchJob(await post(`/releases/${r.release_id}/publish/${phase}`));}finally{await releases();}});b.disabled=publication?.status==='published'||(phase==='finalize'&&publication?.status==='resume_required')||(phase!=='upload'&&!publication?.upload_id)||(phase==='commit'&&publication?.status!=='ready');actions.append(b);}if(publication?.status==='resume_required')actions.append(button('Prüfung ausdrücklich wiederaufnehmen',async()=>{const yes=await modal('Bestehenden Upload erneut prüfen',box=>{box.append(el('p','Dies startet einen neuen serverseitigen Prüflauf für dieselben hochgeladenen Dateien. Die ursprüngliche Uploadfrist bleibt unverändert. Keine neue Sprachfreigabe und keine Veröffentlichung.'));return()=>true;},'Neuen Prüflauf bestätigen');if(yes){try{await watchJob(await post(`/releases/${r.release_id}/publish/resume`,{accepted:true}));}finally{await releases();}}}));if(r.artifact_id)actions.append(button('Bundle herunterladen',()=>download(r.artifact_id)));actions.append(button('Assetübernahme prüfen …',async()=>{const impact=await api(`/releases/${r.release_id}/staging-impact`);const answer=await modal('Separate Assetübernahme',box=>{box.append(el('p',`Ziel: ${impact.destination}. Ausgewählte Version: ${impact.version}. Vorhandenes SQLite und Manifest werden gesichert. Diese Aktion ersetzt das Entwicklungsasset ausdrücklich.`));box.append(el('p','Vorhandener Packhash: '+(impact.existing['content.sqlite']||'Kein Asset')));return()=>true;},'Asset gesichert übernehmen');if(answer)await watchJob(await post(`/releases/${r.release_id}/stage`,{impact_sha256:impact.sha256}));}));card.append(text,actions);$('release-list').append(card);}if(!records.some(r=>r.lang===state.lang))$('release-list').append(el('p','Noch keine lokale Version. Den vorhandenen internen App-Bestand oben übernehmen oder einen bearbeiteten Entwurf prüfen, bestätigen und exportieren.',{class:'hint'}));}
async function importFile(){const file=$('upload-file').files[0];if(!file)throw new Error('Zuerst eine Datei auswählen.');const data=new FormData();data.append('file',file);data.append('lang',state.lang);if($('import-source').value)data.append('source',$('import-source').value);await watchJob(await post('/imports',data),async result=>{const record=await api('/imports/'+result.import_id);renderImport(record);});}
function renderImport(record){const box=clear($('import-preview'));box.hidden=false;box.append(el('span','IMPORTVORSCHAU',{class:'step'}),el('h2',record.filename));const inv=record.preview.inventory,stats=el('div',null,{class:'stats'});for(const [name,value] of [['Erwartet',inv.expected],['Erfasst',inv.processed],['Neu',inv.new_refs.length],['Vorhanden',inv.existing_refs.length],['Unvollständig',inv.incomplete_refs.length],['Konflikte',inv.conflicting_refs.length]]){const cell=el('div');cell.append(el('strong',value),el('span',name));stats.append(cell);}box.append(stats,el('p',`${inv.chunks.length} Blöcke · alle Zielzeilen erfasst. Dateiangaben zur Prüfung erteilen keine lokale Freigabe.`));const findings=el('div');for(const f of record.preview.findings.slice(0,20))findings.append(el('p',`${f.location?.record_ref||''}: ${f.message}`));if(record.preview.findings.length>20)findings.append(el('p',`${record.preview.findings.length-20} weitere Feldhinweise im vollständigen Prüfbericht nach Übernahme.`));box.append(findings,button('Alle Zeilen als neuen Entwurf übernehmen',async()=>{const receipt=await post(`/imports/${record.import_id}/accept`,{preview_sha256:record.preview_sha256});await loadDraft(receipt.draft_id);state.deck=null;await showPage('content');await catalog();},'primary'));if(state.draft)box.append(button('An aktuellen Entwurf anhängen',async()=>{const receipt=await post(`/imports/${record.import_id}/accept`,{preview_sha256:record.preview_sha256,draft_id:state.draft.draft_id},true);await loadDraft(receipt.draft_id);await showPage('content');}));}
async function newDeck(){await ensureDraft();const data=await modal('Neuen Stapel anlegen',box=>{const title=field(box,'Stapelname',''),description=field(box,'Beschreibung','','textarea');return()=>({title:title.value,description:description.value});},'Stapel anlegen');if(!data)return;if(!data.title.trim())throw new Error('Stapelname fehlt.');const ref='deck:'+crypto.randomUUID();await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'create_deck',lang:state.lang,target_ref:ref,expect:{absent:true},payload:{ref,slug:'editor-'+crypto.randomUUID(),title_de:data.title,description_de:data.description,cefr_band:'anfaenger',sort:(state.decks?.length||0)+1}}]},true);state.deck=ref;saved();await catalog();}
async function newTarget(){await ensureDraft();if(!state.decks?.length){await newDeck();}let choices=[];const data=await modal('Neue Aufgabe anlegen',box=>{const form=field(box,'Zielwort oder Ausdruck',''),hint=field(box,'Deutscher Lösungshinweis',''),deck=field(box,'Stapel',state.deck,'select');for(const d of state.decks||[])option(deck,d.ref,d.title_de);if(state.deck)deck.value=state.deck;const sense=field(box,'Bedeutung','','select');option(sense,'','Zielwort eingeben und Bedeutungen laden');box.append(button('Vorhandene Bedeutungen laden',async()=>{choices=await api(`/drafts/${state.draft.draft_id}/vocabulary?surface=${encodeURIComponent(form.value)}`);clear(sense);option(sense,'','Bedeutung auswählen');for(const c of choices)option(sense,c.sense.ref,`${c.lemma.lemma} · ${c.sense.definition_de||c.sense.gloss_de}`);}));box.append(el('p','Die Aufgabe wird zunächst als unvollständiger Entwurf angelegt. Satz, Lücke und Wortbindungen folgen in der Detailansicht. Neue Bedeutungen können dort ausdrücklich angelegt werden.'));return()=>({form:form.value,hint:hint.value,deck:deck.value,sense:sense.value});},'Aufgabe als Entwurf anlegen');if(!data)return;if(!data.form.trim()||!data.deck)throw new Error('Zielwort und Stapel auswählen.');const ref='target:'+crypto.randomUUID();await post(`/drafts/${state.draft.draft_id}/operations`,{operations:[{kind:'create_target',lang:state.lang,target_ref:ref,expect:{absent:true},payload:{deck_ref:data.deck,card:{form:data.form,sense:data.sense||null,translation_de:data.hint,cefr_band:'anfaenger'},context:{text:'',translation_de:'',tokens:[],gap:{},valid_alternatives:[]}}}]},true);state.deck=data.deck;saved();await catalog();await openTarget(ref);}
async function startup(){
  const token=location.hash.slice(1);history.replaceState(null,'',location.pathname);
  if(token){const response=await fetch('/api/v1/session/bootstrap',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token})});const data=await response.json();if(!response.ok)throw new Error(data.message);state.csrf=data.csrf;}else state.csrf=(await api('/session')).csrf;
  const workspace=await api('/workspace-view');state.workspaceId=workspace.workspace_id;state.restoring=true;
  let selection=workspace.selection;
  try{const cached=sessionStorage.getItem('editor-view:'+state.workspaceId);if(cached)selection=JSON.parse(cached);}catch(_){}
  const restored=await post('/workspace-view',{selection});
  state.lang=restored.selection.lang;state.deck=restored.selection.deck;
  await refreshLanguages();await loadDraft(restored.selection.draft_id);await showPage(restored.selection.page);
  state.restoring=false;await rememberView();if(restored.warning||workspace.warning)error(new Error(restored.warning||workspace.warning));
}
document.querySelectorAll('[data-page]').forEach(b=>b.addEventListener('click',act(()=>showPage(b.dataset.page))));
$('language').addEventListener('change',act(async()=>{state.lang=$('language').value;state.deck=null;state.cursor=0;$('search').value='';await loadDraft(null);await refreshLanguages();}));
$('draft-select').addEventListener('change',act(()=>loadDraft($('draft-select').value)));
$('new-draft').addEventListener('click',act(async()=>{await post('/drafts',{lang:state.lang,deck_ref:state.deck});await refreshDrafts();saved();await catalog();}));
$('new-language').addEventListener('click',act(async()=>{const data=await modal('Sprachentwurf anlegen',box=>{const name=field(box,'Anzeigename',''),code=field(box,'Sprachcode (BCP 47)',''),native=field(box,'Name in der Lernsprache','');box.append(el('p','Nur Englisch besitzt derzeit ein geprüftes Profil. Andere Sprachen bleiben bearbeitbare Entwürfe.'));return()=>({lang:code.value,display_name:name.value,name_native:native.value,translation_lang:'de'});},'Sprachentwurf anlegen');if(!data)return;const result=await post('/languages',data);state.lang=result.lang;state.deck=null;state.draft=null;$('search').value='';await refreshLanguages();await loadDraft(null);}));
$('new-deck').addEventListener('click',act(newDeck));$('new-target').addEventListener('click',act(newTarget));
let searchTimer;$('search').addEventListener('input',()=>{clearTimeout(searchTimer);searchTimer=setTimeout(act(async()=>{state.cursor=0;await catalog();}),250);});
$('status-filter').addEventListener('change',act(async()=>{state.cursor=0;await catalog();}));
$('previous').addEventListener('click',act(async()=>{state.cursor=Math.max(0,state.cursor-50);await catalog();}));$('next').addEventListener('click',act(async()=>{state.cursor+=50;await catalog();}));
$('close-detail').addEventListener('click',act(async()=>{if(state.dirty){const answer=await modal('Ungespeicherte Änderungen',box=>{box.append(el('p','Die Änderungen in dieser Detailansicht sind noch nicht gespeichert.'));return()=>true;},'Detailänderungen verwerfen');if(!answer)return;}state.dirty=false;$('detail').hidden=true;}));
$('save-detail').addEventListener('click',act(async()=>{await saveTarget(state.detail);await catalog();}));
$('validate').addEventListener('click',act(validate));$('review').addEventListener('click',act(review));$('export').addEventListener('click',act(exportDraft));
$('discard').addEventListener('click',act(async()=>{const answer=await modal('Entwurf verwerfen',box=>{box.append(el('p','Der Entwurf wird archiviert. Bestehende Releases und Originalinhalte bleiben erhalten.'));return()=>true;},'Entwurf verwerfen');if(answer){await post(`/drafts/${state.draft.draft_id}/discard`,{},true);await loadDraft(null);}}));
$('template').addEventListener('click',act(async()=>{const result=await post('/authoring-contexts',{lang:state.lang,requested_count:Number($('template-count').value),topic:$('template-topic').value});download(result.artifact_id);}));
$('upload').addEventListener('click',act(importFile));$('cancel-job').addEventListener('click',act(async()=>{if(state.job)await post(`/jobs/${state.job}/cancel`);}));
window.addEventListener('beforeunload',event=>{if(state.dirty){event.preventDefault();event.returnValue='';}});
startup().catch(error);

$('mobile-deck').addEventListener('change',act(async()=>{state.deck=$('mobile-deck').value||null;state.cursor=0;await catalog();}));
$('mobile-new-deck').addEventListener('click',act(newDeck));

$('rebase').addEventListener('click',act(async()=>{await ensureDraft();await post(`/drafts/${state.draft.draft_id}/rebase`,{},true);saved();await catalog();}));
$('story-contexts').addEventListener('click',act(async()=>{
  await ensureDraft();if(state.dirty)throw new Error('Detailänderungen zuerst speichern.');
  if(!state.draft.source_history)await watchJob(await post(`/drafts/${state.draft.draft_id}/story-history`,{},true),async r=>{state.draft=r.draft;state.etag=r.etag;saved();});
  const sources=await api(`/drafts/${state.draft.draft_id}/story-contexts`);
  const key=await modal('Geprüfte lokale Storykontexte',box=>{box.append(el('p','Nur zum lokalen Lernen zugelassene Storywörter. Die Herkunft bleibt unverändert; eine Korrektur erzeugt einen neuen Übungskontext für alle belegten Herkunftsversionen.'));
    const select=field(box,'Wort und Übungssatz','','select');for(const s of sources)option(select,s.source_key,s.word+' · '+s.text);if(!sources.length)box.append(el('p','Keine geeigneten lokalen Storyherkünfte in diesem Pack.'));return()=>select.value;},'Kontext bearbeiten');
  if(!key)return;state.detail=await api(`/drafts/${state.draft.draft_id}/story-target?ref=${encodeURIComponent(key)}`);state.dirty=false;renderDetail();$('detail').hidden=false;
}));

async function publisherControls(parent){
  const status=await api('/publisher'),box=el('section',null,{class:'release-card publisher-auth'});
  box.append(el('h2','Private Veröffentlichung'));
  if(!status.configured){box.append(el('p','Privater Inhaltsserver noch nicht eingerichtet. Lokale Prüfung und Export bleiben verfügbar.'));}
  else if(status.signed_in){box.append(el('p','Angemeldet · Publisherrecht wird bei jedem Schritt serverseitig geprüft.'),button('Abmelden',async()=>{await post('/publisher/logout');await releases();}));}
  else{box.append(el('p','Mit der bestehenden E-Mail-Adresse und dem einmalig eingerichteten Passwort anmelden.'));
    const form=el('form',null,{method:'post'});
    const email=field(form,'E-Mail-Adresse','','email');email.autocomplete='username';email.required=true;
    const password=field(form,'Passwort','','password');password.autocomplete='current-password';password.required=true;password.maxLength=4096;
    const login=el('button','Mit Passwort anmelden',{type:'submit',class:'primary'});form.append(login);box.append(form);
    const alternative=el('details');alternative.append(el('summary','Alternativ mit E-Mail-Code'),el('p','Nur verwenden, wenn E-Mail-Zustellung und Codevorlage eingerichtet und geprüft sind.'));
    const code=field(alternative,'E-Mail-Code','','text');code.autocomplete='one-time-code';
    let busy=false;
    async function authenticate(action){if(busy)return;busy=true;login.disabled=true;send.disabled=true;verify.disabled=true;
      try{await action();}finally{busy=false;login.disabled=false;send.disabled=false;verify.disabled=false;}}
    const send=button('Code senden',()=>authenticate(async()=>{await post('/publisher/otp',{email:email.value});error(new Error('Anmeldecode angefordert. Bitte E-Mail prüfen.'));}));
    const verify=button('Mit Code anmelden',()=>authenticate(async()=>{await post('/publisher/verify',{email:email.value,code:code.value});code.value='';password.value='';$('notice').hidden=true;await releases();}));
    alternative.append(send,verify);box.append(alternative);
    form.addEventListener('submit',act(async event=>{event.preventDefault();await authenticate(async()=>{await post('/publisher/password',{email:email.value,password:password.value});password.value='';$('notice').hidden=true;await releases();});}));}
  parent.append(box);
}

async function adoptBaseline(event){
  if(state.adoptionBusy)return;
  state.adoptionBusy=true;
  const trigger=event?.currentTarget;if(trigger)trigger.disabled=true;
  try{
  const view=await api('/baseline-adoption');
  const answer=await modal('Internen App-Bestand übernehmen',box=>{
    box.append(el('p',view.notice),el('h3',view.source.version),
      el('p',`${view.counts.cards} Karten · ${view.counts.decks} Stapel · ${view.counts.form_targets} Formziele`),
      el('p','Neue lokale Version: '+view.version),
      el('h3','Vorhandene Nachweise'),el('p',view.existing_evidence.source_notes),el('p',view.existing_evidence.qa_scope),
      el('h3','Offene Befunde'));
    const findings=el('ul');for(const finding of view.open_findings)findings.append(el('li',finding));box.append(findings);
    const details=el('details');details.append(el('summary','Gebundene Quelle und Nachweishashes'));
    for(const [key,value] of Object.entries(view.source)){const line=el('p',key+': '+value);line.style.overflowWrap='anywhere';details.append(line);}box.append(details);
    box.append(el('p','Die Vorbereitung erfolgt lokal. Ob der private Cloudkanal leer ist, wird erst beim späteren Hochladen serverseitig geprüft.'));
    return()=>({preview_sha256:view.sha256,accepted:true});
  },'Diesen internen Bestand übernehmen');
  if(!answer)return;
  await watchJob(await post('/baseline-adoption',answer));await releases();
  }finally{state.adoptionBusy=false;if(trigger)trigger.disabled=false;}
}
