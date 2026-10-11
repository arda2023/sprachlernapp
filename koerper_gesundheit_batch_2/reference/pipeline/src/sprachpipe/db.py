"""Writes packs into the Supabase schema `content` (the master).

- The connection string comes only from SUPABASE_DB_URL (pipeline/.env).
  It never appears in logs or error messages.
- upsert_pack() is a dry run unless publish=True; with publish it writes all
  tables in foreign-key order in ONE transaction:
  INSERT ... ON CONFLICT (id) DO UPDATE. Running it twice changes nothing.
"""

from __future__ import annotations

import os

from .pack import build_rows
from .schema import COLUMNS, TABLE_ORDER, primary_key

ENV_VAR = "SUPABASE_DB_URL"


class DbError(RuntimeError):
    """Database error with a message that never contains the connection string."""


def connect(url: str | None = None, *, read_only: bool = False):
    import psycopg

    url = url or os.environ.get(ENV_VAR)
    if not url:
        raise DbError(f"{ENV_VAR} is not set (pipeline/.env)")
    try:
        conn = psycopg.connect(url, connect_timeout=5)
    except psycopg.Error as e:
        # psycopg messages may echo host or user; report only the error class.
        raise DbError(f"connection failed ({type(e).__name__}); check {ENV_VAR}") from None
    conn.read_only = read_only
    return conn


def _adapt(table: str, row: dict) -> dict:
    from psycopg.types.json import Jsonb

    types = dict(COLUMNS[table])
    return {k: Jsonb(v) if types[k] == "jsonb" and v is not None else v for k, v in row.items()}


def _upsert_sql(table: str, columns: list[str]):
    from psycopg import sql

    pk = primary_key(table)
    updates = [c for c in columns if c != pk]
    return sql.SQL(
        "insert into content.{t} ({cols}) values ({vals}) "
        "on conflict ({pk}) do update set {sets}"
    ).format(
        t=sql.Identifier(table),
        cols=sql.SQL(", ").join(map(sql.Identifier, columns)),
        vals=sql.SQL(", ").join(sql.Placeholder(c) for c in columns),
        pk=sql.Identifier(pk),
        sets=sql.SQL(", ").join(
            sql.SQL("{c} = excluded.{c}").format(c=sql.Identifier(c)) for c in updates
        ),
    )


def upsert_pack(conn, pack: dict, *, publish: bool = False) -> dict[str, int]:
    """Row counts per table. Writes only with publish=True."""
    rows = build_rows(pack)
    counts = {t: len(rows[t]) for t in TABLE_ORDER if rows[t]}
    if not publish:
        return counts
    try:
        with conn.transaction():
            with conn.cursor() as cur:
                for table in TABLE_ORDER:
                    for row in rows[table]:
                        cur.execute(_upsert_sql(table, list(row)), _adapt(table, row))
    except Exception as e:  # noqa: BLE001 – re-raised without the URL
        raise DbError(f"upsert failed: {type(e).__name__}: {e}") from None
    return counts


def table_counts(conn) -> dict[str, int]:
    from psycopg import sql

    counts = {}
    with conn.cursor() as cur:
        for table in TABLE_ORDER:
            cur.execute(sql.SQL("select count(*) from content.{}").format(sql.Identifier(table)))
            counts[table] = cur.fetchone()[0]
    return counts


def check_db(conn) -> dict[str, int]:
    """Read-only: `select 1` and a row count per content table."""
    with conn.cursor() as cur:
        cur.execute("select 1")
        cur.fetchone()
    counts = table_counts(conn)
    conn.rollback()
    return counts
