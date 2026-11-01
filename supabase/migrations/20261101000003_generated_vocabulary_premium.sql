-- User decision 01.11.2026: topic vocabulary generation requires Premium.
-- Check current server-verified access before any new reservation or stored
-- result is returned. Existing local learning data and paid-attempt tombstones
-- are retained; retries, storage tickets and abuse caps keep their contracts.

create or replace function public.claim_generated_vocabulary(
  p_user uuid,p_request uuid,p_lang text,p_hash text,p_count integer,p_status_only boolean default false
) returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  item app.generated_vocabulary_requests;
  now_at timestamptz := clock_timestamp();
begin
  if p_user is null or p_request is null or p_lang is null or p_lang not in ('en','es','it','nb','pt-BR')
    or p_hash is null or p_hash !~ '^[0-9a-f]{64}$' or p_count is null or p_count not between 1 and 50
    or p_status_only is null then raise exception 'invalid generation claim' using errcode='22023'; end if;
  if not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null
    and not coalesce(is_anonymous,false)) then
    return jsonb_build_object('status','account_unverified');
  end if;
  -- Only server-synced entitlements can authorize this Premium feature.
  -- Sandbox rows are written only for the server's allowlisted testers,
  -- matching the existing Premium translation-budget rule.
  if not exists(
    select 1 from app.verified_entitlements e
    where e.user_id=p_user and e.entitlement_id='premium'
      and e.environment in ('Production','Sandbox') and e.is_active
      and e.product_id in (
        'com.ardasayar.linglossa.premium.monthly',
        'com.ardasayar.linglossa.premium.yearly'
      ) and e.starts_at<=now_at and e.expires_at>now_at
  ) then
    return jsonb_build_object('status','premium_required');
  end if;
  -- Global serialization makes the global and per-account caps atomic together.
  perform pg_advisory_xact_lock(741905507);
  -- Remove private response contents after 30 days; keep replay tombstones until
  -- account deletion so an old request can never trigger another provider call.
  update app.generated_vocabulary_requests set state='expired',response=null
    where state='ready' and created_at<now_at-interval '30 days';
  select * into item from app.generated_vocabulary_requests where user_id=p_user and request_id=p_request;
  if found then
    if item.input_hash<>p_hash or item.lang<>p_lang or item.item_count<>p_count then
      return jsonb_build_object('status','conflict');
    end if;
    if item.state='ready' then return jsonb_build_object('status','hit','response',item.response); end if;
    return jsonb_build_object('status',case
      when item.state='pending' and item.lease_until>now_at then 'busy'
      when item.state='pending' then 'uncertain' else item.state end);
  end if;
  if p_status_only then return jsonb_build_object('status','missing'); end if;
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
  insert into app.generated_vocabulary_requests(user_id,request_id,lang,input_hash,item_count)
    values(p_user,p_request,p_lang,p_hash,p_count) returning * into item;
  return jsonb_build_object('status','claimed','ticket',item.ticket);
end $$;

revoke all on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) from public,anon,authenticated;
grant execute on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) to service_role;
