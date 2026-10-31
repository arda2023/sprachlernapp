begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users(id,email) values
  ('00000000-0000-4000-8000-0000000000d1','billing@example.test'),
  ('00000000-0000-4000-8000-0000000000d2','billing-stranger@example.test');

select ok(not has_table_privilege('anon','app.verified_entitlements','SELECT'), 'anon cannot read entitlements');
select ok(has_table_privilege('authenticated','app.verified_entitlements','SELECT'), 'authenticated can read the RLS-protected snapshot');
select ok(not has_table_privilege('authenticated','app.verified_entitlements','INSERT'), 'authenticated cannot write entitlements');
select ok(not has_table_privilege('authenticated','app.adapty_profile_bindings','SELECT'), 'profile bindings are private');
select ok(not has_function_privilege('authenticated','app.sync_adapty_entitlement(uuid,uuid,text,text,boolean,timestamp with time zone,timestamp with time zone,boolean,timestamp with time zone,text,text,timestamp with time zone)','EXECUTE'), 'authenticated cannot call entitlement RPC');

set local role service_role;
select is(app.bind_adapty_profile(
  '00000000-0000-4000-8000-0000000000d1',
  '00000000-0000-4000-8000-0000000000d3'
), true, 'service role can bind the REST-verified Adapty identity');

select is(app.sync_adapty_entitlement(
  '00000000-0000-4000-8000-0000000000d1',
  '00000000-0000-4000-8000-0000000000d3',
  'Production', 'com.ardasayar.linglossa.premium.monthly', true,
  now(), now() + interval '30 days', true, now() + interval '2 minutes',
  'd4234567-1234-4234-8234-123456789abc', 'subscription_started', now()
)->>'is_active', 'true', 'allowlisted production subscription activates');

select is(app.sync_adapty_entitlement(
  '00000000-0000-4000-8000-0000000000d1',
  '00000000-0000-4000-8000-0000000000d3',
  'Production', null, false, null, null, null, now() + interval '3 minutes',
  'd4234567-1234-4234-8234-123456789abc', 'subscription_refunded', now() + interval '2 minutes'
)->>'duplicate', 'true', 'duplicate webhook is idempotent');

select is(app.sync_adapty_entitlement(
  '00000000-0000-4000-8000-0000000000d1',
  '00000000-0000-4000-8000-0000000000d3',
  'Production', null, false, null, null, null, now() + interval '2 minutes',
  'd4234567-1234-4234-8234-123456789abc', 'subscription_refunded', now() + interval '2 minutes'
)->>'is_active', 'true', 'duplicate cannot overwrite the entitlement');

select is(app.sync_adapty_entitlement(
  '00000000-0000-4000-8000-0000000000d1',
  '00000000-0000-4000-8000-0000000000d3',
  'Production', null, false, null, null, null, now() + interval '1 minute',
  'e4234567-1234-4234-8234-123456789abc', 'subscription_expired', now() - interval '1 day'
)->>'is_active', 'true', 'late event reconciliation cannot roll back a newer observation');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-0000000000d1","role":"authenticated"}';
set local request.jwt.claim.sub = '00000000-0000-4000-8000-0000000000d1';
select results_eq(
  'select entitlement_id from app.verified_entitlements',
  array['premium']::text[],
  'user sees own entitlement');
select is_empty(
  $$select 1 from app.verified_entitlements where user_id = '00000000-0000-4000-8000-0000000000d2'$$,
  'user cannot see another account entitlement');
select throws_ok('update app.verified_entitlements set is_active = false', '42501', null, 'user cannot write entitlement snapshot');
reset role;

select * from finish();
rollback;
