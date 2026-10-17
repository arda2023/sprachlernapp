// Test gateway only. Real Auth/PostgREST/Storage are reached through local Kong.
// No cloud fallback and no recursive worker calls.
const metrics: unknown[] = [];
const mode = Deno.env.get('PROBE_MODE');
Deno.serve({port:9000}, async request => {
  const url = new URL(request.url);
  if (url.pathname === '/health') return Response.json({ready:true});
  if (url.pathname === '/metrics') return Response.json(metrics);
  if (url.pathname === '/metric') {
    metrics.push(await request.json());
    return Response.json({ok:true});
  }
  try {
    const worker = await EdgeRuntime.userWorkers.create({
      servicePath: mode === 'original' ? '/work/functions/content-publish' : '/work/probe',
      memoryLimitMb:256, workerTimeoutMs:150000,
      cpuTimeSoftLimitMs:1000, cpuTimeHardLimitMs:2000,
      forceCreate:Deno.env.get('PROBE_POLICY') === 'oneshot', noModuleCache:false,
      envVars:[['SUPABASE_URL','http://kong:8000'],
        ['SUPABASE_SERVICE_ROLE_KEY',Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!],
        ['PROBE_RPC',Deno.env.get('PROBE_RPC')!]],
    });
    return await worker.fetch(request);
  } catch {
    return Response.json({code:'LOCAL_WORKER_ABORT'}, {status:546});
  }
});
