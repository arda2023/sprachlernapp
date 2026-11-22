-- Run on local Supabase: supabase test db supabase/tests/database/tutor_test.sql
-- No provider calls. All fixtures are synthetic and rolled back.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

create function pg_temp.tutor_user() returns uuid language plpgsql as $$
declare actor uuid:=gen_random_uuid();
begin
  insert into auth.users(id,email,email_confirmed_at,is_anonymous)
    values(actor,actor::text||'@example.test',clock_timestamp(),false);
  return actor;
end $$;
create function pg_temp.tutor_item(actor uuid) returns uuid language plpgsql as $$
declare item uuid:=gen_random_uuid();
begin
  insert into app.tutor_items(user_id,id,request_id,lang,kind,prompt_de,reference_answer,skills,topic)
    values(actor,item,gen_random_uuid(),'en','translate','Ich ging nach Hause.','I went home.',array['past_simple'],'alltag');
  return item;
end $$;
create function pg_temp.tutor_claim(actor uuid, req uuid default gen_random_uuid(),
  n integer default 1, item uuid default null) returns jsonb language sql as $$
  select public.claim_tutor(actor,req,case when item is null then 'tutor-generate' else 'tutor-grade' end,
    repeat('a',64),n,case when item is null then 'en' else null end,item);
$$;

do $$ begin
  assert (select relrowsecurity from pg_class where oid='app.tutor_items'::regclass);
  assert (select relrowsecurity from pg_class where oid='app.tutor_attempts'::regclass);
  assert (select relrowsecurity from pg_class where oid='app.tutor_requests'::regclass);
  assert not has_table_privilege('anon','app.tutor_items','SELECT');
  assert has_table_privilege('authenticated','app.tutor_items','SELECT');
  assert has_table_privilege('authenticated','app.tutor_attempts','SELECT');
  assert not has_table_privilege('authenticated','app.tutor_items','INSERT');
  assert not has_table_privilege('authenticated','app.tutor_attempts','UPDATE');
  assert not has_table_privilege('authenticated','app.tutor_requests','SELECT');
  assert not has_function_privilege('authenticated','public.claim_tutor(uuid,uuid,text,text,integer,text,uuid)','EXECUTE');
  assert not has_function_privilege('anon','public.load_tutor_item(uuid,uuid)','EXECUTE');
  assert not has_function_privilege('authenticated','public.finish_tutor(uuid,uuid,text,uuid,jsonb,text,jsonb)','EXECUTE');
  assert not has_function_privilege('authenticated','public.fail_tutor(uuid,uuid,text,uuid,boolean)','EXECUTE');
  assert has_function_privilege('service_role','public.claim_tutor(uuid,uuid,text,text,integer,text,uuid)','EXECUTE');
end $$;
select pass('RLS and grants: own reads, service-only writes and RPCs');

do $$ declare actor uuid:=pg_temp.tutor_user(); begin
  update auth.users set email_confirmed_at=null where id=actor;
  assert pg_temp.tutor_claim(actor)->>'status'='account_unverified';
  update auth.users set email_confirmed_at=now(),is_anonymous=true where id=actor;
  assert pg_temp.tutor_claim(actor)->>'status'='account_unverified';
  assert pg_temp.tutor_claim(gen_random_uuid())->>'status'='account_unverified';
  assert not exists(select 1 from app.tutor_requests where user_id=actor);
  begin perform pg_temp.tutor_claim(actor,gen_random_uuid(),6); assert false;
  exception when invalid_parameter_value then null; end;
end $$;
select pass('confirmed non-anonymous account and valid inputs required before reservation');

do $$ declare actor uuid:=pg_temp.tutor_user(); req uuid:=gen_random_uuid(); r jsonb; t uuid; begin
  r:=pg_temp.tutor_claim(actor,req,5); t:=(r->>'ticket')::uuid;
  assert r->>'status'='claimed';
  assert pg_temp.tutor_claim(actor,req,5)->>'status'='busy';
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),2)->>'status'='limit';
  perform public.fail_tutor(actor,req,'tutor-generate',t,true);
  assert pg_temp.tutor_claim(actor,req,5)->>'status'='failed';
  assert (select released from app.tutor_requests where user_id=actor and request_id=req);
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),5)->>'status'='claimed';
  assert pg_temp.tutor_claim(actor)->>'status'='claimed';
  r:=pg_temp.tutor_claim(actor); assert r->>'status'='limit';
  assert r->>'premium_required'='true'; assert r->'quota'='{"used":6,"limit":6}'::jsonb;
