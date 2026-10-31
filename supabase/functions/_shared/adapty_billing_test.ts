import {
  AdaptyBillingBackend,
  billingSyncHandler,
  constantTimeEqual,
  deriveEntitlement,
  webhookHandler,
} from "./adapty_billing.ts";

const userId = "12345678-1234-4234-8234-123456789abc";
const otherUserId = "22345678-1234-4234-8234-123456789abc";
const profileId = "32345678-1234-4234-8234-123456789abc";
const monthly = "com.ardasayar.linglossa.premium.monthly";
const yearly = "com.ardasayar.linglossa.premium.yearly";
const observedAt = new Date("2026-10-31T12:00:00Z");

function profile(
  environment = "Production",
  productId = monthly,
  expiresAt: string | null = "2026-11-30T12:00:00Z",
) {
  return {
    profile_id: profileId,
    customer_user_id: userId,
    access_levels: [{
      access_level_id: "premium",
      store_product_id: productId,
      store_transaction_id: "tx-1",
      starts_at: "2026-10-01T12:00:00Z",
      expires_at: expiresAt,
      renewal_cancelled_at: null,
    }],
    subscriptions: [{
      store_product_id: productId,
      store_transaction_id: "tx-1",
      environment,
      will_renew: true,
    }],
  };
}

function backend(options: {
  profileValue?: Record<string, unknown>;
  bindingUserId?: string;
  calls?: string[];
} = {}) {
  const calls = options.calls ?? [];
  const client = new AdaptyBillingBackend(
    "https://supabase.example.test",
    "server-service-key",
    "server-adapty-key",
    async (input, init) => {
      const url = String(input);
      calls.push(url);
      if (url.endsWith("/auth/v1/user")) {
        return Response.json({
          id: userId,
          is_anonymous: false,
          email_confirmed_at: "2026-10-01T12:00:00Z",
        });
      }
      if (url.includes("/rest/v1/")) {
        const headers = new Headers(init?.headers);
        if (
          headers.get("Accept-Profile") !== "app" ||
          headers.get("Content-Profile") !== "app"
        ) {
          throw new Error("Billing RPC/table request must target app schema");
        }
      }
      if (url.includes("api.adapty.io")) {
        const headers = new Headers(init?.headers);
        if (headers.get("adapty-customer-user-id") !== userId) {
          return Response.json({ error: "wrong customer" }, { status: 400 });
        }
        return Response.json({
          data: options.profileValue ?? profile("Sandbox"),
        });
      }
      if (url.includes("adapty_profile_bindings")) {
        return Response.json([{ user_id: options.bindingUserId ?? userId }]);
      }
      if (url.endsWith("/rpc/bind_adapty_profile")) return Response.json(true);
      if (url.endsWith("/rpc/sync_adapty_entitlement")) {
        const body = JSON.parse(String(init?.body));
        return Response.json({
          duplicate: false,
          entitlement: "premium",
          is_active: body.p_is_active,
          product_id: body.p_product_id,
          starts_at: body.p_starts_at,
          expires_at: body.p_expires_at,
          will_renew: body.p_will_renew,
          environment: body.p_environment,
          synced_at: body.p_observed_at,
        });
      }
      return Response.json({ error: "unexpected request" }, { status: 500 });
    },
    true,
    new Set([userId]),
  );
  return { client, calls };
}

Deno.test("Adapty secrets compare in constant-time and reject unequal values", () => {
  if (!constantTimeEqual("a-long-webhook-secret", "a-long-webhook-secret")) {
    throw new Error("equal secrets did not match");
  }
  if (constantTimeEqual("a-long-webhook-secret", "a-long-webhook-secreU")) {
    throw new Error("different secrets matched");
  }
  if (constantTimeEqual("short", "shorter")) {
    throw new Error("different lengths matched");
  }
});

Deno.test("premium requires an allowlisted product and matching store environment", () => {
  const active = deriveEntitlement(profile(), "Production", observedAt);
  if (!active.is_active || active.product_id !== monthly) {
    throw new Error("valid production subscription denied");
  }

  const sandboxOnly = deriveEntitlement(
    profile("Sandbox"),
    "Production",
    observedAt,
  );
  if (sandboxOnly.is_active || sandboxOnly.product_id !== null) {
    throw new Error("sandbox access entered production snapshot");
  }

  const forgedSku = deriveEntitlement(
    profile("Production", "premium.forever"),
    "Production",
    observedAt,
  );
  if (forgedSku.is_active) throw new Error("unlisted product granted access");

  const expired = deriveEntitlement(
    profile("Production", yearly, "2026-10-31T11:59:59Z"),
    "Production",
    observedAt,
  );
  if (expired.is_active) {
    throw new Error("expired subscription remained active");
  }

  const cancelledButPaid = profile();
  (cancelledButPaid.access_levels[0] as Record<string, unknown>)
    .renewal_cancelled_at = "2026-10-15T12:00:00Z";
  const untilExpiry = deriveEntitlement(
    cancelledButPaid,
    "Production",
    observedAt,
  );
  if (!untilExpiry.is_active || untilExpiry.will_renew !== false) {
    throw new Error("cancellation revoked paid-through access");
  }
});

