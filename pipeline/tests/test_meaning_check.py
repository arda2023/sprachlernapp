import json

import pytest

from sprachpipe.config import load_config
from sprachpipe.generate import POS_TAGS, qa_sentence
from sprachpipe.meaning_check import check, violations
from sprachpipe.pack import assemble_pack
from sprachpipe.review import review_rows, write_run_report
from sprachpipe.generate import load_prompt


def sense(key, pos, gloss, *, kind="past", label="Verb, Vergangenheit"):
    return {"sense_key": key, "pos": pos, "form_kind": kind,
            "form_label_de": label, "gloss_de": gloss}


class FakeCheck:
    def __init__(self, result):
        self.result = result
        self.calls = 0
        self.prompt = ""
        self.schema = None

    def generate_json(self, prompt, schema, **kwargs):
        self.calls += 1
        self.prompt = prompt
        self.schema = schema
        return self.result


def checked(fake, sentence, translation, form, meanings):
    return check(fake, load_config(), sentence, form, meanings, translation)


def run_qa(cfg, sentence, translation, form, target_key, target_pos, result):
    attempts = qa_sentence(
        {"text": sentence, "translation_de": translation},
        {"form": form, "sense_key": target_key, "pos": target_pos}, cfg,
        regenerate=lambda _: pytest.fail("meaning check must not add a retry"),
        lint=lambda *_: [], blind=lambda *_: form, judge=lambda _: "passed",
        meaning_check=lambda _text, _translation: result)
    return attempts[-1]


def test_meaning_check_one_call_includes_pos_and_form_details_and_translation():
    response = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
                "translation_ok": False, "language_ok": True, "reason": "early meint hier vorzeitig."}
    fake = FakeCheck(response)
    sentence = "Elias left the concert early yesterday because the music was too loud."
    translation = "Elias verließ das Konzert gestern früh, weil die Musik zu laut war."
    meanings = [sense("leave#verlassen", "VERB", "einen Ort verlassen")]
    result = checked(fake, sentence, translation, "left", meanings)
    assert fake.calls == 1
    assert "POS=VERB" in fake.prompt and "form=past" in fake.prompt
    assert "German translation: " + translation in fake.prompt
    assert result == response
    version, sentence_prompt = load_prompt("sentences")
    assert version == "sentences-v7"
    assert "who does what" in sentence_prompt and "time/tense" in sentence_prompt
    attempt = run_qa(load_config(), sentence, translation, "left", "leave#verlassen", "VERB", result)
    assert attempt["qa_status"] == "failed"
    assert attempt["discard_reasons"] == ["Übersetzung"]


def test_same_meaning_wrong_contextual_pos_is_rejected_for_up_regression():
    sentence = "Nina carries the heavy letter up the post office stairs."
    translation = "Nina trägt den schweren Brief die Treppe hinauf."
    meanings = [sense("up#hinauf", "ADV", "nach oben", kind="other", label="Adverb"),
                sense("up#entlang", "ADP", "entlang", kind="other", label="Präposition")]
    fake = FakeCheck({"sense_key": "up#hinauf", "observed_pos": "ADP",
                      "translation_ok": True, "language_ok": True, "reason": "up steht vor einer Nominalgruppe."})
    result = checked(fake, sentence, translation, "up", meanings)
    assert "up#entlang: POS=ADP" in fake.prompt
    attempt = run_qa(load_config(), sentence, translation, "up", "up#hinauf", "ADV", result)
    assert attempt["qa_status"] == "failed"
    assert attempt["discard_reasons"] == ["Wortart"]


def test_matching_sense_pos_and_translation_pass():
    result = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
              "translation_ok": True, "language_ok": True, "reason": "Die Person verließ den Ort."}
    attempt = run_qa(load_config(), "Elias left the concert early yesterday.",
                     "Elias verließ das Konzert gestern vorzeitig.",
                     "left", "leave#verlassen", "VERB", result)
    assert attempt["qa_status"] == "ok"
    assert attempt["meaning_check"] == "leave#verlassen"
    assert attempt["meaning_check_result"] == result


