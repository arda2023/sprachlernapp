"""Fixed live QA cases: fixture consistency and offline proof that the
diagnosis compares actual verdicts. Simulated answers prove processing, not
live quality."""

import importlib.util
import json
import re
from pathlib import Path

import pytest

from sprachpipe.config import PIPELINE_DIR, load_config
from sprachpipe.cost import BudgetExceeded, append_entry, total_usd
from sprachpipe.generate import gap_offsets
from sprachpipe.inventory import MeaningInventory
from sprachpipe.llm import LlmError

SCRIPT = PIPELINE_DIR / "scripts" / "check_qa_cases.py"
spec = importlib.util.spec_from_file_location("check_qa_cases", SCRIPT)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)
CASES = script.load_cases()


class FakeLlm:
    """Answers with given verdicts; records every prompt and call. With
    [ledger] set, writes one ledger row per call like the real wrapper."""
    def __init__(self, language=None, alternatives=None, fail_after=None, per_model=None):
        self.language = language or {}
        self.alternatives = alternatives or {}
        self.fail_after = fail_after
        self.per_model = per_model or {}   # model -> {text: raw meaning response or Exception}
        self.prompts = []
        self.calls = []
        self.ledger = None

    def generate_json(self, prompt, schema, *, step, **kwargs):
        if self.fail_after is not None and len(self.prompts) >= self.fail_after:
            raise BudgetExceeded("limit")
        self.prompts.append(prompt)
        self.calls.append(dict(kwargs, step=step, prompt=prompt, schema=schema))
        if self.ledger is not None:
            append_entry(self.ledger, step=step, model=kwargs["model"], input_tokens=100,
                         output_tokens=10, thinking_tokens=5, usd=0.001)
        if step == "meaning_check":
            text = re.search(r"^Sentence: (.+)$", prompt, flags=re.M).group(1)
            special = self.per_model.get(kwargs["model"], {}).get(text)
            if isinstance(special, Exception):
                raise special
            if special is not None:
                return special
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
        assert gap_offsets(case["text"], card["form"]) is not None
        if card.get("local_fixture"):   # sense defined only in the fixture, not in the inventory
            assert case in CASES["alternative_cases"] and card["gloss_de"]
            continue
        found = {m["sense_key"]: m for m in inventory.get(card["form"])}
        assert found[card["sense_key"]]["pos"] == card["pos"]
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
                      "C_about_ten_years:nearly", "C_about_ten_years:around",
                      "v8_s34_about_thirty_minutes:nearly", "v8_s34_about_thirty_minutes:around",
                      "v8_s36_about_ten_minutes:around"}
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
        fake.ledger = ledger
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


CFG = load_config()
CHECK_MODEL, GEN_MODEL = CFG["llm"]["meaning_check_model"], CFG["llm"]["generate_model"]
SUN = "The sun is too light."
N_ALT = sum(len(c["candidates"]) for c in CASES["alternative_cases"])


def test_v8_and_tense_fixtures_present_with_expectations():
    alt = {c["id"]: c for c in CASES["alternative_cases"]}
    assert alt["v8_s34_about_thirty_minutes"]["expected"] == {"around": True, "approximately": True,
                                                              "nearly": False}
    assert alt["v8_s36_about_ten_minutes"]["expected"] == {"around": True, "for about": True,
                                                           "for around": True}
    assert alt["went_sour_tense"]["expected"] == {"turned": True, "had gone": False}
    assert {"C_about_ten_years", "D_up_mountain_road", "up_the_stairs_duplicate_article"} <= set(alt)
    assert N_ALT == 16


