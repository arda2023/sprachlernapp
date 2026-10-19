"""Opt-in synthetic direct-API probe; never reads content or credential files."""
from __future__ import annotations

import argparse
import asyncio
import csv
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from .llm import Llm, LlmError, MODEL, direct_client, request_body

PROMPT = 'Return {"ok":true}.'
SCHEMA = {"type": "object", "properties": {"ok": {"type": "boolean"}},
          "required": ["ok"], "additionalProperties": False}
MAX_INPUT = 500
# Count Tokens is an estimate; leave 100 tokens of headroom for this tiny input.
COUNT_CEILING = 400
MAX_OUTPUT = 128


async def count_input():
    body = request_body(PROMPT, SCHEMA, MAX_OUTPUT)
    body.pop("max_tokens")
    async with direct_client(30, count_only=True) as client:
        return (await client.messages.count_tokens(model=MODEL, **body)).input_tokens


def run() -> int:
    result = {"model": MODEL, "provider": "anthropic", "status": "error",
              "counted_input_tokens": None, "input_tokens": None, "output_tokens": None}
    # No YAML, .env, pack, editor or user file is loaded by this entry point.
    cfg = {"llm": {"provider": "anthropic", "effort": "low", "timeout_s": 30,
                   "total_timeout_s": 30, "max_attempts": 1},
           "prices": {"models": {MODEL: {"input_per_mtok_usd": .10,
                       "output_per_mtok_usd": .50, "thinking_per_mtok_usd": .50}}}}
    with TemporaryDirectory(prefix="sprachapp-haiku-probe-") as directory:
        ledger = Path(directory) / "ledger.csv"
        try:
            count = asyncio.run(asyncio.wait_for(count_input(), timeout=30))
            if type(count) is not int or not 0 <= count <= COUNT_CEILING:
                result["error"] = "input_preflight_limit_or_unknown; no generation"
            else:
                result["counted_input_tokens"] = count
                value = Llm(cfg, ledger, .01).generate_json(
                    PROMPT, SCHEMA, model=MODEL, thinking={"type": "disabled"},
                    step="meaning_check", max_output_tokens=MAX_OUTPUT)
                result["status"] = "success" if value == {"ok": True} else "error"
                if result["status"] == "error":
                    result["error"] = "unexpected_synthetic_result"
        except LlmError as error:
            result["error"] = str(error)  # wrapper emits only fixed safe diagnostics
        except Exception:
            # Includes SDK preflight failures: never print their body or chain.
            result["error"] = "request_failed; check local key, API access and limits"
        if ledger.exists():
            rows = list(csv.DictReader(ledger.open(encoding="utf-8")))
            if rows:
                for name in ("input_tokens", "output_tokens"):
                    result[name] = int(rows[-1][name]) if rows[-1][name] else None
            if (result["input_tokens"] is not None and result["input_tokens"] > MAX_INPUT
                    or result["output_tokens"] is not None and result["output_tokens"] > MAX_OUTPUT):
                result.update(status="error", error="reported_token_limit_exceeded; no further request")
    print(json.dumps(result, ensure_ascii=True))
    return 0 if result["status"] == "success" else 2


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="One synthetic Haiku generation after token-count preflight")
    parser.add_argument("--live", action="store_true", help="Explicitly send count request and at most one generation")
    args = parser.parse_args(argv)
    if not args.live:
        parser.error("requires --live; no request sent")
    return run()


if __name__ == "__main__":
    raise SystemExit(main())
