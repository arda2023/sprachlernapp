-- Private distribution only. Existing public legacy buckets remain untouched.
create table public.content_readers (
  user_id uuid not null references auth.users(id),
  channel text not null check (channel = 'internal'),
  lang text not null check (lang ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'),
  primary key (user_id, channel, lang)
);
create table public.content_publishers (user_id uuid primary key references auth.users(id));
create table public.content_release_uploads (
  id uuid primary key,
  request_id uuid not null,
  owner_id uuid not null references auth.users(id),
  lang text not null,
  channel text not null check (channel = 'internal'),
  expected_generation bigint not null check (expected_generation >= 0),
  parent_manifest_sha256 text,
  parent_release_id uuid,
  draft_manifest jsonb not null,
  objects jsonb not null,
  verified_objects jsonb,
  manifest jsonb,
  manifest_sha256 text check (manifest_sha256 ~ '^[0-9a-f]{64}$'),
  status text not null default 'uploading' check (status in ('uploading','verifying','ready','published','failed')),
  failure_code text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  unique (owner_id, request_id),
  check (status not in ('ready','published') or (manifest is not null and manifest_sha256 is not null and verified_objects = objects))
);
create table public.content_release_catalog (
  release_id uuid primary key references public.content_release_uploads(id),
  lang text not null,
  channel text not null check (channel = 'internal'),
  generation bigint not null check (generation > 0),
  manifest jsonb not null,
  manifest_sha256 text not null check (manifest_sha256 ~ '^[0-9a-f]{64}$'),
  objects jsonb not null,
  published_by uuid not null references auth.users(id),
  published_at timestamptz not null default now(),
  unique (lang, channel, generation)
);
create table public.content_channels (
  lang text not null,
  channel text not null check (channel = 'internal'),
  generation bigint not null default 0 check (generation >= 0),
  release_id uuid references public.content_release_catalog(release_id),
  manifest_sha256 text,
  primary key (lang, channel)
);
create table public.content_publish_audit (
  request_id uuid primary key,
  upload_id uuid not null references public.content_release_uploads(id),
  actor_id uuid not null references auth.users(id),
  generation bigint not null,
  created_at timestamptz not null default now()
);

alter table public.content_readers enable row level security;
alter table public.content_publishers enable row level security;
alter table public.content_release_uploads enable row level security;
alter table public.content_release_catalog enable row level security;
alter table public.content_channels enable row level security;
alter table public.content_publish_audit enable row level security;
revoke all on public.content_readers, public.content_publishers, public.content_release_uploads,
  public.content_release_catalog, public.content_channels, public.content_publish_audit from public, anon, authenticated;
grant all on public.content_readers, public.content_publishers, public.content_release_uploads,
  public.content_release_catalog, public.content_channels, public.content_publish_audit to service_role;

create function public.reject_content_history_change() returns trigger
language plpgsql set search_path = '' as $$
begin raise exception 'Published content and publication audit are immutable' using errcode = '55000'; end;
$$;
create trigger content_catalog_immutable before update or delete on public.content_release_catalog
  for each row execute function public.reject_content_history_change();
create trigger content_audit_immutable before update or delete on public.content_publish_audit
  for each row execute function public.reject_content_history_change();

create function public.publish_content_release(upload_id uuid, expected_generation bigint,
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
  if u.status <> 'ready' or u.expires_at <= now() or u.verified_objects is distinct from u.objects then
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
revoke all on function public.reject_content_history_change() from public,anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit)
  values('content-private','content-private',false,268435456)
  on conflict(id) do update set public=false,file_size_limit=268435456;
-- No client policies: even readers use the authorized function and short-lived URLs.

create function public.guard_content_upload() returns trigger
language plpgsql set search_path='' as $$
begin
  if (to_jsonb(new)-array['status','verified_objects','manifest','manifest_sha256','failure_code'])
     is distinct from (to_jsonb(old)-array['status','verified_objects','manifest','manifest_sha256','failure_code']) then
    raise exception 'Upload identity is immutable' using errcode='55000';
  end if;
  if old.status in ('ready','published') and
    not (old.status='ready' and new.status='published' and
      (to_jsonb(new)-'status')=(to_jsonb(old)-'status')) then
    raise exception 'Finalized upload is immutable' using errcode='55000';
  end if;
  return new;
end;
$$;
create trigger content_upload_guard before update on public.content_release_uploads
  for each row execute function public.guard_content_upload();
revoke all on function public.guard_content_upload() from public,anon,authenticated;
