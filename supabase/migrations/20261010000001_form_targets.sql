-- Local schema-4 mirror only. Do not apply remotely as part of package A.
alter table content.cards
  add column identity_function text;
alter table content.cards
  add column introduction_scope text not null default 'ordinary';
alter table content.decks
  add column practice_kind text not null default 'ordinary';
alter table content.sentence_tokens
  add column form_target_id text;

create table content.lexical_targets (
  id text primary key,
  lang text not null,
  anchor_key text not null,
  note text not null,
  removed_in text,
  replaced_by text
);

create table content.card_lexical_targets (
  id text primary key,
  lang text not null,
  card_id text not null,
  lexical_target_id text not null,
  note text not null,
  removed_in text,
  replaced_by text
);

create table content.form_targets (
  id text primary key,
  lang text not null,
  sense_id text not null,
  form text not null,
  form_norm text not null,
  function text not null,
  card_id text not null,
  lexical_target_id text not null,
  note text not null,
  removed_in text,
  replaced_by text
);

create table content.deck_practice_targets (
  id text primary key,
  deck_id text not null,
  form_target_id text not null,
  position integer not null,
  removed_in text,
  replaced_by text
);

alter table content.cards drop constraint cards_lang_form_sense_id_key;
create unique index cards_ordinary_identity on content.cards(lang, form, sense_id) where identity_function is null;
create unique index cards_function_identity on content.cards(lang, form, sense_id, identity_function) where identity_function is not null;
create unique index form_targets_identity on content.form_targets(lang, sense_id, form_norm, function) where removed_in is null;
create unique index form_targets_card on content.form_targets(card_id) where removed_in is null;
create unique index lexical_targets_anchor on content.lexical_targets(lang, anchor_key) where removed_in is null;
create unique index card_lexical_targets_card on content.card_lexical_targets(card_id) where removed_in is null;
create unique index deck_practice_targets_position on content.deck_practice_targets(deck_id, position) where removed_in is null;
alter table content.card_lexical_targets add foreign key (card_id) references content.cards(id);
alter table content.card_lexical_targets add foreign key (lexical_target_id) references content.lexical_targets(id);
alter table content.form_targets add foreign key (card_id) references content.cards(id);
alter table content.form_targets add foreign key (sense_id) references content.senses(id);
alter table content.form_targets add foreign key (lexical_target_id) references content.lexical_targets(id);
alter table content.deck_practice_targets add foreign key (deck_id) references content.decks(id);
alter table content.deck_practice_targets add foreign key (form_target_id) references content.form_targets(id) deferrable initially deferred;
alter table content.sentence_tokens add foreign key (form_target_id) references content.form_targets(id) deferrable initially deferred;
-- The shared validator enforces live references, function/deck agreement,
-- single fixed sentences, ownership and complete lexical group coverage.
alter table content.cards add check (identity_function is null or identity_function in ('base','past','past_participle'));
alter table content.cards add check (introduction_scope in ('ordinary','form_only'));
alter table content.cards add check (identity_function is null or introduction_scope = 'form_only');
alter table content.decks add check (practice_kind in ('ordinary','verb_base','verb_past','verb_participle'));
alter table content.form_targets add check (function in ('base','past','past_participle'));
alter table content.deck_practice_targets add check (position > 0);
create unique index deck_practice_targets_membership on content.deck_practice_targets(deck_id, form_target_id) where removed_in is null;
