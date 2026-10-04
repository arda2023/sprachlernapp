# Nutzerschema (Entwurf v1)

Gilt für Drift `user.db` **und** Supabase-Schema `app`. Im Schema `app` hat jede Tabelle zusätzlich `user_id uuid` und RLS "nur eigene Zeilen". Regeln zu Box, Fälligkeit und Zählern: `docs/srs.md`. Inhalte: `docs/content-schema.md`.

## Gemeinsame Tabellen (user.db und app)

**`user_cards`** — Lernstand je Karte (Cache, rekonstruierbar aus Erstellung + `review_log`)

| Spalte | Typ | Hinweis |
|---|---|---|
| card_id | text pk | Content-ID oder `u:` + Hash bei `local_only` (keine Kollision mit Content-IDs) |
| lang | text | Zielsprache |
| local_only | bool | Karte ohne Content-Zeile (z. B. aus Import) |
| form, gloss_de | text | nur bei `local_only` |
| box | int | 0–5 |
| due_at | timestamp | Beginn des lokalen Tages |
| created_at | timestamp | |
| origin | text | `deck` / `story` |
| disabled, retired, favorite, in_playlist | bool | |
| note | text | |
| updated_at | timestamp | für Sync |

**`card_contexts`** — eigene Sätze einer Karte (Story, Import, KI-Umschreibung)

`id` uuid, `card_id`, `text`, `translation_de`, `gap_start`, `gap_end`, `source` (`story` / `import` / `ai_rewrite`), `source_ref`, `status` (`pending` / `ok` / `rewritten` / `failed`), `is_primary` bool, `created_at`.

Eigene Kontexte haben keine geprüften Alternativen und verhalten sich wie `valid_alternatives` = leere Liste (`docs/srs.md`, Abschnitt Synonymhinweis). Unbestätigte Synonyme, etwa aus Story-Prüfung oder KI-Umschreibung, werden nicht übernommen.

**`review_log`** — Spalten wie in `docs/srs.md`. Nur anhängen; im Schema `app` nur Insert und Select. Beschlossener Zielvertrag, noch nicht migriert: zusätzliche Spalte `hint_used` bool, Standard `false`; bestehende Zeilen behalten `false`, ohne nachträglich erfundene Hinweise.

**`deck_settings`** — `deck_id`, `active` bool, `updated_at`.

**`user_imports`** — `id`, `lang`, `title`, `text`, `word_count` (≤ 5.000), `created_at`.

**`import_sentences`** — `import_id`, `idx`, `text`, `translation_de` (nullable, wird per Edge Function nachgeladen).

**`reading_progress`** — `target_kind` (`story` / `import`), `target_id`, `fraction` (0–1), `updated_at`.

**`settings`** — `daily_goal`, `target_lang`, `updated_at`. Lokal zusätzlich `device_id` (zufällige UUID, einmalig erzeugt; Quelle für `review_log.device_id`).

**Stand `user.db` Schema v1 (Paket A, `lib/data/user/user_database.dart`):** `user_cards` mit `card_id`, `lang`, `local_only`, `box`, `due_at` (null bei Box 0), `created_at`, `origin`, `disabled`, `retired`, `updated_at`; `review_log` vollständig inkl. `hint_used` (Standard `false`) und Primärschlüssel `id` = Durchgangs-ID; `deck_settings`; `settings` mit `device_id`, `target_lang`, `updated_at`. `review_log` ist per Trigger gegen `UPDATE`/`DELETE` gesperrt. `form`, `gloss_de`, `in_playlist`, `note`, `daily_goal` und die übrigen Tabellen folgen mit den Schritten, die sie nutzen (Schema-Migration).

## Nur lokal (user.db)

**`ai_jobs`** — Warteschlange für Edge-Function-Aufrufe: `type`, `payload` (JSON), `status`, `attempts`, `next_try_at`.

## Nur Server (Supabase)

**`profiles`** — `id` (= `auth.users.id`), `created_at`.

**`usage`** — `user_id`, `day`, `kind`, `units`. Schreiben nur Edge Functions.

## Sync-Regel (Entwurf)

- `review_log` und `card_contexts` werden nur angehängt und hochgeladen.
- Alle anderen Tabellen: last-write-wins nach `updated_at`.
- Sync-Zeitpunkt ist offen (`PRODUCT.md` → Open Decisions).

## Lokale Migration v1 → v2 (Übungsoberfläche)
Additiv: `user_cards.favorite` bool Standard false; `settings.motif` (`automatic`/`light`/`dark`, Standard automatic), `include_diacritics` bool Standard true, `auto_next` und `show_grammar` bool Standard false. Geräte-ID, Deck-Einstellungen, Kartenstände, Fälligkeiten und append-only Reviews bleiben erhalten. Keine Änderung am Serververtrag und kein Cloud-Aufruf.
`local_submissions`: `id` text PK, `created_at`, `body` (maximal 2000 Grapheme), `category` nullable, `rating` nullable (1–5), `card_id`, `sentence_id`, `pack_version` nullable. Problemberichte enthalten Kategorie und Inhaltsreferenzen; Feedback eine Bewertung. Nur lokales Speichern und expliziter nativer Export. Keine vollständigen Lernverläufe oder Zugangsdaten.
