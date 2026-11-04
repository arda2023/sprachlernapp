-- User decision 01.11.2026: aggregate all user-triggered AI under EUR 5/month.
-- UTC calendar months; integer micro-euros; no client write/read access.
-- Conservative tariff: USD price * 2 EUR/USD INCLUDING exchange/tax/fee buffer.
-- Reserve the FULL documented 1M input context, not a tokenizer estimate, plus
-- the feature's maximum output. Settle once using trusted provider usage.
-- Current prices must be reviewed before valid_until. Expired policy fails shut.
create table app.ai_spend_policy (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default true,
  valid_until timestamptz not null,
  model text not null check (model='claude-haiku-5-5'),
  monthly_limit_micros bigint not null check (monthly_limit_micros between 1 and 5000000)
);
insert into app.ai_spend_policy values (true,true,'2026-12-01 00:00:00+00','claude-haiku-5-5',5000000);

create table app.ai_spend_months (
  user_id uuid not null references auth.users(id) on delete cascade,
  month_start date not null,
  used_micros bigint not null default 0 check (used_micros between 0 and 5000000),
  primary key(user_id,month_start)
);
create table app.ai_spend_attempts (
  attempt_id uuid primary key,
  user_id uuid not null,
  month_start date not null,
  feature text not null check(feature in ('lookup-word','translate-sentence','personal-learning','topic-check','generated-vocabulary')),
  max_output integer not null,
  reserved_micros bigint not null,
  charged_micros bigint,
  input_tokens integer,
  output_tokens integer,
  created_at timestamptz not null default clock_timestamp(),
  foreign key(user_id,month_start) references app.ai_spend_months on delete cascade,
  check(charged_micros is null or charged_micros between 0 and reserved_micros)
);
create index ai_spend_attempts_owner on app.ai_spend_attempts(user_id,month_start);
alter table app.ai_spend_policy enable row level security;
alter table app.ai_spend_months enable row level security;
alter table app.ai_spend_attempts enable row level security;
revoke all on app.ai_spend_policy,app.ai_spend_months,app.ai_spend_attempts from public,anon,authenticated;
grant select on app.ai_spend_policy,app.ai_spend_months,app.ai_spend_attempts to service_role;

create function public.reserve_ai_spend(p_user uuid,p_attempt uuid,p_feature text)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  period date := date_trunc('month',clock_timestamp() at time zone 'UTC')::date;
  policy app.ai_spend_policy;
  max_out integer;
  reserve bigint;
  existing app.ai_spend_attempts;
begin
  max_out := case p_feature when 'lookup-word' then 384 when 'translate-sentence' then 384
    when 'personal-learning' then 1500 when 'topic-check' then 128 when 'generated-vocabulary' then 16000 end;
  if p_user is null or p_attempt is null or max_out is null then raise exception 'Invalid AI reservation' using errcode='22023'; end if;
  select * into policy from app.ai_spend_policy where singleton;
  if not found or not policy.enabled or policy.valid_until<=clock_timestamp() then
    return jsonb_build_object('status','unavailable');
  end if;
  if not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null and not coalesce(is_anonymous,false)) then
    return jsonb_build_object('status','forbidden');
  end if;
  -- Separate from business quotas. Never modified by cache deletion, failed
  -- delivery, logout, purchase changes, or expiration of an endpoint lease.
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905508));
  select * into existing from app.ai_spend_attempts where attempt_id=p_attempt;
  if found then return jsonb_build_object('status','replay'); end if;
  reserve := 1000000 + max_out::bigint*5;
  insert into app.ai_spend_months(user_id,month_start) values(p_user,period) on conflict do nothing;
  update app.ai_spend_months set used_micros=used_micros+reserve
    where user_id=p_user and month_start=period
      and used_micros+reserve<=policy.monthly_limit_micros;
  if not found then return jsonb_build_object('status','limit'); end if;
  insert into app.ai_spend_attempts(attempt_id,user_id,month_start,feature,max_output,reserved_micros)
    values(p_attempt,p_user,period,p_feature,max_out,reserve);
  return jsonb_build_object('status','reserved');
end $$;

create function public.settle_ai_spend(p_user uuid,p_attempt uuid,p_input_tokens integer,p_output_tokens integer)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  attempt app.ai_spend_attempts;
  charged bigint;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905508));
  select * into attempt from app.ai_spend_attempts where attempt_id=p_attempt and user_id=p_user for update;
  if not found then return jsonb_build_object('status','missing'); end if;
  if attempt.charged_micros is not null then return jsonb_build_object('status','settled'); end if;
  if p_input_tokens is null or p_input_tokens<0 or p_input_tokens>1000000 or
     p_output_tokens is null or p_output_tokens<0 or p_output_tokens>attempt.max_output then
    raise exception 'Invalid provider usage' using errcode='22023';
  end if;
  -- Short prompts: EUR 0.20 / 1.00 per MTok. Long: EUR 1.00 / 5.00.
  charged := case when p_input_tokens<=100000 then (p_input_tokens::bigint+4)/5+p_output_tokens::bigint
    else p_input_tokens::bigint+5*p_output_tokens::bigint end;
  update app.ai_spend_months set used_micros=used_micros-attempt.reserved_micros+charged
    where user_id=p_user and month_start=attempt.month_start;
  update app.ai_spend_attempts set charged_micros=charged,input_tokens=p_input_tokens,output_tokens=p_output_tokens
    where attempt_id=p_attempt;
  return jsonb_build_object('status','settled');
end $$;
revoke all on function public.reserve_ai_spend(uuid,uuid,text),public.settle_ai_spend(uuid,uuid,integer,integer) from public,anon,authenticated;
grant execute on function public.reserve_ai_spend(uuid,uuid,text),public.settle_ai_spend(uuid,uuid,integer,integer) to service_role;