def test_only_alternative_check_runs_all_alternative_cases_and_no_meaning_case(tmp_path, monkeypatch):
    fake = expected_llm()
    created = patch_llm(monkeypatch, fake)
    out = tmp_path / "alt"
    assert script.main(["--out", str(out), "--max-usd", "0.25", "--only", "alternative_check"]) == 0
    assert created == [(out / "ledger.csv", 0.25)]          # one llm, one budget
    assert {c["step"] for c in fake.calls} == {"alternative_check"}
    assert len(fake.calls) == len(CASES["alternative_cases"])
    c = CFG["llm"]
    assert all((k["model"], k["thinking"], k["max_output_tokens"]) ==
               (c["alternative_check_model"], c["alternative_check_thinking"], 1024) for k in fake.calls)
    for prompt in fake.prompts:
        assert "expected" not in prompt and "finding" not in prompt
    assert any('inserted: "for about" -> David waited for about ten minutes' in p for p in fake.prompts)
    assert any('inserted: "had gone" -> The milk had gone sour yesterday.' in p for p in fake.prompts)
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    assert data["only"] == "alternative_check" and data["total"] == N_ALT
    assert all(r["kind"] == "alternative_check" and r["model"] == c["alternative_check_model"]
               for r in data["results"])
    # one ledger row per case call, counted once
    usage = [u for r in data["results"] for u in r["usage"]]
    assert len(usage) == len(CASES["alternative_cases"])
    assert {u["model"] for u in usage} == {c["alternative_check_model"]}
    assert total_usd(out / "ledger.csv") == pytest.approx(sum(float(u["usd"]) for u in usage))


def test_only_alternative_check_detects_wrong_verdicts(tmp_path, monkeypatch):
    patch_llm(monkeypatch, expected_llm(alternatives={"nearly": True, "had gone": True}))
    out = tmp_path / "alt"
    assert script.main(["--out", str(out), "--only", "alternative_check"]) == 1
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    assert {r["id"] for r in data["results"] if not r["passed"]} == {
        "C_about_ten_years:nearly", "v8_s34_about_thirty_minutes:nearly", "went_sour_tense:had gone"}


def test_only_rejects_bad_values_and_compare_combination(tmp_path, monkeypatch):
    created = patch_llm(monkeypatch, FakeLlm())
    assert script.main(["--out", str(tmp_path / "a"), "--only", "meaning_check"]) == 2
    assert script.main(["--out", str(tmp_path / "b"), "--only", "alternative_check",
                        "--compare-models"]) == 2
    assert created == [] and not (tmp_path / "a").exists() and not (tmp_path / "b").exists()


def test_normal_mode_uses_pipeline_meaning_check_config(tmp_path, monkeypatch):
    fake = expected_llm()
    patch_llm(monkeypatch, fake)
    out = tmp_path / "qa"
    assert script.main(["--out", str(out)]) == 0
    meaning = [c for c in fake.calls if c["step"] == "meaning_check"]
    assert meaning and all((c["model"], c["thinking"]) == (CHECK_MODEL, CFG["llm"]["meaning_check_thinking"])
                           for c in meaning)
    alternative = [c for c in fake.calls if c["step"] == "alternative_check"]
    assert alternative and all((c["model"], c["thinking"]) == (CFG["llm"]["alternative_check_model"],
                                                              CFG["llm"]["alternative_check_thinking"])
                               for c in alternative)
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    rows = [r for r in data["results"] if r["kind"] == "meaning_check"]
    assert all((r["model"], r["thinking"]) == (CHECK_MODEL, CFG["llm"]["meaning_check_thinking"])
               for r in rows)


def compare(tmp_path, monkeypatch, fake, *extra):
    created = patch_llm(monkeypatch, fake)
    out = tmp_path / "cmp"
    code = script.main(["--out", str(out), "--max-usd", "0.25", "--compare-models", *extra])
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    return code, data, created, out


