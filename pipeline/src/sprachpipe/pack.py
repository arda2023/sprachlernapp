"""Pack file → table rows with stable IDs.

A pack is JSON written by hand or by later pipeline steps. Rows refer to
each other by `ref` names; build_rows() turns them into rows of the schema
`content` (schema.COLUMNS) with IDs from ids.stable_id().
"""

from __future__ import annotations

import json
from collections import Counter
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


def _valid_alternatives(cs: dict, form: str) -> list[str]:
    """Missing in old packs → []. null, wrong types, unnormalized values,
    duplicates or the target form are invalid content, never an empty result."""
    if "valid_alternatives" not in cs:
        return []
    values = cs["valid_alternatives"]
    where = f"card_sentences {cs.get('card')!r}/{cs.get('sentence')!r}: valid_alternatives"
    if type(values) is not list or not all(isinstance(v, str) for v in values):
        raise ValueError(f"{where} must be a list of strings")
    for v in values:
        if not v or v != form_norm(v.strip()):
            raise ValueError(f"{where}: {v!r} is not normalized")
        if v == form_norm(form):
            raise ValueError(f"{where}: {v!r} is the target form")
    if len(set(values)) != len(values):
        raise ValueError(f"{where}: duplicates")
    return list(values)


def build_rows(pack: dict) -> dict[str, list[dict]]:
    lang = pack["lang"]
    rows: dict[str, list[dict]] = {t: [] for t in COLUMNS}
    lemma_ids: dict[str, str] = {}
    lemma_pos: dict[str, str] = {}
    sense_ids: dict[str, str] = {}
    sense_lemma: dict[str, str] = {}
    card_ids: dict[str, str] = {}
    card_forms: dict[str, str] = {}
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
        card_forms[ca["ref"]] = ca["form"]
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
            "valid_alternatives": _valid_alternatives(cs, card_forms[cs["card"]]),
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
    cards = {c["ref"]: c for c in pack.get("cards", [])}
    texts = {s["ref"]: s["text"] for s in pack.get("sentences", [])}
    return [
        {"card": cs["card"], "form": cards[cs["card"]]["form"],
         "cefr_band": cards[cs["card"]].get("cefr_band") or "anfaenger",
         "sentence": texts[cs["sentence"]],
         "gap_start": cs["gap_start"], "gap_end": cs["gap_end"]}
        for cs in pack.get("card_sentences", [])
    ]


def _slug(text: str) -> str:
    import re
    import unicodedata

    t = text.lower().replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", t).strip("-") or "x"


