"""Offline curation of existing packs (sprachpipe.curate). Small synthetic
packs only; no out/, no network, no credentials."""

import copy
import json
import re

import pytest

from sprachpipe.config import PIPELINE_DIR
from sprachpipe.curate import CurationError, curate, finalize, sentence_id
from sprachpipe.generate import gap_offsets
from sprachpipe.linter import _whole_token_count
from sprachpipe.pack import build_rows


def make_pack(cards: list[tuple[str, str, str, list[tuple[str, str, list[str]]]]]) -> dict:
    """cards: (form, lemma/pos, sense_key, [(text, translation, alternatives) x3]).
    Sentence refs are local s1, s2, ... and therefore collide between packs."""
    pack = {"lang": "en", "release": {"version": "t", "schema_version": 1},
            "languages": [], "lemmas": [], "senses": [], "cards": [],
            "decks": [{"ref": "allgemeine-sprache", "slug": "allgemeine-sprache",
                       "title_de": "Allgemeine Sprache", "sort": 1}],
            "deck_cards": [], "dictionary_forms": [], "sentences": [],
            "sentence_tokens": [], "card_sentences": []}
    for n, (form, lref, key, sentences) in enumerate(cards, start=1):
        lemma, pos = lref.split("/")
        if not any(lm["ref"] == lref for lm in pack["lemmas"]):
            pack["lemmas"].append({"ref": lref, "lemma": lemma, "pos": pos})
        sref, cref = f"{lref}|{key}", f"{form}|{lref}|{key}"
        pack["senses"].append({"ref": sref, "lemma": lref, "sense_key": key, "gloss_de": key})
        pack["cards"].append({"ref": cref, "form": form, "sense": sref, "freq_rank": n})
        pack["deck_cards"].append({"deck": "allgemeine-sprache", "card": cref, "position": n})
        for position, (text, translation, alternatives) in enumerate(sentences, start=1):
            ref = f"s{len(pack['sentences']) + 1}"
            pack["sentences"].append({"ref": ref, "text": text, "translation_de": translation,
                                      "origins": ["deck"], "model": "m", "qa_status": "ok",
                                      "qa_report": {"alternative_check": [
                                          {"candidate": a, "status": "confirmed"} for a in alternatives]}})
            start, end = gap_offsets(text, form)
            for idx, m in enumerate(re.finditer(r"\w+", text)):
                card_token = m.start() == start
                pack["sentence_tokens"].append({
                    "sentence": ref, "idx": idx, "start_pos": m.start(), "end_pos": m.end(),
                    "surface": m.group(), "lemma": lref if card_token else None,
                    "sense": sref if card_token else None, "card": cref if card_token else None})
            pack["card_sentences"].append({"card": cref, "sentence": ref, "position": position,
                                           "gap_start": start, "gap_end": end,
                                           "accepted": [form], "valid_alternatives": list(alternatives)})
    pack["dictionary_forms"] = [{"form": "went", "sense": "go/VERB|go#gehen", "card": None,
                                 "gloss_de": "ging", "rank": 1}]
    return pack


GO = ("went", "go/VERB", "go#gehen", [
    ("She went home early.", "Sie ging früh nach Hause.", ["walked"]),
    ("We went to the park.", "Wir gingen in den Park.", ["walked", "ran"]),
    ("They went out yesterday.", "Sie gingen gestern aus.", [])])
UP_OLD = ("up", "up/VERB", "up#hinauf", [
    ("Mia climbs up the hill.", "Mia klettert den Hügel hinauf.", []),
    ("Leo looks up at the sky.", "Leo schaut zum Himmel hinauf.", []),
    ("Run up the stairs.", "Lauf die Treppe hinauf.", [])])
UP_NEW = ("up", "up/ADV", "up#hinauf", [
    ("Ben walks up the road.", "Ben geht die Straße hinauf.", []),
    ("Zoe swims up the river.", "Zoe schwimmt den Fluss hinauf.", []),
    ("Sara drives up the street.", "Sara fährt die Straße hinauf.", [])])
