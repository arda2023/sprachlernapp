begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
do $$
declare
  free_user uuid := '00000000-0000-4000-8000-0000000000a1';
  premium_user uuid := '00000000-0000-4000-8000-0000000000a2';
  sandbox_user uuid := '00000000-0000-4000-8000-0000000000a3';
  unverified_user uuid := '00000000-0000-4000-8000-0000000000a4';
  pending_user uuid := '00000000-0000-4000-8000-0000000000a5';
  r jsonb; current_ticket uuid; i integer; key text; answer jsonb := jsonb_build_object(
    'provider','anthropic','model','claude-haiku-5-5','contract',2,
    'prompt','translation-v2','usage',jsonb_build_object('input_tokens',20,'output_tokens',8),
    'translation_de','Synthetische Übersetzung.'
  );
  premium_anchor timestamptz := date_trunc('month',clock_timestamp()) - interval '1 day';
  expected_start timestamptz;
  expected_end timestamptz;
  race_start timestamptz;
  race_end timestamptz;
begin
  assert not has_table_privilege('anon','app.translation_budget_reservations','SELECT');
  assert not has_table_privilege('authenticated','app.translation_budget_reservations','SELECT');
  assert not has_function_privilege('anon','public.claim_translation(uuid,text,text)','EXECUTE');
  assert not has_function_privilege('authenticated','public.claim_translation(uuid,text,text)','EXECUTE');
  assert not has_function_privilege('authenticated','public.release_translation(uuid,text,uuid)','EXECUTE');
  assert has_function_privilege('service_role','public.claim_translation(uuid,text,text)','EXECUTE');
  assert has_function_privilege('service_role','public.release_translation(uuid,text,uuid)','EXECUTE');

  insert into auth.users(id,email,email_confirmed_at,is_anonymous) values
    (free_user,'free@example.test',now(),false),
    (premium_user,'premium@example.test',now(),false),
    (sandbox_user,'sandbox@example.test',now(),false),
    (unverified_user,'unverified@example.test',null,false),
    (pending_user,'pending@example.test',now(),false);
  assert not exists(select 1 from public.content_readers
    where user_id in (free_user,premium_user,sandbox_user,pending_user));

  insert into app.verified_entitlements(
    user_id,entitlement_id,environment,is_active,product_id,starts_at,expires_at,will_renew,observed_at
  ) values
    (premium_user,'premium','Production',true,'com.ardasayar.linglossa.premium.yearly',
      premium_anchor,now()+interval '2 years',true,now()),
    (sandbox_user,'premium','Sandbox',true,'com.ardasayar.linglossa.premium.monthly',
      now()-interval '1 day',now()+interval '29 days',true,now());

  -- Unverified account is rejected and cannot consume the free pool.
  assert public.claim_translation(unverified_user,'en',repeat('e',64))->>'status'='account_unverified';
  assert not exists(select 1 from app.translation_budget_reservations where user_id=unverified_user);
  assert public.claim_translation(free_user,'fr',repeat('1',64))->>'status'='forbidden';

  -- Five lifetime free successes are shared between languages. Each success
  -- charges on finish; a repeated server cache hit is free.
  for i in 1..5 loop
    key := lpad(to_hex(i),64,'0');
    r := public.claim_translation(free_user,case when i%2=0 then 'pt-BR' else 'en' end,key);
    assert r->>'status'='claimed'; current_ticket := (r->>'ticket')::uuid;
    assert public.finish_translation(free_user,key,current_ticket,answer)->>'stored'='true';
  end loop;
  assert public.claim_translation(free_user,'en',repeat('f',64))->>'status'='quota';
  assert public.claim_translation(free_user,'en',lpad(to_hex(1),64,'0'))->>'status'='hit';
  assert (select count(*)=5 from app.translation_budget_reservations where user_id=free_user and state='charged');

  -- Sandbox never activates the public paid pool: this account gets only free quota.
  for i in 1..5 loop
    key := lpad(to_hex(100+i),64,'0');
    r := public.claim_translation(sandbox_user,'en',key);
    assert r->>'status'='claimed'; current_ticket := (r->>'ticket')::uuid;
    assert (select b.quota_kind='free' from app.translation_budget_reservations b where b.ticket=current_ticket);
    assert public.finish_translation(sandbox_user,key,current_ticket,answer)->>'stored'='true';
  end loop;
  assert public.claim_translation(sandbox_user,'en',repeat('b',64))->>'status'='quota';

  -- Production annual subscription allocates 500 per anchored month (not 6000).
  -- Clear only abuse counters between synthetic calls so the separate monthly
  -- budget reaches its own boundary in this single-session SQL test.
  select c.period_start,c.period_end into expected_start,expected_end
    from app.translation_cycle(premium_anchor,clock_timestamp()) c;
  for i in 1..500 loop
    key := lpad(to_hex(1000+i),64,'0');
    r := public.claim_translation(premium_user,'en',key);
    assert r->>'status'='claimed'; current_ticket := (r->>'ticket')::uuid;
    assert (select b.quota_kind='premium' and b.period_start=expected_start
      from app.translation_budget_reservations b where b.ticket=current_ticket);
    assert public.finish_translation(premium_user,key,current_ticket,answer)->>'stored'='true';
    if i=250 then
      update app.verified_entitlements set product_id='com.ardasayar.linglossa.premium.monthly'
        where user_id=premium_user;
    elsif i=400 then
      update app.verified_entitlements set product_id='com.ardasayar.linglossa.premium.yearly'
        where user_id=premium_user;
    end if;
    delete from app.usage where user_id=premium_user;
  end loop;
  assert public.claim_translation(premium_user,'pt-BR',repeat('c',64))->>'status'='quota';
  assert (select count(*)=500 from app.translation_budget_reservations
    where user_id=premium_user and quota_kind='premium' and state='charged'
      and period_start=expected_start);

  -- Calendar month arithmetic stays anchored across February, leap years,
  -- month ends and database timezone settings.
  perform set_config('TimeZone','Pacific/Auckland',true);
  select c.period_start,c.period_end into race_start,race_end
    from app.translation_cycle('2025-01-31 12:00:00+00','2025-02-28 12:00:00+00') c;
  assert race_start='2025-02-28 12:00:00+00'::timestamptz;
  assert race_end='2025-03-31 12:00:00+00'::timestamptz;
  select c.period_start,c.period_end into race_start,race_end
    from app.translation_cycle('2025-01-31 12:00:00+00','2025-02-28 11:59:59+00') c;
  assert race_start='2025-01-31 12:00:00+00'::timestamptz;
  assert race_end='2025-02-28 12:00:00+00'::timestamptz;
  select c.period_start,c.period_end into race_start,race_end
    from app.translation_cycle('2024-01-31 12:00:00+00','2024-02-28 12:00:00+00') c;
  assert race_start='2024-01-31 12:00:00+00'::timestamptz;
  assert race_end='2024-02-29 12:00:00+00'::timestamptz;
  select c.period_start,c.period_end into race_start,race_end
    from app.translation_cycle('2024-01-31 12:00:00+00','2024-02-29 12:00:00+00') c;
  assert race_start='2024-02-29 12:00:00+00'::timestamptz;
  assert race_end='2024-03-31 12:00:00+00'::timestamptz;
  select c.period_start,c.period_end into race_start,race_end
    from app.translation_cycle('2025-01-31 12:00:00+00','2025-03-31 12:00:00+00') c;
  assert race_start='2025-03-31 12:00:00+00'::timestamptz;
  assert race_end='2025-04-30 12:00:00+00'::timestamptz;

  -- A failed generation releases one reservation. Releasing twice is safe,
  -- and a later distinct request can take the freed final unit.
  update app.verified_entitlements set is_active=false where user_id=premium_user;
  delete from app.translation_budget_reservations where user_id=premium_user;
  key := repeat('d',64);
  r := public.claim_translation(premium_user,'en',key);
  assert r->>'status'='claimed'; current_ticket := (r->>'ticket')::uuid;
  assert public.release_translation(premium_user,key,current_ticket)->>'released'='true';
  assert public.release_translation(premium_user,key,current_ticket)->>'released'='true';
  assert public.claim_translation(premium_user,'en',repeat('a',64))->>'status'='claimed';
  assert (select count(*)=1 from app.translation_budget_reservations
    where user_id=premium_user and state='pending');

  -- Pending tickets occupy the free quota before any finish call. A sixth
  -- parallel claimant therefore cannot take the same last unit.
  for i in 1..5 loop
    key := lpad(to_hex(2000+i),64,'0');
    assert public.claim_translation(pending_user,'en',key)->>'status'='claimed';
  end loop;
  assert public.claim_translation(pending_user,'en',repeat('9',64))->>'status'='quota';
  assert (select count(*)=5 from app.translation_budget_reservations
    where user_id=pending_user and state='pending');
end $$;
select pass('server display translation budgets: verified free accounts, production-only anchored premium, caps, cache, failure refunds and privileges');
select * from finish();
rollback;
