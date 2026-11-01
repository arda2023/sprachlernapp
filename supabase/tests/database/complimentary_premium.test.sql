begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

do $$
declare
  actor uuid:='5a100000-0000-4000-8000-000000000001';
  profile uuid:='5a100000-0000-4000-8000-000000000002';
  product text:='com.ardasayar.linglossa.premium.complimentary';
  r jsonb;
begin
  assert not has_table_privilege('authenticated','app.verified_entitlements','INSERT');
  assert not has_table_privilege('anon','app.verified_entitlements','SELECT');
  assert not has_function_privilege('authenticated','app.sync_adapty_entitlement(uuid,uuid,text,text,boolean,timestamptz,timestamptz,boolean,timestamptz,text,text,timestamptz)','EXECUTE');
  assert has_function_privilege('service_role','app.sync_adapty_entitlement(uuid,uuid,text,text,boolean,timestamptz,timestamptz,boolean,timestamptz,text,text,timestamptz)','EXECUTE');
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'gift-sync@example.test',clock_timestamp());
  begin
    perform app.sync_adapty_entitlement(actor,profile,'Production',product,true,
      now()-interval '1 minute',now()+interval '30 days',false,now());
    raise exception 'unbound grant accepted';
  exception when insufficient_privilege then null;
  end;
  assert app.bind_adapty_profile(actor,profile);
  r:=app.sync_adapty_entitlement(actor,profile,'Production',product,true,
    now()-interval '1 minute',now()+interval '30 days',false,now());
  assert r->>'is_active'='true' and r->>'product_id'=product;
  assert r->>'environment'='Production' and r->>'will_renew'='false';
  assert (r->>'expires_at')::timestamptz=now()+interval '30 days';
  -- Replay and stale-observation fencing are unchanged for manual gifts.
  r:=app.sync_adapty_entitlement(actor,profile,'Production',product,false,
    now()-interval '1 minute',now()+interval '30 days',false,now()-interval '1 second');
  assert r->>'is_active'='true';
end $$;
select pass('only a server-bound Production gift can enter the private entitlement snapshot');

do $$
declare
  actor uuid:='5a200000-0000-4000-8000-000000000001';
  profile uuid:='5a200000-0000-4000-8000-000000000002';
  product text:='com.ardasayar.linglossa.premium.complimentary';
  scenario record;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'gift-rejections@example.test',clock_timestamp());
  assert app.bind_adapty_profile(actor,profile);
  for scenario in select * from (values
    ('Sandbox',now()-interval '1 minute',now()+interval '30 days',false),
    ('Production',now()-interval '1 minute',now()+interval '30 days',true),
    ('Production',now()-interval '1 minute',now()+interval '30 days',null::boolean),
    ('Production',null::timestamptz,now()+interval '30 days',false),
    ('Production',now()-interval '1 minute',null::timestamptz,false),
    ('Production',now()-interval '1 minute','infinity'::timestamptz,false),
    ('Production',now()+interval '1 day',now()+interval '30 days',false),
    ('Production',now()-interval '30 days',now()-interval '1 second',false),
    ('Production',now()-interval '1 minute',now()-interval '1 minute',false)
  ) as cases(environment,starts_at,expires_at,will_renew) loop
    begin
      perform app.sync_adapty_entitlement(actor,profile,scenario.environment,product,true,
        scenario.starts_at,scenario.expires_at,scenario.will_renew,now());
      raise exception 'invalid gift accepted';
    exception when invalid_parameter_value then null;
    end;
  end loop;
  -- A direct service write also cannot bypass the gift shape constraint.
  begin
    insert into app.verified_entitlements(user_id,entitlement_id,environment,
      is_active,product_id,starts_at,expires_at,will_renew,observed_at)
      values(actor,'premium','Sandbox',true,product,now(),now()+interval '30 days',false,now());
    raise exception 'sandbox gift table write accepted';
  exception when check_violation then null;
  end;
  assert not exists(select 1 from app.verified_entitlements where user_id=actor);
