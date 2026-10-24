import { test } from "node:test";
import assert from "node:assert/strict";
import {
  MODEL,
  TranslationBackend,
  translationHandler,
  validateInput,
} from "./runtime_translation.ts";
const actor = "00000000-0000-4000-8000-000000000001";
const other = "00000000-0000-4000-8000-000000000002";
const request = {
  contract: 2,
  lang: "en",
  target_lang: "de",
  sentence: "bank bank",
  form: "bank",
  start: 0,
  end: 4,
  sense_ref: null,
  form_ref: null,
};
function fixture({ invalid = false, failSave = false, hang = false } = {}) {
  const rows = new Map<
    string,
    { status: string; ticket: string; response?: any }
  >();
  let generations = 0, budget = 0;
  const keys: string[] = [];
  const fetcher: typeof fetch = async (url, init = {}) => {
    if (String(url).endsWith("/auth/v1/user")) {
      const token = (init.headers as any).Authorization;
      return Response.json({
        id: token === "Bearer other" ? other : actor,
        is_anonymous: token === "Bearer anonymous",
      });
    }
    const body = JSON.parse(String(init.body));
    if (String(url).includes("/rpc/")) {
      const key = body.p_user + ":" + body.p_key;
      if (String(url).endsWith("/claim_translation")) {
        keys.push(body.p_key);
        const old = rows.get(key);
        if (old) {
          return Response.json(
            old.status === "ready"
              ? { status: "hit", response: old.response }
              : { status: "busy" },
          );
        }
        budget++;
        rows.set(key, { status: "pending", ticket: actor });
        return Response.json({ status: "claimed", ticket: actor });
      }
      if (String(url).endsWith("/finish_translation")) {
        if (failSave) return Response.json({}, { status: 503 });
        const old = rows.get(key);
        const stored = old?.status === "pending" &&
          old.ticket === body.p_ticket;
        if (stored) {
          rows.set(key, {
            status: "ready",
            ticket: actor,
            response: body.p_response,
          });
        }
        return Response.json({ stored });
      }
      if (String(url).endsWith("/clear_translation_cache")) {
        for (const [key, row] of rows) {
          if (key.startsWith(body.p_user + ":")) {
            if (row.status === "ready") rows.delete(key);
            else row.status = "uncertain";
          }
        }
        return Response.json({ deleted: true });
      }
      throw Error("Unexpected RPC");
    }
    generations++;
    if (hang) {
      return await new Promise((_, reject) =>
        init.signal!.addEventListener("abort", () => reject(Error("synthetic")))
      );
    }
    const input = JSON.parse(body.messages[0].content);
    return Response.json({
      model: MODEL,
      stop_reason: "end_turn",
      usage: { input_tokens: 20, output_tokens: 8 },
      content: [{
        type: "text",
        text: JSON.stringify(
          invalid ? {} : input.form
            ? {
              senses: [{
                lemma: input.form,
                pos: "noun",
                form_label: "Singular",
                gloss_de: "Synthetische Bedeutung",
              }],
            }
            : { translation_de: "Ein synthetischer Satz." },
        ),
      }],
    });
  };
  const backend = new TranslationBackend(
    "https://fixture.invalid",
    "service-synthetic",
    "api-synthetic",
    fetcher,
    hang ? 30 : 1000,
  );
  async function run(
    input: any = request,
    token = "actor",
    kind: "lookup-word" | "translate-sentence" = "lookup-word",
    method = "POST",
  ) {
    const response = await translationHandler(kind, backend)(
      new Request("https://fixture.invalid", {
        method,
        headers: { Authorization: "Bearer " + token },
        body: method === "POST" ? JSON.stringify(input) : undefined,
      }),
    );
    return { status: response.status, body: await response.json() };
  }
  return {
    run,
    keys,
    rows,
    get generations() {
      return generations;
    },
    get budget() {
      return budget;
    },
  };
}
test("persistent server hit: one model call and one budget reservation for two requests", async () => {
  const f = fixture();
  const first = await f.run();
  const second = await f.run();
  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.equal(second.body.cached, true);
  assert.equal(first.body.request_id, second.body.request_id);
  assert.equal(f.generations, 1);
  assert.equal(f.budget, 1);
});
test("simultaneous requests never duplicate paid work; follower is bounded busy or hit", async () => {
  const f = fixture();
  const results = await Promise.all(Array.from({ length: 8 }, () => f.run()));
  assert(results.some((r) => r.status === 200));
  assert(results.every((r) => [200, 409].includes(r.status)));
  assert.equal(f.generations, 1);
  assert.equal(f.budget, 1);
});
test("owner separation, anonymous rejection and deletion limited to authenticated owner", async () => {
  const f = fixture();
  await f.run();
  await f.run(request, "other");
  assert.equal(f.generations, 2);
  assert.equal((await f.run(request, "anonymous")).status, 401);
  assert.equal(
    (await f.run({}, "actor", "translate-sentence", "DELETE")).status,
    200,
  );
  assert.equal((await f.run(request, "other")).body.cached, true);
  assert.equal(f.generations, 2);
  assert.equal(f.rows.size, 1);
});
test("same sentence different position/sense/form reference/language has separate keys", async () => {
  const f = fixture();
  for (
    const input of [
      request,
      { ...request, start: 5, end: 9 },
      { ...request, sense_ref: "river" },
      { ...request, sense_ref: "finance" },
      { ...request, form_ref: "verb" },
      { ...request, lang: "pt-BR" },
      { ...request, sentence: "bank bank!" },
    ]
  ) assert.equal((await f.run(input)).status, 200);
  assert.equal(new Set(f.keys).size, 7);
  assert.equal(f.generations, 7);
});
test("accent spelling and word/sentence operations remain distinct", async () => {
  const f = fixture();
  for (const form of ["avó", "avo", "avo\u0301"]) {
    await f.run({
      ...request,
      lang: "pt-BR",
      form,
      sentence: form,
      start: 0,
      end: form.length,
    });
  }
  await f.run(
    { lang: "pt-BR", target_lang: "de", text: "avó" },
    "actor",
    "translate-sentence",
  );
  assert.equal(new Set(f.keys).size, 4);
  assert.equal(f.generations, 4);
});
test("ambiguous legacy word or invalid UTF16 span fails before auth/budget", async () => {
  const f = fixture();
  assert.equal(
    (await f.run({ ...request, start: undefined, end: undefined })).status,
    422,
  );
  assert.equal((await f.run({ ...request, start: 1, end: 5 })).status, 422);
  assert.equal((await f.run({ ...request, contract: 99 })).status, 422);
  assert.equal(f.budget, 0);
  const value = validateInput("lookup-word", {
    lang: "pt-BR",
    target_lang: "de",
    sentence: "🙂 avó",
    form: "avó",
    start: 3,
    end: 6,
  });
  assert.equal(value.start, 3);
});
for (const options of [{ invalid: true }, { failSave: true }, { hang: true }]) {
  test(`uncertain/invalid/failed-save result never cached or automatically regenerated ${JSON.stringify(options)}`, async () => {
    const f = fixture(options);
    const first = await f.run();
    assert([502, 503, 504].includes(first.status));
    const second = await f.run();
    assert.equal(second.status, 409);
    assert.equal(f.generations, 1);
    assert.equal(f.budget, 1);
    assert([...f.rows.values()].every((row) => !row.response));
    await f.run({}, "actor", "translate-sentence", "DELETE");
    assert.equal((await f.run()).status, 409);
    assert.equal(f.generations, 1);
  });
}
test("cached corrupted output fails closed without budget/model call", async () => {
  const f = fixture();
  await f.run();
  const row = [...f.rows.values()][0];
  row.response.senses = [];
  assert.equal((await f.run()).status, 503);
  assert.equal(f.generations, 1);
  assert.equal(f.budget, 1);
});
