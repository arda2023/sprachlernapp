-- Private tutor. Only service_role can reserve, complete or release a request.
-- Keep content-free replay tombstones until account deletion. Never retry an
-- expired lease: an unknown provider outcome may already have been billed.
create table app.tutor_requests (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  operation text not null check (operation in ('tutor-generate','tutor-grade')),
  input_hash text not null check (input_hash ~ '^[0-9a-f]{64}$'),
  units integer not null check (units between 1 and 5),
  lang text check (lang in ('en','pt-BR','es','it','nb')),
  item_id uuid,
  quota_day date not null,
  quota_limit integer not null,
  quota_used integer not null,
  released boolean not null default false,
  state text not null default 'pending' check (state in ('pending','ready','failed','expired')),
  ticket uuid not null default gen_random_uuid(),
  response jsonb,
  created_at timestamptz not null default clock_timestamp(),
  lease_until timestamptz not null default (clock_timestamp()+interval '2 minutes'),
  primary key(user_id,operation,request_id),
  check ((state='ready')=(response is not null)),
  check (not released or state in ('failed','expired')),
  check (response is null or octet_length(response::text)<=65536),
  check ((operation='tutor-generate' and lang is not null and item_id is null)
    or (operation='tutor-grade' and lang is null and item_id is not null and units=1))
);
create index tutor_requests_daily on app.tutor_requests(user_id,operation,quota_day) where not released;

create table app.tutor_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  id uuid not null,
  request_id uuid not null,
  lang text not null check (lang in ('en','pt-BR','es','it','nb')),
  kind text not null check (kind in ('translate','situation')),
  prompt_de text check (char_length(prompt_de) between 8 and 160),
  reference_answer text check (char_length(reference_answer) between 2 and 200),
  skills text[],
  topic text,
  parent_item_id uuid,
  created_at timestamptz not null default clock_timestamp(),
  primary key(user_id,id),
  foreign key(user_id,parent_item_id) references app.tutor_items(user_id,id),
  check (skills is null or cardinality(skills) between 1 and 2)
);
create table app.tutor_attempts (
  user_id uuid not null references auth.users(id) on delete cascade,
  attempt_id uuid not null,
  item_id uuid not null,
  answer text check (char_length(answer) between 1 and 300),
  result jsonb check (result is null or octet_length(result::text)<=8192),
  created_at timestamptz not null default clock_timestamp(),
  primary key(user_id,attempt_id),
  foreign key(user_id,item_id) references app.tutor_items(user_id,id) on delete cascade
);
create index tutor_attempts_item on app.tutor_attempts(user_id,item_id,created_at desc);
alter table app.tutor_requests enable row level security;
alter table app.tutor_items enable row level security;
alter table app.tutor_attempts enable row level security;
revoke all on app.tutor_requests,app.tutor_items,app.tutor_attempts from public,anon,authenticated;
grant all on app.tutor_requests,app.tutor_items,app.tutor_attempts to service_role;
grant select on app.tutor_items,app.tutor_attempts to authenticated;
create policy tutor_items_own on app.tutor_items for select to authenticated
  using (user_id=(select auth.uid()) and created_at>now()-interval '30 days');
create policy tutor_attempts_own on app.tutor_attempts for select to authenticated
  using (user_id=(select auth.uid()) and created_at>now()-interval '30 days');

create function public.claim_tutor(p_user uuid,p_request uuid,p_operation text,p_hash text,
  p_count integer,p_lang text,p_item uuid)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare r app.tutor_requests; now_at timestamptz; day_at date; premium boolean;
  used integer; cap integer;