Deno.test("billing sync derives the UUID from Auth, binds REST profile, and rejects client identity", async () => {
  const { client, calls } = backend();
  const handler = billingSyncHandler(client, () => observedAt);
  const forged = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: {
        Authorization: "Bearer user-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ user_id: otherUserId }),
    }),
  );
  if (forged.status !== 400 || calls.length !== 0) {
    throw new Error("client-supplied account ID accepted");
  }

  const synced = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "Bearer user-token" },
    }),
  );
  const result = await synced.json();
  if (
    synced.status !== 200 || result.is_active !== true ||
    result.environment !== "Sandbox" || result.purchase_allowed !== true ||
    result.purchase_environment !== "Sandbox" ||
    result.product_id !== monthly ||
    result.starts_at !== "2026-10-01T12:00:00.000Z"
  ) {
    throw new Error(
      `verified billing response has the wrong contract: ${
        JSON.stringify(result)
      }`,
    );
  }
  const bindCall = calls.find((url) =>
    url.endsWith("/rpc/bind_adapty_profile")
  );
  if (!bindCall || !calls.some((url) => url.includes("api.adapty.io"))) {
    throw new Error("server did not bind the verified Adapty profile");
  }
});

Deno.test("billing sync denies arbitrary customer identity and does not expose the entitlement", async () => {
  const { client, calls } = backend({
    profileValue: { ...profile(), customer_user_id: otherUserId },
  });
  const response = await billingSyncHandler(client)(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "Bearer user-token" },
    }),
  );
  if (
    response.status !== 403 ||
    calls.some((url) => url.endsWith("/rpc/sync_adapty_entitlement"))
  ) {
    throw new Error("mismatched Adapty profile granted access");
  }
});

Deno.test("webhook requires secret, environment, allowlisted schema, and verified profile binding", async () => {
  const { client, calls } = backend({ bindingUserId: userId });
  const handler = webhookHandler(
    client,
    "a-webhook-secret-long-enough-for-tests",
    "Production",
  );
  const body = {
    profile_id: profileId,
    customer_user_id: userId,
    event_type: "subscription_refunded",
    event_datetime: "2026-10-30T11:00:00Z",
    event_properties: {
      environment: "Production",
      profile_event_id: "42345678-1234-4234-8234-123456789abc",
    },
  };
  const badSecret = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "wrong" },
      body: JSON.stringify(body),
    }),
  );
  if (badSecret.status !== 401 || calls.length !== 0) {
    throw new Error("invalid webhook secret accepted");
  }

  const wrongEnvironment = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "a-webhook-secret-long-enough-for-tests" },
      body: JSON.stringify({
        ...body,
        event_properties: { ...body.event_properties, environment: "Sandbox" },
      }),
    }),
  );
  if (wrongEnvironment.status !== 400 || calls.length !== 0) {
    throw new Error("cross-environment event accepted");
  }

  const forgedUser = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "a-webhook-secret-long-enough-for-tests" },
      body: JSON.stringify({ ...body, customer_user_id: otherUserId }),
    }),
  );
  if (
    forgedUser.status !== 403 ||
    calls.includes(
      "https://supabase.example.test/rest/v1/rpc/sync_adapty_entitlement",
    )
  ) {
    throw new Error("webhook identity mismatch was accepted");
  }

  const accepted = await handler(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "a-webhook-secret-long-enough-for-tests" },
      body: JSON.stringify(body),
    }),
  );
  if (
    accepted.status !== 200 ||
    !calls.includes(
      "https://supabase.example.test/rest/v1/rpc/sync_adapty_entitlement",
    )
  ) {
    throw new Error("valid webhook did not reconcile the verified profile");
  }
});

Deno.test("webhook verification request is accepted only with the shared secret", async () => {
  const { client, calls } = backend();
  const response = await webhookHandler(
    client,
    "a-webhook-secret-long-enough-for-tests",
    "Production",
  )(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "a-webhook-secret-long-enough-for-tests" },
      body: "{}",
    }),
  );
  if (response.status !== 200 || calls.length !== 0) {
    throw new Error("verification request performed a billing write");
  }
});
