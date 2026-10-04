"""Reproducible curation of existing packs (docs/pilot-60-curation-plan.md).

curate() takes loaded packs and a versioned curation list
(pipeline/data/curation/*.json) and returns a new working state plus a change
log. Inputs are never mutated. Every operation names its source, card
reference and stable sentence ID; preconditions (expected text, translation,
alternative) must match exactly once, otherwise CurationError and no result.

The working state is not a final pack: changed English texts need annotation
and QA (Vertex), changed translations a new translation check, and the final
dictionary_forms (set and rank) follow only from the annotated tokens. The
source dictionary entries are kept with their origin in
working["curation"]["dictionary_sources"]. Open steps are listed in
working["curation"]["pending"]; pack.build_rows() and finalize() refuse such a
state.
"""

from __future__ import annotations

import copy

from .generate import gap_offsets
from .ids import stable_id
from .linter import _whole_token_count
from .pack import deck_order_key


class CurationError(ValueError):
    pass


def sentence_id(lang: str, text: str) -> str:
    return stable_id("sentences", lang=lang, text=text)


def _reref(name: str, pack: dict) -> None:
    """Local sentence refs (s1, s2, ...) collide between packs: prefix them
    with the source name in sentences, tokens and card sentences."""
    new = {s["ref"]: f"{name}/{s['ref']}" for s in pack["sentences"]}
    for s in pack["sentences"]:
        s["ref"] = new[s["ref"]]
    for row in pack["sentence_tokens"] + pack["card_sentences"]:
        row["sentence"] = new[row["sentence"]]


def _card(pack: dict, ref: str, where: str) -> dict:
    found = [c for c in pack["cards"] if c["ref"] == ref]
    if len(found) != 1:
        raise CurationError(f"{where}: card {ref!r} found {len(found)}x, expected exactly once")
    return found[0]


def _remove_card(work: dict, ref: str, where: str) -> dict:
    card = _card(work, ref, where)
    links = [cs for cs in work["card_sentences"] if cs["card"] == ref]
    srefs = {cs["sentence"] for cs in links}
    shared = [cs for cs in work["card_sentences"] if cs["sentence"] in srefs and cs["card"] != ref]
    if shared:
        raise CurationError(f"{where}: sentences of {ref!r} are shared with other cards")
    work["cards"].remove(card)
    work["card_sentences"] = [cs for cs in work["card_sentences"] if cs["card"] != ref]
    removed = [s for s in work["sentences"] if s["ref"] in srefs]
    work["sentences"] = [s for s in work["sentences"] if s["ref"] not in srefs]
    work["sentence_tokens"] = [t for t in work["sentence_tokens"] if t["sentence"] not in srefs]
    work["deck_cards"] = [d for d in work["deck_cards"] if d["card"] != ref]
    return {"card": ref, "sentence_ids": [sentence_id(work["lang"], s["text"]) for s in removed]}


