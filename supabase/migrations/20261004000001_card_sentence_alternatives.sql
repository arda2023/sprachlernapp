-- Vorab geprüfte Alternativantworten je Karte-Satz-Lücke (docs/content-schema.md).
-- Additiv: bestehende Zeilen erhalten die leere Liste. Kein Teil stabiler IDs;
-- accepted[] bleibt ausschließlich die Zielform.
alter table content.card_sentences
  add column valid_alternatives text[] not null default '{}'::text[];
