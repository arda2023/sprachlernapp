"""Offline completion of a saved curation run: apply the versioned gloss
resolutions, derive dictionary_forms, check the state and write an internal
test pack (pack.json, content.sqlite, finalization_report.json).

Reuses the saved working state; no cloud call, no regeneration, no DB upload,
no tombstones. A technically complete pack is no public content approval.
Exit codes: 0 written and verified, 2 argument or precondition error,
3 export or verification error (finalization_report.json says "failed").
"""

from __future__ import annotations

from sprachpipe.content_contract import sentence_count

import argparse
import copy
import json
import sqlite3
import sys
from pathlib import Path

from sprachpipe.config import PIPELINE_DIR

RESOLUTIONS = PIPELINE_DIR / "data" / "curation" / "pilot_60_gloss_resolutions_v1.json"
INTERNAL_NOTE = ("INTERNES TEST-PACK: technisch geprüft, keine öffentliche Inhaltsfreigabe; "
                 "offene redaktionelle Fälle siehe docs/pilot-60-curation-plan.md Abschnitt 4")
OPEN_EDITORIAL = [
    "your#ihr / your#euer: Produktentscheidung offen (Plan 4.1)",
    "they#singular_they: Übersetzungskonvention offen",
    "like#fuellwort: nicht aufnehmen empfohlen, offen",
    "will#testament: Produktentscheidung offen",
    "Einzelsätze pilot_60_v1/s64, s292, s294, s390, s466: Ersatz empfohlen, offen",
    "pilot_60_v1/s398, s399: Übersetzungspräzisierung empfohlen, offen",
    "pos_check_v1/s9 (which#fragepronomen): Ersatz empfohlen, offen",
    "6 Alternativen (s18, s105, s141, s180 x2, s221): Entfernung empfohlen, offen",
    "Stilfälle Plan 4.2 und 9 Bedeutungsglossen-Konflikte (Pilotwert behalten)",
]
OLD_IDS_NOTE = ("Veröffentlichungsstatus alter IDs (u. a. be|be/VERB|be#befinden) ungeklärt; "
                "keine Tombstones, keine Lernstandsübertragung")


class FinalizeError(ValueError):
    pass


def _fail(msg: str):
    raise FinalizeError(msg)


