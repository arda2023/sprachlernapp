"""Command line: python -m sprachpipe.cli <command> (or `sprachpipe`)."""

from __future__ import annotations

import argparse
import json
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from .config import PIPELINE_DIR, load_config, load_env


def _print_counts(title: str, counts: dict[str, int]) -> None:
    print(title)
    for table, n in counts.items():
        print(f"  {table:<18} {n}")


def cmd_check_db(args, cfg) -> int:
    from .db import check_db, connect

    load_env()
    conn = connect(read_only=True)
    try:
        _print_counts("select 1 ok; rows per content table:", check_db(conn))
    finally:
        conn.close()
    return 0


def cmd_lemmas(args, cfg) -> int:
    from .lemmas import select_lemmas, spacy_analyzer, wordfreq_words

    c = cfg["lemmas"]
    result = select_lemmas(
        wordfreq_words(c["lang"], c["top_n"]),
        spacy_analyzer(c["spacy_model"]),
        c["pos_allowed"],
        c["max_rank"],
    )
    out = Path(args.out or PIPELINE_DIR / cfg["out_dir"] / f"lemmas_{c['lang']}.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"{len(result)} lemmas -> {out}")
    return 0


def cmd_lint(args, cfg) -> int:
    from .linter import lint_sentence
    from .pack import load_pack, sentence_lint_items

    c = cfg["linter"]
    errors = 0
    for item in sentence_lint_items(load_pack(args.file)):
        findings = lint_sentence(
            item["sentence"], item["form"], item["gap_start"], item["gap_end"],
            c["min_zipf"][item["cefr_band"]], lang=cfg["generate"]["lang"],
            names=cfg["generate"]["names"],
            max_words=c["max_words"], max_subclauses=c["max_subclauses"],
        )
        status = "ok" if not findings else ", ".join(f"{f.level}:{f.rule}" for f in findings)
        print(f"[{status}] {item['sentence']}")
        for f in findings:
            print(f"    {f.level} {f.rule}: {f.message}")
        errors += sum(f.level == "error" for f in findings)
    print(f"{errors} error(s)")
    return 1 if errors else 0


def cmd_upsert(args, cfg) -> int:
    from .db import connect, table_counts, upsert_pack
    from .pack import load_pack

    pack = load_pack(args.pack)
    if not args.publish:
        _print_counts("dry run (nothing written); rows per table:", upsert_pack(None, pack))
        print("use --publish to write")
        return 0
    load_env()
    conn = connect()
    try:
        _print_counts("written; rows in pack:", upsert_pack(conn, pack, publish=True))
        _print_counts("rows in database:", table_counts(conn))
        conn.rollback()
    finally:
        conn.close()
    return 0


def cmd_export(args, cfg) -> int:
    from .export import export_sqlite
    from .pack import load_pack

    _print_counts(f"exported -> {args.target}", export_sqlite(load_pack(args.pack), args.target))
    return 0


SMOKE_MAX_USD = 1.0


def _process_card(llm, cfg, card, found, avoid_words):
    from .annotate import annotate_card
    from .blindtest import ask, judge
    from .generate import qa_sentence, sentences, slot_context
    from .linter import lint_sentence
    from .meaning_check import check as check_meaning
    from .quality import duplicate

    g, lc = cfg["generate"], cfg["linter"]
    def evaluate(first, make):
        slot = qa_sentence(
            first, card, cfg, regenerate=make,
            lint=lambda text, gap: lint_sentence(
                text, card["form"], gap[0], gap[1], lc["min_zipf"][card["cefr_band"]],
                lang=g["lang"], names=g["names"], max_words=lc["max_words"],
                max_subclauses=lc["max_subclauses"]),
            blind=lambda text, gap, tr: ask(llm, cfg, text, gap, tr, card["gloss_de"]),
            judge=lambda ans: judge(ans, card["form"], [card["form"]], card["lemma"], None, None),
            meaning_check=lambda text, translation: check_meaning(
                llm, cfg, text, card["display_form"], found, translation),
            duplicate=lambda text, gap: duplicate(text, gap, card["accepted"]))
        card["slots"].append(slot)
        final = slot[-1]
        if final["qa_status"] == "ok" and len(card["accepted"]) < 3:
            card["accepted"].append(final)

    for start, count in ((0, 5), (5, 3), (8, 3)):
        if start and len(card["accepted"]) >= 3:
            break
        contexts = [slot_context(cfg, card, start + i) for i in range(count)]
        batch = sentences(llm, cfg, card, count=count, contexts=contexts,
                          avoid_words=avoid_words)
        for i, first in enumerate(batch):
            if len(card["accepted"]) >= 3:
                card["slots"].append([{
                    "text": first["text"], "translation_de": first["translation_de"],
                    "gap": None, "lint": [], "lint_rules": [], "blind": None,
                    "blind_answer": None, "meaning_check": None,
                    "discard_reason": "", "discard_reasons": [], "qa_status": "unused"}])
                continue
            context = contexts[i]
            def regenerate(feedback, context=context):
                others = [b["text"] for b in batch]
                others += [a["text"] for slot in card["slots"] for a in slot]
                extra = " Do not reuse: " + " / ".join(others)
                return sentences(llm, cfg, card, count=1,
                                 feedback=feedback + extra,
                                 contexts=[context], avoid_words=avoid_words)[0]
            evaluate(first, regenerate)
    if len(card["accepted"]) == 3:
        annotate_card(llm, cfg, card, card["accepted"])
    return card


def run_generate(llm, cfg, forms, out_path, out_dir, *, max_usd, label,
                 inventory_path=None, refresh_meanings=None) -> str | None:
    """Steps 3-7 for [forms] ((form, rank) pairs); writes the pack,
    review.csv and run_report.md. Returns the abort reason or None."""
    from .generate import load_prompt, meanings
    from .inventory import MeaningInventory
    from .llm import BudgetExceeded, LlmError
    from .pack import assemble_pack, build_rows
    from .quality import common_lemmas
    from .review import write_review_csv, write_run_report
    from .ids import stable_id

    g, c, lc = cfg["generate"], cfg["llm"], cfg["linter"]
    inventory = MeaningInventory(g["lang"], inventory_path)
    out_dir = Path(out_dir)
    cards, skipped, aborted = [], [], None
    llm.set_progress(out_dir / "progress.txt", len(forms))
    try:
        work = []
        remaining = {}
        for form, rank in forms:
            found = meanings(llm, cfg, form, rank, inventory,
                             refresh=form == refresh_meanings)
            if not found:
                skipped.append(f"{form}: keine Bedeutung (Fragment, Eigenname oder Zahl)")
                llm.form_done()
                continue
            active = [(idx, m) for idx, m in enumerate(found, start=1)
                      if m.get("status", "active") == "active"]
            remaining[form] = len(active)
            if not active:
                skipped.append(f"{form}: alle Bedeutungen ausgeschlossen")
                llm.form_done()
            for idx, m in active:
                card = {"form": form, "display_form": inventory.display_form(form),
                        "rank": rank, "sense_index": idx, **m, "slots": [], "accepted": []}
                cards.append(card)
                work.append((card, found))
        concurrency = max(1, int(g.get("concurrency", 8)))
        with ThreadPoolExecutor(max_workers=concurrency) as pool:
            for start in range(0, len(work), concurrency):
                wave = work[start:start + concurrency]
                avoid_words = common_lemmas(cards[:start])
                futures = {pool.submit(_process_card, llm, cfg, card, found, avoid_words): card
                           for card, found in wave}
                for future in as_completed(futures):
                    card = futures[future]
                    try:
                        future.result()
                    except Exception:
                        for other in futures:
                            other.cancel()
                        raise
                    remaining[card["form"]] -= 1
                    if remaining[card["form"]] == 0:
                        llm.form_done()
    except (BudgetExceeded, LlmError) as e:
        aborted = f"{type(e).__name__}: {e}"
    finally:
        llm.finish_progress()
        def card_id(card):
            lemma_id = stable_id("lemmas", lang=g["lang"], lemma=card["lemma"], pos=card["pos"])
            sense_id = stable_id("senses", lemma_id=lemma_id, sense_key=card["sense_key"])
            return stable_id("cards", lang=g["lang"], form=card["form"], sense_id=sense_id)
        cards.sort(key=card_id)
        pack = assemble_pack(g["lang"], cards, model=c["generate_model"], version="0.0.0-generate")
        build_rows(pack)  # validates refs and columns
        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(pack, ensure_ascii=False, indent=1), encoding="utf-8")
        write_review_csv(cards, out_dir / "review.csv")
        write_run_report(
            out_dir / "run_report.md", cards=cards, skipped=skipped, ledger=llm.ledger,
            packed_cards=len(pack["cards"]), aborted=aborted,
            info={"forms": label, "n_forms": len(forms), "max_usd": max_usd,
                  "generate_model": c["generate_model"], "generate_thinking": c["generate_thinking"],
                  "blindtest_model": c["blindtest_model"],
                  "blindtest_thinking": c["blindtest_thinking"],
                  "prompt_versions": [load_prompt(n)[0] for n in
                                      ("meanings", "sentences", "annotate", "blindtest", "meaning_check")]})
    return aborted


