import csv
import json
import re
from types import SimpleNamespace

import pytest

from sprachpipe import llm as llm_mod
from sprachpipe.blindtest import judge
from sprachpipe.cli import run_generate
from sprachpipe.config import load_config
from sprachpipe.cost import BudgetExceeded, total_usd
from sprachpipe.generate import gap_offsets, qa_sentence, slot_context
from sprachpipe.linter import Finding
from sprachpipe.meaning_check import check as check_meaning
from sprachpipe.quality import duplicate
from sprachpipe.review import REVIEW_COLUMNS

WENT = {"pos": "VERB", "lemma": "go", "sense_key": "go#gehen",
        "gloss_de": "gehen (sich fortbewegen)", "form_kind": "past",
        "form_label_de": "Verb, Vergangenheit", "cefr_band": "anfaenger",
        "translation_de": "ging"}
SENTENCES = ["She went home after work.", "We went to the beach on Sunday.",
             "They went to school by bus yesterday.", "I went downtown on Monday.",
             "The children went outside before dinner.",
             "My parents went shopping this morning.",
             "Our teacher went into the classroom.",
             "The dog went through the open gate."]


class FakeVertex(llm_mod.Llm):
    def __init__(self, cfg, ledger, max_usd, *, usage=(100, 50, 10),
                 sentences=None, answers=None, senses=None):
        super().__init__(cfg, ledger, max_usd)
        self.usage = usage
        self.sentences = iter(sentences or SENTENCES)
        self.answers = answers or {}
        self.senses = senses or {}
        self.calls = []
        self.prompts = []

    def _call(self, prompt, schema, model, thinking, max_output_tokens):
        key = next(iter(schema["properties"]))
        self.calls.append(key)
        self.prompts.append(prompt)
        if key == "meanings":
            out = {"meanings": [WENT]}
        elif key == "sentences":
            out = {"sentences": [{"text": next(self.sentences), "translation_de": "Deutsch."}]}
        elif key == "tokens":
            toks = re.findall(r"^(\d+): (.+)$", prompt, flags=re.M)
            out = {"tokens": [{"token_idx": int(i), "surface": s, "lemma": s.lower(),
                               "gloss_de": "x"} for i, s in toks]}
        elif key == "sense_key":
            text = re.search(r"^Sentence: (.+)$", prompt, flags=re.M).group(1)
            out = {"sense_key": self.senses.get(text, WENT["sense_key"])}
        else:
            match = re.search(r"^Sentence: (.+)$", prompt, flags=re.M)
            text = match.group(1) if match else ""
            out = {"answer": self.answers.get(text, "went")}
        return json.dumps(out), self.usage


@pytest.fixture
def cfg(monkeypatch):
    monkeypatch.setattr("sprachpipe.quality.lemma_ranks", lambda cfg: {})
    return load_config()


def run(cfg, tmp_path, llm):
    aborted = run_generate(llm, cfg, [("went", 50)], tmp_path / "pack.json", tmp_path,
                           max_usd=llm.max_usd, label="test")
    return aborted, json.loads((tmp_path / "pack.json").read_text(encoding="utf-8"))


def test_gap_offsets():
    assert gap_offsets("She went home.", "went") == (4, 8)
    assert gap_offsets("Wentworth went home.", "went") == (10, 14)
    assert gap_offsets("Went home, she did.", "went") == (0, 4)
    assert gap_offsets("She is home.", "went") is None


def test_five_candidates_pack_only_ok(cfg, tmp_path):
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 1.0)
    aborted, pack = run(cfg, tmp_path, llm)
    assert aborted is None
    assert llm.calls.count("sentences") == 5
    assert llm.calls.count("sense_key") == 5
    assert len(pack["card_sentences"]) == 3
    texts = {s["ref"]: s for s in pack["sentences"]}
    for cs in pack["card_sentences"]:
        sn = texts[cs["sentence"]]
        assert sn["text"][cs["gap_start"]:cs["gap_end"]] == "went"
        assert sn["qa_status"] == "ok" and cs["accepted"] == ["went"]


def test_second_round_of_three_after_duplicate_rejections(cfg, tmp_path):
    texts = [SENTENCES[0]] * 5 + SENTENCES[1:4]
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 1.0, sentences=texts)
    aborted, pack = run(cfg, tmp_path, llm)
    assert aborted is None
    assert llm.calls.count("sentences") == 8
    assert len(pack["card_sentences"]) == 3
    review = list(csv.DictReader(open(tmp_path / "review.csv", encoding="utf-8-sig"), delimiter=";"))
    assert sum(r["verworfen_grund"] == "Duplikat" for r in review) == 4
    assert "| Duplikat | 4 |" in (tmp_path / "run_report.md").read_text(encoding="utf-8")


def test_blind_mismatch_feedback_in_generation(cfg, tmp_path):
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 1.0,
                     sentences=SENTENCES[:6], answers={SENTENCES[0].replace("went", "___"): "walked"})
    aborted, pack = run(cfg, tmp_path, llm)
    assert aborted is None
    assert llm.calls.count("sentences") == 6
    assert any("walked" in p and 'only the target form "went"' in p for p in llm.prompts)
    assert SENTENCES[0] not in [s["text"] for s in pack["sentences"]]
    review = list(csv.DictReader(open(tmp_path / "review.csv", encoding="utf-8-sig"), delimiter=";"))
    assert any(r["Modellantwort bei Abweichung"] == "walked" for r in review)


def test_budget_abort_keeps_results(cfg, tmp_path):
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 0.01, usage=(1000, 1000, 0))
    aborted, pack = run(cfg, tmp_path, llm)
    assert aborted.startswith("BudgetExceeded")
    assert llm.calls == ["meanings"]
    assert total_usd(tmp_path / "ledger.csv") <= 0.01
    assert (tmp_path / "review.csv").exists()
    assert "Abgebrochen" in (tmp_path / "run_report.md").read_text(encoding="utf-8")
    assert pack["cards"] == []


