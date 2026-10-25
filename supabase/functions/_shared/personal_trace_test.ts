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
