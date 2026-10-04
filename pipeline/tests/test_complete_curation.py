"""Targeted curation completion (scripts/complete_curation.py) with simulated
model answers. Synthetic packs from test_curate; no out/, no network.
Simulated answers prove processing, not live quality."""

import copy
import importlib.util
import json
import re

import pytest

from sprachpipe.config import PIPELINE_DIR, load_config
from sprachpipe.cost import BudgetExceeded, append_entry
from sprachpipe.curate import curate
from sprachpipe.llm import AuthError, LlmError

from test_curate import CURATION, META, PACKS, sid

SCRIPT = PIPELINE_DIR / "scripts" / "complete_curation.py"
spec = importlib.util.spec_from_file_location("complete_curation", SCRIPT)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)

CFG = load_config()
NEW = "Ben went home after work."
FIXED = "They went out yesterday."
SISTER = "We went to the park."


class Inventory:
    meanings = {"went": [{"sense_key": "go#gehen", "pos": "VERB", "form_kind": "past",
                          "form_label_de": "Präteritum", "gloss_de": "ging (gehen)"}],
                "up": [{"sense_key": "up#hinauf", "pos": "ADV", "form_kind": "base",
                        "form_label_de": "Grundform", "gloss_de": "hinauf"}],
                "at": [{"sense_key": "at#zeit", "pos": "ADP", "form_kind": "base",
                        "form_label_de": "Grundform", "gloss_de": "um"}]}

    def get(self, form):
        return copy.deepcopy(self.meanings.get(form))

    def display_form(self, form):
        return form


class FakeLlm:
    """meaning: text -> verdict overrides; blind: text -> raw answer;
    alternatives: candidate -> valid (missing = invalid response);
    fail: (call number, exception)."""
    def __init__(self, meaning=None, blind=None, alternatives=None, fail=None, ledger=None):
        self.meaning, self.blind = meaning or {}, blind or {}
        self.alternatives = {"walked": False} if alternatives is None else alternatives
        self.fail, self.ledger = fail, ledger
        self.calls = []

    def generate_json(self, prompt, schema, *, step, model, **kwargs):
        if self.fail and len(self.calls) + 1 == self.fail[0]:
            raise self.fail[1]
        self.calls.append((step, prompt))
        if self.ledger:
            append_entry(self.ledger, step=step, model=model, input_tokens=1, output_tokens=1,
                         thinking_tokens=0, usd=0.001)
        text = next((t for t in (NEW, FIXED, SISTER) if t in prompt
                     or t.replace("went", "___") in prompt), None)
        if step == "blindtest":
            return self.blind.get(text, {"answer": "went", "alternatives": []})
        if step == "meaning_check":
            return dict({"sense_key": "go#gehen", "observed_pos": "VERB", "translation_ok": True,
                         "language_ok": True, "reason": "passt"}, **self.meaning.get(text, {}))
        if step == "alternative_check":
            cands = re.findall(r'inserted: "([^"]+)"', prompt)
            if any(c not in self.alternatives for c in cands):
                return {"results": []}
            return {"results": [{"candidate_index": i, "valid": self.alternatives[c], "reason": "r"}
                                for i, c in enumerate(cands, start=1)]}
        if step == "annotate":
            out = []
            for block in re.split(r"(?=Sentence \d+: )", prompt):
                m = re.match(r"Sentence (\d+): ", block)
                if not m:
                    continue
                toks = re.findall(r"^(\d+): (\S+)$", block, flags=re.M)
                out.append({"sentence_idx": int(m.group(1)), "tokens": [
                    {"token_idx": int(i), "surface": s, "lemma": s.lower(), "gloss_de": f"{s.lower()}-de"}
                    for i, s in toks]})
            return {"sentences": out}
        raise AssertionError(step)


def setup():
    work, _ = curate(PACKS, CURATION, META)
    cards = {ref: script.card_info(work, Inventory(), ref) for ref in [c["ref"] for c in work["cards"]]}
    return work, cards


