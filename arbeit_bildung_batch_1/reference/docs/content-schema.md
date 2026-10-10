# Inhaltsschema (Version 2, kompatibler Leser für Version 1)

Gilt für Supabase Schema `content` und, gleich, für `content.sqlite` je Sprache. Die App liest nur. Lernzustand steht in `user.db` (`docs/user-schema.md`) und verweist über `card_id` auf `cards.id`.

## Master und IDs

- **Supabase Schema `content` ist der Master.** `content.sqlite` ist ein Export daraus.
- `id` = Hash des normalisierten Schlüssels: Hex der ersten 16 Byte von SHA-256 über Tabellenname und Schlüsselfelder (Details: Abschnitt „Kanonisierung (festgeschrieben)“).
- IDs werden **beim ersten Upsert berechnet und danach nie neu berechnet**. Eine gespeicherte ID gilt, auch wenn sich die Hash-Regel später ändert.
- **Schlüssel enthalten nur unveränderliche Felder.** Korrekturen an Glossen, Übersetzungen oder Labels ändern nie eine ID; sie sind normale Spalten.
- IDs werden **nie wiederverwendet**.
- Alle Inhaltstabellen außer den Verknüpfungstabellen (`deck_cards`, `card_sentences`, `story_sentences`, `sentence_tokens`) tragen `lang` (Zielsprache). Die Glossensprache steht einmal in `languages.gloss_lang` (v1: `de`).
- Formen wie `null`, `true`, `false` immer als Text behandeln.

## Normalisierung `form_norm`

Unicode NFC, Kleinschreibung, `’` → `'`, sonst unverändert (keine Akzententfernung, keine Lemmatisierung).

## Kanonisierung (festgeschrieben)

Code: `pipeline/src/sprachpipe/ids.py` (`stable_id`). Testvektoren: `pipeline/tests/test_ids.py`.

- Kanonische Zeichenfolge: `<tabelle>` `\u001f` `<feld 1>` `\u001f` `<feld 2>` … Der Tabellenname steht zuerst, damit gleiche Schlüssel in verschiedenen Tabellen (z. B. `decks` und `stories`, beide `lang` + `slug`) verschiedene IDs ergeben.
- Jeder Wert wird Text (Ganzzahlen als Dezimalziffern) und nach Unicode NFC normalisiert. Sonst keine Änderung: keine Kleinschreibung, kein Trimmen. `null` ist als Schlüsselwert verboten.
- `id` = Hex der ersten 16 Byte von SHA-256 über die UTF-8-Bytes (32 Zeichen).
- `languages` hat keine `id`; Schlüssel ist `code`.

| Tabelle            | Feldreihenfolge                            |
| ------------------ | ------------------------------------------ |
| `lemmas`           | `lang`, `lemma`, `pos`                     |
| `senses`           | `lemma_id`, `sense_key`                    |
| `cards`            | `lang`, `form`, `sense_id`                 |
| `dictionary_forms` | `lang`, `form_norm`, `sense_id`            |
| `decks`            | `lang`, `slug`                             |
| `deck_cards`       | `deck_id`, `card_id`                       |
| `sentences`        | `lang`, `text`                             |
| `sentence_tokens`  | `sentence_id`, `idx`                       |
| `card_sentences`   | `card_id`, `sentence_id`                   |
| `stories`          | `lang`, `slug`                             |
| `story_sentences`  | `story_id`, `idx`                          |
| `exercises`        | `lang`, `kind`, `slug`                     |
| `grammar_rules`    | `lang`, `slug`                             |
| `audio_assets`     | `owner_kind`, `owner_id`, `voice`, `model` |
| `content_releases` | `lang`, `version`                          |

Eine Änderung an dieser Tabelle ändert alle IDs der betroffenen Tabelle und ist deshalb ausgeschlossen.

## Tombstones

- Entfernte Zeilen bleiben als **Tombstone** (`removed_in` = Release-Version, optional `replaced_by` = neue ID). Sie werden nie gelöscht.
- Beim Import übernimmt die App den Lernstand entlang der `replaced_by`-Kette (A → B → C: der Stand von A landet bei C).
- Eine Karte ohne Ersatz wird in `user.db` auf `retired = true` gesetzt: raus aus Queues und Zählern, der Verlauf (`review_log`) bleibt.

