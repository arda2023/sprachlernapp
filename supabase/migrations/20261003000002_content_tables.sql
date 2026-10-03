-- Inhaltstabellen nach docs/content-schema.md (Entwurf v1).
-- id = Hash des normalisierten Schlüssels, beim ersten Upsert berechnet (Pipeline).
-- removed_in/replaced_by: Tombstones, Zeilen werden nie gelöscht.

create table content.languages (
  code text primary key,
  name_native text not null,
  name_de text not null,
  gloss_lang text not null
);

create table content.lemmas (
  id text primary key,
  lang text not null references content.languages (code),
  lemma text not null,
  pos text not null,
  family_key text,
  freq_rank integer,
  removed_in text,
  replaced_by text references content.lemmas (id),
  unique (lang, lemma, pos)
);

create table content.senses (
  id text primary key,
  lang text not null references content.languages (code),
  lemma_id text not null references content.lemmas (id),
  sense_key text not null,
  gloss_de text not null,
  definition_de text,
  notes_de text,
  sense_index integer,
  removed_in text,
  replaced_by text references content.senses (id),
  unique (lemma_id, sense_key)
);

create table content.cards (
  id text primary key,
  lang text not null references content.languages (code),
  form text not null,
  sense_id text not null references content.senses (id),
  form_norm text not null,
  lemma_id text not null references content.lemmas (id),
  pos text not null,
  form_kind text,
  form_label_de text,
  translation_de text,
  cefr_band text check (cefr_band in ('anfaenger', 'mittel', 'fortgeschritten')),
  freq_rank integer,
  is_multiword boolean not null default false,
  removed_in text,
  replaced_by text references content.cards (id),
  unique (lang, form, sense_id)
);

create table content.dictionary_forms (
  id text primary key,
  lang text not null references content.languages (code),
  form_norm text not null,
  sense_id text not null references content.senses (id),
  card_id text references content.cards (id),
  gloss_de text not null,
  rank integer,
  removed_in text,
  replaced_by text references content.dictionary_forms (id),
  unique (lang, form_norm, sense_id)
);

create table content.decks (
  id text primary key,
  lang text not null references content.languages (code),
  slug text not null,
  title_de text not null,
  description_de text,
  cefr_band text check (cefr_band in ('anfaenger', 'mittel', 'fortgeschritten')),
  icon text,
  sort integer,
  removed_in text,
  replaced_by text references content.decks (id),
  unique (lang, slug)
);

create table content.deck_cards (
  id text primary key,
  deck_id text not null references content.decks (id),
  card_id text not null references content.cards (id),
  position integer,
  removed_in text,
  replaced_by text references content.deck_cards (id),
  unique (deck_id, card_id)
);

create table content.sentences (
  id text primary key,
  lang text not null references content.languages (code),
  text text not null,
  origins text[] not null default '{}',
  translation_de text,
  model text,
  qa_status text,
  qa_report jsonb,
  removed_in text,
  replaced_by text references content.sentences (id),
  unique (lang, text)
);

-- start/end heißen start_pos/end_pos ("end" ist ein reserviertes Wort).
create table content.sentence_tokens (
  id text primary key,
  sentence_id text not null references content.sentences (id),
  idx integer not null,
  start_pos integer not null,
  end_pos integer not null,
  surface text not null,
  lemma_id text references content.lemmas (id),
  sense_id text references content.senses (id),
  card_id text references content.cards (id),
  removed_in text,
  replaced_by text references content.sentence_tokens (id),
  unique (sentence_id, idx)
);

create table content.card_sentences (
  id text primary key,
  card_id text not null references content.cards (id),
  sentence_id text not null references content.sentences (id),
  position smallint not null check (position between 1 and 3),
  gap_start integer not null,
  gap_end integer not null check (gap_end > gap_start),
  accepted text[] not null default '{}',
  removed_in text,
  replaced_by text references content.card_sentences (id),
  unique (card_id, sentence_id)
);

