import { test } from "node:test";
import assert from "node:assert/strict";
import {
  MODEL,
  TranslationBackend,
  translationHandler,
  validateInput,
} from "./runtime_translation.ts";

const uid = "12345678-1234-4234-8234-123456789abc";
const sentence = { lang: "en", target_lang: "de", text: "She knelt down." };
const word = {
  lang: "pt-BR",
  target_lang: "de",
  form: "banco",
  sentence: "Ela sentou no banco.",
};
const sense = {
  pos: "substantivo",
  form_label: "Substantiv",
  gloss_de: "Bank zum Sitzen",
  lemma: "banco",
};
function fixture(
  options: {
    auth?: number;
    allowed?: object;
    model?: object;
    status?: number;
    hang?: boolean;
    timeout?: number;
  } = {},
) {
  const calls: { url: string; init: RequestInit }[] = [];
  const fetcher: typeof fetch = async (url, init = {}) => {
    calls.push({ url: String(url), init });
    if (String(url).endsWith("/auth/v1/user")) {
      return Response.json({ id: uid }, { status: options.auth ?? 200 });
    }
    if (String(url).endsWith("/rpc/claim_translation")) {
      const allowed = options.allowed as { reason?: string } | undefined;
      return Response.json(
        allowed
          ? { status: allowed.reason }
          : { status: "claimed", ticket: uid },
      );
    }
    if (String(url).endsWith("/rpc/finish_translation")) {
      return Response.json({ stored: true });
    }
    if (options.hang) {
      return await new Promise((_, reject) =>
        init.signal!.addEventListener(
          "abort",
          () => reject(new Error("aborted")),
        )
      );
    }
    const body = JSON.parse(String(init.body));
    const input = JSON.parse(body.messages[0].content);
    return Response.json(
      options.model ?? {
        model: MODEL,
        stop_reason: "end_turn",
        content: [{
          type: "text",
          text: JSON.stringify(
            input.form
              ? { senses: [sense] }
              : { translation_de: "Sie kniete sich hin." },
          ),
        }],
        usage: { input_tokens: 205, output_tokens: 8 },
      },
      { status: options.status ?? 200 },
    );
  };
  const backend = new TranslationBackend(
    "https://project.supabase.co",
    "test-service-value",
    "test-api-value",
    fetcher,
    options.timeout ?? 1000,
  );
  return {
    calls,
    run: async (
      input: object = sentence,
      token: string | null = "user-token",
      kind: "lookup-word" | "translate-sentence" = "translate-sentence",
    ) => {
      const response = await translationHandler(kind, backend)(
        new Request("https://local.test", {
          method: "POST",
          headers: token ? { Authorization: "Bearer " + token } : {},
          body: JSON.stringify(input),
        }),
      );
      return {
        status: response.status,
        body: await response.json(),
        headers: response.headers,
      };
    },
    backend,
  };
}
for (const lang of ["en", "pt-BR"]) {
  test(`sentence contract ${lang}, fixed direct model and minimal input`, async () => {
    const f = fixture();
    const r = await f.run({ ...sentence, lang, import_id: "ignored" });
    assert.equal(r.status, 200);
    assert.equal(r.body.translation_de, "Sie kniete sich hin.");
    assert.equal(r.body.model, MODEL);
    assert.equal(r.headers.get("cache-control"), "no-store");
    assert.equal(r.body.request_id, r.headers.get("x-request-id"));
    assert.equal(f.calls.length, 4); // auth, atomic claim, model, validated save
    const call = f.calls[2];
    assert.equal(call.url, "https://api.anthropic.com/v1/messages");
    const data = JSON.parse(String(call.init.body));
    assert.equal(data.model, MODEL);
    assert.equal(data.max_tokens, 384);
    assert.deepEqual(data.thinking, { type: "disabled" });
    assert.equal(data.output_config.effort, "low");
    assert.deepEqual(
      JSON.parse(data.messages[0].content),
      validateInput("translate-sentence", { ...sentence, lang }),
    );
    assert(!JSON.stringify(r.body).includes("test-api-value"));
    assert(!JSON.stringify(r.body).includes(uid));
  });
}
for (const lang of ["en", "pt-BR"]) {
  test(`word context contract ${lang}`, async () => {
    const f = fixture();
    const input = lang === "en"
      ? { ...word, lang, form: "bank", sentence: "She sat on the bank." }
      : word;
    const r = await f.run(
      { ...input, sentence_id: "ignored" },
      "user-token",
      "lookup-word",
    );
    assert.equal(r.status, 200);
    assert.deepEqual(r.body.senses, [sense]);
    assert.equal(r.body.form, input.form);
    assert.deepEqual(
      JSON.parse(JSON.parse(String(f.calls[2].init.body)).messages[0].content),
      validateInput("lookup-word", input),
    );
  });
}
test("missing JWT never calls auth, quota or provider", async () => {
  const f = fixture();
  assert.equal((await f.run(sentence, null)).status, 401);
  assert.equal(f.calls.length, 0);
});
test("invalid JWT never calls quota or provider", async () => {
  const f = fixture({ auth: 401 });
  assert.equal((await f.run()).status, 401);
  assert.equal(f.calls.length, 1);
});
for (const [reason, status] of [["forbidden", 403], ["limit", 429]] as const) {
  test(`reservation ${reason} prevents provider call`, async () => {
    const f = fixture({ allowed: { allowed: false, reason } });
    assert.equal((await f.run()).status, status);
    assert.equal(f.calls.length, 2);
  });
}
for (
  const input of [
    { ...sentence, lang: "fr" },
    { ...sentence, target_lang: "en" },
    { ...sentence, text: "x".repeat(601) },
    { ...sentence, profile: { name: "private" } },
    { ...sentence, text: "" },
  ]
) {
  test(`invalid input ${JSON.stringify(input).slice(0, 80)}`, async () => {
    const f = fixture();
    assert.equal((await f.run(input)).status, 422);
    assert.equal(f.calls.length, 0);
  });
}
test("word must occur in context", async () => {
  const f = fixture();
  assert.equal(
    (await f.run({ ...word, form: "other" }, "user-token", "lookup-word"))
      .status,
    422,
  );
  assert.equal(f.calls.length, 0);
});
test("provider rate limit has no retry or fallback", async () => {
  const f = fixture({ status: 429 });
  const r = await f.run();
  assert.equal(r.status, 429);
  assert.equal(r.body.error, "PROVIDER_RATE_LIMIT");
  assert.equal(f.calls.length, 3);
});
for (
  const model of [{ model: "gemini" }, {
    model: MODEL,
    stop_reason: "max_tokens",
    content: [],
  }, {
    model: MODEL,
    stop_reason: "end_turn",
    content: [{ type: "text", text: '{"translation_de":""}' }],
  }]
) {
  test(`reject invalid model result ${JSON.stringify(model)}`, async () => {
    const f = fixture({ model });
    assert.equal((await f.run()).status, 502);
    assert.equal(f.calls.length, 3);
  });
}
test("provider timeout fails safely, no retry", async () => {
  const f = fixture({ hang: true, timeout: 15 });
  const r = await f.run();
  assert.equal(r.status, 504);
  assert.equal(r.body.error, "TIMEOUT");
  assert.equal(f.calls.length, 3);
});
test("stalled input body is cancelled on deadline", async () => {
  const f = fixture({ timeout: 15 });
  const req = new Request(
    "https://local.test",
    {
      method: "POST",
      headers: { Authorization: "Bearer user-token" },
      body: new ReadableStream(),
      duplex: "half",
    } as RequestInit,
  );
  const r = await translationHandler("translate-sentence", f.backend)(req);
  assert.equal(r.status, 504);
  assert.equal(f.calls.length, 0);
});
test("oversized request is rejected before auth", async () => {
  const f = fixture();
  assert.equal(
    (await f.run({ ...sentence, text: "x".repeat(5000) })).status,
    413,
  );
  assert.equal(f.calls.length, 0);
});
