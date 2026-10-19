import {
  TranslationBackend,
  translationHandler,
} from "../_shared/runtime_translation.ts";
Deno.serve(translationHandler(
  "translate-sentence",
  new TranslationBackend(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    Deno.env.get("ANTHROPIC_API_KEY") ?? "",
  ),
));
