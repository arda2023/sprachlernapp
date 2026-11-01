-- Private topic generation: one provider attempt per user/request UUID.
-- Failed and abandoned attempts still reserve quota: the provider may have billed.
create table app.generated_vocabulary_requests (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  lang text not null check (lang in ('en','es','it','nb','pt-BR')),
  input_hash text not null check (input_hash ~ '^[0-9a-f]{64}$'),
  item_count integer not null check (item_count between 1 and 50),
  state text not null default 'pending' check (state in ('pending','ready','failed','expired')),
  ticket uuid not null default gen_random_uuid(),
  response jsonb,
  created_at timestamptz not null default clock_timestamp(),
  lease_until timestamptz not null default (clock_timestamp()+interval '3 minutes'),
  primary key (user_id,request_id),
  check ((state='ready') = (response is not null)),
  check (response is null or octet_length(response::text)<=262144)
);
create index generated_vocabulary_created on app.generated_vocabulary_requests(created_at);
alter table app.generated_vocabulary_requests enable row level security;
revoke all on app.generated_vocabulary_requests from public,anon,authenticated;
grant all on app.generated_vocabulary_requests to service_role;

create function public.claim_generated_vocabulary(
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

create function public.finish_generated_vocabulary(p_user uuid,p_request uuid,p_ticket uuid,p_response jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare changed integer;
begin
  if p_response is null or jsonb_typeof(p_response)<>'object'
    or octet_length(p_response::text)>262144 then raise exception 'invalid response'; end if;
  update app.generated_vocabulary_requests set state='ready',response=p_response
    where user_id=p_user and request_id=p_request and ticket=p_ticket and state='pending'
    and lease_until>clock_timestamp()
    and lower(p_response->>'request_id')=request_id::text and p_response->>'lang'=lang
    and p_response->>'contract'='1' and jsonb_typeof(p_response->'items')='array'
    and jsonb_array_length(p_response->'items') between 1 and item_count;
  get diagnostics changed=row_count;
  return jsonb_build_object('status',case when changed=1 then 'saved' else 'stale' end);
end $$;

create function public.fail_generated_vocabulary(p_user uuid,p_request uuid,p_ticket uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  update app.generated_vocabulary_requests set state='failed'
    where user_id=p_user and request_id=p_request and ticket=p_ticket and state='pending';
  return jsonb_build_object('status','ok');
end $$;
revoke all on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) from public,anon,authenticated;
revoke all on function public.finish_generated_vocabulary(uuid,uuid,uuid,jsonb) from public,anon,authenticated;
revoke all on function public.fail_generated_vocabulary(uuid,uuid,uuid) from public,anon,authenticated;
grant execute on function public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean) to service_role;
grant execute on function public.finish_generated_vocabulary(uuid,uuid,uuid,jsonb) to service_role;
grant execute on function public.fail_generated_vocabulary(uuid,uuid,uuid) to service_role;
