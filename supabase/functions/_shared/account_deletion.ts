type Json = Record<string, unknown>;

export class AccountDeletionError extends Error {
  constructor(public code: string, public status: number) {
    super(code);
  }
}

export interface AuthenticatedAccount {
  id: string;
  sessionId: string;
  anonymous: boolean;
  recentAuthAt: number | null;
  appleIdentity: boolean;
}

export interface AccountDeletionBackend {
  authenticate(
    token: string,
    signal: AbortSignal,
  ): Promise<AuthenticatedAccount>;
  isPublisher(userId: string, signal: AbortSignal): Promise<boolean>;
  adaptyProfile(userId: string, signal: AbortSignal): Promise<string | null>;
  deleteAdaptyProfile(profileId: string, signal: AbortSignal): Promise<void>;
  deleteAuthUser(userId: string, signal: AbortSignal): Promise<void>;
}

function requireValue(
  condition: unknown,
  code: string,
  status: number,
): asserts condition {
  if (!condition) throw new AccountDeletionError(code, status);
}

async function readJson(request: Request, maxBytes = 1024): Promise<Json> {
  const reader = request.body?.getReader();
  requireValue(reader, "JSON_INVALID", 422);
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      requireValue(length <= maxBytes, "BODY_LIMIT", 413);
      chunks.push(value);
    }
  } finally {
    void reader.cancel().catch(() => {});
    reader.releaseLock();
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  try {
    const result = JSON.parse(
      new TextDecoder("utf-8", { fatal: true }).decode(bytes),
    );
    requireValue(
      result && typeof result === "object" && !Array.isArray(result),
      "JSON_INVALID",
      422,
    );
    return result as Json;
  } catch (error) {
    if (error instanceof AccountDeletionError) throw error;
    throw new AccountDeletionError("JSON_INVALID", 422);
  }
}

export function accountDeletionHandler(
  backend: AccountDeletionBackend,
  now: () => number = Date.now,
  timeoutMs = 20000,
): (request: Request) => Promise<Response> {
  return async (request: Request) => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      requireValue(request.method === "POST", "METHOD_NOT_ALLOWED", 405);
      const authorization = request.headers.get("authorization") ?? "";
      const match = /^Bearer ([A-Za-z0-9._~-]{20,8192})$/.exec(authorization);
      requireValue(match, "AUTH_REQUIRED", 401);
      const input = await readJson(request);
      requireValue(Object.keys(input).length === 1, "INPUT_INVALID", 422);
      requireValue(
        input.confirmation === "DELETE",
        "CONFIRMATION_REQUIRED",
        422,
      );

      const user = await backend.authenticate(match[1], controller.signal);
      requireValue(!user.anonymous, "AUTH_REQUIRED", 401);
      requireValue(
        user.recentAuthAt !== null &&
          user.recentAuthAt <= now() / 1000 + 60 &&
          now() / 1000 - user.recentAuthAt <= 300,
        "RECENT_AUTH_REQUIRED",
        403,
      );
      requireValue(
        !(await backend.isPublisher(user.id, controller.signal)),
        "PUBLISHER_ACCOUNT_REQUIRES_TRANSFER",
        403,
      );

      const adaptyProfileId = await backend.adaptyProfile(
        user.id,
        controller.signal,
      );
      if (adaptyProfileId) {
        await backend.deleteAdaptyProfile(adaptyProfileId, controller.signal);
      }
      await backend.deleteAuthUser(user.id, controller.signal);

      return Response.json({
        deleted: true,
        apple_manual_revocation_required: user.appleIdentity,
      }, { headers: { "Cache-Control": "no-store" } });
    } catch (error) {
      const known = error instanceof AccountDeletionError
        ? error
        : new AccountDeletionError(
          controller.signal.aborted ? "REQUEST_TIMEOUT" : "DELETION_FAILED",
          controller.signal.aborted ? 504 : 503,
        );
      return Response.json({ error: known.code }, {
        status: known.status,
        headers: { "Cache-Control": "no-store" },
      });
    } finally {
      clearTimeout(timer);
    }
  };
}

async function boundedJson(
  response: Response,
  maxBytes = 32768,
): Promise<Json> {
  const bytes = new Uint8Array(await response.arrayBuffer());
  requireValue(bytes.length <= maxBytes, "BACKEND_UNAVAILABLE", 503);
  try {
    const value = JSON.parse(
      new TextDecoder("utf-8", { fatal: true }).decode(bytes),
    );
    requireValue(
      value && typeof value === "object" && !Array.isArray(value),
      "BACKEND_UNAVAILABLE",
      503,
    );
    return value as Json;
  } catch (error) {
    if (error instanceof AccountDeletionError) throw error;
    throw new AccountDeletionError("BACKEND_UNAVAILABLE", 503);
  }
}

export class SupabaseAccountDeletionBackend implements AccountDeletionBackend {
  constructor(
    private url: string,
    private serviceKey: string,
    private adaptyApiKey: string,
    private fetcher: typeof fetch = fetch,
  ) {}

  private configured(): URL {
    requireValue(
      this.url.length > 0 && this.serviceKey.length > 0,
      "NOT_CONFIGURED",
      503,
    );
    let url: URL;
    try {
      url = new URL(this.url);
    } catch {
      throw new AccountDeletionError("NOT_CONFIGURED", 503);
    }
    requireValue(
      url.protocol === "https:" ||
        ["localhost", "127.0.0.1", "kong"].includes(url.hostname),
      "NOT_CONFIGURED",
      503,
    );
    return url;
  }

