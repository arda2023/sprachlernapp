begin;
create extension if not exists pgtap with schema extensions;
select plan(1);
-- The same assertions are executable on an isolated PostgreSQL test runtime.
do $$
<<scenario>>
declare
  actor uuid := '00000000-0000-0000-0000-0000000000a1';
  tester uuid := '00000000-0000-0000-0000-0000000000b1';
  first_id uuid := '10000000-0000-0000-0000-000000000001';
  second_id uuid := '10000000-0000-0000-0000-000000000002';
  req uuid := '20000000-0000-0000-0000-000000000001';
  manifest jsonb;
  result jsonb;
begin
  assert not has_table_privilege('anon','public.content_release_catalog','SELECT');
  assert not has_table_privilege('authenticated','public.content_channels','UPDATE');
  assert not has_function_privilege('authenticated','public.publish_content_release(uuid,bigint,text,uuid,uuid)','EXECUTE');
  assert has_function_privilege('service_role','public.publish_content_release(uuid,bigint,text,uuid,uuid)','EXECUTE');
  assert not (select public from storage.buckets where id='content-private');
  insert into auth.users(id,email) values(actor,'publisher@example.test'),(tester,'reader@example.test');
  insert into public.content_publishers values(actor);
  insert into public.content_readers values(tester,'internal','en');
  manifest=jsonb_build_object('lang','en','channel','internal','release_id',first_id,'generation',1,'parent_release_id',null,'parent_manifest_sha256',null);
  insert into public.content_release_uploads(id,request_id,owner_id,lang,channel,expected_generation,draft_manifest,objects)
    values(first_id,first_id,actor,'en','internal',0,'{}','{}'),(second_id,second_id,actor,'en','internal',0,'{}','{}');
  begin
    perform public.publish_content_release(first_id,0,null,req,tester);
    raise exception 'unauthorized publish succeeded';
  exception when insufficient_privilege then null;end;
  begin
    perform public.publish_content_release(first_id,0,null,req,actor);
    raise exception 'incomplete publish succeeded';
  exception when object_not_in_prerequisite_state then null;end;
  assert (select count(*)=0 from public.content_channels);
  update public.content_release_uploads set status='ready',verified_objects='{}',manifest=scenario.manifest,
    manifest_sha256=repeat('a',64) where id=first_id;
  update public.content_release_uploads set status='ready',verified_objects='{}',
    manifest=jsonb_set(scenario.manifest,'{release_id}',to_jsonb(second_id)),manifest_sha256=repeat('b',64) where id=second_id;
  result=public.publish_content_release(first_id,0,null,req,actor);
  assert result=public.publish_content_release(first_id,0,null,req,actor), 'retry differs';
  assert (select count(*)=1 from public.content_publish_audit);
  begin
    perform public.publish_content_release(second_id,0,null,second_id,actor);
    raise exception 'stale publisher succeeded';
  exception when serialization_failure then null;end;
  assert (select generation=1 and release_id=first_id from public.content_channels where lang='en' and channel='internal');
  begin
    update public.content_release_catalog set manifest='{}' where release_id=first_id;
    raise exception 'catalog changed';
  exception when object_not_in_prerequisite_state then null;end;
  begin
    update public.content_release_uploads set status='verifying' where id=first_id;
    raise exception 'published upload regressed';
  exception when object_not_in_prerequisite_state then null;end;
  begin
    delete from public.content_publish_audit;
    raise exception 'audit deleted';
  exception when object_not_in_prerequisite_state then null;end;
end;
$$;
select pass('distribution permissions, readiness, CAS, retry and immutability');
select * from finish();
rollback;
