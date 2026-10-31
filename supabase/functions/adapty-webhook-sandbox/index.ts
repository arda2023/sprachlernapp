import {
  AdaptyBillingBackend,
  webhookHandler,
} from "../_shared/adapty_billing.ts";

Deno.serve(webhookHandler(
  new AdaptyBillingBackend(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    Deno.env.get("ADAPTY_API_KEY") ?? "",
  ),
  Deno.env.get("ADAPTY_SANDBOX_WEBHOOK_SECRET") ?? "",
  "Sandbox",
));
