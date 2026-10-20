begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare
  actor uuid := '00000000-0000-4000-8000-0000000000c1';
  stranger uuid := '00000000-0000-4000-8000-0000000000c2';
  today date := (clock_timestamp() at time zone 'UTC')::date;
  result jsonb;
begin
  assert not has_function_privilege('anon','public.reserve_runtime_translation(uuid,text)','EXECUTE');
  assert not has_function_privilege('authenticated','public.reserve_runtime_translation(uuid,text)','EXECUTE');
  assert has_function_privilege('service_role','public.reserve_runtime_translation(uuid,text)','EXECUTE');
  insert into auth.users(id,email) values(actor,'translation@example.test'),(stranger,'stranger@example.test');
  insert into public.content_readers(user_id,channel,lang) values(actor,'internal','en'),(actor,'internal','pt-BR');
  assert public.reserve_runtime_translation(stranger,'en')->>'reason'='forbidden';
  assert public.reserve_runtime_translation(actor,'fr')->>'reason'='forbidden';
  for i in 1..5 loop
    result := public.reserve_runtime_translation(actor,case when i%2=0 then 'pt-BR' else 'en' end);
    assert result->>'allowed'='true';
  end loop;
  assert public.reserve_runtime_translation(actor,'en')->>'reason'='limit';
  assert (select units=5 from app.usage where user_id=actor and day=today and kind='runtime-translation');
  -- Reset minute buckets only inside this rolled-back synthetic test.
  delete from app.usage where user_id=actor and kind like 'translation-minute:%';
  update app.usage set units=20 where user_id=actor and kind='runtime-translation';
  assert public.reserve_runtime_translation(actor,'pt-BR')->>'reason'='limit';
  update app.usage set units=0 where user_id=actor and kind='runtime-translation';
  insert into app.usage(user_id,day,kind,units) values(stranger,today,'runtime-translation',1000);
  assert public.reserve_runtime_translation(actor,'en')->>'reason'='limit';
  assert (select units=0 from app.usage where user_id=actor and day=today and kind='runtime-translation');
end $$;
select pass('service-only, allowlist, shared en/pt-BR minute/day/global reservations');
select * from finish();
rollback;
