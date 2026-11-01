begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

do $$
begin
  assert (select relrowsecurity from pg_class where oid='app.generated_vocabulary_requests'::regclass);
  assert not has_table_privilege('anon','app.generated_vocabulary_requests','SELECT');
  assert not has_table_privilege('authenticated','app.generated_vocabulary_requests','SELECT');
  assert not has_table_privilege('authenticated','app.generated_vocabulary_requests','INSERT');
  assert has_table_privilege('service_role','app.generated_vocabulary_requests','SELECT');
  assert not has_function_privilege('anon','public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean)','EXECUTE');
  assert not has_function_privilege('authenticated','public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean)','EXECUTE');
  assert not has_function_privilege('authenticated','public.finish_generated_vocabulary(uuid,uuid,uuid,jsonb)','EXECUTE');
  assert not has_function_privilege('anon','public.fail_generated_vocabulary(uuid,uuid,uuid)','EXECUTE');
  assert has_function_privilege('service_role','public.claim_generated_vocabulary(uuid,uuid,text,text,integer,boolean)','EXECUTE');
  assert has_function_privilege('service_role','public.finish_generated_vocabulary(uuid,uuid,uuid,jsonb)','EXECUTE');
  assert has_function_privilege('service_role','public.fail_generated_vocabulary(uuid,uuid,uuid)','EXECUTE');
end $$;
select pass('generation table and RPCs are private to service_role');

do $$
declare
  actor uuid:='4a100000-0000-4000-8000-000000000001';
  anonymous_actor uuid:='4a100000-0000-4000-8000-000000000002';
  req uuid:='4a100000-0000-4000-8000-000000000003';
  k text:=repeat('a',64);
begin
  insert into auth.users(id,email) values(actor,'generation-unverified@example.test');
  insert into auth.users(id,email,email_confirmed_at,is_anonymous)
    values(anonymous_actor,'generation-anonymous@example.test',clock_timestamp(),true);
  assert public.claim_generated_vocabulary(actor,req,'en',k,10)->>'status'='account_unverified';
  assert public.claim_generated_vocabulary(anonymous_actor,req,'en',k,10)->>'status'='account_unverified';
  assert public.claim_generated_vocabulary('4a100000-0000-4000-8000-000000000099',req,'en',k,10)->>'status'='account_unverified';
  assert not exists(select 1 from app.generated_vocabulary_requests where user_id in(actor,anonymous_actor));
  update auth.users set email_confirmed_at=clock_timestamp() where id=actor;
  assert public.claim_generated_vocabulary(actor,req,'en',k,10,true)->>'status'='missing';
  assert not exists(select 1 from app.generated_vocabulary_requests where user_id=actor);
  assert public.claim_generated_vocabulary(actor,req,'en',k,10)->>'status'='claimed';
end $$;
select pass('only confirmed non-anonymous users can claim; status-only misses reserve nothing');

do $$
declare
  actor uuid:='4a200000-0000-4000-8000-000000000001';
  other_actor uuid:='4a200000-0000-4000-8000-000000000002';
  req uuid:='4a200000-0000-4000-8000-000000000003';
  other_req uuid:='4a200000-0000-4000-8000-000000000004';
  k text:=repeat('b',64); r jsonb; ticket uuid; other_ticket uuid; payload jsonb;
