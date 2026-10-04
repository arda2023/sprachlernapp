"""Alternative check: code inserts candidates, the model only judges.
Simulated model answers prove processing, not live quality."""

import csv
import json
import re

import pytest

from sprachpipe.alternative_check import check, filled
from sprachpipe.blindtest import judge
from sprachpipe.config import load_config
from sprachpipe.cost import BudgetExceeded
from sprachpipe.generate import load_prompt, qa_sentence
from sprachpipe.llm import AuthError, Llm, LlmError
from sprachpipe.pack import assemble_pack

ABOUT = "Nina walks for about thirty minutes."
ABOUT_GAP = (15, 20)
STAIRS = "Zoe carries the food up the stairs."
STAIRS_GAP = (21, 23)


@pytest.fixture
def cfg():
    return load_config()


NO_RAW = object()


class Judge:
    """Fake checker: valid per candidate (ignoring case); records every call."""
    def __init__(self, verdicts=None, raw=NO_RAW):
        self.verdicts = verdicts or {}
        self.raw = raw
        self.calls = []

    def generate_json(self, prompt, schema, **kwargs):
        self.calls.append((prompt, schema, kwargs))
        if self.raw is not NO_RAW:
            return self.raw
        found = re.findall(r'^(\d+)\. inserted: "(.*)" -> ', prompt, flags=re.M)
        verdict = lambda c: self.verdicts.get(c.casefold(), (False, "Im Zweifel ungültig."))
        return {"results": [{"candidate_index": int(i), "valid": verdict(c)[0], "reason": verdict(c)[1]}
                            for i, c in found]}


def run_qa(cfg, text, gap, form, blind_answer, checker, *, meaning_ok=True, language_ok=True,
           regenerate=None):
    calls = {"blind": 0, "meaning": 0, "alternative": 0}
    def blind(*_):
        calls["blind"] += 1
        return blind_answer
    def meaning(*_):
        calls["meaning"] += 1
        return {"sense_key": "k" if meaning_ok else "other", "observed_pos": "ADV",
                "translation_ok": True, "language_ok": language_ok, "reason": "Passt."}
    def alternative(text, gap, tr, candidates):
        calls["alternative"] += 1
        return check(checker, cfg, text, gap, tr, candidates)
    attempts = qa_sentence(
        {"text": text, "translation_de": "Deutsch."}, {"form": form, "sense_key": "k", "pos": "ADV"}, cfg,
        regenerate=regenerate or (lambda fb: pytest.fail("no regeneration expected")),
        lint=lambda *_: [], blind=blind, judge=lambda r: judge(r, form, [form], form, None, None),
        meaning_check=meaning, alternative_check=alternative)
    return attempts, calls


def test_code_inserts_candidates_literally(cfg):
    assert STAIRS[slice(*STAIRS_GAP)] == "up" and ABOUT[slice(*ABOUT_GAP)] == "about"
    assert filled(STAIRS, STAIRS_GAP, "up the") == "Zoe carries the food up the the stairs."
    fake = Judge()
    results = check(fake, cfg, STAIRS, STAIRS_GAP, "Zoe trägt das Essen die Treppe hinauf.", ["up the"])
    prompt, schema, kwargs = fake.calls[0]
    assert '1. inserted: "up the" -> Zoe carries the food up the the stairs.' in prompt
    assert "Original sentence: " + STAIRS in prompt
    assert "German translation: Zoe trägt das Essen die Treppe hinauf." in prompt
    assert kwargs["step"] == "alternative_check"
    assert kwargs["model"] == cfg["llm"]["alternative_check_model"] == "gemini-3.8-flash"
    assert kwargs["thinking"] == cfg["llm"]["alternative_check_thinking"] == {"thinking_level": "LOW"}
    assert kwargs["max_output_tokens"] == cfg["llm"]["max_output_tokens"]["alternative_check"] == 1024
    assert schema["properties"]["results"]["minItems"] == schema["properties"]["results"]["maxItems"] == 1
    assert results == [{"candidate_index": 1, "candidate": "up the", "norm": "up the",
                        "sentence": "Zoe carries the food up the the stairs.",
                        "status": "rejected", "reason": "Im Zweifel ungültig."}]


