-- Sicherheitsregeln für die Schemas app und content (supabase test db).
begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

-- Zwei Nutzer; der Trigger legt ihre profiles an.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');

-- (e) neuer auth.users-Eintrag erzeugt eine profiles-Zeile
select is(
  (select count(*)::int from app.profiles where id in (
    '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000b')),
  2, 'profiles row is created for each new auth user');

insert into app.user_cards (user_id, card_id, lang, origin) values
  ('00000000-0000-0000-0000-00000000000a', 'card-a', 'en', 'deck'),
  ('00000000-0000-0000-0000-00000000000b', 'card-b', 'en', 'deck');

-- Als Nutzer A
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

-- (a) A sieht keine user_cards von B
select results_eq(
  'select card_id from app.user_cards',
  array['card-a'],
  'user A sees only own user_cards');
select is_empty(
  $$select 1 from app.user_cards where user_id = '00000000-0000-0000-0000-00000000000b'$$,
  'user A sees no user_cards of user B');

-- (b) review_log: anhängen geht, UPDATE und DELETE schlagen fehl
select lives_ok(
  $$insert into app.review_log (id, user_id, card_id, mode, first_attempt_correct,
      box_before, box_after, due_at_after)
    values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a',
      'card-a', 'mixed', true, 0, 3, now() + interval '14 days')$$,
  'user A can insert own review_log row');
select throws_ok(
  'update app.review_log set error_count = 1', '42501', null,
  'authenticated cannot update review_log');
select throws_ok(
  'delete from app.review_log', '42501', null,
  'authenticated cannot delete review_log');

-- (d) authenticated kann content nicht lesen
select throws_ok(
  'select * from content.cards', '42501', null,
  'authenticated cannot read content');

reset role;

-- Auch ohne RLS und Grants (postgres) weist der Trigger Änderungen ab.
select throws_ok(
  'update app.review_log set error_count = 1', 'P0001', null,
  'trigger rejects update on review_log');
select throws_ok(
  'delete from app.review_log', 'P0001', null,
  'trigger rejects delete on review_log');

-- (c) anon kann weder app noch content lesen
set local role anon;
set local request.jwt.claims = '{"role": "anon"}';
select throws_ok(
  'select * from app.user_cards', '42501', null,
  'anon cannot read app');
select throws_ok(
  'select * from content.cards', '42501', null,
  'anon cannot read content');
reset role;

select * from finish();
rollback;
