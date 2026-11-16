-- Lifetime allowance for one authenticated non-Premium reservation.
-- Once vocabulary generation starts, even a failed or uncertain call retains
-- the allowance. Rejections before that call leave a replay tombstone.
alter table app.generated_vocabulary_requests
  add column free_sample boolean not null default false,
  add column free_sample_released boolean not null default false,
  add constraint released_free_sample_was_failed
    check (not free_sample_released or (free_sample and state='failed'));

create unique index generated_vocabulary_one_free_sample
  on app.generated_vocabulary_requests(user_id)
  where free_sample and not free_sample_released;

-- Read-only availability for the signed-in account. Reservation is still
-- authorized under the shared lock in claim_generated_vocabulary.
create function public.free_vocabulary_generation_available()
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from auth.users
    where id=auth.uid() and email_confirmed_at is not null
      and not coalesce(is_anonymous,false)
  ) and not exists (
    select 1 from app.generated_vocabulary_requests
    where user_id=auth.uid() and free_sample and not free_sample_released
  );
$$;
revoke all on function public.free_vocabulary_generation_available() from public,anon,authenticated;
grant execute on function public.free_vocabulary_generation_available() to authenticated;

create or replace function public.claim_generated_vocabulary(
  p_user uuid,p_request uuid,p_lang text,p_hash text,p_count integer,p_status_only boolean default false
) returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  item app.generated_vocabulary_requests;
  now_at timestamptz;
  premium boolean;
begin
  if p_user is null or p_request is null or p_lang is null or p_lang not in ('en','es','it','nb','pt-BR')
    or p_hash is null or p_hash !~ '^[0-9a-f]{64}$' or p_count is null or p_count not between 1 and 50
    or p_status_only is null then raise exception 'invalid generation claim' using errcode='22023'; end if;
  if not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null
    and not coalesce(is_anonymous,false)) then
    return jsonb_build_object('status','account_unverified');
  end if;
  -- Serialize all reservations against the shared budget and lifetime quota.
  perform pg_advisory_xact_lock(741905507);
  now_at := clock_timestamp();
  -- Only server-synced entitlements can authorize paid generations.
  -- Sandbox rows are written only for the server's allowlisted testers,
  -- matching the existing Premium translation-budget rule.
  select exists(
    select 1 from app.verified_entitlements e
    where e.user_id=p_user and e.entitlement_id='premium'
      and e.environment in ('Production','Sandbox') and e.is_active
      and e.product_id in (
        'com.ardasayar.linglossa.premium.monthly',
        'com.ardasayar.linglossa.premium.yearly',
        'com.ardasayar.linglossa.premium.complimentary'
      ) and e.starts_at<=now_at and e.expires_at>now_at
  ) into premium;
  -- Remove private response contents after 30 days; keep replay tombstones until
  -- account deletion so an old request can never trigger another provider call.
  update app.generated_vocabulary_requests set state='expired',response=null
    where state='ready' and created_at<now_at-interval '30 days';
  select * into item from app.generated_vocabulary_requests where user_id=p_user and request_id=p_request;
  if found then
    if not premium and not item.free_sample then
      return jsonb_build_object('status','premium_required');
    end if;
    if item.input_hash<>p_hash or item.lang<>p_lang or item.item_count<>p_count then
      return jsonb_build_object('status','conflict');
    end if;
    if item.state='ready' then
      return jsonb_build_object('status','hit','response',item.response,'free_sample',item.free_sample);
    end if;
    return jsonb_build_object('status',case
      when item.state='pending' and item.lease_until>now_at then 'busy'
      when item.state='pending' then 'uncertain' else item.state end);
  end if;
  if p_status_only then return jsonb_build_object('status','missing'); end if;
  if not premium and exists(
    select 1 from app.generated_vocabulary_requests
    where user_id=p_user and free_sample and not free_sample_released
  ) then
    return jsonb_build_object('status','premium_required');
  end if;
  if exists(select 1 from app.generated_vocabulary_requests where user_id=p_user
    and state='pending' and lease_until>now_at) then return jsonb_build_object('status','busy'); end if;
  -- Initial abuse/cost guardrails, independent of subscription/translation quotas.
  if (select count(*) from app.generated_vocabulary_requests
      where user_id=p_user and created_at>now_at-interval '24 hours')>=5
    or (select coalesce(sum(item_count),0) from app.generated_vocabulary_requests
      where user_id=p_user and created_at>now_at-interval '24 hours')+p_count>250
    or (select coalesce(sum(item_count),0) from app.generated_vocabulary_requests
      where created_at>now_at-interval '24 hours')+p_count>20000 then
    return jsonb_build_object('status','limit');
  end if;
  insert into app.generated_vocabulary_requests(user_id,request_id,lang,input_hash,item_count,free_sample)
    values(p_user,p_request,p_lang,p_hash,p_count,not premium) returning * into item;
  return jsonb_build_object('status','claimed','ticket',item.ticket,'free_sample',item.free_sample);
end $$;

revoke all on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) from public,anon,authenticated;
grant execute on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) to service_role;

-- Keep the request, its paid admission costs, and the rolling attempt/word
-- caps even when the main provider call provably never started.
create function public.release_unused_free_vocabulary_sample(
  p_user uuid,p_request uuid,p_ticket uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
begin
  update app.generated_vocabulary_requests set state='failed',free_sample_released=true
    where user_id=p_user and request_id=p_request and ticket=p_ticket
      and free_sample and state='pending';
  return jsonb_build_object('status','ok');
end $$;
revoke all on function public.release_unused_free_vocabulary_sample(uuid,uuid,uuid)
  from public,anon,authenticated;
grant execute on function public.release_unused_free_vocabulary_sample(uuid,uuid,uuid)
  to service_role;
