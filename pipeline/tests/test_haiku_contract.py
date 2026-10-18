"""Offline contracts: real pinned SDK + in-memory HTTP transport, never ADC/network."""
import asyncio
import copy
import csv
import json
import time
from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace

import anthropic
import httpx2
import pytest

from sprachpipe.config import load_config
from sprachpipe.cost import BudgetExceeded, append_entry, total_usd
from sprachpipe.llm import (AuthError, Llm, LlmError, MODEL, MODEL_PATH, BASE_URL,
                           cost_usd, model_price, request_body, reservation_usd,
                           transport_schema, usage_counts)

SCHEMA = {"type": "object", "properties": {"answer": {"type": "string", "minLength": 1}},
          "required": ["answer"], "additionalProperties": False}


def reply(text='{"answer":"ok"}', *, usage=True, stop="end_turn"):
    body = {"id": "synthetic", "type": "message", "role": "assistant", "model": MODEL,
            "content": [{"type": "thinking", "thinking": "", "signature": "synthetic"},
                        {"type": "text", "text": text}], "stop_reason": stop,
            "stop_sequence": None}
    if usage:
        body["usage"] = {"input_tokens": 100, "output_tokens": 20}
    return body


@pytest.fixture
def offline(monkeypatch, tmp_path):
    real_sdk, real_http = anthropic.AsyncAnthropicVertex, httpx2.AsyncClient
    calls, clients = [], []
    state = {"handler": lambda request: httpx2.Response(200, json=reply())}

    async def handler(request):
        calls.append(request)
        result = state["handler"](request)
        return await result if hasattr(result, "__await__") else result

    def sdk(**kwargs):
        # Synthetic token bypasses ADC; this never reads login files.
        kwargs["http_client"]._transport = httpx2.MockTransport(handler)
        kwargs["http_client"]._mounts = {}  # no environment proxy mounts in offline fixture
        client = real_sdk(access_token="synthetic-offline-token", **kwargs)
        clients.append(client)
        return client

    monkeypatch.setattr(anthropic, "AsyncAnthropicVertex", sdk)
    llm = Llm(load_config(), tmp_path / "ledger.csv", 1.0)
    return llm, calls, clients, state


def generate(llm, *, schema=SCHEMA, prompt="synthetic", **kwargs):
    args = dict(model=MODEL, thinking={"type": "disabled"}, step="meaning_check", max_output_tokens=256)
    args.update(kwargs)
    return llm.generate_json(prompt, schema, **args)


def test_pinned_sdk_constructs_eu_project_and_model_route(offline, monkeypatch):
    llm, calls, clients, state = offline
    monkeypatch.setenv("ANTHROPIC_VERTEX_BASE_URL", "https://api.anthropic.com/v1")
    monkeypatch.setenv("CLOUD_ML_REGION", "global")
    monkeypatch.setenv("ANTHROPIC_VERTEX_PROJECT_ID", "wrong-project")
    assert anthropic.__version__ == "1.15.0"
    assert generate(llm) == {"answer": "ok"}
    assert len(calls) == 1
    request = calls[0]
    assert str(request.url) == BASE_URL + MODEL_PATH.removeprefix("/v1")
    assert request.method == "POST"
    assert clients[0].project_id == "sprachlernapp-510508" and clients[0].region == "eu"
    assert clients[0].max_retries == 0
    body = json.loads(request.content)
    assert body == {**request_body("synthetic", SCHEMA, 256), "anthropic_version": "vertex-2023-10-16"}
    assert "model" not in body
    assert not {"temperature", "top_p", "top_k", "thinking_config", "response_json_schema"} & body.keys()
    row = next(csv.DictReader(llm.ledger.open()))
    assert (row["input_tokens"], row["output_tokens"], row["thinking_tokens"]) == ("100", "20", "0")
    assert float(row["usd"]) == pytest.approx((100 * .11 + 20 * .55) / 1e6)


@pytest.mark.parametrize("change", [{"model": "gemini-3.8-flash"}, {"thinking": {"thinking_budget": 0}},
                                    {"max_output_tokens": 4097}, {"step": "private text"}])
def test_no_fallback_or_unchecked_parameters(offline, change):
    llm, calls, _, _ = offline
    with pytest.raises(LlmError, match="unsupported"):
        generate(llm, **change)
    assert calls == [] and not llm.ledger.exists()


@pytest.mark.parametrize("field,value", [("location", "global"), ("project", "other"), ("effort", "medium")])
def test_config_cannot_override_routing_policy(offline, field, value):
    llm, calls, _, _ = offline
    llm.cfg[field] = value
    with pytest.raises(LlmError, match="unsupported"):
        generate(llm)
    assert not calls


