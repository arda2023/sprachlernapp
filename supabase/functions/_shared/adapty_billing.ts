const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PRODUCTS = new Set([
  "com.ardasayar.linglossa.premium.monthly",
  "com.ardasayar.linglossa.premium.yearly",
]);
const WEBHOOK_EVENTS = new Set([
  "subscription_started",
  "subscription_active",
  "subscription_renewed",
  "subscription_renewal_cancelled",
  "subscription_renewal_reactivated",
  "subscription_expired",
  "subscription_paused",
  "subscription_deferred",
  "trial_started",
  "trial_active",
  "trial_converted",
  "trial_renewal_cancelled",
  "trial_renewal_reactivated",
  "trial_expired",
  "entered_grace_period",
  "billing_issue_detected",
  "subscription_refunded",
  "access_level_updated",
]);
const MAX_BODY = 16 * 1024;

export type BillingEnvironment = "Production" | "Sandbox";
export type EntitlementSnapshot = {
  entitlement: "premium";
  is_active: boolean;
  product_id: string | null;
  starts_at: string | null;
  expires_at: string | null;
  will_renew: boolean | null;
  environment: BillingEnvironment;
  synced_at: string;
};

export class BillingError extends Error {
  constructor(readonly code: string, readonly status: number) {
    super(code);
  }
}

function check(
  condition: unknown,
  code: string,
  status = 503,
): asserts condition {
  if (!condition) throw new BillingError(code, status);
}

function date(value: unknown): number | null {
  if (typeof value !== "string") return null;
  const time = Date.parse(value);
  return Number.isFinite(time) ? time : null;
}

function iso(value: unknown): string | null {
  const time = date(value);
  return time === null ? null : new Date(time).toISOString();
}

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID.test(value);
}

export function constantTimeEqual(left: string, right: string): boolean {
  const a = new TextEncoder().encode(left);
  const b = new TextEncoder().encode(right);
  let difference = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let i = 0; i < length; i++) {
    difference |= (a[i] ?? 0) ^ (b[i] ?? 0);
  }
  return difference === 0;
}

export async function boundedJson(
  body: ReadableStream<Uint8Array> | null,
  maxBytes = MAX_BODY,
): Promise<unknown> {
  const bytes = await boundedBytes(body, maxBytes);
  try {
    return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } catch {
    throw new BillingError("INVALID_BODY", 400);
  }
}

