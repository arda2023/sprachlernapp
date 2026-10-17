// Local integration instrumentation only: production handler and real backend.
import {DistributionBackend,handler} from '../functions/_shared/content_distribution.ts';
Deno.serve(async request=>{
  let bytes=0,requests=0;const samples:any[]=[];
  const sample=(name:string)=>samples.push({name,memory:Deno.memoryUsage()});
  class Instrumented extends DistributionBackend {
    override async object(id:string,name:string,d:any,read=false){const value=await super.object(id,name,d,read);sample(name);return value;}
    override async json(path:string,method='GET',body?:any):Promise<any>{
      const value=await super.json(path,method,body);
      if(body?.p_op==='claim'&&request.headers.get('x-local-abort-after-claim')==='yes'){
        let sum=0;for(let i=0;i<2_000_000_000;i++)sum=(sum+i)|0;
        throw new Error('Abort injection did not fire '+sum);
      }
      return value;
    }
  }
  const backend=new Instrumented(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,async(...args)=>{
    requests++;const r=await fetch(...args);
    return r.body?new Response(r.body.pipeThrough(new TransformStream({transform(chunk,c){bytes+=chunk.byteLength;c.enqueue(chunk);}})),{status:r.status,headers:r.headers}):r;
  });
  sample('begin');const begin=performance.now();
  let response:Response;
  if(new URL(request.url).pathname==='/oracle'){
    const actor=await backend.actor(request);await backend.publisher(actor);
    const u=await backend.upload((await request.json()).upload_id,actor);
    const old=await import('../oracle/content_distribution.ts');
    response=Response.json(await old.verifyBundle(backend as any,u));
  }else response=await handler('publish',backend)(request);
  sample('end');
  await fetch('http://localhost:9000/metric',{method:'POST',body:JSON.stringify({
    path:new URL(request.url).pathname,requests,bytes,wall_ms:performance.now()-begin,samples,status:response.status})});
  return response;
});