begin
  insert into auth.users(id,email,email_confirmed_at) values
    (actor,'generation-cas@example.test',clock_timestamp()),
    (other_actor,'generation-other@example.test',clock_timestamp());
  r:=public.claim_generated_vocabulary(actor,req,'es',k,5);
  assert r->>'status'='claimed'; ticket:=(r->>'ticket')::uuid;
  assert public.claim_generated_vocabulary(actor,req,'es',k,5)->>'status'='busy';
  assert public.claim_generated_vocabulary(actor,req,'es',k,5,true)->>'status'='busy';
  assert public.claim_generated_vocabulary(actor,other_req,'es',k,5)->>'status'='busy';
  assert (select count(*)=1 from app.generated_vocabulary_requests where user_id=actor);
  assert public.claim_generated_vocabulary(actor,req,'en',k,5)->>'status'='conflict';
  assert public.claim_generated_vocabulary(actor,req,'es',repeat('c',64),5)->>'status'='conflict';
  assert public.claim_generated_vocabulary(actor,req,'es',k,4)->>'status'='conflict';
  payload:=jsonb_build_object('contract',1,'request_id',req,'lang','es','items',jsonb_build_array(jsonb_build_object('form','billete')));
  -- Even the correct ticket cannot cross an account or request boundary.
  assert public.finish_generated_vocabulary(other_actor,req,ticket,payload)->>'status'='stale';
  assert public.finish_generated_vocabulary(actor,other_req,ticket,payload)->>'status'='stale';
  assert public.finish_generated_vocabulary(actor,req,gen_random_uuid(),payload)->>'status'='stale';
  -- Non-array items may fail the predicate or raise during jsonb_array_length;
  -- both outcomes must leave the pending reservation untouched.
  begin
    assert public.finish_generated_vocabulary(actor,req,ticket,
      jsonb_set(payload,'{items}','{}'::jsonb))->>'status'='stale';
  exception when invalid_parameter_value then
    null;
  end;
  assert (select state='pending' and response is null from app.generated_vocabulary_requests where user_id=actor and request_id=req);
  perform public.fail_generated_vocabulary(actor,req,gen_random_uuid());
  assert (select state='pending' from app.generated_vocabulary_requests where user_id=actor and request_id=req);
  assert public.finish_generated_vocabulary(actor,req,ticket,payload)->>'status'='saved';
  assert public.finish_generated_vocabulary(actor,req,ticket,payload)->>'status'='stale';
  perform public.fail_generated_vocabulary(actor,req,ticket);
  r:=public.claim_generated_vocabulary(actor,req,'es',k,5,true);
  assert r->>'status'='hit' and r->'response'=payload;
  assert public.claim_generated_vocabulary(other_actor,req,'es',k,5,true)->>'status'='missing';
  r:=public.claim_generated_vocabulary(other_actor,req,'es',k,5);
  assert r->>'status'='claimed'; other_ticket:=(r->>'ticket')::uuid;
  assert other_ticket<>ticket;
  assert public.finish_generated_vocabulary(other_actor,req,ticket,payload)->>'status'='stale';
  assert public.finish_generated_vocabulary(other_actor,req,other_ticket,payload)->>'status'='saved';
end $$;
select pass('deduplication, input conflicts, partial response hit, ticket CAS and cross-account isolation');

do $$
declare
  actor uuid:='4a300000-0000-4000-8000-000000000001';
  req uuid:='4a300000-0000-4000-8000-000000000002';
  next_req uuid:='4a300000-0000-4000-8000-000000000003';
  k text:=repeat('d',64); r jsonb; ticket uuid; failed_ticket uuid; payload jsonb;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'generation-failure@example.test',clock_timestamp());
  r:=public.claim_generated_vocabulary(actor,req,'nb',k,50); ticket:=(r->>'ticket')::uuid;
  perform public.fail_generated_vocabulary(actor,req,ticket);
  failed_ticket:=ticket;
  assert public.claim_generated_vocabulary(actor,req,'nb',k,50)->>'status'='failed';
  assert public.claim_generated_vocabulary(actor,req,'nb',k,50,true)->>'status'='failed';
  assert (select g.ticket=failed_ticket and g.state='failed' from app.generated_vocabulary_requests g where g.user_id=actor and g.request_id=req);
  r:=public.claim_generated_vocabulary(actor,next_req,'nb',k,50); ticket:=(r->>'ticket')::uuid;
  update app.generated_vocabulary_requests set lease_until=clock_timestamp()-interval '1 second'
    where user_id=actor and request_id=next_req;
  assert public.claim_generated_vocabulary(actor,next_req,'nb',k,50)->>'status'='uncertain';
  payload:=jsonb_build_object('contract',1,'request_id',next_req,'lang','nb','items','[{}]'::jsonb);
  assert public.finish_generated_vocabulary(actor,next_req,ticket,payload)->>'status'='stale';
  assert (select count(*)=2 and sum(item_count)=100 from app.generated_vocabulary_requests where user_id=actor);
end $$;
select pass('failed and abandoned attempts retain their reservation and never retry implicitly');