end $$;
select pass('Free generation cap 6, batch all-or-none, idempotency and pre-provider release');

do $$ declare actor uuid:=pg_temp.tutor_user(); req uuid:=gen_random_uuid(); item uuid:=gen_random_uuid(); r jsonb; t uuid; payload jsonb; begin
  r:=pg_temp.tutor_claim(actor,req); t:=(r->>'ticket')::uuid;
  payload:=jsonb_build_object('items',jsonb_build_array(jsonb_build_object('id',item,'kind','translate',
    'prompt_de','Ich ging nach Hause.','reference_answer','I went home.','skills',jsonb_build_array('past_simple'),'topic','alltag')));
  assert public.finish_tutor(actor,req,'tutor-generate',gen_random_uuid(),payload,null,'[null]')->>'status'='stale';
  assert public.finish_tutor(pg_temp.tutor_user(),req,'tutor-generate',t,payload,null,'[null]')->>'status'='stale';
  assert public.finish_tutor(actor,req,'tutor-generate',t,payload,null,'[null]')->>'status'='saved';
  assert pg_temp.tutor_claim(actor,req)->'response'=payload;
  assert pg_temp.tutor_claim(actor,req)->>'status'='hit';
  assert public.claim_tutor(actor,req,'tutor-generate',repeat('b',64),1,'en',null)->>'status'='conflict';
  perform public.fail_tutor(actor,req,'tutor-generate',t,true);
  assert not (select released from app.tutor_requests where user_id=actor and request_id=req);
  assert public.load_tutor_item(actor,item)->>'status'='found';
  assert public.load_tutor_item(pg_temp.tutor_user(),item)->>'status'='missing';
end $$;
select pass('atomic item persistence, stored replay, hash conflict, ownership and ticket CAS');

do $$ declare actor uuid:=pg_temp.tutor_user(); item uuid:=pg_temp.tutor_item(actor); req uuid:=gen_random_uuid(); r jsonb; t uuid; payload jsonb; begin
  r:=pg_temp.tutor_claim(actor,req,1,item); t:=(r->>'ticket')::uuid;
  payload:=jsonb_build_object('scores',jsonb_build_object('meaning',2,'grammar',2,'naturalness',2),
    'outcome','correct','errors','[]'::jsonb,'feedback_de','Die Aussage stimmt.','ideal_answer','I went home.','quota',r->'quota');
  assert public.finish_tutor(actor,req,'tutor-grade',t,payload,'I went home.',null)->>'status'='saved';
  assert pg_temp.tutor_claim(actor,req,1,item)->'response'=payload;
  assert (select answer='I went home.' from app.tutor_attempts where user_id=actor and attempt_id=req);
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),1,item)->>'status'='claimed';
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),1,item)->>'status'='claimed';
  r:=pg_temp.tutor_claim(actor,gen_random_uuid(),1,item);
  assert r->>'status'='limit'; assert r->'quota'='{"used":3,"limit":3}'::jsonb;
  assert pg_temp.tutor_claim(pg_temp.tutor_user(),gen_random_uuid(),1,item)->>'status'='missing';
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),1,gen_random_uuid())->>'status'='missing';
end $$;
select pass('Free grading cap 3, exact stored result, owner-only task and attempt storage');

