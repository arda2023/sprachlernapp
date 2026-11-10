import { withBrowserCors } from "../_shared/browser_cors.ts";
import {
  accountDeletionHandler,
  SupabaseAccountDeletionBackend,
} from "../_shared/account_deletion.ts";

Deno.serve(withBrowserCors(accountDeletionHandler(
  new SupabaseAccountDeletionBackend(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    Deno.env.get("ADAPTY_API_KEY") ?? "",
  ),
)));
