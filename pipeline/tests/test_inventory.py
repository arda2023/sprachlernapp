import json
from pathlib import Path

from sprachpipe.config import load_config
from sprachpipe.classify import classify_form
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
    assert {m["sense_key"] for m in data["forms"]["left"]["meanings"]} == {
        "leave#verlassen", "left#uebrig", "left#links", "left#nach_links"}
    assert data["forms"]["i"]["display_form"] == "I"
    for key in ("what#ausruf", "there#beruhigung", "like#als_ob", "this#so_graduierend"):
        assert any(m["sense_key"] == key and m["status"] == "excluded"
                   and m["exclude_reason"] == "cloze_ambiguous"
                   for form in data["forms"].values() for m in form["meanings"])


def test_classification_preserves_keys_and_excludes_rare(tmp_path):
    inv = MeaningInventory("en", tmp_path / "en.json")
    inv.append("what", [entry("what#ausruf"), entry("what#frage"), entry("what#alt")], 4)
    inv.classify("what", {"what#ausruf": "haupt", "what#frage": "neben", "what#alt": "selten"})
    stored = MeaningInventory("en", inv.path).get("what")
    assert [m["sense_key"] for m in stored] == ["what#ausruf", "what#frage", "what#alt"]
    assert [(m["usage"], m["status"], m.get("exclude_reason")) for m in stored] == [
        ("haupt", "excluded", "cloze_ambiguous"), ("neben", "active", None),
        ("selten", "excluded", "selten")]


def test_classify_usage_one_call_exact_existing_keys():
    class Fake:
        def __init__(self):
            self.calls = 0
        def generate_json(self, prompt, schema, **kwargs):
            self.calls += 1
            assert 'English form "I"' in prompt
            assert set(schema["properties"]["usages"]["required"]) == {"i#ich", "i#alt"}
            return {"usages": {"i#ich": "haupt", "i#alt": "selten"}}
    fake = Fake()
    assert classify_form(fake, load_config(), "i", [entry("i#ich"), entry("i#alt")], "I") == {
        "i#ich": "haupt", "i#alt": "selten"}
    assert fake.calls == 1


def test_numeric_forms_skip_fragments_numbers_proper_names(monkeypatch):
    cfg = load_config()
    ranked = ["the", "'s", "42", "london", "and", "one", "went", "to"]
    monkeypatch.setattr("wordfreq.top_n_list", lambda lang, n: ranked)
    monkeypatch.setattr("sprachpipe.lemmas.spacy_analyzer",
                        lambda model: lambda word: (word, "PROPN" if word == "london" else "DET",
                                                    word == "one"))
    assert candidate_forms("3", cfg) == [("the", 1), ("and", 5), ("went", 7)]
    assert [form for form, _ in candidate_forms("smoke", cfg)] == cfg["smoke_forms"]