AT = ("at", "at/ADP", "at#zeit", [
    ("Eva eats at noon.", "Eva isst mittags.", []),
    ("Omar sleeps at night.", "Omar schläft nachts.", []),
    ("Nina leaves at six.", "Nina geht um sechs.", [])])
GO_DUP = ("went", "go/VERB", "go#gehen", [
    ("Ali went to school.", "Ali ging zur Schule.", []),
    ("Luca went inside.", "Luca ging hinein.", []),
    ("Rosa went shopping.", "Rosa ging einkaufen.", [])])

BASE = make_pack([GO, UP_OLD])
EXTRA = make_pack([AT, UP_NEW, GO_DUP])
PACKS = {"base": BASE, "extra": EXTRA}
# deck order input (pack.deck_order_key): 'neben' adds 200 to the rank
META = {"went|go/VERB|go#gehen": {"rank": 5, "usage": "haupt", "sense_index": 1},
        "up|up/VERB|up#hinauf": {"rank": 7, "usage": "haupt", "sense_index": 1},
        "up|up/ADV|up#hinauf": {"rank": 7, "usage": "haupt", "sense_index": 1},
        "at|at/ADP|at#zeit": {"rank": 1, "usage": "neben", "sense_index": 2}}


def sid(text):
    return sentence_id("en", text)


CURATION = {
    "version": "test-curation-v1", "lang": "en", "base": "base",
    "sources": {"base": "-", "extra": "-"},
    "expect": {"cards": 3, "card_sentences": 9},
    "card_operations": [
        {"op": "add_card", "source": "extra", "card": "at|at/ADP|at#zeit"},
        {"op": "replace_card", "source": "extra", "card": "up|up/ADV|up#hinauf",
         "replaces": "up|up/VERB|up#hinauf"},
        {"op": "keep_base_card", "source": "extra", "card": "went|go/VERB|go#gehen"}],
    "sentence_operations": [
        {"op": "replace_text", "source": "base", "label": "s1", "card": "went|go/VERB|go#gehen",
         "sentence_id": sid("She went home early."),
         "expect": {"text": "She went home early.", "translation_de": "Sie ging früh nach Hause."},
         "new": {"text": "Ben went home after work.", "translation_de": "Ben ging nach der Arbeit nach Hause."}},
        {"op": "replace_translation", "source": "base", "label": "s3", "card": "went|go/VERB|go#gehen",
         "sentence_id": sid("They went out yesterday."),
         "expect": {"text": "They went out yesterday.", "translation_de": "Sie gingen gestern aus."},
         "new": {"translation_de": "Sie sind gestern ausgegangen."}},
        {"op": "remove_alternative", "source": "base", "label": "s2", "card": "went|go/VERB|go#gehen",
         "sentence_id": sid("We went to the park."), "expect": {"text": "We went to the park."},
         "alternative": "walked"}]}


def run(curation=CURATION, packs=PACKS):
    return curate(packs, curation, META)


def test_strict_metadata_requires_exact_decisions_and_preserves_inputs():
    packs = copy.deepcopy(PACKS)
    # Shared entity used by an added card, independent of source order.
    packs['extra']['senses'].append(copy.deepcopy(packs['base']['senses'][0]))
    packs['extra']['senses'][-1]['gloss_de'] = 'anders'
    # Remove duplicate synthetic sense from GO_DUP before constructing conflict.
    packs['extra']['senses'] = [s for i, s in enumerate(packs['extra']['senses'])
                                if s['ref'] != 'go/VERB|go#gehen' or i == len(packs['extra']['senses']) - 1]
    c = dict(CURATION, metadata_resolutions=[])
    with pytest.raises(CurationError, match='unresolved metadata conflict'):
        run(c, packs)
    expected = {name: next(s for s in p['senses'] if s['ref'] == 'go/VERB|go#gehen')
                for name, p in packs.items()}
    c['metadata_resolutions'] = [{'table': 'senses', 'ref': 'go/VERB|go#gehen',
                                  'expect': copy.deepcopy(expected),
                                  'new': {'gloss_de': 'gehen'}, 'reason': 'gleiche Bedeutung'}]
    snapshot = copy.deepcopy(packs)
    work, log = run(c, packs)
    assert packs == snapshot
    assert next(s for s in work['senses'] if s['ref'] == 'go/VERB|go#gehen')['gloss_de'] == 'gehen'
    assert log['metadata_resolutions'] == c['metadata_resolutions']
    packs['extra']['senses'][-1]['gloss_de'] = 'unexpected'
    with pytest.raises(CurationError, match='precondition differs'):
        run(c, packs)


