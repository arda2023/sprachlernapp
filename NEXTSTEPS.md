# NEXTSTEPS

## Erledigt (Stand 2026-10-03)
- Supabase lokal: `supabase init`, `config.toml` (E-Mail-Bestätigung an, anonym aus, API-Schemas + `app`, nicht `content`, `health` mit `verify_jwt = true`).
- Migrationen 1–4: Schemas, `content`-Tabellen (RLS ohne Policies), `app`-Tabellen (RLS nur eigene Zeilen, `review_log` append-only per Trigger, `profiles`-Trigger), Storage-Buckets `audio`/`packs` (öffentlich), `imports` (privat, eigener Ordner).
- pgTAP-Tests (11), Edge Function `health`, `.env.example`, `.gitignore`, `docs/backend.md` (Lokale Entwicklung, Deploy).

## Geänderte Dateien
`supabase/` (config.toml, .gitignore, migrations/4, tests/database/security.test.sql, functions/health/index.ts), `.env.example`, `.gitignore`, `docs/backend.md`, `NEXTSTEPS.md`.

## Testergebnis
- `supabase db reset`: exit 0. `supabase test db`: Files=1, Tests=11, PASS.
- `health` mit lokalem Anon-Key: `{"ok":true,...}`; ohne JWT: HTTP 401.
- Schlüssel-Suche über alle nicht ignorierten Dateien: keine Treffer.

## Abweichungen
- `sentence_tokens.start/end` heißen `start_pos/end_pos` (`end` ist reserviert).
- `profiles` hat `id` statt `user_id` (wie `docs/user-schema.md`).
- Join-Tabellen (`deck_cards`, `card_sentences`, `story_sentences`, `sentence_tokens`) ohne `lang`.
- `git status` zeigt noch `DESIGN.md`, `docs/srs.md`, `docs/content-schema.md`, `docs/user-schema.md` aus dem vorigen Auftrag (uncommitted).
- `supabase/.temp/` enthält von der CLI erzeugte lokale Demo-Keys; per `supabase/.gitignore` und `.gitignore` ignoriert.

## Offen
- Deploy durch Arda (`link`, `db push --dry-run`, `db push`, `functions deploy health`).
- `docker` fehlt im PATH der PowerShell-Sitzung; Supabase CLI 2.118.0 (2.119.0 verfügbar).