def test_no_candidates_no_call(cfg):
    fake = Judge()
    assert check(fake, cfg, ABOUT, ABOUT_GAP, "x", []) == []
    assert fake.calls == []
    attempts, calls = run_qa(cfg, ABOUT, ABOUT_GAP, "about",
                             {"answer": "about", "alternatives": []}, fake)
    assert attempts[-1]["qa_status"] == "ok" and calls["alternative"] == 0 and fake.calls == []
    assert attempts[-1]["alternative_candidates"] == [] and attempts[-1]["valid_alternatives"] == []


@pytest.mark.parametrize("raw", [
    None, [], {}, {"results": None}, {"results": []}, {"results": [], "extra": 1},
    {"results": [{"candidate_index": 1, "valid": True, "reason": "ok"}]},                   # index 2 missing
    {"results": [{"candidate_index": 1, "valid": True, "reason": "ok"}] * 2},               # duplicate
    {"results": [{"candidate_index": 1, "valid": True, "reason": "ok"},
                 {"candidate_index": 3, "valid": True, "reason": "ok"}]},                   # invented index
    {"results": [{"candidate_index": True, "valid": True, "reason": "ok"},
                 {"candidate_index": 2, "valid": True, "reason": "ok"}]},                   # bool index
    {"results": [{"candidate_index": 1, "valid": "yes", "reason": "ok"},
                 {"candidate_index": 2, "valid": True, "reason": "ok"}]},
    {"results": [{"candidate_index": 1, "valid": True, "reason": " "},
                 {"candidate_index": 2, "valid": True, "reason": "ok"}]},
    {"results": [{"candidate_index": 1, "valid": True, "reason": "ok", "sentence": "rewritten"},
                 {"candidate_index": 2, "valid": True, "reason": "ok"}]},
])
def test_invalid_check_structure_is_never_accepted(cfg, raw):
    results = check(Judge(raw=raw), cfg, ABOUT, ABOUT_GAP, "x", ["approximately", "around"])
    assert [r["status"] for r in results] == ["invalid", "invalid"]
    assert all(r["reason"].startswith("Ungültige Prüfantwort:") for r in results)
    attempts, _ = run_qa(cfg, ABOUT, ABOUT_GAP, "about", {"answer": "about", "alternatives": [
        {"answer": "approximately", "reason": "x"}, {"answer": "around", "reason": "x"}]}, Judge(raw=raw))
    assert attempts[-1]["qa_status"] == "failed"
    assert attempts[-1]["discard_reasons"] == ["Ungültige Prüfantwort: Alternativprüfung"]
    assert attempts[-1]["valid_alternatives"] == []


@pytest.mark.parametrize("error", [AuthError("ADC"), BudgetExceeded("limit"), LlmError("timeout")])
def test_errors_are_not_swallowed(cfg, error):
    class Failing:
        def generate_json(self, *args, **kwargs):
            raise error
    with pytest.raises(type(error)):
        check(Failing(), cfg, ABOUT, ABOUT_GAP, "x", ["approximately"])


def test_about_main_answer_with_confirmed_approximately(cfg):
    fake = Judge({"approximately": (True, "Gleiche Schätzung, Satz natürlich.")})
    attempts, calls = run_qa(cfg, ABOUT, ABOUT_GAP, "about", {"answer": "about", "alternatives": [
        {"answer": "Approximately", "reason": "Same estimate."}]}, fake)
    a = attempts[-1]
    assert len(attempts) == 1 and a["qa_status"] == "ok" and a["blind"] == "passed"
    assert a["valid_alternatives"] == ["approximately"]
    assert a["alternative_check"][0]["sentence"] == "Nina walks for Approximately thirty minutes."
    assert calls == {"blind": 1, "meaning": 1, "alternative": 1} and len(fake.calls) == 1


def test_approximately_main_answer_confirmed_for_about(cfg):
    fake = Judge({"approximately": (True, "Gleiche Bedeutung.")})
    attempts, calls = run_qa(cfg, ABOUT, ABOUT_GAP, "about",
                             {"answer": "approximately", "alternatives": []}, fake)
    a = attempts[-1]
    assert len(attempts) == 1 and a["qa_status"] == "ok"
    assert a["blind"] == "confirmed_alternative" and a["blind_answer"] == "approximately"
    assert a["valid_alternatives"] == ["approximately"]
    assert calls == {"blind": 1, "meaning": 1, "alternative": 1}


