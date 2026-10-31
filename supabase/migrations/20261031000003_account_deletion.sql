-- Personal account rows cascade with auth.users. The append-only review log is
-- immutable during normal operation, but account erasure may remove it as part
-- of the parent-user cascade.
create or replace function app.reject_review_log_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' and not exists (
    select 1 from auth.users where id = old.user_id
  ) then
    return old;
  end if;
  raise exception 'review_log is append-only (% not allowed)', tg_op
    using errcode = 'P0001';
end $$;

-- Publication records must outlive a publisher account. Keep their actor UUIDs
-- as immutable historical identifiers, without retaining an auth.users FK.
alter table public.content_release_catalog
  drop constraint content_release_catalog_published_by_fkey;
alter table public.content_publish_audit
  drop constraint content_publish_audit_actor_id_fkey;
alter table public.content_release_uploads
  drop constraint content_release_uploads_owner_id_fkey;

-- Reader grants are user data and should be removed with the account.
alter table public.content_readers
  drop constraint content_readers_user_id_fkey;
alter table public.content_readers
  add constraint content_readers_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete cascade;

-- A resumable publisher verification run is tied to immutable publication
-- history only by its upload; erase the account reference if one exists.
alter table public.content_verification_runs
  drop constraint content_verification_runs_resume_actor_fkey;
alter table public.content_verification_runs
  add constraint content_verification_runs_resume_actor_fkey
  foreign key (resume_actor) references auth.users(id) on delete set null;

-- Remove server-side billing event details in the same transaction as auth
-- deletion. Entitlement/profile binding rows already cascade from auth.users.
create or replace function public.purge_billing_events_for_deleted_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  delete from app.adapty_webhook_events where user_id = old.id;
  return old;
end;
$$;
revoke all on function public.purge_billing_events_for_deleted_user()
  from public, anon, authenticated;
create trigger purge_billing_events_before_auth_delete
  before delete on auth.users
  for each row execute function public.purge_billing_events_for_deleted_user();
