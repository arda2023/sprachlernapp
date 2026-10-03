# Inhaltsschema (Entwurf v0)

Gilt für Supabase Schema `content` und, gleich, für `content.sqlite` je Sprache. Die App liest nur. Lernzustand steht in `user.db` (`docs/srs.md`) und verweist über `card_id` auf `cards.id`.

## IDs und Tombstones

- `id` = Hash des normalisierten Inhalts: Hex der ersten 16 Byte von SHA-256 über die kanonische Zeichenfolge der Schlüsselfelder (Unicode NFC, Kleinschreibung wo sinnvoll, Felder mit `\u001f` getrennt). Gleicher Inhalt ergibt dieselbe ID, der Import ist idempotent.
- IDs werden **nie wiederverwendet**. Ändert sich ein Schlüsselfeld, entsteht eine neue ID.
- Entfernte Zeilen bleiben als **Tombstone** (`removed_in` = Release-Version, optional `replaced_by`). Sie werden nicht gelöscht, damit `user.db` weiter auflösen kann.
- Alle Tabellen tragen `lang` (Zielsprache) und, wo Glossen vorkommen, `gloss_lang` (v1: `de`).
- `literal values`: Formen wie `null`, `true`, `false` immer als Text behandeln.

## Tabellen

| Tabelle | Schlüsselfelder → id | Weitere Spalten |
|---|---|---|
| `languages` | `code` (pk) | `name_native`, `name_de`, `gloss_lang` |
| `lemmas` | `lang`, `lemma`, `pos` | `family_key`, `freq_rank` |
| `senses` | `lemma_id`, `gloss_de`, `pos` | `sense_index`, `definition_de`, `notes_de` |
| `cards` | `lang`, `form`, `sense_id` | `lemma_id`, `pos`, `form_kind`, `form_label_de`, `translation_de`, `cefr_band`, `freq_rank` |
| `dictionary_forms` | `lang`, `form_norm`, `sense_id` | `card_id` (null, wenn keine Karte), `gloss_de`, `rank` |
| `decks` | `lang`, `slug` | `title_de`, `description_de`, `cefr_band`, `icon`, `sort` |
| `deck_cards` | `deck_id`, `card_id` | `position` |
| `sentences` | `lang`, `text` | `translation_de`, `origin` (deck / story / exercise), `model`, `qa_status`, `qa_report` |
| `sentence_tokens` | `sentence_id`, `idx` | `start`, `end`, `surface`, `lemma_id`, `sense_id`, `card_id` |
| `card_sentences` | `card_id`, `sentence_id` | `position` (1–3), `gap_start`, `gap_end`, `accepted[]` |
| `stories` | `lang`, `slug` | `title`, `kind` (story / text), `cefr_band`, `topic`, `minutes`, `cover` |
| `story_sentences` | `story_id`, `idx` | `sentence_id`, `paragraph_idx`, `heading` |
| `exercises` | `lang`, `kind`, `slug` | `title`, `cefr_band`, `payload` (JSON je Art: Lückentext, Hören, Grammatik) |
| `audio_assets` | `owner_kind`, `owner_id`, `voice`, `model` | `path` (relativ zur Audio-Basis-URL), `sha256`, `duration_ms` |
| `content_releases` | `lang`, `version` | `schema_version`, `created_at`, `sha256`, `size_bytes`, `notes` |

## Regeln

- **Karte**: eine exakte Form in einer Bedeutung. Lemma und Familie verbinden Karten nur über `lemma_id` ("Andere Formen", Erkennung falscher Formen), verschmelzen nie.
- **Sätze je Karte**: genau 3 Zeilen in `card_sentences`; jeder Satz enthält genau diese Form an `gap_start`–`gap_end` (Zeichen-Offsets in `sentences.text`). `accepted[]` listet erlaubte Antworten (Normalfall: nur die Form selbst).
- **Wörterbuch** (Schicht 1): `dictionary_forms`. **Token-Annotation** (Schicht 2): `sentence_tokens`. **Satzübersetzung** (Schicht 3): `sentences.translation_de`.
- `cefr_band` ∈ `anfaenger` (A1–A2), `mittel` (B1–B2), `fortgeschritten` (C1–C2).
- `audio_assets.path` ist relativ. Die Basis-URL liegt in der Konfiguration (`docs/backend.md`).
- `content_releases` verweist auf den Export `packs/<lang>/<version>/content.sqlite`.

## Offen

- Grammatikregeln und Nachrichten (Schema folgt, wenn entschieden).
- Genaue Kanonisierung je Tabelle (Feldreihenfolge) wird mit dem ersten Import festgeschrieben.
