import { test } from 'node:test';
import assert from 'node:assert/strict';
import { GeneratedVocabularyBackend, generatedVocabularyHandler } from './generated_vocabulary.ts';
import { MODEL } from './runtime_translation.ts';

const requestId = '12345678-1234-4234-8234-123456789abc';
const input = { contract: 1, request_id: requestId, lang: 'en',
  prompt: 'Vokabeln zum Thema Medizin', count: 50, consent: 1 };
const item = { form: 'brain', lemma: 'brain', pos: 'NOUN', gloss_de: 'Gehirn',
  definition_de: 'Das zentrale Organ des Nervensystems.', form_detail: 'Substantiv im Singular',
  sentence: 'The brain controls movement.', translation_de: 'Das Gehirn steuert Bewegungen.', start: 4 };

const { start: _start, ...providerItem } = item;

type Options = { claim?: string; auth?: number; provider?: unknown; providerStatus?: number;
  budget?: string; admitted?: boolean; wait?: Promise<void>; finish?: 'lost' | 'stale'; hang?: boolean; apiKey?: string };
function fixture(options: Options = {}) {
  let models = 0, claims = 0, failures = 0, finishes = 0;
  let ready: unknown, pending = false, failed = false;
  let modelBody: Record<string, unknown> | undefined;
  const bodies: Record<string, unknown>[] = [];
  const fetcher: typeof fetch = async (url, init) => {
    if (String(url).endsWith('/reserve_ai_spend')) return Response.json({ status: options.budget ?? 'reserved' });
    if (String(url).endsWith('/settle_ai_spend')) return Response.json({ status: 'settled' });
    const path = String(url);
    const body = init?.body ? JSON.parse(String(init.body)) : null;
    if (path.endsWith('/auth/v1/user')) return Response.json({ id: requestId,
      is_anonymous: false }, { status: options.auth ?? 200 });
    if (path.endsWith('/claim_generated_vocabulary')) {
      claims++; bodies.push(body);
      if (options.claim) return Response.json({ status: options.claim });
      if (ready) return Response.json({ status: 'hit', response: ready });
      if (failed) return Response.json({ status: 'failed' });
      if (pending) return Response.json({ status: 'busy' });
      if (body.p_status_only) return Response.json({ status: 'missing' });
      pending = true;
      return Response.json({ status: 'claimed', ticket: requestId });
    }
    if (path.endsWith('/finish_generated_vocabulary')) {
      finishes++;
      if (options.finish === 'stale') return Response.json({ status: 'stale' });
      ready = body.p_response;
      if (options.finish === 'lost') throw Error('lost acknowledgement');
      return Response.json({ status: 'saved' });
    }
    if (path.endsWith('/fail_generated_vocabulary')) {
      failures++; failed = true; return Response.json({ status: 'ok' });
    }
    assert.equal(path, 'https://api.anthropic.com/v1/messages');
    assert.equal(new Headers(init?.headers).get('x-api-key'), 'server-only');
    assert.equal(init?.redirect, 'error');
    if (body.max_tokens === 128) return Response.json({ model: MODEL, stop_reason: 'end_turn',
      usage: { input_tokens: 100, output_tokens: 4 },
      content: [{ type: 'text', text: JSON.stringify({ allowed: options.admitted ?? true }) }] });
    models++; modelBody = body;
    await options.wait;
    if (options.hang) return await new Promise<Response>((_, reject) => {
      if (init?.signal?.aborted) reject(Error('aborted'));
      init?.signal?.addEventListener('abort', () => reject(Error('aborted')), { once: true });
    });
    return Response.json(options.provider ?? { model: MODEL, stop_reason: 'end_turn',
      usage: { input_tokens: 100, output_tokens: 100 },
      content: [{ type: 'text', text: JSON.stringify({ items: [providerItem] }) }] },
      { status: options.providerStatus ?? 200 });
  };
  const handler = generatedVocabularyHandler(new GeneratedVocabularyBackend(
    'https://example.test', 'service', options.apiKey ?? 'server-only', fetcher, options.hang ? 20 : 1000));
  return { handler, run: (value: unknown = input, status = false) => handler(new Request(
    'https://example.test/generate-vocabulary' + (status ? '?status=1' : ''), {
      method: 'POST', headers: { Authorization: 'Bearer synthetic' }, body: JSON.stringify(value) })),
    stats: () => ({ models, claims, failures, finishes, bodies, modelBody }) };
}

