# sprachpipe

Offline-Content-Pipeline für Sprachapp (Python, läuft nie in der App). Details und Befehle für Windows und macOS: `docs/pipeline.md`, Abschnitte „3a Stand“ und „3b Stand“.

## Module (`src/sprachpipe/`)

| Modul | Aufgabe |
|---|---|
| `ids.py` | stabile IDs (`stable_id`), `form_norm` |
| `schema.py` | Spalten des Schemas `content` (Spiegel der Migration 2) |
| `pack.py` | Pack-JSON → Tabellenzeilen mit IDs |
| `lemmas.py` | wordfreq + spaCy → Lemmata mit Rang |
| `linter.py` | Satz-Linter (QA-Regeln) |
| `db.py` | Upsert (Dry-Run, `--publish`), `check_db` |
| `export.py` | Export nach `content.sqlite` |
| `cost.py` | Kosten-Protokoll, `check_budget` |
| `llm.py` | Vertex-AI-Wrapper: Budget-Prüfung, Wiederholung, Ledger |
| `generate.py` | Bedeutungen, Sätze, Gap-Offsets, QA-Schleife |
| `annotate.py` | Tokens + Glossen im Kontext |
| `blindtest.py` | Blindtest mit zweitem Modell |
| `review.py` | `review.csv`, `run_report.md` |
| `cli.py` | `check-db`, `lemmas`, `lint`, `upsert`, `export`, `generate` |

## Regeln

- Verbindung nur über `SUPABASE_DB_URL` in `.env` (Vorlage `.env.example`). Die URL erscheint nie in Logs.
- `upsert` schreibt nur mit `--publish`.
- KI nur über Vertex AI mit Application Default Credentials (`generate`, siehe `docs/pipeline.md`, „3b Stand“). Preise in `config.yaml` geprüft am 2026-10-03.