begin
  if p_user is null or p_request is null or p_operation is null
    or p_operation not in ('tutor-generate','tutor-grade')
    or p_hash is null or p_hash !~ '^[0-9a-f]{64}$' or p_count is null
    or p_count not between 1 and 5
    or (p_operation='tutor-generate' and (p_lang is null or p_lang not in ('en','pt-BR','es','it','nb') or p_item is not null))
    or (p_operation='tutor-grade' and (p_count<>1 or p_item is null or p_lang is not null))
    then raise exception 'invalid tutor claim' using errcode='22023'; end if;
  if not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null
    and not coalesce(is_anonymous,false)) then return jsonb_build_object('status','account_unverified'); end if;
  -- All tutor operations for this account share a transaction lock, including
  -- completions and refunds. Day is computed AFTER the lock (Berlin DST safe).
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905509));
  now_at:=clock_timestamp(); day_at:=(now_at at time zone 'Europe/Berlin')::date;
  update app.tutor_requests set state='expired',response=null where user_id=p_user
    and state<>'expired' and created_at<=now_at-interval '30 days';
  select * into r from app.tutor_requests where user_id=p_user and operation=p_operation and request_id=p_request;
  if found then
    if r.input_hash<>p_hash or r.units<>p_count or r.lang is distinct from p_lang or r.item_id is distinct from p_item
      then return jsonb_build_object('status','conflict'); end if;
    if r.state='ready' then return jsonb_build_object('status','hit','response',r.response); end if;
    return jsonb_build_object('status',case when r.state='pending' and r.lease_until>now_at then 'busy'
      when r.state='pending' then 'uncertain' else r.state end);
  end if;
  if p_operation='tutor-grade' then
    if not exists(select 1 from app.tutor_items where user_id=p_user and id=p_item) then
      return jsonb_build_object('status','missing'); end if;
    if not exists(select 1 from app.tutor_items where user_id=p_user and id=p_item
      and prompt_de is not null and created_at>now_at-interval '30 days') then
      return jsonb_build_object('status','item_expired'); end if;
  end if;
  -- Sandbox snapshots are written only for server-allowlisted testers, as in
  -- generated vocabulary. Complimentary grants use their actual validity dates.
  select exists(select 1 from app.verified_entitlements e where e.user_id=p_user
    and e.entitlement_id='premium' and e.environment in ('Production','Sandbox') and e.is_active
    and e.product_id in ('com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly','com.ardasayar.linglossa.premium.complimentary')
    and e.starts_at<=now_at and e.expires_at>now_at) into premium;
  cap:=case when p_operation='tutor-grade' then case when premium then 150 else 3 end
    else case when premium then 60 else 6 end end;
  select coalesce(sum(units),0)::integer into used from app.tutor_requests
    where user_id=p_user and operation=p_operation and quota_day=day_at and not released;
  if used+p_count>cap then return jsonb_build_object('status','limit','premium_required',not premium,
    'quota',jsonb_build_object('used',used,'limit',cap,'quota_day',day_at)); end if;
  insert into app.tutor_requests(user_id,request_id,operation,input_hash,units,lang,item_id,quota_day,quota_limit,quota_used)
    values(p_user,p_request,p_operation,p_hash,p_count,p_lang,p_item,day_at,cap,used+p_count) returning * into r;
  return jsonb_build_object('status','claimed','ticket',r.ticket,'quota',jsonb_build_object('used',used+p_count,'limit',cap,'quota_day',day_at));
end $$;

