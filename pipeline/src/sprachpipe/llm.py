"""Thin wrapper around Vertex AI (google-genai, Application Default Credentials).

Every call: estimate cost → check_budget → call (retry transient errors at
most max_retries times) → ledger entry with the real token counts from
usage_metadata, thinking tokens included. No API key, no key file.
"""

from __future__ import annotations

import json
import time
from datetime import date
from pathlib import Path

from .cost import BudgetExceeded, append_entry, check_budget

TRANSIENT_CODES = {408, 429, 500, 502, 503, 504}


class LlmError(RuntimeError):
    pass


class AuthError(LlmError):
    """Authentication or permission error from Vertex: never retried."""


def model_price(prices: dict, model: str, today: date | None = None) -> dict:
    try:
        p = prices["models"][model]
    except KeyError:
        raise LlmError(f"no checked price for model {model!r} in config.yaml") from None
    until = p.get("intro_until")
    if until and (today or date.today()) > date.fromisoformat(until):
        return p["after_intro"]
    return p


def cost_usd(price: dict, input_tokens: int, output_tokens: int, thinking_tokens: int) -> float:
    return (input_tokens * price["input_per_mtok_usd"]
            + output_tokens * price["output_per_mtok_usd"]
            + thinking_tokens * price["thinking_per_mtok_usd"]) / 1_000_000


def usage_counts(metadata) -> tuple[int, int, int]:
    """Vertex separates visible candidate tokens from thoughts_token_count."""
    return (int(getattr(metadata, "prompt_token_count", 0) or 0),
            int(getattr(metadata, "candidates_token_count", 0) or 0),
            int(getattr(metadata, "thoughts_token_count", 0) or 0))


class Llm:
    def __init__(self, cfg: dict, ledger: str | Path, max_usd: float):
        self.cfg = cfg["llm"]
        self.prices = cfg["prices"]
        self.ledger = Path(ledger)
        self.max_usd = max_usd
        self._client = None

    def generate_json(self, prompt: str, schema: dict, *, model: str, thinking: dict,
                      step: str, max_output_tokens: int):
        price = model_price(self.prices, model)
        # Upper bound: ~2 characters per input token, full output budget.
        estimate = cost_usd(price, len(prompt) // 2 + 1, max_output_tokens, 0)
        check_budget(self.max_usd, self.ledger, next_usd=estimate)

        retries = self.cfg.get("max_retries", 2)
        for attempt in range(retries + 1):
            try:
                text, usage = self._call(prompt, schema, model, thinking, max_output_tokens)
                inp, out, think = usage
                append_entry(self.ledger, step=step, model=model, input_tokens=inp,
                             output_tokens=out, thinking_tokens=think,
                             usd=cost_usd(price, inp, out, think))
                return json.loads(text)
            except AuthError:
                raise
            except (LlmError, json.JSONDecodeError) as e:
                if attempt == retries or not _transient(e):
                    raise LlmError(f"{step}: {e}") from e
                check_budget(self.max_usd, self.ledger, next_usd=estimate)
                time.sleep(2 ** attempt)

    def _call(self, prompt, schema, model, thinking, max_output_tokens):
        """Returns (json_text, (input_tokens, output_tokens, thinking_tokens))."""
        from google.auth.exceptions import GoogleAuthError
        from google.genai import errors, types

        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            response_json_schema=schema,
            thinking_config=types.ThinkingConfig(**thinking),
            max_output_tokens=max_output_tokens,
        )
        try:
            r = self.client.models.generate_content(model=model, contents=prompt, config=config)
        except errors.APIError as e:
            if e.code in (401, 403):
                raise AuthError(f"Vertex {e.code} {e.status}") from None
            raise LlmError(f"Vertex {e.code} {e.status}: {e.message}") from e
        except GoogleAuthError as e:
            raise AuthError(f"ADC {type(e).__name__}") from e
        except Exception as e:  # network errors and timeouts
            raise LlmError(f"{type(e).__name__}: {e}") from e
        u = r.usage_metadata
        usage = usage_counts(u)
        if not r.text:
            # Tokens were spent; record them before failing.
            append_entry(self.ledger, step="empty-response", model=model, input_tokens=usage[0],
                         output_tokens=usage[1], thinking_tokens=usage[2],
                         usd=cost_usd(model_price(self.prices, model), *usage))
            raise LlmError(f"empty response (finish_reason {_finish(r)})")
        return r.text, usage

    @property
    def client(self):
        if self._client is None:
            from google import genai
            from google.genai import types

            self._client = genai.Client(
                vertexai=True, project=self.cfg["project"], location=self.cfg["location"],
                http_options=types.HttpOptions(timeout=int(self.cfg["timeout_s"] * 1000)),
            )
        return self._client


def _transient(e: Exception) -> bool:
    if isinstance(e, json.JSONDecodeError):
        return True
    msg = str(e)
    if msg.startswith("Vertex "):
        code = msg.split()[1]
        return code.isdigit() and int(code) in TRANSIENT_CODES
    return True  # network error, timeout, empty response


def _finish(r) -> str:
    try:
        return str(r.candidates[0].finish_reason)
    except (AttributeError, IndexError, TypeError):
        return "unknown"


__all__ = ["Llm", "LlmError", "AuthError", "BudgetExceeded", "cost_usd", "model_price"]
