"""Command line: python -m sprachpipe.cli <command> (or `sprachpipe`)."""

from __future__ import annotations

import argparse
import json
import sys
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
    ranks = None
    if args.lemmas:
        ranks = {e["lemma"]: e["freq_rank"]
                 for e in json.loads(Path(args.lemmas).read_text(encoding="utf-8"))}
    errors = 0
    for item in sentence_lint_items(load_pack(args.file)):
        findings = lint_sentence(
            item["sentence"], item["form"], item["gap_start"], item["gap_end"],
            c["allowed_rank"], ranks=ranks,
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


def run_generate(llm, cfg, forms, out_path, out_dir, *, max_usd, label,
                 lemma_of=None, is_word=None) -> str | None:
    """Steps 3-7 for [forms] ((form, rank) pairs); writes the pack,
    review.csv and run_report.md. Returns the abort reason or None."""
    from .annotate import annotate
    from .blindtest import ask, judge
    from .generate import load_prompt, meanings, qa_sentence, sentences, slot_context
    from .linter import lint_sentence
    from .llm import BudgetExceeded, LlmError
    from .meaning_check import check as check_meaning
    from .pack import assemble_pack, build_rows
    from .quality import common_lemmas, duplicate, lemma_ranks
    from .review import write_review_csv, write_run_report

    g, c, lc = cfg["generate"], cfg["llm"], cfg["linter"]
    ranks = lemma_ranks(cfg)
    out_dir = Path(out_dir)
    cards, skipped, aborted = [], [], None
    try:
        for form, rank in forms:
            found = meanings(llm, cfg, form, rank)
            if not found:
                skipped.append(f"{form}: keine Bedeutung (Fragment, Eigenname oder Zahl)")
                continue
            for m in found:
                card = {"form": form, "rank": rank, **m, "slots": [], "accepted": []}
                cards.append(card)
                def candidate(slot_index):
                    situation, name = slot_context(cfg, card, slot_index)
                    avoid_words = common_lemmas(cards[:-1])
                    def make(feedback=""):
                        others = [a["text"] for s in card["slots"] for a in s]
                        extra = (" Do not reuse: " + " / ".join(others)) if others else ""
                        return sentences(llm, cfg, card, count=1, feedback=feedback + extra,
                                         situation=situation, name=name,
                                         avoid_words=avoid_words)[0]
                    return make

                # Create five candidates, each with its own deterministic situation.
                makers = [candidate(i) for i in range(5)]
                initial = [make() for make in makers]

                def evaluate(first, make):
                    slot = qa_sentence(
                        first, card, cfg, regenerate=make,
                        lint=lambda text, gap: lint_sentence(
                            text, form, gap[0], gap[1], lc["allowed_rank"][card["cefr_band"]],
                            ranks=ranks, max_words=lc["max_words"],
                            max_subclauses=lc["max_subclauses"]),
                        blind=lambda text, gap, tr: ask(llm, cfg, text, gap, tr, card["gloss_de"]),
                        judge=lambda ans: judge(ans, form, [form], card["lemma"], None, None),
                        meaning_check=lambda text: check_meaning(llm, cfg, text, form, found),
                        duplicate=lambda text, gap: duplicate(text, gap, card["accepted"]))
                    card["slots"].append(slot)
                    final = slot[-1]
                    if final["qa_status"] == "ok" and len(card["accepted"]) < 3:
                        card["accepted"].append(final)

                for first, make in zip(initial, makers):
                    evaluate(first, make)
                if len(card["accepted"]) < 3:
                    for i in range(5, 8):
                        make = candidate(i)
                        evaluate(make(), make)
                for final in card["accepted"]:
                    final["tokens"], final["annotate_problems"] = annotate(
                        llm, cfg, final["text"], final["translation_de"], card, final["gap"])
    except (BudgetExceeded, LlmError) as e:
        aborted = f"{type(e).__name__}: {e}"
    finally:
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
    out_dir = PIPELINE_DIR / cfg["out_dir"]
    out_dir.mkdir(parents=True, exist_ok=True)
    ledger = out_dir / "ledger.csv"
    if ledger.exists():  # one ledger per run; keep the previous one
        ledger.rename(out_dir / f"ledger-{datetime.now():%Y%m%d-%H%M%S}.csv")
    forms = candidate_forms(args.forms, cfg)
    aborted = run_generate(Llm(cfg, ledger, args.max_usd), cfg, forms, args.out, out_dir,
                           max_usd=args.max_usd, label=args.forms)
    print(f"pack -> {args.out}")
    print(f"review -> {out_dir / 'review.csv'}")
    print(f"report -> {out_dir / 'run_report.md'}")
    print(f"ledger -> {ledger}")
    if aborted:
        print(f"aborted: {aborted}", file=sys.stderr)
        return 3
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="sprachpipe")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("check-db", help="read-only: select 1 and row counts")
    lp = sub.add_parser("lemmas", help="lemma selection from wordfreq + spaCy")
    lp.add_argument("--out")
    li = sub.add_parser("lint", help="lint the card sentences of a pack")
    li.add_argument("file")
    li.add_argument("--lemmas", help="lemmas JSON for the i+1 rule")
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
    args = p.parse_args(argv)

    from .db import DbError

    handlers = {"check-db": cmd_check_db, "lemmas": cmd_lemmas, "lint": cmd_lint,
                "upsert": cmd_upsert, "export": cmd_export, "generate": cmd_generate}
    try:
        return handlers[args.command](args, load_config())
    except DbError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