def test_route_hook_rejects_redirect_before_second_request(offline):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(307, headers={"location": "https://api.anthropic.com/v1/messages"})
    with pytest.raises(LlmError):
        generate(llm)
    assert len(calls) == 1


@pytest.mark.parametrize("text", ['{"answer":"left means links"}', '{"answer":"manga significa manga da camisa"}'])
def test_synthetic_en_and_pt_br_text_contract_only(offline, text):
    llm, _, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json=reply(text))
    assert generate(llm) == json.loads(text)


def test_transport_copy_preserves_property_names_and_full_local_validation(offline):
    llm, _, _, state = offline
    schema = {"type": "object", "properties": {"maxItems": {"type": "array", "minItems": 2,
              "maxItems": 2, "items": {"type": "string", "minLength": 2}}}, "required": ["maxItems"]}
    before = copy.deepcopy(schema)
    wire = transport_schema(schema)
    assert "maxItems" in wire["properties"]
    assert "maxItems" not in wire["properties"]["maxItems"]
    assert wire["additionalProperties"] is False
    state["handler"] = lambda request: httpx2.Response(200, json=reply('{"maxItems":["xx"]}'))
    with pytest.raises(LlmError, match="local schema"):
        generate(llm, schema=schema)
    assert schema == before


@pytest.mark.parametrize("text,stop,diagnosis", [
    ('{"answer":"ok"}', "max_tokens", "incomplete"),
    ('{"answer":"ok"}', "refusal", "refused"),
    ('{"answer":"private fragment', "end_turn", "invalid JSON"),
    ('{"answer":""}', "end_turn", "local schema"),
    ('{"wrong":"private"}', "end_turn", "local schema"),
])
def test_invalid_responses_never_return_or_retry_or_leak_text(offline, text, stop, diagnosis):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json=reply(text, stop=stop))
    with pytest.raises(LlmError, match=diagnosis) as error:
        generate(llm, prompt="private prompt")
    assert len(calls) == 1
    assert "private" not in str(error.value) and error.value.__cause__ is None
    assert "private" not in llm.ledger.read_text()
    assert total_usd(llm.ledger) > 0


@pytest.mark.parametrize("code", [429, 500, 502, 503, 504])
def test_retry_exactly_three_with_new_reservation_and_no_sdk_retry(offline, monkeypatch, code):
    llm, calls, _, state = offline
    monkeypatch.setattr("sprachpipe.llm.time.sleep", lambda _: None)
    state["handler"] = lambda request: httpx2.Response(code, json={"error": {"message": "private provider text"}})
    with pytest.raises(LlmError, match="retry limit") as error:
        generate(llm)
    assert len(calls) == 3
    assert "private" not in str(error.value)
    rows = list(csv.DictReader(llm.ledger.open()))
    assert len(rows) == 3 and all(row["input_tokens"] == "" for row in rows)
    assert total_usd(llm.ledger) > 0 and llm._reserved == pytest.approx(0)
    assert all(row["status"] == "server_error_reserved" for row in csv.DictReader(PathSidecar(llm).open()))


def PathSidecar(llm):
    return llm.ledger.with_name(llm.ledger.name + ".attempts.csv")


@pytest.mark.parametrize("code", [400, 401, 403, 404, 408, 409, 422, 501])
def test_nonretryable_http_errors_redacted(offline, code):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(code, json={"error": {"message": "private provider text"}})
    with pytest.raises(LlmError) as error:
        generate(llm)
    assert len(calls) == 1 and "private" not in str(error.value)
    if code in (401, 403):
        assert isinstance(error.value, AuthError)
        with pytest.raises(AuthError):
            generate(llm)
        assert len(calls) == 1


def test_unknown_usage_is_not_zero_and_blocks_subsequent_requests(offline):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json=reply(usage=False))
    with pytest.raises(LlmError, match="unknown usage"):
        generate(llm)
    with pytest.raises(LlmError, match="run stopped"):
        generate(llm)
    assert len(calls) == 1
    row = next(csv.DictReader(llm.ledger.open()))
    assert row["input_tokens"] == row["output_tokens"] == row["thinking_tokens"] == ""
    assert float(row["usd"]) > 0
    assert next(csv.DictReader(PathSidecar(llm).open()))["status"] == "unknown_reserved"


@pytest.mark.parametrize("usage", [None, SimpleNamespace(input_tokens=1),
    SimpleNamespace(input_tokens=-1, output_tokens=2),
    SimpleNamespace(input_tokens=1, output_tokens=2, cache_read_input_tokens=10)])
