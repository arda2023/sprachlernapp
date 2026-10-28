import {test} from 'node:test';
import assert from 'node:assert/strict';
import {PersonalTrace} from './personal_trace.ts';
test('trace is content-free, bounded and request-local even on emitter failure',()=>{
 const lines:string[]=[];const a=new PersonalTrace(s=>lines.push(s)),b=new PersonalTrace(s=>lines.push(s));
 a.enter('model_request');b.enter('pack');a.fail('private text bearer secret',502);b.fail('REFERENCE_INVALID',422);
 assert.notEqual(a.id,b.id);assert.ok(!lines.join('').includes('private text'));
 const records=lines.map(s=>JSON.parse(s));
 assert.equal(records.at(-2).code,'SERVICE_UNAVAILABLE');
 assert.equal(records.at(-1).stage,'pack');
 assert.ok(records.every(r=>Object.keys(r).every(k=>['component','diagnostic_id','stage','event','elapsed_ms','stage_ms','code','http_status'].includes(k))));
 assert.doesNotThrow(()=>new PersonalTrace(()=>{throw Error('private');}).enter('auth'));
});

test('provider error diagnostics are a closed vocabulary, never raw messages',()=>{
 const lines:string[]=[];const trace=new PersonalTrace(s=>lines.push(s));
 for(const [type,message,expected]of [
  ['invalid_request_error','Your credit balance is too low to access the Anthropic API. PRIVATE','PROVIDER_CREDIT'],
  ['invalid_request_error','Schema is too complex for compilation. PRIVATE','PROVIDER_SCHEMA_COMPLEXITY'],
  ['invalid_request_error','PRIVATE unknown reason','PROVIDER_INVALID_REQUEST'],
  ['PRIVATE','PRIVATE','PROVIDER_ERROR_UNCLASSIFIED'],
  ['authentication_error','PRIVATE','PROVIDER_AUTH'],
 ]){trace.providerFailure({error:{type,message}});assert.equal(JSON.parse(lines.at(-1)!).code,expected);}
 trace.providerFailure(null);trace.providerFailure({error:{message:{private:'PRIVATE'}}});
 assert.ok(!lines.join('').includes('PRIVATE'));
});
