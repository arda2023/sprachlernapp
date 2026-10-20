// Runs the actual UI functions with deferred HTTP replies to reproduce click races.
const assert=require('node:assert/strict');
const fs=require('node:fs');const vm=require('node:vm');
class Element{
 constructor(tag){this.tag=tag;this.children=[];this.attrs={};this.value='';this.isConnected=true;this.listeners={};}
 append(...nodes){this.children.push(...nodes);}
 replaceChildren(...nodes){this.children=nodes;}
 setAttribute(k,v){this.attrs[k]=v;}
 addEventListener(k,fn){(this.listeners[k]??=[]).push(fn);}
}
const editor=new Element('div');const nodes={'token-editor':editor};
const context=vm.createContext({document:{getElementById:id=>nodes[id],createElement:tag=>new Element(tag)},crypto:{randomUUID:()=> 'test'},console,sessionStorage:{setItem(){}}});
const source=fs.readFileSync('pipeline/src/sprachpipe/editor/web/app.js','utf8').split("\ndocument.querySelectorAll('[data-page]')")[0];
vm.runInContext(source,context);
async function race(){
 vm.runInContext(`state.detail={context:{tokens:[]}};state.draft={draft_id:'test'};var pending=[];api=()=>new Promise(resolve=>pending.push(resolve));var a={surface:'print',sense:'print'},b={surface:'paper',sense:'paper'};var first=editToken(a);var second=editToken(b);`,context);
 const choice=word=>[{sense:{ref:word,gloss_de:word,definition_de:word},lemma:{lemma:word,pos:'NOUN'},form:{gloss_de:word}}];
 context.resolveB=choice('paper');context.resolveA=choice('print');
 await vm.runInContext('pending[1](resolveB);second',context);
 await vm.runInContext('pending[0](resolveA);first',context);
 const selects=editor.children.filter(n=>n.tag==='div').flatMap(n=>n.children).filter(n=>n.tag==='select');
 assert.equal(selects.length,1);assert.equal(selects[0].value,'paper');
 // Same token clicked twice: latest response also wins, listeners aren't stacked.
 vm.runInContext('pending=[];first=editToken(a);second=editToken(a);',context);
 await vm.runInContext('pending[0](resolveA);first',context);
 await vm.runInContext('pending[1](resolveA);second',context);
 const fields=editor.children.filter(n=>n.tag==='div').flatMap(n=>n.children).filter(n=>n.tag==='select');
 assert.equal(fields.length,1);assert.equal(fields[0].listeners.change.length,1);
 // Closing/replacing a detail invalidates an outstanding response.
 vm.runInContext('pending=[];first=editToken(a);state.detail={context:{tokens:[]}};',context);
 await vm.runInContext('pending[0](resolveA);first',context);
 assert.equal(editor.children.length,1);
 console.log('PASS: reverse responses, repeated click, single listener, stale detail');
}
race().catch(e=>{console.error(e);process.exitCode=1;});