def _copy_card(work: dict, src: dict, name: str, ref: str, where: str, log: dict) -> dict:
    if any(c["ref"] == ref for c in work["cards"]):
        raise CurationError(f"{where}: card {ref!r} already exists in the working state")
    card = copy.deepcopy(_card(src, ref, where))
    links = [copy.deepcopy(cs) for cs in src["card_sentences"] if cs["card"] == ref]
    srefs = {cs["sentence"] for cs in links}
    sentences = [copy.deepcopy(s) for s in src["sentences"] if s["ref"] in srefs]
    tokens = [copy.deepcopy(t) for t in src["sentence_tokens"] if t["sentence"] in srefs]
    existing = {sentence_id(work["lang"], s["text"]) for s in work["sentences"]}
    clash = [s["text"] for s in sentences if sentence_id(work["lang"], s["text"]) in existing]
    if clash:
        raise CurationError(f"{where}: sentence text already in the working state: {clash}")
    # lemmas and senses by content-derived ref; existing rows win, conflicts are logged
    need_senses = {card["sense"]} | {t["sense"] for t in tokens if t.get("sense")}
    src_senses = {s["ref"]: s for s in src["senses"]}
    work_senses = {s["ref"]: s for s in work["senses"]}
    for sref in sorted(need_senses):
        if sref not in work_senses:
            work["senses"].append(copy.deepcopy(src_senses[sref]))
        elif work_senses[sref].get("gloss_de") != src_senses[sref].get("gloss_de"):
            conflict = {"kind": "sense_gloss", "sense": sref,
                        "kept": work_senses[sref].get("gloss_de"),
                        "not_taken": src_senses[sref].get("gloss_de"), "source": name}
            if conflict not in log["metadata_conflicts"]:
                log["metadata_conflicts"].append(conflict)
    need_lemmas = ({src_senses[s]["lemma"] for s in need_senses}
                   | {t["lemma"] for t in tokens if t.get("lemma")})
    work_lemmas = {lm["ref"] for lm in work["lemmas"]}
    work["lemmas"] += [copy.deepcopy(lm) for lm in src["lemmas"]
                       if lm["ref"] in need_lemmas and lm["ref"] not in work_lemmas]
    decks = {d["deck"] for d in src["deck_cards"] if d["card"] == ref}
    if len(decks) != 1 or not any(d["ref"] in decks for d in work["decks"]):
        raise CurationError(f"{where}: deck of {ref!r} missing in source or working state")
    work["cards"].append(card)
    work["card_sentences"] += links
    work["sentences"] += sentences
    work["sentence_tokens"] += tokens
    work["deck_cards"].append({"deck": decks.pop(), "card": ref, "position": None})
    return {"card": ref, "source": name,
            "sentence_ids": [sentence_id(work["lang"], s["text"]) for s in sentences]}


def _locate(work: dict, op: dict, where: str) -> tuple[dict, dict]:
    prefix = op["source"] + "/"
    texts = {s["ref"]: s for s in work["sentences"]}
    hits = [cs for cs in work["card_sentences"]
            if cs["card"] == op["card"] and cs["sentence"].startswith(prefix)
            and sentence_id(work["lang"], texts[cs["sentence"]]["text"]) == op["sentence_id"]]
    if len(hits) != 1:
        raise CurationError(f"{where}: sentence {op['sentence_id']} on card {op['card']!r} "
                            f"in {op['source']} found {len(hits)}x, expected exactly once")
    cs = hits[0]
    if cs["sentence"] != prefix + op["label"]:
        raise CurationError(f"{where}: label {op['label']!r} does not match ref {cs['sentence']!r}")
    if sum(other["sentence"] == cs["sentence"] for other in work["card_sentences"]) != 1:
        raise CurationError(f"{where}: sentence is linked to more than one card")
    sentence = texts[cs["sentence"]]
    for key, expected in op.get("expect", {}).items():
        if sentence.get(key) != expected:
            raise CurationError(f"{where}: {key} differs: expected {expected!r}, "
                                f"found {sentence.get(key)!r}")
    return cs, sentence


def _pending_annotation(pending: list, card: str, work: dict) -> None:
    refs = sorted(cs["sentence"] for cs in work["card_sentences"] if cs["card"] == card)
    entry = next((p for p in pending if p["kind"] == "annotate_card" and p["card"] == card), None)
    if entry is None:
        pending.append({"kind": "annotate_card", "card": card, "sentences": refs,
                        "note": "annotate_card annotates all three sentences of the card; "
                                "existing token rows of unchanged sentences come from the "
                                "source pack and stay until then"})
    else:
        entry["sentences"] = refs