def test_compare_models_same_cases_prompts_schema_limit_one_budget(tmp_path, monkeypatch):
    fake = expected_llm()
    code, data, created, out = compare(tmp_path, monkeypatch, fake)
    assert code == 0 and data["aborted"] is None and data["mode"] == "compare-models"
    assert created == [(out / "ledger.csv", 0.25)]          # one llm, one budget for both models
    n = len(CASES["meaning_cases"])
    assert len(fake.calls) == 2 * n and {c["step"] for c in fake.calls} == {"meaning_check"}
    first, second = fake.calls[:n], fake.calls[n:]
    assert {c["model"] for c in first} == {CHECK_MODEL} and {c["model"] for c in second} == {GEN_MODEL}
    assert all(c["thinking"] == CFG["llm"]["meaning_check_thinking"] for c in first)
    assert all(c["thinking"] == CFG["llm"]["generate_thinking"] for c in second)
    limit = CFG["llm"]["max_output_tokens"]["meaning_check"]
    for a, b in zip(first, second):
        assert (a["prompt"], a["schema"]) == (b["prompt"], b["schema"])
        assert a["max_output_tokens"] == b["max_output_tokens"] == limit
    for prompt in fake.prompts:
        assert "expected" not in prompt and "finding" not in prompt
    labels = [(m["label"], m["model"], m["thinking"], m["max_output_tokens"]) for m in data["models"]]
    assert labels == [("pruefmodell", CHECK_MODEL, CFG["llm"]["meaning_check_thinking"], limit),
                      ("generierungsmodell", GEN_MODEL, CFG["llm"]["generate_thinking"], limit)]
    for m in data["models"]:
        assert m["summary"] == {"cases": n, "passed": n, "valid_responses": n, "invalid_responses": 0,
                                "false_accept": 0, "false_reject": 0, "calls": n,
                                "cost_usd": pytest.approx(n * 0.001)}
    assert total_usd(out / "ledger.csv") == pytest.approx(2 * n * 0.001)


def test_compare_separates_format_errors_from_wrong_verdicts(tmp_path, monkeypatch):
    # distinct check model so simulated answers can be keyed per model
    import copy
    cfg = copy.deepcopy(CFG)
    cfg["llm"].update(meaning_check_model=CFG["llm"]["blindtest_model"],
                      meaning_check_thinking=CFG["llm"]["blindtest_thinking"])
    monkeypatch.setattr(script, "load_config", lambda: cfg)
    CHECK_MODEL = cfg["llm"]["meaning_check_model"]
    assert CHECK_MODEL != GEN_MODEL

    def raw(**change):
        return dict({"sense_key": "light#hell", "observed_pos": "ADJ", "translation_ok": True,
                     "language_ok": True, "reason": "Simuliert."}, **change)
    window = "Maya reads her book in the light from the window."
    fake = expected_llm()
    fake.per_model = {
        CHECK_MODEL: {SUN: raw(reason=""),                       # format error, expected false
                      "The room is light and airy.": raw(translation_ok="yes"),
                      "Maya checks her dress in the sun light.": raw(sense_key="light#licht",
                                                                     observed_pos="NOUN")},  # false accept
        GEN_MODEL: {window: raw(sense_key="light#licht", observed_pos="NOUN", language_ok=False),  # false reject
                    SUN: LlmError("meaning_check: Expecting value")}}
    fake.per_model[GEN_MODEL][SUN].__cause__ = json.JSONDecodeError("Expecting value", "", 0)
    code, data, _, _ = compare(tmp_path, monkeypatch, fake)
    assert code == 1 and data["aborted"] is None
    check, gen = data["models"]
    n = len(CASES["meaning_cases"])
    assert check["summary"]["invalid_responses"] == 2 and check["summary"]["valid_responses"] == n - 2
    assert check["summary"]["false_accept"] == 1 and check["summary"]["false_reject"] == 0
    assert gen["summary"]["invalid_responses"] == 1 and gen["summary"]["false_reject"] == 1
    assert gen["summary"]["false_accept"] == 0
    rows = {r["id"]: r for r in check["results"]}
    sun = rows["sun_too_light_short"]
    # expected language_ok=false, but an invalid answer is never a detected language error
    assert not sun["passed"] and not sun["valid_response"] and not sun["false_accept"]
    assert sun["response"] == raw(reason="")
    assert sun["violations"] == [{"field": "reason", "problem": "kein nicht-leerer String",
                                  "type": "str", "value": ""}]
    assert rows["room_light_and_airy"]["violations"][0]["field"] == "translation_ok"
    assert rows["sun_light_split_short"]["false_accept"]
    gen_sun = next(r for r in gen["results"] if r["id"] == "sun_too_light_short")
    assert gen_sun["violations"][0]["problem"] == "keine parsebare JSON-Antwort"
    assert gen_sun["usage"] == [{"model": GEN_MODEL, "input_tokens": "100", "output_tokens": "10",
                                 "thinking_tokens": "5", "usd": "0.001000"}]