def test_editorial_translation_preserves_english_ids_tokens_and_historical_qa():
    c = copy.deepcopy(CURATION)
    op = c['sentence_operations'][1]
    op.update(op='editorial_translation', reason='Redaktionell, keine Modellprüfung')
    c['sentence_operations'] = [op]
    work, log = run(c)
    original = BASE['sentences'][2]
    edited = next(s for s in work['sentences'] if s['ref'] == 'base/s3')
    assert sid(original['text']) == sid(edited['text'])
    assert edited['qa_report'] == original['qa_report']
    assert edited['editorial_reviews'][0]['model_check'] is False
    assert [p['kind'] for p in work['curation']['pending']] == ['dictionary_forms']
    assert [{**t, 'sentence': 's3'} for t in work['sentence_tokens'] if t['sentence'] == 'base/s3'] == [
        t for t in BASE['sentence_tokens'] if t['sentence'] == 's3']
    op['expect']['translation_de'] = 'wrong original'
    with pytest.raises(CurationError, match='translation_de differs'):
        run(c)


def links(work, card):
    texts = {s["ref"]: s for s in work["sentences"]}
    return [(cs, texts[cs["sentence"]]) for cs in sorted(
        (cs for cs in work["card_sentences"] if cs["card"] == card), key=lambda c: c["position"])]


def test_merge_resolves_colliding_local_refs_and_keeps_cards_consistent():
    assert {s["ref"] for s in BASE["sentences"]} & {s["ref"] for s in EXTRA["sentences"]}  # s1.. collide
    work, log = run()
    refs = [s["ref"] for s in work["sentences"]]
    assert len(refs) == len(set(refs)) == 9
    assert sorted(c["ref"] for c in work["cards"]) == [
        "at|at/ADP|at#zeit", "up|up/ADV|up#hinauf", "went|go/VERB|go#gehen"]
    assert log["counts"] == {"cards": 3, "card_sentences": 9}
    assert {t["sentence"] for t in work["sentence_tokens"]} <= set(refs)
    assert {cs["sentence"] for cs in work["card_sentences"]} == set(refs)
    # kept base card: its own sentences, not the duplicate set from extra
    assert all(s["ref"].startswith("base/") or s["ref"].startswith("test-curation-v1/")
               for _, s in links(work, "went|go/VERB|go#gehen"))
    assert not any("Ali went" in s["text"] for s in work["sentences"])
    # replaced card and its sentences are gone; orphaned lemma pruned
    assert "up|up/VERB|up#hinauf" not in {c["ref"] for c in work["cards"]}
    assert "up/VERB" not in {lm["ref"] for lm in work["lemmas"]}
    assert {d["card"]: d["position"] for d in work["deck_cards"]} == {
        "went|go/VERB|go#gehen": 1, "up|up/ADV|up#hinauf": 2, "at|at/ADP|at#zeit": 3}
    with pytest.raises(CurationError, match="card_meta missing"):
        curate(PACKS, CURATION, {k: v for k, v in META.items() if not k.startswith("at|")})


