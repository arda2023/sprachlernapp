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


def test_not_gar_nicht_excluded_not_nicht_and_which_senses_stay_active():
    inv = MeaningInventory("en")
    status = {(f, m["sense_key"]): (m["status"], m.get("exclude_reason"), m["pos"], m["usage"])
              for f in ("not", "which") for m in inv.get(f)}
    assert status[("not", "not#gar_nicht")] == ("excluded", "cloze_ambiguous", "PART", "haupt")
    assert status[("not", "not#nicht")][0] == "active"
    assert status[("which", "which#fragepronomen")][:3] == ("active", None, "PRON")
    assert status[("which", "which#determiner_auswahl")][:3] == ("active", None, "DET")
    # same filter as cli.run_generate: only active meanings become cards
    active = [m["sense_key"] for m in inv.get("not") if m.get("status", "active") == "active"]
    assert active == ["not#nicht"]


def test_sentence_prompt_separates_which_pron_from_det():
    from sprachpipe.generate import load_prompt, sentences
    inv = MeaningInventory("en")
    card = dict(next(m for m in inv.get("which") if m["sense_key"] == "which#fragepronomen"),
                form="which", lemma="which")

    class Fake:
        def generate_json(self, prompt, schema, **kwargs):
            self.prompt = prompt
            return {"sentences": [{"text": "Which is cheaper?", "translation_de": "Was ist billiger?"}]}
    fake = Fake()
    sentences(fake, load_config(), card, count=1, contexts=[("Einkaufen", "Mia")])
    assert load_prompt("sentences")[0] == "sentences-v7"
    assert "meaning: PRON" in fake.prompt and card["gloss_de"] in fake.prompt
    assert "part of speech given above (PRON)" in fake.prompt
    assert '"Which is cheaper?"' in fake.prompt and '"Which of these coats is yours?"' in fake.prompt
    assert 'not "Which coat ..." or "Which red coat ..." (those are DET)' in fake.prompt
    assert "adjectives may stand between it and the noun" in fake.prompt

BE_AUX = {("are", "be#sein_vollverb"), ("was", "be#sein_vollverb"), ("is", "be#sein_vollverb"),
          ("be", "be#sein_existieren"), ("be", "be#befinden")}
BE_NEW_IDS = {   # documented in docs/be-pos-correction.md
    ("are", "be#sein_vollverb"): ("8de352bb7b769583aa91247dc72c7c44", "08470372ea71b7c40444c2b7bc738766"),
    ("was", "be#sein_vollverb"): ("c48c461e1f24c588b75a7a1452eadc95", "319aa2e30453222cf8a74fad14b00e91"),
    ("be", "be#sein_existieren"): ("728c107ed31ac9fbef2b3b5bdde730af", "7be993be34e9d87e7156cfc02256dc0f"),
    ("be", "be#befinden"): ("7194af61bee4d3bae01d152bb82975ae", "d2ef9df94be5dd1c9ec9e98860c00764"),
}


def card_id(form, lemma, pos, key):
    from sprachpipe.ids import stable_id
    lid = stable_id("lemmas", lang="en", lemma=lemma, pos=pos)
    return stable_id("cards", lang="en", form=form,
                     sense_id=stable_id("senses", lemma_id=lid, sense_key=key))


def test_copular_be_is_aux_and_visit_sense_stays_verb():
    inv = MeaningInventory("en")
    pos = {(f, m["sense_key"]): m["pos"] for f in ("be", "is", "are", "was", "were", "been")
           for m in inv.get(f)}
    assert all(pos[k] == "AUX" for k in BE_AUX)
    assert pos[("been", "be#besucht")] == "VERB"   # "have been to" (visited): not changed
    assert [k for k, v in pos.items() if v == "VERB"] == [("been", "be#besucht")]


def test_be_pos_correction_yields_documented_new_ids():
    for (form, key), (old, new) in BE_NEW_IDS.items():
        assert card_id(form, "be", "VERB", key) == old
        assert card_id(form, "be", "AUX", key) == new != old


# Pilot 60 v1 cards not touched by the be correction, with their card IDs
# recorded once (docs/be-pos-correction.md); no pack file needed.
UNAFFECTED_PILOT_CARDS = {
    "is|be/AUX|be#sein_vollverb": "b325798ce493fd8ad1968460d3a038ab",
    "been|be/VERB|be#besucht": "9571634153cd34d44b188319e007d49b",
    "be|be/AUX|be#hilfsverb": "bdac6410e29b305386120132d1a7c724",
    "not|not/PART|not#nicht": "05f5c519ff76c3267775f5e763e81c0a",
    "which|which/DET|which#determiner_auswahl": "724b9485f87a31b2f761596f955bb2c4",
}


def inventory_card_id(inv, form, key):
    """Card ID as generation derives it from the current inventory."""
    meaning = next(m for m in inv.get(form) if m["sense_key"] == key)
    return card_id(form, meaning["lemma"], meaning["pos"], key)


def test_corrected_and_unaffected_identities_from_current_inventory():
    inv = MeaningInventory("en")
    for (form, key), (_, new) in BE_NEW_IDS.items():
        assert inventory_card_id(inv, form, key) == new
    for ref, expected in UNAFFECTED_PILOT_CARDS.items():
        form, _, key = ref.split("|")
        assert inventory_card_id(inv, form, key) == expected


def test_be_sein_vollverb_is_one_copular_sense_across_forms():
    inv = MeaningInventory("en")
    entries = {f: next(m for m in inv.get(f) if m["sense_key"] == "be#sein_vollverb")
               for f in ("is", "are", "was")}
    for form, m in entries.items():
        assert (m["lemma"], m["pos"], m["status"]) == ("be", "AUX", "active")
        gloss = m["gloss_de"]
        assert all(w in gloss for w in ("Zustand", "Eigenschaft", "Identität")), form
        assert "existier" not in gloss and "es gibt" not in gloss, form
    # form-dependent display and translations stay distinct
    assert [entries[f]["translation_de"] for f in ("is", "are", "was")] == ["ist", "sind / bist / seid", "war"]