def _editorial_sentence(work: dict, cs: dict, sentence: dict, op: dict,
                        version: str, pending: list, log: dict) -> None:
    """Explicit model-editorial decision, never a fabricated Vertex verdict.

    Used only by the hash-bound exchange adapter. Historical evidence lives in
    the change log; the current QA report binds the exact new text and lists.
    Annotation and full lint remain mandatory pending steps.
    """
    from .pack import _valid_alternatives

    before = {k: cs.get(k, []) for k in
              ("gap_start", "gap_end", "accepted", "valid_alternatives")}
    if before != op["expect_link"] or not op.get("reason") or not op.get("provenance"):
        raise CurationError("editorial sentence: missing provenance or link precondition differs")
    new = op["new"]
    card = _card(work, cs["card"], "editorial sentence")
    if new["accepted"] != cs["accepted"] or new["accepted"] != [card["form"]]:
        raise CurationError("editorial sentence: accepted must stay the target form")
    if _whole_token_count(new["text"], card["form"]) != 1:
        raise CurationError("editorial sentence: target must occur exactly once")
    gap = gap_offsets(new["text"], card["form"])
    if list(gap) != [new["gap_start"], new["gap_end"]]:
        raise CurationError("editorial sentence: declared gap differs from gap_offsets")
    _valid_alternatives(dict(cs, valid_alternatives=new["valid_alternatives"]), card["form"])
    original = copy.deepcopy(sentence)
    old_ref = sentence["ref"]
    old_id = sentence_id(work["lang"], sentence["text"])
    changed = new["text"] != sentence["text"]
    history = {"sentence": original, "link": copy.deepcopy(cs)}
    if changed:
        new_id = sentence_id(work["lang"], new["text"])
        if any(sentence_id(work["lang"], s["text"]) == new_id for s in work["sentences"]):
            raise CurationError("editorial sentence: duplicate replacement text")
        history["tokens"] = [t for t in work["sentence_tokens"] if t["sentence"] == old_ref]
        work["sentence_tokens"] = [t for t in work["sentence_tokens"] if t["sentence"] != old_ref]
        history["audio"] = [a for a in work.get("audio_assets", [])
                            if a.get("owner_kind") == "sentence"
                            and a.get("owner_id") in (old_ref, old_id)]
        if "audio_assets" in work:
            work["audio_assets"] = [a for a in work["audio_assets"] if a not in history["audio"]]
        sentence.clear()
        sentence.update(ref=f"{version}/{old_ref}", origins=original.get("origins", []), model=None)
        cs["sentence"] = sentence["ref"]
        pending.append({"kind": "editorial_annotation", "sentence": sentence["ref"],
                        "card": cs["card"], "op_id": op["op_id"]})
    sentence.update(text=new["text"], translation_de=new["translation_de"],
                    qa_status="editorial_reviewed", qa_report={
                        "editorial": {"provenance": op["provenance"], "op_id": op["op_id"],
                                      "reason": op["reason"], "checked": copy.deepcopy(new),
                                      "alternatives_exhaustive": False,
                                      "new_vertex_check": False},
                        "historical_source_sentence_id": old_id})
    cs.update({k: copy.deepcopy(new[k]) for k in before})
    log["sentence_operations"].append({
        "op": "editorial_sentence", "op_id": op["op_id"], "card": cs["card"],
        "old_sentence_id": old_id, "new_sentence_id": sentence_id(work["lang"], new["text"]),
        "new_ref": sentence["ref"], "english_changed": changed, "history": history,
        "new": copy.deepcopy(new), "reason": op["reason"]})


