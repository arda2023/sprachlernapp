"""Thin wrapper around Vertex AI (google-genai, Application Default Credentials).

Every call reserves estimated cost before Vertex, retries 429/5xx at most
five attempts, then reconciles actual usage in a thread-safe ledger.
"""

from __future__ import annotations

import json
import random
import time
from datetime import date
from pathlib import Path
from threading import Condition, Event, Lock

from .cost import BudgetExceeded, append_entry, check_budget

TRANSIENT_CODES = {429, 500, 502, 503, 504}


class LlmError(RuntimeError):
    pass


class AuthError(LlmError):
    """Authentication or permission error from Vertex: never retried."""


class RetryableError(LlmError):
    """Vertex capacity or server error."""


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


def parse_context(model: str, max_output_tokens: int, usage, meta: dict) -> str:
    """Diagnosis for an unparseable response: no prompt, no response text;
    values the call did not report are named 'unbekannt'."""
    known = meta.get("usage_known", True)
    tokens = [f"{k}={v if known else 'unbekannt'}"
              for k, v in zip(("input_tokens", "output_tokens", "thinking_tokens"), usage)]
    return ", ".join([f"model={model}", f"max_output_tokens={max_output_tokens}", *tokens,
                      f"finish_reason={meta.get('finish_reason') or 'unbekannt'}"])


class Llm:
    def __init__(self, cfg: dict, ledger: str | Path, max_usd: float):
        self.cfg = cfg["llm"]
        self.prices = cfg["prices"]
        self.ledger = Path(ledger)
        self.max_usd = max_usd
        self._client = None
        self._client_lock = Lock()
        self._fatal_auth = Event()
        self._budget = Condition(Lock())
        self._reserved = 0.0
        self._spent = 0.0
        self._calls = 0
        self._started = time.monotonic()
        self._progress_path = None
        self._forms_done = 0
        self._forms_total = 0

    def set_progress(self, path: str | Path, total_forms: int) -> None:
        with self._budget:
            self._progress_path = Path(path)
            self._forms_total = total_forms
            self._write_progress()

    def form_done(self) -> None:
        with self._budget:
            self._forms_done += 1
            self._write_progress()

    def finish_progress(self) -> None:
        with self._budget:
            self._write_progress()

    def _write_progress(self) -> None:
        if self._progress_path is None:
            return
        self._progress_path.parent.mkdir(parents=True, exist_ok=True)
        self._progress_path.write_text(
            f"forms {self._forms_done}/{self._forms_total}\n"
            f"calls {self._calls}\nUSD {self._spent:.6f}\n"
            f"elapsed_s {time.monotonic() - self._started:.1f}\n", encoding="ascii")

    def generate_json(self, prompt: str, schema: dict, *, model: str, thinking: dict,
                      step: str, max_output_tokens: int):
        price = model_price(self.prices, model)
        # Upper bound: ~2 characters per input token, full output budget.
        estimate = cost_usd(price, len(prompt) // 2 + 1, max_output_tokens, 0)
        with self._budget:
            while True:
                if self._fatal_auth.is_set():
                    raise AuthError("Vertex authentication failed in this run")
                try:
                    check_budget(self.max_usd, self.ledger, next_usd=estimate + self._reserved)
                    self._reserved += estimate
                    break
                except BudgetExceeded:
                    if self._reserved == 0:
                        raise
                    self._budget.wait()
        try:
            for attempt in range(5):
                if self._fatal_auth.is_set():
                    raise AuthError("Vertex authentication failed in this run")
                try:
                    response, usage, *meta = self._call(prompt, schema, model, thinking,
                                                        max_output_tokens)
                    inp, out, think = usage
                    with self._budget:
                        usd = cost_usd(price, inp, out, think)
                        append_entry(self.ledger, step=step, model=model, input_tokens=inp,
                                     output_tokens=out, thinking_tokens=think, usd=usd)
                        self._spent += usd
                        self._calls += 1
                        if self._calls % 25 == 0:
                            self._write_progress()
                    if not response:
                        raise LlmError("empty response")
                    return json.loads(response)
                except RetryableError as e:
                    if attempt == 4:
                        raise LlmError(f"{step}: {e}") from e
                    time.sleep(min(16, 2 ** attempt) * (0.5 + random.random()))
                except AuthError:
                    self._fatal_auth.set()
                    with self._budget:
                        self._budget.notify_all()
                    raise
                except json.JSONDecodeError as e:   # no retry, no repair
                    context = parse_context(model, max_output_tokens, usage, meta[0] if meta else {})
                    raise LlmError(f"{step}: {e} ({context})") from e
                except LlmError as e:
                    raise LlmError(f"{step}: {e}") from e
        finally:
            with self._budget:
                self._reserved -= estimate
                self._budget.notify_all()

    def _call(self, prompt, schema, model, thinking, max_output_tokens):
        """Returns (json_text, (input_tokens, output_tokens, thinking_tokens),
        {finish_reason, usage_known})."""
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
            code = int(e.code) if str(e.code).isdigit() else e.code
            if code in (401, 403):
                raise AuthError(f"Vertex {e.code} {e.status}") from None
            kind = RetryableError if code in TRANSIENT_CODES or e.status == "RESOURCE_EXHAUSTED" else LlmError
            raise kind(f"Vertex {e.code} {e.status}: {e.message}") from e
        except GoogleAuthError as e:
            raise AuthError(f"ADC {type(e).__name__}") from e
        except Exception as e:  # network errors and timeouts
            raise LlmError(f"{type(e).__name__}: {e}") from e
        u = r.usage_metadata
        usage = usage_counts(u)
        finish = getattr((r.candidates or [None])[0], "finish_reason", None)
        return r.text, usage, {"finish_reason": None if finish is None else getattr(finish, "value", str(finish)),
                               "usage_known": u is not None}

    @property
    def client(self):
        with self._client_lock:
            if self._client is None:
                from google import genai
                from google.genai import types

                self._client = genai.Client(
                    vertexai=True, project=self.cfg["project"], location=self.cfg["location"],
                    http_options=types.HttpOptions(timeout=int(self.cfg["timeout_s"] * 1000)),
                )
        return self._client


__all__ = ["Llm", "LlmError", "AuthError", "BudgetExceeded", "cost_usd", "model_price"]