## Tabellen

| Tabelle            | Schlüssel → id                             | Weitere Spalten                                                                                                                    |
| ------------------ | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `languages`        | `code` (pk)                                | `name_native`, `name_de`, `gloss_lang`                                                                                             |
| `lemmas`           | `lang`, `lemma`, `pos`                     | `family_key`, `freq_rank`                                                                                                          |
| `senses`           | `lemma_id`, `sense_key`                    | `gloss_de`, `definition_de`, `notes_de`, `sense_index`                                                                             |
| `cards`            | `lang`, `form`, `sense_id`                 | `form_norm`, `lemma_id`, `pos`, `form_kind`, `form_label_de`, `translation_de`, `cefr_band`, `freq_rank`, `is_multiword`           |
| `dictionary_forms` | `lang`, `form_norm`, `sense_id`            | `card_id` (null, wenn keine Karte), `gloss_de`, `rank`                                                                             |
| `decks`            | `lang`, `slug`                             | `title_de`, `description_de`, `cefr_band`, `icon`, `sort`                                                                          |
| `deck_cards`       | `deck_id`, `card_id`                       | `position`                                                                                                                         |
| `sentences`        | `lang`, `text`                             | `origins` (Menge: deck / story / exercise), `translation_de`, `model`, `qa_status`, `qa_report`                                    |
| `sentence_tokens`  | `sentence_id`, `idx`                       | `start_pos`, `end_pos`, `surface`, `lemma_id`, `sense_id`, `card_id`                                                               |
| `card_sentences`   | `card_id`, `sentence_id`                   | `position` (aktiv 1; historische Positionen erhalten), `gap_start`, `gap_end`, `accepted[]`, `valid_alternatives[]` (siehe Regeln) |
| `stories`          | `lang`, `slug`                             | `title`, `kind` (story / text), `cefr_band`, `topic`, `minutes`, `cover`                                                           |
| `story_sentences`  | `story_id`, `idx`                          | `sentence_id`, `paragraph_idx`, `heading`                                                                                          |
| `exercises`        | `lang`, `kind`, `slug`                     | `title`, `cefr_band`, `payload` (JSON je Art: Lückentext, Hören, Grammatik)                                                        |
| `grammar_rules`    | `lang`, `slug`                             | `title_de`, `summary_de`, `cefr_band`, `sections` (JSON)                                                                           |
| `audio_assets`     | `owner_kind`, `owner_id`, `voice`, `model` | `path` (relativ zur Audio-Basis-URL), `sha256`, `duration_ms`                                                                      |
| `content_releases` | `lang`, `version`                          | `schema_version`, `created_at`, `sha256`, `size_bytes`, `notes`                                                                    |

Alle Tabellen außer `languages` und `content_releases` haben zusätzlich `removed_in` und `replaced_by`.

## Regeln

