-- Daily news schedule (user decision 01.11.2026). One call per desk, a few
-- minutes apart, from 05:00 Berlin winter time (04:00 UTC). Each call stays
-- under the Edge Function time limit. The project URL and the shared secret
-- live in Vault (names project_url and news_cron_secret, see
-- docs/daily-news.md); the function compares the secret with its own
-- NEWS_CRON_SECRET, so the public anon key cannot start paid work.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

do $$
declare
  desk text;
  minute integer := 0;
begin
  foreach desk in array array['politics','economy','technology','medicine','entertainment'] loop
    perform cron.schedule(
      'daily-news-' || desk,
      minute || ' 4 * * *',
      format($job$
        select net.http_post(
          url := (select decrypted_secret from vault.decrypted_secrets
            where name = 'project_url') || '/functions/v1/refresh-news',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-news-secret', (select decrypted_secret from vault.decrypted_secrets
              where name = 'news_cron_secret')),
          body := jsonb_build_object('category', %L),
          timeout_milliseconds := 150000)
      $job$, desk));
    minute := minute + 6;
  end loop;
end $$;
