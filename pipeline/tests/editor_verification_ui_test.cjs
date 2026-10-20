// Actual release UI with isolated synthetic DOM/HTTP, never a live editor.
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
class Element{
  constructor(tag){this.tag=tag;this.children=[];this.listeners={};this.attrs={};}
  append(...v){this.children.push(...v);} replaceChildren(...v){this.children=v;}
  setAttribute(k,v){this.attrs[k]=v;} addEventListener(k,v){(this.listeners[k]??=[]).push(v);}
}
const list=new Element('div'),calls=[];
const context=vm.createContext({document:{getElementById:()=>list,createElement:tag=>new Element(tag)},crypto:{randomUUID:()=> 'test'},sessionStorage:{setItem(){}}});
const source=fs.readFileSync('pipeline/src/sprachpipe/editor/web/app.js','utf8');
vm.runInContext(source.split("\ndocument.querySelectorAll('[data-page]')")[0]+'\n'+source.split('\n').find(x=>x.startsWith('async function releases()')),context);
context.calls=calls;
context.adoptBaseline=async()=>{throw new Error('Unrelated adoption action must not run');};
vm.runInContext(`var remoteStatus='verifying',consent=false;
  publisherControls=async()=>{};
  api=async (path,options)=>{if(options?.method==='POST'){calls.push({method:'POST',path,body:options.body});return {};}calls.push({method:'GET',path});if(path==='/publisher')return {signed_in:true};
    if(path==='/releases')return [{release_id:'test',lang:'en',version:'v',created_at:'2026-10-18',publication:{upload_id:'same',status:'uploaded'}}];
    return {upload_id:'same',status:remoteStatus,processed:4,total:14,next_stage:'F4'};};
  modal=async()=>consent;watchJob=async()=>{};
`,context);
const all=node=>[node,...node.children.flatMap(all)];
const button=label=>all(list).find(x=>x.tag==='button'&&x.textContent===label);
async function test(){
  await vm.runInContext('releases()',context);
  assert(calls.some(x=>x.path==='/releases/test/publication'));
  assert(button('2 · Prüfung fortsetzen'));
  assert(button('3 · Veröffentlichen').disabled);
  assert(all(list).some(x=>String(x.textContent).includes('Serverfortschritt: 4 / 14')));
  vm.runInContext("remoteStatus='resume_required'",context);await vm.runInContext('releases()',context);
  assert(button('2 · Serverprüfung').disabled);
  await button('Prüfung ausdrücklich wiederaufnehmen').listeners.click[0]();
  assert(!calls.some(x=>x.method==='POST'));
  vm.runInContext('consent=true',context);
  await button('Prüfung ausdrücklich wiederaufnehmen').listeners.click[0]();
  const posts=calls.filter(x=>x.method==='POST');assert.equal(posts.length,1);
  assert.equal(posts[0].path,'/releases/test/publish/resume');assert.equal(posts[0].body.accepted,true);
  assert(!posts.some(x=>x.path.endsWith('/commit')));
  console.log('PASS: server progress, restart status, explicit resume consent, separate publish');
}
test().catch(e=>{console.error(e);process.exitCode=1;});