def test_compare_abort_keeps_partial_results_under_shared_budget(tmp_path, monkeypatch):
    fake = expected_llm()
    n = len(CASES["meaning_cases"])
    fake.fail_after = n + 2
    code, data, _, _ = compare(tmp_path, monkeypatch, fake)
    assert code == 3 and data["aborted"].startswith("BudgetExceeded")
    assert [len(m["results"]) for m in data["models"]] == [n, 2]


def test_transport_error_still_aborts(tmp_path, monkeypatch):
    fake = expected_llm()
    fake.per_model = {CHECK_MODEL: {SUN: LlmError("meaning_check: Vertex 503")}}
    code, data, _, _ = compare(tmp_path, monkeypatch, fake)
    assert code == 3 and data["aborted"].startswith("LlmError")


def test_normal_mode_records_diagnostics(tmp_path, monkeypatch):
    fake = expected_llm()
    fake.per_model = {CHECK_MODEL: {SUN: {"sense_key": "light#hell", "observed_pos": "ADJ",
                                          "translation_ok": True, "language_ok": False, "reason": ""}}}
    patch_llm(monkeypatch, fake)
    out = tmp_path / "qa"
    assert script.main(["--out", str(out)]) == 1
    data = json.loads((out / "results.json").read_text(encoding="utf-8"))
    row = next(r for r in data["results"] if r["id"] == "sun_too_light_short")
    assert not row["passed"] and row["response"]["reason"] == ""
    assert [v["field"] for v in row["violations"]] == ["reason"]
    assert sum(r["kind"] == "alternative_check" for r in data["results"]) == N_ALT


def test_compare_refuses_existing_folder(tmp_path, monkeypatch):
    created = patch_llm(monkeypatch, FakeLlm())
    (tmp_path / "cmp").mkdir()
    assert script.main(["--out", str(tmp_path / "cmp"), "--compare-models"]) == 2
    assert created == []


def test_pilot60_content_cases_use_exact_gaps_and_real_checks():
    meaning = {c["id"]: c for c in CASES["meaning_cases"]}
    alt = {c["id"]: c for c in CASES["alternative_cases"]}
    assert meaning["pilot60_s126_quiet_library_books"]["expected"] == {"language_ok": False}
    assert meaning["library_books_quietly"]["expected"] == {"language_ok": True}
    for cid in ("pilot60_s126_quiet_library_books", "library_books_quietly"):
        assert meaning[cid]["card"] == {"form": "in", "sense_key": "in#herein_drinnen", "pos": "ADV"}
    at, before = alt["pilot60_s399_at_bedtime"], alt["before_bedtime_prior_to"]
    assert at["text"][slice(*at["gap"])] == "at" and at["expected"] == {"before": False}
    assert before["text"][slice(*before["gap"])] == "before" and before["expected"] == {"prior to": True}
    assert at["translation_de"] == before["translation_de"] == "Mia nimmt ihre Medizin vor dem Schlafengehen."
    fake = expected_llm()
    results, aborted, _ = run(fake)
    assert aborted is None and all(r["passed"] for r in results)
    prompts = "\n".join(fake.prompts)
    assert '1. inserted: "before" -> Mia takes her medicine before bedtime.' in prompts
    assert '1. inserted: "prior to" -> Mia takes her medicine prior to bedtime.' in prompts
    assert "Sentence: Ben stayed in all afternoon to read quiet library books." in prompts
    check_prompt = next(p for p in fake.prompts if "quiet library books" in p)
    assert "language_ok covers the whole sentence" in check_prompt
    assert "An unusual but plausible situation is acceptable." in check_prompt
    assert "quiet" not in load_prompt_text("meaning_check") and "bedtime" not in load_prompt_text("alternative_check")
    for p in fake.prompts:
        assert "expected" not in p and "finding" not in p and "local_fixture" not in p


def load_prompt_text(name):
    from sprachpipe.generate import load_prompt
    return load_prompt(name)[1]