-- Expiration is enforced even if nobody opens the app. Retain request hashes
-- as no-replay tombstones, but remove generated vocabulary response contents.
create function app.purge_expired_private_ai() returns integer
language plpgsql security definer set search_path='' as $$
declare removed integer; personal_removed integer;
begin
  update app.generated_vocabulary_requests set state='expired',response=null
    where state='ready' and created_at<clock_timestamp()-interval '30 days';
  get diagnostics removed = row_count;
  update app.personal_learning_jobs set state='uncertain',response=null
    where state='ready' and expires_at<=clock_timestamp();
  get diagnostics personal_removed = row_count;
  -- Closed spending periods cannot affect the active budget. No prompt or
  -- provider content is ever recorded in this ledger.
  delete from app.ai_spend_months
    where month_start < (date_trunc('month',clock_timestamp() at time zone 'UTC')-interval '2 months')::date;
  return removed+personal_removed;
end $$;
revoke all on function app.purge_expired_private_ai() from public,anon,authenticated;
grant execute on function app.purge_expired_private_ai() to service_role;

create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('purge-private-ai','17 * * * *','select app.purge_expired_private_ai()');