def test_ids_stable_unless_english_text_changes():
    work, log = run()
    before = {sid(s["text"]) for s in BASE["sentences"] + EXTRA["sentences"]}
    after = {sid(s["text"]) for s in work["sentences"]}
    replaced = log["sentence_operations"][0]
    assert replaced["old_sentence_id"] == sid("She went home early.") not in after
    assert replaced["new_sentence_id"] == sid("Ben went home after work.") in after
    assert after - before == {replaced["new_sentence_id"]}
    # translation-only change: same sentence ID, same tokens
    (_, s3) = links(work, "went|go/VERB|go#gehen")[2]
    assert sid(s3["text"]) == sid("They went out yesterday.")
    assert s3["translation_de"] == "Sie sind gestern ausgegangen."
    old_ref = next(s["ref"] for s in BASE["sentences"] if s["text"] == "They went out yesterday.")
    old_tokens = [dict(t, sentence=s3["ref"]) for t in BASE["sentence_tokens"] if t["sentence"] == old_ref]
    assert [t for t in work["sentence_tokens"] if t["sentence"] == s3["ref"]] == old_tokens
    assert s3["qa_report"] == next(s["qa_report"] for s in BASE["sentences"] if s["ref"] == old_ref)


def test_english_replacement_takes_over_no_old_annotation_alternatives_or_qa():
    work, log = run()
    cs, s = links(work, "went|go/VERB|go#gehen")[0]
    assert s["text"] == "Ben went home after work." and s["qa_status"] == "pending"
    assert s["qa_report"] == {"curation": {"version": "test-curation-v1",
                                           "replaces_sentence_id": sid("She went home early.")}}
    assert cs["valid_alternatives"] == [] and cs["accepted"] == ["went"]
    assert not [t for t in work["sentence_tokens"] if t["sentence"] == s["ref"]]
    assert log["sentence_operations"][0]["dropped_alternatives"] == ["walked"]
    pending = work["curation"]["pending"]
    annotate = [p for p in pending if p["kind"] == "annotate_card"]
    assert annotate == [dict(annotate[0], card="went|go/VERB|go#gehen")]
    assert len(annotate[0]["sentences"]) == 3   # annotate_card works on all three sentences
    qa = next(p for p in pending if p["kind"] == "sentence_qa")
    assert qa["recheck_alternatives"] == ["walked"] and "alternative_check" in qa["checks"]
    assert any(p["kind"] == "translation_check" and p["sentence_id"] == sid("They went out yesterday.")
               for p in pending)
    assert work["dictionary_forms"] == [] and any(p["kind"] == "dictionary_forms" for p in pending)


def test_gaps_match_the_target_form_exactly():
    work, _ = run()
    forms = {c["ref"]: c["form"] for c in work["cards"]}
    texts = {s["ref"]: s["text"] for s in work["sentences"]}
    for cs in work["card_sentences"]:
        assert texts[cs["sentence"]][cs["gap_start"]:cs["gap_end"]] == forms[cs["card"]]
    cs, s = links(work, "went|go/VERB|go#gehen")[0]
    assert (cs["gap_start"], cs["gap_end"]) == gap_offsets(s["text"], "went") == (4, 8)


def test_targeted_alternative_removal_keeps_others_and_history():
    work, log = run()
    cs, s = links(work, "went|go/VERB|go#gehen")[1]
    assert cs["valid_alternatives"] == ["ran"]
    assert log["sentence_operations"][2] | {} == {
        "op": "remove_alternative", "label": "s2", "card": "went|go/VERB|go#gehen",
        "sentence_id": sid("We went to the park."), "removed": "walked",
        "before": ["walked", "ran"], "after": ["ran"],
        "note": "qa_report.alternative_check keeps the historical model verdict"}
    assert {a["candidate"] for a in s["qa_report"]["alternative_check"]} == {"walked", "ran"}


def test_inputs_are_not_mutated():
    packs, curation = copy.deepcopy(PACKS), copy.deepcopy(CURATION)
    run(curation, packs)
    assert packs == PACKS and curation == CURATION


def changed(path, value):
    curation = copy.deepcopy(CURATION)
    target = curation
    for key in path[:-1]:
        target = target[key]
    target[path[-1]] = value
    return curation