  private async request(
    path: string,
    init: RequestInit = {},
    token = this.serviceKey,
  ): Promise<Response> {
    const url = this.configured();
    const response = await this.fetcher(new URL(path, url).toString(), {
      ...init,
      headers: {
        apikey: this.serviceKey,
        Authorization: `Bearer ${token}`,
        ...(init.body ? { "Content-Type": "application/json" } : {}),
        ...init.headers,
      },
      redirect: "error",
    });
    return response;
  }

  async authenticate(
    token: string,
    signal: AbortSignal,
  ): Promise<AuthenticatedAccount> {
    const response = await this.request("/auth/v1/user", { signal }, token);
    requireValue(response.ok, "AUTH_REQUIRED", 401);
    const user = await boundedJson(response, 32768);
    requireValue(
      typeof user.id === "string" && /^[0-9a-f-]{36}$/i.test(user.id),
      "AUTH_REQUIRED",
      401,
    );
    // /auth/v1/user verifies the JWT signature and subject. Supabase's signed
    // AMR timestamps record authentication time; iat alone is unsuitable
    // because refreshing an old session issues a new token.
    let claims: Json;
    try {
      const parts = token.split(".");
      requireValue(parts.length === 3, "AUTH_REQUIRED", 401);
      const payload = parts[1].replace(/-/g, "+").replace(/_/g, "/");
      claims = JSON.parse(
        atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, "=")),
      );
    } catch (error) {
      if (error instanceof AccountDeletionError) throw error;
      throw new AccountDeletionError("AUTH_REQUIRED", 401);
    }
    requireValue(claims.sub === user.id, "AUTH_REQUIRED", 401);
    requireValue(
      typeof claims.session_id === "string" &&
        /^[0-9a-f-]{36}$/i.test(claims.session_id),
      "AUTH_REQUIRED",
      401,
    );
    requireValue(Array.isArray(claims.amr), "AUTH_REQUIRED", 401);
    const amrTimes = claims.amr.map((entry) =>
      entry && typeof entry === "object" &&
        typeof (entry as Json).method === "string"
        ? Number((entry as Json).timestamp)
        : NaN
    ).filter((timestamp) => Number.isSafeInteger(timestamp) && timestamp > 0);
    const recentAuthAt = amrTimes.length > 0 ? Math.max(...amrTimes) : null;
    const appMetadata =
      user.app_metadata && typeof user.app_metadata === "object"
        ? user.app_metadata as Json
        : {};
    const providers = Array.isArray(appMetadata.providers)
      ? appMetadata.providers
      : [];
    const identities = Array.isArray(user.identities) ? user.identities : [];
    return {
      id: user.id,
      sessionId: claims.session_id,
      anonymous: user.is_anonymous !== false || claims.is_anonymous !== false,
      recentAuthAt,
      appleIdentity: providers.includes("apple") ||
        identities.some((identity) =>
          !!identity && typeof identity === "object" &&
          (identity as Json).provider === "apple"
        ),
    };
  }

  async isPublisher(userId: string, signal: AbortSignal): Promise<boolean> {
    const response = await this.request(
      `/rest/v1/content_publishers?user_id=eq.${
        encodeURIComponent(userId)
      }&select=user_id`,
      {
        signal,
        headers: { "Accept-Profile": "public", "Content-Profile": "public" },
      },
    );
    requireValue(response.ok, "BACKEND_UNAVAILABLE", 503);
    const rows = await response.json();
    requireValue(Array.isArray(rows), "BACKEND_UNAVAILABLE", 503);
    return rows.length > 0;
  }

  async adaptyProfile(
    userId: string,
    signal: AbortSignal,
  ): Promise<string | null> {
    const response = await this.request(
      `/rest/v1/adapty_profile_bindings?user_id=eq.${
        encodeURIComponent(userId)
      }&select=profile_id`,
      {
        signal,
        headers: { "Accept-Profile": "app", "Content-Profile": "app" },
      },
    );
    requireValue(response.ok, "BACKEND_UNAVAILABLE", 503);
    const rows = await response.json();
    requireValue(
      Array.isArray(rows) && rows.length <= 1,
      "BACKEND_UNAVAILABLE",
      503,
    );
    if (rows.length === 0) return null;
    const profileId = rows[0]?.profile_id;
    requireValue(
      typeof profileId === "string" && /^[0-9a-f-]{36}$/i.test(profileId),
      "BACKEND_UNAVAILABLE",
      503,
    );
    return profileId;
  }

  async deleteAdaptyProfile(
    profileId: string,
    signal: AbortSignal,
  ): Promise<void> {
    requireValue(this.adaptyApiKey.length > 0, "NOT_CONFIGURED", 503);
    let response: Response;
    try {
      response = await this.fetcher(
        "https://api.adapty.io/api/v2/server-side-api/profile/",
        {
          method: "DELETE",
          headers: {
            Authorization: `Api-Key ${this.adaptyApiKey}`,
            "adapty-profile-id": profileId,
          },
          signal,
          redirect: "error",
        },
      );
    } catch {
      throw new AccountDeletionError("BILLING_PROFILE_DELETE_FAILED", 503);
    }
    requireValue(
      response.status === 204 || response.status === 404,
      "BILLING_PROFILE_DELETE_FAILED",
      503,
    );
  }

  async deleteAuthUser(userId: string, signal: AbortSignal): Promise<void> {
    const response = await this.request(
      `/auth/v1/admin/users/${encodeURIComponent(userId)}`,
      { method: "DELETE", signal },
    );
    requireValue(response.ok, "BACKEND_UNAVAILABLE", 503);
  }
}
