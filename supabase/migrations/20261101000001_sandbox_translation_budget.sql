-- User decision 01.11.2026: an active, verified Sandbox Premium entitlement
-- of an allowlisted tester unlocks the same monthly Premium translation
-- budget (500 per purchase month) as a Production entitlement, so a tester
-- with a Sandbox purchase no longer hits the 5 free translations. Free
-- accounts and every other rule stay unchanged; Production wins when both
-- rows exist.

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
      'com.ardasayar.linglossa.premium.yearly'
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
