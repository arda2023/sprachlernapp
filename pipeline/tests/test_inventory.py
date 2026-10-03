import json
from pathlib import Path

from sprachpipe.config import load_config
from sprachpipe.generate import candidate_forms, meanings
from sprachpipe.inventory import MeaningInventory


def entry(key, gloss="Bedeutung"):
    return {"pos": "VERB", "lemma": "go", "sense_key": key, "gloss_de": gloss,
            "form_kind": "past", "form_label_de": "Verb, Vergangenheit",
            "cefr_band": "anfaenger", "translation_de": "ging"}


class FakeMeanings:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.calls = []

    def generate_json(self, prompt, schema, **kwargs):
        self.calls.append((prompt, schema))
        return {"meanings": next(self.responses)}


def test_inventory_reused_without_ai_and_keys_unchanged(tmp_path):
    cfg = load_config()
    path = tmp_path / "meanings" / "en.json"
    llm = FakeMeanings([[entry("go#gehen"), entry("go#fahren")],
                        [entry("go#gehen", "andere Glosse"), entry("go#werden")]])
    inventory = MeaningInventory("en", path)
    first = meanings(llm, cfg, "went", 500, inventory)
    second = meanings(llm, cfg, "went", 500, MeaningInventory("en", path))
    assert first == second
    assert len(llm.calls) == 1
    assert llm.calls[0][1]["properties"]["meanings"]["maxItems"] == 4
    refreshed = meanings(llm, cfg, "went", 500, inventory, refresh=True)
    assert [m["sense_key"] for m in refreshed] == ["go#gehen", "go#fahren", "go#werden"]
    assert refreshed[0]["gloss_de"] == "Bedeutung"
    assert len(llm.calls) == 2
    assert [m["sense_key"] for m in MeaningInventory("en", path).get("went")] == [
        "go#gehen", "go#fahren", "go#werden"]


def test_meaning_limit_three_outside_top_thousand(tmp_path):
    cfg = load_config()
    llm = FakeMeanings([[entry("a"), entry("b"), entry("c")]])
    stored = meanings(llm, cfg, "went", 1001, MeaningInventory("en", tmp_path / "en.json"))
    assert len(stored) == 3
    assert llm.calls[0][1]["properties"]["meanings"]["maxItems"] == 3
    assert "At most 3" in llm.calls[0][0]


def test_seed_preserves_smoke_keys():
    path = Path(__file__).resolve().parents[1] / "data" / "meanings" / "en.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    assert list(data["forms"])[:5] == ["went", "left", "about", "up", "light"]
    assert {m["sense_key"] for m in data["forms"]["left"]} == {
        "leave#verlassen", "left#uebrig", "left#links", "left#nach_links"}


def test_numeric_forms_skip_fragments_numbers_proper_names(monkeypatch):
    cfg = load_config()
    ranked = ["the", "'s", "42", "london", "and", "one", "went", "to"]
    monkeypatch.setattr("wordfreq.top_n_list", lambda lang, n: ranked)
    monkeypatch.setattr("sprachpipe.lemmas.spacy_analyzer",
                        lambda model: lambda word: (word, "PROPN" if word == "london" else "DET",
                                                    word == "one"))
    assert candidate_forms("3", cfg) == [("the", 1), ("and", 5), ("went", 7)]
    assert [form for form, _ in candidate_forms("smoke", cfg)] == cfg["smoke_forms"]
