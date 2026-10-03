# NEXTSTEPS

## Erledigt (Stand 2026-10-03, Pipeline 3a)
- `pipeline/`: venv, gepinnte Abhängigkeiten, Module ids, schema, pack, lemmas, linter, db, export, cost, cli; Fixture `mini_pack.json` (went; left = verließ / links als 2 Karten).
- Doku: `docs/content-schema.md` (Abschnitt Kanonisierung, `start_pos`/`end_pos`, `lang` nach Migration), `docs/pipeline.md` (Abschnitt „3a Stand“).

## Geänderte Dateien
`pipeline/` (neu), `docs/content-schema.md`, `docs/pipeline.md`, `NEXTSTEPS.md`.

## Testergebnis
- `pytest`: 43 passed.
- Lokale DB (`supabase db reset`, 2× `upsert --publish`): Zeilenzahlen in beiden Läufen identisch (u. a. cards 3, sentences 9, sentence_tokens 62).
- `export`: content.sqlite mit 16 Tabellen; Join cards → card_sentences → sentences liefert 9 Zeilen.
- `lemmas`: 60 Lemmata. `lint` auf das Fixture: 0 Fehler.

## Abweichungen
- Python 3.11 statt 3.12 (3.12 nicht installiert; vorhanden 3.9, 3.11, 3.14).
- ID-Kanonisierung nimmt den Tabellennamen als erstes Feld (vermeidet gleiche IDs bei decks/stories/grammar_rules).
- i+1-Regel läuft nur mit `--lemmas <json>`; ohne Rangliste wird sie übersprungen.
- `pipeline/.gitignore` statt Root-`.gitignore` für `.venv/` und `out/`.

## Offene Probleme
- spaCy ohne Kontext: `about`/`up`/`out` als ADV, `best`/`better` unter `well`.
- Funktionswörter: offene Entscheidung (`docs/pipeline.md`). Preise in `config.yaml` leer (3b).
- content.sqlite ohne Indizes außer Primärschlüsseln; Tombstone-Übernahme noch nicht implementiert.