def curate(packs: dict[str, dict], curation: dict, card_meta: dict[str, dict]) -> tuple[dict, dict]:
    """New working state and change log. [card_meta]: card ref → {rank,
    usage, sense_index} for the deck order (pack.deck_order_key)."""
    packs = copy.deepcopy(packs)
    lang, base = curation["lang"], curation["base"]
    missing = [n for n in [base, *curation["sources"]] if n not in packs]
    if missing:
        raise CurationError(f"missing source packs: {missing}")
    metadata = []
    if "metadata_resolutions" in curation:
        # Opt-in strict merge: every differing entity needs an exact, versioned
        # decision. Keep source rows in the log before changing our copies.
        decisions = {(r["table"], r["ref"]): r for r in curation["metadata_resolutions"]}
        if len(decisions) != len(curation["metadata_resolutions"]):
            raise CurationError("duplicate metadata resolution")
        used = set()
        for table in ("lemmas", "senses", "decks"):
            groups = {}
            for name, pack in packs.items():
                for row in pack[table]:
                    group = groups.setdefault(row["ref"], {})
                    if name in group:
                        raise CurationError(f"duplicate {table} ref {row['ref']}")
                    group[name] = row
            for ref, origins in groups.items():
                key = (table, ref)
                decision = decisions.get(key)
                if decision:
                    if origins != decision["expect"] or not decision.get("reason"):
                        raise CurationError(f"metadata precondition differs: {table}/{ref}")
                    if table != "senses" or set(decision["new"]) != {"gloss_de"}:
                        raise CurationError("only explicit sense gloss changes supported")
                    metadata.append(copy.deepcopy(decision))
                    for row in origins.values():
                        row.update(decision["new"])
                    used.add(key)
                if any(row != next(iter(origins.values())) for row in origins.values()):
                    raise CurationError(f"unresolved metadata conflict: {table}/{ref}")
        if set(decisions) != used:
            raise CurationError("unused metadata resolution")
    for name, pack in packs.items():
        if pack["lang"] != lang:
            raise CurationError(f"{name}: lang {pack['lang']!r} != {lang!r}")
        _reref(name, pack)
    work = packs[base]
    log = {"version": curation["version"], "card_operations": [], "sentence_operations": [],
           "metadata_conflicts": [], "metadata_resolutions": metadata, "pruned": {}}
    pending: list[dict] = []

    # every card of a non-base source must be decided exactly once
    decided: dict[tuple[str, str], int] = {}
    for i, op in enumerate(curation["card_operations"], start=1):
        decided[(op["source"], op["card"])] = decided.get((op["source"], op["card"]), 0) + 1
    for name, pack in packs.items():
        if name == base:
            continue
        for c in pack["cards"]:
            if decided.get((name, c["ref"])) != 1:
                raise CurationError(f"{name}: card {c['ref']!r} needs exactly one card operation, "
                                    f"has {decided.get((name, c['ref']), 0)}")

    for i, op in enumerate(curation["card_operations"], start=1):
        where = f"card_operations[{i}] {op['op']} {op['card']!r}"
        if op["source"] == base or op["source"] not in packs:
            raise CurationError(f"{where}: source must be a non-base pack")
        src = packs[op["source"]]
        if op["op"] == "keep_base_card":
            _card(src, op["card"], where)
            _card(work, op["card"], where)
            log["card_operations"].append({"op": "keep_base_card", "card": op["card"],
                                           "not_taken_from": op["source"]})
        elif op["op"] == "add_card":
            entry = _copy_card(work, src, op["source"], op["card"], where, log)
            log["card_operations"].append({"op": "add_card", **entry})
        elif op["op"] == "replace_card":
            removed = _remove_card(work, op["replaces"], where)
            entry = _copy_card(work, src, op["source"], op["card"], where, log)
            log["card_operations"].append({"op": "replace_card", "removed": removed, "added": entry,
                                           "old_ids_publication": "unknown"})
        else:
            raise CurationError(f"{where}: unknown operation")

    cards = {c["ref"]: c for c in work["cards"]}
    for i, op in enumerate(curation["sentence_operations"], start=1):
        where = f"sentence_operations[{i}] {op['op']} {op['source']}/{op['label']}"
        cs, sentence = _locate(work, op, where)
        old_id = op["sentence_id"]
        if op["op"] == "editorial_sentence":
            _editorial_sentence(work, cs, sentence, op, curation["version"], pending, log)
        elif op["op"] == "replace_text":
            text, form = op["new"]["text"], cards[op["card"]]["form"]
            if _whole_token_count(text, form) != 1:
                raise CurationError(f"{where}: new text must contain {form!r} exactly once")
            new_id = sentence_id(lang, text)
            if any(sentence_id(lang, s["text"]) == new_id for s in work["sentences"]):
                raise CurationError(f"{where}: new text already exists in the working state")
            gap = gap_offsets(text, form)
            new_ref = f"{curation['version']}/{op['source']}/{op['label']}"
            dropped_tokens = sum(t["sentence"] == sentence["ref"] for t in work["sentence_tokens"])
            work["sentence_tokens"] = [t for t in work["sentence_tokens"]
                                       if t["sentence"] != sentence["ref"]]
            work["sentences"][work["sentences"].index(sentence)] = {
                "ref": new_ref, "text": text, "translation_de": op["new"]["translation_de"],
                "origins": list(sentence.get("origins", [])), "model": None,
                "qa_status": "pending",
                "qa_report": {"curation": {"version": curation["version"],
                                           "replaces_sentence_id": old_id}}}
            dropped_alternatives = list(cs.get("valid_alternatives", []))
            cs.update(sentence=new_ref, gap_start=gap[0], gap_end=gap[1], valid_alternatives=[])
            log["sentence_operations"].append({
                "op": "replace_text", "label": op["label"], "card": op["card"],
                "old_sentence_id": old_id, "new_sentence_id": new_id, "new_ref": new_ref,
                "gap": list(gap), "dropped_tokens": dropped_tokens,
                "dropped_alternatives": dropped_alternatives})
            _pending_annotation(pending, op["card"], work)
            pending.append({"kind": "sentence_qa", "sentence": new_ref, "sentence_id": new_id,
                            "checks": ["lint", "blindtest", "meaning_check", "alternative_check"],
                            "recheck_alternatives": dropped_alternatives})
        elif op["op"] in ("replace_translation", "editorial_translation"):
            if op["op"] == "editorial_translation" and (
                    not op.get("reason") or set(op.get("expect", {})) != {"text", "translation_de"}):
                raise CurationError(f"{where}: editorial translation needs text, translation and reason")
            sentence["translation_de"] = op["new"]["translation_de"]
            log["sentence_operations"].append({
                "op": op["op"], "label": op["label"], "card": op["card"],
                "sentence_id": old_id, "old": op["expect"]["translation_de"],
                "new": op["new"]["translation_de"], "reason": op.get("reason")})
            if op["op"] == "replace_translation":
                pending.append({"kind": "translation_check", "sentence": sentence["ref"],
                                "sentence_id": old_id})
            else:
                sentence.setdefault("editorial_reviews", []).append({
                    "version": curation["version"], "kind": "translation", "model_check": False,
                    "original": op["expect"], "translation_de": sentence["translation_de"],
                    "reason": op["reason"]})
        elif op["op"] == "remove_alternative":
            before = list(cs.get("valid_alternatives", []))
            if before.count(op["alternative"]) != 1:
                raise CurationError(f"{where}: alternative {op['alternative']!r} found "
                                    f"{before.count(op['alternative'])}x, expected exactly once")
            cs["valid_alternatives"] = [a for a in before if a != op["alternative"]]
            log["sentence_operations"].append({
                "op": "remove_alternative", "label": op["label"], "card": op["card"],
                "sentence_id": old_id, "removed": op["alternative"], "before": before,
                "after": cs["valid_alternatives"],
                **({"reason": op["reason"]} if "reason" in op else {}),
                "note": "qa_report.alternative_check keeps the historical model verdict"})
        else:
            raise CurationError(f"{where}: unknown operation")

    for op in curation.get("editorial_metadata", []):
        if (op["table"], op["field"]) not in (("senses", "gloss_de"), ("cards", "translation_de")):
            raise CurationError("unsupported editorial metadata field")
        hits = [r for r in work[op["table"]] if r["ref"] == op["ref"]]
        if len(hits) != 1 or hits[0][op["field"]] != op["expect"] or not op.get("reason"):
            raise CurationError(f"editorial metadata precondition: {op['ref']}")
        affected = sorted(c["ref"] for c in work["cards"]
                          if c["sense"] == op["ref"] or c["ref"] == op["ref"])
        if affected != sorted(op["affected_card_refs"]):
            raise CurationError(f"editorial metadata affected cards: {op['ref']}")
        hits[0][op["field"]] = op["new"]
        log.setdefault("editorial_metadata", []).append(copy.deepcopy(op))

    if any(op["op"] == "editorial_sentence" for op in curation["sentence_operations"]):
        pending.append({"kind": "editorial_validation", "note": "complete lint and ID/reference checks"})

    # drop lemmas and senses that nothing references any more
    used_senses = {c["sense"] for c in work["cards"]} | {t["sense"] for t in work["sentence_tokens"]
                                                          if t.get("sense")}
    before = len(work["senses"])
    work["senses"] = [s for s in work["senses"] if s["ref"] in used_senses]
    used_lemmas = ({s["lemma"] for s in work["senses"]}
                   | {t["lemma"] for t in work["sentence_tokens"] if t.get("lemma")})
    before_lemmas = len(work["lemmas"])
    work["lemmas"] = [lm for lm in work["lemmas"] if lm["ref"] in used_lemmas]
    log["pruned"] = {"senses": before - len(work["senses"]),
                     "lemmas": before_lemmas - len(work["lemmas"])}

    # dictionary_forms: the gloss is the translation of the concrete form
    # (token annotation), not the sense gloss, and the rank counts tokens.
    # Keep every source entry by schema key (form_norm + sense) with its
    # origin; the final set and ranks follow only from the annotated tokens.
    dictionary = _dictionary_sources(packs)
    work["dictionary_forms"] = []
    log["dictionary_forms"] = {"preserved_keys": len(dictionary["entries"]),
                               "conflicting_keys": len(dictionary["conflicts"])}
    pending.append({"kind": "dictionary_forms",
                    "note": "source entries are preserved in curation.dictionary_sources; the "
                            "final set and rank follow from the tokens after annotation; then "
                            "list keys without a form translation and keys with conflicting "
                            "values one by one",
                    "conflicting_keys": dictionary["conflicts"]})

    # deck positions with the existing order rule
    deck_rows = {d["card"]: d for d in work["deck_cards"]}
    if set(deck_rows) != set(cards) or len(deck_rows) != len(work["deck_cards"]):
        raise CurationError("every card needs exactly one deck_cards row")
    missing_meta = sorted(set(cards) - set(card_meta))
    if missing_meta:
        raise CurationError(f"card_meta missing for {missing_meta}")

    def order(ref: str) -> tuple:
        form, lref, key = ref.split("|")
        return deck_order_key({**card_meta[ref], "form": form, "sense_key": key})
    for position, ref in enumerate(sorted(cards, key=order), start=1):
        deck_rows[ref]["position"] = position

    # structure checks and expected counts
    srefs = {s["ref"] for s in work["sentences"]}
    for ref in cards:
        positions = sorted(cs["position"] for cs in work["card_sentences"] if cs["card"] == ref)
        if positions != [1, 2, 3]:
            raise CurationError(f"card {ref!r} has sentence positions {positions}")
    for cs in work["card_sentences"]:
        text = next(s["text"] for s in work["sentences"] if s["ref"] == cs["sentence"])
        if text[cs["gap_start"]:cs["gap_end"]].casefold() != cards[cs["card"]]["form"].casefold():
            raise CurationError(f"gap of {cs['sentence']!r} does not match {cs['card']!r}")
    if {t["sentence"] for t in work["sentence_tokens"]} - srefs or \
            {cs["sentence"] for cs in work["card_sentences"]} != srefs:
        raise CurationError("sentence references are inconsistent")
    ids = [sentence_id(lang, s["text"]) for s in work["sentences"]]
    if len(set(ids)) != len(ids):
        raise CurationError("duplicate sentence texts in the working state")
    counts = {"cards": len(work["cards"]), "card_sentences": len(work["card_sentences"])}
    if counts != curation["expect"]:
        raise CurationError(f"counts {counts} != expected {curation['expect']}")
    log["counts"] = counts

    work["release"] = {"version": curation["version"],
                       "schema_version": (work.get("release") or {}).get("schema_version", 1),
                       "notes": "curated working state, not a final pack"}
    work["curation"] = {"version": curation["version"], "sources": sorted(packs),
                        "pending": pending, "dictionary_sources": dictionary["entries"]}
    return work, log


