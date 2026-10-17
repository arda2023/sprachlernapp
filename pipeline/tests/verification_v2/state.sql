-- LOCAL PROTOTYPE ONLY. Substituted nonce identifiers; never a production migration.
-- Results are diagnostic receipts, deliberately incapable of publishing content.
create schema __SCHEMA__;
create table __SCHEMA__.runs (
  id uuid primary key default gen_random_uuid(), upload_id uuid not null,
  identity jsonb not null, verifier text not null, revision bigint not null default 0,
  step integer not null default 0, lease uuid, lease_until timestamptz,
  last_lease uuid, last_result jsonb, expires_at timestamptz not null,
  resume_request uuid, resume_at timestamptz, resume_actor uuid,
  constraint resume_id unique(upload_id,resume_request)
);
revoke all on schema __SCHEMA__ from public,anon,authenticated;
create function public.__RPC__(actor uuid,upload_id uuid,op text,input jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u public.content_release_uploads; r __SCHEMA__.runs; identity jsonb;
begin
  if not exists(select 1 from public.content_publishers p where p.user_id=actor) then
    raise exception 'publisher required' using errcode='42501';
  end if;
  select * into u from public.content_release_uploads x where x.id=upload_id;
  if u.id is null or u.owner_id<>actor then raise exception 'owner required' using errcode='42501'; end if;
  identity=jsonb_build_object('upload',u.id,'manifest',u.draft_manifest,'objects',u.objects,
    'parent',u.parent_release_id,'parent_hash',u.parent_manifest_sha256,'generation',u.expected_generation);
  if op='resume_start' then
    if input->>'accepted' is distinct from 'true' or input->>'scope' is distinct from 'resume-same-upload-probe-v1'
      or input->>'request_id' is null then raise exception 'explicit resume required' using errcode='42501'; end if;
    if u.expires_at>clock_timestamp() then raise exception 'not expired' using errcode='40001'; end if;
    insert into __SCHEMA__.runs(upload_id,identity,verifier,expires_at,resume_request,resume_at,resume_actor)
      values(u.id,identity,'probe-v1',clock_timestamp()+interval '1 hour',(input->>'request_id')::uuid,clock_timestamp(),actor)
      on conflict on constraint resume_id do nothing;
    select * into r from __SCHEMA__.runs x where x.upload_id=u.id and x.resume_request=(input->>'request_id')::uuid;
    if r.identity<>identity then raise exception 'identity mismatch' using errcode='40001'; end if;
    return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step);
  end if;
  if op='start' then
    if u.expires_at<=clock_timestamp() then raise exception 'expired' using errcode='40001'; end if;
    insert into __SCHEMA__.runs(upload_id,identity,verifier,expires_at)
      values(u.id,identity,'probe-v1',u.expires_at) returning * into r;
    return jsonb_build_object('run_id',r.id,'revision',0,'step',0);
  end if;
  select * into r from __SCHEMA__.runs x where x.id=(input->>'run_id')::uuid for update;
  if r.id is null or r.upload_id<>u.id or r.identity<>identity or r.verifier is distinct from input->>'verifier' then
    raise exception 'identity mismatch' using errcode='40001';
  end if;
  if op='resume' then
    -- Explicit, audited diagnostic-run authorization; original upload expiry stays immutable.
    if input->>'accepted' is distinct from 'true' or input->>'scope' is distinct from 'resume-same-upload-probe-v1'
      or input->>'request_id' is null then
      raise exception 'explicit resume required' using errcode='42501';
    end if;
    if r.resume_request=(input->>'request_id')::uuid then
      return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step);
    end if;
    if r.expires_at>clock_timestamp() then raise exception 'not expired' using errcode='40001'; end if;
    update __SCHEMA__.runs set expires_at=clock_timestamp()+interval '1 hour',
      resume_request=(input->>'request_id')::uuid,resume_at=clock_timestamp(),resume_actor=actor,
      revision=revision+1,step=0,lease=null,lease_until=null,last_lease=null,last_result=null
      where id=r.id returning * into r;
    return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step);
  end if;
  if r.expires_at<=clock_timestamp() then raise exception 'expired' using errcode='40001'; end if;
  if op='status' then return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step); end if;
  if op='claim' then
    if r.lease_until>clock_timestamp() or r.revision is distinct from (input->>'revision')::bigint then
      raise exception 'busy or stale' using errcode='40001';
    end if;
    update __SCHEMA__.runs set revision=revision+1,lease=gen_random_uuid(),
      lease_until=clock_timestamp()+interval '2 seconds' where id=r.id returning * into r;
    return jsonb_build_object('run_id',r.id,'lease',r.lease,'revision',r.revision,'step',r.step);
  end if;
  if op='finish' then
    if r.last_lease=(input->>'lease')::uuid and r.last_result=input->'result' then
      return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step);
    end if;
    if r.lease is null or r.lease is distinct from (input->>'lease')::uuid or r.lease_until is null
      or r.lease_until<=clock_timestamp() or r.revision is distinct from (input->>'revision')::bigint then
      raise exception 'stale lease' using errcode='40001';
    end if;
    update __SCHEMA__.runs set step=step+1,last_lease=lease,last_result=input->'result',
      lease=null,lease_until=null where id=r.id returning * into r;
    return jsonb_build_object('run_id',r.id,'revision',r.revision,'step',r.step);
  end if;
  -- The storage immutability proof is deliberately absent: no publication path.
  if op='complete' then raise exception 'unsealed or incomplete' using errcode='40001'; end if;
  raise exception 'unsupported action';
end;
$$;
revoke all on function public.__RPC__(uuid,uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.__RPC__(uuid,uuid,text,jsonb) to service_role;
notify pgrst,'reload schema';
