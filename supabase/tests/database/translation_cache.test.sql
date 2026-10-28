begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare
  actor uuid := '00000000-0000-4000-8000-0000000000d1';
  stranger uuid := '00000000-0000-4000-8000-0000000000d2';
  forbidden uuid := '00000000-0000-4000-8000-0000000000d3';
  key text := repeat('a',64);
  r jsonb; ticket uuid; units_before integer; snapshot jsonb;
  answer jsonb := jsonb_build_object('provider','anthropic','model','claude-haiku-5-5','contract',2,'prompt','translation-v2','usage',jsonb_build_object('input_tokens',20,'output_tokens',8),'translation_de','Synthetischer Satz.');
begin
  assert not has_table_privilege('anon','app.translation_cache','SELECT');
  assert not has_table_privilege('authenticated','app.translation_cache','SELECT');
  assert not has_table_privilege('authenticated','app.translation_cache','INSERT');
  assert (select relrowsecurity from pg_class where oid='app.translation_cache'::regclass);
  assert not exists(select 1 from pg_policy where polrelid='app.translation_cache'::regclass);
  foreach key in array array['public.claim_translation(uuid,text,text)','public.finish_translation(uuid,text,uuid,jsonb)','public.clear_translation_cache(uuid)'] loop
    assert not has_function_privilege('anon',key,'EXECUTE');
    assert not has_function_privilege('authenticated',key,'EXECUTE');
    assert has_function_privilege('service_role',key,'EXECUTE');
  end loop;
  key := repeat('a',64);
  insert into auth.users(id,email) values(actor,'cache-a@example.test'),(stranger,'cache-b@example.test'),(forbidden,'cache-c@example.test');
  insert into public.content_readers(user_id,channel,lang) values(actor,'internal','en'),(actor,'internal','pt-BR'),(stranger,'internal','en');
  insert into app.user_cards(user_id,card_id,lang,box,origin) values(actor,'synthetic-story-card','en',3,'story');
  insert into app.review_log(user_id,card_id,mode,first_attempt_correct,error_count,revealed,box_before,box_after,due_at_after)
    values(actor,'synthetic-story-card','mixed',true,0,false,2,3,now()+interval '1 day');
  select jsonb_build_array((select jsonb_agg(to_jsonb(c)) from app.user_cards c),(select jsonb_agg(to_jsonb(review_row)) from app.review_log review_row)) into snapshot;
  assert public.claim_translation(forbidden,'en',key)->>'status'='forbidden';
  assert public.claim_translation(actor,'fr',key)->>'status'='forbidden';
  r := public.claim_translation(actor,'en',key); assert r->>'status'='claimed';ticket := (r->>'ticket')::uuid;
  assert public.claim_translation(actor,'en',key)->>'status'='busy';
  assert (select units=1 from app.usage where user_id=actor and kind='runtime-translation');
  assert public.finish_translation(stranger,key,ticket,answer)->>'stored'='false';
  assert public.finish_translation(actor,key,gen_random_uuid(),answer)->>'stored'='false';
  assert public.finish_translation(actor,key,ticket,answer)->>'stored'='true';
  -- A cache hit remains available even if all generation budget is spent.
  update app.usage set units=20 where user_id=actor and kind='runtime-translation';
  assert public.claim_translation(actor,'en',key)->>'status'='hit';
  assert (select units=20 from app.usage where user_id=actor and kind='runtime-translation');
  assert public.claim_translation(actor,'en',repeat('b',64))->>'status'='limit';
  assert public.claim_translation(stranger,'en',key)->>'status'='claimed';
  assert public.clear_translation_cache(actor)->>'deleted'='true';
  assert not exists(select 1 from app.translation_cache where user_id=actor);
  assert exists(select 1 from app.translation_cache where user_id=stranger);
  -- Late completions after clear cannot resurrect private output; no budget reset.
  update app.usage set units=1 where user_id=actor and kind='runtime-translation';
  r := public.claim_translation(actor,'en',key);ticket := (r->>'ticket')::uuid;
  perform public.clear_translation_cache(actor);
  assert public.finish_translation(actor,key,ticket,answer)->>'stored'='false';
  assert public.claim_translation(actor,'en',key)->>'status'='uncertain';
  assert (select response is null from app.translation_cache where user_id=actor and request_key=key);
  -- Lease expiry is uncertainty, NOT permission to generate again.
  update app.translation_cache set state='pending',lease_until=clock_timestamp()-interval '1 second' where user_id=actor;
  assert public.claim_translation(actor,'en',key)->>'status'='uncertain';
  assert public.finish_translation(actor,key,ticket,answer)->>'stored'='false';
  -- Only after 24h and an explicit next request may a new claim spend again.
  update app.translation_cache set expires_at=clock_timestamp()-interval '1 second' where user_id=actor;
  assert public.claim_translation(actor,'en',key)->>'status'='claimed';
  assert snapshot=jsonb_build_array((select jsonb_agg(to_jsonb(c)) from app.user_cards c),(select jsonb_agg(to_jsonb(review_row)) from app.review_log review_row));
end $$;
select pass('private cache: owner isolation, generation budgets, leases, deletion and unchanged learner data');
select * from finish();
rollback;
