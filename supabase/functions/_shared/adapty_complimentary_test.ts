import {
  AdaptyBillingBackend,
  billingSyncHandler,
  deriveEntitlement,
  webhookHandler,
} from "./adapty_billing.ts";

const userId = "12345678-1234-4234-8234-123456789abc";
const profileId = "32345678-1234-4234-8234-123456789abc";
const product = "com.ardasayar.linglossa.premium.complimentary";
const observedAt = new Date("2026-11-01T12:00:00Z");

function manualProfile(overrides: Record<string, unknown> = {}) {
  return {
    profile_id: profileId,
    customer_user_id: userId,
    access_levels: [{
      access_level_id: "premium",
      store: "adapty",
      store_product_id: "adapty_server_side_product",
      store_transaction_id: "42345678-1234-4234-8234-123456789abc",
      starts_at: "2026-11-01T11:59:00Z",
      purchased_at: "2026-11-01T11:59:00Z",
      expires_at: "2026-12-01T11:59:00Z",
      renewal_cancelled_at: "2026-11-01T11:59:00Z",
      ...overrides,
    }],
    subscriptions: [],
    non_subscriptions: [],
  };
}

Deno.test("a finite server manual grant activates Production Premium without a subscription", () => {
  const grant = deriveEntitlement(manualProfile(), "Production", observedAt);
  if (
    !grant.is_active || grant.product_id !== product ||
    grant.will_renew !== false || grant.environment !== "Production" ||
    grant.starts_at !== "2026-11-01T11:59:00.000Z" ||
    grant.expires_at !== "2026-12-01T11:59:00.000Z"
  ) throw new Error("the verified manual grant lost its non-renewing contract");

  const immediate = deriveEntitlement(
    manualProfile({ starts_at: null, renewal_cancelled_at: null }),
    "Production",
    observedAt,
  );
  if (!immediate.is_active || immediate.will_renew !== false) {
    throw new Error("an immediate grant must use its purchase date and never renew");
  }
});

Deno.test("manual grants require exact provider markers and cannot enter Sandbox", () => {
  for (const fields of [
    { store: "play_store" },
    { store: null },
    { store_product_id: "another_manual_product" },
    { store_product_id: product },
    { access_level_id: "another_access_level" },
  ]) {
    const grant = deriveEntitlement(manualProfile(fields), "Production", observedAt);
    if (grant.is_active || grant.product_id !== null) {
      throw new Error(`unrecognized manual grant accepted: ${JSON.stringify(fields)}`);
    }
  }
  const sandbox = deriveEntitlement(manualProfile(), "Sandbox", observedAt);
  if (sandbox.is_active || sandbox.product_id !== null) {
    throw new Error("a manual grant was classified as a sandbox purchase");
  }
});

Deno.test("future, expired, malformed and unbounded manual grants fail closed", () => {
  for (const fields of [
    { starts_at: "2026-11-02T12:00:00Z" },
    { expires_at: observedAt.toISOString() },
    { expires_at: "2026-10-31T12:00:00Z" },
    { expires_at: null },
    { expires_at: "invalid" },
    { starts_at: "invalid" },
    { starts_at: null, purchased_at: null },
  ]) {
    const grant = deriveEntitlement(manualProfile(fields), "Production", observedAt);
    if (grant.is_active) throw new Error(`invalid grant activated: ${JSON.stringify(fields)}`);
  }
});

function serverFixture() {
  const writes: Record<string, unknown>[] = [];
  let profileReads = 0;
  const client = new AdaptyBillingBackend(
    "https://supabase.example.test",
    "fixture-service-key",
    "fixture-adapty-key",
    async (input, init) => {
      const url = String(input);
      if (url.endsWith("/auth/v1/user")) {
        return Response.json({
          id: userId,
          is_anonymous: false,
          email_confirmed_at: "2026-10-01T12:00:00Z",
        });
      }
      if (url.includes("api.adapty.io")) {
        profileReads++;
        const headers = new Headers(init?.headers);
        if (
          headers.get("Authorization") !== "Api-Key fixture-adapty-key" ||
          headers.get("adapty-customer-user-id") !== userId
        ) throw new Error("manual grant profile was not fetched by the server");
        const now = Date.now();
        return Response.json({
          data: manualProfile({
            starts_at: new Date(now - 60_000).toISOString(),
            expires_at: new Date(now + 30 * 86_400_000).toISOString(),
          }),
        });
      }
      if (url.endsWith("/rpc/bind_adapty_profile")) return Response.json(true);
      if (url.includes("/adapty_profile_bindings?")) {
        return Response.json([{ user_id: userId }]);
      }
      if (url.endsWith("/rpc/sync_adapty_entitlement")) {
        const body = JSON.parse(String(init?.body));
        writes.push(body);
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
      throw new Error(`unexpected request: ${url}`);
    },
  );
  return { client, writes, profileReads: () => profileReads };
}

Deno.test("authenticated billing reconciliation returns the server-verified complimentary snapshot", async () => {
  const fixture = serverFixture();
  const response = await billingSyncHandler(fixture.client)(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: "Bearer fixture-user-token" },
    }),
  );
  const result = await response.json();
  if (
    response.status !== 200 || !result.is_active ||
    result.product_id !== product || result.will_renew !== false ||
    result.environment !== "Production" || fixture.profileReads() !== 1 ||
    fixture.writes.length !== 1 || fixture.writes[0].p_user_id !== userId
  ) throw new Error("complimentary entitlement did not cross the server contract");
});

Deno.test("manual access webhooks re-fetch the bound profile instead of trusting event access flags", async () => {
  const fixture = serverFixture();
  const secret = "fixture-webhook-secret-at-least-32-characters";
  const response = await webhookHandler(fixture.client, secret, "Production")(
    new Request("https://edge.test", {
      method: "POST",
      headers: { Authorization: secret },
      body: JSON.stringify({
        profile_id: profileId,
        customer_user_id: userId,
        event_type: "access_level_updated",
        access_levels: [],
        event_properties: {
          environment: "Production",
          profile_event_id: "52345678-1234-4234-8234-123456789abc",
        },
      }),
    }),
  );
  if (
    response.status !== 200 || fixture.profileReads() !== 1 ||
    fixture.writes.length !== 1 ||
    fixture.writes[0].p_product_id !== product ||
    fixture.writes[0].p_is_active !== true ||
    fixture.writes[0].p_will_renew !== false
  ) throw new Error("manual access webhook did not verify the grant with Adapty");
});
