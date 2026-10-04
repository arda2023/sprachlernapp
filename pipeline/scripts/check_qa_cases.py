"""Diagnosis: run the fixed QA cases once against the real meaning and
alternative checks (Vertex AI) and compare actual verdicts with expectations.

No generation, no cards, no database. Expectations never reach the model.
Exit codes: 0 all passed, 1 deviations, 2 argument error, 3 technical or
budget abort (partial results are kept in results.json).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from sprachpipe.config import PIPELINE_DIR, load_config

CASES = PIPELINE_DIR / "tests" / "fixtures" / "qa_language_cases.json"
MAX_USD = 0.25


def load_cases(path: str | Path = CASES) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def run_cases(llm, cfg: dict, cases: dict, inventory, save) -> tuple[list[dict], str | None]:
    """One pass over all cases; save(results) after each case. Returns
    (results, abort reason or None)."""
    from sprachpipe.alternative_check import check as check_alternatives
    from sprachpipe.llm import AuthError, BudgetExceeded, LlmError
    from sprachpipe.meaning_check import check as check_meaning

    results: list[dict] = []
    try:
        for case in cases["meaning_cases"]:
            card = case["card"]
            actual = check_meaning(llm, cfg, case["text"], inventory.display_form(card["form"]),
                                   inventory.get(card["form"]), case["translation_de"])
            invalid = actual["reason"].startswith("Ungültige Prüfantwort:")
            results.append({
                "kind": "meaning_check", "id": case["id"], "finding": case["finding"],
                "input": {"text": case["text"], "translation_de": case["translation_de"],
                          "card": card},
                "actual": actual, "expected": case["expected"],
                "reason": actual["reason"],
                "passed": not invalid and actual["language_ok"] is case["expected"]["language_ok"]})
            save(results)
        for case in cases["alternative_cases"]:
            actual = check_alternatives(llm, cfg, case["text"], tuple(case["gap"]),
                                        case["translation_de"], case["candidates"])
            for r in actual:
                expected = case["expected"][r["candidate"]]
                results.append({
                    "kind": "alternative_check", "id": f"{case['id']}:{r['candidate']}",
                    "finding": case["finding"],
                    "input": {"text": case["text"], "translation_de": case["translation_de"],
                              "card": case["card"], "candidate": r["candidate"],
                              "sentence": r["sentence"]},
                    "actual": {"status": r["status"]}, "expected": {"valid": expected},
                    "reason": r["reason"],
                    "passed": r["status"] == ("confirmed" if expected else "rejected")})
            save(results)
    except (AuthError, BudgetExceeded, LlmError) as e:
        return results, f"{type(e).__name__}: {e}"
    return results, None


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="check_qa_cases",
                                description="Fixed live QA cases (meaning_check, alternative_check)")
    p.add_argument("--out", required=True, help="new output folder (must not exist)")
    p.add_argument("--max-usd", type=float, default=MAX_USD,
                   help=f"cost limit, 0 < x <= {MAX_USD:.2f}")
    try:
        args = p.parse_args(argv)
    except SystemExit as e:
        return 0 if e.code == 0 else 2
    if not 0 < args.max_usd <= MAX_USD:
        print(f"error: --max-usd must be > 0 and <= {MAX_USD:.2f}", file=sys.stderr)
        return 2
    out = Path(args.out)
    if out.exists():
        print(f"error: {out} already exists; choose a new folder", file=sys.stderr)
        return 2

    from sprachpipe.inventory import MeaningInventory
    from sprachpipe.llm import Llm
    from sprachpipe.cost import total_usd

    cfg = load_config()
    cases = load_cases()
    inventory = MeaningInventory(cfg["generate"]["lang"])   # read only, never saved
    missing = [c["card"]["form"] for c in cases["meaning_cases"] if not inventory.get(c["card"]["form"])]
    if missing:
        print(f"error: no inventory entry for {sorted(set(missing))}", file=sys.stderr)
        return 2
    out.mkdir(parents=True)
    ledger = out / "ledger.csv"
    results_path = out / "results.json"

    def save(results, aborted=None):
        results_path.write_text(json.dumps(
            {"cases": str(CASES.name), "max_usd": args.max_usd, "aborted": aborted,
             "passed": sum(r["passed"] for r in results), "total": len(results),
             "results": results}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    results, aborted = run_cases(Llm(cfg, ledger, args.max_usd), cfg, cases, inventory, save)
    save(results, aborted)
    for r in results:
        actual = r["actual"].get("status", r["actual"].get("language_ok"))
        print(f"{'PASS' if r['passed'] else 'FAIL'} {r['kind']} {r['id']}: actual={actual} "
              f"expected={json.dumps(r['expected'])} | {r['reason']}")
    print(f"passed {sum(r['passed'] for r in results)}/{len(results)}")
    print(f"cost_usd {total_usd(ledger):.6f}")
    print(f"results -> {results_path}")
    print(f"ledger -> {ledger}")
    if aborted:
        print(f"aborted: {aborted}", file=sys.stderr)
        return 3
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