def _dictionary_sources(packs: dict[str, dict]) -> dict:
    """Every dictionary_forms entry of the source packs by (form, sense) with
    its origin. Identical values are merged; different values stay side by
    side and the key is listed as a conflict. No value is chosen here."""
    entries: dict[tuple[str, str], dict] = {}
    for name in sorted(packs):
        for d in packs[name].get("dictionary_forms", []):
            entry = entries.setdefault((d["form"], d["sense"]),
                                       {"form": d["form"], "sense": d["sense"], "values": []})
            value = next((v for v in entry["values"] if v["gloss_de"] == d["gloss_de"]), None)
            if value is None:
                value = {"gloss_de": d["gloss_de"], "sources": {}}
                entry["values"].append(value)
            value["sources"][name] = {"card": d.get("card"), "rank": d.get("rank")}
    return {"entries": [entries[k] for k in sorted(entries)],
            "conflicts": [{"form": f, "sense": s} for (f, s) in sorted(entries)
                          if len(entries[(f, s)]["values"]) > 1]}


def derive_dictionary(work: dict, resolutions: list[dict] | None = None) -> dict:
    """dictionary_forms from the complete token set. Values: preserved source
    entries and annotation glosses with origin; no sense gloss fallback.
    [resolutions]: editorial choices by exact (form, sense); applied only if
    the key's variants equal expected_variants exactly, otherwise and for
    unused resolutions CurationError. Rejected variants stay in the origin."""
    from .ids import form_norm

    counts: dict[tuple[str, str], list] = {}
    for t in work["sentence_tokens"]:
        if t.get("sense"):
            c = counts.setdefault((form_norm(t["surface"]), t["sense"]), [0, None])
            c[0] += 1
            c[1] = c[1] or t.get("card")
    values: dict[tuple[str, str], dict] = {}
    for e in work["curation"]["dictionary_sources"]:
        for v in e["values"]:
            values.setdefault((e["form"], e["sense"]), {}).setdefault(
                v["gloss_de"], {})["sources"] = v["sources"]
    for g in work["curation"].get("annotation_glosses", []):
        origin = values.setdefault((g["form"], g["sense"]), {}).setdefault(g["gloss_de"], {})
        origin.setdefault("annotation", []).append({"sentence": g["sentence"], "idx": g["idx"]})
    chosen: dict[tuple[str, str], dict] = {}
    for r in resolutions or []:
        key = (r["form"], r["sense"])
        if key in chosen:
            raise CurationError(f"resolution for {key} given twice")
        chosen[key] = r
    by_form: dict[str, list] = {}
    for (norm, sense), (n, card) in counts.items():
        by_form.setdefault(norm, []).append((-n, sense, card))
    entries, missing, conflicts, used = [], [], [], set()
    for norm in sorted(by_form):
        for rank, (_, sense, card) in enumerate(sorted(by_form[norm]), start=1):
            found = values.get((norm, sense), {})
            r = chosen.get((norm, sense))
            if r is not None:
                if sorted(found) != sorted(r["expected_variants"]) or (r["gloss_de"] not in found
                        and not (r.get("editorial") is True and r.get("reason") and found)):
                    raise CurationError(f"resolution {norm!r}/{sense!r}: variants {sorted(found)} "
                                        f"!= expected {sorted(r['expected_variants'])} or choice missing")
                used.add((norm, sense))
                entries.append({"form": norm, "sense": sense, "card": card, "gloss_de": r["gloss_de"],
                                "rank": rank, "origin": dict(found.get(r["gloss_de"], {"editorial": True}), resolution={
                                    "reason": r["reason"], "rejected": [
                                        {"gloss_de": k, **v} for k, v in found.items()
                                        if k != r["gloss_de"]]})})
            elif not found:
                missing.append({"form": norm, "sense": sense})
            elif len(found) > 1:
                conflicts.append({"form": norm, "sense": sense,
                                  "values": [{"gloss_de": k, **v} for k, v in found.items()]})
            else:
                [(gloss, origin)] = found.items()
                entries.append({"form": norm, "sense": sense, "card": card, "gloss_de": gloss,
                                "rank": rank, "origin": origin})
    unused = sorted(set(chosen) - used)
    if unused:
        raise CurationError(f"resolutions for keys not in the token set: {unused}")
    return {"entries": entries, "missing": missing, "conflicts": conflicts,
            "token_keys": sum(len(v) for v in by_form.values())}


def finalize(work: dict) -> dict:
    """Final pack only without pending steps."""
    pending = (work.get("curation") or {}).get("pending")
    if pending:
        kinds = sorted({p["kind"] for p in pending})
        raise CurationError(f"working state has {len(pending)} pending steps ({', '.join(kinds)}); "
                            "not a final pack")
    final = copy.deepcopy(work)
    final.pop("curation", None)
    return final


def card_meta_from_inventory(packs: dict[str, dict], inventory) -> dict[str, dict]:
    """rank (freq_rank), usage and sense_index (1-based meaning order of the
    form in the inventory) for every card of the given packs."""
    meta = {}
    for pack in packs.values():
        for card in pack["cards"]:
            key = card["ref"].split("|")[2]
            meanings = inventory.get(card["form"]) or []
            hits = [(i, m) for i, m in enumerate(meanings, start=1) if m["sense_key"] == key]
            if len(hits) != 1:
                raise CurationError(f"inventory: {card['ref']!r} found {len(hits)}x")
            i, m = hits[0]
            meta[card["ref"]] = {"rank": card.get("freq_rank"), "usage": m.get("usage"),
                                 "sense_index": i}
    return meta
