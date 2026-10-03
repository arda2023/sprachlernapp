"""Pack file → table rows with stable IDs.

A pack is JSON written by hand or by later pipeline steps. Rows refer to
each other by `ref` names; build_rows() turns them into rows of the schema
`content` (schema.COLUMNS) with IDs from ids.stable_id().
"""

from __future__ import annotations

import json
from pathlib import Path

from .ids import form_norm, stable_id
from .schema import COLUMNS


def load_pack(path: str | Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _lookup(refs: dict[str, str], kind: str, ref: str | None) -> str | None:
    if ref is None:
        return None
    try:
        return refs[ref]
    except KeyError:
        raise ValueError(f"unknown {kind} ref {ref!r}") from None


def _complete(table: str, row: dict) -> dict:
    """Keep only schema columns; unknown keys are an error."""
    allowed = {name for name, _ in COLUMNS[table]}
    extra = set(row) - allowed
    if extra:
        raise ValueError(f"{table}: unknown columns {sorted(extra)}")
    return row


def build_rows(pack: dict) -> dict[str, list[dict]]:
    lang = pack["lang"]
    rows: dict[str, list[dict]] = {t: [] for t in COLUMNS}
    lemma_ids: dict[str, str] = {}
    lemma_pos: dict[str, str] = {}
    sense_ids: dict[str, str] = {}
    sense_lemma: dict[str, str] = {}
    card_ids: dict[str, str] = {}
    sentence_ids: dict[str, str] = {}
    deck_ids: dict[str, str] = {}

    for lg in pack.get("languages", []):
        rows["languages"].append(_complete("languages", dict(lg)))

    for lm in pack.get("lemmas", []):
        lid = stable_id("lemmas", lang=lang, lemma=lm["lemma"], pos=lm["pos"])
        lemma_ids[lm["ref"]] = lid
        lemma_pos[lid] = lm["pos"]
        rows["lemmas"].append(_complete("lemmas", {
            "id": lid, "lang": lang, "lemma": lm["lemma"], "pos": lm["pos"],
            "family_key": lm.get("family_key"), "freq_rank": lm.get("freq_rank"),
        }))

    for se in pack.get("senses", []):
        lid = _lookup(lemma_ids, "lemma", se["lemma"])
        sid = stable_id("senses", lemma_id=lid, sense_key=se["sense_key"])
        sense_ids[se["ref"]] = sid
        sense_lemma[sid] = lid
        rows["senses"].append(_complete("senses", {
            "id": sid, "lang": lang, "lemma_id": lid, "sense_key": se["sense_key"],
            "gloss_de": se["gloss_de"], "definition_de": se.get("definition_de"),
            "notes_de": se.get("notes_de"), "sense_index": se.get("sense_index"),
        }))

    for ca in pack.get("cards", []):
        sid = _lookup(sense_ids, "sense", ca["sense"])
        cid = stable_id("cards", lang=lang, form=ca["form"], sense_id=sid)
        card_ids[ca["ref"]] = cid
        lid = sense_lemma[sid]
        rows["cards"].append(_complete("cards", {
            "id": cid, "lang": lang, "form": ca["form"], "sense_id": sid,
            "form_norm": form_norm(ca["form"]), "lemma_id": lid, "pos": lemma_pos[lid],
            "form_kind": ca.get("form_kind"), "form_label_de": ca.get("form_label_de"),
            "translation_de": ca.get("translation_de"), "cefr_band": ca.get("cefr_band"),
            "freq_rank": ca.get("freq_rank"), "is_multiword": " " in ca["form"].strip(),
        }))

    for df in pack.get("dictionary_forms", []):
        sid = _lookup(sense_ids, "sense", df["sense"])
        norm = form_norm(df["form"])
        rows["dictionary_forms"].append(_complete("dictionary_forms", {
            "id": stable_id("dictionary_forms", lang=lang, form_norm=norm, sense_id=sid),
            "lang": lang, "form_norm": norm, "sense_id": sid,
            "card_id": _lookup(card_ids, "card", df.get("card")),
            "gloss_de": df["gloss_de"], "rank": df.get("rank"),
        }))

    for de in pack.get("decks", []):
        did = stable_id("decks", lang=lang, slug=de["slug"])
        deck_ids[de["ref"]] = did
        rows["decks"].append(_complete("decks", {
            "id": did, "lang": lang, "slug": de["slug"], "title_de": de["title_de"],
            "description_de": de.get("description_de"), "cefr_band": de.get("cefr_band"),
            "icon": de.get("icon"), "sort": de.get("sort"),
        }))

    for dc in pack.get("deck_cards", []):
        did = _lookup(deck_ids, "deck", dc["deck"])
        cid = _lookup(card_ids, "card", dc["card"])
        rows["deck_cards"].append(_complete("deck_cards", {
            "id": stable_id("deck_cards", deck_id=did, card_id=cid),
            "deck_id": did, "card_id": cid, "position": dc.get("position"),
        }))

    for sn in pack.get("sentences", []):
        snid = stable_id("sentences", lang=lang, text=sn["text"])
        sentence_ids[sn["ref"]] = snid
        rows["sentences"].append(_complete("sentences", {
            "id": snid, "lang": lang, "text": sn["text"], "origins": list(sn.get("origins", [])),
            "translation_de": sn.get("translation_de"), "model": sn.get("model"),
            "qa_status": sn.get("qa_status"), "qa_report": sn.get("qa_report"),
        }))

    for tk in pack.get("sentence_tokens", []):
        snid = _lookup(sentence_ids, "sentence", tk["sentence"])
        rows["sentence_tokens"].append(_complete("sentence_tokens", {
            "id": stable_id("sentence_tokens", sentence_id=snid, idx=tk["idx"]),
            "sentence_id": snid, "idx": tk["idx"], "start_pos": tk["start_pos"],
            "end_pos": tk["end_pos"], "surface": tk["surface"],
            "lemma_id": _lookup(lemma_ids, "lemma", tk.get("lemma")),
            "sense_id": _lookup(sense_ids, "sense", tk.get("sense")),
            "card_id": _lookup(card_ids, "card", tk.get("card")),
        }))

    for cs in pack.get("card_sentences", []):
        cid = _lookup(card_ids, "card", cs["card"])
        snid = _lookup(sentence_ids, "sentence", cs["sentence"])
        rows["card_sentences"].append(_complete("card_sentences", {
            "id": stable_id("card_sentences", card_id=cid, sentence_id=snid),
            "card_id": cid, "sentence_id": snid, "position": cs["position"],
            "gap_start": cs["gap_start"], "gap_end": cs["gap_end"],
            "accepted": list(cs.get("accepted", [])),
        }))

    release = pack.get("release")
    if release:
        rows["content_releases"].append(_complete("content_releases", {
            "id": stable_id("content_releases", lang=lang, version=release["version"]),
            "lang": lang, "version": release["version"],
            "schema_version": release["schema_version"], "notes": release.get("notes"),
        }))

    return rows


def sentence_lint_items(pack: dict) -> list[dict]:
    """Every card sentence of the pack with its form and gap, for the linter."""
    forms = {c["ref"]: c["form"] for c in pack.get("cards", [])}
    texts = {s["ref"]: s["text"] for s in pack.get("sentences", [])}
    return [
        {"card": cs["card"], "form": forms[cs["card"]], "sentence": texts[cs["sentence"]],
         "gap_start": cs["gap_start"], "gap_end": cs["gap_end"]}
        for cs in pack.get("card_sentences", [])
    ]