def cmd_generate(args, cfg) -> int:
    from datetime import datetime

    from .generate import candidate_forms
    from .llm import Llm

    if args.max_usd <= 0:
        print("error: --max-usd must be > 0", file=sys.stderr)
        return 2
    if args.forms == "smoke" and args.max_usd > SMOKE_MAX_USD:
        print(f"error: smoke test is capped at {SMOKE_MAX_USD:.2f} USD", file=sys.stderr)
        return 2
    forms = candidate_forms(args.forms, cfg)
    if args.refresh_meanings and args.refresh_meanings not in {form for form, _ in forms}:
        print("error: --refresh-meanings must be among --forms", file=sys.stderr)
        return 2
    out_dir = PIPELINE_DIR / cfg["out_dir"]
    out_dir.mkdir(parents=True, exist_ok=True)
    ledger = out_dir / "ledger.csv"
    if ledger.exists():  # one ledger per run; keep the previous one
        ledger.rename(out_dir / f"ledger-{datetime.now():%Y%m%d-%H%M%S}.csv")
    aborted = run_generate(Llm(cfg, ledger, args.max_usd), cfg, forms, args.out, out_dir,
                           max_usd=args.max_usd, label=args.forms,
                           refresh_meanings=args.refresh_meanings)
    print(f"pack -> {args.out}")
    print(f"review -> {out_dir / 'review.csv'}")
    print(f"report -> {out_dir / 'run_report.md'}")
    print(f"ledger -> {ledger}")
    if aborted:
        print(f"aborted: {aborted}", file=sys.stderr)
        return 3
    return 0


