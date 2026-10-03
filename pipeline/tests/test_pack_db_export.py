import json
import sqlite3
from pathlib import Path

import pytest

from sprachpipe.db import DbError, connect, upsert_pack
from sprachpipe.export import export_sqlite
from sprachpipe.pack import build_rows

FIXTURE = Path(__file__).parent / "fixtures" / "mini_pack.json"


@pytest.fixture
def pack():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def test_left_is_two_cards(pack):
    cards = build_rows(pack)["cards"]
    left = [c for c in cards if c["form"] == "left"]
    assert len(left) == 2
    assert left[0]["id"] != left[1]["id"]
    assert left[0]["sense_id"] != left[1]["sense_id"]


def test_every_card_has_three_sentences_containing_the_form(pack):
    rows = build_rows(pack)
    texts = {s["id"]: s["text"] for s in rows["sentences"]}
    forms = {c["id"]: c["form"] for c in rows["cards"]}
    per_card = {}
    for cs in rows["card_sentences"]:
        per_card.setdefault(cs["card_id"], []).append(cs)
        assert texts[cs["sentence_id"]][cs["gap_start"]:cs["gap_end"]] == forms[cs["card_id"]]
    assert sorted(len(v) for v in per_card.values()) == [3, 3, 3]


def test_build_is_deterministic(pack):
    assert build_rows(pack) == build_rows(json.loads(json.dumps(pack)))


def test_dry_run_needs_no_connection(pack):
    counts = upsert_pack(None, pack)
    assert counts["cards"] == 3
    assert counts["sentence_tokens"] == 62
    assert counts["content_releases"] == 1


def test_connection_error_hides_url(monkeypatch):
    secret = "postgresql://pipeline:topsecretpw@127.0.0.1:1/postgres"
    with pytest.raises(DbError) as exc:
        connect(secret)
    text = str(exc.value) + repr(exc.value.__cause__) + repr(exc.value.__context__)
    assert "topsecretpw" not in text
    assert secret not in text


def test_missing_env_var(monkeypatch):
    monkeypatch.delenv("SUPABASE_DB_URL", raising=False)
    with pytest.raises(DbError, match="SUPABASE_DB_URL is not set"):
        connect()


def test_export_sqlite(pack, tmp_path):
    target = tmp_path / "content.sqlite"
    counts = export_sqlite(pack, target)
    assert counts["cards"] == 3 and counts["content_releases"] == 1
    con = sqlite3.connect(target)
    try:
        for table, n in counts.items():
            assert con.execute(f'select count(*) from "{table}"').fetchone()[0] == n
        rows = con.execute(
            """select c.form, s.text, cs.position, cs.accepted
               from cards c
               join card_sentences cs on cs.card_id = c.id
               join sentences s on s.id = cs.sentence_id
               where c.form = 'left' order by c.id, cs.position"""
        ).fetchall()
        assert len(rows) == 6
        assert all(json.loads(r[3]) == ["left"] for r in rows)
        release = con.execute("select version, created_at from content_releases").fetchone()
        assert release[0] == "0.0.0-fixture" and release[1]
    finally:
        con.close()
