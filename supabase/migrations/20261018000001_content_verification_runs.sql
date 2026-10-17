-- Native bounded verification. No storage mutation or client write privileges.
create table public.content_verification_runs (
  id uuid primary key default gen_random_uuid(),
  upload_id uuid not null references public.content_release_uploads(id),
  identity jsonb not null, verifier text not null check(verifier='native-v2'),
  active boolean not null default true,
  state text not null default 'verifying' check(state in ('verifying','complete','failed','superseded')),
  stages text[] not null, results jsonb not null default '{}',
  revision bigint not null default 0, lease uuid, lease_until timestamptz,
  last_lease uuid, last_revision bigint, last_stage text, last_result jsonb, last_result_sha256 text,
  expires_at timestamptz not null, created_at timestamptz not null default now(),
  resume_request uuid, resume_actor uuid references auth.users(id), resume_at timestamptz,
  failure_code text,
  unique(upload_id,resume_request)
);
create unique index content_verification_one_active on public.content_verification_runs(upload_id) where active;
alter table public.content_verification_runs enable row level security;
revoke all on public.content_verification_runs from public,anon,authenticated,service_role;
grant select on public.content_verification_runs to service_role;

create function public.content_verification_identity(u public.content_release_uploads)
returns jsonb language sql immutable set search_path='' as $$
 select to_jsonb(u)-array['status','verified_objects','manifest','manifest_sha256','failure_code'];
$$;
revoke all on function public.content_verification_identity(public.content_release_uploads) from public,anon,authenticated;