def test_up_the_and_up_and_down_rejected_sentence_still_passes(cfg):
    fake = Judge({"up the": (False, "Doppelter Artikel: up the the stairs."),
                  "up and down": (False, "Bedeutung verschiebt sich zu hin und her.")})
    attempts, calls = run_qa(cfg, STAIRS, STAIRS_GAP, "up", {"answer": "up", "alternatives": [
        {"answer": "up the", "reason": "x"}, {"answer": "up and down", "reason": "x"}]}, fake)
    a = attempts[-1]
    assert a["qa_status"] == "ok" and a["valid_alternatives"] == []
    assert [(r["sentence"], r["status"]) for r in a["alternative_check"]] == [
        ("Zoe carries the food up the the stairs.", "rejected"),
        ("Zoe carries the food up and down the stairs.", "rejected")]
    assert calls["alternative"] == 1 and len(fake.calls) == 1


def test_unconfirmed_wrong_main_answer_fails_after_one_retry(cfg):
    fake = Judge({"around": (False, "Unklar.")})
    feedback = []
    attempts, calls = run_qa(cfg, ABOUT, ABOUT_GAP, "about", {"answer": "around", "alternatives": []}, fake,
                             regenerate=lambda fb: (feedback.append(fb),
                                                    {"text": "Leo sleeps for about an hour.", "translation_de": "x"})[1])
    assert [a["qa_status"] for a in attempts] == ["replaced", "failed"]
    assert [a["blind"] for a in attempts] == ["unconfirmed", "unconfirmed"]
    assert attempts[-1]["discard_reasons"] == ["Blindtest"]
    assert len(feedback) == 1 and "Checker: Unklar." in feedback[0]
    assert calls == {"blind": 2, "meaning": 2, "alternative": 2}   # one check per attempt


def test_alternative_check_only_after_original_checks(cfg):
    fake = Judge({"approximately": (True, "ok")})
    attempts, calls = run_qa(cfg, ABOUT, ABOUT_GAP, "about", {"answer": "about", "alternatives": [
        {"answer": "approximately", "reason": "x"}]}, fake, meaning_ok=False)
    assert attempts[-1]["qa_status"] == "failed" and attempts[-1]["discard_reasons"] == ["Bedeutung"]
    assert calls["alternative"] == 0 and attempts[-1]["valid_alternatives"] == []


def test_ledger_step_alternative_check(cfg, tmp_path):
    class Vertex(Llm):
        def _call(self, prompt, schema, model, thinking, max_output_tokens):
            assert max_output_tokens == 1024 and model == "gemini-3.8-flash"
            assert thinking == {"thinking_level": "LOW"}
            return json.dumps({"results": [{"candidate_index": 1, "valid": True, "reason": "ok"}]}), (80, 20, 10)
    llm = Vertex(cfg, tmp_path / "ledger.csv", 1.0)
    assert check(llm, cfg, ABOUT, ABOUT_GAP, "x", ["approximately"])[0]["status"] == "confirmed"
    rows = list(csv.DictReader(open(tmp_path / "ledger.csv", encoding="utf-8")))
    assert [(r["step"], r["model"]) for r in rows] == [("alternative_check", "gemini-3.8-flash")]
    # priced with the model actually called, no fallback
    from sprachpipe.llm import cost_usd, model_price
    assert float(rows[0]["usd"]) == pytest.approx(
        cost_usd(model_price(cfg["prices"], "gemini-3.8-flash"), 80, 20, 10), abs=1e-6)


def test_other_checks_keep_their_models(cfg):
    from sprachpipe.blindtest import ask
    from sprachpipe.meaning_check import check as check_meaning
    c = cfg["llm"]
    seen = {}
    class Rec:
        def generate_json(self, prompt, schema, **kwargs):
            seen[kwargs["step"]] = (kwargs["model"], kwargs["thinking"], kwargs["max_output_tokens"])
            if kwargs["step"] == "blindtest":
                return {"answer": "about", "alternatives": []}
            return {"sense_key": "about#ungefaehr", "observed_pos": "ADV", "translation_ok": True,
                    "language_ok": True, "reason": "ok"}
    ask(Rec(), cfg, ABOUT, ABOUT_GAP, "x", "ungefähr")
    check_meaning(Rec(), cfg, ABOUT, "about", [{"sense_key": "about#ungefaehr", "pos": "ADV",
                  "form_kind": "other", "form_label_de": "Adverb", "gloss_de": "ungefähr"}], "x")
    assert seen == {"blindtest": ("gemini-2.5-flash", {"thinking_budget": 0}, 256),
                    "meaning_check": (c["meaning_check_model"], c["meaning_check_thinking"], 1024)}


