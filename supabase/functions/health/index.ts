// Health check: GET → {"ok": true, "time": <ISO>}. JWT verification stays on (config.toml).
Deno.serve((req) => {
  if (req.method !== "GET") {
    return new Response(null, { status: 405, headers: { Allow: "GET" } });
  }
  return Response.json({ ok: true, time: new Date().toISOString() });
});
