import { DailyNewsBackend, dailyNewsHandler } from '../../../functions/_shared/daily_news.ts';
Deno.serve(dailyNewsHandler(new DailyNewsBackend(
  Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  Deno.env.get('ANTHROPIC_API_KEY') ?? '', Deno.env.get('NEWS_CRON_SECRET') ?? '',
)));