test('one provider call produces validated suggestions and repeat/status reads reuse it', async () => {
  const f = fixture();
  const result = await f.run();
  assert.equal(result.status, 200);
  assert.equal(result.headers.get('Cache-Control'), 'no-store');
  assert.deepEqual(await result.json(), { contract: 1, request_id: requestId, lang: 'en', items: [item] });
  assert.equal((await f.run()).status, 200);
  assert.equal((await f.run(input, true)).status, 200);
  assert.equal(f.stats().models, 1);
  assert.equal(f.stats().finishes, 1);
  assert.equal(f.stats().modelBody?.model, MODEL);
  assert.equal(f.stats().modelBody?.max_tokens, 16000);
  assert.equal(f.stats().bodies[0].p_hash, f.stats().bodies[2].p_hash);
  assert.equal(f.stats().bodies[0].p_user, requestId);
  assert.equal(JSON.stringify(f.stats().bodies).includes(input.prompt), false);
});

test('parallel repeated clicks cannot create parallel model calls', async () => {
  let release!: () => void;
  const wait = new Promise<void>(resolve => release = resolve);
  const f = fixture({ wait });
  const first = f.run();
  while (f.stats().models === 0) await new Promise(resolve => setTimeout(resolve, 1));
  const others = await Promise.all(Array.from({ length: 8 }, () => f.run()));
  assert.ok(others.every(response => response.status === 409));
  assert.equal(f.stats().models, 1);
  release();
  assert.equal((await first).status, 200);
});

test('status-only missing never starts a provider request', async () => {
  const f = fixture();
  const result = await f.run(input, true);
  assert.equal(result.status, 404);
  assert.deepEqual(await result.json(), { error: 'REQUEST_MISSING' });
  assert.equal(f.stats().models, 0);
});

test('lost finish acknowledgement can be recovered without charging again', async () => {
  const f = fixture({ finish: 'lost' });
  assert.equal((await f.run()).status, 503);
  assert.equal(f.stats().failures, 0);
  assert.equal((await f.run(input, true)).status, 200);
  assert.equal(f.stats().models, 1);
});

test('stale ticket never delivers unsaved cards', async () => {
  const f = fixture({ finish: 'stale' });
  const response = await f.run();
  assert.equal(response.status, 409);
  assert.deepEqual(await response.json(), { error: 'REQUEST_UNCERTAIN' });
  assert.equal(f.stats().failures, 0);
});

test('failed or malformed provider outputs fail closed and never auto-retry', async () => {
  const validEnvelope = { model: MODEL, stop_reason: 'end_turn', content: [{ type: 'text', text: '{"items":[]}' }] };
  for (const provider of [null, {}, { ...validEnvelope, model: 'other-model' },
    { ...validEnvelope, stop_reason: 'max_tokens' }, { ...validEnvelope, content: [] },
    { ...validEnvelope, content: [{ type: 'text', text: 'not json' }] },
    { ...validEnvelope, content: [{ type: 'text', text: JSON.stringify({ items: [{ ...item, start: 1 }] }) }] }]) {
    const f = fixture({ provider: provider ?? 'invalid' });
    assert.equal((await f.run()).status, 502);
    assert.equal(f.stats().finishes, 0);
    assert.equal(f.stats().failures, 1);
    assert.equal((await f.run()).status, 409);
    assert.equal(f.stats().models, 1);
  }
  const refusal = fixture({ provider: validEnvelope });
  assert.equal((await refusal.run()).status, 422);
});

test('auth, confirmation, quotas and conflicts deny before provider', async () => {
  for (const [claim, status] of [['account_unverified', 403], ['limit', 429], ['conflict', 409],
    ['busy', 409], ['uncertain', 409], ['failed', 409], ['expired', 410]] as const) {
    const f = fixture({ claim });
    assert.equal((await f.run()).status, status);
    assert.equal(f.stats().models, 0);
  }
  const auth = fixture({ auth: 401 });
  assert.equal((await auth.run()).status, 401);
  assert.equal(auth.stats().claims, 0);
  const config = fixture({ apiKey: '' });
  assert.equal((await config.run()).status, 503);
  assert.equal(config.stats().claims, 0);
});

test('Premium denial blocks generation and status reads before any model or storage write', async () => {
  const f = fixture({ claim: 'premium_required' });
  for (const status of [false, true]) {
    const response = await f.run(input, status);
    assert.equal(response.status, 403);
    assert.deepEqual(await response.json(), { error: 'PREMIUM_REQUIRED' });
  }
  assert.equal(f.stats().models, 0);
  assert.equal(f.stats().finishes, 0);
  assert.equal(f.stats().failures, 0);
});

