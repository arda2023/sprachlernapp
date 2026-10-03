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
    print(f"{len(result)} lemmas → {out}")
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

    _print_counts(f"exported → {args.target}", export_sqlite(load_pack(args.pack), args.target))
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
    args = p.parse_args(argv)

    from .db import DbError

    handlers = {"check-db": cmd_check_db, "lemmas": cmd_lemmas, "lint": cmd_lint,
                "upsert": cmd_upsert, "export": cmd_export}
    try:
        return handlers[args.command](args, load_config())
    except DbError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