def test_no_call_without_check_budget(cfg, tmp_path, monkeypatch):
    order = []
    real = llm_mod.check_budget
    monkeypatch.setattr(llm_mod, "check_budget",
                        lambda *a, **kw: (order.append("check"), real(*a, **kw))[1])
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 1.0)
    orig = llm._call
    llm._call = lambda *a: (order.append("call"), orig(*a))[1]
    llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                      thinking={}, step="blindtest", max_output_tokens=10)
    assert order == ["check", "call"]
    order.clear()
    llm.max_usd = 0.0
    with pytest.raises(BudgetExceeded):
        llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                          thinking={}, step="blindtest", max_output_tokens=10)
    assert order == ["check"]


def test_ledger_records_vertex_thoughts_metadata(cfg, tmp_path):
    metadata = SimpleNamespace(prompt_token_count=1_000_000, candidates_token_count=0,
                               thoughts_token_count=1_000_000, total_token_count=2_000_000)
    assert llm_mod.usage_counts(metadata) == (1_000_000, 0, 1_000_000)
    llm = FakeVertex(cfg, tmp_path / "ledger.csv", 1.0, usage=llm_mod.usage_counts(metadata))
    llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                      thinking={}, step="blindtest", max_output_tokens=10)
    row = next(csv.DictReader(open(tmp_path / "ledger.csv", encoding="utf-8")))
    assert row["thinking_tokens"] == "1000000"
    assert float(row["usd"]) == pytest.approx(0.30 + 2.50)


def test_blind_mismatch_regenerates_once_with_answer(cfg):
    answers = iter(["walked", "walked"])
    feedback = []
    attempts = qa_sentence({"text": "She went home.", "translation_de": "x"},
                           {"form": "went", "sense_key": "go#gehen"}, cfg,
                           regenerate=lambda fb: (feedback.append(fb), {"text": "He went out.", "translation_de": "y"})[1],
                           lint=lambda *a: [], blind=lambda *a: next(answers),
                           judge=lambda a: judge(a, "went", ["went"], "go", None, None))
    assert [a["qa_status"] for a in attempts] == ["replaced", "failed"]
    assert len(feedback) == 1 and "walked" in feedback[0]
    assert 'only the target form "went"' in feedback[0]
    assert judge("walked", "went", ["went", "walked"], "go", None, None) == "failed"


def test_linter_retry_and_duplicate(cfg):
    findings = iter([[Finding("error", "length", "bad")], []])
    attempts = qa_sentence({"text": "She went home.", "translation_de": "x"},
                           {"form": "went", "sense_key": "go#gehen"}, cfg,
                           regenerate=lambda fb: {"text": "He went out.", "translation_de": "y"},
                           lint=lambda *a: next(findings), blind=lambda *a: "went",
                           judge=lambda a: "passed")
    assert [a["qa_status"] for a in attempts] == ["replaced", "ok"]
    accepted = [{"text": "Mia went to the shop today.", "gap": (4, 8)}]
    assert duplicate("Mia went to the shop later.", (4, 8), accepted)
    assert duplicate("Mia went to the park.", (4, 8), accepted)
    assert not duplicate("Leo went home after lunch.", (4, 8), accepted)


def test_meaning_check_rejects_left_keys(cfg):
    class Fake:
        def generate_json(self, prompt, schema, **kwargs):
            assert "left#verlassen: verlassen (einen Ort verlassen)" in prompt
            assert "left#zuruecklassen: zurücklassen (etwas liegen lassen)" in prompt
            return {"sense_key": "left#zuruecklassen"}
    meanings = [{"sense_key": "left#verlassen", "gloss_de": "verlassen (einen Ort verlassen)"},
                {"sense_key": "left#zuruecklassen", "gloss_de": "zurücklassen (etwas liegen lassen)"}]
    answer = check_meaning(Fake(), cfg, "Tom left his keys.", "left", meanings)
    attempts = qa_sentence({"text": "Tom left his keys.", "translation_de": "Tom ließ seine Schlüssel liegen."},
                           {"form": "left", "sense_key": "left#verlassen"}, cfg,
                           regenerate=lambda fb: pytest.fail("meaning mismatch must be discarded"),
                           lint=lambda *a: [], blind=lambda *a: "left", judge=lambda a: "passed",
                           meaning_check=lambda text: answer)
    assert attempts[-1]["qa_status"] == "failed"
    assert attempts[-1]["discard_reason"] == "Bedeutung"


def test_situations_are_stable_and_distinct(cfg):
    card = {"form": "went", "sense_key": "go#gehen"}
    first = [slot_context(cfg, card, i) for i in range(8)]
    assert first == [slot_context(cfg, card, i) for i in range(8)]
    assert len({s for s, _ in first}) == 8
    assert all(name not in ("Tom", "Anna") for _, name in first)


def test_review_csv_and_report(cfg, tmp_path):
    run(cfg, tmp_path, FakeVertex(cfg, tmp_path / "ledger.csv", 1.0))
    raw = (tmp_path / "review.csv").read_bytes()
    assert raw.startswith(b"\xef\xbb\xbf")
    rows = list(csv.reader(raw.decode("utf-8-sig").splitlines(), delimiter=";"))
    assert rows[0] == REVIEW_COLUMNS and len(rows) == 6
    report = (tmp_path / "run_report.md").read_text(encoding="utf-8")
    assert "## Verworfene Sätze je Grund" in report
    assert "i+1-Verstöße" in report
