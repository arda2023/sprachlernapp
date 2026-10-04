import pytest

from sprachpipe.blindtest import ask, judge, normalize, alternatives_for, candidates_for
from sprachpipe.config import load_config
from sprachpipe.generate import qa_sentence


def verdict(result, form="about"):
    return judge(result, form, [form], form, None, None)


@pytest.mark.parametrize("result,form,expected", [
    ({"answer": "about", "alternatives": []}, "about", "passed"),
    ({"answer": "around", "alternatives": []}, "about", "other"),
    ({"answer": "about", "alternatives": [{"answer": "approximately", "reason": "Same estimate."}]}, "about", "passed"),
    ({"answer": "I", "alternatives": [{"answer": "'i.'", "reason": "Case variant."}]}, "i", "passed"),
    ({"answer": "about", "alternatives": [{"answer": "more or less", "reason": "Same estimate."}]}, "about", "passed"),
])
def test_verdict(result, form, expected):
    """Alternatives no longer decide the verdict; only the main answer does."""
    assert verdict(result, form) == expected


@pytest.mark.parametrize("result", [None, "about", {}, {"answer": "about"},
    {"answer": "about", "alternatives": None},
    {"answer": 1, "alternatives": []},
    {"answer": "  ", "alternatives": []},
    {"answer": "about", "alternatives": [], "extra": True},
    *[{"answer": "about", "alternatives": [item]} for item in [
        None, "approximately", {}, {"answer": "approximately"},
        {"answer": None, "reason": "x"}, {"answer": "x", "reason": False},
        {"answer": "x", "reason": " "}, {"answer": "x", "reason": "x", "extra": 1}]],
    {"answer": "about", "alternatives": [{"answer": "x", "reason": "x"}] * 4},
])
def test_invalid_model_structure_cannot_pass(result):
    class Fake:
        def generate_json(self, *args, **kwargs):
            return result
    response = ask(Fake(), load_config(), "For about thirty minutes.", (4, 9), "Ungefähr.", "ungefähr")
    assert verdict(response) == "failed"
    assert candidates_for(response, "about") == []


def test_normalization_deduplication_and_single_blind_call():
    class Fake:
        calls = 0
        def generate_json(self, prompt, schema, **kwargs):
            self.calls += 1
            assert "For ___ thirty minutes." in prompt
            assert "about" not in prompt and "sense_key" not in prompt
            assert schema["properties"]["alternatives"]["maxItems"] == 3
            return {"answer": "about", "alternatives": [
                {"answer": "Approximately!", "reason": " Same estimate. "},
                {"answer": " approximately ", "reason": "Duplicate."},
                {"answer": "About.", "reason": "Target variant."}]}
    fake = Fake()
    response = ask(fake, load_config(), "For about thirty minutes.", (4, 9), "Ungefähr.", "ungefähr")
    assert fake.calls == 1
    assert alternatives_for(response, "about") == [
        {"answer": "Approximately", "reason": "Same estimate."}]
    assert candidates_for(response, "about") == ["Approximately"]


def test_candidates_case_duplicates_multiword_and_main_answer():
    response = {"answer": "Around", "alternatives": [
        {"answer": "AROUND", "reason": "Duplicate of the main answer."},
        {"answer": "more or less", "reason": "Multiword estimate."},
        {"answer": "About!", "reason": "Target form."}]}
    assert candidates_for(response, "about") == ["Around", "more or less"]
    full = {"answer": "roughly", "alternatives": [
        {"answer": a, "reason": "x"} for a in ("around", "approximately", "more or less")]}
    assert candidates_for(full, "about") == ["roughly", "around", "approximately", "more or less"]
    assert candidates_for("about", "about") == [] and candidates_for(" Around. ", "about") == ["Around"]


def test_alternatives_trigger_no_retry():
    calls = []
    def blind(*args):
        calls.append(args)
        return {"answer": "about", "alternatives": [
            {"answer": "approximately", "reason": "Same estimate."}]}
    attempts = qa_sentence(
        {"text": "Nina walks for about thirty minutes.", "translation_de": "Ungefähr dreißig Minuten."},
        {"form": "about", "sense_key": "about#ungefaehr"}, load_config(),
        regenerate=lambda fb: pytest.fail("alternatives must not regenerate the sentence"),
        lint=lambda *_: [], blind=blind, judge=verdict)
    assert len(calls) == 1
    assert [a["qa_status"] for a in attempts] == ["ok"]
    assert attempts[0]["alternative_candidates"] == ["approximately"]
    assert attempts[0]["valid_alternatives"] == []   # never confirmed without a check


def test_wrong_main_answer_uses_the_one_blind_retry():
    calls, feedback = [], []
    def blind(*args):
        calls.append(args)
        return {"answer": "around", "alternatives": []}
    attempts = qa_sentence(
        {"text": "Nina walks for about thirty minutes.", "translation_de": "Ungefähr dreißig Minuten."},
        {"form": "about", "sense_key": "about#ungefaehr"}, load_config(),
        regenerate=lambda fb: (feedback.append(fb), {"text": "Leo walks for about thirty minutes.", "translation_de": "Ungefähr."})[1],
        lint=lambda *_: [], blind=blind, judge=verdict)
    assert len(calls) == 2 and len(feedback) == 1
    assert [a["qa_status"] for a in attempts] == ["replaced", "failed"]
    assert [a["blind"] for a in attempts] == ["unconfirmed", "unconfirmed"]
    assert attempts[-1]["discard_reasons"] == ["Blindtest"]
    assert "'around'" in feedback[0] and 'only the target form "about"' in feedback[0]
