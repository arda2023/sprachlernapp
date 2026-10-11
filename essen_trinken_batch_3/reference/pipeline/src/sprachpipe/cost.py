"""Cost ledger (docs/pipeline.md, "Kosten"): one CSV per run, appended."""

from __future__ import annotations

import csv
from datetime import datetime, timezone
from pathlib import Path

FIELDS = ["time", "step", "model", "input_tokens", "output_tokens", "thinking_tokens", "usd"]


class BudgetExceeded(RuntimeError):
    pass


def append_entry(
    ledger: str | Path,
    *,
    step: str,
    model: str,
    input_tokens: int,
    output_tokens: int,
    thinking_tokens: int,
    usd: float,
    time: datetime | None = None,
) -> None:
    ledger = Path(ledger)
    ledger.parent.mkdir(parents=True, exist_ok=True)
    new = not ledger.exists()
    with open(ledger, "a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if new:
            w.writeheader()
        w.writerow({
            "time": (time or datetime.now(timezone.utc)).isoformat(),
            "step": step, "model": model, "input_tokens": input_tokens,
            "output_tokens": output_tokens, "thinking_tokens": thinking_tokens,
            "usd": f"{usd:.6f}",
        })


def total_usd(ledger: str | Path) -> float:
    ledger = Path(ledger)
    if not ledger.exists():
        return 0.0
    with open(ledger, newline="", encoding="utf-8") as f:
        return sum(float(r["usd"]) for r in csv.DictReader(f))


def check_budget(max_usd: float, ledger: str | Path, *, next_usd: float = 0.0) -> float:
    """Raises BudgetExceeded if the run total plus [next_usd] would exceed
    [max_usd]; returns the current total otherwise."""
    total = total_usd(ledger)
    if total + next_usd > max_usd:
        raise BudgetExceeded(
            f"budget {max_usd:.2f} USD exceeded: {total:.4f} spent + {next_usd:.4f} next")
    return total