def run(llm, work=None):
    work, cards = (work, None) if work else setup()
    cards = cards or {ref: script.card_info(work, Inventory(), ref) for ref in [c["ref"] for c in work["cards"]]}
    saves = []
    report, aborted = script.run(llm, CFG, work, cards,
                                 lambda w, r: saves.append(copy.deepcopy((w, r))))
    return work, report, aborted, saves


def steps(llm):
    return [s for s, _ in llm.calls]


def links(work, card="went|go/VERB|go#gehen"):
    texts = {s["ref"]: s for s in work["sentences"]}
    return [(cs, texts[cs["sentence"]]) for cs in sorted(
        (cs for cs in work["card_sentences"] if cs["card"] == card), key=lambda c: c["position"])]


def test_only_planned_sentences_and_card_are_processed():
    llm = FakeLlm()
    work, report, aborted, _ = run(llm)
    assert aborted is None
    assert steps(llm) == ["meaning_check", "blindtest", "meaning_check", "alternative_check", "annotate"]
    assert FIXED in llm.calls[0][1] and NEW.replace("went", "___") in llm.calls[1][1]
    # the annotation covers exactly the three sentences of the one changed card
    annotate_prompt = llm.calls[4][1]
    assert all(t in annotate_prompt for t in (NEW, SISTER, FIXED)) and "Eva" not in annotate_prompt
    kinds = {s["kind"]: s["status"] for s in report["steps"]}
    assert kinds == {"translation_check": "closed", "sentence_qa": "closed",
                     "annotate_card": "closed", "dictionary_forms": "open"}
    (_, new), (_, sister), (_, fixed) = links(work)
    assert new["qa_status"] == "ok"
    assert new["qa_report"]["checked"] == {"text": NEW, "translation_de": new["translation_de"],
                                           "gap": [4, 8]}
    assert new["qa_report"]["curation"]["replaces_sentence_id"] == sid("She went home early.")
    # translation-only: result bound to exactly the checked text and translation, old QA as history
    check = fixed["qa_report"]["curation_translation_check"]
    assert check["checked"] == {"text": FIXED, "translation_de": "Sie sind gestern ausgegangen."}
    assert fixed["qa_report"]["history"] == PACKS["base"]["sentences"][2]["qa_report"]


def test_reannotation_reports_changes_on_unchanged_sister_sentences():
    work, report, _, _ = run(FakeLlm())
    [ann] = [s for s in report["steps"] if s["kind"] == "annotate_card"]
    by_ref = {c["text"]: c for c in ann["sentences"]}
    assert by_ref[NEW]["replaced_sentence"] is True
    sister = by_ref[SISTER]
    assert sister["replaced_sentence"] is False and sister["token_changes"]
    change = next(c for c in sister["token_changes"] if c["surface"] == "park")
    assert change["old"] == {"lemma": None, "sense": None, "card": None}
    assert change["new"]["sense"] == "park/NOUN|park#park-de"
    # card token keeps the card sense
    card_tokens = [t for t in work["sentence_tokens"] if t["card"] == "went|go/VERB|go#gehen"]
    assert len(card_tokens) == 3 and {t["sense"] for t in card_tokens} == {"go/VERB|go#gehen"}


def test_rejection_stays_open_and_blocks_only_dependent_steps():
    llm = FakeLlm(meaning={NEW: {"language_ok": False, "reason": "unnatürlich"}})
    work, report, aborted, _ = run(llm)
    assert aborted is None and "annotate" not in steps(llm)
    pending = {p["kind"]: p for p in work["curation"]["pending"]}
    assert set(pending) == {"sentence_qa", "annotate_card", "dictionary_forms"}
    assert pending["sentence_qa"]["findings"] == ["Sprache", "Prüfbegründung: unnatürlich"]
    (cs, new), _, (_, fixed) = links(work)
    assert new["qa_status"] == "pending" and cs["valid_alternatives"] == []
    assert "curation_translation_check" in fixed["qa_report"]   # independent step closed
    assert not [t for t in work["sentence_tokens"] if t["sentence"] == new["ref"]]


