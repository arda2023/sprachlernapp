-- Content schema 2. Local mirror only; not applied remotely by Package A.
create table content.deck_words (
  id text primary key,
  lang text not null references content.languages(code),
  form_norm text not null,
  deck_id text not null references content.decks(id),
  primary_card_id text not null references content.cards(id),
  position integer not null,
  removed_in text,
  replaced_by text
);
create unique index deck_words_active_form on content.deck_words(lang, form_norm) where removed_in is null;
create unique index deck_words_active_position on content.deck_words(deck_id, position) where removed_in is null;
create table content.word_aliases (
  id text primary key,
  lang text not null references content.languages(code),
  form_norm text not null,
  word_id text not null references content.deck_words(id),
  removed_in text,
  replaced_by text
);
create unique index word_aliases_active_form on content.word_aliases(lang, form_norm) where removed_in is null;
-- Active-position uniqueness must allow historical links with the old position.
create unique index card_sentences_active_position on content.card_sentences(card_id, position) where removed_in is null;
