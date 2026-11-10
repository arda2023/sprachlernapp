import { test } from 'node:test';
import assert from 'node:assert/strict';
import { withBrowserCors } from './browser_cors.ts';

const origin = 'https://example.pages.dev';

test('preflight permits bearer JSON and deletion without invoking handler', async () => {
  let calls = 0;
  const handler = withBrowserCors(() => { calls++; throw new Error('must not run'); });
  for (const method of ['POST', 'DELETE']) {
    const response = await handler(new Request('https://example.test/endpoint', {
      method: 'OPTIONS', headers: { Origin: origin,
        'Access-Control-Request-Method': method,
        'Access-Control-Request-Headers': 'authorization,content-type,apikey,x-client-info' },
    }));
    assert.equal(response.status, 204);
    assert.equal(await response.text(), '');
    assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
    assert.match(response.headers.get('Access-Control-Allow-Methods')!, new RegExp(method));
    for (const header of ['authorization','content-type','apikey','x-client-info']) {
      assert.ok(response.headers.get('Access-Control-Allow-Headers')!.includes(header));
    }
    assert.equal(response.headers.has('Access-Control-Allow-Credentials'), false);
  }
  assert.equal(calls, 0);
});

test('real requests preserve bearer identity, success payload and response metadata', async () => {
  const request = new Request('https://example.test/endpoint', { method: 'POST',
    headers: { Origin: origin, Authorization: 'Bearer test-token', 'Content-Type': 'application/json' }, body: '{"text":"hello"}' });
  const handler = withBrowserCors(async (received) => {
    assert.equal(received, request);
    assert.equal(received.headers.get('Authorization'), 'Bearer test-token');
    assert.equal(await received.text(), '{"text":"hello"}');
    return Response.json({ok:true}, { status:201, headers:{'Cache-Control':'no-store','X-Request-Id':'request-a'} });
  });
  const response=await handler(request);
  assert.equal(response.status,201);
  assert.deepEqual(await response.json(),{ok:true});
  assert.equal(response.headers.get('Cache-Control'),'no-store');
  assert.equal(response.headers.get('X-Request-Id'),'request-a');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'),'*');
});

test('authentication, method and quota errors retain status and safe body with CORS', async () => {
  for (const status of [401,403,405,409,422,429,502,503,504]) {
    const response=await withBrowserCors(() => Response.json({error:'original'}, {status,headers:{'Retry-After':'5'}}))(
      new Request('https://example.test/endpoint',{method:'DELETE'}));
    assert.equal(response.status,status);
    assert.deepEqual(await response.json(),{error:'original'});
    assert.equal(response.headers.get('Retry-After'),'5');
    assert.equal(response.headers.get('Access-Control-Allow-Origin'),'*');
  }
});

test('unexpected handler failures receive safe CORS error without leaking details', async () => {
  const response=await withBrowserCors(() => { throw new Error('secret internal payload'); })(new Request('https://example.test'));
  assert.equal(response.status,500);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'),'*');
  assert.equal(response.headers.get('Cache-Control'),'no-store');
  assert.equal((await response.text()).includes('secret'),false);
});

test('all browser endpoint entrypoints are actually wrapped, including DELETE translation cache', async () => {
  const callbacks: ((request: Request) => Promise<Response>)[]=[];
  const previous=(globalThis as any).Deno;
  (globalThis as any).Deno={env:{get:()=>undefined},serve:(handler:any)=>callbacks.push(handler)};
  try {
    for (const name of ['lookup-word','translate-sentence','create-learning-card','generate-vocabulary','billing-sync','delete-account']) {
      await import(`../${name}/index.ts`);
    }
    assert.equal(callbacks.length,6);
    for (const handler of callbacks) {
      const preflight=await handler(new Request('https://example.test',{method:'OPTIONS'}));
      assert.equal(preflight.status,204);
      const denied=await handler(new Request('https://example.test',{method:'POST',body:'{}'}));
      assert.equal(denied.headers.get('Access-Control-Allow-Origin'),'*');
      assert.ok(denied.status>=400);
    }
  } finally { (globalThis as any).Deno=previous; }
});
