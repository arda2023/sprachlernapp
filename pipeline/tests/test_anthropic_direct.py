"""Real SDK, synthetic key and in-memory transport only; no live requests."""
import asyncio
import csv
import json
import logging
import traceback

import anthropic
import google.auth
import httpx2
import pytest

from sprachpipe import haiku_smoke
from sprachpipe.config import load_config
from sprachpipe.llm import Llm, LlmError, AuthError, MODEL, direct_client, request_body, model_price

SECRET = "synthetic-secret-never-log"
PRIVATE = "synthetic-private-prompt"
SCHEMA = {"type": "object", "properties": {"ok": {"type": "boolean"}},
          "required": ["ok"], "additionalProperties": False}


def reply(text='{"ok":true}', *, stop="end_turn", usage=None):
    return {"id": "synthetic", "type": "message", "role": "assistant", "model": MODEL,
            "content": [{"type": "text", "text": text}], "stop_reason": stop,
            "stop_sequence": None, "usage": usage or {"input_tokens": 80, "output_tokens": 8}}


@pytest.fixture
def offline(monkeypatch, tmp_path):
    calls, clients = [], []
    state = {"handler": lambda request: httpx2.Response(200, json=reply())}
    real = anthropic.AsyncAnthropic

    def forbidden(*args, **kwargs):
        raise AssertionError("Google auth / Vertex must never be used")

    async def handler(request):
        calls.append(request)
        answer = state["handler"](request)
        return await answer if hasattr(answer, "__await__") else answer

    def sdk(**kwargs):
        kwargs["http_client"]._transport = httpx2.MockTransport(handler)
        kwargs["http_client"]._mounts = {}
        client = real(**kwargs)
        clients.append(client)
        return client

    monkeypatch.setenv("ANTHROPIC_API_KEY", SECRET)
    monkeypatch.setenv("ANTHROPIC_BASE_URL", "https://invalid.example")
    monkeypatch.setenv("ANTHROPIC_AUTH_TOKEN", "wrong-auth")
    monkeypatch.setenv("ANTHROPIC_PROFILE", "must-not-load")
    monkeypatch.setenv("GOOGLE_APPLICATION_CREDENTIALS", "/nonexistent-do-not-read.json")
    monkeypatch.setattr(google.auth, "default", forbidden)
    monkeypatch.setattr(anthropic, "AsyncAnthropicVertex", forbidden)
    monkeypatch.setattr(anthropic, "AsyncAnthropic", sdk)
    cfg = load_config()
    assert cfg["llm"]["provider"] == "anthropic"
    del cfg["llm"]["project"], cfg["llm"]["location"]
    return Llm(cfg, tmp_path / "ledger.csv", 1), calls, clients, state


def generate(llm):
    return llm.generate_json(PRIVATE, SCHEMA, model=MODEL, thinking={"type": "disabled"},
                             step="meaning_check", max_output_tokens=128)


def test_direct_sdk_route_parameters_usage_without_google(offline):
    llm, calls, clients, _ = offline
    assert generate(llm) == {"ok": True}
    assert len(calls) == 1
    request = calls[0]
    assert str(request.url) == "https://api.anthropic.com/v1/messages"
    assert request.headers["x-api-key"] == SECRET
    assert "authorization" not in request.headers
    assert request.headers["anthropic-version"] == "2023-06-01"
    assert json.loads(request.content) == {"model": MODEL, **request_body(PRIVATE, SCHEMA, 128)}
    assert clients[0].max_retries == 0
    row = next(csv.DictReader(llm.ledger.open()))
    assert (row["model"], row["input_tokens"], row["output_tokens"]) == (MODEL, "80", "8")
    assert float(row["usd"]) == pytest.approx((80 * .10 + 8 * .50) / 1e6)
    attempt = next(csv.DictReader(llm.ledger.with_name("ledger.csv.attempts.csv").open()))
    assert attempt["region"] == "not-eu-bound"


@pytest.mark.parametrize("key", [None, "", "  "])
def test_missing_key_is_clear_and_no_request(offline, monkeypatch, key):
    llm, calls, _, _ = offline
    if key is None:
        monkeypatch.delenv("ANTHROPIC_API_KEY")
    else:
        monkeypatch.setenv("ANTHROPIC_API_KEY", key)
    with pytest.raises(LlmError, match="ANTHROPIC_API_KEY fehlt"):
        generate(llm)
    assert not calls


@pytest.mark.parametrize("provider", [None, "", "gemini", "auto"])
def test_provider_must_be_explicit(tmp_path, provider):
    cfg = load_config()
    cfg["llm"]["provider"] = provider
    with pytest.raises(LlmError, match="explicitly"):
        Llm(cfg, tmp_path / "ledger.csv", 1)


