# Inhaltsschema (Entwurf v1)

Gilt für Supabase Schema `content` und, gleich, für `content.sqlite` je Sprache. Die App liest nur. Lernzustand steht in `user.db` (`docs/user-schema.md`) und verweist über `card_id` auf `cards.id`.

## Master und IDs

- **Supabase Schema `content` ist der Master.** `content.sqlite` ist ein Export daraus.
- `id` = Hash des normalisierten Schlüssels: Hex der ersten 16 Byte von SHA-256 über die Schlüsselfelder (Unicode NFC, Felder mit `\u001f` getrennt).
- IDs werden **beim ersten Upsert berechnet und danach nie neu berechnet**. Eine gespeicherte ID gilt, auch wenn sich die Hash-Regel später ändert.
- **Schlüssel enthalten nur unveränderliche Felder.** Korrekturen an Glossen, Übersetzungen oder Labels ändern nie eine ID; sie sind normale Spalten.
- IDs werden **nie wiederverwendet**.
- Alle Tabellen tragen `lang` (Zielsprache) und, wo Glossen vorkommen, `gloss_lang` (v1: `de`).
- Formen wie `null`, `true`, `false` immer als Text behandeln.

## Normalisierung `form_norm`

Unicode NFC, Kleinschreibung, `’` → `'`, sonst unverändert (keine Akzententfernung, keine Lemmatisierung).

## Tombstones

- Entfernte Zeilen bleiben als **Tombstone** (`removed_in` = Release-Version, optional `replaced_by` = neue ID). Sie werden nie gelöscht.
- Beim Import übernimmt die App den Lernstand entlang der `replaced_by`-Kette (A → B → C: der Stand von A landet bei C).
- Eine Karte ohne Ersatz wird in `user.db` auf `retired = true` gesetzt: raus aus Queues und Zählern, der Verlauf (`review_log`) bleibt.

## Tabellen

| Tabelle | Schlüssel → id | Weitere Spalten |
|---|---|---|
| `languages` | `code` (pk) | `name_native`, `name_de`, `gloss_lang` |
| `lemmas` | `lang`, `lemma`, `pos` | `family_key`, `freq_rank` |
| `senses` | `lemma_id`, `sense_key` | `gloss_de`, `definition_de`, `notes_de`, `sense_index` |
| `cards` | `lang`, `form`, `sense_id` | `form_norm`, `lemma_id`, `pos`, `form_kind`, `form_label_de`, `translation_de`, `cefr_band`, `freq_rank`, `is_multiword` |
| `dictionary_forms` | `lang`, `form_norm`, `sense_id` | `card_id` (null, wenn keine Karte), `gloss_de`, `rank` |
| `decks` | `lang`, `slug` | `title_de`, `description_de`, `cefr_band`, `icon`, `sort` |
| `deck_cards` | `deck_id`, `card_id` | `position` |
| `sentences` | `lang`, `text` | `origins` (Menge: deck / story / exercise), `translation_de`, `model`, `qa_status`, `qa_report` |
| `sentence_tokens` | `sentence_id`, `idx` | `start`, `end`, `surface`, `lemma_id`, `sense_id`, `card_id` |
| `card_sentences` | `card_id`, `sentence_id` | `position` (1–3), `gap_start`, `gap_end`, `accepted[]` |
| `stories` | `lang`, `slug` | `title`, `kind` (story / text), `cefr_band`, `topic`, `minutes`, `cover` |
| `story_sentences` | `story_id`, `idx` | `sentence_id`, `paragraph_idx`, `heading` |
| `exercises` | `lang`, `kind`, `slug` | `title`, `cefr_band`, `payload` (JSON je Art: Lückentext, Hören, Grammatik) |
| `grammar_rules` | `lang`, `slug` | `title_de`, `summary_de`, `cefr_band`, `sections` (JSON) |
| `audio_assets` | `owner_kind`, `owner_id`, `voice`, `model` | `path` (relativ zur Audio-Basis-URL), `sha256`, `duration_ms` |
| `content_releases` | `lang`, `version` | `schema_version`, `created_at`, `sha256`, `size_bytes`, `notes` |

Alle Tabellen außer `languages` und `content_releases` haben zusätzlich `removed_in` und `replaced_by`.

## Regeln

- **Karte**: eine exakte Form in einer Bedeutung. Lemma und Familie verbinden Karten nur über `lemma_id` ("Andere Formen", Erkennung falscher Formen), verschmelzen nie.
- **`sense_key`**: stabiler Slug je Lemma, z. B. `bank#ufer`. Einmal vergeben, nie geändert.
- **Mehrwort-Karten** (Redewendungen, Verbalphrasen): `form` darf mehrere Wörter enthalten; die Lücke ist eine zusammenhängende Zeichenspanne. Trennbare Formen ("pick it up") werden in v1 nicht erzeugt.
- **Sätze je Karte**: genau 3 Zeilen in `card_sentences`; jeder Satz enthält genau diese Form an `gap_start`–`gap_end` (Zeichen-Offsets in `sentences.text`). `accepted[]` listet erlaubte Antworten (Normalfall: nur die Form selbst).
- **Satzkorrektur**: Der Text ist Schlüssel, eine Korrektur ergibt eine neue ID plus Tombstone der alten Zeile mit `replaced_by`. `origins` ist nicht Teil des Schlüssels.
- **Wörterbuch** (Schicht 1): `dictionary_forms`. **Token-Annotation** (Schicht 2): `sentence_tokens`. **Satzübersetzung** (Schicht 3): `sentences.translation_de`.
- `cefr_band` ∈ `anfaenger` (A1–A2), `mittel` (B1–B2), `fortgeschritten` (C1–C2).
- `audio_assets.path` ist relativ. Die Basis-URL liegt in der Konfiguration (`docs/backend.md`).
- `content_releases` verweist auf den Export `packs/<lang>/<version>/content.sqlite`.

## Offen

- Nachrichten (Schema folgt, wenn entschieden).
- Feldreihenfolge der Kanonisierung je Tabelle wird mit dem ersten Upsert festgeschrieben.