async function boundedBytes(
  body: ReadableStream<Uint8Array> | null,
  maxBytes: number,
): Promise<Uint8Array> {
  check(body, "INVALID_BODY", 400);
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      check(size <= maxBytes, "BODY_TOO_LARGE", 413);
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

export function deriveEntitlement(
  profile: Record<string, unknown>,
  expectedEnvironment: BillingEnvironment,
  observedAt = new Date(),
): Omit<EntitlementSnapshot, "synced_at"> {
  const now = observedAt.getTime();
  const accessLevels = Array.isArray(profile.access_levels)
    ? profile.access_levels as Record<string, unknown>[]
    : [];
  const subscriptions = Array.isArray(profile.subscriptions)
    ? profile.subscriptions as Record<string, unknown>[]
    : [];

  const candidates = accessLevels.flatMap((access) => {
    if (
      access.access_level_id !== "premium" ||
      typeof access.store_product_id !== "string" ||
      !PRODUCTS.has(access.store_product_id)
    ) return [];
    const subscription = subscriptions.find((item) =>
      item.store_transaction_id === access.store_transaction_id &&
      item.store_product_id === access.store_product_id &&
      item.environment === expectedEnvironment
    );
    if (!subscription) return [];

    // A renewal may arrive before its purchased_at timestamp (sandbox does
    // this in practice). Keep the original continuous subscription start;
    // an explicit starts_at still takes precedence for scheduled access.
    const startsAt = iso(access.starts_at) ??
      iso(access.originally_purchased_at) ??
      iso(subscription.originally_purchased_at) ?? iso(access.purchased_at) ??
      iso(subscription.purchased_at);
    const expiresAt = iso(access.expires_at);
    const startTime = date(startsAt);
    const expiryTime = date(expiresAt);
    const active = startTime !== null && expiryTime !== null &&
      startTime <= now && expiryTime > now;
    const renew = typeof access.renewal_cancelled_at === "string" ||
        typeof subscription.renewal_cancelled_at === "string"
      ? false
      : true;
    return [{
      entitlement: "premium" as const,
      is_active: active,
      product_id: access.store_product_id,
      starts_at: startsAt,
      expires_at: expiresAt,
      will_renew: renew,
      environment: expectedEnvironment,
      expiryTime: expiryTime ?? Number.NEGATIVE_INFINITY,
    }];
  });

  candidates.sort((a, b) => b.expiryTime - a.expiryTime);
  const winner = candidates[0];
  if (!winner) {
    return {
      entitlement: "premium",
      is_active: false,
      product_id: null,
      starts_at: null,
      expires_at: null,
      will_renew: null,
      environment: expectedEnvironment,
    };
  }
  const { expiryTime: _expiryTime, ...snapshot } = winner;
  return snapshot;
}

export class AdaptyBillingBackend {
  constructor(
    readonly supabaseUrl: string,
    private readonly serviceKey: string,
    private readonly adaptyApiKey: string,
    private readonly fetcher: typeof fetch = fetch,
    private readonly sandboxEnabled = false,
    private readonly sandboxTesterIds: ReadonlySet<string> = new Set(),
  ) {}

  private async request(
    path: string,
    options: RequestInit = {},
    bearer = this.serviceKey,
  ): Promise<Response> {
    check(
      this.serviceKey.length > 0 && this.supabaseUrl.length > 0,
      "NOT_CONFIGURED",
    );
    const url = new URL(this.supabaseUrl);
    check(
      url.protocol === "https:" ||
        ["localhost", "127.0.0.1", "kong"].includes(url.hostname),
      "NOT_CONFIGURED",
    );
    return await this.fetcher(this.supabaseUrl + path, {
      ...options,
      headers: {
        apikey: this.serviceKey,
        Authorization: `Bearer ${bearer}`,
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(path.startsWith("/rest/v1/")
          ? { "Accept-Profile": "app", "Content-Profile": "app" }
          : {}),
        ...options.headers,
      },
      redirect: "error",
    });
  }

  async authenticate(token: string, signal?: AbortSignal): Promise<string> {
    check(token.length > 0 && token.length < 8192, "AUTH_REQUIRED", 401);
    const response = await this.request("/auth/v1/user", { signal }, token);
    check(response.ok, "AUTH_REQUIRED", 401);
    const user = await boundedJson(response.body, 32 * 1024) as Record<
      string,
      unknown
    >;
    check(
      isUuid(user.id) && user.is_anonymous !== true &&
        (date(user.email_confirmed_at) !== null ||
          date(user.phone_confirmed_at) !== null),
      "AUTH_REQUIRED",
      401,
    );
    return user.id;
  }

  private async rpc(
    name: string,
    body: Record<string, unknown>,
    signal?: AbortSignal,
  ): Promise<unknown> {
    const response = await this.request(`/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal,
    });
    check(response.ok, "BILLING_STORAGE_UNAVAILABLE");
    const value = await boundedJson(response.body);
    check(
      typeof value === "boolean" || value !== null && typeof value === "object",
      "BILLING_STORAGE_UNAVAILABLE",
    );
    return value;
  }

  async bind(
    userId: string,
    profileId: string,
    signal?: AbortSignal,
  ): Promise<void> {
    const bound = await this.rpc("bind_adapty_profile", {
      p_user_id: userId,
      p_profile_id: profileId,
    }, signal);
    check(bound === true, "BILLING_IDENTITY_CONFLICT", 409);
  }

  async profile(
    userId: string,
    signal?: AbortSignal,
  ): Promise<Record<string, unknown>> {
    check(this.adaptyApiKey.length > 0, "NOT_CONFIGURED");
    const started = new Date();
    const response = await this.fetcher(
      "https://api.adapty.io/api/v2/server-side-api/profile/",
      {
        method: "GET",
        headers: {
          Authorization: `Api-Key ${this.adaptyApiKey}`,
          "adapty-customer-user-id": userId,
        },
        signal,
        redirect: "error",
      },
    );
    check(response.ok, "ADAPTY_PROFILE_UNAVAILABLE", 503);
    const envelope = await boundedJson(response.body, 256 * 1024) as Record<
      string,
      unknown
    >;
    const profile = envelope.data as Record<string, unknown> | undefined;
    check(
      profile && typeof profile.customer_user_id === "string" &&
        profile.customer_user_id.toLowerCase() === userId.toLowerCase(),
      "ADAPTY_IDENTITY_MISMATCH",
      403,
    );
    check(isUuid(profile.profile_id), "ADAPTY_PROFILE_INVALID");
    return {
      ...profile,
      _profileId: profile.profile_id,
      _observedAt: started.toISOString(),
    };
  }

  async syncUser(
    userId: string,
    signal?: AbortSignal,
  ): Promise<EntitlementSnapshot> {
    const profile = await this.profile(userId, signal);
    const profileId = profile._profileId as string;
    const bound = await this.rpc("bind_adapty_profile", {
      p_user_id: userId,
      p_profile_id: profileId,
    }, signal);
    check(bound === true, "BILLING_IDENTITY_CONFLICT", 409);
    const observedAt = profile._observedAt as string;
    const environment: BillingEnvironment = this.sandboxEnabled &&
        this.sandboxTesterIds.has(userId.toLowerCase())
      ? "Sandbox"
      : "Production";
    const values = deriveEntitlement(
      profile,
      environment,
      new Date(observedAt),
    );
    const saved = await this.rpc("sync_adapty_entitlement", {
      p_user_id: userId,
      p_profile_id: profileId,
      p_environment: environment,
      p_product_id: values.product_id,
      p_is_active: values.is_active,
      p_starts_at: values.starts_at,
      p_expires_at: values.expires_at,
      p_will_renew: values.will_renew,
      p_observed_at: observedAt,
    }, signal);
    check(
      saved !== null && typeof saved === "object",
      "BILLING_STORAGE_UNAVAILABLE",
    );
    return snapshot(saved as Record<string, unknown>);
  }

  async binding(profileId: string, signal?: AbortSignal): Promise<string> {
    check(isUuid(profileId), "INVALID_EVENT", 400);
    const response = await this.request(
      `/rest/v1/adapty_profile_bindings?profile_id=eq.${profileId}&select=user_id`,
      { signal },
    );
    check(response.ok, "BILLING_STORAGE_UNAVAILABLE");
    const rows = await boundedJson(response.body) as Record<string, unknown>[];
    check(
      Array.isArray(rows) && rows.length === 1 && isUuid(rows[0].user_id),
      "PROFILE_NOT_BOUND",
      503,
    );
    return rows[0].user_id as string;
  }

  async reconcileWebhook(
    userId: string,
    profileId: string,
    environment: BillingEnvironment,
    eventId: string,
    eventType: string,
    eventDatetime: string | null,
    signal?: AbortSignal,
  ): Promise<Record<string, unknown>> {
    const profile = await this.profile(userId, signal);
    check(profile._profileId === profileId, "ADAPTY_IDENTITY_MISMATCH", 403);
    const observedAt = profile._observedAt as string;
    const values = deriveEntitlement(
      profile,
      environment,
      new Date(observedAt),
    );
    const result = await this.rpc("sync_adapty_entitlement", {
      p_user_id: userId,
      p_profile_id: profileId,
      p_environment: environment,
      p_product_id: values.product_id,
      p_is_active: values.is_active,
      p_starts_at: values.starts_at,
      p_expires_at: values.expires_at,
      p_will_renew: values.will_renew,
      p_observed_at: observedAt,
      p_event_id: eventId,
      p_event_type: eventType,
      p_event_datetime: eventDatetime,
    }, signal);
    check(
      result !== null && typeof result === "object",
      "BILLING_STORAGE_UNAVAILABLE",
    );
    return result as Record<string, unknown>;
  }
}

function snapshot(value: Record<string, unknown>): EntitlementSnapshot {
  check(
    value.entitlement === "premium" && typeof value.is_active === "boolean" &&
      (value.environment === "Production" || value.environment === "Sandbox") &&
      typeof value.synced_at === "string",
    "BILLING_STORAGE_UNAVAILABLE",
  );
  check(
    value.product_id === null ||
      typeof value.product_id === "string" && PRODUCTS.has(value.product_id),
    "BILLING_STORAGE_UNAVAILABLE",
  );
  check(
    value.starts_at === null || typeof value.starts_at === "string",
    "BILLING_STORAGE_UNAVAILABLE",
  );
  check(
    value.expires_at === null || typeof value.expires_at === "string",
    "BILLING_STORAGE_UNAVAILABLE",
  );
  check(
    value.will_renew === null || typeof value.will_renew === "boolean",
    "BILLING_STORAGE_UNAVAILABLE",
  );
  return value as unknown as EntitlementSnapshot;
}

async function bodyDigest(raw: Uint8Array): Promise<string> {
  const copy = Uint8Array.from(raw);
  const hash = await crypto.subtle.digest("SHA-256", copy.buffer);
  return [...new Uint8Array(hash)].map((v) => v.toString(16).padStart(2, "0"))
    .join("");
}

export function billingSyncHandler(
  backend: AdaptyBillingBackend,
  now: () => Date = () => new Date(),
) {
  return async (request: Request): Promise<Response> => {
    const headers = {
      "Cache-Control": "no-store",
      "Content-Type": "application/json",
    };
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8500);
    try {
      check(request.method === "POST", "METHOD_NOT_ALLOWED", 405);
      const authorization = request.headers.get("Authorization");
      check(
        typeof authorization === "string" &&
          authorization.startsWith("Bearer ") && authorization.length < 8192,
        "AUTH_REQUIRED",
        401,
      );
      const body = new TextDecoder("utf-8", { fatal: true }).decode(
        request.body
          ? await boundedBytes(request.body, 1024)
          : new Uint8Array(),
      );
      check(
        body.length <= 1024 && (body.trim() === "" || body.trim() === "{}"),
        "INVALID_BODY",
        400,
      );
      const userId = await backend.authenticate(
        authorization.slice(7),
        controller.signal,
      );
      const result = await backend.syncUser(userId, controller.signal);
      return Response.json({
        ...result,
        purchase_allowed: true,
        purchase_environment: result.environment,
        synced_at: result.synced_at || now().toISOString(),
      }, { headers });
    } catch (error) {
      const failure = error instanceof BillingError
        ? error
        : new BillingError("BILLING_UNAVAILABLE", 503);
      return Response.json({ error: failure.code }, {
        status: failure.status,
        headers,
      });
    } finally {
      clearTimeout(timer);
    }
  };
}

export function webhookHandler(
  backend: AdaptyBillingBackend,
  secret: string,
  expectedEnvironment: BillingEnvironment,
) {
  return async (request: Request): Promise<Response> => {
    const headers = {
      "Cache-Control": "no-store",
      "Content-Type": "application/json",
    };
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8500);
    try {
      check(request.method === "POST", "METHOD_NOT_ALLOWED", 405);
      check(secret.length >= 32 && secret.length <= 4096, "NOT_CONFIGURED");
      const providedSecret = request.headers.get("Authorization") ?? "";
      check(
        constantTimeEqual(providedSecret, secret),
        "WEBHOOK_UNAUTHORIZED",
        401,
      );

      const raw = await boundedBytes(request.body, MAX_BODY);
      const event = await boundedJson(
        new Response(Uint8Array.from(raw).buffer).body,
        MAX_BODY,
      ) as Record<string, unknown>;

      // Adapty's dashboard verification request is an authenticated empty object.
      if (Object.keys(event).length === 0) {
        return Response.json({ ok: true }, { headers });
      }
      const properties = event.event_properties as
        | Record<string, unknown>
        | undefined;
      check(
        typeof event.event_type === "string" &&
          WEBHOOK_EVENTS.has(event.event_type),
        "INVALID_EVENT",
        400,
      );
      check(
        properties && properties.environment === expectedEnvironment,
        "WEBHOOK_ENVIRONMENT_MISMATCH",
        400,
      );
      check(isUuid(event.profile_id), "INVALID_EVENT", 400);

      const suppliedUserId = event.customer_user_id;
      const targets = new Map<string, string>();
      try {
        const userId = await backend.binding(
          event.profile_id,
          controller.signal,
        );
        if (suppliedUserId !== null && suppliedUserId !== undefined) {
          check(
            isUuid(suppliedUserId) &&
              suppliedUserId.toLowerCase() === userId.toLowerCase(),
            "WEBHOOK_IDENTITY_MISMATCH",
            403,
          );
        }
        targets.set(event.profile_id, userId);
      } catch (error) {
        // An anonymous inheritor can emit its own access-level event after
        // logout/reinstallation. It has no app binding; only refresh known
        // shared accounts, never bind the anonymous profile from this payload.
        if (
          !(error instanceof BillingError) ||
          error.code !== "PROFILE_NOT_BOUND" ||
          suppliedUserId !== null && suppliedUserId !== undefined
        ) throw error;
        const shared = event.profiles_sharing_access_level;
        check(
          Array.isArray(shared) && shared.length <= 32,
          "PROFILE_NOT_BOUND",
        );
        for (const candidate of shared) {
          check(
            candidate !== null && typeof candidate === "object" &&
              isUuid(candidate.profile_id),
            "INVALID_EVENT",
            400,
          );
          let userId: string;
          try {
            userId = await backend.binding(
              candidate.profile_id,
              controller.signal,
            );
          } catch (bindingError) {
            if (
              bindingError instanceof BillingError &&
              bindingError.code === "PROFILE_NOT_BOUND"
            ) continue;
            throw bindingError;
          }
          check(
            isUuid(candidate.customer_user_id) &&
              candidate.customer_user_id.toLowerCase() === userId.toLowerCase(),
            "WEBHOOK_IDENTITY_MISMATCH",
            403,
          );
          targets.set(candidate.profile_id, userId);
        }
        check(targets.size > 0, "PROFILE_NOT_BOUND");
      }
      const suppliedEventId = properties.profile_event_id;
      const eventId = typeof suppliedEventId === "string" &&
          /^[0-9a-f-]{1,80}$/i.test(suppliedEventId)
        ? suppliedEventId.toLowerCase()
        : await bodyDigest(raw);
      const eventDatetime = typeof event.event_datetime === "string" &&
          date(event.event_datetime) !== null
        ? new Date(event.event_datetime).toISOString()
        : null;
      let duplicate = true;
      for (const [profileId, userId] of targets) {
        // One shared event may refresh several existing accounts. Namespace its
        // idempotency key per target so retries and partial failures stay safe.
        const targetEventId = profileId === event.profile_id
          ? eventId
          : await bodyDigest(
            new TextEncoder().encode(`${eventId}:${profileId}`),
          );
        // This fetches the target from Adapty again and checks its exact profile
        // and customer identity. Access flags in the webhook are never trusted.
        const result = await backend.reconcileWebhook(
          userId,
          profileId,
          expectedEnvironment,
          targetEventId,
          event.event_type,
          eventDatetime,
          controller.signal,
        );
        duplicate = duplicate && result.duplicate === true;
      }
      return Response.json({ ok: true, duplicate }, {
        headers,
      });
    } catch (error) {
      const failure = error instanceof BillingError
        ? error
        : new BillingError("BILLING_UNAVAILABLE", 503);
      return Response.json({ error: failure.code }, {
        status: failure.status,
        headers,
      });
    } finally {
      clearTimeout(timer);
    }
  };
}