def test_invalid_or_unexpected_cache_usage_is_explicitly_unknown(usage):
    assert usage_counts(usage) is None


def test_historical_ledger_still_counts_before_reservation(offline):
    llm, calls, _, _ = offline
    append_entry(llm.ledger, step="old", model="gemini-2.5-flash", input_tokens=100,
                 output_tokens=100, thinking_tokens=10, usd=.99)
    llm.max_usd = .99
    with pytest.raises(BudgetExceeded):
        generate(llm)
    assert not calls and total_usd(llm.ledger) == pytest.approx(.99)


def test_each_retry_must_fit_remaining_budget(offline, monkeypatch):
    llm, calls, _, state = offline
    monkeypatch.setattr("sprachpipe.llm.time.sleep", lambda _: None)
    size = len(json.dumps(request_body("synthetic", SCHEMA, 256), ensure_ascii=True).encode())
    reserve = reservation_usd(model_price(llm.prices, MODEL), size, 256)
    llm.max_usd = reserve * 1.5
    state["handler"] = lambda request: httpx2.Response(503, json={"error": "synthetic"})
    with pytest.raises(BudgetExceeded):
        generate(llm)
    assert len(calls) == 1 and total_usd(llm.ledger) > 0


def test_cancellable_deadline_stops_trickling_http_body(offline):
    llm, calls, _, state = offline
    finished = []
    class SlowBody(httpx2.AsyncByteStream):
        async def __aiter__(self):
            try:
                for byte in json.dumps(reply()).encode():
                    await asyncio.sleep(.005)
                    yield bytes([byte])
            finally:
                finished.append(True)
    state["handler"] = lambda request: httpx2.Response(200, stream=SlowBody())
    llm.cfg["timeout_s"] = .03
    started = time.monotonic()
    with pytest.raises(LlmError, match="timeout"):
        generate(llm)
    assert time.monotonic() - started < .5 and len(calls) == 1 and finished == [True]
    assert total_usd(llm.ledger) > 0


def test_overall_deadline_includes_backoff(offline, monkeypatch):
    llm, calls, _, state = offline
    llm.cfg["total_timeout_s"] = .02
    monkeypatch.setattr("sprachpipe.llm.random.random", lambda: 0)
    state["handler"] = lambda request: httpx2.Response(503, json={"error": "synthetic"})
    with pytest.raises(LlmError, match="deadline"):
        generate(llm)
    assert len(calls) == 1


def test_unknown_attempt_wakes_parallel_waiters_and_stops_run(offline):
    llm, calls, _, state = offline
    llm.max_usd = .0008  # only one request reservation fits
    async def handler(request):
        await asyncio.sleep(.02)
        return httpx2.Response(200, json=reply(usage=False))
    state["handler"] = handler
    def run(_):
        try:
            generate(llm)
        except LlmError as error:
            return str(error)
    with ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(run, range(3)))
    assert len(calls) == 1 and len(results) == 3
    assert all("unknown usage" in r or "run stopped" in r for r in results)
    assert llm._reserved == pytest.approx(0)


def test_sdk_debug_logging_cannot_emit_private_request_or_error(offline, caplog):
    import logging
    llm, _, _, state = offline
    state["handler"] = lambda request: httpx2.Response(400, json={"error": {"message": "private server text"}})
    with caplog.at_level(logging.DEBUG):
        with pytest.raises(LlmError):
            generate(llm, prompt="private personal text")
    assert "private" not in caplog.text and "synthetic-offline-token" not in caplog.text


def test_cancelled_adc_wait_cannot_send_a_late_model_request(offline, monkeypatch):
    from anthropic.lib.vertex import _client
    llm, calls, clients, _ = offline
    real_factory = anthropic.AsyncAnthropicVertex
    def sdk(**kwargs):
        client = real_factory(**kwargs)
        client.access_token = None
        return client
    monkeypatch.setattr(anthropic, "AsyncAnthropicVertex", sdk)
    def load_auth(**kwargs):
        time.sleep(.08)
        return SimpleNamespace(token="synthetic", expired=False), "sprachlernapp-510508"
    monkeypatch.setattr(_client, "load_auth", load_auth)
    llm.cfg["timeout_s"] = .01
    started = time.monotonic()
    with pytest.raises(LlmError, match="timeout"):
        generate(llm)
    assert time.monotonic() - started < .06
    time.sleep(.10)  # let synthetic ADC worker finish; cancelled coroutine must stay cancelled
    assert not calls and clients[0].is_closed()
