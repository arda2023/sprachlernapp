-- Additive content schema 5. Local authoring contract; not deployed by the editor.
alter table content.sentences add column root_sentence_id text;
alter table content.sentences add column revision_sha256 text;
alter table content.sentence_tokens add column context_gloss_de text;
alter table content.sentence_tokens add column context_snapshot jsonb;

create table content.story_context_corrections (
  id text primary key,
  lang text not null,
  identity_key text not null,
  source_key text not null,
  previous_fingerprint text not null,
  next_fingerprint text not null,
  previous_revision text not null,
  next_revision text not null,
  previous_context jsonb not null,
  next_context jsonb not null,
  introduced_in text not null,
  reason text not null
);

alter table content.story_context_corrections enable row level security;