create function public.content_verification_transition(p_actor uuid,p_upload uuid,p_op text,p_input jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u public.content_release_uploads; r public.content_verification_runs;
  identity jsonb; stages text[]; stage text; completed integer; result jsonb; expected jsonb;
begin
  if not exists(select 1 from public.content_publishers where user_id=p_actor) then
    raise exception 'PUBLISHER_REQUIRED' using errcode='PV403'; end if;
  select * into u from public.content_release_uploads where id=p_upload for update;
  if u.id is null or u.owner_id is distinct from p_actor then
    raise exception 'UPLOAD_FORBIDDEN' using errcode='PV403'; end if;
  identity=public.content_verification_identity(u);
  stages=array['F0','F1','F2','F3','F4','F5','F6','F7','F8','M','P_full'];
  if u.draft_manifest->>'publication_kind'='internal-baseline-adoption-v1' then stages=stages||array['P_content']; end if;
  stages=stages||array['H','A'];
  select * into r from public.content_verification_runs where upload_id=u.id and active for update;
  if u.status='published' then return jsonb_build_object('published',true); end if;
  if p_op='resume' then
    if p_input->'accepted' is distinct from 'true'::jsonb or p_input->>'scope' is distinct from 'resume-same-upload-native-v2'
       or p_input->>'request_id' is null then raise exception 'RESUME_CONFIRMATION' using errcode='PV409'; end if;
    -- A lost resume response is safe to retry, but cannot resurrect a superseded run.
    select * into r from public.content_verification_runs where upload_id=u.id and resume_request=(p_input->>'request_id')::uuid;
    if r.id is not null then
      if not r.active or r.identity<>identity then raise exception 'VERIFICATION_STALE' using errcode='PV409'; end if;
      return to_jsonb(r);
    end if;
    update public.content_verification_runs set active=false,state='superseded',lease=null,lease_until=null where upload_id=u.id and active;
    insert into public.content_verification_runs(upload_id,identity,verifier,stages,expires_at,resume_request,resume_actor,resume_at)
      values(u.id,identity,'native-v2',stages,clock_timestamp()+interval '24 hours',(p_input->>'request_id')::uuid,p_actor,clock_timestamp()) returning * into r;
    update public.content_release_uploads set status='verifying',verified_objects=null,manifest=null,manifest_sha256=null,failure_code=null where id=u.id;
    return to_jsonb(r);
  end if;
  if r.id is null then
    if p_op='status' then return jsonb_build_object('required',true,'stages',stages,'expires_at',u.expires_at,'failed',u.status='failed'); end if;
    if p_op<>'claim' then raise exception 'VERIFICATION_STALE' using errcode='PV409'; end if;
    if u.expires_at<=clock_timestamp() or u.status='failed' then raise exception 'VERIFICATION_EXPIRED' using errcode='PV410'; end if;
    insert into public.content_verification_runs(upload_id,identity,verifier,stages,expires_at)
      values(u.id,identity,'native-v2',stages,u.expires_at) returning * into r;
    update public.content_release_uploads set status='verifying',verified_objects=null,manifest=null,manifest_sha256=null,failure_code=null where id=u.id;
  end if;
  if r.identity<>identity or r.verifier<>'native-v2' or r.stages<>stages then raise exception 'VERIFICATION_IDENTITY' using errcode='PV409'; end if;
  if p_op='status' then return to_jsonb(r); end if;
  if r.expires_at<=clock_timestamp() then raise exception 'VERIFICATION_EXPIRED' using errcode='PV410'; end if;
  if p_op='finish' and r.id=(p_input->>'run_id')::uuid and r.last_stage=p_input->>'stage' and r.last_lease=(p_input->>'lease')::uuid and r.last_revision=(p_input->>'revision')::bigint
     and r.last_result=p_input->'result' and r.last_result_sha256=p_input->>'result_sha256' then return to_jsonb(r); end if;
  if r.state='complete' and p_op='claim' then return to_jsonb(r); end if;
  if r.state<>'verifying' then raise exception 'VERIFICATION_FAILED' using errcode='PV409'; end if;
  select count(*) into completed from jsonb_object_keys(r.results);
  stage=r.stages[completed+1];
  if p_op='claim' then
    if r.lease_until>clock_timestamp() then raise exception 'VERIFICATION_BUSY' using errcode='PV409'; end if;
    if p_input ? 'run_id' and (p_input->>'run_id')::uuid<>r.id then raise exception 'VERIFICATION_STALE' using errcode='PV409'; end if;
    update public.content_verification_runs set revision=revision+1,lease=gen_random_uuid(),lease_until=clock_timestamp()+interval '90 seconds'
      where id=r.id returning * into r;
    return to_jsonb(r)||jsonb_build_object('stage',stage);
  end if;
  if r.id is distinct from (p_input->>'run_id')::uuid or r.lease is null or r.lease is distinct from (p_input->>'lease')::uuid
     or r.revision is distinct from (p_input->>'revision')::bigint or r.lease_until<=clock_timestamp()
     or stage is distinct from p_input->>'stage' then raise exception 'VERIFICATION_STALE' using errcode='PV409'; end if;
  if p_op='fail' then
    update public.content_verification_runs set state='failed',lease=null,lease_until=null,failure_code=p_input->>'code' where id=r.id returning * into r;
    update public.content_release_uploads set status='failed',failure_code=p_input->>'code' where id=u.id;
    return to_jsonb(r);
  end if;
  if p_op<>'finish' then raise exception 'VERIFICATION_STAGE' using errcode='PV409'; end if;
  result=p_input->'result';
  if jsonb_typeof(result) is distinct from 'object' or octet_length(result::text)>65536
     or coalesce(p_input->>'result_sha256','') !~ '^[0-9a-f]{64}$' then raise exception 'VERIFICATION_RESULT' using errcode='PV409'; end if;
  if stage='A' then
    if completed<>cardinality(r.stages)-1 or not (r.results ?& r.stages[1:cardinality(r.stages)-1])
      then raise exception 'VERIFICATION_INCOMPLETE' using errcode='PV409'; end if;
    expected=(u.draft_manifest-'local_only')||jsonb_build_object('pack_canonical_sha256',r.results->'P_full'->>'sha256',
      'release_id',u.id,'channel',u.channel,'generation',u.expected_generation+1,'parent_release_id',u.parent_release_id,
      'parent_manifest_sha256',u.parent_manifest_sha256,'created_at',to_char(u.created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"+00:00"'));
    -- Timestamp lexical form belongs to the immutable REST upload representation.
    expected=expected||jsonb_build_object('created_at',result->'manifest'->'created_at');
    if result->'manifest' is distinct from expected or (result->'manifest'->>'created_at')::timestamptz is distinct from u.created_at
       or coalesce(result->>'manifest_sha256','') !~ '^[0-9a-f]{64}$' then raise exception 'VERIFICATION_RESULT' using errcode='PV409'; end if;
  end if;
  update public.content_verification_runs set results=results||jsonb_build_object(stage,result),
    last_lease=lease,last_revision=revision,last_stage=stage,last_result=result,last_result_sha256=p_input->>'result_sha256',lease=null,lease_until=null,
    state=case when stage='A' then 'complete' else 'verifying' end where id=r.id returning * into r;
  if stage='A' then
    update public.content_release_uploads set status='ready',verified_objects=objects,manifest=result->'manifest',manifest_sha256=result->>'manifest_sha256',failure_code=null where id=u.id;
  end if;
  return to_jsonb(r);
end;
$$;
revoke all on function public.content_verification_transition(uuid,uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.content_verification_transition(uuid,uuid,text,jsonb) to service_role;

-- A legacy Function cannot write ready without a completed new run.
create or replace function public.guard_content_upload() returns trigger
language plpgsql set search_path='' as $$
declare r public.content_verification_runs;
begin
  if public.content_verification_identity(new)<>public.content_verification_identity(old) then raise exception 'Upload identity is immutable' using errcode='55000'; end if;
  if old.status='published' then raise exception 'Published upload is immutable' using errcode='55000'; end if;
  select * into r from public.content_verification_runs where upload_id=new.id and active;
  if new.status in ('ready','published') and (r.id is null or r.state<>'complete' or r.expires_at<=clock_timestamp()
    or r.identity<>public.content_verification_identity(new) or r.results->'A'->'manifest' is distinct from new.manifest
    or r.results->'A'->>'manifest_sha256' is distinct from new.manifest_sha256 or new.verified_objects is distinct from new.objects) then
    raise exception 'VERIFIER_UPGRADE_REQUIRED' using errcode='PV409'; end if;
  if old.status='ready' and new.status not in ('published','verifying') then raise exception 'Finalized upload is immutable' using errcode='55000'; end if;
  if old.status='ready' and new.status='verifying' and (r.id is null or r.state<>'verifying' or r.results<>'{}') then raise exception 'Explicit verification required' using errcode='55000'; end if;
  return new;
end;
$$;

create or replace function public.publish_content_release(upload_id uuid, expected_generation bigint,
  expected_manifest_sha256 text, request_id uuid, verified_actor_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  u public.content_release_uploads;
  c public.content_channels;
  a public.content_publish_audit;
  result jsonb;
begin
  if not exists(select 1 from public.content_publishers where user_id=verified_actor_id) then
    raise exception 'Publisher permission required' using errcode='42501';
  end if;
  select * into u from public.content_release_uploads where id=upload_id for update;
  if u.id is null or u.owner_id is distinct from verified_actor_id then
    raise exception 'Upload scope mismatch' using errcode='42501';
  end if;
  select * into a from public.content_publish_audit where content_publish_audit.request_id=publish_content_release.request_id;
  if a.request_id is not null then
    if a.upload_id <> upload_id or a.actor_id <> verified_actor_id then
      raise exception 'Request ID conflict' using errcode='40001';
    end if;
    select jsonb_build_object('manifest',manifest,'manifest_sha256',manifest_sha256)
      into result from public.content_release_catalog where release_id=upload_id;
    return result;
  end if;
  if u.status <> 'ready' or not exists(select 1 from public.content_verification_runs r where r.upload_id=u.id and r.active and r.state='complete' and r.verifier='native-v2' and r.expires_at>clock_timestamp() and r.identity=public.content_verification_identity(u) and r.results->'A'->'manifest'=u.manifest and r.results->'A'->>'manifest_sha256'=u.manifest_sha256) or u.verified_objects is distinct from u.objects then
    raise exception 'Upload not ready' using errcode='55000';
  end if;
  if u.expected_generation is distinct from expected_generation or
     u.parent_manifest_sha256 is distinct from expected_manifest_sha256 then
    raise exception 'Upload basis mismatch' using errcode='40001';
  end if;
  insert into public.content_channels(lang,channel) values(u.lang,u.channel) on conflict do nothing;
  select * into c from public.content_channels where lang=u.lang and channel=u.channel for update;
  if c.generation is distinct from expected_generation or c.manifest_sha256 is distinct from expected_manifest_sha256
     or c.release_id is distinct from u.parent_release_id then
    raise exception 'Channel changed; build on the latest release' using errcode='40001';
  end if;
  if u.manifest->>'lang' is distinct from u.lang or u.manifest->>'channel' is distinct from u.channel
     or u.manifest->>'release_id' is distinct from u.id::text
     or (u.manifest->>'generation')::bigint is distinct from c.generation+1
     or u.manifest->>'parent_manifest_sha256' is distinct from c.manifest_sha256
     or u.manifest->>'parent_release_id' is distinct from c.release_id::text then
    raise exception 'Manifest scope mismatch' using errcode='22023';
  end if;
  insert into public.content_release_catalog(release_id,lang,channel,generation,manifest,manifest_sha256,objects,published_by)
    values(u.id,u.lang,u.channel,c.generation+1,u.manifest,u.manifest_sha256,u.verified_objects,verified_actor_id);
  update public.content_channels set generation=c.generation+1,release_id=u.id,manifest_sha256=u.manifest_sha256
    where lang=u.lang and channel=u.channel;
  insert into public.content_publish_audit(request_id,upload_id,actor_id,generation)
    values(request_id,u.id,verified_actor_id,c.generation+1);
  update public.content_release_uploads set status='published' where id=u.id;
  return jsonb_build_object('manifest',u.manifest,'manifest_sha256',u.manifest_sha256);
end;
$$;
revoke all on function public.publish_content_release(uuid,bigint,text,uuid,uuid) from public,anon,authenticated;
grant execute on function public.publish_content_release(uuid,bigint,text,uuid,uuid) to service_role;