do $$ declare actor uuid; item uuid; env text; product text; r jsonb; begin
  for env,product in values ('Production','monthly'),('Sandbox','yearly'),('Production','complimentary') loop
    actor:=pg_temp.tutor_user(); item:=pg_temp.tutor_item(actor);
    insert into app.verified_entitlements(user_id,entitlement_id,environment,is_active,product_id,starts_at,expires_at,observed_at)
      values(actor,'premium',env,true,'com.ardasayar.linglossa.premium.'||product,now()-interval '1 day',now()+interval '1 day',now());
    for i in 1..12 loop assert pg_temp.tutor_claim(actor,gen_random_uuid(),5)->>'status'='claimed'; end loop;
    r:=pg_temp.tutor_claim(actor); assert r->>'status'='limit'; assert r->>'premium_required'='false';
    assert r->'quota'='{"used":60,"limit":60}'::jsonb;
    for i in 1..150 loop assert pg_temp.tutor_claim(actor,gen_random_uuid(),1,item)->>'status'='claimed'; end loop;
    r:=pg_temp.tutor_claim(actor,gen_random_uuid(),1,item);
    assert r->>'status'='limit'; assert r->'quota'='{"used":150,"limit":150}'::jsonb;
  end loop;
end $$;
select pass('Premium 60/150 for Production, allowlisted Sandbox and Complimentary snapshots');

do $$ declare actor uuid:=pg_temp.tutor_user(); r jsonb; begin
  insert into app.verified_entitlements(user_id,entitlement_id,environment,is_active,product_id,starts_at,expires_at,observed_at)
    values(actor,'premium','Production',true,'com.ardasayar.linglossa.premium.monthly',now()-interval '2 days',now()-interval '1 day',now());
  r:=pg_temp.tutor_claim(actor); assert r->'quota'->>'limit'='6';
  update app.verified_entitlements set starts_at=now()+interval '1 day',expires_at=now()+interval '2 days' where user_id=actor;
  r:=pg_temp.tutor_claim(actor); assert r->'quota'->>'limit'='6';
end $$;
select pass('expired and future Premium do not grant paid quota');

do $$ declare actor uuid:=pg_temp.tutor_user(); req uuid:=gen_random_uuid(); r jsonb; t uuid; begin
  assert ('2026-03-28 23:30Z'::timestamptz at time zone 'Europe/Berlin')::date='2026-03-29'::date;
  assert ('2026-10-25 22:30Z'::timestamptz at time zone 'Europe/Berlin')::date='2026-10-25'::date;
  assert ('2026-10-25 23:30Z'::timestamptz at time zone 'Europe/Berlin')::date='2026-10-26'::date;
  r:=pg_temp.tutor_claim(actor,req,5); t:=(r->>'ticket')::uuid;
  assert (select quota_day=(clock_timestamp() at time zone 'Europe/Berlin')::date from app.tutor_requests where user_id=actor and request_id=req);
  update app.tutor_requests set quota_day=quota_day-1,lease_until=now()-interval '1 minute' where user_id=actor;
  assert pg_temp.tutor_claim(actor,req,5)->>'status'='uncertain';
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),5)->>'status'='claimed';
  perform public.fail_tutor(actor,req,'tutor-generate',t,true);
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),2)->>'status'='limit';
end $$;
select pass('Berlin calendar/DST, no expired-lease replay and late refunds stay on original day');

do $$ declare actor uuid:=pg_temp.tutor_user(); item uuid:=pg_temp.tutor_item(actor); req uuid:=gen_random_uuid(); begin
  perform pg_temp.tutor_claim(actor,req);
  insert into app.tutor_attempts(user_id,attempt_id,item_id,answer,result,created_at)
    values(actor,gen_random_uuid(),item,'private answer','{"errors":[]}',now()-interval '31 days');
  update app.tutor_items set created_at=now()-interval '31 days' where user_id=actor;
  update app.tutor_requests set created_at=now()-interval '31 days' where user_id=actor;
  assert public.load_tutor_item(actor,item)->>'status'='expired';
  assert pg_temp.tutor_claim(actor,gen_random_uuid(),1,item)->>'status'='item_expired';
  perform app.purge_expired_private_ai();
  assert (select prompt_de is null and reference_answer is null and skills is null and topic is null from app.tutor_items where user_id=actor);
  assert (select answer is null and result is null from app.tutor_attempts where user_id=actor);
  assert (select response is null and state='expired' from app.tutor_requests where user_id=actor);
  assert pg_temp.tutor_claim(actor,req)->>'status'='expired';
