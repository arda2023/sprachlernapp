import {
  type AccountDeletionBackend,
  accountDeletionHandler,
  type AuthenticatedAccount,
  SupabaseAccountDeletionBackend,
} from "./account_deletion.ts";

const id = "12345678-1234-4234-8234-123456789abc";

class FakeBackend implements AccountDeletionBackend {
  constructor(
    public user: AuthenticatedAccount = {
      id,
      sessionId: "42345678-1234-4234-8234-123456789abc",
      anonymous: false,
      recentAuthAt: Math.floor(Date.now() / 1000),
      appleIdentity: false,
    },
    public publisher = false,
    public profile: string | null = null,
  ) {}
  calls: string[] = [];

  authenticate(token: string): Promise<AuthenticatedAccount> {
    this.calls.push("authenticate");
    if (token !== "test-access-token-123456789") throw new Error("bad token");
    return Promise.resolve(this.user);
  }
  isPublisher(userId: string): Promise<boolean> {
    this.calls.push(`publisher:${userId}`);
    return Promise.resolve(this.publisher);
  }
  adaptyProfile(userId: string): Promise<string | null> {
    this.calls.push(`profile:${userId}`);
    return Promise.resolve(this.profile);
  }
  deleteAdaptyProfile(profileId: string): Promise<void> {
    this.calls.push(`delete-profile:${profileId}`);
    return Promise.resolve();
  }
  deleteAuthUser(userId: string): Promise<void> {
    this.calls.push(`delete-user:${userId}`);
    return Promise.resolve();
  }
}

function request(confirmation = "DELETE"): Request {
  return new Request("https://example.test/functions/v1/delete-account", {
    method: "POST",
    headers: { authorization: "Bearer test-access-token-123456789" },
    body: JSON.stringify({ confirmation }),
  });
}

Deno.test("deletion requires typed confirmation before looking up the user", async () => {
  const backend = new FakeBackend();
  const response = await accountDeletionHandler(backend)(
    request("DELETE PLEASE"),
  );
  if (response.status !== 422 || backend.calls.length !== 0) {
    throw new Error("unconfirmed deletion reached account backend");
  }
});

Deno.test("recent authenticated account deletes Adapty profile and then account", async () => {
  const backend = new FakeBackend(
    undefined,
    false,
    "32345678-1234-4234-8234-123456789abc",
  );
  backend.user = { ...backend.user, appleIdentity: true };
  const response = await accountDeletionHandler(backend)(request());
  const body = await response.json();
  if (
    response.status !== 200 || body.deleted !== true ||
    body.apple_manual_revocation_required !== true
  ) {
    throw new Error(
      `account deletion response ${response.status}: ${JSON.stringify(body)}`,
    );
  }
  const finalCalls = backend.calls.slice(-3);
  if (
    finalCalls.join(",") !==
      `profile:${id},delete-profile:32345678-1234-4234-8234-123456789abc,delete-user:${id}`
  ) {
    throw new Error(`unexpected cleanup order: ${finalCalls.join(",")}`);
  }
});

Deno.test("stale authentication and anonymous sessions cannot delete accounts", async () => {
  for (
    const user of [
      {
        id,
        sessionId: "42345678-1234-4234-8234-123456789abc",
        anonymous: false,
        recentAuthAt: Math.floor(Date.now() / 1000) - 600,
        appleIdentity: false,
      },
      {
        id,
        sessionId: "42345678-1234-4234-8234-123456789abc",
        anonymous: true,
        recentAuthAt: Math.floor(Date.now() / 1000),
        appleIdentity: false,
      },
    ]
  ) {
    const backend = new FakeBackend(user);
    const response = await accountDeletionHandler(backend)(request());
    if (response.status !== 401 && response.status !== 403) {
      throw new Error(`ineligible account received HTTP ${response.status}`);
    }
    if (backend.calls.some((call) => call.startsWith("delete-"))) {
      throw new Error("ineligible account reached destructive cleanup");
    }
  }
});

