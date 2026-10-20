"""Cost ledger (docs/pipeline.md, "Kosten"): one CSV per run, appended."""

from __future__ import annotations

import csv
import math
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
    input_tokens: int | None,
    output_tokens: int | None,
    thinking_tokens: int | None,
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
            "usd": f"{math.ceil(usd * 1_000_000_000) / 1_000_000_000:.9f}",
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
    if not math.isfinite(max_usd) or max_usd < 0 or not math.isfinite(next_usd) or next_usd < 0:
        raise BudgetExceeded("invalid budget or reservation")
    total = total_usd(ledger)
    if total + next_usd > max_usd:
        raise BudgetExceeded(
            f"budget {max_usd:.2f} USD exceeded: {total:.4f} spent + {next_usd:.4f} next")
    return total


def append_attempt(ledger: str | Path, *, step: str, model: str, attempt: int,
                   status: str, reserved_usd: float, accounted_usd: float,
                   elapsed_s: float, http_status: int | None, finish_reason: str | None,
                   region: str = "eu") -> None:
    """Safe metadata beside the unchanged historical seven-column ledger.

    For unknown usage, ledger.usd is a local conservative reservation, not a
    measured provider charge. Empty token cells preserve that distinction.
    """
    path = Path(str(ledger) + ".attempts.csv")
    fields = ["step", "model", "region", "attempt", "status", "reserved_usd", "accounted_usd",
              "elapsed_s", "http_status", "finish_reason"]
    if finish_reason not in {"end_turn", "max_tokens", "refusal", "stop_sequence", "tool_use", "pause_turn"}:
        finish_reason = "unknown"
    new = not path.exists()
    with path.open("a", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        if new:
            writer.writeheader()
        writer.writerow(dict(step=step, model=model, region=region, attempt=attempt,
                             status=status, reserved_usd=f"{reserved_usd:.9f}",
                             accounted_usd=f"{accounted_usd:.9f}", elapsed_s=f"{elapsed_s:.3f}",
                             http_status=http_status, finish_reason=finish_reason))
