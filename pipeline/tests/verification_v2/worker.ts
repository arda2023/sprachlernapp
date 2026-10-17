// Diagnostic workloads, NOT a replacement validator or deployable v2 endpoint.
// The unmodified original handler is run separately against the same real services.
import {DistributionBackend, canonical, digest, requireThat} from '../functions/_shared/content_distribution.ts';
const base = new DistributionBackend(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
Deno.serve(async request => {
  const start = performance.now(), samples: unknown[] = [];
  let requests = 0, bytes = 0;
  const sample = (name:string) => samples.push({name, memory:Deno.memoryUsage()});
  const backend = new DistributionBackend(base.url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, async (...args) => {
    requests++;
    const response = await fetch(...args);
    if (!response.body) return response;
    return new Response(response.body.pipeThrough(new TransformStream({
      transform(chunk, controller) {bytes += chunk.byteLength; controller.enqueue(chunk);},
    })), {status:response.status, headers:response.headers});
  });
  let phase='auth';
  try {
    const actor = await backend.actor(request); await backend.publisher(actor);
    const data = await request.json(); phase=data.phase;
    const u = await backend.upload(data.upload_id,actor);
    if (phase==='state') {
      // Test-only state protocol, always unable to set a real upload ready/published.
      const result=await backend.json('/rest/v1/rpc/'+Deno.env.get('PROBE_RPC'),
        'POST',{actor,upload_id:u.id,op:data.op==='abort_after_claim'?'claim':data.op,input:data.input??{}});
      if(data.op==='abort_after_claim') {
        // Deliberate LOCAL failure injection, bounded by the 2s supervisor.
        // The lease is durable; no result or upload status is written afterward.
        let sum=0;for(let i=0;i<2_000_000_000;i++)sum=(sum+i)|0;
        return Response.json({code:'ABORT_NOT_OBSERVED',sum},{status:500});
      }
      return Response.json(result);
    }
    requireThat(Date.parse(u.expires_at)>Date.now(),'UPLOAD_EXPIRED',409);
    const read=async (name:string) => {
      const value=await backend.object(u.id,name,u.objects[name],true); sample('read:'+name);return value;
    };
    sample('begin');
    let result: unknown = {ok:true};
    if(phase==='file') await backend.object(u.id,data.name,u.objects[data.name]);
    else if(phase==='sidecars') {
      const m=await read('content.manifest.json');
      requireThat(canonical(m)===canonical(u.draft_manifest),'MANIFEST_CHANGED');
      const report=await read('finalization_report.json'),reviews=await read('editorial_reviews.json');
      const v={...report.validation};delete v.sha256;
      requireThat(digest(v)===report.validation.sha256,'VALIDATION_HASH');
      requireThat(digest(reviews)===m.editorial_reviews_sha256,'REVIEW_UNBOUND');
      const inv=await read('history_inventory.json'),reg=await read('registry.json');
      requireThat(digest(inv)===m.history_inventory_sha256&&digest(reg)===m.registry_sha256,'SIDECAR_HASH');
      await read('provenance.json');
    } else if(['pack_parse','pack_full_hash','pack_content_hash','pack_both_hashes'].includes(phase)) {
      const pack=await read('pack.json');
      if(phase==='pack_full_hash'||phase==='pack_both_hashes') result={full:digest(pack)};
      if(phase==='pack_content_hash'||phase==='pack_both_hashes') {
        const content={...pack,release:{...pack.release}};delete content.release.created_at;
        result={...result as object,content:digest(content)};
      }
    } else if(phase==='history') {
      // Same real bytes as both sides, to measure the current-size comparison.
      // This is not a claimed normal release/Parent-CAS integration test.
      const registry=await read('registry.json'),inventory=await read('history_inventory.json');
      const oldRegistry=await read('registry.json'),old=await read('history_inventory.json');
      const words=new Map(registry.words.map((w:any)=>[w.lang+'|'+w.form_norm,w]));
      requireThat(words.size===registry.words.length,'REGISTRY_INVALID');
      for(const word of oldRegistry.words)requireThat(canonical(words.get(word.lang+'|'+word.form_norm))===canonical(word),'REGISTRY_HISTORY_LOSS');
      for(const [table,entries] of Object.entries(old.tables) as [string,Record<string,string>][]) {
        for(const [id,hash] of Object.entries(entries)) {
          requireThat(inventory.tables[table]?.[id],'HISTORY_LOSS');
          if(['sentences','sentence_tokens','card_sentences','story_context_corrections'].includes(table))requireThat(inventory.tables[table][id]===hash,'CONTEXT_HISTORY_LOSS');
        }
      }
      const snapshots=new Set((inventory.story_source_snapshots??[]).map(canonical));
      for(const source of old.story_source_snapshots??[])requireThat(snapshots.has(canonical(source)),'STORY_HISTORY_LOSS');
    } else throw new Error('Unknown probe phase');
    sample('end');
    await fetch('http://localhost:9000/metric',{method:'POST',body:JSON.stringify({phase,
      bytes,backend_requests:requests,elapsed_ms:performance.now()-start,samples})});
    return Response.json(result);
  } catch(e) {
    const code = typeof e?.code === 'string' ? e.code : 'PROBE_FAILED';
    return Response.json({code},{status:e?.status??400});
  }
});