def check_preconditions(work: dict, report: dict, expect: dict) -> None:
    from sprachpipe.ids import form_norm

    if report.get("aborted"):
        _fail(f"run was aborted: {report['aborted']}")
    pending = work["curation"]["pending"]
    if [p["kind"] for p in pending] != ["dictionary_forms"]:
        _fail(f"pending steps must be only dictionary_forms, found {[p['kind'] for p in pending]}")
    counts = {"cards": len(work["cards"]), "card_sentences": len(work["card_sentences"])}
    if counts != {k: expect[k] for k in counts}:
        _fail(f"counts {counts} != expected")
    texts = {s["ref"]: s for s in work["sentences"]}
    cards = {c["ref"]: c for c in work["cards"]}
    if len(cards) != len(work["cards"]):
        _fail("duplicate card refs")
    for ref in cards:
        pos = sorted(cs["position"] for cs in work["card_sentences"] if cs["card"] == ref and not cs.get("removed_in"))
        if pos != list(range(1, sentence_count(work)+1)):
            _fail(f"card {ref!r} has positions {pos}")
    for cs in work["card_sentences"]:
        s, form = texts.get(cs["sentence"]), cards[cs["card"]]["form"]
        if s is None or s["text"][cs["gap_start"]:cs["gap_end"]].casefold() != form.casefold():
            _fail(f"gap of {cs['sentence']!r} does not match {form!r}")
        if cs.get("accepted") != [form]:
            _fail(f"accepted of {cs['sentence']!r} is {cs.get('accepted')!r}")
        alts = cs.get("valid_alternatives", [])
        if len(set(alts)) != len(alts) or form_norm(form) in alts \
                or any(a != form_norm(a.strip()) for a in alts):
            _fail(f"valid_alternatives of {cs['sentence']!r} invalid: {alts}")
    # stored QA results must refer to the current text, translation and gap
    for step in work["curation"].get("completed", []):
        res = step["result"]
        if step["kind"] == "sentence_qa":
            s = texts[step["sentence"]]
            cs = next(c for c in work["card_sentences"] if c["sentence"] == s["ref"])
            now = {"text": s["text"], "translation_de": s["translation_de"],
                   "gap": [cs["gap_start"], cs["gap_end"]]}
            if res["checked"] != now or s.get("qa_status") != "ok" \
                    or cs["valid_alternatives"] != res["valid_alternatives"]:
                _fail(f"sentence_qa {s['ref']!r} does not match the current sentence")
        elif step["kind"] == "translation_check":
            s = texts[step["sentence"]]
            if res["checked"] != {"text": s["text"], "translation_de": s["translation_de"]}:
                _fail(f"translation_check {s['ref']!r} does not match the current sentence")
        elif step["kind"] == "annotate_card":
            links = sorted((c for c in work["card_sentences"]
                            if c["card"] == step["card"] and not c.get("removed_in")),
                           key=lambda c: c["position"])
            now = [{"text": texts[c["sentence"]]["text"],
                    "translation_de": texts[c["sentence"]]["translation_de"]} for c in links]
            if res["checked"] != now:
                _fail(f"annotation of {step['card']!r} does not match the current sentences")
    if any(s.get("qa_status") != "ok" for s in work["sentences"]):
        _fail("sentences without qa_status ok")
    # annotation complete and consistent
    lemmas = {lm["ref"] for lm in work["lemmas"]}
    senses = {se["ref"]: se for se in work["senses"]}
    with_tokens = {t["sentence"] for t in work["sentence_tokens"]}
    if with_tokens != set(texts):
        _fail(f"sentences without tokens: {sorted(set(texts) - with_tokens)[:5]}")
    for t in work["sentence_tokens"]:
        s = texts.get(t["sentence"])
        if s is None or s["text"][t["start_pos"]:t["end_pos"]] != t["surface"]:
            _fail(f"token offset mismatch in {t['sentence']!r} idx {t['idx']}")
        if t.get("lemma") is not None and t["lemma"] not in lemmas \
                or t.get("sense") is not None and t["sense"] not in senses \
                or t.get("card") is not None and t["card"] not in cards:
            _fail(f"unresolvable token ref in {t['sentence']!r} idx {t['idx']}")
        if t.get("card") and t["sense"] != cards[t["card"]]["sense"]:
            _fail(f"card token sense mismatch in {t['sentence']!r}")
    for c in work["cards"]:
        if c["sense"] not in senses or senses[c["sense"]]["lemma"] not in lemmas:
            _fail(f"unresolvable sense/lemma of card {c['ref']!r}")


def check_curation_log(work: dict, log: dict) -> None:
    """Removed alternatives stay removed; replaced cards stay replaced."""
    from sprachpipe.curate import sentence_id

    by_id = {sentence_id(work["lang"], s["text"]): s["ref"] for s in work["sentences"]}
    for op in log.get("sentence_operations", []):
        if op["op"] == "remove_alternative":
            ref = by_id.get(op["sentence_id"])
            cs = [c for c in work["card_sentences"] if c["sentence"] == ref and c["card"] == op["card"]]
            if len(cs) != 1 or op["removed"] in cs[0]["valid_alternatives"]:
                _fail(f"removed alternative {op['removed']!r} of {op['label']} is back or sentence missing")
    refs = {c["ref"] for c in work["cards"]}
    for op in log.get("card_operations", []):
        if op["op"] == "replace_card" and op["removed"]["card"] in refs:
            _fail(f"replaced card {op['removed']['card']!r} is back")