def cmd_classify_usage(args, cfg) -> int:
    from .classify import classify_form
    from .cost import total_usd
    from .inventory import MeaningInventory
    from .llm import AuthError, BudgetExceeded, Llm, LlmError

    if args.max_usd <= 0 or args.max_usd > 0.50:
        print("error: classify-usage requires 0 < --max-usd <= 0.50", file=sys.stderr)
        return 2
    out_dir = PIPELINE_DIR / cfg["out_dir"]
    ledger = out_dir / "classify_ledger.csv"
    if ledger.exists():
        print("error: classify ledger exists; one-time run already started", file=sys.stderr)
        return 2
    inventory = MeaningInventory(cfg["generate"]["lang"])
    inventory.save()
    llm = Llm(cfg, ledger, args.max_usd)
    llm.set_progress(out_dir / "classify_progress.txt", len(inventory.forms))
    try:
        for form in inventory.forms:
            found = inventory.get(form)
            usages = classify_form(llm, cfg, form, found, inventory.display_form(form))
            inventory.classify(form, usages)
            llm.form_done()
    except (AuthError, BudgetExceeded, LlmError, ValueError) as e:
        print(f"aborted: {type(e).__name__}: {e}", file=sys.stderr)
        return 3
    finally:
        llm.finish_progress()
    print("form | sense_key | usage | status")
    for form in inventory.forms:
        for meaning in inventory.get(form):
            if meaning["usage"] != "haupt" or meaning["status"] == "excluded":
                print(f"{form} | {meaning['sense_key']} | {meaning['usage']} | {meaning['status']}")
    print(f"cost_usd {total_usd(ledger):.6f}")
    print(f"ledger {ledger}")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="sprachpipe")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("check-db", help="read-only: select 1 and row counts")
    lp = sub.add_parser("lemmas", help="lemma selection from wordfreq + spaCy")
    lp.add_argument("--out")
    li = sub.add_parser("lint", help="lint the card sentences of a pack")
    li.add_argument("file")
    up = sub.add_parser("upsert", help="write a pack into schema content (dry run by default)")
    up.add_argument("pack")
    up.add_argument("--publish", action="store_true")
    ex = sub.add_parser("export", help="export a pack to content.sqlite")
    ex.add_argument("pack")
    ex.add_argument("target")
    ge = sub.add_parser("generate", help="AI generation of cards and sentences (Vertex AI)")
    ge.add_argument("--forms", required=True, help="'smoke', a number n or 'a,b,c'")
    ge.add_argument("--out", required=True, help="pack JSON to write")
    ge.add_argument("--max-usd", type=float, default=1.0, help="cost limit for this run")
    ge.add_argument("--refresh-meanings", metavar="FORM",
                    help="regenerate meanings for this form and append new sense keys")
    cu = sub.add_parser("classify-usage", help="classify existing inventory meanings once")
    cu.add_argument("--max-usd", type=float, default=0.50)
    args = p.parse_args(argv)

    from .db import DbError

    handlers = {"check-db": cmd_check_db, "lemmas": cmd_lemmas, "lint": cmd_lint,
                "upsert": cmd_upsert, "export": cmd_export, "generate": cmd_generate,
                "classify-usage": cmd_classify_usage}
    try:
        return handlers[args.command](args, load_config())
    except DbError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
