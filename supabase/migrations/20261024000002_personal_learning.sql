-- Private creation responses, deliberately separate from display translations.
create table app.personal_learning_jobs (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_key text not null check(request_key ~ '^[0-9a-f]{64}$'),
  ticket uuid not null,
  state text not null check(state in ('pending','ready','uncertain')),
  lease_until timestamptz not null,
  expires_at timestamptz not null,
  response jsonb,
  primary key(user_id,request_key),
  check ((state='ready') = (response is not null))
);
alter table app.personal_learning_jobs enable row level security;
revoke all on app.personal_learning_jobs from public, anon, authenticated;
create index personal_learning_jobs_expiry on app.personal_learning_jobs(expires_at);

-- Service-only: caller identity comes from /auth/v1/user, never from request JSON.
-- Short transaction lock; never held while talking to the provider.
create function public.claim_personal_learning(p_user uuid,p_lang text,p_key text)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare item app.personal_learning_jobs; quota jsonb; ticket uuid;
begin
  if p_lang not in ('en','pt-BR') or not exists (
    select 1 from public.content_readers where user_id=p_user and lang=p_lang and channel='internal'
  ) then return jsonb_build_object('status','forbidden'); end if;
  if p_key is null or p_key !~ '^[0-9a-f]{64}$' then raise exception 'invalid key'; end if;
  perform pg_advisory_xact_lock(741905501);
  -- Expired payloads are never returned; lazy physical collection on activity.
  delete from app.personal_learning_jobs where expires_at<=clock_timestamp();
  select * into item from app.personal_learning_jobs where user_id=p_user and request_key=p_key;
  if found then
    if item.state='ready' then
      return jsonb_build_object('status','hit','response',item.response);
    end if;
    return jsonb_build_object('status',case when item.state='pending' and item.lease_until>clock_timestamp() then 'busy' else 'uncertain' end);
  end if;
  quota := public.reserve_runtime_translation(p_user,p_lang);
  if quota->>'allowed' <> 'true' then return jsonb_build_object('status',quota->>'reason'); end if;
  ticket := gen_random_uuid();
  insert into app.personal_learning_jobs values(p_user,p_key,ticket,'pending',clock_timestamp()+interval '45 seconds',clock_timestamp()+interval '24 hours',null);
  return jsonb_build_object('status','claimed','ticket',ticket);
end $$;

create function public.finish_personal_learning(p_user uuid,p_key text,p_ticket uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
  -- Full response validation is also enforced in the Edge Function before RPC.
  if p_response is null or jsonb_typeof(p_response) <> 'object' or length(p_response::text)>16384 then raise exception 'invalid response'; end if;
  perform pg_advisory_xact_lock(741905501);
  update app.personal_learning_jobs set state='ready',response=p_response,
    expires_at=clock_timestamp()+interval '30 days'
    where user_id=p_user and request_key=p_key and ticket=p_ticket
      and state='pending' and lease_until>clock_timestamp();
  get diagnostics changed=row_count;
  return jsonb_build_object('stored',changed=1);
end $$;


revoke all on function public.claim_personal_learning(uuid,text,text) from public,anon,authenticated;
revoke all on function public.finish_personal_learning(uuid,text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.claim_personal_learning(uuid,text,text) to service_role;
grant execute on function public.finish_personal_learning(uuid,text,uuid,jsonb) to service_role;

-- Verify IDs supplied from the actual installed pack, then supply authoritative
-- metadata to the model. Unknown/stale/foreign references fail; never dropped.
create function public.personal_learning_release(p_user uuid,p_lang text,p_release uuid,p_manifest text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.content_release_catalog;
begin
  if not exists(select 1 from public.content_readers where user_id=p_user and lang=p_lang and channel='internal') then
    return jsonb_build_object('status','forbidden');
  end if;
  select * into r from public.content_release_catalog where release_id=p_release and lang=p_lang and channel='internal' and manifest_sha256=p_manifest;
  if not found then return jsonb_build_object('status','invalid'); end if;
  return jsonb_build_object('status','ok','release',to_jsonb(r)-array['published_by']);
end; $$;
revoke all on function public.personal_learning_release(uuid,text,uuid,text) from public,anon,authenticated;
grant execute on function public.personal_learning_release(uuid,text,uuid,text) to service_role;