- **Karte**: eine exakte Form in einer Bedeutung. Lemma und Familie verbinden Karten nur über `lemma_id` ("Andere Formen", Erkennung falscher Formen), verschmelzen nie.
- **`sense_key`**: stabiler Slug je Lemma, z. B. `bank#ufer`. Einmal vergeben, nie geändert.
- **Bedeutungs-Inventar der Pipeline**: `pipeline/data/meanings/en.json` speichert je Form `display_form` und eine geordnete Bedeutungs-Liste. `display_form` steuert die Schreibweise in Prompts (z. B. `i` → `I`); Karten-IDs nutzen weiter die kanonische Form. Vorhandene `sense_key` bleiben unverändert und werden nicht gelöscht; `--refresh-meanings <form>` kann neue Bedeutungen nur anhängen. Jede Bedeutung hat `usage` (`haupt`, `neben`, `selten`) und `status` (`active`, `excluded`); ausgeschlossene Einträge bleiben für stabile IDs im Inventar, erzeugen aber keine Karte. `exclude_reason` begründet den Ausschluss.
- **Mehrwort-Karten** (Redewendungen, Verbalphrasen): `form` darf mehrere Wörter enthalten; die Lücke ist eine zusammenhängende Zeichenspanne. Trennbare Formen ("pick it up") werden in v1 nicht erzeugt.
- **Sätze je Karte**: genau 3 Zeilen in `card_sentences`; jeder Satz enthält die Form an `gap_start`–`gap_end` (Zeichen-Offsets in `sentences.text`, Vergleich ohne Beachtung der Groß-/Kleinschreibung). `accepted[]` enthält ausschließlich die Zielform; nur sie schließt die Karte regulär ab.
- **`valid_alternatives[]`** (beschlossen 04.10.2026): Postgres `text[] not null default '{}'::text[]` (Migration `20261004000001_card_sentence_alternatives.sql`, additiv, erstellt, noch nicht angewendet); in `content.sqlite` wie alle `text[]`-Felder als JSON-Text. Pipeline, Pack, `schema.py` und Export sind umgesetzt; die App liest das Feld. Liste von Strings, Standard leer. `null`, falsche Typen, nicht normalisierte Werte, Duplikate oder die Zielform im Pack sind ungültiger Inhalt und brechen den Pack-Aufbau ab. Gilt ausschließlich für diese Karte-Satz-Lücken-Zuordnung (`card_id`, `sentence_id`, `gap_start`–`gap_end`), nie für andere Sätze derselben Karte oder als globales Synonym. Enthält nur Alternativen, die die Pipeline wörtlich in diese Lückenspanne eingesetzt und als vollständigen Satz geprüft hat (`docs/pipeline.md`); normalisiert wie `form_norm` und getrimmt, ohne Duplikate, ohne die Zielform. Die Werte sind keine Antworten zum sofortigen Abschluss, sondern lösen in der App einen neutralen erneuten Versuch ohne Lernstandnachteil aus (`docs/srs.md`, Abschnitt Neutrale Synonymversuche). Fehlt das Feld in alten Packs, gilt die leere Liste. Das Feld ist kein Teil stabiler IDs; der Schlüssel von `card_sentences` bleibt `card_id`, `sentence_id`.
- **Satzkorrektur**: Der Text ist Schlüssel, eine Korrektur ergibt eine neue ID plus Tombstone der alten Zeile mit `replaced_by`. `origins` ist nicht Teil des Schlüssels.
- **Wörterbuch** (Schicht 1): `dictionary_forms`. **Token-Annotation** (Schicht 2): `sentence_tokens`. **Satzübersetzung** (Schicht 3): `sentences.translation_de`.
- `cefr_band` ∈ `anfaenger` (A1–A2), `mittel` (B1–B2), `fortgeschritten` (C1–C2).
- `audio_assets.path` ist relativ. Die Basis-URL liegt in der Konfiguration (`docs/backend.md`).
- `content_releases` verweist auf den Export `packs/<lang>/<version>/content.sqlite`.

## Offen

- Nachrichten (Schema folgt, wenn entschieden).

## Schema 2: feste Sätze und Wortbesitz (04.10.2026)

- Genau ein aktiver `card_sentences`-Link auf Position 1 je nicht retirierter Karte. `removed_in` an einem Link archiviert nur diese Verknüpfung, niemals die Karte. Historische Texte/Token/IDs bleiben lesbar; keine Reviewumschreibung.
- `deck_words`: id = stable_id(lang, form_norm), dazu deck_id, primary_card_id, position, removed_in, replaced_by. Ein aktiver Besitzer je normalisierter Form/Sprache; eine aktive Primärkarte und Position je Wort. Aktive deck_cards entsprechen exakt diesen Primärzuordnungen, Positionen 1..n je Stapel.
- `word_aliases`: id = stable_id(lang, form_norm), word_id, removed_in, replaced_by. Alias kollidiert mit keiner anderen aktiven Form/Reservierung. Keine Fortschrittsgleichsetzung.
- Alle früheren KEY_FIELDS unverändert. Registry `pipeline/data/words/en.v1.json` mit SHA-gebundenem Snapshot im JSON-Pack; zusätzliche Senses behalten eigene Karten-IDs beim selben Wortbesitz.
- Schema-1-Packs bleiben read-only lesbar: drei alte Links werden geprüft, Position 1 bleibt fest; Primärplätze werden deterministisch nach Stapelreihenfolge und normalisierter Form projiziert. Neue normale Exporte verwenden Schema 2. CLI-Replay von Schema 1 braucht `export --legacy`.
- `build_rows` transportiert Tombstones, Stories und Story-Satzverweise und prüft Struktur, Referenzen, Spans, accepted, Alternativen und Besitz vor jedem Schema-2-Export. SQLite-Readback vergleicht alle Zeilen aller 18 Tabellen.
- Migration `supabase/migrations/20261004000003_deck_word_ownership.sql` ist ein lokaler Schemaspiegel; nicht remote angewendet. Keine user.db-Migration.

