"""Targeted, budget-limited completion of a curated working state
(docs/pilot-60-curation-plan.md, sections 8 and 9).

Runs exactly the pending steps that curate() leaves open, once each, with the
existing QA functions, Vertex wrapper, cost ledger and budget reservation:
- translation_check: meaning_check of a changed German translation;
- sentence_qa: linter, blind test, meaning/language/translation check and
  alternative check of a replaced English sentence; dropped alternatives are
  re-checked in the new sentence and only confirmed ones are taken over;
- annotate_card: annotate_card() for all three sentences of a card whose
  replaced sentence passed QA;
- dictionary_forms: set and rank from the resulting tokens; form translations
  only from source entries or the new annotation, never from sense glosses.

No regeneration, no repair or retry loops (lint/blind retries are 0). A
rejection keeps its step open with the concrete finding. Technically closed
steps are no editorial approval. No DB upload, SQLite export or release.
Exit codes: 0 no open steps, 1 open steps remain, 2 argument or precondition
error, 3 technical or budget abort (partial state is saved).
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
from collections import Counter
from pathlib import Path

from sprachpipe.config import PIPELINE_DIR, load_config

CURATION = PIPELINE_DIR / "data" / "curation" / "pilot_60_v1.json"
STEP_ORDER = ("translation_check", "sentence_qa", "annotate_card", "dictionary_forms")
# (model key, max_output_tokens key) per call kind, for the cost upper bound
CALLS = {"blindtest": ("blindtest_model", "blindtest"),
         "meaning_check": ("meaning_check_model", "meaning_check"),
         "alternative_check": ("alternative_check_model", "alternative_check"),
         "annotate": ("generate_model", "annotate")}


class PreconditionError(ValueError):
    pass


# --- local helpers ---------------------------------------------------------

def card_info(work: dict, inventory, ref: str) -> dict:
    """Card dict for the QA and annotation functions; gloss from the inventory."""
    card = next(c for c in work["cards"] if c["ref"] == ref)
    form, lref, key = ref.split("|")
    lemma, pos = lref.rsplit("/", 1)
    meanings = inventory.get(form) or []
    hits = [m for m in meanings if m["sense_key"] == key]
    if len(hits) != 1:
        raise PreconditionError(f"inventory: {ref!r} found {len(hits)}x")
    return {"ref": ref, "form": form, "display_form": inventory.display_form(form),
            "lemma": lemma, "pos": pos, "sense_key": key, "sense": card["sense"],
            "gloss_de": hits[0]["gloss_de"], "cefr_band": card.get("cefr_band") or "anfaenger",
            "meanings": meanings}


def _sentence(work: dict, ref: str) -> dict:
    return next(s for s in work["sentences"] if s["ref"] == ref)


def _links(work: dict, card: str) -> list[dict]:
    return sorted((cs for cs in work["card_sentences"] if cs["card"] == card),
                  key=lambda cs: cs["position"])


def _card_of(work: dict, sref: str) -> str:
    [card] = [cs["card"] for cs in work["card_sentences"] if cs["sentence"] == sref]
    return card


def planned_steps(work: dict) -> list[dict]:
    pending = work["curation"]["pending"]
    return sorted(pending, key=lambda p: STEP_ORDER.index(p["kind"]))


def check_preconditions(work: dict, curation: dict, inventory, cfg: dict) -> dict:
    """Everything that can fail without the cloud. Returns card infos by ref."""
    from sprachpipe.annotate import tokenize
    from sprachpipe.llm import LlmError, model_price

    ops = curation["sentence_operations"]
    expected = Counter({"translation_check": sum(o["op"] == "replace_translation" for o in ops),
                        "sentence_qa": sum(o["op"] == "replace_text" for o in ops),
                        "annotate_card": len({o["card"] for o in ops if o["op"] == "replace_text"}),
                        "dictionary_forms": 1})
    found = Counter(p["kind"] for p in work["curation"]["pending"])
    if found != expected:
        raise PreconditionError(f"pending steps {dict(found)} != expected {dict(expected)}")
    cards = {}
    for o in ops:
        if o["op"] in ("replace_text", "replace_translation"):
            cards[o["card"]] = card_info(work, inventory, o["card"])
    for p in work["curation"]["pending"]:
        if p["kind"] == "annotate_card" and len(p["sentences"]) != 3:
            raise PreconditionError(f"{p['card']!r}: annotation needs three sentences")
    c = cfg["llm"]
    for model_key, _ in CALLS.values():
        try:
            model_price(cfg["prices"], c[model_key])
        except LlmError as e:
            raise PreconditionError(str(e)) from None
    tokenize("Local spaCy check.")
    return cards


def cost_upper_bound(cfg: dict, work: dict) -> dict:
    """Reservation upper bound per planned call (llm.Llm formula with a
    generous prompt length); actual costs are lower and land in the ledger."""
    from sprachpipe.llm import cost_usd, model_price

    c = cfg["llm"]
    calls = Counter()
    for p in work["curation"]["pending"]:
        if p["kind"] == "translation_check":
            calls["meaning_check"] += 1
        elif p["kind"] == "sentence_qa":
            calls.update(blindtest=1, meaning_check=1, alternative_check=1)
            if p.get("recheck_alternatives"):
                calls["alternative_check"] += 1
        elif p["kind"] == "annotate_card":
            calls["annotate"] += 1
    prompt_chars = {"annotate": 12000}
    out = {}
    for kind, n in sorted(calls.items()):
        model_key, tokens_key = CALLS[kind]
        each = cost_usd(model_price(cfg["prices"], c[model_key]),
                        prompt_chars.get(kind, 8000) // 2 + 1,
                        c["max_output_tokens"][tokens_key], 0)
        out[kind] = {"calls": n, "max_usd_each": round(each, 6), "max_usd": round(n * each, 6)}
    out["total_max_usd"] = round(sum(v["max_usd"] for v in out.values()), 6)
    return out


# --- steps -----------------------------------------------------------------

def _close(work: dict, step: dict, result: dict) -> None:
    work["curation"]["pending"].remove(step)
    work["curation"].setdefault("completed", []).append(dict(step, result=result))


def _keep_open(step: dict, findings: list[str], result: dict) -> None:
    step["findings"] = findings
    step["last_result"] = result


def run_translation_check(llm, cfg, work, step, cards, report) -> None:
    from sprachpipe.meaning_check import check as check_meaning

    s = _sentence(work, step["sentence"])
    card = cards[_card_of(work, s["ref"])]
    checked = {"text": s["text"], "translation_de": s["translation_de"]}
    result = check_meaning(llm, cfg, s["text"], card["display_form"], card["meanings"],
                           s["translation_de"])
    entry = {"checked": checked, "meaning_check_result": result}
    findings = []
    if result["reason"].startswith("Ungültige Prüfantwort:"):
        findings.append(result["reason"])
    elif result["translation_ok"] is not True:
        findings.append(f"Übersetzung abgelehnt: {result['reason']}")
    notes = []   # reported, but the step only checks the translation
    if not findings:
        if result["language_ok"] is not True:
            notes.append("language_ok ist nicht true")
        if result["sense_key"] != card["sense_key"]:
            notes.append(f"sense_key {result['sense_key']!r} != {card['sense_key']!r}")
        if result["observed_pos"] != card["pos"]:
            notes.append(f"observed_pos {result['observed_pos']!r} != {card['pos']!r}")
    entry["notes"] = notes
    report["steps"].append({"kind": "translation_check", "sentence": s["ref"],
                            "status": "open" if findings else "closed",
                            "findings": findings, **entry})
    if findings:
        _keep_open(step, findings, entry)
        return
    s["qa_report"] = {"curation_translation_check": entry, "history": s.get("qa_report")}
    _close(work, step, entry)


def run_sentence_qa(llm, cfg, work, step, cards, report) -> None:
    from sprachpipe.alternative_check import check as check_alternatives
    from sprachpipe.blindtest import ask, judge
    from sprachpipe.generate import qa_sentence
    from sprachpipe.ids import form_norm
    from sprachpipe.linter import lint_sentence
    from sprachpipe.meaning_check import check as check_meaning

    s = _sentence(work, step["sentence"])
    cs = next(cs for cs in work["card_sentences"] if cs["sentence"] == s["ref"])
    card = cards[cs["card"]]
    g, lc = cfg["generate"], cfg["linter"]
    once = dict(cfg, generate=dict(g, lint_retries=0, blind_retries=0))   # no repair loops

    def no_regenerate(feedback):
        raise AssertionError("regeneration is disabled in the curation run")

    attempts = qa_sentence(
        {"text": s["text"], "translation_de": s["translation_de"]}, card, once,
        regenerate=no_regenerate,
        lint=lambda text, gap: lint_sentence(
            text, card["form"], gap[0], gap[1], lc["min_zipf"][card["cefr_band"]],
            lang=g["lang"], names=g["names"], max_words=lc["max_words"],
            max_subclauses=lc["max_subclauses"]),
        blind=lambda text, gap, tr: ask(llm, cfg, text, gap, tr, card["gloss_de"]),
        judge=lambda ans: judge(ans, card["form"], [card["form"]], card["lemma"], None, None),
        meaning_check=lambda text, tr: check_meaning(llm, cfg, text, card["display_form"],
                                                     card["meanings"], tr),
        alternative_check=lambda text, gap, tr, cands: check_alternatives(
            llm, cfg, text, gap, tr, cands))
    if len(attempts) != 1:
        raise AssertionError("qa_sentence must run exactly once")
    a = attempts[0]
    findings = [] if a["qa_status"] == "ok" else list(a["discard_reasons"]) or ["abgelehnt"]
    if a["qa_status"] != "ok" and (a.get("meaning_check_result") or {}).get("reason"):
        findings.append(f"Prüfbegründung: {a['meaning_check_result']['reason']}")
    gap = (cs["gap_start"], cs["gap_end"])
    recheck = []
    if a["qa_status"] == "ok":
        known = {r["norm"] for r in a["alternative_check"]}
        extra = [c for c in step.get("recheck_alternatives", []) if form_norm(c) not in known]
        if extra:
            recheck = check_alternatives(llm, cfg, s["text"], gap, s["translation_de"], extra)
            if any(r["status"] not in ("confirmed", "rejected") for r in recheck):
                findings.append("Ungültige Prüfantwort: erneute Alternativprüfung")
    confirmed = []
    for r in a.get("alternative_check", []) + recheck:
        if r["status"] == "confirmed" and r["norm"] not in confirmed \
                and r["norm"] != form_norm(card["form"]):
            confirmed.append(r["norm"])
    entry = {"checked": {"text": s["text"], "translation_de": s["translation_de"],
                         "gap": list(gap)},
             "lint": a["lint"], "blind": a["blind"], "blind_answer": a["blind_answer"],
             "blind_alternatives": a.get("blind_alternatives", []),
             "alternative_candidates": a.get("alternative_candidates", []),
             "alternative_check": a.get("alternative_check", []),
             "recheck_alternative_check": recheck,
             "meaning_check": a.get("meaning_check"),
             "meaning_check_result": a.get("meaning_check_result"),
             "language_ok": (a.get("meaning_check_result") or {}).get("language_ok"),
             "valid_alternatives": confirmed if not findings else []}
    report["steps"].append({"kind": "sentence_qa", "sentence": s["ref"], "card": cs["card"],
                            "status": "open" if findings else "closed",
                            "findings": findings, **entry})
    if findings:
        _keep_open(step, findings, entry)
        return
    s["qa_status"] = "ok"
    s["qa_report"] = dict(s.get("qa_report") or {}, **entry)
    cs["valid_alternatives"] = confirmed
    _close(work, step, entry)


def _token_rows(work: dict, sref: str, tokens: list[dict], card: dict) -> tuple[list, list]:
    """Pack token rows (rule of pack.assemble_pack) and the form translations
    they carry. Missing lemmas and senses are added to the working state."""
    from sprachpipe.ids import form_norm
    from sprachpipe.pack import _slug

    lemmas = {lm["ref"] for lm in work["lemmas"]}
    senses = {se["ref"] for se in work["senses"]}
    rows, glosses = [], []
    for t in tokens:
        row = {"sentence": sref, "idx": t["idx"], "start_pos": t["start_pos"],
               "end_pos": t["end_pos"], "surface": t["surface"],
               "lemma": None, "sense": None, "card": None}
        if t.get("gloss_de"):
            lref = f"{t['lemma']}/{t['pos']}"
            if lref not in lemmas:
                lemmas.add(lref)
                work["lemmas"].append({"ref": lref, "lemma": t["lemma"], "pos": t["pos"]})
            if t.get("card"):
                sense = card["sense"]
            else:
                sense = f"{lref}|{_slug(t['lemma'])}#{_slug(t['gloss_de'])}"
                if sense not in senses:
                    senses.add(sense)
                    work["senses"].append({"ref": sense, "lemma": lref,
                                           "sense_key": sense.split("|", 1)[1],
                                           "gloss_de": t["gloss_de"]})
            row.update(lemma=lref, sense=sense, card=card["ref"] if t.get("card") else None)
            glosses.append({"form": form_norm(t["surface"]), "sense": sense,
                            "gloss_de": t["gloss_de"], "sentence": sref, "idx": t["idx"],
                            "card": row["card"]})
        rows.append(row)
    return rows, glosses


def _prune(work: dict) -> dict:
    used = {c["sense"] for c in work["cards"]} | {t["sense"] for t in work["sentence_tokens"]
                                                  if t.get("sense")}
    before_s, before_l = len(work["senses"]), len(work["lemmas"])
    work["senses"] = [s for s in work["senses"] if s["ref"] in used]
    used_l = {s["lemma"] for s in work["senses"]} | {t["lemma"] for t in work["sentence_tokens"]
                                                     if t.get("lemma")}
    work["lemmas"] = [lm for lm in work["lemmas"] if lm["ref"] in used_l]
    return {"senses": before_s - len(work["senses"]), "lemmas": before_l - len(work["lemmas"])}


def run_annotation(llm, cfg, work, step, cards, report) -> None:
    from sprachpipe.annotate import annotate_card

    card = cards[step["card"]]
    links = _links(work, step["card"])
    finals = [{"text": _sentence(work, cs["sentence"])["text"],
               "translation_de": _sentence(work, cs["sentence"])["translation_de"],
               "gap": (cs["gap_start"], cs["gap_end"])} for cs in links]
    try:
        annotate_card(llm, cfg, card, finals)
        findings = [f"{cs['sentence']}: {p}" for cs, a in zip(links, finals)
                    for p in a["annotate_problems"]]
    except ValueError as e:   # invalid response shape: a finding, not an abort
        findings = [f"Ungültige Annotationsantwort: {e}"]
    if findings:
        report["steps"].append({"kind": "annotate_card", "card": step["card"], "status": "open",
                                "findings": findings})
        _keep_open(step, findings, {"checked": finals})
        return
    changes, new_glosses = [], []
    for cs, a in zip(links, finals):
        sref = cs["sentence"]
        old = {t["idx"]: t for t in work["sentence_tokens"] if t["sentence"] == sref}
        rows, glosses = _token_rows(work, sref, a["tokens"], card)
        new_glosses += glosses
        diff = [{"idx": r["idx"], "surface": r["surface"],
                 "old": {k: old[r["idx"]].get(k) for k in ("lemma", "sense", "card")}
                 if r["idx"] in old else None,
                 "new": {k: r[k] for k in ("lemma", "sense", "card")}}
                for r in rows
                if r["idx"] not in old
                or any(old[r["idx"]].get(k) != r[k] for k in ("lemma", "sense", "card"))]
        changes.append({"sentence": sref, "text": a["text"],
                        "replaced_sentence": not old, "token_changes": diff})
        work["sentence_tokens"] = [t for t in work["sentence_tokens"] if t["sentence"] != sref] + rows
    sources = work["curation"].setdefault("annotation_glosses", [])
    sources[:] = [g for g in sources if g["sentence"] not in {cs["sentence"] for cs in links}]
    sources += new_glosses
    pruned = _prune(work)
    entry = {"checked": [{"text": f["text"], "translation_de": f["translation_de"]} for f in finals],
             "sentences": changes, "pruned": pruned}
    report["steps"].append({"kind": "annotate_card", "card": step["card"], "status": "closed",
                            "findings": [], **entry})
    _close(work, step, entry)


def run_dictionary(work, step, report) -> None:
    from sprachpipe.curate import derive_dictionary

    if any(p["kind"] == "annotate_card" for p in work["curation"]["pending"]):
        report["steps"].append({"kind": "dictionary_forms", "status": "open",
                                "findings": ["Annotation unvollständig; nicht abgeleitet"]})
        _keep_open(step, ["Annotation unvollständig"], {})
        return
    d = derive_dictionary(work)
    summary = {"token_keys": d["token_keys"], "resolved": len(d["entries"]),
               "missing": d["missing"], "conflicts": d["conflicts"]}
    findings = ([f"{len(d['missing'])} Schlüssel ohne Formübersetzung"] if d["missing"] else []) \
        + ([f"{len(d['conflicts'])} Schlüssel mit mehreren Formübersetzungen"] if d["conflicts"] else [])
    report["steps"].append({"kind": "dictionary_forms", "status": "open" if findings else "closed",
                            "findings": findings, **summary})
    report["dictionary_draft"] = d["entries"]
    if findings:
        _keep_open(step, findings, summary)
        step["conflicting_keys"] = [{"form": c["form"], "sense": c["sense"]} for c in d["conflicts"]]
        step["missing_keys"] = d["missing"]
        return
    work["dictionary_forms"] = [{k: e[k] for k in ("form", "sense", "card", "gloss_de", "rank")}
                                for e in d["entries"]]
    _close(work, step, {"entries": len(d["entries"]), "origins": [
        {"form": e["form"], "sense": e["sense"], "origin": e["origin"]} for e in d["entries"]]})


def run(llm, cfg: dict, work: dict, cards: dict, save) -> tuple[dict, str | None]:
    """All pending steps once, in STEP_ORDER; save(work, report) after each.
    Returns (report, abort reason or None). Auth, budget and transport errors
    end the run; the interrupted step stays pending."""
    from sprachpipe.llm import AuthError, BudgetExceeded, LlmError

    report = {"version": work["curation"]["version"], "steps": [], "aborted": None,
              "editorial_note": "technisch abgeschlossene Schritte sind keine redaktionelle "
                                "Freigabe; offene Inhaltsentscheidungen (Plan Abschnitt 4) bleiben"}
    runners = {"translation_check": run_translation_check, "sentence_qa": run_sentence_qa,
               "annotate_card": run_annotation}
    try:
        for step in planned_steps(work):
            if step["kind"] == "annotate_card":
                open_qa = [p["sentence"] for p in work["curation"]["pending"]
                           if p["kind"] == "sentence_qa" and p["sentence"] in step["sentences"]]
                if open_qa:
                    step["findings"] = [f"Satz-QA offen: {open_qa}"]
                    report["steps"].append({"kind": "annotate_card", "card": step["card"],
                                            "status": "skipped", "findings": step["findings"]})
                    save(work, report)
                    continue
            if step["kind"] == "dictionary_forms":
                run_dictionary(work, step, report)
            else:
                runners[step["kind"]](llm, cfg, work, step, cards, report)
            save(work, report)
    except (AuthError, BudgetExceeded, LlmError) as e:
        report["aborted"] = f"{type(e).__name__}: {e}"
    report["pending"] = [{k: p.get(k) for k in ("kind", "card", "sentence", "findings")}
                         for p in work["curation"]["pending"]]
    save(work, report)
    return report, report["aborted"]


# --- CLI -------------------------------------------------------------------

def load_inputs(pack_args: list[str], curation_path: str | Path, inventory=None, cfg=None):
    from sprachpipe.curate import CurationError, card_meta_from_inventory, curate
    from sprachpipe.inventory import MeaningInventory
    from sprachpipe.pack import load_pack

    cfg = cfg or load_config()
    curation = json.loads(Path(curation_path).read_text(encoding="utf-8"))
    paths = {}
    for item in pack_args:
        name, sep, path = item.partition("=")
        if not sep or not name or not path:
            raise PreconditionError(f"--pack expects NAME=PATH, got {item!r}")
        paths[name] = Path(path)
    if set(paths) != set(curation["sources"]):
        raise PreconditionError(f"--pack names {sorted(paths)} != curation sources "
                                f"{sorted(curation['sources'])}")
    missing = [str(p) for p in paths.values() if not p.is_file()]
    if missing:
        raise PreconditionError(f"pack files not found: {missing}")
    packs = {name: load_pack(p) for name, p in paths.items()}
    inventory = inventory or MeaningInventory(cfg["generate"]["lang"])   # read only
    try:
        work, log = curate(packs, curation, card_meta_from_inventory(packs, inventory))
    except CurationError as e:
        raise PreconditionError(f"curation: {e}") from None
    cards = check_preconditions(work, curation, inventory, cfg)
    return cfg, curation, work, log, cards, paths


def print_plan(work: dict, cards: dict, estimate: dict, max_usd: float) -> None:
    print(f"curation {work['curation']['version']}: {len(work['cards'])} cards, "
          f"{len(work['card_sentences'])} card sentences")
    for i, p in enumerate(planned_steps(work), start=1):
        if p["kind"] == "translation_check":
            s = _sentence(work, p["sentence"])
            print(f"{i:2}. translation_check {p['sentence']} [{_card_of(work, p['sentence'])}]"
                  f"\n      {s['text']} | {s['translation_de']}")
        elif p["kind"] == "sentence_qa":
            s = _sentence(work, p["sentence"])
            extra = f" recheck={p['recheck_alternatives']}" if p.get("recheck_alternatives") else ""
            print(f"{i:2}. sentence_qa {p['sentence']} [{_card_of(work, p['sentence'])}]"
                  f" checks={'+'.join(p['checks'])}{extra}\n      {s['text']} | {s['translation_de']}")
        elif p["kind"] == "annotate_card":
            print(f"{i:2}. annotate_card {p['card']} (3 sentences: {', '.join(p['sentences'])})")
        else:
            print(f"{i:2}. dictionary_forms (local, after annotation; "
                  f"{len(p['conflicting_keys'])} known conflicting source keys stay open)")
    print("affected cards: " + ", ".join(sorted(cards)))
    for kind, v in estimate.items():
        if kind != "total_max_usd":
            print(f"reservation bound {kind}: {v['calls']} x {v['max_usd_each']:.6f} = {v['max_usd']:.6f} USD")
    verdict = "fits" if estimate["total_max_usd"] <= max_usd else "EXCEEDS"
    print(f"reservation bound total {estimate['total_max_usd']:.6f} USD {verdict} --max-usd {max_usd:.2f}")


def main(argv: list[str] | None = None, *, inventory=None, cfg=None, llm_factory=None) -> int:
    p = argparse.ArgumentParser(
        prog="complete_curation",
        description="Targeted completion of the pending curation steps (QA, annotation, "
                    "dictionary). No regeneration, no DB upload, no release.")
    p.add_argument("--pack", action="append", required=True, metavar="NAME=PATH",
                   help="source pack per curation source (repeat), e.g. pilot_60_v1=out/pilot_60_v1.json")
    p.add_argument("--curation", default=str(CURATION), help="curation list (default: %(default)s)")
    p.add_argument("--out", required=True, help="new output folder (must not exist)")
    p.add_argument("--max-usd", type=float, required=True, help="cost limit for the whole run (> 0)")
    p.add_argument("--dry-run", action="store_true",
                   help="local only: print planned steps, affected cards and cost bound; no cloud, no files")
    try:
        args = p.parse_args(argv)
    except SystemExit as e:
        return 0 if e.code == 0 else 2
    if not args.max_usd > 0:
        print("error: --max-usd must be > 0", file=sys.stderr)
        return 2
    out = Path(args.out)
    if out.exists():
        print(f"error: {out} already exists; choose a new folder", file=sys.stderr)
        return 2
    try:
        cfg, curation, work, log, cards, paths = load_inputs(args.pack, args.curation, inventory, cfg)
    except PreconditionError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    estimate = cost_upper_bound(cfg, work)
    print_plan(work, cards, estimate, args.max_usd)
    if args.dry_run:
        print("dry run: no cloud calls, no files written")
        return 0

    from sprachpipe.cost import total_usd
    from sprachpipe.llm import Llm

    out.mkdir(parents=True)
    ledger, state_path, report_path = out / "ledger.csv", out / "working_state.json", out / "report.json"
    llm = (llm_factory or Llm)(cfg, ledger, args.max_usd)
    inputs = {"packs": {k: str(v) for k, v in paths.items()}, "curation": str(args.curation),
              "max_usd": args.max_usd, "cost_upper_bound": estimate, "curation_log": log}

    def save(work, report):
        state_path.write_text(json.dumps(work, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        report_path.write_text(json.dumps(dict(report, inputs=inputs, cost_usd=round(total_usd(ledger), 6)),
                                          ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report, aborted = run(llm, cfg, work, cards, save)
    for s in report["steps"]:
        target = s.get("sentence") or s.get("card") or ""
        print(f"{s['status'].upper():7} {s['kind']} {target}" +
              (f" | {'; '.join(s['findings'])}" if s["findings"] else ""))
    print(f"open steps: {len(report['pending'])}")
    print(f"cost_usd {total_usd(ledger):.6f} (limit {args.max_usd:.2f})")
    print(f"state -> {state_path}\nreport -> {report_path}\nledger -> {ledger}")
    if aborted:
        print(f"aborted: {aborted}", file=sys.stderr)
        return 3
    return 1 if report["pending"] else 0


if __name__ == "__main__":
    sys.exit(main())
