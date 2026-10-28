-- Private display translations only; no content or learning tables are changed.
create table app.translation_cache (
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
alter table app.translation_cache enable row level security;
revoke all on app.translation_cache from public, anon, authenticated;
create index translation_cache_expiry on app.translation_cache(expires_at);

-- Service-only: caller identity comes from /auth/v1/user, never from request JSON.
-- Short transaction lock; never held while talking to the provider.
create function public.claim_translation(p_user uuid,p_lang text,p_key text)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare item app.translation_cache; quota jsonb; ticket uuid;
begin
  if p_lang not in ('en','pt-BR') or not exists (
    select 1 from public.content_readers where user_id=p_user and lang=p_lang and channel='internal'
  ) then return jsonb_build_object('status','forbidden'); end if;
  if p_key is null or p_key !~ '^[0-9a-f]{64}$' then raise exception 'invalid key'; end if;
  perform pg_advisory_xact_lock(741905501);
  -- Expired payloads are never returned; lazy physical collection on activity.
  delete from app.translation_cache where expires_at<=clock_timestamp();
  select * into item from app.translation_cache where user_id=p_user and request_key=p_key;
  if found then
    if item.state='ready' then
      return jsonb_build_object('status','hit','response',item.response);
    end if;
    return jsonb_build_object('status',case when item.state='pending' and item.lease_until>clock_timestamp() then 'busy' else 'uncertain' end);
  end if;
  quota := public.reserve_runtime_translation(p_user,p_lang);
  if quota->>'allowed' <> 'true' then return jsonb_build_object('status',quota->>'reason'); end if;
  ticket := gen_random_uuid();
  insert into app.translation_cache values(p_user,p_key,ticket,'pending',clock_timestamp()+interval '45 seconds',clock_timestamp()+interval '24 hours',null);
  return jsonb_build_object('status','claimed','ticket',ticket);
end $$;

create function public.finish_translation(p_user uuid,p_key text,p_ticket uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
  -- Full response validation is also enforced in the Edge Function before RPC.
  if p_response is null or p_response->>'provider' is distinct from 'anthropic'
    or p_response->>'model' is distinct from 'claude-haiku-5-5'
    or p_response->>'contract' is distinct from '2'
    or p_response->>'prompt' is distinct from 'translation-v2'
    or jsonb_typeof(p_response->'usage') is distinct from 'object'
    or length(p_response::text)>16384 then raise exception 'invalid response'; end if;
  perform pg_advisory_xact_lock(741905501);
  update app.translation_cache set state='ready',response=p_response,
    expires_at=clock_timestamp()+interval '30 days'
    where user_id=p_user and request_key=p_key and ticket=p_ticket
      and state='pending' and lease_until>clock_timestamp();
  get diagnostics changed=row_count;
  return jsonb_build_object('stored',changed=1);
end $$;

create function public.clear_translation_cache(p_user uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
begin
  perform pg_advisory_xact_lock(741905501);
  delete from app.translation_cache where user_id=p_user and (state='ready' or expires_at<=clock_timestamp());
  -- No text in these markers. A late response cannot resurrect deleted data;
  -- deletion is deliberately not a way to reset uncertain generation budget.
  update app.translation_cache set state='uncertain',response=null where user_id=p_user;
  return jsonb_build_object('deleted',true);
end $$;
revoke all on function public.claim_translation(uuid,text,text) from public,anon,authenticated;
revoke all on function public.finish_translation(uuid,text,uuid,jsonb) from public,anon,authenticated;
revoke all on function public.clear_translation_cache(uuid) from public,anon,authenticated;
grant execute on function public.claim_translation(uuid,text,text) to service_role;
grant execute on function public.finish_translation(uuid,text,uuid,jsonb) to service_role;
grant execute on function public.clear_translation_cache(uuid) to service_role;
