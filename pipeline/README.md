# sprachpipe

Offline-Content-Pipeline für Sprachapp (Python, läuft nie in der App). Details und Befehle für Windows und macOS: `docs/pipeline.md`, Abschnitt „3a Stand“.

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
| `cli.py` | `check-db`, `lemmas`, `lint`, `upsert`, `export` |

## Regeln

- Verbindung nur über `SUPABASE_DB_URL` in `.env` (Vorlage `.env.example`). Die URL erscheint nie in Logs.
- `upsert` schreibt nur mit `--publish`. Keine KI-Aufrufe in diesem Stand.
- Preise in `config.yaml` sind leer und ungeprüft.