def check_pack(final: dict, before_rows: dict) -> dict:
    """Rows of the final pack: IDs unchanged by the gloss choice, deck
    positions and dictionary ranks consistent."""
    from sprachpipe.pack import build_rows

    rows = build_rows(final)
    for table, items in rows.items():
        if table in ("dictionary_forms", "content_releases"):
            continue
        if sorted(r.get("id", r.get("code")) for r in items) != \
                sorted(r.get("id", r.get("code")) for r in before_rows[table]):
            _fail(f"IDs of {table} changed by finalization")
    positions = sorted(d["position"] for d in rows["deck_cards"] if not d.get("removed_in"))
    if sentence_count(final) == 3 and positions != list(range(1, len(rows["cards"]) + 1)):
        _fail("deck positions are not 1..n")
    ranks: dict[str, list] = {}
    for d in rows["dictionary_forms"]:
        ranks.setdefault(d["form_norm"], []).append(d["rank"])
    if any(sorted(v) != list(range(1, len(v) + 1)) for v in ranks.values()):
        _fail("dictionary ranks are not 1..n per form")
    return rows


def check_sqlite(path: Path, rows: dict) -> dict:
    """Reopen the export and compare every row with build_rows."""
    from sprachpipe.export import _value
    from sprachpipe.schema import COLUMNS, TABLE_ORDER

    conn = sqlite3.connect(path)
    try:
        counts = {}
        for table in TABLE_ORDER:
            names = [n for n, _ in COLUMNS[table] if n != "created_at"]
            got = conn.execute(f'SELECT {", ".join(chr(34) + n + chr(34) for n in names)} '
                               f'FROM "{table}"').fetchall()
            want = [tuple(_value(pg, r.get(n)) for n, pg in COLUMNS[table] if n != "created_at")
                    for r in rows[table]]
            if sorted(got, key=repr) != sorted(want, key=repr):
                _fail(f"SQLite table {table} differs from build_rows")
            counts[table] = len(got)
    finally:
        conn.close()
    return counts


