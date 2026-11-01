import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DailyNewsBackend, dailyNewsHandler, LANGUAGES, validStories } from './daily_news.ts';
import { MODEL } from './runtime_translation.ts';

const urls = ['https://news.example/a', 'https://news.example/b', 'https://news.example/c',
  'https://news.example/d'];
const searchBlock = { type: 'web_search_tool_result', tool_use_id: 'srv_1',
  content: urls.map((url, i) => ({ type: 'web_search_result', url, title: `Story ${i}` })) };
const stories = [0, 1, 2, 3].map((i) => ({ headline: `Headline ${i}`,
  facts: `Fact one about ${i}. Fact two about ${i}. Fact three about ${i}.`,
  sources: [{ title: `Story ${i}`, url: urls[i] }] }));
const sentence = (n: number) => ({ text: `Sentence ${n}.`, de: `Satz ${n}.` });
const article = (story: number) => ({ story, title: `Title ${story}`, sections: [
  { heading: 'First', sentences: [sentence(1), sentence(2)] },
  { heading: 'Second', sentences: [sentence(3), sentence(4)] },
] });

type Options = { pause?: boolean; invented?: boolean; failLang?: string; refuse?: boolean };
function fixture(options: Options = {}) {
  const bodies: Record<string, unknown>[] = [];
  const stored: Record<string, unknown>[] = [];
  let researchCalls = 0;
  const fetcher = (async (url: string | URL, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body));
    if (String(url).endsWith('/rest/v1/rpc/store_news')) {
      stored.push(body);
      return new Response('{"stored":1}', { status: 200 });
    }
    bodies.push(body);
    if (body.tools) {
      researchCalls++;
      if (options.refuse) {
        return Response.json({ model: MODEL, stop_reason: 'refusal', content: [] });
      }
      if (options.pause && researchCalls === 1) {
        return Response.json({ model: MODEL, stop_reason: 'pause_turn',
          content: [{ type: 'server_tool_use', id: 'srv_1', name: 'web_search', input: {} }, searchBlock] });
      }
      const reported = options.invented
        ? stories.map((s) => ({ ...s, sources: [{ title: 'x', url: 'https://invented.example/x' }] }))
        : stories;
      return Response.json({ model: MODEL, stop_reason: 'tool_use', content: [
        ...(options.pause ? [] : [searchBlock]),
        { type: 'tool_use', id: 'toolu_1', name: 'report_stories', input: { stories: reported } },
      ] });
    }
    const lang = Object.entries(LANGUAGES).find(([, name]) => body.system.includes(name))![0];
    if (lang === options.failLang) return new Response('{}', { status: 529 });
    return Response.json({ model: MODEL, stop_reason: 'end_turn', content: [
      { type: 'text', text: JSON.stringify({ articles: [3, 1, 0, 2].map(article) }) }] });
  }) as typeof fetch;
  const backend = new DailyNewsBackend('https://project.example', 'service', 'key', 'secret-123', fetcher);
  const handler = dailyNewsHandler(backend, () => new Date('2026-11-01T04:00:00Z'));
  const call = (body: unknown, secret = 'secret-123') => handler(new Request('https://f/refresh-news', {
    method: 'POST', headers: { 'x-news-secret': secret }, body: JSON.stringify(body) }));
  return { call, bodies, stored };
}

test('one desk: research once, every language stored in story order', async () => {
  const f = fixture();
  const response = await f.call({ category: 'politics' });
  assert.equal(response.status, 200);
  const result = await response.json();
  assert.deepEqual(result.stored.sort(), Object.keys(LANGUAGES).sort());
  assert.deepEqual(result.failed, []);
  assert.equal(f.bodies.filter((b) => b.tools).length, 1);
  const research = f.bodies.find((b) => b.tools)!;
  assert.equal(research.model, MODEL);
  assert.deepEqual((research.tools as { type?: string }[])[0],
    { type: 'web_search_20250305', name: 'web_search', max_uses: 5 });
  const en = f.stored.find((s) => s.p_lang === 'en')!;
  assert.equal(en.p_edition, '2026-11-01');
  assert.equal(en.p_category, 'politics');
  const articles = en.p_articles as Record<string, unknown>[];
  assert.deepEqual(articles.map((a) => a.title), ['Title 0', 'Title 1', 'Title 2', 'Title 3']);
  assert.deepEqual(articles.map((a) => a.id), [1, 2, 3, 4].map((n) => `2026-11-01-en-politics-${n}`));
  assert.deepEqual(articles[0].sources, [{ title: 'Story 0', url: urls[0] }]);
  const writing = f.bodies.find((b) => !b.tools)!;
  assert.deepEqual(writing.thinking, { type: 'disabled' });
  assert.equal((writing.output_config as { format: { type: string } }).format.type, 'json_schema');
});

test('a paused search turn is resumed without an extra user message', async () => {
  const f = fixture({ pause: true });
  assert.equal((await f.call({ category: 'economy' })).status, 200);
  const research = f.bodies.filter((b) => b.tools);
  assert.equal(research.length, 2);
  const messages = research[1].messages as { role: string }[];
  assert.deepEqual(messages.map((m) => m.role), ['user', 'assistant']);
});

test('sources must come from the search results', async () => {
  const f = fixture({ invented: true });
  const response = await f.call({ category: 'technology' });
  assert.equal(response.status, 502);
  assert.deepEqual(await response.json(), { error: 'TOO_FEW_STORIES' });
  assert.equal(f.stored.length, 0);
});

test('a failing language keeps its old edition, the others are stored', async () => {
  const f = fixture({ failLang: 'nb' });
  const result = await (await f.call({ category: 'medicine' })).json();
  assert.equal(result.stored.includes('nb'), false);
  assert.deepEqual(result.failed, ['nb:MODEL_UNAVAILABLE']);
  assert.equal(f.stored.length, Object.keys(LANGUAGES).length - 1);
});

test('refusals, wrong secrets and unknown desks start no paid work', async () => {
  assert.equal((await fixture({ refuse: true }).call({ category: 'politics' })).status, 502);
  const f = fixture();
  assert.equal((await f.call({ category: 'politics' }, 'wrong-secret')).status, 401);
  assert.equal((await f.call({ category: 'politics' }, '')).status, 401);
  assert.equal((await f.call({ category: 'sports' })).status, 400);
  assert.equal(f.bodies.length, 0);
});

test('stories need three usable entries with known https sources', () => {
  const seen = new Map(urls.map((u) => [u, 'x']));
  assert.equal(validStories({ stories }, seen).length, 4);
  assert.throws(() => validStories({ stories: stories.slice(0, 2) }, seen));
  const http = stories.map((s) => ({ ...s, sources: [{ title: 'x', url: s.sources[0].url.replace('https', 'http') }] }));
  assert.throws(() => validStories({ stories: http }, seen));
});
