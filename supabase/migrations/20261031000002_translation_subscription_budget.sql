-- Server-owned budgets for newly generated display translations only.
-- Personal-learning jobs keep using reserve_runtime_translation unchanged.
create table app.translation_budget_reservations (
  ticket uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  request_key text not null check (request_key ~ '^[0-9a-f]{64}$'),
  quota_kind text not null check (quota_kind in ('free', 'premium')),
  period_start timestamptz,
  state text not null check (state in ('pending', 'charged', 'released')),
  lease_until timestamptz not null,
  created_at timestamptz not null default now(),
  check ((quota_kind = 'free') = (period_start is null))
);
create index translation_budget_user_period
  on app.translation_budget_reservations(user_id, quota_kind, period_start, state);
alter table app.translation_budget_reservations enable row level security;
revoke all on app.translation_budget_reservations from public, anon, authenticated;
grant all on app.translation_budget_reservations to service_role;

create or replace function app.translation_cycle(p_anchor timestamptz,p_now timestamptz)
returns table(period_start timestamptz,period_end timestamptz)
language plpgsql immutable set search_path='' as $$
declare
  anchor_utc timestamp without time zone := p_anchor at time zone 'UTC';
  now_utc timestamp without time zone := p_now at time zone 'UTC';
  month_index integer;
  start_utc timestamp without time zone;
  end_utc timestamp without time zone;
begin
  if p_anchor is null or p_now is null or p_now<p_anchor then
    raise exception 'Invalid translation cycle boundary' using errcode='22023';
  end if;
  month_index := (extract(year from now_utc)::integer-extract(year from anchor_utc)::integer)*12
    + extract(month from now_utc)::integer-extract(month from anchor_utc)::integer;
  start_utc := anchor_utc+make_interval(months=>month_index);
  while start_utc>now_utc loop
    month_index := month_index-1;
    start_utc := anchor_utc+make_interval(months=>month_index);
  end loop;
  end_utc := anchor_utc+make_interval(months=>month_index+1);
  while end_utc<=now_utc loop
    month_index := month_index+1;
    start_utc := end_utc;
    end_utc := anchor_utc+make_interval(months=>month_index+1);
  end loop;
  return query select start_utc at time zone 'UTC',end_utc at time zone 'UTC';
end $$;
revoke all on function app.translation_cycle(timestamptz,timestamptz)
  from public,anon,authenticated;
grant execute on function app.translation_cycle(timestamptz,timestamptz)
  to service_role;

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
    and e.environment='Production' and e.is_active
    and e.product_id in (
      'com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly'
    ) and e.starts_at<=now_at and e.expires_at>now_at;

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

create or replace function public.finish_translation(p_user uuid,p_key text,p_ticket uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
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
      and state='pending' and lease_until>clock_timestamp()
      and exists(select 1 from app.translation_budget_reservations r
        where r.ticket=p_ticket and r.user_id=p_user and r.request_key=p_key
          and r.state='pending' and r.lease_until>clock_timestamp());
  get diagnostics changed=row_count;
  if changed=1 then
    update app.translation_budget_reservations set state='charged'
      where ticket=p_ticket and user_id=p_user and state='pending';
  end if;
  return jsonb_build_object('stored',changed=1);
end $$;

create or replace function public.release_translation(p_user uuid,p_key text,p_ticket uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare changed integer;
begin
  perform pg_advisory_xact_lock(741905501);
  update app.translation_budget_reservations set state='released'
    where ticket=p_ticket and user_id=p_user and request_key=p_key and state='pending';
  get diagnostics changed=row_count;
  update app.translation_cache set state='uncertain',response=null,
    lease_until=clock_timestamp()
    where user_id=p_user and request_key=p_key and ticket=p_ticket and state='pending';
  return jsonb_build_object('released',changed=1 or exists(
    select 1 from app.translation_budget_reservations
    where ticket=p_ticket and user_id=p_user and request_key=p_key and state='released'
  ));
end $$;

create or replace function public.clear_translation_cache(p_user uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
begin
  perform pg_advisory_xact_lock(741905501);
  delete from app.translation_cache where user_id=p_user and (state='ready' or expires_at<=clock_timestamp());
  -- A deleted in-flight result cannot be delivered, so release its reservation.
  update app.translation_budget_reservations set state='released'
    where user_id=p_user and state='pending';
  update app.translation_cache set state='uncertain',response=null
    where user_id=p_user;
  return jsonb_build_object('deleted',true);
end $$;

revoke all on function public.claim_translation(uuid,text,text) from public,anon,authenticated;
revoke all on function public.finish_translation(uuid,text,uuid,jsonb) from public,anon,authenticated;
revoke all on function public.release_translation(uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.clear_translation_cache(uuid) from public,anon,authenticated;
grant execute on function public.claim_translation(uuid,text,text) to service_role;
grant execute on function public.finish_translation(uuid,text,uuid,jsonb) to service_role;
grant execute on function public.release_translation(uuid,text,uuid) to service_role;
grant execute on function public.clear_translation_cache(uuid) to service_role;
