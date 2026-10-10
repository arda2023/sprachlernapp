# Nutzerschema (Entwurf v1)

Der gemeinsame Entwurf gilt für Drift `user.db` und Supabase-Schema `app`; die unten ausdrücklich beschriebenen lokalen Migrationen sind kein angewendeter Serververtrag. Im Schema `app` hat jede Tabelle zusätzlich `user_id uuid` und RLS "nur eigene Zeilen". Regeln zu Box, Fälligkeit und Zählern: `docs/srs.md`. Inhalte: `docs/content-schema.md`.

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

Eigene Kontexte haben keine geprüften Alternativen und verhalten sich wie `valid_alternatives` = leere Liste (`docs/srs.md`, Abschnitt Neutrale Synonymversuche). Unbestätigte Synonyme, etwa aus Story-Prüfung oder KI-Umschreibung, werden nicht übernommen.

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

## Lokale Migration v2 → v3 (gemeinsamer Lernstand)
Additiv: `user_cards.note` text Standard leer, `user_cards.in_playlist` bool Standard false und `settings.daily_goal` int Standard 10. Favorit/Deaktivierung verwenden weiterhin die bestehenden Felder. Wortform, Übersetzung und Beispielsatz werden aus dem Content-Repository aufgelöst; unbekannte alte IDs bleiben unverändert gespeichert, erscheinen aber nicht mit erfundenen Texten in der Wortliste. Keine gespeicherten Vokabelzähler. Migration von v1 berücksichtigt weiterhin v2; bestehende Karten, Reviews, Geräte-ID und Einstellungen bleiben erhalten. Playlist ist nur die persistierte Auswahl; Audio bleibt außerhalb dieser Integration.

## Lokale Migration v3 → v4 (Story-Lernen, umgesetzt 04.10.2026)
Migration auch ab v1/v2 additiv; keine Zeilen werden zusammengeführt oder nach Schreibweise gebunden. Alte Werte, Review-IDs, Geräte-ID und Review-Trigger bleiben erhalten.

- `user_cards`: nullable `form`, `form_norm`, `gloss_de`, `lemma`, `pos`, `lemma_identity`, `sense_identity`, `sense_key`, `primary_context_id`. Nur neue lokale Karten benötigen diese Metadaten. Kuratierte Karten behalten ihre Inhalte in `content.sqlite`.
- `card_contexts`: `id` UUID PK, `card_id`, `text_value`, `translation_de`, `gap_start`, `gap_end` (UTF-16), `source_ref` (Story-ID), `sentence_ref`, `token_index`, `revision`, `fingerprint` UNIQUE, `tokens_json`, `other_forms_json`, `lang`, `provenance`, `created_at`. Nur freigegebene Kontexte werden angelegt; kein pending-Erfolg. UPDATE/DELETE sind per Trigger gesperrt. `primary_context_id` ersetzt den früheren unimplementierten `is_primary`-Entwurf; keine Kontextwahl-Oberfläche.
- `story_learning_additions`: `card_id` PK, `added_at`. Explizite Lernentscheidung unabhängig vom ursprünglichen `origin`.
- `story_word_sources`: zusammengesetzter PK (`card_id`, `fingerprint`), `source_ref`, `sentence_ref`, `token_index`, `revision`, `added_at`. Fingerprint bindet genaue Quelle, Satz, Übersetzung, Tokenstelle und Identität. Wiederholte Adds ändern keine ursprünglichen Zeitpunkte.
- `learning_identity_bindings`: `identity_key` PK, `lang`, `form_norm`, `semantic_anchor`, `card_id`; zusätzlich UNIQUE (`lang`, `form_norm`, `semantic_anchor`). Anker ist die belegte stabile Sense-ID. Neue lokale ID: `u:` + SHA256 über JSON `["local-card-v1", lang, form_norm, semantic_anchor]`.

Karte, erster Kontext, Bindung, Quelle und Lernentscheidung werden in einer Transaktion gespeichert. INSERT OR IGNORE dient nur idempotenten Entscheidungen/Bindungen; kein INSERT OR REPLACE. Konflikt nach paralleler Bindung führt zum Rollback. Kein Review beim Add. Lokale Reviews referenzieren `card_contexts.id`; akzeptierte Zielantwort ist die exakte Form, `valid_alternatives` bleibt leer. Unvollständige alte lokale Karten bleiben erhalten und werden als nicht verfügbar ausgewiesen.

## Gruppen und neutrale Synonyme (06.10.2026)
Keine neue user.db-Version und keine Migration vorhandener Lernstände. Gruppen leben ausschließlich in Content-Schema 3. Eigene Karten werden zur Laufzeit nur über belegte Sprache + form_norm + sense_identity zugeordnet. Alle alten Zustände, Favoriten, Notizen, Zeitpunkte und Reviews bleiben getrennt erhalten.
Story-Add reserviert das bestehende Gruppenziel oder den Kopf atomar und idempotent. `story_word_sources` belegt die tatsächlich angetippte Quelle; sie muss nicht die Form des ausgewählten Übungsziels enthalten. In diesem Fall wird dessen vorhandener geprüfter Satz verwendet. Eine Gruppenweiterleitung schreibt **keine** falsche `learning_identity_bindings`-Gleichsetzung für unterschiedliche Formen/Bedeutungen.
Neue neutrale Synonymversuche setzen `hint_used` nicht; `first_attempt_correct` überspringt diese Versuche. Historische Hilfeflags bleiben unverändert; weder Neubewertung noch Umschreiben alter Reviews. Regeln: `srs.md`, Nachweise: `learning-groups-v1.md`.