create table content.stories (
  id text primary key,
  lang text not null references content.languages (code),
  slug text not null,
  title text not null,
  kind text not null check (kind in ('story', 'text')),
  cefr_band text check (cefr_band in ('anfaenger', 'mittel', 'fortgeschritten')),
  topic text,
  minutes integer,
  cover text,
  removed_in text,
  replaced_by text references content.stories (id),
  unique (lang, slug)
);

create table content.story_sentences (
  id text primary key,
  story_id text not null references content.stories (id),
  idx integer not null,
  sentence_id text not null references content.sentences (id),
  paragraph_idx integer not null,
  heading text,
  removed_in text,
  replaced_by text references content.story_sentences (id),
  unique (story_id, idx)
);

create table content.exercises (
  id text primary key,
  lang text not null references content.languages (code),
  kind text not null,
  slug text not null,
  title text not null,
  cefr_band text check (cefr_band in ('anfaenger', 'mittel', 'fortgeschritten')),
  payload jsonb not null,
  removed_in text,
  replaced_by text references content.exercises (id),
  unique (lang, kind, slug)
);

create table content.grammar_rules (
  id text primary key,
  lang text not null references content.languages (code),
  slug text not null,
  title_de text not null,
  summary_de text,
  cefr_band text check (cefr_band in ('anfaenger', 'mittel', 'fortgeschritten')),
  sections jsonb not null,
  removed_in text,
  replaced_by text references content.grammar_rules (id),
  unique (lang, slug)
);

create table content.audio_assets (
  id text primary key,
  lang text not null references content.languages (code),
  owner_kind text not null,
  owner_id text not null,
  voice text not null,
  model text not null,
  path text not null,
  sha256 text,
  duration_ms integer,
  removed_in text,
  replaced_by text references content.audio_assets (id),
  unique (owner_kind, owner_id, voice, model)
);

create table content.content_releases (
  id text primary key,
  lang text not null references content.languages (code),
  version text not null,
  schema_version integer not null,
  created_at timestamptz not null default now(),
  sha256 text,
  size_bytes bigint,
  notes text,
  unique (lang, version)
);

-- Indizes auf Fremdschlüssel (inkl. replaced_by) und das Wörterbuch-Nachschlagen.
create index on content.lemmas (lang);
create index on content.lemmas (replaced_by);
create index on content.senses (lang);
create index on content.senses (lemma_id);
create index on content.senses (replaced_by);
create index on content.cards (lang);
create index on content.cards (sense_id);
create index on content.cards (lemma_id);
create index on content.cards (replaced_by);
create index on content.dictionary_forms (lang, form_norm);
create index on content.dictionary_forms (sense_id);
create index on content.dictionary_forms (card_id);
create index on content.dictionary_forms (replaced_by);
create index on content.decks (lang);
create index on content.decks (replaced_by);
create index on content.deck_cards (deck_id);
create index on content.deck_cards (card_id);
create index on content.deck_cards (replaced_by);
create index on content.sentences (lang);
create index on content.sentences (replaced_by);
create index on content.sentence_tokens (sentence_id);
create index on content.sentence_tokens (lemma_id);
create index on content.sentence_tokens (sense_id);
create index on content.sentence_tokens (card_id);
create index on content.sentence_tokens (replaced_by);
create index on content.card_sentences (card_id);
create index on content.card_sentences (sentence_id);
create index on content.card_sentences (replaced_by);
create index on content.stories (lang);
create index on content.stories (replaced_by);
create index on content.story_sentences (story_id);
create index on content.story_sentences (sentence_id);
create index on content.story_sentences (replaced_by);
create index on content.exercises (lang);
create index on content.exercises (replaced_by);
create index on content.grammar_rules (lang);
create index on content.grammar_rules (replaced_by);
create index on content.audio_assets (lang);
create index on content.audio_assets (replaced_by);
create index on content.content_releases (lang);

-- RLS an, keine Policies: nur die Pipeline (DB-Verbindung als postgres) kommt heran.
do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'content' loop
    execute format('alter table content.%I enable row level security', t.tablename);
  end loop;
end $$;

revoke all on all tables in schema content from public, anon, authenticated;
