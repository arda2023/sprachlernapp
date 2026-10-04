"""Diagnosis: run the fixed QA cases once against the real meaning and
alternative checks (Vertex AI) and compare actual verdicts with expectations.

No generation, no cards, no database. Expectations never reach the model.
--compare-models runs only the meaning cases, once with the configured
meaning_check model and once with the configured generation model (each with its own
thinking setting), sharing one ledger and one budget. --only alternative_check
runs all alternative cases and no meaning cases, with the pipeline's
alternative_check configuration.
Exit codes: 0 all passed, 1 deviations, 2 argument error, 3 technical or
budget abort (partial results are kept in results.json).
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

from sprachpipe.config import PIPELINE_DIR, load_config

CASES = PIPELINE_DIR / "tests" / "fixtures" / "qa_language_cases.json"
MAX_USD = 0.25


def load_cases(path: str | Path = CASES) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def _ledger_rows(llm) -> list[dict]:
    path = getattr(llm, "ledger", None)
    if path is None or not Path(path).exists():
        return []
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def meaning_result(llm, cfg: dict, case: dict, inventory, *, model=None, thinking=None) -> dict:
    """One meaning case. Unparseable or empty model output counts as an invalid
    answer, not as an abort; auth, budget and transport errors propagate."""
    from sprachpipe.llm import AuthError, LlmError
    from sprachpipe.meaning_check import check as check_meaning

    c = cfg["llm"]
    card = case["card"]
    before = len(_ledger_rows(llm))
    diagnostics: dict = {}
    try:
        actual = check_meaning(llm, cfg, case["text"], inventory.display_form(card["form"]),
                               inventory.get(card["form"]), case["translation_de"],
                               model=model, thinking=thinking, diagnostics=diagnostics)
    except AuthError:
        raise
    except LlmError as e:
        if not (isinstance(e.__cause__, json.JSONDecodeError) or str(e).endswith("empty response")):
            raise
        actual = {"sense_key": None, "observed_pos": None, "translation_ok": False,
                  "language_ok": False, "reason": f"Ungültige Prüfantwort: {e}"}
        diagnostics = {"response": None, "violations": [
            {"field": None, "problem": "keine parsebare JSON-Antwort", "type": "str", "value": str(e)}]}
    invalid = actual["reason"].startswith("Ungültige Prüfantwort:")
    expected = case["expected"]["language_ok"]
    return {
        "kind": "meaning_check", "id": case["id"], "finding": case["finding"],
        "input": {"text": case["text"], "translation_de": case["translation_de"], "card": card},
        "model": model or c["meaning_check_model"],
        "thinking": c["meaning_check_thinking"] if thinking is None else thinking,
        "max_output_tokens": c["max_output_tokens"]["meaning_check"],
        "actual": actual, "expected": case["expected"], "reason": actual["reason"],
        "valid_response": not invalid,
        # an invalid answer is never a correctly detected language error
        "false_accept": not invalid and actual["language_ok"] is True and expected is False,
        "false_reject": not invalid and actual["language_ok"] is False and expected is True,
        "response": diagnostics.get("response"), "violations": diagnostics.get("violations", []),
        "usage": [{k: r[k] for k in ("model", "input_tokens", "output_tokens", "thinking_tokens", "usd")}
                  for r in _ledger_rows(llm)[before:]],
        "passed": not invalid and actual["language_ok"] is expected}


def run_cases(llm, cfg: dict, cases: dict, inventory, save,
              only: str | None = None) -> tuple[list[dict], str | None]:
    """One pass over all cases (only='alternative_check': alternative cases
    only); save(results) after each case. Returns (results, abort reason or None)."""
    from sprachpipe.alternative_check import check as check_alternatives
    from sprachpipe.llm import AuthError, BudgetExceeded, LlmError

    c = cfg["llm"]
    results: list[dict] = []
    try:
        for case in cases["meaning_cases"] if only is None else []:
            results.append(meaning_result(llm, cfg, case, inventory))
            save(results)
        for case in cases["alternative_cases"]:
            before = len(_ledger_rows(llm))
            actual = check_alternatives(llm, cfg, case["text"], tuple(case["gap"]),
                                        case["translation_de"], case["candidates"])
            usage = [{k: r[k] for k in ("model", "input_tokens", "output_tokens", "thinking_tokens", "usd")}
                     for r in _ledger_rows(llm)[before:]]
            for r in actual:
                expected = case["expected"][r["candidate"]]
                results.append({
                    "kind": "alternative_check", "id": f"{case['id']}:{r['candidate']}",
                    "finding": case["finding"],
                    "input": {"text": case["text"], "translation_de": case["translation_de"],
                              "card": case["card"], "candidate": r["candidate"],
                              "sentence": r["sentence"]},
                    "model": c["alternative_check_model"], "thinking": c["alternative_check_thinking"],
                    "max_output_tokens": c["max_output_tokens"]["alternative_check"],
                    "actual": {"status": r["status"]}, "expected": {"valid": expected},
                    "reason": r["reason"],
                    # one shared call per case: its ledger rows sit on the first candidate only
                    "usage": usage if r["candidate_index"] == 1 else [],
                    "passed": r["status"] == ("confirmed" if expected else "rejected")})
            save(results)
    except (AuthError, BudgetExceeded, LlmError) as e:
        return results, f"{type(e).__name__}: {e}"
    return results, None


def compare_models(llm, cfg: dict, cases: dict, inventory, save) -> tuple[list[dict], str | None]:
    """Meaning cases only: meaning_check model, then generation model, each with its
    configured thinking; one shared llm (ledger and budget). save(models)
    after each case."""
    from sprachpipe.llm import AuthError, BudgetExceeded, LlmError

    c = cfg["llm"]
    models = [{"label": "pruefmodell", "model": c["meaning_check_model"],
               "thinking": c["meaning_check_thinking"]},
              {"label": "generierungsmodell", "model": c["generate_model"],
               "thinking": c["generate_thinking"]}]
    for m in models:
        m.update(max_output_tokens=c["max_output_tokens"]["meaning_check"], results=[])
    try:
        for m in models:
            for case in cases["meaning_cases"]:
                m["results"].append(meaning_result(llm, cfg, case, inventory,
                                                   model=m["model"], thinking=m["thinking"]))
                save(models)
    except (AuthError, BudgetExceeded, LlmError) as e:
        return models, f"{type(e).__name__}: {e}"
    return models, None


def summary(results: list[dict]) -> dict:
    return {"cases": len(results), "passed": sum(r["passed"] for r in results),
            "valid_responses": sum(r["valid_response"] for r in results),
            "invalid_responses": sum(not r["valid_response"] for r in results),
            "false_accept": sum(r["false_accept"] for r in results),
            "false_reject": sum(r["false_reject"] for r in results),
            "calls": sum(len(r["usage"]) for r in results),
            "cost_usd": round(sum(float(u["usd"]) for r in results for u in r["usage"]), 6)}


def _print_violations(r: dict) -> None:
    for v in r.get("violations", []):
        print(f"    violation {v['field']}: {v['problem']} ({v['type']}: {v['value']!r})")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="check_qa_cases",
                                description="Fixed live QA cases (meaning_check, alternative_check)")
    p.add_argument("--out", required=True, help="new output folder (must not exist)")
    p.add_argument("--max-usd", type=float, default=MAX_USD,
                   help=f"cost limit for the whole run, 0 < x <= {MAX_USD:.2f}")
    p.add_argument("--compare-models", action="store_true",
                   help="meaning cases only: configured meaning_check model vs. configured generation "
                        "model (own thinking settings; same prompt, schema, token limit and budget)")
    p.add_argument("--only", choices=["alternative_check"],
                   help="run only all alternative cases (no meaning_check calls)")
    try:
        args = p.parse_args(argv)
    except SystemExit as e:
        return 0 if e.code == 0 else 2
    if args.only and args.compare_models:
        print("error: --only and --compare-models cannot be combined", file=sys.stderr)
        return 2
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

    llm = Llm(cfg, ledger, args.max_usd)

    if args.compare_models:
        def save_models(models, aborted=None):
            results_path.write_text(json.dumps(
                {"cases": str(CASES.name), "mode": "compare-models", "max_usd": args.max_usd,
                 "aborted": aborted,
                 "models": [dict({k: v for k, v in m.items() if k != "results"},
                                 summary=summary(m["results"]), results=m["results"])
                            for m in models]},
                ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        models, aborted = compare_models(llm, cfg, cases, inventory, save_models)
        save_models(models, aborted)
        for m in models:
            for r in m["results"]:
                print(f"{'PASS' if r['passed'] else 'FAIL'} {m['label']} {r['id']}: "
                      f"language_ok={r['actual']['language_ok']} valid={r['valid_response']} "
                      f"expected={r['expected']['language_ok']} | {r['reason']}")
                _print_violations(r)
        for m in models:
            print(f"{m['label']} {m['model']} thinking={json.dumps(m['thinking'])} "
                  f"max_output_tokens={m['max_output_tokens']} {json.dumps(summary(m['results']))}")
        ok = all(len(m["results"]) == len(cases["meaning_cases"])
                 and all(r["passed"] for r in m["results"]) for m in models)
    else:
        def save(results, aborted=None):
            results_path.write_text(json.dumps(
                {"cases": str(CASES.name), "only": args.only, "max_usd": args.max_usd,
                 "aborted": aborted, "passed": sum(r["passed"] for r in results),
                 "total": len(results), "results": results},
                ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        results, aborted = run_cases(llm, cfg, cases, inventory, save, only=args.only)
        save(results, aborted)
        for r in results:
            actual = r["actual"].get("status", r["actual"].get("language_ok"))
            print(f"{'PASS' if r['passed'] else 'FAIL'} {r['kind']} {r['id']}: model={r['model']} "
                  f"actual={actual} expected={json.dumps(r['expected'])} | {r['reason']}")
            _print_violations(r)
        print(f"passed {sum(r['passed'] for r in results)}/{len(results)}")
        ok = all(r["passed"] for r in results)
    print(f"cost_usd {total_usd(ledger):.6f} (limit {args.max_usd:.2f} for the whole run)")
    print(f"results -> {results_path}")
    print(f"ledger -> {ledger}")
    if aborted:
        print(f"aborted: {aborted}", file=sys.stderr)
        return 3
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
