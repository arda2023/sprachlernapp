import re
from datetime import datetime, timezone
from pathlib import Path

import pytest

from sprachpipe.config import load_config
from sprachpipe.cost import BudgetExceeded, append_entry, check_budget, total_usd
from sprachpipe.schema import COLUMNS

MIGRATION = (Path(__file__).resolve().parents[2]
             / "supabase" / "migrations" / "20261003000002_content_tables.sql")


def fake(ledger, usd):
    append_entry(ledger, step="sentences", model="fake-model", input_tokens=100,
                 output_tokens=50, thinking_tokens=20, usd=usd,
                 time=datetime(2026, 10, 3, tzinfo=timezone.utc))


def test_ledger_appends_and_sums(tmp_path):
    ledger = tmp_path / "ledger.csv"
    fake(ledger, 0.25)
    fake(ledger, 0.50)
    lines = ledger.read_text(encoding="utf-8").splitlines()
    assert lines[0] == "time,step,model,input_tokens,output_tokens,thinking_tokens,usd"
    assert len(lines) == 3
    assert total_usd(ledger) == pytest.approx(0.75)


def test_budget(tmp_path):
    ledger = tmp_path / "ledger.csv"
    fake(ledger, 0.75)
    assert check_budget(1.0, ledger) == pytest.approx(0.75)
    with pytest.raises(BudgetExceeded):
        check_budget(1.0, ledger, next_usd=0.30)
    with pytest.raises(BudgetExceeded):
        check_budget(0.5, ledger)


def test_price_table_is_checked():
    cfg = load_config()
    prices = cfg["prices"]
    assert prices["status"] == "geprüft"
    assert prices["as_of"] and prices["source"].startswith("https://")
    for model in (cfg["llm"]["generate_model"], cfg["llm"]["blindtest_model"]):
        assert {"input_per_mtok_usd", "output_per_mtok_usd",
                "thinking_per_mtok_usd"} <= set(prices["models"][model])


def test_schema_matches_migration():
    sql = MIGRATION.read_text(encoding="utf-8")
    found = {}
    for name, body in re.findall(r"create table content\.(\w+) \((.*?)\n\);", sql, re.S):
        cols = []
        for line in body.splitlines():
            word = line.strip().split(" ")[0]
            if word and word not in ("unique", "check", "primary", "--"):
                cols.append(word)
        found[name] = cols
    assert found == {t: [c for c, _ in cols] for t, cols in COLUMNS.items()}
