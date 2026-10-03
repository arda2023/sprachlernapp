-- Nutzerdaten nach docs/user-schema.md (ohne die nur lokale Tabelle ai_jobs).
-- Jede Tabelle hängt an auth.users; RLS: nur eigene Zeilen.

create table app.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table app.user_cards (
  user_id uuid not null references auth.users (id) on delete cascade,
  card_id text not null,
  lang text not null,
  local_only boolean not null default false,
  form text,
  gloss_de text,
  box smallint not null default 0 check (box between 0 and 5),
  due_at timestamptz,
  created_at timestamptz not null default now(),
  origin text not null check (origin in ('deck', 'story')),
  disabled boolean not null default false,
  retired boolean not null default false,
  favorite boolean not null default false,
  in_playlist boolean not null default false,
  note text,
  updated_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

create table app.card_contexts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  card_id text not null,
  text text not null,
  translation_de text,
  gap_start integer not null,
  gap_end integer not null check (gap_end > gap_start),
  source text not null check (source in ('story', 'import', 'ai_rewrite')),
  source_ref text,
  status text not null default 'pending'
    check (status in ('pending', 'ok', 'rewritten', 'failed')),
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create table app.review_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  card_id text not null,
  created_at timestamptz not null default now(),
  mode text not null check (mode in ('mixed', 'deck', 'revue', 'early')),
  sentence_id text,
  first_attempt_correct boolean not null,
  error_count integer not null default 0 check (error_count >= 0),
  revealed boolean not null default false,
  box_before smallint not null check (box_before between 0 and 5),
  box_after smallint not null check (box_after between 1 and 5),
  due_at_after timestamptz not null,
  response_ms integer check (response_ms >= 0),
  app_version text,
  device_id text
);

create table app.deck_settings (
  user_id uuid not null references auth.users (id) on delete cascade,
  deck_id text not null,
  active boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, deck_id)
);

create table app.user_imports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  lang text not null,
  title text not null,
  text text not null,
  word_count integer not null check (word_count between 0 and 5000),
  created_at timestamptz not null default now()
);

create table app.import_sentences (
  user_id uuid not null references auth.users (id) on delete cascade,
  import_id uuid not null references app.user_imports (id) on delete cascade,
  idx integer not null,
  text text not null,
  translation_de text,
  primary key (import_id, idx)
);

create table app.reading_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  target_kind text not null check (target_kind in ('story', 'import')),
  target_id text not null,
  fraction real not null default 0 check (fraction between 0 and 1),
  updated_at timestamptz not null default now(),
  primary key (user_id, target_kind, target_id)
);

create table app.settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  daily_goal integer not null default 10 check (daily_goal > 0),
  target_lang text not null default 'en',
  updated_at timestamptz not null default now()
);

-- Tageslimits; schreiben nur Edge Functions (service_role).
create table app.usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  kind text not null,
  units integer not null default 0 check (units >= 0),
  primary key (user_id, day, kind)
);

create index on app.card_contexts (user_id, card_id);
create index on app.review_log (user_id, card_id);
create index on app.review_log (user_id, created_at);
create index on app.user_imports (user_id);
create index on app.import_sentences (user_id);

-- review_log ist append-only: UPDATE und DELETE werden immer abgewiesen.
create function app.reject_review_log_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'review_log is append-only (% not allowed)', tg_op
    using errcode = 'P0001';
end $$;

create trigger review_log_append_only
  before update or delete on app.review_log
  for each row execute function app.reject_review_log_change();

-- Neue Nutzer bekommen eine Zeile in profiles.
create function app.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into app.profiles (id) values (new.id);
  return new;
end $$;

revoke all on function app.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- RLS
alter table app.profiles enable row level security;
alter table app.user_cards enable row level security;
alter table app.card_contexts enable row level security;
alter table app.review_log enable row level security;
alter table app.deck_settings enable row level security;
alter table app.user_imports enable row level security;
alter table app.import_sentences enable row level security;
alter table app.reading_progress enable row level security;
alter table app.settings enable row level security;
alter table app.usage enable row level security;

create policy "own profile" on app.profiles
  for select to authenticated using ((select auth.uid()) = id);

do $$
declare t text;
begin
  foreach t in array array['user_cards', 'card_contexts', 'deck_settings',
    'user_imports', 'import_sentences', 'reading_progress', 'settings'] loop
    execute format('create policy "own rows select" on app.%I for select to authenticated using ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows insert" on app.%I for insert to authenticated with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows update" on app.%I for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows delete" on app.%I for delete to authenticated using ((select auth.uid()) = user_id)', t);
  end loop;
end $$;

create policy "own rows select" on app.review_log
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own rows insert" on app.review_log
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "own rows select" on app.usage
  for select to authenticated using ((select auth.uid()) = user_id);

-- Grants: nur authenticated, nichts an anon.
revoke all on all tables in schema app from public, anon, authenticated;
grant usage on schema app to authenticated, service_role;
grant select, insert, update, delete on
  app.user_cards, app.card_contexts, app.deck_settings, app.user_imports,
  app.import_sentences, app.reading_progress, app.settings
  to authenticated;
grant select, insert on app.review_log to authenticated;
grant select on app.profiles, app.usage to authenticated;
grant all on all tables in schema app to service_role;
