"""Bounded Haiku requests through explicit Anthropic or EU Vertex; no fallback.

The ledger is a local budget policy, not a guarantee of the provider's invoice.
Unknown attempts consume their reservation and are identified in a sidecar CSV.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import random
import time
from datetime import date
from pathlib import Path
from threading import Condition, Event, local

from jsonschema import Draft202012Validator, SchemaError, ValidationError

from .cost import BudgetExceeded, append_attempt, append_entry, check_budget

MODEL = "claude-haiku-5-5"
PROJECT = "sprachlernapp-510508"
DIRECT_BASE_URL = "https://api.anthropic.com"
BASE_URL = "https://aiplatform.eu.rep.googleapis.com/v1"
MODEL_PATH = f"/v1/projects/{PROJECT}/locations/eu/publishers/anthropic/models/{MODEL}:rawPredict"
TRANSIENT_CODES = {429, 500, 502, 503, 504}
STEPS = {"meanings", "sentences", "annotate", "blindtest", "meaning_check",
         "classify_usage", "alternative_check"}


class LlmError(RuntimeError):
    def __init__(self, message, *, status_code=None):
        super().__init__(message)
        self.status_code = status_code


class AuthError(LlmError):
    """Authentication or permission error: never retried."""


class RetryableError(LlmError):
    """Only explicitly selected HTTP statuses may be retried."""


def model_price(prices: dict, model: str, today: date | None = None,
                *, provider: str = "anthropic") -> dict:
    try:
        p = prices["models"][model]
        if model == MODEL and provider == "vertex":
            p = p["vertex_eu"]
    except KeyError:
        raise LlmError("model has no checked price") from None
    until = p.get("intro_until")
    if until and (today or date.today()) > date.fromisoformat(until):
        return p["after_intro"]
    return p


def cost_usd(price: dict, input_tokens: int, output_tokens: int, thinking_tokens: int) -> float:
    return (input_tokens * price["input_per_mtok_usd"]
            + output_tokens * price["output_per_mtok_usd"]
            + thinking_tokens * price["thinking_per_mtok_usd"]) / 1_000_000


def reservation_usd(price: dict, prompt_chars: int, max_output_tokens: int) -> float:
    """Local conservative policy: text byte estimate + 4096 overhead tokens.

    Caller supplies serialized UTF-8 request bytes at runtime. Offline selection
    supplies its estimated prompt length. Neither is a provider invoice cap.
    """
    return cost_usd(price, prompt_chars + 4096, max_output_tokens, 0)


def usage_counts(metadata) -> tuple[int, int, int] | None:
    """Haiku output_tokens already includes thinking. Missing != zero."""
    if metadata is None:
        return None
    inp = getattr(metadata, "input_tokens", None)
    out = getattr(metadata, "output_tokens", None)
    if type(inp) is not int or type(out) is not int or inp < 0 or out < 0:
        return None
    # No caching is requested. Reject unexpected cache accounting rather than
    # silently pricing cached input at the wrong tariff.
    for name in ("cache_creation_input_tokens", "cache_read_input_tokens"):
        value = getattr(metadata, name, 0)
        if value not in (None, 0):
            return None
    return inp, out, 0


def parse_context(model: str, max_output_tokens: int, usage, meta: dict) -> str:
    known = usage is not None and meta.get("usage_known", True)
    tokens = [f"{k}={v if known else 'unbekannt'}"
              for k, v in zip(("input_tokens", "output_tokens", "thinking_tokens"), usage or (0, 0, 0))]
    finish = meta.get("finish_reason")
    if finish not in {"end_turn", "max_tokens", "refusal", "stop_sequence", "tool_use", "pause_turn"}:
        finish = "unbekannt"
    return ", ".join([f"model={MODEL}", f"max_output_tokens={max_output_tokens}", *tokens,
                      f"finish_reason={finish}"])


def transport_schema(schema):
    """Copy the schema, relaxing ONLY wire-level unsupported constraints.

    The original is always validated locally. Property names are not keywords.
    """
    if not isinstance(schema, dict):
        return schema
    result = {}
    for key, value in schema.items():
        if key in {"minimum", "maximum", "exclusiveMinimum", "exclusiveMaximum",
                   "multipleOf", "minLength", "maxLength", "maxItems", "uniqueItems"}:
            continue
        if key == "minItems" and value not in (0, 1):
            continue
        if key in {"properties", "$defs", "definitions", "patternProperties"}:
            result[key] = {name: transport_schema(child) for name, child in value.items()}
        elif key in {"items", "additionalProperties", "not"}:
            result[key] = transport_schema(value)
        elif key in {"anyOf", "allOf", "oneOf", "prefixItems"}:
            result[key] = [transport_schema(child) for child in value]
        else:
            result[key] = value
    if result.get("type") == "object" or "properties" in result:
        result["additionalProperties"] = False
    return result


def request_body(prompt, schema, max_output_tokens):
    return {"messages": [{"role": "user", "content": prompt}],
            "max_tokens": max_output_tokens, "thinking": {"type": "disabled"},
            "output_config": {"effort": "low", "format": {
                "type": "json_schema", "schema": transport_schema(schema)}}}


async def verify_route(request):
    if (str(request.url.scheme) != "https" or request.url.host != "aiplatform.eu.rep.googleapis.com"
            or request.url.path != MODEL_PATH or request.method != "POST"):
        raise LlmError("EU Vertex route rejected")


def direct_client(timeout: float, *, count_only: bool = False):
    """Explicit static key and fixed endpoint; never consult SDK login profiles."""
    from anthropic import AsyncAnthropic
    from httpx2 import AsyncClient

    key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not key.strip():
        raise LlmError("ANTHROPIC_API_KEY fehlt; im selben Terminal verdeckt eingeben")
    path = "/v1/messages/count_tokens" if count_only else "/v1/messages"

    async def route(request):
        if (str(request.url) != DIRECT_BASE_URL + path or request.method != "POST"):
            raise LlmError("direct Anthropic route rejected")

    logging.getLogger("anthropic._base_client").disabled = True
    return AsyncAnthropic(
        api_key=key, base_url=DIRECT_BASE_URL, max_retries=0,
        timeout=min(30.0, timeout), open_telemetry=False,
        http_client=AsyncClient(follow_redirects=False, trust_env=False,
                               event_hooks={"request": [route]}),
    )


class Llm:
    def __init__(self, cfg: dict, ledger: str | Path, max_usd: float):
        self.cfg = cfg["llm"]
        self.provider = self.cfg.get("provider")
        if self.provider not in {"anthropic", "vertex"}:
            raise LlmError("llm.provider must explicitly be anthropic or vertex")
        self.prices = cfg["prices"]
        self.ledger = Path(ledger)
        self.max_usd = max_usd
        self._fatal_auth = Event()
        self._uncertain = Event()
        self._budget = Condition()
        self._request = local()
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
        if (model != MODEL or (self.provider == "vertex" and
                (self.cfg.get("project") != PROJECT or self.cfg.get("location") != "eu"))
                or thinking != {"type": "disabled"} or self.cfg.get("effort") != "low"
                or step not in STEPS or type(max_output_tokens) is not int
                or not 0 < max_output_tokens <= 4096):
            raise LlmError("unsupported Haiku configuration")
        try:
            Draft202012Validator.check_schema(schema)
        except SchemaError:
            raise LlmError("invalid local schema") from None
        price = model_price(self.prices, model, provider=self.provider)
        size = len(json.dumps(request_body(prompt, schema, max_output_tokens),
                              ensure_ascii=True).encode("utf-8"))
        # Keep well clear of the long-context boundary, including schema overhead.
        if size + 4096 >= 100_000:
            raise LlmError("request exceeds local short-context limit")
        estimate = reservation_usd(price, size, max_output_tokens)
        deadline = time.monotonic() + min(95.0, self.cfg.get("total_timeout_s", 95.0))
        self._request.deadline = deadline
        attempts = min(3, max(1, int(self.cfg.get("max_attempts", 3))))
        for attempt in range(1, attempts + 1):
            with self._budget:
                while True:
                    if self._fatal_auth.is_set():
                        raise AuthError("Haiku authentication failed in this run")
                    if self._uncertain.is_set():
                        raise LlmError("run stopped: uncertain usage or accounting")
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        raise LlmError("request deadline exceeded")
                    try:
                        check_budget(self.max_usd, self.ledger, next_usd=estimate + self._reserved)
                        self._reserved += estimate
                        break
                    except BudgetExceeded:
                        if self._reserved == 0:
                            raise
                        self._budget.wait(timeout=remaining)
            usage, meta, status, usd = None, {}, "unknown_reserved", estimate
            retry = False
            started, http_status = time.monotonic(), None
            try:
                response, usage, *metadata = self._call(prompt, schema, model, thinking,
                                                      max_output_tokens)
                meta = metadata[0] if metadata else {"usage_known": True, "finish_reason": "end_turn"}
                if (usage is None or meta.get("usage_known") is False or len(usage) != 3
                        or any(type(n) is not int or n < 0 for n in usage)):
                    usage = None
                    self._uncertain.set()
                    raise LlmError("unknown usage (" + parse_context(model, max_output_tokens, usage, meta) + ")")
                usd = cost_usd(price, *usage)
                status = "reported"
                if usd > estimate:
                    self._uncertain.set()
                    raise LlmError("reported cost exceeded local reservation; run stopped")
                if meta.get("model_matches", True) is not True:
                    raise LlmError("unexpected response model; no fallback")
                context = parse_context(model, max_output_tokens, usage, meta)
                if meta.get("finish_reason") != "end_turn":
                    raise LlmError("incomplete or refused response (" + context + ")")
                try:
                    value = json.loads(response)
                except (json.JSONDecodeError, TypeError):
                    raise LlmError("invalid JSON (" + context + ")") from None
                try:
                    Draft202012Validator(schema).validate(value)
                except ValidationError:
                    raise LlmError("local schema validation failed (" + context + ")") from None
                status = "success_reported"
                return value
            except RetryableError as error:
                http_status = error.status_code
                status = "server_error_reserved"
                retry = attempt < attempts
                if not retry:
                    raise LlmError(f"{step}: retry limit reached") from None
            except AuthError as error:
                http_status = error.status_code
                status = "auth_error_reserved"
                self._fatal_auth.set()
                raise AuthError(f"{step}: Haiku authentication failed") from None
            except LlmError as error:
                http_status = error.status_code
                if usage is not None:
                    status = "response_error_reported"
                if usage is None and status == "unknown_reserved":
                    self._uncertain.set()
                # Only our fixed diagnostics are emitted; no provider exception chain.
                raise LlmError(f"{step}: {error}", status_code=http_status) from None
            except Exception:
                self._uncertain.set()
                raise LlmError(f"{step}: request failed; usage unknown") from None
            finally:
                with self._budget:
                    try:
                        append_entry(self.ledger, step=step, model=model,
                                     input_tokens=None if usage is None else usage[0],
                                     output_tokens=None if usage is None else usage[1],
                                     thinking_tokens=None if usage is None else usage[2], usd=usd)
                        append_attempt(self.ledger, step=step, model=model, attempt=attempt,
                                       status=status, reserved_usd=estimate, accounted_usd=usd,
                                       elapsed_s=time.monotonic() - started, http_status=http_status,
                                       finish_reason=meta.get("finish_reason"),
                                       region="eu" if self.provider == "vertex" else "not-eu-bound")
                        self._spent += usd
                        self._calls += 1
                        if self._calls % 25 == 0:
                            self._write_progress()
                    except Exception:
                        self._uncertain.set()
                        raise LlmError("local accounting failed; run stopped") from None
                    finally:
                        self._reserved = max(0.0, self._reserved - estimate)
                        self._budget.notify_all()
            if retry:
                delay = min(16, 2 ** (attempt - 1)) * (0.5 + random.random())
                if time.monotonic() + delay >= deadline:
                    raise LlmError("request deadline exceeded")
                time.sleep(delay)

    def _call(self, prompt, schema, model, thinking, max_output_tokens):
        """Run a cancellable async SDK request behind the existing sync seam."""
        import anthropic
        auth_errors = (anthropic.AuthenticationError, anthropic.PermissionDeniedError)
        if self.provider == "vertex":
            from google.auth.exceptions import GoogleAuthError
            auth_errors += (GoogleAuthError,)

        async def request():
            async with self.client as client:
                return await client.messages.create(model=model, **request_body(prompt, schema, max_output_tokens))

        timeout = min(30.0, self.cfg["timeout_s"],
                      self._request.deadline - time.monotonic())
        loop = asyncio.new_event_loop()
        try:
            response = loop.run_until_complete(asyncio.wait_for(request(), timeout=timeout))
        except (TimeoutError, anthropic.APITimeoutError):
            raise LlmError("request timeout; usage unknown") from None
        except auth_errors as error:
            raise AuthError("Haiku authentication failed", status_code=getattr(error, "status_code", None)) from None
        except anthropic.APIStatusError as error:
            code = error.status_code
            kind = RetryableError if code in TRANSIENT_CODES else LlmError
            raise kind(f"Haiku HTTP {code}", status_code=code) from None
        except LlmError:
            raise
        except Exception:
            raise LlmError("Haiku transport failed; usage unknown") from None
        finally:
            # Cancels the HTTP request, not a detached model-request thread. ADC
            # refresh may finish in an executor after cancellation; its awaiting
            # task is gone and cannot subsequently send the model request.
            loop.close()
        usage = usage_counts(response.usage)
        finish = response.stop_reason
        text = "".join(block.text for block in response.content if block.type == "text")
        return text, usage, {"finish_reason": finish, "usage_known": usage is not None,
                             "model_matches": response.model == model}

    @property
    def client(self):
        # One scoped async client per call: no connection pool shared between
        # the independent event loops of concurrent synchronous callers.
        if self.provider == "anthropic":
            return direct_client(min(30.0, self.cfg["timeout_s"]))
        from anthropic import AsyncAnthropicVertex
        from httpx2 import AsyncClient

        # The pinned SDK's debug request logger includes JSON and exception bodies.
        # Keep it off even if ANTHROPIC_LOG or the application's root logger is DEBUG.
        logging.getLogger("anthropic._base_client").disabled = True
        return AsyncAnthropicVertex(
            project_id=PROJECT, region="eu", base_url=BASE_URL,
            timeout=min(30.0, self.cfg["timeout_s"]), max_retries=0,
            open_telemetry=False,
            http_client=AsyncClient(follow_redirects=False,
                                    event_hooks={"request": [verify_route]}),
        )


__all__ = ["Llm", "LlmError", "AuthError", "BudgetExceeded", "cost_usd", "model_price"]