end $$;
select pass('gifts reject Sandbox, renewal, unbounded, missing, future and expired active access');

do $$
declare
  actor uuid:='5a300000-0000-4000-8000-000000000001';
  profile uuid:='5a300000-0000-4000-8000-000000000002';
  anchor timestamptz:=now()-interval '1 minute';
  r jsonb; current_ticket uuid; period timestamptz;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'gift-translations@example.test',clock_timestamp());
  assert app.bind_adapty_profile(actor,profile);
  perform app.sync_adapty_entitlement(actor,profile,'Production',
    'com.ardasayar.linglossa.premium.complimentary',true,
    anchor,now()+interval '30 days',false,now());
  -- Exhausted lifetime free quota must not restrict an active gift.
  insert into app.translation_budget_reservations(ticket,user_id,request_key,
    quota_kind,period_start,state,lease_until)
    select gen_random_uuid(),actor,lpad(to_hex(i),64,'0'),'free',null,'charged',now()
      from generate_series(1,5) i;
  r:=public.claim_translation(actor,'en',repeat('a',64));
  assert r->>'status'='claimed'; current_ticket:=(r->>'ticket')::uuid;
  select period_start into period from app.translation_budget_reservations
    where translation_budget_reservations.ticket=current_ticket;
  assert period=anchor;
  assert (select quota_kind='premium' from app.translation_budget_reservations
    where translation_budget_reservations.ticket=current_ticket);
  -- Pending claims count toward exactly the same 500 monthly units.
  insert into app.translation_budget_reservations(ticket,user_id,request_key,
    quota_kind,period_start,state,lease_until)
    select gen_random_uuid(),actor,lpad(to_hex(i+1000),64,'0'),'premium',period,'charged',now()
      from generate_series(1,499) i;
  r:=public.claim_translation(actor,'en',repeat('b',64));
  assert r->>'status'='quota' and r->>'quota_kind'='premium';
  assert public.release_translation(actor,repeat('a',64),current_ticket)->>'released'='true';
  r:=public.claim_translation(actor,'en',repeat('c',64));
  assert r->>'status'='claimed';
  update app.verified_entitlements set expires_at=clock_timestamp()-interval '1 second'
    where user_id=actor;
  r:=public.claim_translation(actor,'en',repeat('d',64));
  assert r->>'status'='quota' and r->>'quota_kind'='free';
end $$;
select pass('an active gift receives 500 anchored monthly translations and expires back to free');

do $$
declare
  actor uuid:='5a400000-0000-4000-8000-000000000001';
  profile uuid:='5a400000-0000-4000-8000-000000000002';
  request uuid:='5a400000-0000-4000-8000-000000000003';
  key text:=repeat('a',64); r jsonb;
begin
  insert into auth.users(id,email,email_confirmed_at)
    values(actor,'gift-vocabulary@example.test',clock_timestamp());
  assert public.claim_generated_vocabulary(actor,request,'en',key,10,true)->>'status'='premium_required';
  assert app.bind_adapty_profile(actor,profile);
  perform app.sync_adapty_entitlement(actor,profile,'Production',
    'com.ardasayar.linglossa.premium.complimentary',true,
    now()-interval '1 minute',now()+interval '30 days',false,now());
  assert public.claim_generated_vocabulary(actor,request,'en',key,10,true)->>'status'='missing';
  r:=public.claim_generated_vocabulary(actor,request,'en',key,10);
  assert r->>'status'='claimed';
  perform public.fail_generated_vocabulary(actor,request,(r->>'ticket')::uuid);
  update app.verified_entitlements set expires_at=clock_timestamp()-interval '1 second'
    where user_id=actor;
  assert public.claim_generated_vocabulary(actor,request,'en',key,10,true)->>'status'='premium_required';
  assert public.claim_generated_vocabulary(actor,gen_random_uuid(),'en',key,10)->>'status'='premium_required';
  assert (select count(*)=1 from app.generated_vocabulary_requests where user_id=actor);
end $$;
select pass('topic vocabulary recognizes active gifts and refuses new attempts after expiry');

select * from finish();
rollback;