Deno.test("publisher accounts retain publishing access and immutable history", async () => {
  const backend = new FakeBackend(
    undefined,
    true,
    "32345678-1234-4234-8234-123456789abc",
  );
  const response = await accountDeletionHandler(backend)(request());
  const body = await response.json();
  if (
    response.status !== 403 ||
    body.error !== "PUBLISHER_ACCOUNT_REQUIRES_TRANSFER"
  ) {
    throw new Error(
      `publisher response ${response.status}: ${JSON.stringify(body)}`,
    );
  }
  if (backend.calls.some((call) => call.startsWith("delete-"))) {
    throw new Error("publisher account reached destructive cleanup");
  }
});

Deno.test("Supabase verifies the user and reads signed session and AMR claims", async () => {
  const sessionId = "42345678-1234-4234-8234-123456789abc";
  const payload = btoa(JSON.stringify({
    sub: id,
    session_id: sessionId,
    is_anonymous: false,
    amr: [{ method: "otp", timestamp: Math.floor(Date.now() / 1000) }],
  }))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const token = `header.${payload}.signature`;
  const backend = new SupabaseAccountDeletionBackend(
    "https://project.supabase.co",
    "service-secret-used-only-server-side",
    "",
    (input, init) => {
      const url = String(input);
      const headers = new Headers(init?.headers);
      if (url.endsWith("/auth/v1/user")) {
        if (headers.get("Authorization") !== `Bearer ${token}`) {
          throw new Error("caller token was not used for user validation");
        }
        return Promise.resolve(Response.json({
          id,
          is_anonymous: false,
          app_metadata: { providers: ["apple"] },
          identities: [{
            provider: "apple",
            identity_data: { sub: "apple-subject" },
          }],
        }));
      }
      throw new Error("unexpected request during account verification");
    },
  );
  const user = await backend.authenticate(token, new AbortController().signal);
  if (
    user.id !== id || user.sessionId !== sessionId ||
    user.recentAuthAt === null || !user.appleIdentity
  ) {
    throw new Error(
      "verified identity/session claims were not resolved correctly",
    );
  }
});

Deno.test("stale JWT rejected by Supabase get-user adapter fails closed", async () => {
  const backend = new SupabaseAccountDeletionBackend(
    "https://project.supabase.co",
    "service-secret-used-only-server-side",
    "",
    (input, init) => {
      if (!String(input).endsWith("/auth/v1/user")) {
        throw new Error("stale JWT reached a destructive endpoint");
      }
      const headers = new Headers(init?.headers);
      if (headers.get("Authorization") !== "Bearer stale-user-jwt") {
        throw new Error("caller JWT was not verified by get-user");
      }
      return Promise.resolve(Response.json({ message: "invalid JWT" }, {
        status: 401,
      }));
    },
  );
  try {
    await backend.authenticate("stale-user-jwt", new AbortController().signal);
    throw new Error("stale JWT was accepted");
  } catch (error) {
    if (!(error instanceof Error) || error.message !== "AUTH_REQUIRED") {
      throw error;
    }
  }
});


Deno.test('an endless deletion request body is cancelled by the endpoint deadline', async () => {
  const backend = new FakeBackend();
  let cancelled = false;
  const body = new ReadableStream<Uint8Array>({ cancel() { cancelled = true; } });
  const response = await accountDeletionHandler(backend, Date.now, 20)(
    new Request('https://example.test/delete-account', {
      method: 'POST', headers: { Authorization: 'Bearer test-access-token-123456789' },
      body, duplex: 'half',
    } as RequestInit),
  );
  if (response.status !== 504 || !cancelled || backend.calls.length !== 0) {
    throw Error('Slow request body bypassed deadline');
  }
});
Deno.test('oversized deletion input is stopped before authentication', async () => {
  const backend = new FakeBackend();
  const response = await accountDeletionHandler(backend)(new Request('https://example.test', {
    method: 'POST', headers: { Authorization: 'Bearer test-access-token-123456789' },
    body: JSON.stringify({ confirmation: 'x'.repeat(2000) }),
  }));
  if (response.status !== 413 || backend.calls.length !== 0) throw Error('Body limit missing');
});
