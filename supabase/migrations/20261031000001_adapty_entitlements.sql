-- Server-verified Adapty identities and entitlements. Client input can never
-- write a paid access flag; authenticated users may only read their own row.
create table app.adapty_profile_bindings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  profile_id uuid not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table app.verified_entitlements (
  user_id uuid not null references auth.users(id) on delete cascade,
  entitlement_id text not null check (entitlement_id = 'premium'),
  environment text not null check (environment in ('Production', 'Sandbox')),
  is_active boolean not null default false,
  product_id text check (product_id in (
    'com.ardasayar.linglossa.premium.monthly',
    'com.ardasayar.linglossa.premium.yearly'
  )),
  starts_at timestamptz,
  expires_at timestamptz,
  will_renew boolean,
  observed_at timestamptz not null,
  primary key (user_id, entitlement_id, environment),
  check (not is_active or (
    product_id is not null and starts_at is not null and expires_at is not null
  ))
);

create table app.adapty_webhook_events (
  environment text not null check (environment in ('Production', 'Sandbox')),
  event_id text not null check (event_id ~ '^[a-f0-9-]{1,80}$'),
  event_type text not null,
  user_id uuid references auth.users(id) on delete set null,
  profile_id uuid not null,
  event_datetime timestamptz,
  received_at timestamptz not null default now(),
  primary key (environment, event_id)
);

alter table app.adapty_profile_bindings enable row level security;
alter table app.verified_entitlements enable row level security;
alter table app.adapty_webhook_events enable row level security;

revoke all on app.adapty_profile_bindings, app.verified_entitlements,
  app.adapty_webhook_events from public, anon, authenticated;
grant select on app.verified_entitlements to authenticated;
grant all on app.adapty_profile_bindings, app.verified_entitlements,
  app.adapty_webhook_events to service_role;

create policy "own verified entitlement read" on app.verified_entitlements
  for select to authenticated using ((select auth.uid()) = user_id);

create function app.bind_adapty_profile(p_user_id uuid, p_profile_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if p_user_id is null or p_profile_id is null then return false; end if;

  insert into app.adapty_profile_bindings(user_id, profile_id)
    values (p_user_id, p_profile_id)
    on conflict do nothing;

  if exists (
    select 1 from app.adapty_profile_bindings
    where user_id = p_user_id and profile_id = p_profile_id
  ) then
    return true;
  end if;
  return false;
end $$;

revoke all on function app.bind_adapty_profile(uuid, uuid)
  from public, anon, authenticated;
grant execute on function app.bind_adapty_profile(uuid, uuid) to service_role;

create function app.sync_adapty_entitlement(
  p_user_id uuid,
  p_profile_id uuid,
  p_environment text,
  p_product_id text,
  p_is_active boolean,
  p_starts_at timestamptz,
  p_expires_at timestamptz,
  p_will_renew boolean,
  p_observed_at timestamptz,
  p_event_id text default null,
  p_event_type text default null,
  p_event_datetime timestamptz default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  current_row app.verified_entitlements;
  saved_row app.verified_entitlements;
begin
  if p_environment not in ('Production', 'Sandbox')
    or p_product_id is not null and p_product_id not in (
      'com.ardasayar.linglossa.premium.monthly',
      'com.ardasayar.linglossa.premium.yearly'
    )
    or p_is_active and (
      p_product_id is null or p_starts_at is null or p_expires_at is null
      or p_starts_at > now() or p_expires_at <= now()
    )
    or (p_event_id is null) <> (p_event_type is null)
    or p_event_id is not null and p_event_id !~ '^[a-f0-9-]{1,80}$'
    or p_event_type is not null and length(p_event_type) > 80
  then
    raise exception 'Invalid verified entitlement' using errcode = '22023';
  end if;

  if not exists (
    select 1 from app.adapty_profile_bindings b
    where b.user_id = p_user_id and b.profile_id = p_profile_id
  ) then
    raise exception 'Adapty profile is not bound to this account'
      using errcode = '42501';
  end if;

  if p_event_id is not null then
    insert into app.adapty_webhook_events(
      environment, event_id, event_type, user_id, profile_id,
      event_datetime
    ) values (
      p_environment, p_event_id, p_event_type, p_user_id, p_profile_id,
      p_event_datetime
    ) on conflict do nothing;

    if not found then
      select * into current_row from app.verified_entitlements
        where user_id = p_user_id and entitlement_id = 'premium'
          and environment = p_environment;
      return jsonb_build_object(
        'duplicate', true,
        'entitlement', 'premium',
        'is_active', coalesce(current_row.is_active, false),
        'product_id', current_row.product_id,
        'starts_at', current_row.starts_at,
        'expires_at', current_row.expires_at,
        'will_renew', current_row.will_renew,
        'environment', p_environment,
        'synced_at', current_row.observed_at
      );
    end if;
  end if;

  insert into app.verified_entitlements(
    user_id, entitlement_id, environment, is_active, product_id,
    starts_at, expires_at, will_renew, observed_at
  ) values (
    p_user_id, 'premium', p_environment, p_is_active, p_product_id,
    p_starts_at, p_expires_at, p_will_renew, p_observed_at
  ) on conflict (user_id, entitlement_id, environment) do update set
    is_active = excluded.is_active,
    product_id = excluded.product_id,
    starts_at = excluded.starts_at,
    expires_at = excluded.expires_at,
    will_renew = excluded.will_renew,
    observed_at = excluded.observed_at
  where app.verified_entitlements.observed_at <= excluded.observed_at
  returning * into saved_row;

  if not found then
    select * into saved_row from app.verified_entitlements
      where user_id = p_user_id and entitlement_id = 'premium'
        and environment = p_environment;
  end if;

  return jsonb_build_object(
    'duplicate', false,
    'entitlement', 'premium',
    'is_active', saved_row.is_active,
    'product_id', saved_row.product_id,
    'starts_at', saved_row.starts_at,
    'expires_at', saved_row.expires_at,
    'will_renew', saved_row.will_renew,
    'environment', saved_row.environment,
    'synced_at', saved_row.observed_at
  );
end $$;

revoke all on function app.sync_adapty_entitlement(
  uuid, uuid, text, text, boolean, timestamptz, timestamptz, boolean,
  timestamptz, text, text, timestamptz
) from public, anon, authenticated;
grant execute on function app.sync_adapty_entitlement(
  uuid, uuid, text, text, boolean, timestamptz, timestamptz, boolean,
  timestamptz, text, text, timestamptz
) to service_role;
