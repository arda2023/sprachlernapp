-- Account learning sync v1. No provider calls and no computed counters.
-- Opaque row payloads retain the installed app's SQLite schema; the protocol
-- allowlist excludes credentials, translation consent, caches and feedback.
create table app.learning_sync_rows (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in (
    'user_cards','card_contexts','review_log','deck_settings',
    'story_learning_additions','generated_vocabulary_additions',
    'story_word_sources','learning_identity_bindings','form_identity_bindings',
    'language_learning_preferences','learning_sync_documents'
  )),
  row_key text not null check (octet_length(row_key) between 1 and 4096),
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 200000),
  changed_at bigint not null check (changed_at > 0),
  hash text not null check (hash ~ '^[0-9a-f]{64}$'),
  primary key (user_id, kind, row_key)
);
alter table app.learning_sync_rows enable row level security;
create policy "read own learning sync" on app.learning_sync_rows for select to authenticated using ((select auth.uid()) = user_id);
revoke all on app.learning_sync_rows from public, anon, authenticated;
grant select on app.learning_sync_rows to authenticated;
grant all on app.learning_sync_rows to service_role;

create function public.push_learning_rows(rows jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  item jsonb;
  existing app.learning_sync_rows;
  row_kind text;
  row_id text;
  row_time bigint;
  row_hash text;
begin
  if uid is null or not exists (select 1 from auth.users where id=uid and email_confirmed_at is not null and not coalesce(is_anonymous,false)) then
    raise exception 'Confirmed account required' using errcode='42501';
  end if;
  if jsonb_typeof(rows) <> 'array' or jsonb_array_length(rows) > 100 or octet_length(rows::text) > 4000000 then
    raise exception 'Invalid sync batch' using errcode='22023';
  end if;
  -- Serialize one account's batches, including first inserts.
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 7241));
  for item in select value from jsonb_array_elements(rows) loop
    row_kind := item->>'kind'; row_id := item->>'key';
    row_time := (item->>'changed_at')::bigint; row_hash := item->>'hash';
    if row_time > extract(epoch from now())*1000 + 86400000 then
      raise exception 'Device clock is ahead' using errcode='22023';
    end if;
    select * into existing from app.learning_sync_rows where user_id=uid and kind=row_kind and row_key=row_id;
    if found then
      if existing.hash = row_hash then continue; end if;
      if row_kind not in ('user_cards','deck_settings','language_learning_preferences','learning_sync_documents') then
        -- Review/context IDs are immutable, even through this privileged RPC.
        raise exception 'Immutable learning row conflict' using errcode='23505';
      end if;
      if (existing.changed_at, existing.hash) >= (row_time,row_hash) then continue; end if;
      update app.learning_sync_rows set payload=item->'data', changed_at=row_time, hash=row_hash
        where user_id=uid and kind=row_kind and row_key=row_id;
    else
      insert into app.learning_sync_rows(user_id,kind,row_key,payload,changed_at,hash)
        values(uid,row_kind,row_id,item->'data',row_time,row_hash);
    end if;
  end loop;
end $$;

create function public.pull_learning_rows(after_key text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); result jsonb;
begin
  if uid is null or not exists (select 1 from auth.users where id=uid and email_confirmed_at is not null and not coalesce(is_anonymous,false)) then
    raise exception 'Confirmed account required' using errcode='42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('kind',kind,'key',row_key,'data',payload,'changed_at',changed_at,'hash',hash) order by cursor_key collate "C"),'[]'::jsonb)
    into result from (
      select *, kind || chr(31) || row_key as cursor_key from app.learning_sync_rows
      where user_id=uid and (after_key is null or (kind || chr(31) || row_key) collate "C" > after_key collate "C")
      order by (kind || chr(31) || row_key) collate "C" limit 500
    ) page;
  return result;
end $$;
revoke all on function public.push_learning_rows(jsonb) from public, anon;
revoke all on function public.pull_learning_rows(text) from public, anon;
grant execute on function public.push_learning_rows(jsonb), public.pull_learning_rows(text) to authenticated;
