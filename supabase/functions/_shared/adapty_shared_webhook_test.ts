import {
  AdaptyBillingBackend,
  deriveEntitlement,
  webhookHandler,
} from "./adapty_billing.ts";

const user = "12345678-1234-4234-8234-123456789abc";
const bound = "22345678-1234-4234-8234-123456789abc";
const anonymous = "32345678-1234-4234-8234-123456789abc";
const other = "42345678-1234-4234-8234-123456789abc";
const secret = "shared-profile-webhook-secret-for-testing";

function fixture(options: {
  wrongCustomer?: boolean;
  wrongServerProfile?: boolean;
  active?: boolean;
  noShares?: boolean;
  bindingUnavailable?: boolean;
  secondAccount?: boolean;
} = {}) {
  const writes: Record<string, unknown>[] = [];
  const bindingCalls: string[] = [];
  const backend = new AdaptyBillingBackend(
    "https://supabase.example.test",
    "service",
    "adapty",
    async (input, init) => {
      const url = new URL(String(input));
      if (url.pathname.endsWith("adapty_profile_bindings")) {
        bindingCalls.push(String(input));
        if (options.bindingUnavailable) {
          return new Response(null, { status: 503 });
        }
        return Response.json(
          url.searchParams.get("profile_id") === `eq.${bound}`
            ? [{ user_id: user }]
            : options.secondAccount &&
                url.searchParams.get("profile_id") === `eq.${other}`
            ? [{ user_id: other }]
            : [],
        );
      }
      if (url.hostname === "api.adapty.io") {
        const requestedUser = new Headers(init?.headers).get(
          "adapty-customer-user-id",
        );
        if (
          requestedUser !== user &&
          !(options.secondAccount && requestedUser === other)
        ) {
          throw new Error("Must fetch the bound app account from Adapty");
        }
        const product = "com.ardasayar.linglossa.premium.yearly";
        return Response.json({
          data: {
            profile_id: options.wrongServerProfile || requestedUser === other
              ? other
              : bound,
            customer_user_id: requestedUser,
            access_levels: options.active === false ? [] : [{
              access_level_id: "premium",
              store_product_id: product,
              store_transaction_id: "tx",
              starts_at: "2026-01-01T00:00:00Z",
              expires_at: "2099-01-01T00:00:00Z",
              renewal_cancelled_at: null,
            }],
            subscriptions: [{
              store_product_id: product,
              store_transaction_id: "tx",
              environment: "Sandbox",
              will_renew: true,
            }],
          },
        });
      }
      if (url.pathname.endsWith("/rpc/sync_adapty_entitlement")) {
        const body = JSON.parse(String(init?.body));
        writes.push(body);
        return Response.json({ duplicate: writes.length > 1 });
      }
      throw new Error(`Unexpected call ${url.pathname}`);
    },
  );
  const event = {
    event_type: "access_level_updated",
    profile_id: anonymous,
    customer_user_id: null,
    event_datetime: "2026-10-31T09:33:41Z",
    event_properties: {
      environment: "Sandbox",
      is_active: true,
      profile_event_id: "52345678-1234-4234-8234-123456789abc",
    },
    profiles_sharing_access_level: options.noShares ? [] : [
      {
        profile_id: bound,
        customer_user_id: options.wrongCustomer ? other : user,
      },
      // Other unbound anonymous profiles must not acquire an app binding.
      {
        profile_id: other,
        customer_user_id: options.secondAccount ? other : null,
      },
    ],
  };
  const handler = webhookHandler(backend, secret, "Sandbox");
  const send = (body: unknown = event, auth = secret) =>
    handler(
      new Request(
        "https://edge.test",
        {
          method: "POST",
          headers: { Authorization: auth },
          body: JSON.stringify(body),
        },
      ),
    );
  return { writes, bindingCalls, event, send };
}

Deno.test("anonymous inherited event refreshes only a bound, server-verified account", async () => {
  const f = fixture();
  const first = await f.send();
  if (first.status !== 200 || f.writes.length !== 1) {
    throw new Error(
      `Expected reconciliation, got ${first.status}: ${await first.text()}`,
    );
  }
  const saved = f.writes[0];
  if (
    saved.p_profile_id !== bound || saved.p_user_id !== user ||
    saved.p_is_active !== true
  ) {
    throw new Error("Wrong profile or access state reconciled");
  }
  if (saved.p_event_id === f.event.event_properties.profile_event_id) {
    throw new Error(
      "Shared-target event must not collide with the original event",
    );
  }
  const second = await f.send();
  const body = await second.json();
  if (
    second.status !== 200 || body.duplicate !== true ||
    f.writes[1].p_event_id !== saved.p_event_id
  ) {
    throw new Error("Shared-event retry must use the same idempotency key");
  }
});

