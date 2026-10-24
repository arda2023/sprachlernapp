import { PersonalLearningBackend, personalHandler } from '../_shared/personal_learning.ts';
Deno.serve(personalHandler(new PersonalLearningBackend(
  Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  Deno.env.get('ANTHROPIC_API_KEY') ?? '',
)));