create function public.load_tutor_item(p_user uuid,p_item uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare item app.tutor_items; patterns jsonb;
begin
  select * into item from app.tutor_items where user_id=p_user and id=p_item;
  if not found then return jsonb_build_object('status','missing'); end if;
  if item.prompt_de is null or item.created_at<=clock_timestamp()-interval '30 days' then
    return jsonb_build_object('status','expired'); end if;
  -- At most eight recent attempts (32 errors) bound model input. All patterns
  -- come from stored server grades; the client cannot supply quotes or fixes.
  select coalesce(jsonb_agg(e.value),'[]'::jsonb) into patterns from
    (select result from app.tutor_attempts where user_id=p_user and item_id=p_item
      and result is not null and created_at>clock_timestamp()-interval '30 days'
      order by created_at desc,attempt_id limit 8) a,
    lateral jsonb_array_elements(a.result->'errors') e;
  return jsonb_build_object('status','found','item',jsonb_build_object('id',item.id,'lang',item.lang,
    'kind',item.kind,'prompt_de',item.prompt_de,'reference_answer',item.reference_answer,
    'skills',item.skills,'topic',item.topic,'errors',patterns));
end $$;

create function public.finish_tutor(p_user uuid,p_request uuid,p_operation text,p_ticket uuid,
  p_response jsonb,p_answer text,p_parents jsonb)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare r app.tutor_requests; entry jsonb; ordinal bigint; parent uuid; expires_at timestamptz;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905509));
  select * into r from app.tutor_requests where user_id=p_user and request_id=p_request
    and operation=p_operation and ticket=p_ticket for update;
  if not found or r.state<>'pending' or r.lease_until<=clock_timestamp() then
    return jsonb_build_object('status','stale'); end if;
  if p_response is null or jsonb_typeof(p_response)<>'object' or octet_length(p_response::text)>65536
    then raise exception 'invalid tutor response' using errcode='22023'; end if;
  if p_operation='tutor-generate' then
    if jsonb_typeof(p_response->'items') is distinct from 'array'
      or jsonb_typeof(p_parents) is distinct from 'array' then raise exception 'invalid tutor items'; end if;
    if jsonb_array_length(p_response->'items')<>r.units or jsonb_array_length(p_parents)<>r.units
      then raise exception 'invalid tutor count'; end if;
    for entry,ordinal in select value,ordinality from jsonb_array_elements(p_response->'items') with ordinality loop
      parent:=(p_parents->>(ordinal::integer-1))::uuid;
      if parent is not null and not exists(select 1 from app.tutor_items where user_id=p_user and id=parent
        and lang=r.lang and to_jsonb(skills)=entry->'skills' and topic<>entry->>'topic') then
        raise exception 'invalid tutor parent'; end if;
      if entry->>'prompt_de' is null or entry->>'reference_answer' is null or entry->>'topic' is null
        or jsonb_typeof(entry->'skills') is distinct from 'array' then raise exception 'invalid tutor item'; end if;
      insert into app.tutor_items(user_id,id,request_id,lang,kind,prompt_de,reference_answer,skills,topic,parent_item_id)
        values(p_user,(entry->>'id')::uuid,p_request,r.lang,entry->>'kind',entry->>'prompt_de',
          entry->>'reference_answer',array(select jsonb_array_elements_text(entry->'skills')),entry->>'topic',parent)
        returning created_at + interval '30 days' into expires_at;
      p_response:=jsonb_set(p_response,array['items',(ordinal-1)::text,'expires_at'],to_jsonb(expires_at));
    end loop;
  else
    if p_answer is null or char_length(btrim(p_answer)) not between 1 and 300
      or p_response->>'outcome' is null or p_response->>'outcome' not in ('correct','acceptable','incorrect')
      or jsonb_typeof(p_response->'scores') is distinct from 'object'
      or jsonb_typeof(p_response->'errors') is distinct from 'array'
      or p_response->'quota' is distinct from jsonb_build_object('used',r.quota_used,'limit',r.quota_limit,'quota_day',r.quota_day)
      then raise exception 'invalid tutor grade'; end if;
    insert into app.tutor_attempts(user_id,attempt_id,item_id,answer,result)
      values(p_user,p_request,r.item_id,p_answer,p_response);
  end if;
  update app.tutor_requests set state='ready',response=p_response
    where user_id=p_user and request_id=p_request and operation=p_operation;
  return jsonb_build_object('status','saved','response',p_response);
end $$;

create function public.fail_tutor(p_user uuid,p_request uuid,p_operation text,p_ticket uuid,p_release boolean)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905509));
  update app.tutor_requests set state='failed',released=p_release
    where user_id=p_user and request_id=p_request and operation=p_operation and ticket=p_ticket and state='pending';
  return jsonb_build_object('status','ok');
end $$;
revoke all on function public.claim_tutor(uuid,uuid,text,text,integer,text,uuid),
  public.load_tutor_item(uuid,uuid),public.finish_tutor(uuid,uuid,text,uuid,jsonb,text,jsonb),
  public.fail_tutor(uuid,uuid,text,uuid,boolean) from public,anon,authenticated;
grant execute on function public.claim_tutor(uuid,uuid,text,text,integer,text,uuid),
  public.load_tutor_item(uuid,uuid),public.finish_tutor(uuid,uuid,text,uuid,jsonb,text,jsonb),
  public.fail_tutor(uuid,uuid,text,uuid,boolean) to service_role;