Deno.test("shared payload cannot grant access absent from the Adapty server", async () => {
  const f = fixture({ active: false });
  const response = await f.send();
  if (response.status !== 200 || f.writes[0]?.p_is_active !== false) {
    throw new Error(
      "Access was derived from webhook payload instead of server profile",
    );
  }
});

Deno.test("shared customer must match its existing binding", async () => {
  const f = fixture({ wrongCustomer: true });
  if ((await f.send()).status !== 403 || f.writes.length !== 0) {
    throw new Error("Mismatched shared customer accepted");
  }
});

Deno.test("shared target must still match the Adapty server profile", async () => {
  const f = fixture({ wrongServerProfile: true });
  if ((await f.send()).status !== 403 || f.writes.length !== 0) {
    throw new Error("Unverified shared target accepted");
  }
});

Deno.test("unbound anonymous event without known shared accounts remains retryable", async () => {
  const f = fixture({ noShares: true });
  if ((await f.send()).status !== 503 || f.writes.length !== 0) {
    throw new Error("Unknown event must not be acknowledged as reconciled");
  }
});

Deno.test("binding outage must not be treated as an unbound shared profile", async () => {
  const f = fixture({ bindingUnavailable: true });
  if (
    (await f.send()).status !== 503 || f.bindingCalls.length !== 1 ||
    f.writes.length
  ) {
    throw new Error("Binding outage should remain retryable without fallback");
  }
});

Deno.test("shared fallback retains webhook authentication and environment isolation", async () => {
  const f = fixture();
  if (
    (await f.send(f.event, "wrong")).status !== 401 || f.bindingCalls.length
  ) {
    throw new Error("Unauthenticated shared event reached bindings");
  }
  if (
    (await f.send({
        ...f.event,
        event_properties: {
          ...f.event.event_properties,
          environment: "Production",
        },
      })).status !== 400 || f.bindingCalls.length
  ) {
    throw new Error("Cross-environment shared event reached bindings");
  }
});

Deno.test("several bound shared accounts reconcile with distinct stable event keys", async () => {
  const f = fixture({ secondAccount: true });
  if ((await f.send()).status !== 200 || f.writes.length !== 2) {
    throw new Error("Both known shared accounts must refresh");
  }
  const [first, second] = f.writes;
  if (
    first.p_profile_id !== bound || second.p_profile_id !== other ||
    first.p_user_id !== user || second.p_user_id !== other ||
    first.p_event_id === second.p_event_id
  ) {
    throw new Error("Shared accounts were conflated or reused one event key");
  }
  if (
    (await f.send()).status !== 200 ||
    f.writes[2].p_event_id !== first.p_event_id ||
    f.writes[3].p_event_id !== second.p_event_id
  ) {
    throw new Error("Retry must retain each target's idempotency key");
  }
});

Deno.test("early renewal uses original purchase start while explicit future starts remain locked", () => {
  const product = "com.ardasayar.linglossa.premium.yearly";
  const original = "2026-10-31T09:16:03Z";
  const renewal = "2026-10-31T10:16:03Z";
  const expires = "2026-10-31T11:16:03Z";
  const now = new Date("2026-10-31T10:15:20Z");
  const access = {
    access_level_id: "premium",
    store_product_id: product,
    store_transaction_id: "tx-renewed",
    starts_at: null,
    originally_purchased_at: original,
    purchased_at: renewal,
    expires_at: expires,
  };
  const subscription = {
    store_product_id: product,
    store_transaction_id: "tx-renewed",
    originally_purchased_at: original,
    purchased_at: renewal,
    environment: "Sandbox",
  };
  const profile = { access_levels: [access], subscriptions: [subscription] };
  const active = deriveEntitlement(profile, "Sandbox", now);
  if (
    !active.is_active || active.starts_at !== new Date(original).toISOString()
  ) {
    throw new Error(
      "Early renewal temporarily revoked an already active subscription",
    );
  }
  const future = deriveEntitlement(
    {
      ...profile,
      access_levels: [
        { ...access, starts_at: renewal },
      ],
    },
    "Sandbox",
    now,
  );
  if (future.is_active) {
    throw new Error("An explicit future start must not grant early access");
  }
  const expired = deriveEntitlement(profile, "Sandbox", new Date(expires));
  if (expired.is_active) {
    throw new Error("Original purchase date must not extend expired access");
  }
  const otherEnvironment = deriveEntitlement(profile, "Production", now);
  if (otherEnvironment.is_active) {
    throw new Error("Original purchase date bypassed environment check");
  }
});

Deno.test("identified but unbound event cannot redirect through a shared account", async () => {
  const f = fixture();
  if (
    (await f.send({ ...f.event, customer_user_id: user })).status !== 503 ||
    f.writes.length !== 0 || f.bindingCalls.length !== 1
  ) {
    throw new Error(
      "Identified events must retain their direct binding requirement",
    );
  }
});