@pytest.mark.parametrize("curation,message", [
    (changed(["sentence_operations", 0, "expect", "text"], "She went home late."), "text differs"),
    (changed(["sentence_operations", 1, "expect", "translation_de"], "x"), "translation_de differs"),
    (changed(["sentence_operations", 0, "sentence_id"], "0" * 32), "found 0x"),
    (changed(["sentence_operations", 0, "label"], "s2"), "does not match ref"),
    (changed(["sentence_operations", 0, "card"], "at|at/ADP|at#zeit"), "found 0x"),
    (changed(["sentence_operations", 2, "alternative"], "flew"), "found 0x"),
    (changed(["sentence_operations", 0, "new", "text"], "Ben walked home."), "exactly once"),
    (changed(["sentence_operations", 0, "new", "text"], "We went to the park."), "already exists"),
    (changed(["card_operations"], CURATION["card_operations"][:2]), "needs exactly one card operation"),
    (changed(["card_operations", 1, "replaces"], "up|up/ADV|up#nirgends"), "found 0x"),
    (changed(["expect", "cards"], 4), "counts"),
])
def test_mismatched_preconditions_abort_visibly(curation, message):
    packs = copy.deepcopy(PACKS)
    with pytest.raises(CurationError, match=message):
        curate(packs, curation, META)
    assert packs == PACKS


def test_add_card_never_duplicates_a_base_card():
    curation = changed(["card_operations", 2], {"op": "add_card", "source": "extra",
                                                "card": "went|go/VERB|go#gehen"})
    with pytest.raises(CurationError, match="already exists"):
        run(curation)


def test_pending_steps_block_finalize_and_pack_rows():
    work, _ = run()
    with pytest.raises(CurationError, match="pending steps"):
        finalize(work)
    with pytest.raises(ValueError, match="pending annotation/QA"):
        build_rows(work)
    done = dict(work, curation=dict(work["curation"], pending=[]))
    assert "curation" not in finalize(done)


def test_versioned_pilot_curation_list_has_exactly_the_planned_scope():
    data = json.loads((PIPELINE_DIR / "data" / "curation" / "pilot_60_v1.json").read_text(encoding="utf-8"))
    ops = [(o["op"], o.get("label") or o["card"]) for o in data["card_operations"] + data["sentence_operations"]]
    assert sorted(o for o, _ in ops) == sorted(
        ["add_card"] * 4 + ["replace_card"] + ["keep_base_card"] * 5
        + ["replace_text"] * 5 + ["replace_translation"] * 2 + ["remove_alternative"] * 2)
    assert {l for o, l in ops if o == "replace_text"} == {"s30", "s126", "s153", "s171", "s413"}
    assert {l for o, l in ops if o == "replace_translation"} == {"s99", "s331"}
    assert {(o["label"], o["alternative"]) for o in data["sentence_operations"]
            if o["op"] == "remove_alternative"} == {("s399", "before"), ("s140", "you")}
    assert data["expect"] == {"cards": 164, "card_sentences": 492}
    # no card exclusions from the review's open questions
    assert not any(k in json.dumps(data) for k in ("your#ihr", "your#euer", "singular_they",
                                                   "fuellwort", "testament"))
    fixtures = json.loads((PIPELINE_DIR / "tests" / "fixtures" / "qa_language_cases.json").read_text(encoding="utf-8"))
    fixture_texts = {c["text"] for c in fixtures["meaning_cases"] + fixtures["alternative_cases"]}
    for o in data["sentence_operations"]:
        assert sid(o["expect"]["text"]) == o["sentence_id"]
        if o["op"] == "replace_text":
            form = o["card"].split("|")[0]
            assert _whole_token_count(o["new"]["text"], form) == 1
            assert gap_offsets(o["new"]["text"], form) is not None
            assert o["new"]["text"] not in fixture_texts and o["new"]["translation_de"]


def with_dictionary(base_entries, extra_entries):
    packs = copy.deepcopy(PACKS)
    packs["base"]["dictionary_forms"] = base_entries
    packs["extra"]["dictionary_forms"] = extra_entries
    return packs


def entry(form, sense, gloss, card=None, rank=1):
    return {"form": form, "sense": sense, "card": card, "gloss_de": gloss, "rank": rank}


