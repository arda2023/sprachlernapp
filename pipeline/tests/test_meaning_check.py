import json

import pytest

from sprachpipe.config import load_config
from sprachpipe.generate import POS_TAGS, qa_sentence
from sprachpipe.meaning_check import check
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
                "translation_ok": False, "reason": "early meint hier vorzeitig."}
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
    assert version == "sentences-v4"
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
                      "translation_ok": True, "reason": "up steht vor einer Nominalgruppe."})
    result = checked(fake, sentence, translation, "up", meanings)
    assert "up#entlang: POS=ADP" in fake.prompt
    attempt = run_qa(load_config(), sentence, translation, "up", "up#hinauf", "ADV", result)
    assert attempt["qa_status"] == "failed"
    assert attempt["discard_reasons"] == ["Wortart"]


def test_matching_sense_pos_and_translation_pass():
    result = {"sense_key": "leave#verlassen", "observed_pos": "VERB",
              "translation_ok": True, "reason": "Die Person verließ den Ort."}
    attempt = run_qa(load_config(), "Elias left the concert early yesterday.",
                     "Elias verließ das Konzert gestern vorzeitig.",
                     "left", "leave#verlassen", "VERB", result)
    assert attempt["qa_status"] == "ok"
    assert attempt["meaning_check"] == "leave#verlassen"
    assert attempt["meaning_check_result"] == result


def test_sent_schema_requires_nullable_enum_fields():
    fake = FakeCheck({"sense_key": None, "observed_pos": None,
                      "translation_ok": True, "reason": "Unklar."})
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
                "translation_ok": True, "reason": "Prüfergebnis."}
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
    {"sense_key": None, "observed_pos": "VERB", "translation_ok": True, "reason": "Unklar."},
    {"sense_key": "invented#key", "observed_pos": "VERB", "translation_ok": True,
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
                   "translation_ok": True, "reason": "Passt."}
    failed_result = {"sense_key": "leave#verlassen", "observed_pos": "ADJ",
                     "translation_ok": False, "reason": "Wortart und Übersetzung weichen ab."}
    failed = {"text": "Elias left early.", "translation_de": "Elias ging früh.",
              "gap": (6, 10), "qa_status": "failed", "lint": [], "lint_rules": [],
              "blind": "passed", "blind_answer": "left", "meaning_check": "leave#verlassen",
              "meaning_check_result": failed_result, "discard_reason": "Wortart",
              "discard_reasons": ["Wortart", "Übersetzung"]}
    accepted = []
    slots = [[failed]]
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
            "cefr_band": "anfaenger", "rank": 12, "accepted": accepted, "slots": slots}
    pack = assemble_pack("en", [card], model="fake", version="test")
    saved = pack["sentences"][0]["qa_report"]
    assert saved["meaning_check"] == "leave#verlassen"
    assert saved["meaning_check_result"] == good_result
    rows = review_rows([card])
    assert rows[0]["Prüfwortart"] == "ADJ"
    assert rows[0]["Übersetzungsprüfung"] == "fehlerhaft"
    assert rows[0]["verworfen_grund"] == "Wortart; Übersetzung"
    report_path = tmp_path / "run_report.md"
    write_run_report(report_path, cards=[card], skipped=[], ledger=tmp_path / "none.csv",
                     packed_cards=len(pack["cards"]), info={"forms": "smoke", "n_forms": 1,
                     "max_usd": 1.0})
    report = report_path.read_text(encoding="utf-8")
    assert "| Wortart | 1 |" in report
    assert "| Übersetzung | 1 |" in report
    json.dumps(pack)