def assemble_pack(lang: str, cards: list[dict], *, model: str, version: str) -> dict:
    """Pack (schema of tests/fixtures/mini_pack.json) from generated cards.
    A card goes in only with 3 ok sentences. Sets card['packed']."""
    pack = {"lang": lang, "release": {"version": version, "schema_version": 1,
                                      "notes": "generated by sprachpipe generate"},
            "languages": [{"code": "en", "name_native": "English", "name_de": "Englisch",
                           "gloss_lang": "de"}],
            "lemmas": [], "senses": [], "cards": [], "decks": [], "deck_cards": [],
            "dictionary_forms": [],
            "sentences": [], "sentence_tokens": [], "card_sentences": []}
    lemmas: set[str] = set()
    senses: set[str] = set()
    texts: set[str] = set()
    dict_counts: dict[tuple[str, str], list] = {}

    def lemma_ref(lemma: str, pos: str) -> str:
        ref = f"{lemma}/{pos}"
        if ref not in lemmas:
            lemmas.add(ref)
            pack["lemmas"].append({"ref": ref, "lemma": lemma, "pos": pos})
        return ref

    def sense_ref(lref: str, sense_key: str, gloss_de: str) -> str:
        ref = f"{lref}|{sense_key}"
        if ref not in senses:
            senses.add(ref)
            pack["senses"].append({"ref": ref, "lemma": lref, "sense_key": sense_key,
                                   "gloss_de": gloss_de})
        return ref

    packed_source = []
    for card in cards:
        finals = card.get("accepted", [])
        card["packed"] = (len(finals) == 3
                          and all(a["qa_status"] == "ok" and "tokens" in a for a in finals)
                          and not any(a["text"] in texts for a in finals))
        if not card["packed"]:
            continue
        packed_source.append(card)
        lref = lemma_ref(card["lemma"], card["pos"])
        sref = sense_ref(lref, card["sense_key"], card["gloss_de"])
        cref = f"{card['form']}|{sref}"
        pack["cards"].append({
            "ref": cref, "form": card["form"], "sense": sref, "form_kind": card["form_kind"],
            "form_label_de": card["form_label_de"], "translation_de": card["translation_de"],
            "cefr_band": card["cefr_band"], "freq_rank": card.get("rank")})
        for pos_, a in enumerate(finals, start=1):
            texts.add(a["text"])
            snref = f"s{len(pack['sentences']) + 1}"
            pack["sentences"].append({
                "ref": snref, "text": a["text"], "translation_de": a["translation_de"],
                "origins": ["deck"], "model": model, "qa_status": a["qa_status"],
                "qa_report": {"lint": a["lint"], "blind": a["blind"],
                              "blind_answer": a["blind_answer"],
                              "blind_alternatives": a.get("blind_alternatives", []),
                              "alternative_candidates": a.get("alternative_candidates", []),
                              "alternative_check": a.get("alternative_check", []),
                              "blind_attempts": [
                                  {"text": item["text"], "answer": item.get("blind_answer"),
                                   "blind": item.get("blind"),
                                   "alternatives": item.get("blind_alternatives", []),
                                   "candidates": item.get("alternative_candidates", []),
                                   "alternative_check": item.get("alternative_check", []),
                                   "discard_reason": item.get("discard_reason", "")}
                                  for slot in card["slots"] if any(item is a for item in slot)
                                  for item in slot if item.get("blind")],
                              "annotate": a.get("annotate_problems", []),
                              "meaning_check": a.get("meaning_check"),
                              "meaning_check_result": a.get("meaning_check_result"),
                              "language_ok": (a.get("meaning_check_result") or {}).get("language_ok"),
                              "discard_reason": a.get("discard_reason", ""),
                              "discard_reasons": a.get("discard_reasons", []),
                              "attempts": next(len(slot) for slot in card["slots"]
                                               if any(item is a for item in slot))}})
            pack["card_sentences"].append({
                "card": cref, "sentence": snref, "position": pos_,
                "gap_start": a["gap"][0], "gap_end": a["gap"][1], "accepted": [card["form"]],
                "valid_alternatives": list(a.get("valid_alternatives", []))})
            for t in a.get("tokens", []):
                row = {"sentence": snref, "idx": t["idx"], "start_pos": t["start_pos"],
                       "end_pos": t["end_pos"], "surface": t["surface"],
                       "lemma": None, "sense": None, "card": None}
                if t.get("gloss_de"):
                    tl = lemma_ref(t["lemma"], t["pos"])
                    key = card["sense_key"] if t.get("card") else \
                        f"{_slug(t['lemma'])}#{_slug(t['gloss_de'])}"
                    ts = sense_ref(tl, key, t["gloss_de"])
                    row.update(lemma=tl, sense=ts, card=cref if t.get("card") else None)
                    d = dict_counts.setdefault((form_norm(t["surface"]), ts),
                                               [t["surface"], t["gloss_de"], row["card"], 0])
                    d[3] += 1
                    d[2] = d[2] or row["card"]
                pack["sentence_tokens"].append(row)

    if packed_source:
        bands = Counter(c["cefr_band"] for c in packed_source)
        band = sorted(bands, key=lambda value: (-bands[value],
                      ["anfaenger", "mittel", "fortgeschritten"].index(value)))[0]
        pack["decks"].append({"ref": "allgemeine-sprache", "slug": "allgemeine-sprache",
                              "title_de": "Allgemeine Sprache", "cefr_band": band, "sort": 1})
        ordered = sorted(packed_source, key=lambda c: (
            (c.get("rank") or 10**9) + (200 if c.get("usage") == "neben" else 0),
            c.get("sense_index", 0), c["form"], c["sense_key"]))
        for position, card in enumerate(ordered, start=1):
            pack["deck_cards"].append({"deck": "allgemeine-sprache",
                                       "card": f"{card['form']}|{card['lemma']}/{card['pos']}|{card['sense_key']}",
                                       "position": position})

    # dictionary_forms: rank = order of the senses of one form by frequency in the pack.
    by_form: dict[str, list] = {}
    for (norm, sref), (surface, gloss, cref, n) in dict_counts.items():
        by_form.setdefault(norm, []).append((-n, sref, surface, gloss, cref))
    for norm in sorted(by_form):
        for rank, (_, sref, surface, gloss, cref) in enumerate(sorted(by_form[norm]), start=1):
            pack["dictionary_forms"].append({"form": norm, "sense": sref, "card": cref,
                                             "gloss_de": gloss, "rank": rank})
    return pack
