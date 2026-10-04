"""Export a pack to content.sqlite with the same tables and columns as the
Supabase schema `content` (SQLite types; jsonb and text[] as JSON text)."""

from __future__ import annotations

import json
import os
import sqlite3
import tempfile
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
    """Writes a fresh content.sqlite and returns the row count per table.
    The database is built in a temporary file next to [path] and replaces an
    existing file only after a complete write; on any error [path] stays as
    it was and the error propagates."""
    path = Path(path)
    rows = build_rows(pack)   # validation before the target is touched
    now = datetime.now(timezone.utc).isoformat()
    for r in rows["content_releases"]:
        r.setdefault("created_at", now)

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    os.close(fd)
    tmp = Path(tmp_name)
    try:
        conn = sqlite3.connect(tmp)
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
            conn.close()   # Windows: no own handle may stay open before replace
        os.replace(tmp, path)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise
    return {t: len(rows[t]) for t in TABLE_ORDER}