def test_sent_schema_requires_nullable_enum_fields():
    fake = FakeCheck({"sense_key": None, "observed_pos": None,
                      "translation_ok": True, "language_ok": True, "reason": "Unklar."})
    meanings = [sense("leave#verlassen", "VERB", "verlassen"),
                sense("left#links", "ADJ", "links")]
    checked(fake, "Elias left early.", "Elias ging vorzeitig.", "left", meanings)
    assert fake.calls == 1
    for field, values in (("sense_key", [m["sense_key"] for m in meanings]),
                          ("observed_pos", POS_TAGS)):
        assert field in fake.schema["required"]
        assert fake.schema["properties"][field] == {
            "anyOf": [{"type": "string", "enum": values}, {"type": "null"}]}


@pytest.mark.parametrize("field", ["sense_key", "observed_pos"])
@pytest.mark.parametrize("case", ["null", "unknown", "integer", "boolean", "list", "object", "missing"])
def test_nullable_fields_never_allow_invalid_qa_or_card(field, case):
    response = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
                "translation_ok": True, "language_ok": True, "reason": "Prüfergebnis."}
    if case == "missing":
        del response[field]
    else:
        response[field] = {"null": None, "unknown": "UNKNOWN", "integer": 1,
                           "boolean": True, "list": [], "object": {}}[case]
    normalized = checked(FakeCheck(response), "Elias left early.", "Elias ging vorzeitig.",
                         "left", [sense("leave#verlassen", "VERB", "verlassen")])
    attempt = run_qa(load_config(), "Elias left early.", "Elias ging vorzeitig.",
                     "left", "leave#verlassen", "VERB", normalized)
    assert attempt["qa_status"] == "failed"
    expected = ("Bedeutung" if field == "sense_key" else "Wortart") if case == "null" else "Ungültige Prüfantwort"
    assert attempt["discard_reasons"] == [expected]
    # Even three annotated attempts cannot make a card when QA rejected them.
    attempt["tokens"] = []
    card = {"accepted": [dict(attempt) for _ in range(3)]}
    pack = assemble_pack("en", [card], model="fake", version="test")
    assert not card["packed"]
    assert pack["cards"] == [] and pack["sentences"] == []


@pytest.mark.parametrize("result", [
    {"sense_key": None, "observed_pos": "VERB", "translation_ok": True, "language_ok": True, "reason": "Unklar."},
    {"sense_key": "invented#key", "observed_pos": "VERB", "translation_ok": True, "language_ok": True,
     "reason": "Erfundener Schlüssel."},
    {"sense_key": "leave#verlassen", "observed_pos": "VERB", "translation_ok": True},
])
def test_null_unknown_and_incomplete_responses_never_pass(result):
    fake = FakeCheck(result)
    meanings = [sense("leave#verlassen", "VERB", "einen Ort verlassen")]
    normalized = checked(fake, "Elias left early.", "Elias ging vorzeitig.", "left", meanings)
    attempt = run_qa(load_config(), "Elias left early.", "Elias ging vorzeitig.",
                     "left", "leave#verlassen", "VERB", normalized)
    assert attempt["qa_status"] == "failed"
    assert attempt["discard_reasons"]
    if result["sense_key"] == "invented#key" or "observed_pos" not in result:
        assert attempt["discard_reasons"] == ["Ungültige Prüfantwort"]