def test_rejected_translation_keeps_step_open_without_touching_history():
    llm = FakeLlm(meaning={FIXED: {"translation_ok": False, "reason": "Tempus"}})
    work, report, _, _ = run(llm)
    step = next(p for p in work["curation"]["pending"] if p["kind"] == "translation_check")
    assert step["findings"] == ["Übersetzung abgelehnt: Tempus"]
    fixed = links(work)[2][1]
    assert fixed["qa_report"] == PACKS["base"]["sentences"][2]["qa_report"]


def test_only_confirmed_alternatives_are_taken_over():
    llm = FakeLlm(blind={NEW: {"answer": "went", "alternatives": [
        {"answer": "walked", "reason": "x"}, {"answer": "ran", "reason": "y"}]}},
        alternatives={"walked": True, "ran": False})
    work, report, _, _ = run(llm)
    cs, _ = links(work)[0]
    assert cs["valid_alternatives"] == ["walked"]
    # dropped alternative 'walked' was already a blind candidate: no second call
    assert steps(llm).count("alternative_check") == 1


def test_dropped_alternatives_are_rechecked_and_invalid_answers_stay_open():
    confirmed = FakeLlm(alternatives={"walked": False})
    work, report, _, _ = run(confirmed)
    qa = next(s for s in report["steps"] if s["kind"] == "sentence_qa")
    assert [r["candidate"] for r in qa["recheck_alternative_check"]] == ["walked"]
    assert links(work)[0][0]["valid_alternatives"] == []
    invalid = FakeLlm(alternatives={})
    work, report, _, _ = run(invalid)
    step = next(p for p in work["curation"]["pending"] if p["kind"] == "sentence_qa")
    assert step["findings"] == ["Ungültige Prüfantwort: erneute Alternativprüfung"]
    assert links(work)[0][0]["valid_alternatives"] == []


def test_unconfirmed_blind_answer_is_a_rejection_without_regeneration():
    llm = FakeLlm(blind={NEW: {"answer": "walked", "alternatives": []}}, alternatives={"walked": False})
    work, report, _, _ = run(llm)
    step = next(p for p in work["curation"]["pending"] if p["kind"] == "sentence_qa")
    assert step["findings"][0] == "Blindtest"
    assert steps(llm).count("blindtest") == 1 and "annotate" not in steps(llm)


@pytest.mark.parametrize("error", [BudgetExceeded("limit"), AuthError("Vertex 403"),
                                   LlmError("ConnectionError: down")])
def test_budget_auth_and_transport_errors_abort_visibly_with_saved_state(error):
    llm = FakeLlm(fail=(3, error))   # third call: meaning_check of the replaced sentence
    work, report, aborted, saves = run(llm)
    assert aborted == f"{type(error).__name__}: {error}"
    last_work, last_report = saves[-1]
    assert last_report["aborted"] == aborted
    kinds = sorted(p["kind"] for p in last_work["curation"]["pending"])
    assert kinds == ["annotate_card", "dictionary_forms", "sentence_qa"]
    assert [c["kind"] for c in last_work["curation"]["completed"]] == ["translation_check"]


def test_dictionary_reuses_source_values_with_origin_and_takes_annotation_values():
    packs = copy.deepcopy(PACKS)
    packs["extra"]["dictionary_forms"] = []
    packs["base"]["dictionary_forms"] = [
        {"form": "went", "sense": "go/VERB|go#gehen", "card": "went|go/VERB|go#gehen",
         "gloss_de": "ging (gehen)", "rank": 1}]
    work, _ = curate(packs, CURATION, META)
    work, report, _, _ = run(FakeLlm(), work)
    d = script.derive_dictionary(work)
    went = next(e for e in d["entries"] if e["form"] == "went")
    assert went["gloss_de"] == "ging (gehen)" and went["card"] == "went|go/VERB|go#gehen"
    assert went["origin"]["sources"] == {"base": {"card": "went|go/VERB|go#gehen", "rank": 1}}
    assert len(went["origin"]["annotation"]) == 3   # same value from the new annotation
    park = next(e for e in d["entries"] if e["form"] == "park")
    assert park["gloss_de"] == "park-de" and "sources" not in park["origin"]
    # unannotated sentences of other cards have no form translation: open, no sense gloss fallback
    assert any(m["form"] == "at" for m in d["missing"])
    assert work["dictionary_forms"] == []
    assert next(p for p in work["curation"]["pending"] if p["kind"] == "dictionary_forms")["missing_keys"]


