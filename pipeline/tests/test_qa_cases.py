"""Fixed live QA cases: fixture consistency and offline proof that the
diagnosis compares actual verdicts. Simulated answers prove processing, not
live quality."""

import importlib.util
import json
import re
from pathlib import Path

import pytest

from sprachpipe.config import PIPELINE_DIR, load_config
from sprachpipe.cost import BudgetExceeded
from sprachpipe.generate import gap_offsets
from sprachpipe.inventory import MeaningInventory

SCRIPT = PIPELINE_DIR / "scripts" / "check_qa_cases.py"
spec = importlib.util.spec_from_file_location("check_qa_cases", SCRIPT)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)
CASES = script.load_cases()


class FakeLlm:
    """Answers with given verdicts; records every prompt."""
    def __init__(self, language=None, alternatives=None, fail_after=None):
        self.language = language or {}
        self.alternatives = alternatives or {}
        self.fail_after = fail_after
        self.prompts = []

    def generate_json(self, prompt, schema, *, step, **kwargs):
        if self.fail_after is not None and len(self.prompts) >= self.fail_after:
            raise BudgetExceeded("limit")
        self.prompts.append(prompt)
        if step == "meaning_check":
            text = re.search(r"^Sentence: (.+)$", prompt, flags=re.M).group(1)
            keys = schema["properties"]["sense_key"]["anyOf"][0]["enum"]
            return {"sense_key": keys[0], "observed_pos": "ADJ", "translation_ok": True,
                    "language_ok": self.language[text], "reason": "Simuliert."}
        found = re.findall(r'^(\d+)\. inserted: "(.*)" -> ', prompt, flags=re.M)
        return {"results": [{"candidate_index": int(i), "valid": self.alternatives[c],
                             "reason": "Simuliert."} for i, c in found]}


def expected_llm(**overrides):
    language = {c["text"]: c["expected"]["language_ok"] for c in CASES["meaning_cases"]}
    alternatives = {}
    for case in CASES["alternative_cases"]:
        alternatives.update(case["expected"])
    language.update(overrides.get("language", {}))
    alternatives.update(overrides.get("alternatives", {}))
    return FakeLlm(language, alternatives)


def run(fake):
    saved = []
    inventory = MeaningInventory("en")
    results, aborted = script.run_cases(fake, load_config(), CASES, inventory,
                                        lambda r: saved.append(len(r)))
    return results, aborted, saved


def test_fixture_cases_are_complete_and_consistent():
    inventory = MeaningInventory("en")
    texts = {c["text"] for c in CASES["meaning_cases"]}
    for required in ("The sun is too light.", "Maya checks her dress in the sun light.",
                     "The room is light and airy.",
                     "Maya reads her book in the light from the window."):
        assert required in texts
    for case in CASES["meaning_cases"] + CASES["alternative_cases"]:
        card = case["card"]
        assert case["text"] and case["translation_de"] and case["expected"]
        found = {m["sense_key"]: m for m in inventory.get(card["form"])}
        assert found[card["sense_key"]]["pos"] == card["pos"]
        assert gap_offsets(case["text"], card["form"]) is not None
    for case in CASES["meaning_cases"]:
        assert set(case["expected"]) == {"language_ok"}
        assert type(case["expected"]["language_ok"]) is bool
    for case in CASES["alternative_cases"]:
        assert tuple(case["gap"]) == gap_offsets(case["text"], case["card"]["form"])
        assert set(case["expected"]) == set(case["candidates"])
    about = next(c for c in CASES["alternative_cases"] if c["id"] == "C_about_ten_years")
    assert about["expected"] == {"around": True, "approximately": True,
                                 "nearly": False, "almost": False}
    assert not any("Rosa" in c["text"] for c in CASES["alternative_cases"])


def test_fixture_never_in_content_packs():
    texts = {c["text"] for c in CASES["meaning_cases"] + CASES["alternative_cases"]}
    pack = json.loads((Path(__file__).parent / "fixtures" / "mini_pack.json").read_text(encoding="utf-8"))
    assert not texts & {s["text"] for s in pack["sentences"]}