@pytest.mark.parametrize("text,stop", [('private invalid', 'end_turn'), ('{"ok":"private"}', 'end_turn'),
                                      ('{"ok":true}', 'max_tokens'), ('{"ok":true}', 'refusal')])
def test_invalid_answer_never_retries_or_leaks(offline, text, stop):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json=reply(text, stop=stop))
    with pytest.raises(LlmError) as error:
        generate(llm)
    assert len(calls) == 1
    assert "private" not in "".join(traceback.format_exception(error.value))


@pytest.mark.parametrize("code,attempts", [(401, 1), (403, 1), (429, 3), (500, 3), (400, 1), (307, 1)])
def test_http_errors_no_fallback_and_safe_logging(offline, monkeypatch, caplog, code, attempts):
    llm, calls, _, state = offline
    monkeypatch.setattr("sprachpipe.llm.time.sleep", lambda _: None)
    caplog.set_level(logging.DEBUG)
    state["handler"] = lambda request: httpx2.Response(code, headers={"location": "https://invalid.example"},
        json={"error": {"message": SECRET + PRIVATE}})
    with pytest.raises(LlmError) as error:
        generate(llm)
    assert len(calls) == attempts
    if code in (401, 403):
        assert isinstance(error.value, AuthError)
        with pytest.raises(AuthError):
            generate(llm)
        assert len(calls) == 1
    output = caplog.text + "".join(traceback.format_exception(error.value))
    output += llm.ledger.read_text() + llm.ledger.with_name("ledger.csv.attempts.csv").read_text()
    assert SECRET not in output and PRIVATE not in output


@pytest.mark.parametrize("error_type", [httpx2.ConnectError, httpx2.ReadTimeout])
def test_network_errors_no_retry_or_secret(offline, error_type):
    llm, calls, _, state = offline
    def fail(request):
        raise error_type(SECRET + PRIVATE, request=request)
    state["handler"] = fail
    with pytest.raises(LlmError) as error:
        generate(llm)
    assert len(calls) == 1
    assert SECRET not in "".join(traceback.format_exception(error.value))


def test_direct_route_hook_rejects_changed_client_url(offline):
    _, calls, _, _ = offline
    async def attempt():
        async with direct_client(1) as client:
            client.base_url = "https://invalid.example"
            await client.messages.create(model=MODEL, **request_body(PRIVATE, SCHEMA, 128))
    with pytest.raises(anthropic.APIConnectionError):
        asyncio.run(attempt())
    assert not calls


def test_provider_prices():
    prices = load_config()["prices"]
    assert model_price(prices, MODEL)["input_per_mtok_usd"] == .10
    assert model_price(prices, MODEL, provider="vertex")["input_per_mtok_usd"] == .11


def test_response_model_must_match(offline):
    llm, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json={**reply(), "model": "other"})
    with pytest.raises(LlmError, match="unexpected response model"):
        generate(llm)
    assert len(calls) == 1


def test_smoke_reports_actual_limit_violation(offline, capsys):
    _, calls, _, state = offline
    state["handler"] = lambda request: httpx2.Response(200, json=(
        {"input_tokens": 100} if request.url.path.endswith("count_tokens")
        else reply(usage={"input_tokens": 501, "output_tokens": 8})))
    assert haiku_smoke.main(["--live"]) == 2
    assert len(calls) == 2
    assert json.loads(capsys.readouterr().out)["error"].startswith("reported_token_limit_exceeded")


def test_smoke_requires_explicit_start(offline):
    with pytest.raises(SystemExit) as exit:
        haiku_smoke.main([])
    assert exit.value.code == 2 and not offline[1]


@pytest.mark.parametrize("count,code,expected_calls,success", [(100, 200, 2, True), (401, 200, 1, False),
                                                              (100, 429, 2, False), (100, 401, 2, False)])
def test_smoke_bounded_synthetic_only(offline, capsys, count, code, expected_calls, success):
    _, calls, _, state = offline
    def handler(request):
        if request.url.path.endswith("count_tokens"):
            return httpx2.Response(200, json={"input_tokens": count})
        return httpx2.Response(code, json=reply() if code == 200 else {"error": {"message": SECRET}})
    state["handler"] = handler
    assert haiku_smoke.main(["--live"]) == (0 if success else 2)
    assert len(calls) == expected_calls
    output = capsys.readouterr().out
    assert SECRET not in output
    result = json.loads(output)
    assert result["model"] == MODEL and result["status"] == ("success" if success else "error")
    for request in calls:
        body = json.loads(request.content)
        assert body["messages"] == [{"role": "user", "content": haiku_smoke.PROMPT}]
        assert body["output_config"]["format"]["schema"] == SCHEMA
        assert len(request.content) < 500
        if not request.url.path.endswith("count_tokens"):
            assert body["max_tokens"] == 128
