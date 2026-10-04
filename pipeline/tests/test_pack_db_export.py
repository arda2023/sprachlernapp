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


def with_alternatives(pack):
    new = json.loads(json.dumps(pack))
    new["card_sentences"][0]["valid_alternatives"] = ["headed", "more or less"]
    return new


def test_old_pack_without_field_gets_empty_list(pack):
    assert all("valid_alternatives" not in cs for cs in pack["card_sentences"])
    rows = build_rows(pack)["card_sentences"]
    assert rows and all(r["valid_alternatives"] == [] for r in rows)


def test_alternatives_survive_build_and_sqlite_export(pack, tmp_path):
    new = with_alternatives(pack)
    rows = build_rows(new)["card_sentences"]
    assert rows[0]["valid_alternatives"] == ["headed", "more or less"]
    assert rows[0]["accepted"] == ["went"]
    target = tmp_path / "content.sqlite"
    export_sqlite(new, target)
    con = sqlite3.connect(target)
    try:
        stored = dict(con.execute("select id, valid_alternatives from card_sentences").fetchall())
        accepted = dict(con.execute("select id, accepted from card_sentences").fetchall())
        assert "valid_alternatives" in [c[1] for c in con.execute("pragma table_info(card_sentences)")]
    finally:
        con.close()
    assert json.loads(stored[rows[0]["id"]]) == ["headed", "more or less"]
    assert sorted(json.loads(v) for k, v in stored.items() if k != rows[0]["id"]) == [[]] * 8
    assert json.loads(accepted[rows[0]["id"]]) == ["went"]


def test_ids_unchanged_with_and_without_alternatives(pack):
    old, new = build_rows(pack), build_rows(with_alternatives(pack))
    for table in old:
        assert [r.get("id", r.get("code")) for r in old[table]] == [
            r.get("id", r.get("code")) for r in new[table]]
    assert upsert_pack(None, pack) == upsert_pack(None, with_alternatives(pack))


@pytest.mark.parametrize("value", [None, "headed", ["headed", None], [1], ["Headed"], [" headed"],
                                   [""], ["headed", "headed"], ["went"]])
def test_invalid_alternatives_are_rejected(pack, value):
    bad = json.loads(json.dumps(pack))
    bad["card_sentences"][0]["valid_alternatives"] = value
    with pytest.raises(ValueError, match="valid_alternatives"):
        build_rows(bad)
