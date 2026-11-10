import { withBrowserCors } from "../_shared/browser_cors.ts";
import {
  AdaptyBillingBackend,
  billingSyncHandler,
} from "../_shared/adapty_billing.ts";

const testerIds = new Set(
  (Deno.env.get("ADAPTY_SANDBOX_TESTER_IDS") ?? "")
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
);

Deno.serve(withBrowserCors(billingSyncHandler(
  new AdaptyBillingBackend(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    Deno.env.get("ADAPTY_API_KEY") ?? "",
    fetch,
    Deno.env.get("ADAPTY_SANDBOX_ENABLED") === "true",
    testerIds,
  ),
)));
