-- Synthetic mini content pack (schema of pipeline export, docs/content-schema.md).
-- Readable ids instead of hashes; tests check they pass through unchanged.
CREATE TABLE "languages" ("code" TEXT PRIMARY KEY, "name_native" TEXT, "name_de" TEXT, "gloss_lang" TEXT);
CREATE TABLE "lemmas" ("id" TEXT PRIMARY KEY, "lang" TEXT, "lemma" TEXT, "pos" TEXT, "family_key" TEXT, "freq_rank" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "senses" ("id" TEXT PRIMARY KEY, "lang" TEXT, "lemma_id" TEXT, "sense_key" TEXT, "gloss_de" TEXT, "definition_de" TEXT, "notes_de" TEXT, "sense_index" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "cards" ("id" TEXT PRIMARY KEY, "lang" TEXT, "form" TEXT, "sense_id" TEXT, "form_norm" TEXT, "lemma_id" TEXT, "pos" TEXT, "form_kind" TEXT, "form_label_de" TEXT, "translation_de" TEXT, "cefr_band" TEXT, "freq_rank" INTEGER, "is_multiword" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "dictionary_forms" ("id" TEXT PRIMARY KEY, "lang" TEXT, "form_norm" TEXT, "sense_id" TEXT, "card_id" TEXT, "gloss_de" TEXT, "rank" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "decks" ("id" TEXT PRIMARY KEY, "lang" TEXT, "slug" TEXT, "title_de" TEXT, "description_de" TEXT, "cefr_band" TEXT, "icon" TEXT, "sort" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "deck_cards" ("id" TEXT PRIMARY KEY, "deck_id" TEXT, "card_id" TEXT, "position" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "sentences" ("id" TEXT PRIMARY KEY, "lang" TEXT, "text" TEXT, "origins" TEXT, "translation_de" TEXT, "model" TEXT, "qa_status" TEXT, "qa_report" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "sentence_tokens" ("id" TEXT PRIMARY KEY, "sentence_id" TEXT, "idx" INTEGER, "start_pos" INTEGER, "end_pos" INTEGER, "surface" TEXT, "lemma_id" TEXT, "sense_id" TEXT, "card_id" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "card_sentences" ("id" TEXT PRIMARY KEY, "card_id" TEXT, "sentence_id" TEXT, "position" INTEGER, "gap_start" INTEGER, "gap_end" INTEGER, "accepted" TEXT, "removed_in" TEXT, "replaced_by" TEXT, "valid_alternatives" TEXT);
CREATE TABLE "stories" ("id" TEXT PRIMARY KEY, "lang" TEXT, "slug" TEXT, "title" TEXT, "kind" TEXT, "cefr_band" TEXT, "topic" TEXT, "minutes" INTEGER, "cover" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "story_sentences" ("id" TEXT PRIMARY KEY, "story_id" TEXT, "idx" INTEGER, "sentence_id" TEXT, "paragraph_idx" INTEGER, "heading" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "exercises" ("id" TEXT PRIMARY KEY, "lang" TEXT, "kind" TEXT, "slug" TEXT, "title" TEXT, "cefr_band" TEXT, "payload" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "grammar_rules" ("id" TEXT PRIMARY KEY, "lang" TEXT, "slug" TEXT, "title_de" TEXT, "summary_de" TEXT, "cefr_band" TEXT, "sections" TEXT, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "audio_assets" ("id" TEXT PRIMARY KEY, "lang" TEXT, "owner_kind" TEXT, "owner_id" TEXT, "voice" TEXT, "model" TEXT, "path" TEXT, "sha256" TEXT, "duration_ms" INTEGER, "removed_in" TEXT, "replaced_by" TEXT);
CREATE TABLE "content_releases" ("id" TEXT PRIMARY KEY, "lang" TEXT, "version" TEXT, "schema_version" INTEGER, "created_at" TEXT, "sha256" TEXT, "size_bytes" INTEGER, "notes" TEXT);

INSERT INTO languages VALUES ('en', 'English', 'Englisch', 'de');
INSERT INTO content_releases VALUES ('rel-mini', 'en', 'mini-v1', 1, '2026-10-04T00:00:00+00:00', NULL, NULL, 'INTERNES TEST-PACK: synthetische Fixture');
INSERT INTO decks VALUES ('deck-allg', 'en', 'allgemeine-sprache', 'Allgemeine Sprache', NULL, 'anfaenger', NULL, 1, NULL, NULL);

INSERT INTO lemmas VALUES ('lem-go', 'en', 'go', 'VERB', NULL, 30, NULL, NULL);
INSERT INTO lemmas VALUES ('lem-about', 'en', 'about', 'ADV', NULL, 40, NULL, NULL);
INSERT INTO lemmas VALUES ('lem-a', 'en', 'a', 'DET', NULL, 5, NULL, NULL);
INSERT INTO senses VALUES ('sen-go', 'en', 'lem-go', 'go#gehen', 'gehen', NULL, NULL, 1, NULL, NULL);
INSERT INTO senses VALUES ('sen-about', 'en', 'lem-about', 'about#ungefaehr', 'ungefähr', NULL, NULL, 1, NULL, NULL);
INSERT INTO senses VALUES ('sen-a', 'en', 'lem-a', 'a#ein', 'ein', NULL, NULL, 1, NULL, NULL);

INSERT INTO cards VALUES ('card-went', 'en', 'went', 'sen-go', 'went', 'lem-go', 'VERB', 'past', 'Verb, Vergangenheit', 'ging', 'anfaenger', 30, 0, NULL, NULL);
INSERT INTO cards VALUES ('card-about', 'en', 'about', 'sen-about', 'about', 'lem-about', 'ADV', 'base', 'Adverb', 'ungefähr', 'anfaenger', 40, 0, NULL, NULL);
INSERT INTO cards VALUES ('card-a', 'en', 'a', 'sen-a', 'a', 'lem-a', 'DET', 'base', 'Artikel', 'ein / eine', 'anfaenger', 5, 0, NULL, NULL);
INSERT INTO cards VALUES ('card-goes', 'en', 'goes', 'sen-go', 'goes', 'lem-go', 'VERB', 'third_person', 'Verb, 3. Person Singular', 'geht', 'anfaenger', 30, 0, NULL, NULL);
-- A removed card (tombstone): never returned.
INSERT INTO cards VALUES ('card-gone-old', 'en', 'gone', 'sen-go', 'gone', 'lem-go', 'VERB', 'past_participle', 'Verb, Partizip Perfekt', 'gegangen', 'anfaenger', 30, 0, '0.9', NULL);

INSERT INTO deck_cards VALUES ('dc-1', 'deck-allg', 'card-went', 1, NULL, NULL);
INSERT INTO deck_cards VALUES ('dc-2', 'deck-allg', 'card-about', 2, NULL, NULL);
INSERT INTO deck_cards VALUES ('dc-3', 'deck-allg', 'card-a', 3, NULL, NULL);
INSERT INTO deck_cards VALUES ('dc-4', 'deck-allg', 'card-goes', 4, NULL, NULL);
INSERT INTO deck_cards VALUES ('dc-5', 'deck-allg', 'card-gone-old', 5, '0.9', NULL);

INSERT INTO dictionary_forms VALUES ('df-go', 'en', 'go', 'sen-go', NULL, 'gehen', 1, NULL, NULL);
INSERT INTO dictionary_forms VALUES ('df-goes', 'en', 'goes', 'sen-go', 'card-goes', 'geht', 1, NULL, NULL);
INSERT INTO dictionary_forms VALUES ('df-went', 'en', 'went', 'sen-go', 'card-went', 'ging', 1, NULL, NULL);
INSERT INTO dictionary_forms VALUES ('df-gone', 'en', 'gone', 'sen-go', NULL, 'gegangen', 1, NULL, NULL);
INSERT INTO dictionary_forms VALUES ('df-about', 'en', 'about', 'sen-about', 'card-about', 'ungefähr', 1, NULL, NULL);
INSERT INTO dictionary_forms VALUES ('df-a', 'en', 'a', 'sen-a', 'card-a', 'ein', 1, NULL, NULL);

INSERT INTO sentences VALUES ('s-went-1', 'en', 'Mia went home after work.', '["deck"]', 'Mia ging nach der Arbeit nach Hause.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-went-2', 'en', 'We went to the park yesterday.', '["deck"]', 'Wir gingen gestern in den Park.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-went-3', 'en', 'Leo went to bed early.', '["deck"]', 'Leo ging früh ins Bett.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-about-1', 'en', 'The trip takes about two hours.', '["deck"]', 'Die Fahrt dauert ungefähr zwei Stunden.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-about-2', 'en', 'Nina has about ten books.', '["deck"]', 'Nina hat ungefähr zehn Bücher.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-about-3', 'en', 'We waited about an hour.', '["deck"]', 'Wir warteten ungefähr eine Stunde.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-a-1', 'en', 'Leo has a dog.', '["deck"]', 'Leo hat einen Hund.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-a-2', 'en', 'I need a pen.', '["deck"]', 'Ich brauche einen Stift.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-a-3', 'en', 'Sara buys a lamp.', '["deck"]', 'Sara kauft eine Lampe.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-goes-1', 'en', 'Ben goes to school by bus.', '["deck"]', 'Ben fährt mit dem Bus zur Schule.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-goes-2', 'en', 'She goes running every morning.', '["deck"]', 'Sie geht jeden Morgen laufen.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-goes-3', 'en', 'Omar goes to the gym.', '["deck"]', 'Omar geht ins Fitnessstudio.', 'm', 'ok', NULL, NULL, NULL);
INSERT INTO sentences VALUES ('s-gone-old', 'en', 'She has gone home.', '["deck"]', 'Sie ist nach Hause gegangen.', 'm', 'ok', NULL, '0.9', NULL);

-- Stored out of position order on purpose: the repository sorts by position.
INSERT INTO card_sentences VALUES ('cs-went-2', 'card-went', 's-went-2', 2, 3, 7, '["went"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-went-1', 'card-went', 's-went-1', 1, 4, 8, '["went"]', NULL, NULL, '["walked"]');
INSERT INTO card_sentences VALUES ('cs-went-3', 'card-went', 's-went-3', 3, 4, 8, '["went"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-about-1', 'card-about', 's-about-1', 1, 15, 20, '["about"]', NULL, NULL, '["around","approximately"]');
INSERT INTO card_sentences VALUES ('cs-about-2', 'card-about', 's-about-2', 2, 9, 14, '["about"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-about-3', 'card-about', 's-about-3', 3, 10, 15, '["about"]', NULL, NULL, '["around"]');
INSERT INTO card_sentences VALUES ('cs-a-1', 'card-a', 's-a-1', 1, 8, 9, '["a"]', NULL, NULL, '["one"]');
INSERT INTO card_sentences VALUES ('cs-a-2', 'card-a', 's-a-2', 2, 7, 8, '["a"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-a-3', 'card-a', 's-a-3', 3, 10, 11, '["a"]', NULL, NULL, NULL);
INSERT INTO card_sentences VALUES ('cs-goes-1', 'card-goes', 's-goes-1', 1, 4, 8, '["goes"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-goes-2', 'card-goes', 's-goes-2', 2, 4, 8, '["goes"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-goes-3', 'card-goes', 's-goes-3', 3, 5, 9, '["goes"]', NULL, NULL, '[]');
INSERT INTO card_sentences VALUES ('cs-gone-old', 'card-gone-old', 's-gone-old', 1, 8, 12, '["gone"]', '0.9', NULL, '[]');
