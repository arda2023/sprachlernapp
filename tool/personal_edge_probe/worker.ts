// Local probe bootstrap only. Production entrypoint/modules are copied unchanged.
// All outbound requests are forced to loopback fixtures; no provider can be called.
const realFetch=globalThis.fetch;
globalThis.fetch=(input,init)=>{
 const url=new URL(typeof input==='string'?input:input instanceof URL?input.href:input.url);
 if(url.origin==='https://synthetic.invalid')return realFetch('http://localhost:9000'+url.pathname+url.search,init);
 if(url.href==='https://api.anthropic.com/v1/messages')return realFetch('http://localhost:9000/synthetic-anthropic',init);
 throw new Error('Probe blocks non-fixture network');
};
const parse=JSON.parse;
let builds=0,peakObserved=0;
function sample(){const m=Deno.memoryUsage();peakObserved=Math.max(peakObserved,m.heapUsed+m.external);return m;}
JSON.parse=function(...args){sample();const result=parse.apply(JSON,args);if(result?.cards&&result?.lemmas){builds++;sample();}return result;};
const serve=Deno.serve;
Deno.serve=function(handler){return serve(async req=>{
 const start=performance.now(),before=sample(),initial=builds;
 const timer=setInterval(sample,2);
 try{const result=await handler(req);console.log(JSON.stringify({probe:'request',status:result.status,wall_ms:performance.now()-start,builds_delta:builds-initial,builds_total:builds,peak_observed_heap_external:peakObserved,before,after:sample()}));return result;}
 finally{clearInterval(timer);}
});};
await import('../functions/create-learning-card/index.ts');