end $$;
select pass('30-day retention clears private content and preserves no-replay tombstones');

do $$ declare actor uuid:=pg_temp.tutor_user(); attempt uuid:=gen_random_uuid(); begin
  update app.ai_spend_policy set enabled=true,valid_until=now()+interval '1 day';
  assert public.reserve_ai_spend(actor,attempt,'tutor-generate')->>'status'='reserved';
  assert (select reserved_micros=1020480 and max_output=4096 from app.ai_spend_attempts where attempt_id=attempt);
  assert public.settle_ai_spend(actor,attempt,100,100)->>'status'='settled';
  assert (select used_micros=120 from app.ai_spend_months where user_id=actor);
  attempt:=gen_random_uuid();
  assert public.reserve_ai_spend(actor,attempt,'tutor-grade')->>'status'='reserved';
  assert (select reserved_micros=1007680 and max_output=1536 from app.ai_spend_attempts where attempt_id=attempt);
  assert public.reserve_ai_spend(actor,attempt,'tutor-grade')->>'status'='replay';
  for i in 1..3 loop assert public.reserve_ai_spend(actor,gen_random_uuid(),'lookup-word')->>'status'='reserved'; end loop;
  assert public.reserve_ai_spend(actor,gen_random_uuid(),'tutor-generate')->>'status'='limit';
end $$;
select pass('new budget features share cap, tariffs, token maxima and exactly-once settlement');

do $$ declare actor uuid:=pg_temp.tutor_user(); item uuid:=pg_temp.tutor_item(actor); begin
  perform pg_temp.tutor_claim(actor);
  insert into app.tutor_attempts(user_id,attempt_id,item_id,answer,result) values(actor,gen_random_uuid(),item,'answer','{}');
  -- Include a self-referencing regenerated child to exercise cascade ordering.
  insert into app.tutor_items(user_id,id,request_id,lang,kind,parent_item_id)
    values(actor,gen_random_uuid(),gen_random_uuid(),'en','translate',item);
  delete from auth.users where id=actor;
  assert not exists(select 1 from app.tutor_requests where user_id=actor);
  assert not exists(select 1 from app.tutor_items where user_id=actor);
  assert not exists(select 1 from app.tutor_attempts where user_id=actor);
end $$;
select pass('account deletion cascades all tutor rows, including regenerated children');

-- Real role switch: permissions alone do not prove RLS isolation.
do $$ declare actor uuid:='aabbccdd-1234-4234-8234-123456789abc'; item uuid; begin
  insert into auth.users(id,email,email_confirmed_at) values(actor,'tutor-rls@example.test',now());
  item:=pg_temp.tutor_item(actor);
  insert into app.tutor_attempts(user_id,attempt_id,item_id,answer,result) values(actor,gen_random_uuid(),item,'answer','{}');
  perform pg_temp.tutor_item(pg_temp.tutor_user());
end $$;
select set_config('request.jwt.claim.sub','aabbccdd-1234-4234-8234-123456789abc',true);
set local role authenticated;
do $$ begin
  assert (select count(*)=1 from app.tutor_items);
  assert (select count(*)=1 from app.tutor_attempts);
  assert (select bool_and(user_id=auth.uid()) from app.tutor_items);
end $$;
reset role;
select pass('authenticated table reads expose only own unexpired rows');

do $$ declare actor uuid:=pg_temp.tutor_user(); item uuid:=pg_temp.tutor_item(actor); errors jsonb; r jsonb; begin
  errors:='[{"skill":"past_simple","severity":"major","quote":"goed","fix":"went"}]';
  insert into app.tutor_attempts(user_id,attempt_id,item_id,answer,result)
    values(actor,gen_random_uuid(),item,'I goed home.',jsonb_build_object('errors',errors));
  r:=public.load_tutor_item(actor,item);
  assert r->'item'->'errors'=errors;
  assert public.load_tutor_item(pg_temp.tutor_user(),item)->>'status'='missing';
end $$;
select pass('regeneration context uses persisted owner-bound error patterns');

select * from finish();
rollback;
