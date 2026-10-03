import pytest

from sprachpipe.blindtest import ask, judge, normalize, alternatives_for
from sprachpipe.config import load_config
from sprachpipe.generate import qa_sentence


def verdict(result, form="about"):
    return judge(result, form, [form], form, None, None)


@pytest.mark.parametrize("result,form,expected", [
    ({"answer": "about", "alternatives": []}, "about", "passed"),
    ({"answer": "around", "alternatives": []}, "about", "failed"),
    ({"answer": "about", "alternatives": [{"answer": "approximately", "reason": "Same estimate."}]}, "about", "ambiguous"),
    ({"answer": "I", "alternatives": [{"answer": "'i.'", "reason": "Case variant."}]}, "i", "passed"),
    ({"answer": "about", "alternatives": [{"answer": "more or less", "reason": "Same estimate."}]}, "about", "ambiguous"),
])
def test_verdict(result, form, expected):
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


@pytest.mark.parametrize("first", ["wrong", "ambiguous"])
def test_mismatch_and_ambiguity_share_one_retry(first):
    ambiguous = {"answer": "about", "alternatives": [
        {"answer": "approximately", "reason": "Same estimate."}]}
    responses = iter([ambiguous if first == "ambiguous" else {"answer": "around", "alternatives": []}, ambiguous])
    calls, feedback = [], []
    def blind(*args):
        calls.append(args)
        return next(responses)
    attempts = qa_sentence(
        {"text": "Nina walks for about thirty minutes.", "translation_de": "Ungefähr dreißig Minuten."},
        {"form": "about", "sense_key": "about#ungefaehr"}, load_config(),
        regenerate=lambda fb: (feedback.append(fb), {"text": "Leo walks for about thirty minutes.", "translation_de": "Ungefähr."})[1],
        lint=lambda *_: [], blind=blind, judge=verdict,
        meaning_check=lambda *_: pytest.fail("ambiguous attempt must not reach meaning check"))
    assert len(calls) == 2 and len(feedback) == 1
    assert [a["qa_status"] for a in attempts] == ["replaced", "failed"]
    assert attempts[-1]["discard_reasons"] == ["Mehrdeutige Lücke"]
    assert attempts[-1]["blind_alternatives"] == ambiguous["alternatives"]
    if first == "ambiguous":
        assert "approximately: Same estimate." in feedback[0]