do $$
declare
  actor uuid:='4a400000-0000-4000-8000-000000000001';
  k text:=repeat('e',64); req uuid; ticket uuid; r jsonb;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'generation-quota@example.test',clock_timestamp());
  for i in 1..5 loop
    req:=gen_random_uuid();
    r:=public.claim_generated_vocabulary(actor,req,'it',k,50);
    assert r->>'status'='claimed'; ticket:=(r->>'ticket')::uuid;
    perform public.fail_generated_vocabulary(actor,req,ticket);
  end loop;
  assert (select count(*)=5 and sum(item_count)=250 from app.generated_vocabulary_requests where user_id=actor);
  assert public.claim_generated_vocabulary(actor,gen_random_uuid(),'it',k,1)->>'status'='limit';
  assert (select count(*)=5 from app.generated_vocabulary_requests where user_id=actor);
  -- The rolling window frees both reservations after 24 hours.
  update app.generated_vocabulary_requests set created_at=clock_timestamp()-interval '25 hours' where user_id=actor;
  assert public.claim_generated_vocabulary(actor,gen_random_uuid(),'it',k,50)->>'status'='claimed';
end $$;
select pass('five daily requests and 250 requested items include failures and reset after 24 hours');

do $$
declare
  actor uuid:='4a500000-0000-4000-8000-000000000001';
  req uuid:='4a500000-0000-4000-8000-000000000002';
  k text:=repeat('f',64); r jsonb; ticket uuid; payload jsonb;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'generation-retention@example.test',clock_timestamp());
  r:=public.claim_generated_vocabulary(actor,req,'pt-BR',k,1); ticket:=(r->>'ticket')::uuid;
  payload:=jsonb_build_object('contract',1,'request_id',req,'lang','pt-BR','items','[{}]'::jsonb);
  assert public.finish_generated_vocabulary(actor,req,ticket,payload)->>'status'='saved';
  update app.generated_vocabulary_requests set created_at=clock_timestamp()-interval '31 days'
    where user_id=actor and request_id=req;
  assert public.claim_generated_vocabulary(actor,req,'pt-BR',k,1,true)->>'status'='expired';
  assert (select state='expired' and response is null from app.generated_vocabulary_requests where user_id=actor and request_id=req);
  assert public.claim_generated_vocabulary(actor,req,'pt-BR',k,1)->>'status'='expired';
  assert (select count(*)=1 from app.generated_vocabulary_requests where user_id=actor);
  delete from auth.users where id=actor;
  assert not exists(select 1 from app.generated_vocabulary_requests where user_id=actor);
end $$;
select pass('30-day payload expiry retains a replay tombstone until account deletion');

do $$
declare
  actor uuid:='4a600000-0000-4000-8000-000000000001';
  seed_actor uuid:='4a600000-0000-4000-8000-000000000002';
  k text:=repeat('a',64); remaining integer; seed_request uuid;
begin
  insert into auth.users(id,email,email_confirmed_at) values
    (actor,'generation-global@example.test',clock_timestamp()),
    (seed_actor,'generation-global-seed@example.test',clock_timestamp());
  select 20000-coalesce(sum(item_count),0)::integer into remaining
    from app.generated_vocabulary_requests where created_at>clock_timestamp()-interval '24 hours';
  assert remaining>0;
  -- Only service_role can seed the private ledger; failed attempts consume the
  -- same global budget as completed requests.
  set local role service_role;
  insert into app.generated_vocabulary_requests(user_id,request_id,lang,input_hash,item_count,state)
    select seed_actor,gen_random_uuid(),'en',k,least(50,remaining-(n-1)*50),'failed'
    from generate_series(1,(remaining+49)/50) n;
  reset role;
  assert (select sum(item_count)=20000 from app.generated_vocabulary_requests
    where created_at>clock_timestamp()-interval '24 hours');
  assert public.claim_generated_vocabulary(actor,gen_random_uuid(),'en',k,1)->>'status'='limit';
  assert not exists(select 1 from app.generated_vocabulary_requests where user_id=actor);
  -- Free exactly one unit to verify the inclusive boundary, without moving
  -- reservations outside the rolling window.
  select request_id into seed_request from app.generated_vocabulary_requests
    where user_id=seed_actor and item_count>1 limit 1;
  update app.generated_vocabulary_requests set item_count=item_count-1
    where user_id=seed_actor and request_id=seed_request;
  assert public.claim_generated_vocabulary(actor,gen_random_uuid(),'en',k,1)->>'status'='claimed';
  assert (select sum(item_count)=20000 from app.generated_vocabulary_requests
    where created_at>clock_timestamp()-interval '24 hours');
end $$;
select pass('global 20000-item rolling cap is inclusive and cannot reserve excess units');

select * from finish();
rollback;
