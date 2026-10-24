begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare actor uuid:='2a100000-0000-4000-8000-000000000001'; other uuid:='2a100000-0000-4000-8000-000000000002';
 r jsonb; ticket uuid; key text:=repeat('c',64);
begin
 assert (select relrowsecurity from pg_class where oid='app.personal_learning_jobs'::regclass);
 assert not has_table_privilege('authenticated','app.personal_learning_jobs','SELECT');
 assert not has_function_privilege('authenticated','public.claim_personal_learning(uuid,text,text)','EXECUTE');
 assert not has_function_privilege('anon','public.personal_learning_release(uuid,text,uuid,text)','EXECUTE');
 insert into auth.users(id,email) values(actor,'personal@example.test'),(other,'other@example.test');
 insert into public.content_readers(user_id,channel,lang) values(actor,'internal','en');
 insert into public.content_release_uploads(id,request_id,owner_id,lang,channel,expected_generation,draft_manifest,objects)
 select id,id,actor,'en','internal',0,'{}','{}' from unnest(array['2a100000-0000-4000-8000-000000000003'::uuid,'2a100000-0000-4000-8000-000000000004'::uuid]) id;
 insert into public.content_release_catalog(release_id,lang,channel,generation,manifest,manifest_sha256,objects,published_by) values
 ('2a100000-0000-4000-8000-000000000003','en','internal',1,'{}',repeat('a',64),'{}',actor),
 ('2a100000-0000-4000-8000-000000000004','en','internal',2,'{}',repeat('b',64),'{}',actor);
 insert into public.content_channels values('en','internal',2,'2a100000-0000-4000-8000-000000000004',repeat('b',64));
 -- Older active release remains valid after channel advancement; exact hash required.
 assert public.personal_learning_release(actor,'en','2a100000-0000-4000-8000-000000000003',repeat('a',64))->>'status'='ok';
 assert public.personal_learning_release(actor,'en','2a100000-0000-4000-8000-000000000003',repeat('b',64))->>'status'='invalid';
 assert public.personal_learning_release(actor,'pt-BR','2a100000-0000-4000-8000-000000000003',repeat('a',64))->>'status'='forbidden';
 assert public.personal_learning_release(other,'en','2a100000-0000-4000-8000-000000000003',repeat('a',64))->>'status'='forbidden';
 assert public.claim_personal_learning(other,'en',key)->>'status'='forbidden';
 r:=public.claim_personal_learning(actor,'en',key);assert r->>'status'='claimed';ticket:=(r->>'ticket')::uuid;
 assert public.claim_personal_learning(actor,'en',key)->>'status'='busy';
 assert (select units=1 from app.usage where user_id=actor and kind='runtime-translation');
 assert public.finish_personal_learning(other,key,ticket,'{"fixture":true}')->>'stored'='false';
 assert public.finish_personal_learning(actor,key,ticket,'{"fixture":true}')->>'stored'='true';
 update app.usage set units=20 where user_id=actor and kind='runtime-translation';
 assert public.claim_personal_learning(actor,'en',key)->>'status'='hit';
 assert public.claim_personal_learning(actor,'en',repeat('d',64))->>'status'='limit';
 perform public.clear_translation_cache(actor);
 assert public.claim_personal_learning(actor,'en',key)->>'status'='hit';
 assert not exists(select 1 from app.translation_cache where user_id=actor);
 assert not exists(select 1 from app.user_cards where user_id=actor);
 assert not exists(select 1 from app.review_log where user_id=actor);
 update app.usage set units=1 where user_id=actor and kind='runtime-translation';
 r:=public.claim_personal_learning(actor,'en',repeat('e',64));ticket:=(r->>'ticket')::uuid;
 update app.personal_learning_jobs set lease_until=now()-interval '1 second' where request_key=repeat('e',64);
 assert public.claim_personal_learning(actor,'en',repeat('e',64))->>'status'='uncertain';
 assert public.finish_personal_learning(actor,repeat('e',64),ticket,'{}')->>'stored'='false';
end $$;
select pass('personal learning: private rights, real reference validation, shared budget, independent cache, no learning mutation');
select * from finish();
rollback;
