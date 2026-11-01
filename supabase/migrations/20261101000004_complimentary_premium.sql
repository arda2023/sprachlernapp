-- User decision 01.11.2026: a finite Premium gift granted through Adapty's
-- server API has the same Premium features and translation budget. The Edge
-- Functions recognize only Adapty's exact manual-grant markers from a fresh
-- authenticated provider profile and map them to this internal product ID.
-- Gifts are Production-only, have a finite validity window and never renew.

alter table app.verified_entitlements
  drop constraint verified_entitlements_product_id_check;
alter table app.verified_entitlements
  add constraint verified_entitlements_product_id_check check (product_id in (
    'com.ardasayar.linglossa.premium.monthly',
    'com.ardasayar.linglossa.premium.yearly',
    'com.ardasayar.linglossa.premium.complimentary'
  )),
  add constraint verified_entitlements_complimentary_check check (
    product_id is distinct from 'com.ardasayar.linglossa.premium.complimentary'
    or (environment='Production' and will_renew is false
      and starts_at is not null and expires_at is not null
      and isfinite(starts_at) and isfinite(expires_at) and expires_at>starts_at)
  );

create or replace function app.sync_adapty_entitlement(
  p_user_id uuid,
  p_profile_id uuid,
  p_environment text,
  p_product_id text,
  p_is_active boolean,
  p_starts_at timestamptz,
  p_expires_at timestamptz,
  p_will_renew boolean,
  p_observed_at timestamptz,
  p_event_id text default null,
  p_event_type text default null,
  p_event_datetime timestamptz default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  current_row app.verified_entitlements;
  saved_row app.verified_entitlements;
begin
  if p_environment not in ('Production', 'Sandbox')
    or p_product_id is not null and p_product_id not in (
      'com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly',
      'com.ardasayar.linglossa.premium.complimentary'
    )
    or p_product_id='com.ardasayar.linglossa.premium.complimentary' and (
      p_environment is distinct from 'Production' or p_will_renew is distinct from false
      or p_starts_at is null or p_expires_at is null
      or not isfinite(p_starts_at) or not isfinite(p_expires_at)
      or p_expires_at<=p_starts_at
    )
    or p_is_active and (
      p_product_id is null or p_starts_at is null or p_expires_at is null
      or p_starts_at > now() or p_expires_at <= now()
    )
    or (p_event_id is null) <> (p_event_type is null)
    or p_event_id is not null and p_event_id !~ '^[a-f0-9-]{1,80}$'
    or p_event_type is not null and length(p_event_type) > 80
  then
    raise exception 'Invalid verified entitlement' using errcode = '22023';
  end if;

  if not exists (
    select 1 from app.adapty_profile_bindings b
    where b.user_id = p_user_id and b.profile_id = p_profile_id
  ) then
    raise exception 'Adapty profile is not bound to this account'
      using errcode = '42501';
  end if;

  if p_event_id is not null then
    insert into app.adapty_webhook_events(
      environment, event_id, event_type, user_id, profile_id,
      event_datetime
    ) values (
      p_environment, p_event_id, p_event_type, p_user_id, p_profile_id,
      p_event_datetime
    ) on conflict do nothing;

    if not found then
      select * into current_row from app.verified_entitlements
        where user_id = p_user_id and entitlement_id = 'premium'
          and environment = p_environment;
      return jsonb_build_object(
        'duplicate', true,
        'entitlement', 'premium',
        'is_active', coalesce(current_row.is_active, false),
        'product_id', current_row.product_id,
        'starts_at', current_row.starts_at,
        'expires_at', current_row.expires_at,
        'will_renew', current_row.will_renew,
        'environment', p_environment,
        'synced_at', current_row.observed_at
      );
    end if;
  end if;

  insert into app.verified_entitlements(
    user_id, entitlement_id, environment, is_active, product_id,
    starts_at, expires_at, will_renew, observed_at
  ) values (
    p_user_id, 'premium', p_environment, p_is_active, p_product_id,
    p_starts_at, p_expires_at, p_will_renew, p_observed_at
  ) on conflict (user_id, entitlement_id, environment) do update set
    is_active = excluded.is_active,
    product_id = excluded.product_id,
    starts_at = excluded.starts_at,
    expires_at = excluded.expires_at,
    will_renew = excluded.will_renew,
    observed_at = excluded.observed_at
  where app.verified_entitlements.observed_at <= excluded.observed_at
  returning * into saved_row;

  if not found then
    select * into saved_row from app.verified_entitlements
      where user_id = p_user_id and entitlement_id = 'premium'
        and environment = p_environment;
  end if;

  return jsonb_build_object(
    'duplicate', false,
    'entitlement', 'premium',
    'is_active', saved_row.is_active,
    'product_id', saved_row.product_id,
    'starts_at', saved_row.starts_at,
    'expires_at', saved_row.expires_at,
    'will_renew', saved_row.will_renew,
    'environment', saved_row.environment,
    'synced_at', saved_row.observed_at
  );
end $$;

revoke all on function app.sync_adapty_entitlement(
  uuid, uuid, text, text, boolean, timestamptz, timestamptz, boolean,
  timestamptz, text, text, timestamptz
) from public, anon, authenticated;
grant execute on function app.sync_adapty_entitlement(
  uuid, uuid, text, text, boolean, timestamptz, timestamptz, boolean,
  timestamptz, text, text, timestamptz
) to service_role;

create or replace function public.claim_translation(p_user uuid,p_lang text,p_key text)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  item app.translation_cache;
  ticket uuid;
  actor_verified boolean;
  v_paid_start timestamptz;
  v_quota_kind text;
  v_period_start timestamptz;
  v_period_end timestamptz;
  used integer;
  today date := (clock_timestamp() at time zone 'UTC')::date;
  now_at timestamptz := clock_timestamp();
  minute_kind text := 'translation-minute:' || to_char(clock_timestamp() at time zone 'UTC','YYYYMMDDHH24MI');
  per_minute integer;
  total bigint;
  cap integer;
begin
  if p_lang not in ('en','pt-BR') then
    return jsonb_build_object('status','forbidden');
  end if;
  if p_key is null or p_key !~ '^[0-9a-f]{64}$' then raise exception 'invalid key'; end if;
  select coalesce(u.email_confirmed_at is not null and not coalesce(u.is_anonymous,false),false)
    into actor_verified from auth.users u where u.id=p_user;
  if not coalesce(actor_verified,false) then
    return jsonb_build_object('status','account_unverified');
  end if;

  -- Serializes display claims, budget finishes/releases, cache operations, and
  -- the existing global runtime-translation abuse counters.
  perform pg_advisory_xact_lock(741905501);
  delete from app.translation_cache where expires_at<=now_at;
  update app.translation_budget_reservations set state='released'
    where state='pending' and lease_until<=now_at;
  delete from app.translation_budget_reservations
    where (state='released' and lease_until<now_at-interval '1 day')
      or (quota_kind='premium' and state='charged'
        and period_start<now_at-interval '2 months');
  select * into item from app.translation_cache
    where user_id=p_user and request_key=p_key;
  if found then
    if item.state='ready' then
      return jsonb_build_object('status','hit','response',item.response);
    end if;
    return jsonb_build_object(
      'status',case when item.state='pending' and item.lease_until>now_at then 'busy' else 'uncertain' end
    );
  end if;

  select e.starts_at into v_paid_start
  from app.verified_entitlements e
  where e.user_id=p_user and e.entitlement_id='premium'
    -- Sandbox rows exist only for allowlisted testers (billing-sync writes
    -- them only with ADAPTY_SANDBOX_ENABLED and ADAPTY_SANDBOX_TESTER_IDS).
    and e.environment in ('Production','Sandbox') and e.is_active
    and e.product_id in (
      'com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly',
      'com.ardasayar.linglossa.premium.complimentary'
    ) and e.starts_at<=now_at and e.expires_at>now_at
  order by e.environment='Production' desc, e.starts_at
  limit 1;

  if v_paid_start is not null then
    v_quota_kind := 'premium';
    -- The original purchase timestamp anchors monthly allocations, including
    -- annual subscriptions. PostgreSQL clamps short months while preserving
    -- the original anchor for later cycles (for example, Jan 31 -> Feb 28 -> Mar 31).
    select c.period_start,c.period_end into v_period_start,v_period_end
      from app.translation_cycle(v_paid_start,now_at) c;
    cap := 500;
    select count(*) into used from app.translation_budget_reservations r
      where r.user_id=p_user and r.quota_kind='premium'
        and r.period_start=v_period_start
        and (r.state='charged' or (r.state='pending' and r.lease_until>now_at));
  else
    v_quota_kind := 'free';
    v_period_start := null;
    v_period_end := null;
    cap := 5;
    select count(*) into used from app.translation_budget_reservations r
      where r.user_id=p_user and r.quota_kind='free'
        and (r.state='charged' or (r.state='pending' and r.lease_until>now_at));
  end if;

  if used >= cap then
    return jsonb_build_object(
      'status','quota', 'quota_kind',v_quota_kind,
      'resets_at',v_period_end, 'remaining',0
    );
  end if;

  -- Keep only the short/global abuse protection here. The existing
  -- personal-learning daily gate remains in reserve_runtime_translation.
  select coalesce(sum(units),0) into total from app.usage
    where day=today and kind='runtime-translation';
  select coalesce(max(units),0) into per_minute from app.usage
    where user_id=p_user and day=today and kind=minute_kind;
  if total>=1000 or per_minute>=5 then
    return jsonb_build_object('status','limit');
  end if;

  ticket := gen_random_uuid();
  insert into app.translation_budget_reservations(
    ticket,user_id,request_key,quota_kind,period_start,state,lease_until
  ) values (ticket,p_user,p_key,v_quota_kind,v_period_start,'pending',now_at+interval '45 seconds');
  insert into app.translation_cache(
    user_id,request_key,ticket,state,lease_until,expires_at,response
  ) values (p_user,p_key,ticket,'pending',now_at+interval '45 seconds',now_at+interval '24 hours',null);
  insert into app.usage(user_id,day,kind,units)
    values(p_user,today,'runtime-translation',1),(p_user,today,minute_kind,1)
    on conflict(user_id,day,kind) do update set units=app.usage.units+1;
  return jsonb_build_object('status','claimed','ticket',ticket);
end $$;

revoke all on function public.claim_translation(uuid,text,text) from public,anon,authenticated;
grant execute on function public.claim_translation(uuid,text,text) to service_role;

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
        'com.ardasayar.linglossa.premium.yearly',
        'com.ardasayar.linglossa.premium.complimentary'
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