test('request boundaries reject unsupported fields, missing consent and excessive text', async () => {
  const f = fixture();
  for (const invalid of [{ ...input, count: 51 }, { ...input, consent: 0 },
    { ...input, lang: 'de' }, { ...input, api_key: 'injection' },
    { ...input, prompt: 'x'.repeat(401) }, { ...input, prompt: 'One. Two. Three.' }]) {
    assert.equal((await f.run(invalid)).status, 422);
  }
  assert.equal((await f.run({ ...input, prompt: 'x'.repeat(10000) })).status, 413);
  assert.equal(f.stats().claims, 0);
  assert.equal((await f.handler(new Request('https://example.test'))).status, 405);
  assert.equal((await f.handler(new Request('https://example.test', { method: 'POST', body: '{}' }))).status, 401);
});

test('bounded provider timeout persists a failed attempt instead of retrying', async () => {
  const f = fixture({ hang: true });
  const response = await f.run();
  assert.equal(response.status, 504);
  assert.equal(f.stats().failures, 1);
  assert.equal(f.stats().models, 1);
});


test('server derives exact UTF16 word offsets, including astral characters and repeated words', async () => {
  for (const [sentence, start] of [
    ['🧠 The brain controls movement.', 7],
    ['The brain studies another brain.', 4],
  ] as const) {
    const f = fixture({ provider: { model: MODEL, stop_reason: 'end_turn',
      content: [{ type: 'text', text: JSON.stringify({ items: [{ ...providerItem, sentence }] }) }] } });
    const response = await f.run();
    assert.equal(response.status, 200);
    assert.equal((await response.json()).items[0].start, start);
  }
});

test('absent, case-mismatched and substring-only target words are rejected', async () => {
  for (const sentence of ['The brainstem controls movement.', 'A Brain controls movement.', 'The organ controls movement.']) {
    const f = fixture({ provider: { model: MODEL, stop_reason: 'end_turn',
      content: [{ type: 'text', text: JSON.stringify({ items: [{ ...providerItem, sentence }] }) }] } });
    const response = await f.run();
    assert.equal(response.status, 502);
    assert.equal((await response.json()).diagnostic, 'word occurrence');
    assert.equal(f.stats().finishes, 0);
  }
});


test('partial batches preserve validated cards and omit malformed or duplicate candidates', async () => {
  const f = fixture({ provider: { model: MODEL, stop_reason: 'end_turn',
    content: [{ type: 'text', text: JSON.stringify({ items: [
      { ...providerItem, sentence: 'The organ controls movement.' },
      providerItem, providerItem, { ...providerItem, start: 99 },
    ] }) }] } });
  const response = await f.run();
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).items, [item]);
  assert.equal(f.stats().models, 1);
});

test('accepted batch is capped to requested count without extra model calls', async () => {
  const other = { ...providerItem, form: 'movement', lemma: 'movement' };
  const f = fixture({ provider: { model: MODEL, stop_reason: 'end_turn',
    content: [{ type: 'text', text: JSON.stringify({ items: [providerItem, other] }) }] } });
  const response = await f.run({ ...input, count: 1 });
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).items, [item]);
  assert.equal(f.stats().models, 1);
});


test('off-task classification blocks generation and consumes no retry automatically', async () => {
  const f = fixture({ admitted: false });
  const response = await f.run({ ...input, prompt: 'Erkläre mir Diabetes' });
  assert.equal(response.status, 422);
  assert.deepEqual(await response.json(), { error: 'TOPIC_NOT_ALLOWED' });
  assert.equal(f.stats().models, 0);
  assert.equal(f.stats().failures, 1);
});
test('questions are refused before reservation or provider; monthly limit blocks both AI stages', async () => {
  const question = fixture();
  assert.equal((await question.run({ ...input, prompt: 'Was ist Diabetes?' })).status, 422);
  assert.equal(question.stats().claims, 0);
  assert.equal(question.stats().models, 0);
  const f = fixture({ budget: 'limit' });
  const response = await f.run();
  assert.equal(response.status, 429);
  assert.deepEqual(await response.json(), { error: 'AI_MONTHLY_LIMIT' });
  assert.equal(f.stats().models, 0);
});
