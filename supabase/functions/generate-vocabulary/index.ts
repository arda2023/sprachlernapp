import { GeneratedVocabularyBackend, generatedVocabularyHandler } from '../_shared/generated_vocabulary.ts';
Deno.serve(generatedVocabularyHandler(new GeneratedVocabularyBackend(
  Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  Deno.env.get('ANTHROPIC_API_KEY') ?? '',
)));
