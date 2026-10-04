import json
import re
import time
from concurrent.futures import ThreadPoolExecutor
from threading import Lock

import pytest

from sprachpipe.cli import run_generate
from sprachpipe.config import load_config
from sprachpipe.cost import BudgetExceeded, total_usd
from sprachpipe.inventory import MeaningInventory
from sprachpipe.llm import Llm, LlmError, RetryableError


def meaning(form, lemma, key, gloss):
    return {"pos": "VERB", "lemma": lemma, "sense_key": key, "gloss_de": gloss,
            "form_kind": "past", "form_label_de": "Verb, Vergangenheit",
            "cefr_band": "anfaenger", "translation_de": gloss, "usage": "haupt"}


class ParallelFake(Llm):
    def __init__(self, cfg, ledger):
        super().__init__(cfg, ledger, 1.0)
        self.lock = Lock()
        self.active = 0
        self.max_active = 0

    def _call(self, prompt, schema, model, thinking, max_output_tokens):
        with self.lock:
            self.active += 1
            self.max_active = max(self.max_active, self.active)
        try:
            time.sleep(0.005)
            key = next(iter(schema["properties"]))
            if key == "sentences" and "sentence_idx" in schema["properties"]["sentences"]["items"]["properties"]:
                groups = []
                for idx, block in re.findall(r"Sentence (\d+): (.*?)(?=Sentence \d+:|For EVERY|\Z)",
                                             prompt, flags=re.S):
                    groups.append({"sentence_idx": int(idx), "tokens": [
                        {"token_idx": int(i), "surface": surface, "lemma": surface.lower(),
                         "gloss_de": "x"} for i, surface in re.findall(r"^(\d+): (.+)$", block, flags=re.M)]})
                result = {"sentences": groups}
            elif key == "sentences":
                form = re.search(r'^- form: "([^"]+)', prompt, flags=re.M).group(1)
                names = ["Mia", "Yesterday", "Leo", "Sara", "Today"]
                n = schema["properties"]["sentences"]["minItems"]
                result = {"sentences": [{"text": f"{name} {form} home after work.",
                                          "translation_de": "Deutsch."} for name in names[:n]]}
            elif key == "answer":
                result = ({"answer": "went", "alternatives": []} if "gehen" in prompt else
                          {"answer": "left", "alternatives": [{"answer": "Departed", "reason": "Gleicher Sinn."}]})
            elif key == "sense_key":
                result = {"sense_key": "go#gehen" if "go#gehen" in prompt else "leave#verlassen",
                          "observed_pos": "VERB", "translation_ok": True, "reason": "Passt."}
            elif key == "results":
                n = len(re.findall(r"^\d+\. inserted: ", prompt, flags=re.M))
                result = {"results": [{"candidate_index": i, "valid": True, "reason": "Passt."}
                                      for i in range(1, n + 1)]}
            else:
                raise AssertionError(key)
            return json.dumps(result), (100, 50, 0)
        finally:
            with self.lock:
                self.active -= 1


def test_same_pack_with_concurrency_one_and_eight(tmp_path):
    outputs = []
    active = []
    for concurrency in (1, 8):
        folder = tmp_path / str(concurrency)
        inventory_path = folder / "inventory.json"
        inv = MeaningInventory("en", inventory_path)
        inv.append("went", [meaning("went", "go", "go#gehen", "gehen")], 4)
        inv.append("left", [meaning("left", "leave", "leave#verlassen", "verlassen")], 4)
        cfg = load_config()
        cfg["generate"]["concurrency"] = concurrency
        fake = ParallelFake(cfg, folder / "ledger.csv")
        aborted = run_generate(fake, cfg, [("went", 50), ("left", 60)],
                               folder / "pack.json", folder, max_usd=1.0, label="test",
                               inventory_path=inventory_path)
        assert aborted is None
        pack = json.loads((folder / "pack.json").read_text(encoding="utf-8"))
        assert len(pack["cards"]) == 2
        senses = {s["ref"]: s["sense_key"] for s in pack["senses"]}
        assert {(c["form"], senses[c["sense"]]) for c in pack["cards"]} == {
            ("went", "go#gehen"), ("left", "leave#verlassen")}
        assert len(pack["sentences"]) == 6
        assert all(s["qa_status"] == "ok" for s in pack["sentences"])
        sentence_refs = {s["ref"] for s in pack["sentences"]}
        for card in pack["cards"]:
            rows = [s for s in pack["card_sentences"] if s["card"] == card["ref"]]
            assigned = [s["sentence"] for s in rows]
            assert len(assigned) == len(set(assigned)) == 3
            assert set(assigned) <= sentence_refs
            assert all(s["accepted"] == [card["form"]] for s in rows)
            assert all(s["valid_alternatives"] == (["departed"] if card["form"] == "left" else [])
                       for s in rows)
        print(f"concurrency={concurrency}: cards=2 sentences=6 per_card=3 qa_status=ok")
        outputs.append(pack)
        active.append(fake.max_active)
        assert "forms 2/2" in (folder / "progress.txt").read_text(encoding="ascii")
    assert outputs[0] == outputs[1]
    assert active == [1, 2]


def test_retry_only_rate_limit_and_server_error(tmp_path, monkeypatch):
    cfg = load_config()
    llm = Llm(cfg, tmp_path / "retry.csv", 1.0)
    calls = []
    sleeps = []
    def fake_call(*args):
        calls.append(1)
        if len(calls) < 3:
            raise RetryableError("Vertex 429 RESOURCE_EXHAUSTED")
        return '{"answer":"ok"}', (100, 20, 0)
    llm._call = fake_call
    monkeypatch.setattr("sprachpipe.llm.time.sleep", sleeps.append)
    monkeypatch.setattr("sprachpipe.llm.random.random", lambda: 0.0)
    assert llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                             thinking={}, step="blindtest", max_output_tokens=100) == {"answer": "ok"}
    assert len(calls) == 3 and sleeps == [0.5, 1.0]
    llm._call = lambda *args: (_ for _ in ()).throw(RetryableError("Vertex 503"))
    with pytest.raises(LlmError):
        llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                          thinking={}, step="blindtest", max_output_tokens=100)
    assert len(sleeps) == 6  # four more waits, then fifth attempt stops


def test_concurrent_budget_reservations_are_safe(tmp_path):
    cfg = load_config()
    llm = Llm(cfg, tmp_path / "budget.csv", 0.005)
    called = []
    def fake_call(*args):
        called.append(1)
        time.sleep(0.01)
        return '{"answer":"ok"}', (100, 400, 0)
    llm._call = fake_call
    def request(_):
        try:
            llm.generate_json("p", {"properties": {"answer": {}}}, model="gemini-2.5-flash",
                              thinking={}, step="blindtest", max_output_tokens=1000)
            return "ok"
        except BudgetExceeded:
            return "budget"
    with ThreadPoolExecutor(max_workers=8) as pool:
        outcomes = list(pool.map(request, range(8)))
    assert "budget" in outcomes and "ok" in outcomes
    assert len(called) == outcomes.count("ok")
    assert total_usd(llm.ledger) <= 0.005