def test_all_expected_verdicts_pass_and_expectations_never_reach_model():
    fake = expected_llm()
    results, aborted, saved = run(fake)
    assert aborted is None and all(r["passed"] for r in results)
    n_alt = sum(len(c["candidates"]) for c in CASES["alternative_cases"])
    assert len(results) == len(CASES["meaning_cases"]) + n_alt
    # one call per meaning case and one bundled call per alternative case
    assert len(fake.prompts) == len(CASES["meaning_cases"]) + len(CASES["alternative_cases"])
    for prompt in fake.prompts:
        assert "expected" not in prompt and "finding" not in prompt
        assert not any(c["id"] in prompt for c in CASES["meaning_cases"] + CASES["alternative_cases"])
    assert saved == sorted(saved) and saved[-1] == len(results)


def test_deviations_are_detected_from_actual_verdicts():
    fake = expected_llm(language={"The sun is too light.": True,
                                  "The room is light and airy.": False},
                        alternatives={"nearly": True, "around": False})
    results, aborted, _ = run(fake)
    failed = {r["id"] for r in results if not r["passed"]}
    assert aborted is None
    assert failed == {"sun_too_light_short", "room_light_and_airy",
                      "C_about_ten_years:nearly", "C_about_ten_years:around"}
    row = next(r for r in results if r["id"] == "sun_too_light_short")
    assert row["actual"]["language_ok"] is True and row["expected"] == {"language_ok": False}


def test_invalid_answer_is_a_deviation():
    class Broken(FakeLlm):
        def generate_json(self, prompt, schema, *, step, **kwargs):
            result = expected_llm().generate_json(prompt, schema, step=step, **kwargs)
            if step == "meaning_check":
                del result["language_ok"]
            return result
    results, _, _ = run(Broken())
    meaning = [r for r in results if r["kind"] == "meaning_check"]
    assert meaning and not any(r["passed"] for r in meaning)
    assert all(r["reason"].startswith("Ungültige Prüfantwort:") for r in meaning)


def patch_llm(monkeypatch, fake):
    created = []
    def factory(cfg, ledger, max_usd):
        created.append((ledger, max_usd))
        return fake
    monkeypatch.setattr("sprachpipe.llm.Llm", factory)
    return created


@pytest.mark.parametrize("fake,code", [(expected_llm(), 0),
                                       (expected_llm(alternatives={"along": True}), 1)])
def test_main_exit_codes_and_results_file(tmp_path, monkeypatch, fake, code):
    created = patch_llm(monkeypatch, fake)
    out = tmp_path / "qa"
    assert script.main(["--out", str(out), "--max-usd", "0.25"]) == code
    assert created == [(out / "ledger.csv", 0.25)]
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    assert data["aborted"] is None and data["total"] == len(data["results"])
    assert (data["passed"] == data["total"]) is (code == 0)


def test_main_argument_errors_before_any_call(tmp_path, monkeypatch):
    created = patch_llm(monkeypatch, FakeLlm())
    existing = tmp_path / "exists"
    existing.mkdir()
    assert script.main(["--out", str(existing)]) == 2
    assert script.main(["--out", str(tmp_path / "new"), "--max-usd", "0.5"]) == 2
    assert script.main(["--out", str(tmp_path / "new"), "--max-usd", "0"]) == 2
    assert script.main([]) == 2
    assert created == [] and not (tmp_path / "new").exists()
    assert list(existing.iterdir()) == []


def test_main_abort_keeps_partial_results(tmp_path, monkeypatch):
    fake = expected_llm()
    fake.fail_after = 3
    patch_llm(monkeypatch, fake)
    out = tmp_path / "qa"
    assert script.main(["--out", str(out), "--max-usd", "0.25"]) == 3
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    assert data["aborted"].startswith("BudgetExceeded")
    assert len(data["results"]) == 3 and all(r["passed"] for r in data["results"])
