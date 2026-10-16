// Actual publisher UI, synthetic DOM/transport: no browser or cloud credentials.
const assert=require('node:assert/strict');
const fs=require('node:fs');const vm=require('node:vm');
class Element{
  constructor(tag){this.tag=tag;this.children=[];this.attrs={};this.value='';this.listeners={};}
  append(...nodes){this.children.push(...nodes);}
  replaceChildren(...nodes){this.children=nodes;}
  setAttribute(k,v){this.attrs[k]=v;}
  addEventListener(k,fn){(this.listeners[k]??=[]).push(fn);}
}
const notice=new Element('div');const writes=[];const calls=[];
const context=vm.createContext({document:{getElementById:()=>notice,createElement:tag=>new Element(tag)},
  crypto:{randomUUID:()=> 'synthetic-id'},sessionStorage:{setItem:(...args)=>writes.push(args)}});
const source=fs.readFileSync('pipeline/src/sprachpipe/editor/web/app.js','utf8');
vm.runInContext(source.split("\ndocument.querySelectorAll('[data-page]')")[0]+'\n'+source.slice(source.indexOf('async function publisherControls(')),context);
context.parent=new Element('div');context.calls=calls;
vm.runInContext(`var fail=true,refreshed=0;
  api=async(path,options)=>{if(!options)return {configured:true,signed_in:false};calls.push({path,body:options.body});if(fail)throw new Error('Passwort ist falsch.');};
  releases=async()=>{refreshed++;};`,context);
const flatten=node=>[node,...node.children.flatMap(flatten)];
async function test(){
  await vm.runInContext('publisherControls(parent)',context);
  const nodes=flatten(context.parent),form=nodes.find(n=>n.tag==='form');
  const inputs=nodes.filter(n=>n.tag==='input');const [email,password,code]=inputs;
  assert.equal(password.type,'password');assert.equal(password.autocomplete,'current-password');
  assert.equal(email.autocomplete,'username');assert.equal(code.autocomplete,'one-time-code');
  assert.equal(nodes.find(n=>n.tag==='details').open,undefined);
  assert.equal(calls.length,0);email.value='existing@example.test';password.value='synthetic-password';
  let prevented=0;await form.listeners.submit[0]({preventDefault(){prevented++;}});
  assert.equal(prevented,1);assert.equal(password.value,'synthetic-password');
  assert.equal(notice.hidden,false);assert.equal(nodes.find(n=>n.attrs.type==='submit').disabled,false);
  assert.equal(calls[0].path,'/publisher/password');assert.equal(writes.length,0);
  vm.runInContext('fail=false',context);
  await form.listeners.submit[0]({preventDefault(){}});
  assert.equal(password.value,'');assert.equal(notice.hidden,true);
  assert.equal(vm.runInContext('refreshed',context),1);
  assert.equal(calls.every(c=>c.path==='/publisher/password'),true);
  assert.equal(writes.length,0);
  console.log('PASS: masked password, autocomplete, explicit OTP, safe retry, field cleared, no credential storage');
}
test().catch(error=>{console.error(error);process.exitCode=1;});
