begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare actor uuid:='2b100000-0000-4000-8000-000000000001';
 k text:=repeat('f',64); r jsonb; old_ticket uuid; new_ticket uuid;
begin
 insert into auth.users(id,email) values(actor,'retry@example.test');
 insert into public.content_readers(user_id,channel,lang) values(actor,'internal','en');
 assert not has_function_privilege('authenticated','public.claim_personal_learning(uuid,text,text,uuid)','EXECUTE');
 assert not has_function_privilege('anon','public.fail_personal_learning(uuid,text,uuid)','EXECUTE');
 r:=public.claim_personal_learning(actor,'en',k);old_ticket:=(r->>'ticket')::uuid;
 assert public.claim_personal_learning(actor,'en',k,old_ticket)->>'status'='busy';
 assert public.fail_personal_learning(actor,k,old_ticket)->>'failed'='true';
 r:=public.claim_personal_learning(actor,'en',k);assert r->>'status'='uncertain';
 assert (r->>'retry_ticket')::uuid=old_ticket;
 assert (select units=1 from app.usage where user_id=actor and kind='runtime-translation');
 r:=public.claim_personal_learning(actor,'en',k,old_ticket);assert r->>'status'='claimed';new_ticket:=(r->>'ticket')::uuid;
 assert new_ticket<>old_ticket;
 assert public.claim_personal_learning(actor,'en',k,old_ticket)->>'status'='busy';
 assert public.finish_personal_learning(actor,k,old_ticket,'{"old":true}')->>'stored'='false';
 assert public.fail_personal_learning(actor,k,old_ticket)->>'failed'='false';
 assert public.finish_personal_learning(actor,k,new_ticket,'{"new":true}')->>'stored'='true';
 assert public.claim_personal_learning(actor,'en',k,old_ticket)->'response'='{"new":true}'::jsonb;
 assert (select units=2 from app.usage where user_id=actor and kind='runtime-translation');
 -- Expired ready payload is removed, but its attempt fence survives; no implicit model reservation.
 update app.personal_learning_jobs set expires_at=clock_timestamp()-interval '1 second' where user_id=actor and request_key=k;
 assert public.claim_personal_learning(actor,'en',k)->>'status'='uncertain';
 assert (select response is null and ticket=new_ticket from app.personal_learning_jobs where user_id=actor and request_key=k);
 assert (select units=2 from app.usage where user_id=actor and kind='runtime-translation');
 -- Legacy uncertain/pending rows retry after lease, without waiting for retention expiry.
 k:=repeat('a',64);r:=public.claim_personal_learning(actor,'en',k);old_ticket:=(r->>'ticket')::uuid;
 update app.personal_learning_jobs set lease_until=clock_timestamp()-interval '1 second' where user_id=actor and request_key=k;
 r:=public.claim_personal_learning(actor,'en',k);assert (r->>'retry_ticket')::uuid=old_ticket;
 r:=public.claim_personal_learning(actor,'en',k,old_ticket);assert r->>'status'='claimed';new_ticket:=(r->>'ticket')::uuid;
 assert public.finish_personal_learning(actor,k,old_ticket,'{}')->>'stored'='false';
 perform public.fail_personal_learning(actor,k,new_ticket);
 update app.usage set units=20 where user_id=actor and kind='runtime-translation';
 assert public.claim_personal_learning(actor,'en',k,new_ticket)->>'status'='limit';
 assert (select ticket=new_ticket from app.personal_learning_jobs where user_id=actor and request_key=k);
 assert not exists(select 1 from app.user_cards where user_id=actor);
 assert not exists(select 1 from app.review_log where user_id=actor);
end $$;
select pass('explicit retry, same generation, stale-worker fencing, lease recovery and quota');
select * from finish();
rollback;