def test_review_report_and_pack_keep_check_details(tmp_path):
    cfg = load_config()
    good_result = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
                   "translation_ok": True, "language_ok": True, "reason": "Passt."}
    failed_result = {"sense_key": "leave#verlassen", "observed_pos": "ADJ",
                     "translation_ok": False, "language_ok": True, "reason": "Wortart und Übersetzung weichen ab."}
    failed = {"text": "Elias left early.", "translation_de": "Elias ging früh.",
              "gap": (6, 10), "qa_status": "failed", "lint": [], "lint_rules": [],
              "blind": "passed", "blind_answer": "left", "meaning_check": "leave#verlassen",
              "meaning_check_result": failed_result, "discard_reason": "Wortart",
              "discard_reasons": ["Wortart", "Übersetzung"]}
    language_result = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
                       "translation_ok": True, "language_ok": False,
                       "reason": "Unidiomatische Wortverwendung."}
    unnatural = dict(failed, text="Elias left the sun light.", meaning_check_result=language_result,
                     discard_reason="Sprache", discard_reasons=["Sprache"])
    accepted = []
    slots = [[failed], [unnatural]]
    for idx, (sentence, gap) in enumerate([
            ("Elias left the concert early.", (6, 10)),
            ("Yesterday Elias left the concert.", (16, 20)),
            ("Elias left before the concert ended.", (6, 10))], start=1):
        attempt = {"text": sentence, "translation_de": "Elias verließ das Konzert vorzeitig.",
                   "gap": gap, "qa_status": "ok", "lint": [], "lint_rules": [],
                   "blind": "passed", "blind_answer": "left", "tokens": [],
                   "meaning_check": good_result["sense_key"],
                   "meaning_check_result": good_result, "discard_reason": "",
                   "discard_reasons": []}
        accepted.append(attempt)
        slots.append([attempt])
    card = {"form": "left", "lemma": "leave", "pos": "VERB", "sense_key": "leave#verlassen",
            "gloss_de": "einen Ort verlassen", "form_kind": "past",
            "form_label_de": "Verb, Vergangenheit", "translation_de": "verließ",
            "cefr_band": "anfaenger", "rank": 12, "accepted": accepted[:1], "slots": slots}
    pack = assemble_pack("en", [card], model="fake", version="test")
    saved = pack["sentences"][0]["qa_report"]
    assert saved["meaning_check"] == "leave#verlassen"
    assert saved["meaning_check_result"] == good_result
    assert saved["language_ok"] is True
    rows = review_rows([card])
    assert rows[0]["Prüfwortart"] == "ADJ"
    assert rows[0]["Übersetzungsprüfung"] == "fehlerhaft"
    assert rows[0]["verworfen_grund"] == "Wortart; Übersetzung"
    assert rows[0]["Sprachprüfung"] == "ok"
    assert rows[1]["Sprachprüfung"] == "fehlerhaft"
    assert rows[1]["verworfen_grund"] == "Sprache"
    assert rows[1]["Prüfbegründung"] == "Unidiomatische Wortverwendung."
    report_path = tmp_path / "run_report.md"
    write_run_report(report_path, cards=[card], skipped=[], ledger=tmp_path / "none.csv",
                     packed_cards=len(pack["cards"]), info={"forms": "smoke", "n_forms": 1,
                     "max_usd": 1.0})
    report = report_path.read_text(encoding="utf-8")
    assert "| Wortart | 1 |" in report
    assert "| Übersetzung | 1 |" in report
    assert "| Sprache | 1 |" in report
    json.dumps(pack)


GOOD = {"sense_key": "leave#verlassen", "observed_pos": "VERB", "translation_ok": True,
        "language_ok": True, "reason": "Prüfergebnis."}
LEAVE = [sense("leave#verlassen", "VERB", "verlassen")]


def test_schema_prompt_and_result_carry_language_ok():
    fake = FakeCheck(dict(GOOD))
    result = checked(fake, "Elias left early.", "Elias ging vorzeitig.", "left", LEAVE)
    assert fake.schema["properties"]["language_ok"] == {"type": "boolean"}
    assert "language_ok" in fake.schema["required"]
    assert load_prompt("meaning_check")[0] == "meaning-check-v6"
    assert "language_ok" in fake.prompt and "word boundaries" in fake.prompt
    for word in ("light", "about", "sunlight"):
        assert word not in load_prompt("meaning_check")[1]
    assert "sunlight" not in load_prompt("sentences")[1]
    assert result["language_ok"] is True and fake.calls == 1


def test_language_false_is_negative_verdict_not_invalid():
    # sense_key, observed_pos and translation_ok all match the card; only language_ok is false
    response = dict(GOOD, language_ok=False, reason="light ist hier nicht idiomatisch.")
    assert response["translation_ok"] is True and response["sense_key"] == "leave#verlassen"
    normalized = checked(FakeCheck(response), "Elias left early.", "Elias ging vorzeitig.", "left", LEAVE)
    assert normalized == response
    attempt = run_qa(load_config(), "Elias left early.", "Elias ging vorzeitig.",
                     "left", "leave#verlassen", "VERB", normalized)
    assert attempt["qa_status"] == "failed"
    assert attempt["discard_reasons"] == ["Sprache"]