def test_conflicting_form_translations_stay_open():
    packs = copy.deepcopy(PACKS)
    packs["base"]["dictionary_forms"] = [
        {"form": "went", "sense": "go/VERB|go#gehen", "card": None, "gloss_de": "ging", "rank": 1}]
    work, _ = curate(packs, CURATION, META)
    work, _, _, _ = run(FakeLlm(), work)
    d = script.derive_dictionary(work)
    [conflict] = [c for c in d["conflicts"] if c["form"] == "went"]
    assert {v["gloss_de"] for v in conflict["values"]} == {"ging", "ging (gehen)"}


def test_complete_dictionary_closes_its_step_and_ranks_by_token_count():
    packs = copy.deepcopy(PACKS)
    packs["base"]["dictionary_forms"] = packs["extra"]["dictionary_forms"] = []
    work, _ = curate(packs, CURATION, META)
    # pretend every token key already carries one form translation
    work, _, _, _ = run(FakeLlm(), work)
    for t in work["sentence_tokens"]:
        if t.get("sense") and not any(g["sentence"] == t["sentence"] and g["idx"] == t["idx"]
                                      for g in work["curation"]["annotation_glosses"]):
            work["curation"]["dictionary_sources"].append(
                {"form": t["surface"].lower(), "sense": t["sense"],
                 "values": [{"gloss_de": "g", "sources": {"base": {"card": None, "rank": 1}}}]})
    step = next(p for p in work["curation"]["pending"] if p["kind"] == "dictionary_forms")
    script.run_dictionary(work, step, {"steps": []})
    assert work["curation"]["pending"] == []
    assert work["dictionary_forms"] and all(e["rank"] >= 1 for e in work["dictionary_forms"])


def test_main_dry_run_refuses_existing_output_and_never_touches_inputs(tmp_path, capsys, monkeypatch):
    paths = []
    for name, pack in PACKS.items():
        path = tmp_path / f"{name}.json"
        path.write_text(json.dumps(pack), encoding="utf-8")
        paths.append(f"{name}={path}")
    curation = tmp_path / "curation.json"
    curation.write_text(json.dumps(CURATION), encoding="utf-8")
    before = {p: (tmp_path / p).read_bytes() for p in ("base.json", "extra.json")}
    args = sum([["--pack", p] for p in paths], []) + ["--curation", str(curation)]
    inv = Inventory()

    monkeypatch.setattr("sprachpipe.curate.card_meta_from_inventory", lambda packs, inventory: META)
    assert script.main(args + ["--out", str(tmp_path / "run"), "--max-usd", "0.5", "--dry-run"],
                       inventory=inv) == 0
    out = capsys.readouterr().out
    assert "sentence_qa test-curation-v1/base/s1" in out and "dry run" in out
    assert not (tmp_path / "run").exists()
    (tmp_path / "exists").mkdir()
    assert script.main(args + ["--out", str(tmp_path / "exists"), "--max-usd", "0.5"],
                       inventory=inv) == 2
    assert script.main(args + ["--out", str(tmp_path / "run2")], inventory=inv) == 2
    # live path with a simulated llm: own ledger, state and report in the new folder
    code = script.main(args + ["--out", str(tmp_path / "run3"), "--max-usd", "0.5"], inventory=inv,
                       llm_factory=lambda cfg, ledger, max_usd: FakeLlm(ledger=ledger))
    assert code == 1   # dictionary keys of unannotated synthetic sentences stay open
    assert {p.name for p in (tmp_path / "run3").iterdir()} == {"ledger.csv", "working_state.json",
                                                               "report.json"}
    report = json.loads((tmp_path / "run3" / "report.json").read_text(encoding="utf-8"))
    assert report["cost_usd"] == 0.005 and report["aborted"] is None
    assert before == {p: (tmp_path / p).read_bytes() for p in ("base.json", "extra.json")}
