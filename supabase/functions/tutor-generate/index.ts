import { withBrowserCors } from '../_shared/browser_cors.ts';
import { TutorBackend, tutorHandler } from '../_shared/tutor.ts';
Deno.serve(withBrowserCors(tutorHandler(new TutorBackend(
  Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  Deno.env.get('ANTHROPIC_API_KEY') ?? '',
), 'tutor-generate')));