def test_form_translation_differing_from_sense_gloss_is_kept_exactly():
    packs = with_dictionary([entry("went", "go/VERB|go#gehen", "ging (Vergangenheit)",
                                   "went|go/VERB|go#gehen")], [])
    work, log = curate(packs, CURATION, META)
    sense_gloss = next(s["gloss_de"] for s in work["senses"] if s["ref"] == "go/VERB|go#gehen")
    [kept] = work["curation"]["dictionary_sources"]
    assert sense_gloss == "go#gehen" != kept["values"][0]["gloss_de"] == "ging (Vergangenheit)"
    assert kept["values"][0]["sources"] == {"base": {"card": "went|go/VERB|go#gehen", "rank": 1}}
    assert log["dictionary_forms"] == {"preserved_keys": 1, "conflicting_keys": 0}


def test_same_spelling_with_different_sense_is_not_merged():
    packs = with_dictionary([entry("up", "up/VERB|up#hinauf", "hinauf (Verb)")],
                            [entry("up", "up/ADV|up#hinauf", "hinauf"),
                             entry("up", "up/ADP|up#entlang", "entlang")])
    work, _ = curate(packs, CURATION, META)
    keys = [(e["form"], e["sense"]) for e in work["curation"]["dictionary_sources"]]
    assert sorted(keys) == [("up", "up/ADP|up#entlang"), ("up", "up/ADV|up#hinauf"),
                            ("up", "up/VERB|up#hinauf")]
    # the entry of the replaced card stays as source data; tokens decide later
    assert all(len(e["values"]) == 1 for e in work["curation"]["dictionary_sources"])


def test_conflicting_and_identical_values_stay_traceable():
    packs = with_dictionary([entry("went", "go/VERB|go#gehen", "ging", rank=1),
                             entry("at", "at/ADP|at#zeit", "um", rank=2)],
                            [entry("went", "go/VERB|go#gehen", "gingen", rank=3),
                             entry("at", "at/ADP|at#zeit", "um", rank=1)])
    work, log = curate(packs, CURATION, META)
    by_key = {(e["form"], e["sense"]): e for e in work["curation"]["dictionary_sources"]}
    assert by_key[("at", "at/ADP|at#zeit")]["values"] == [
        {"gloss_de": "um", "sources": {"base": {"card": None, "rank": 2},
                                        "extra": {"card": None, "rank": 1}}}]
    assert by_key[("went", "go/VERB|go#gehen")]["values"] == [
        {"gloss_de": "ging", "sources": {"base": {"card": None, "rank": 1}}},
        {"gloss_de": "gingen", "sources": {"extra": {"card": None, "rank": 3}}}]
    dict_step = next(p for p in work["curation"]["pending"] if p["kind"] == "dictionary_forms")
    assert dict_step["conflicting_keys"] == [{"form": "went", "sense": "go/VERB|go#gehen"}]
    assert log["dictionary_forms"] == {"preserved_keys": 2, "conflicting_keys": 1}


def test_unannotated_replacement_keeps_dictionary_incomplete_and_blocked():
    work, _ = run()
    replaced = links(work, "went|go/VERB|go#gehen")[0][1]
    assert replaced["qa_status"] == "pending"
    assert not [t for t in work["sentence_tokens"] if t["sentence"] == replaced["ref"]]
    assert work["dictionary_forms"] == []   # no final set or rank before annotation
    assert any(p["kind"] == "dictionary_forms" for p in work["curation"]["pending"])
    with pytest.raises(CurationError, match="dictionary_forms"):
        finalize(work)
    with pytest.raises(ValueError, match="pending"):
        build_rows(work)


def test_dictionary_inputs_are_not_mutated():
    packs = with_dictionary([entry("went", "go/VERB|go#gehen", "ging")],
                            [entry("went", "go/VERB|go#gehen", "gingen")])
    snapshot = copy.deepcopy(packs)
    work, _ = curate(packs, CURATION, META)
    work["curation"]["dictionary_sources"][0]["values"][0]["gloss_de"] = "changed"
    assert packs == snapshot