## Story-Lernen im internen Pack story_learning_v1

Content-Schema bleibt 2. Storytexte werden über `stories`, `story_sentences`, `sentences` und `sentence_tokens` transportiert; jede Wortstelle hat eine genaue Lemma-/Sense-Referenz und kontextuelle Formglosse. Python-Codepoint-Offsets werden im Dart-Repository in UTF-16 umgerechnet; Quelle und Tokenindex bleiben erhalten. Keine Suche nach dem ersten gleich geschriebenen Wörterbucheintrag.
Die Satzfreigabe in `qa_report.editorial_create.learning_contexts` bindet `token_index`, `surface`, `sense`, `approved: true` und `reason` an den gehashten redaktionellen Satz-/Tokenstand. Der Adapter prüft Zielstelle, vollständige Annotation, maximal 20 Wörter und bestehende Satzregeln. Nur diese Freigabe erlaubt einen neuen eigenen Übungskontext; eine passende bestehende Lernkarte braucht keinen neuen Story-Kontext. `story_title_de` im ersten Satzreview erhält den gelieferten deutschen Titel ohne neue Schema-Spalte.
„The Open Pocket“ / „Die offene Tasche“: sechs gelieferte Sätze, 58 Token. Backpack in Satz 2 und platform in Satz 6 sind als eigene Lernkontexte redaktionell freigegeben; platform bedeutet Bahnsteig. Table/Ticket sind vorhandene Karten, Backpack/Platform haben keine kuratierte Karte. Alle 264 bisherigen Karten und 160 Primärplätze bleiben unverändert. Herkunft ist redaktionelle Chat-Zulieferung, keine menschliche oder Gemini-/Vertex-Prüfung.

## Schema 3: Lernziele (06.10.2026)
Additiv eine nullable `cards.learning`-Spalte (`jsonb`, SQLite JSON-Text), lokale Spiegelmigration `20261006000001_learning_groups.sql`; keine Remote-Anwendung. In Schema 3 hat jede Karte genau ein Objekt mit `group_id`, `primary_card_id`, `topic`, `related` (Liste eindeutiger Kontrasttags), `note`. Mitgliedschaft ist durch die vorhandene eindeutige Karten-ID bestimmt. Jeder Gruppen-Kopf existiert, gehört derselben Sprache/Gruppe an, verweist auf sich und ist aktiv; alle Mitglieder haben denselben Kopf. Öffnen und Export validieren diese Regeln strikt.
Schema 1/2 bleibt unterstützt; ohne Gruppendaten gilt jede Karte als Einzelziel. Karten-/Satz-/Token-/Besitz-IDs sowie historische Links bleiben erhalten. `deck_words`/`word_aliases` beschreiben weiterhin Wortbesitz und Schreibvarianten; Lerngruppen sind keine Schreibaliasse. `deckCardIds` liefert rohe Primärzuordnungen für Bestandsschutz; Repository-Summaries zählen Gruppen, der Resolver projiziert sie anhand aller vorhandenen Lernstände für Fortschritt/Queue.
Registry `pipeline/data/learning_groups/en.v1.json` bindet 764 alte Kartenreferenzen und IDs an den SHA-256 der Quelle. `learning_groups.apply_learning_groups` ergänzt ausschließlich Gruppenmetadaten sowie die explizite Kartenglosse fasten → anschnallen; Texte, Alternativen und Eigentümer bleiben gleich. Details: `learning-groups-v1.md`.