ABOUT_YEARS = "David has known his best friend for about ten years."
ABOUT_YEARS_GAP = (36, 41)
ABOUT_YEARS_DE = "David kennt seinen besten Freund seit ungefähr zehn Jahren."


@pytest.mark.parametrize("blind_answer", [
    {"answer": "light", "alternatives": [{"answer": "bright", "reason": "x"}]},   # target form
    {"answer": "bright", "alternatives": []}])                                     # other main answer
def test_unnatural_original_is_not_rescued_by_valid_alternative(cfg, blind_answer):
    text, gap = "Ali sits under a tree because the sun is too light.", (45, 50)
    fake = Judge({"bright": (True, "Natürlich, gleiche Bedeutung.")})
    attempts, calls = run_qa(cfg, text, gap, "light", blind_answer, fake, language_ok=False)
    a = attempts[-1]
    assert len(attempts) == 1 and a["qa_status"] == "failed"
    assert a["discard_reasons"] == ["Sprache"]
    assert a["meaning_check_result"]["language_ok"] is False
    assert calls["alternative"] == 0 and fake.calls == [] and a["valid_alternatives"] == []
    a["tokens"] = []
    card = {"accepted": [dict(a) for _ in range(3)]}
    pack = assemble_pack("en", [card], model="fake", version="test")
    assert not card["packed"] and pack["cards"] == [] and pack["card_sentences"] == []


def test_only_meaning_preserving_alternatives_are_kept(cfg):
    fake = Judge({"around": (True, "Ebenfalls ungefähr."),
                  "nearly": (False, "fast statt ungefähr."),
                  "almost": (False, "fast statt ungefähr.")})
    attempts, calls = run_qa(cfg, ABOUT_YEARS, ABOUT_YEARS_GAP, "about", {"answer": "about", "alternatives": [
        {"answer": "around", "reason": "x"}, {"answer": "nearly", "reason": "x"},
        {"answer": "almost", "reason": "x"}]}, fake)
    a = attempts[-1]
    assert a["qa_status"] == "ok" and a["blind"] == "passed"
    assert a["valid_alternatives"] == ["around"]
    assert [r["status"] for r in a["alternative_check"]] == ["confirmed", "rejected", "rejected"]
    assert calls["alternative"] == 1 and len(fake.calls) == 1


def test_rejected_main_answer_never_becomes_alternative(cfg):
    fake = Judge({"almost": (False, "fast statt ungefähr.")})
    attempts, _ = run_qa(cfg, ABOUT_YEARS, ABOUT_YEARS_GAP, "about",
                         {"answer": "almost", "alternatives": []}, fake,
                         regenerate=lambda fb: {"text": ABOUT_YEARS, "translation_de": "x"})
    assert [a["qa_status"] for a in attempts] == ["replaced", "failed"]
    assert all(a["valid_alternatives"] == [] for a in attempts)


def test_alternative_prompt_v3_compares_original_directly(cfg):
    fake = Judge()
    check(fake, cfg, ABOUT_YEARS, ABOUT_YEARS_GAP, ABOUT_YEARS_DE, ["nearly"])
    prompt = fake.calls[0][0]
    assert load_prompt("alternative_check")[0] == "alternative-check-v3"
    assert "German translation: " + ABOUT_YEARS_DE in prompt
    for rule in ("ungefähr", "hinauf", "time reference", "negation, modality",
                 "the people involved", "Compared directly with the original English sentence",
                 "never justifies a shift between original and candidate",
                 "Do not read extra information", "If in doubt, set valid to false"):
        assert rule in prompt
    template = load_prompt("alternative_check")[1]
    for once in ("time reference", "ungefähr", "hinauf"):   # consolidated, not repeated
        assert template.count(once) == 1, once
    assert "about" not in prompt.replace(ABOUT_YEARS, "")   # no hard-coded word decision
