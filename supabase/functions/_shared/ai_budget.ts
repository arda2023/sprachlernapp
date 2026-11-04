import { TranslationError } from './runtime_errors.ts';

export type AiFeature = 'lookup-word' | 'translate-sentence' | 'personal-learning' |
  'topic-check' | 'generated-vocabulary';
type Rpc = (name: string, body: Record<string, any>, signal: AbortSignal) => Promise<Record<string, any>>;
const limits: Record<AiFeature, number> = {
  'lookup-word': 384, 'translate-sentence': 384, 'personal-learning': 1500,
  'topic-check': 128, 'generated-vocabulary': 16000,
};

/** Reserve before dispatch, even across endpoints. Unknown outcomes retain the
 * full reservation. Never refund on timeout, HTTP error or invalid usage.
 * The database, not the client or this worker, owns prices and the monthly cap.
 */
export async function budgetedAnthropicFetch(
  user: string, feature: AiFeature, rpc: Rpc, fetcher: typeof fetch,
  init: RequestInit,
): Promise<Response> {
  const signal = init.signal ?? AbortSignal.timeout(25000);
  const body = JSON.parse(String(init.body));
  // No paid tools, caching, fast mode, other models or implicit SDK retries.
  const allowed = ['model', 'max_tokens', 'thinking', 'system', 'messages', 'output_config'];
  if (body.model !== 'claude-haiku-5-5' || body.max_tokens !== limits[feature] ||
      body.thinking?.type !== 'disabled' || Object.keys(body).some(k => !allowed.includes(k)) ||
      !Array.isArray(body.messages) || body.messages.length !== 1 ||
      body.messages[0].role !== 'user' || typeof body.messages[0].content !== 'string' ||
      typeof body.system !== 'string' || new Headers(init.headers).has('anthropic-beta')) {
    throw new TranslationError('AI_BUDGET_UNAVAILABLE', 503);
  }
  signal.throwIfAborted();
  const attempt = crypto.randomUUID();
  const claim = await rpc('reserve_ai_spend', {
    p_user: user, p_attempt: attempt, p_feature: feature,
  }, signal);
  if (claim.status === 'limit') throw new TranslationError('AI_MONTHLY_LIMIT', 429);
  if (claim.status !== 'reserved') throw new TranslationError('AI_BUDGET_UNAVAILABLE', 503);
  signal.throwIfAborted();
  const response = await fetcher('https://api.anthropic.com/v1/messages', {
    ...init, signal, redirect: 'error',
  });
  if (!response.ok || !response.body) return response;
  // Consume only once with a bounded stream; never clone an unbounded response.
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  const abort = () => { void reader.cancel().catch(() => {}); };
  signal.addEventListener('abort', abort, { once: true });
  try {
    signal.throwIfAborted();
    while (true) {
      const part = await reader.read();
      signal.throwIfAborted();
      if (part.done) break;
      length += part.value.length;
      if (length > 300000) throw new TranslationError('MODEL_INVALID', 502);
      chunks.push(part.value);
    }
  } finally {
    signal.removeEventListener('abort', abort);
    void reader.cancel().catch(() => {});
    reader.releaseLock();
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  // Settlement is based only on the authenticated provider envelope, before
  // application validation. Invalid vocabulary still incurred provider costs.
  try {
    const envelope = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    const usage = envelope.usage;
    const input = usage?.input_tokens, output = usage?.output_tokens;
    if (envelope.model === body.model && Number.isSafeInteger(input) && input >= 0 &&
        input <= 1000000 && Number.isSafeInteger(output) && output >= 0 &&
        output <= limits[feature] && !(usage.cache_creation_input_tokens > 0) &&
        !(usage.cache_read_input_tokens > 0) && !usage.server_tool_use) {
      await rpc('settle_ai_spend', { p_user: user, p_attempt: attempt,
        p_input_tokens: input, p_output_tokens: output }, AbortSignal.timeout(4000));
    }
  } catch { /* Keep the full hold if the provider usage or acknowledgement is unknown. */ }
  return new Response(bytes, { status: response.status, headers: response.headers });
}