def finalize_state(work: dict, report: dict, resolutions: dict) -> tuple[dict, dict, dict]:
    """(final pack, summary, rows before) without touching the inputs."""
    from sprachpipe.curate import CurationError, derive_dictionary, finalize
    from sprachpipe.pack import build_rows

    work = copy.deepcopy(work)
    expect = resolutions["expect"]
    if resolutions["applies_to"] != work["curation"]["version"]:
        _fail(f"resolutions apply to {resolutions['applies_to']!r}, state is "
              f"{work['curation']['version']!r}")
    check_preconditions(work, report, expect)
    check_curation_log(work, (report.get("inputs") or {}).get("curation_log") or {})
    try:
        d = derive_dictionary(work, resolutions["resolutions"])
    except CurationError as e:
        _fail(str(e))
    if d["missing"] or d["conflicts"]:
        _fail(f"dictionary: {len(d['missing'])} missing, {len(d['conflicts'])} unresolved "
              f"({[(c['form'], c['sense']) for c in d['conflicts']][:5]})")
    if d["token_keys"] != expect["dictionary_keys"] or len(d["entries"]) != d["token_keys"]:
        _fail(f"dictionary keys {d['token_keys']} / entries {len(d['entries'])} != "
              f"expected {expect['dictionary_keys']}")
    [step] = work["curation"]["pending"]
    work["dictionary_forms"] = [{k: e[k] for k in ("form", "sense", "card", "gloss_de", "rank")}
                                for e in d["entries"]]
    before = build_rows(dict(work, curation=dict(work["curation"], pending=[])))
    resolved = [{"form": e["form"], "sense": e["sense"], "gloss_de": e["gloss_de"],
                 "origin": e["origin"]} for e in d["entries"] if "resolution" in e["origin"]]
    work["curation"]["pending"].remove(step)
    work["curation"].setdefault("completed", []).append(dict(step, result={
        "entries": len(d["entries"]), "resolutions": resolutions["version"], "resolved": resolved}))
    try:
        final = finalize(work)
    except CurationError as e:
        _fail(str(e))
    final["release"] = dict(final["release"], notes=INTERNAL_NOTE)
    summary = {"cards": len(final["cards"]), "card_sentences": len(final["card_sentences"]),
               "sentences": len(final["sentences"]), "sentence_tokens": len(final["sentence_tokens"]),
               "dictionary_keys": len(final["dictionary_forms"]), "resolved_conflicts": resolved,
               "completed_steps": [{k: s.get(k) for k in ("kind", "card", "sentence")}
                                   for s in work["curation"]["completed"]]}
    return final, summary, before


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="finalize_curation",
                                description="Offline finalization of a saved curation run into an "
                                            "internal test pack (no cloud, no DB upload, no release).")
    p.add_argument("--state", required=True, help="working_state.json of the curation run (read only)")
    p.add_argument("--report", required=True, help="report.json of the curation run (read only)")
    p.add_argument("--resolutions", default=str(RESOLUTIONS), help="gloss resolutions (default: %(default)s)")
    p.add_argument("--out", required=True, help="new output folder (must not exist)")
    try:
        args = p.parse_args(argv)
    except SystemExit as e:
        return 0 if e.code == 0 else 2
    out = Path(args.out)
    if out.exists():
        print(f"error: {out} already exists; choose a new folder", file=sys.stderr)
        return 2
    try:
        work = json.loads(Path(args.state).read_text(encoding="utf-8"))
        report = json.loads(Path(args.report).read_text(encoding="utf-8"))
        resolutions = json.loads(Path(args.resolutions).read_text(encoding="utf-8"))
        final, summary, before = finalize_state(work, report, resolutions)
        rows = check_pack(final, before)
    except (FinalizeError, OSError, ValueError, KeyError) as e:
        print(f"error: {type(e).__name__}: {e}", file=sys.stderr)
        return 2

    from sprachpipe.export import export_sqlite

    out.mkdir(parents=True)
    result = {"status": "failed", "internal_test_pack": True, "note": INTERNAL_NOTE,
              "inputs": {"state": args.state, "report": args.report, "resolutions": args.resolutions},
              "open_editorial_cases": OPEN_EDITORIAL, "old_ids_publication": OLD_IDS_NOTE,
              "ai_cost_usd": 0.0, **summary}
    try:
        (out / "pack.json").write_text(json.dumps(final, ensure_ascii=False, indent=1) + "\n",
                                       encoding="utf-8")
        exported = export_sqlite(final, out / "content.sqlite")
        result["sqlite_counts"] = check_sqlite(out / "content.sqlite", rows)
        if result["sqlite_counts"] != exported:
            _fail("SQLite counts differ from export")
        reloaded = json.loads((out / "pack.json").read_text(encoding="utf-8"))
        if reloaded != final:
            _fail("pack.json does not round-trip")
        result["status"] = "ok"
        code = 0
    except Exception as e:   # never a false success report
        result["error"] = f"{type(e).__name__}: {e}"
        code = 3
    (out / "finalization_report.json").write_text(json.dumps(result, ensure_ascii=False, indent=2)
                                                  + "\n", encoding="utf-8")
    print(f"status {result['status']}: {summary['cards']} cards, {summary['card_sentences']} card "
          f"sentences, {summary['sentences']} sentences, {summary['sentence_tokens']} tokens, "
          f"{summary['dictionary_keys']} dictionary keys, {len(summary['resolved_conflicts'])} "
          f"resolved gloss conflicts")
    for table, n in (result.get("sqlite_counts") or {}).items():
        print(f"  sqlite {table}: {n} (= build_rows)")
    print(f"note: {INTERNAL_NOTE}\nold IDs: {OLD_IDS_NOTE}")
    print(f"open editorial cases: {len(OPEN_EDITORIAL)} groups (see finalization_report.json)")
    print(f"out -> {out}")
    if code:
        print(f"failed: {result['error']}", file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
