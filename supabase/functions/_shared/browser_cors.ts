/** Browser clients authenticate with bearer tokens, never ambient cookies.
 * CORS permits the deployed web origin without granting access to any account.
 * Authentication, method checks and budgets remain inside the wrapped handler.
 */
const browserCorsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, DELETE, OPTIONS',
  'Access-Control-Expose-Headers': 'retry-after, x-request-id',
  'Access-Control-Max-Age': '600',
};

export function withBrowserCors(
  handler: (request: Request) => Response | Promise<Response>,
): (request: Request) => Promise<Response> {
  return async (request) => {
    // No authentication request, provider request or quota reservation for OPTIONS.
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: browserCorsHeaders });
    }
    let response: Response;
    try {
      response = await handler(request);
    } catch {
      // Runtime failures must be readable by the browser, without exposing
      // credentials, request content or internal exception details.
      response = Response.json(
        { error: 'INTERNAL_ERROR', message: 'Anfrage konnte nicht abgeschlossen werden.' },
        { status: 500, headers: { 'Cache-Control': 'no-store' } },
      );
    }
    const headers = new Headers(response.headers);
    for (const [name, value] of Object.entries(browserCorsHeaders)) {
      headers.set(name, value);
    }
    headers.delete('Access-Control-Allow-Credentials');
    return new Response(response.body, {
      status: response.status, statusText: response.statusText, headers,
    });
  };
}
