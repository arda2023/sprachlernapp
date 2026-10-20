import {streamPack} from './stream_pack_probe.ts';
import {digest} from '../../../supabase/functions/_shared/content_distribution.ts';

function input(raw:string,chunk=7) {
  const b=new TextEncoder().encode(raw);
  return new ReadableStream<Uint8Array>({start(c){for(let i=0;i<b.length;i+=chunk)c.enqueue(b.slice(i,i+chunk));c.close();}});
}
const cases=[
  '{"z":1,"a":2,"2":"two","10":"ten"}',
  '{"x":1,"x":2,"release":{"created_at":"old","version":"v"},"release":{"version":"last","created_at":"new"}}',
  '{"__proto__":{"polluted":true},"constructor":4,"nested":{"__proto__":7}}',
  '{"a":[-0,1e3,1e-7,1e21,9007199254740993,1e400,-1e400,0.000001,1.234567890123456789]}',
  '{"é":"é","😀":"\\ud800","\\ue000":"\\ud83d\\ude00","esc":"\\/\\b\\f\\n\\r\\t\\\\\\\""}',
  '{"release":{"created_at":"x","nested":{"created_at":"keep"}},"created_at":"keep","a":[3,2,1]}',
  'null','true','123','"scalar"','[]','{}',
];
for(const [i,raw] of cases.entries()) Deno.test('stream contract '+i,async()=>{
  const actual=(await streamPack(input(raw,1))).value,expected=JSON.parse(raw);
  if(digest(actual)!==digest(expected))throw Error('full canonical mismatch');
  if(expected?.release) {
    const a={...actual,release:{...actual.release}},b={...expected,release:{...expected.release}};
    delete a.release.created_at;delete b.release.created_at;
    if(digest(a)!==digest(b))throw Error('normalized canonical mismatch');
  }
});
for(const raw of ['{"x":1,}','{"x":01}','{"x":NaN}','[1] trailing','{"x":"\\uZZZZ"}','{"x":'])
  Deno.test('reject '+raw,async()=>{
    let rejected=false;try{await streamPack(input(raw));}catch{rejected=true;}
    if(!rejected)throw Error('invalid JSON accepted');
  });
Deno.test('strict UTF8',async()=>{
  let rejected=false;try{await streamPack(new ReadableStream({start(c){c.enqueue(new Uint8Array([34,255,34]));c.close();}}));}catch{rejected=true;}
  if(!rejected)throw Error('invalid UTF8 accepted');
});

// Characterization of a blocker, NOT an acceptance test for production adoption.
// Parser.js uses JS \s, which accepts whitespace excluded by JSON.parse.
for(const raw of ['\u00a0{}','{"x":\u20281}']) Deno.test('BLOCKER: broader whitespace '+JSON.stringify(raw),async()=>{
  let nativeRejects=false;try{JSON.parse(raw);}catch{nativeRejects=true;}
  if(!nativeRejects)throw Error('fixture must be invalid JSON');
  const result=await streamPack(input(raw));
  if(!result.value)throw Error('expected library acceptance to document compatibility gap');
});