@pytest.mark.parametrize("case", ["missing", "null", "string", "integer", "list"])
def test_language_ok_missing_or_wrong_type_is_invalid(case):
    response = dict(GOOD)
    if case == "missing":
        del response["language_ok"]
    else:
        response["language_ok"] = {"null": None, "string": "true", "integer": 1, "list": []}[case]
    normalized = checked(FakeCheck(response), "Elias left early.", "Elias ging vorzeitig.", "left", LEAVE)
    assert normalized["reason"].startswith("Ungültige Prüfantwort:")
    assert normalized["language_ok"] is False
    for result in (normalized, response):   # normalized by check() or raw from a callback
        attempt = run_qa(load_config(), "Elias left early.", "Elias ging vorzeitig.",
                         "left", "leave#verlassen", "VERB", result)
        assert attempt["qa_status"] == "failed"
        assert attempt["discard_reasons"] == ["Ungültige Prüfantwort"]


def test_old_pack_without_language_ok_still_builds():
    from pathlib import Path
    from sprachpipe.pack import build_rows, load_pack
    pack = load_pack(Path(__file__).parent / "fixtures" / "mini_pack.json")
    assert all("language_ok" not in (s.get("qa_report") or {}) for s in pack["sentences"])
    assert build_rows(pack)["sentences"]


class KwargsCheck(FakeCheck):
    def generate_json(self, prompt, schema, **kwargs):
        self.kwargs = kwargs
        return super().generate_json(prompt, schema, **kwargs)


def test_default_is_meaning_check_config_and_override_only_model_and_thinking():
    cfg = load_config()
    c = cfg["llm"]
    assert (c["meaning_check_model"], c["meaning_check_thinking"]) == ("gemini-3.8-flash",
                                                                       {"thinking_level": "LOW"})
    # only meaning_check gets the higher limit
    assert c["max_output_tokens"]["meaning_check"] == 4096
    assert c["max_output_tokens"] == {'meanings':2048, 'sentences':2048, 'annotate':4096,
        'blindtest':256, 'meaning_check':4096, 'classify_usage':1024, 'alternative_check':1024}
    assert (c["max_output_tokens"]["blindtest"], c["max_output_tokens"]["alternative_check"]) == (256, 1024)
    fake = KwargsCheck(dict(GOOD))
    check(fake, cfg, "Elias left early.", "left", LEAVE, "Elias ging vorzeitig.")
    assert fake.kwargs == {"model": "gemini-3.8-flash",
                           "thinking": {"thinking_level": "LOW"}, "step": "meaning_check",
                           "max_output_tokens": 4096}
    prompt, schema = fake.prompt, fake.schema
    check(fake, cfg, "Elias left early.", "left", LEAVE, "Elias ging vorzeitig.",
          model=c["blindtest_model"], thinking=c["blindtest_thinking"])
    assert fake.kwargs["model"] == c["blindtest_model"] == "gemini-2.5-flash"
    assert fake.kwargs["thinking"] == c["blindtest_thinking"] == {"thinking_budget": 0}
    assert fake.kwargs["max_output_tokens"] == cfg["llm"]["max_output_tokens"]["meaning_check"]
    assert (fake.prompt, fake.schema) == (prompt, schema)


TRUNCATED = '{\n  "sense_key": "leave#verlassen",\n  "observed_pos": "VERB",\n  "reason": "Die Pers'


