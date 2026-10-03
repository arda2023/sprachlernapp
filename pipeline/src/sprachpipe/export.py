"""Export a pack to content.sqlite with the same tables and columns as the
Supabase schema `content` (SQLite types; jsonb and text[] as JSON text)."""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from .pack import build_rows
from .schema import COLUMNS, TABLE_ORDER, primary_key

SQLITE_TYPES = {
    "text": "TEXT", "integer": "INTEGER", "smallint": "INTEGER", "bigint": "INTEGER",
    "boolean": "INTEGER", "jsonb": "TEXT", "text[]": "TEXT", "timestamptz": "TEXT",
}


def _ddl(table: str) -> str:
    pk = primary_key(table)
    cols = ", ".join(
        f'"{name}" {SQLITE_TYPES[pg]}' + (" PRIMARY KEY" if name == pk else "")
        for name, pg in COLUMNS[table]
    )
    return f'CREATE TABLE "{table}" ({cols})'


def _value(pg_type: str, value):
    if value is None:
        return None
    if pg_type in ("jsonb", "text[]"):
        return json.dumps(value, ensure_ascii=False)
    if pg_type == "boolean":
        return int(bool(value))
    return value


def export_sqlite(pack: dict, path: str | Path) -> dict[str, int]:
    """Writes a fresh content.sqlite (an existing file is replaced) and
    returns the row count per table."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    rows = build_rows(pack)
    now = datetime.now(timezone.utc).isoformat()
    for r in rows["content_releases"]:
        r.setdefault("created_at", now)

    conn = sqlite3.connect(path)
    try:
        with conn:
            for table in TABLE_ORDER:
                conn.execute(_ddl(table))
                cols = COLUMNS[table]
                placeholders = ", ".join("?" for _ in cols)
                names = ", ".join(f'"{n}"' for n, _ in cols)
                conn.executemany(
                    f'INSERT INTO "{table}" ({names}) VALUES ({placeholders})',
                    [[_value(pg, row.get(n)) for n, pg in cols] for row in rows[table]],
                )
    finally:
        conn.close()
    return {t: len(rows[t]) for t in TABLE_ORDER}