-- Same tariff and accounting as all existing features. No policy extension.
alter table app.ai_spend_attempts drop constraint ai_spend_attempts_feature_check;
alter table app.ai_spend_attempts add constraint ai_spend_attempts_feature_check check(feature in
  ('lookup-word','translate-sentence','personal-learning','topic-check','generated-vocabulary','tutor-generate','tutor-grade'));
create or replace function public.reserve_ai_spend(p_user uuid,p_attempt uuid,p_feature text)
returns jsonb language plpgsql security definer set search_path='' set lock_timeout='2s' as $$
declare
  period date := date_trunc('month',clock_timestamp() at time zone 'UTC')::date;
  policy app.ai_spend_policy; max_out integer; reserve bigint; existing app.ai_spend_attempts;
begin
  max_out := case p_feature when 'lookup-word' then 384 when 'translate-sentence' then 384
    when 'personal-learning' then 1500 when 'topic-check' then 128 when 'generated-vocabulary' then 16000
    when 'tutor-generate' then 4096 when 'tutor-grade' then 1536 end;
  if p_user is null or p_attempt is null or max_out is null then raise exception 'Invalid AI reservation' using errcode='22023'; end if;
  select * into policy from app.ai_spend_policy where singleton;
  if not found or not policy.enabled or policy.valid_until<=clock_timestamp() then
    return jsonb_build_object('status','unavailable'); end if;
  if not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null and not coalesce(is_anonymous,false)) then
    return jsonb_build_object('status','forbidden'); end if;
  perform pg_advisory_xact_lock(hashtextextended(p_user::text,741905508));
  select * into existing from app.ai_spend_attempts where attempt_id=p_attempt;
  if found then return jsonb_build_object('status','replay'); end if;
  reserve:=1000000+max_out::bigint*5;
  insert into app.ai_spend_months(user_id,month_start) values(p_user,period) on conflict do nothing;
  update app.ai_spend_months set used_micros=used_micros+reserve where user_id=p_user and month_start=period
    and used_micros+reserve<=policy.monthly_limit_micros;
  if not found then return jsonb_build_object('status','limit'); end if;
  insert into app.ai_spend_attempts(attempt_id,user_id,month_start,feature,max_output,reserved_micros)
    values(p_attempt,p_user,period,p_feature,max_out,reserve);
  return jsonb_build_object('status','reserved');
end $$;
revoke all on function public.reserve_ai_spend(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.reserve_ai_spend(uuid,uuid,text) to service_role;

-- Reuse the already installed hourly private-AI cron, preserve its old work.
create or replace function app.purge_expired_private_ai() returns integer
language plpgsql security definer set search_path='' as $$
declare removed integer; count_now integer;
begin
  update app.generated_vocabulary_requests set state='expired',response=null
    where state='ready' and created_at<clock_timestamp()-interval '30 days';
  get diagnostics removed=row_count;
  update app.personal_learning_jobs set state='uncertain',response=null
    where state='ready' and expires_at<=clock_timestamp();
  get diagnostics count_now=row_count; removed:=removed+count_now;
  delete from app.ai_spend_months
    where month_start<(date_trunc('month',clock_timestamp() at time zone 'UTC')-interval '2 months')::date;
  update app.tutor_requests set state='expired',response=null
    where state<>'expired' and created_at<=clock_timestamp()-interval '30 days';
  get diagnostics count_now=row_count; removed:=removed+count_now;
  update app.tutor_items set prompt_de=null,reference_answer=null,skills=null,topic=null
    where prompt_de is not null and created_at<=clock_timestamp()-interval '30 days';
  get diagnostics count_now=row_count; removed:=removed+count_now;
  update app.tutor_attempts set answer=null,result=null
    where answer is not null and created_at<=clock_timestamp()-interval '30 days';
  get diagnostics count_now=row_count;
  return removed+count_now;
end $$;
revoke all on function app.purge_expired_private_ai() from public,anon,authenticated;
grant execute on function app.purge_expired_private_ai() to service_role;