def test_new_limit_is_reserved_before_call_and_broken_json_is_not_retried(tmp_path):
    from sprachpipe.llm import Llm, LlmError, cost_usd, model_price
    cfg = load_config()
    llm = Llm(cfg, tmp_path/'ledger.csv', 1.00)
    calls = []
    def fake_call(prompt, schema, model, thinking, max_output_tokens):
        calls.append(max_output_tokens)
        price = model_price(cfg['prices'], model)
        assert max_output_tokens == 4096
        assert llm._reserved == pytest.approx(cost_usd(price, len(prompt)//2+1, 4096, 0))
        assert llm._reserved > cost_usd(price, len(prompt)//2+1, 1024, 0)
        return TRUNCATED, (804,29,981), {'finish_reason':'MAX_TOKENS','usage_known':True}
    llm._call = fake_call
    with pytest.raises(LlmError) as err:
        check(llm, cfg, 'Elias left early.', 'left', LEAVE, 'Elias ging vorzeitig.')
    for part in ['max_output_tokens=4096','output_tokens=29','thinking_tokens=981','finish_reason=MAX_TOKENS']:
        assert part in str(err.value)
    assert calls == [4096]
    assert llm._reserved == pytest.approx(0)


def vertex_llm(tmp_path, response):
    """Real Llm wrapper (budget, ledger, _call) with a fake Vertex client."""
    from types import SimpleNamespace
    from sprachpipe.llm import Llm
    llm = Llm(load_config(), tmp_path / "ledger.csv", 1.0)
    llm._client = SimpleNamespace(models=SimpleNamespace(generate_content=lambda **kw: response))
    return llm


def test_truncated_json_is_visible_error_with_finish_metadata(tmp_path):
    import csv
    from types import SimpleNamespace
    from google.genai import types
    from sprachpipe.llm import LlmError
    response = SimpleNamespace(
        text=TRUNCATED, candidates=[SimpleNamespace(finish_reason=types.FinishReason.MAX_TOKENS)],
        usage_metadata=SimpleNamespace(prompt_token_count=830, candidates_token_count=30,
                                       thoughts_token_count=994))
    llm = vertex_llm(tmp_path, response)
    with pytest.raises(LlmError) as err:
        check(llm, load_config(), "Elias left early.", "left", LEAVE, "Elias ging vorzeitig.")
    message = str(err.value)
    assert message.startswith("meaning_check: Unterminated string starting at")
    for part in ("model=gemini-3.8-flash", "max_output_tokens=4096", "input_tokens=830",
                 "output_tokens=30", "thinking_tokens=994", "finish_reason=MAX_TOKENS"):
        assert part in message
    assert "Elias" not in message and "Die Pers" not in message   # no prompt, no response text
    assert isinstance(err.value.__cause__, json.JSONDecodeError)
    rows = list(csv.DictReader(open(tmp_path / "ledger.csv", encoding="utf-8")))
    assert [(r["step"], r["model"], r["output_tokens"]) for r in rows] == [
        ("meaning_check", "gemini-3.8-flash", "30")]


def test_parse_error_without_metadata_says_unknown(tmp_path):
    from types import SimpleNamespace
    from sprachpipe.llm import LlmError
    llm = vertex_llm(tmp_path, SimpleNamespace(text=TRUNCATED, candidates=None, usage_metadata=None))
    with pytest.raises(LlmError) as err:
        check(llm, load_config(), "Elias left early.", "left", LEAVE, "Elias ging vorzeitig.")
    message = str(err.value)
    for part in ("input_tokens=unbekannt", "output_tokens=unbekannt", "thinking_tokens=unbekannt",
                 "finish_reason=unbekannt", "max_output_tokens=4096"):
        assert part in message


def test_blindtest_keeps_its_own_model_and_thinking():
    from sprachpipe.blindtest import ask
    cfg = load_config()
    fake = KwargsCheck({"answer": "left", "alternatives": []})
    ask(fake, cfg, "Elias left early.", (6, 10), "Elias ging vorzeitig.", "verlassen")
    assert (fake.kwargs["model"], fake.kwargs["thinking"]) == ("gemini-2.5-flash", {"thinking_budget": 0})


def test_reason_contract_is_non_empty_in_prompt_schema_and_parser():
    fake = FakeCheck(dict(GOOD))
    checked(fake, "Elias left early.", "Elias ging vorzeitig.", "left", LEAVE)
    assert fake.schema["properties"]["reason"] == {"type": "string", "minLength": 1}
    assert "reason" in fake.schema["required"]
    assert "non-empty" in fake.prompt and "also when every check passes" in fake.prompt
    for reason in ("", " ", "\n\t"):
        normalized = checked(FakeCheck(dict(GOOD, reason=reason)), "Elias left early.",
                             "Elias ging vorzeitig.", "left", LEAVE)
        assert normalized["reason"].startswith("Ungültige Prüfantwort:")
        attempt = run_qa(load_config(), "Elias left early.", "Elias ging vorzeitig.",
                         "left", "leave#verlassen", "VERB", normalized)
        assert attempt["qa_status"] == "failed"
        assert attempt["discard_reasons"] == ["Ungültige Prüfantwort"]


@pytest.mark.parametrize("change,expected", [
    ({}, []),
    ({"reason": ""}, [("reason", "kein nicht-leerer String", "str", "")]),
    ({"reason": "  "}, [("reason", "kein nicht-leerer String", "str", "  ")]),
    ({"translation_ok": "true"}, [("translation_ok", "kein boolean", "str", "true")]),
    ({"language_ok": None}, [("language_ok", "kein boolean", "NoneType", None)]),
    ({"language_ok": None, "reason": ""}, [("language_ok", "kein boolean", "NoneType", None),
                                           ("reason", "kein nicht-leerer String", "str", "")]),
    ({"sense_key": "invented#key"}, [("sense_key", "nicht null und nicht in der Liste", "str",
                                      "invented#key")]),
    ({"extra": 1}, [("extra", "unbekanntes Feld", "int", 1)]),
])
def test_diagnostics_name_every_violation_without_changing_acceptance(change, expected):
    response = dict(GOOD, **change)
    plain = checked(FakeCheck(dict(response)), "Elias left early.", "Elias ging vorzeitig.", "left", LEAVE)
    diagnostics = {}
    result = check(FakeCheck(dict(response)), load_config(), "Elias left early.", "left", LEAVE,
                   "Elias ging vorzeitig.", diagnostics=diagnostics)
    assert result == plain
    assert diagnostics["response"] == response
    assert [(v["field"], v["problem"], v["type"], v["value"]) for v in diagnostics["violations"]] == expected
    assert plain["reason"].startswith("Ungültige Prüfantwort:") is bool(expected)


def test_missing_field_is_reported_not_filled():
    response = dict(GOOD)
    del response["language_ok"]
    diagnostics = {}
    result = check(FakeCheck(response), load_config(), "Elias left early.", "left", LEAVE,
                   "Elias ging vorzeitig.", diagnostics=diagnostics)
    assert "language_ok" not in diagnostics["response"]
    assert [(v["field"], v["problem"]) for v in diagnostics["violations"]] == [("language_ok", "fehlt")]
    assert result["reason"].startswith("Ungültige Prüfantwort:") and result["language_ok"] is False
    assert violations(None, []) == [{"field": None, "problem": "keine JSON-Objektantwort",
                                     "type": "NoneType", "value": None}]


@pytest.mark.parametrize("form,key", [("are", "be#sein_vollverb"), ("was", "be#sein_vollverb"),
                                      ("be", "be#sein_existieren"), ("be", "be#befinden")])
def test_corrected_copular_be_cards_need_matching_sense_and_aux(form, key):
    def result(sense_key, pos):
        return {"sense_key": sense_key, "observed_pos": pos, "translation_ok": True,
                "language_ok": True, "reason": "Kopula."}
    text = f"Elias {form} happy."
    ok = run_qa(load_config(), text, "x", form, key, "AUX", result(key, "AUX"))
    assert ok["qa_status"] == "ok"
    assert run_qa(load_config(), text, "x", form, key, "AUX", result(key, "VERB"))["discard_reasons"] == ["Wortart"]
    assert run_qa(load_config(), text, "x", form, key, "AUX",
                  result("be#hilfsverb", "AUX"))["discard_reasons"] == ["Bedeutung"]


def test_be_pos_convention_in_both_prompts():
    from sprachpipe.generate import load_prompt
    for name, version in (("meanings", "meanings-v5"), ("meaning_check", "meaning-check-v6")):
        v, text = load_prompt(name)
        assert v == version
        assert 'copular "be" (state, property, identity, location) is AUX' in text
        assert '"be" meaning "exist" is VERB' in text
