begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

do $$
declare
  actor uuid := '00000000-0000-4000-8000-0000000000e1';
  upload uuid := '00000000-0000-4000-8000-0000000000e2';
  request uuid := '00000000-0000-4000-8000-0000000000e3';
begin
  insert into auth.users(id,email) values(actor,'delete-account@example.test');
  insert into public.content_readers(user_id,channel,lang) values(actor,'internal','en');
  insert into app.user_cards(user_id,card_id,lang,origin)
    values(actor,'card-1','en','deck');
  insert into app.review_log(user_id,card_id,mode,first_attempt_correct,box_before,box_after,due_at_after)
    values(actor,'card-1','mixed',true,0,3,now()+interval '1 day');
  insert into app.adapty_webhook_events(environment,event_id,event_type,user_id,profile_id)
    values('Production','e4234567-1234-4234-8234-123456789abc','subscription_started',actor,
      '00000000-0000-4000-8000-0000000000e4');

  insert into public.content_release_uploads(
    id,request_id,owner_id,lang,channel,expected_generation,draft_manifest,objects
  ) values(upload,request,actor,'en','internal',0,'{}','[]');
  insert into public.content_release_catalog(
    release_id,lang,channel,generation,manifest,manifest_sha256,objects,published_by
  ) values(upload,'en','internal',1,'{}',repeat('a',64),'[]',actor);
  insert into public.content_publish_audit(request_id,upload_id,actor_id,generation)
    values(request,upload,actor,1);

end $$;

delete from auth.users where id='00000000-0000-4000-8000-0000000000e1';

select is((select count(*)::integer from public.content_readers
  where user_id='00000000-0000-4000-8000-0000000000e1'),0,
  'reader grants are erased with the user');
select is((select count(*)::integer from app.user_cards
  where user_id='00000000-0000-4000-8000-0000000000e1'),0,
  'cloud learning state is erased with the user');
select is((select count(*)::integer from app.review_log
  where user_id='00000000-0000-4000-8000-0000000000e1'),0,
  'append-only review history can be erased only through account deletion');
select is((select count(*)::integer from app.adapty_webhook_events
  where user_id='00000000-0000-4000-8000-0000000000e1'),0,
  'billing webhook details are erased with the user');
select is((select count(*)::integer from public.content_release_uploads
  where id='00000000-0000-4000-8000-0000000000e2'),1,
  'publication upload history remains after account deletion');
select is((select count(*)::integer from public.content_release_catalog
  where release_id='00000000-0000-4000-8000-0000000000e2'),1,
  'immutable release catalog survives account deletion');
select is((select count(*)::integer from public.content_publish_audit
  where request_id='00000000-0000-4000-8000-0000000000e3'),1,
  'immutable publication audit survives account deletion');

select * from finish();
rollback;
