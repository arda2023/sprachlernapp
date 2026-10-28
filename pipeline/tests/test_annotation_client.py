"""No-network regression tests for editorial client budget, resume and retry."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import threading
from unittest.mock import Mock

import pytest
import requests

SCRIPTS = Path(__file__).resolve().parents[1] / 'scripts'
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location('annotation_client_tested', SCRIPTS / 'annotate_multilingual_corpus.py')
client = importlib.util.module_from_spec(spec)
spec.loader.exec_module(client)


def envelope():
    payload = {'lang': 'it', 'items': [{'text': 'La città è bella.'}]}
    result = {'model': 'claude-haiku-5-5', 'contract': 'editorial-token-annotation-v3',
              'input_sha256': hashlib.sha256(json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest(),
              'usage': {'input_tokens': 100, 'output_tokens': 200}}
    return payload, result


def test_usage_requires_exact_contract_and_unicode_input_binding():
    payload, result = envelope()
    assert client.usage_cost(payload, result) == pytest.approx(.00011)
    for key, value in [('model', 'other'), ('contract', 'other'), ('input_sha256', '0' * 64), ('usage', {})]:
        with pytest.raises(ValueError):
            client.usage_cost(payload, {**result, key: value})
    for invalid in [True, -1, 16001, float('nan'), '10']:
        with pytest.raises(ValueError):
            client.usage_cost(payload, {**result, 'usage': {'input_tokens': 1, 'output_tokens': invalid}})


def test_process_lock_excludes_second_process_handle_and_releases(tmp_path):
    path = tmp_path / 'annotation.lock'
    with client.process_lock(path):
        with pytest.raises(RuntimeError, match='Another editorial'):
            with client.process_lock(path):
                pytest.fail('second lock acquired')
    with client.process_lock(path):
        pass


def test_cost_ledger_conservatively_retains_unsettled_calls(tmp_path):
    path = tmp_path / 'usage.jsonl'
    client.append_usage(path, {'kind': 'reservation', 'usd': .03})
    client.append_usage(path, {'kind': 'reservation', 'usd': .03})
    client.append_usage(path, {'kind': 'settlement', 'usd': -.029})
    assert client.recorded_cost(path) == pytest.approx(.031)
    with path.open('a') as handle:
        handle.write('{"kind":"settlement","usd":NaN}\n')
    with pytest.raises(ValueError):
        client.recorded_cost(path)


def test_transport_retry_is_bounded_and_reserves_each_attempt(monkeypatch):
    post = Mock(side_effect=requests.Timeout('DO_NOT_DISCLOSE'))
    monkeypatch.setattr(client.requests, 'post', post)
    stop = Mock()
    stop.is_set.return_value = False
    stop.wait.return_value = False
    reserved = []
    with pytest.raises(RuntimeError, match='three attempts') as error:
        client.request_annotation('https://synthetic.invalid', {}, {}, reserved.append, stop)
    assert reserved == [0, 1, 2]
    assert post.call_count == 3
    assert 'DO_NOT_DISCLOSE' not in str(error.value)


def test_abort_and_nontransient_status_never_retry(monkeypatch):
    response = Mock(status_code=403)
    post = Mock(return_value=response)
    monkeypatch.setattr(client.requests, 'post', post)
    reserved = []
    with pytest.raises(RuntimeError, match='HTTP 403'):
        client.request_annotation('https://synthetic.invalid', {}, {}, reserved.append, threading.Event())
    assert reserved == [0]
    response.close.assert_called_once()
    stop = threading.Event(); stop.set()
    with pytest.raises(RuntimeError, match='stopped'):
        client.request_annotation('https://synthetic.invalid', {}, {}, reserved.append, stop)
    assert post.call_count == 1


def test_deck_assembly_requires_every_checkpoint_and_binds_source(tmp_path):
    payload = {'lang': 'it', 'items': [{'id': 'deck:0', 'text': 'Ana legge.',
        'translation_de': 'Ana liest.', 'tokens': [{'idx': 0, 'surface': 'Ana', 'start_pos': 0, 'end_pos': 3}]}]}
    _, result = envelope()
    result['input_sha256'] = hashlib.sha256(json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    result['items'] = [{'id': 'deck:0', 'tokens': [{'idx': 0, 'surface': 'Ana', 'lemma': 'Ana', 'pos': 'PROPN', 'gloss_de': 'Ana', 'context_gloss_de': 'Ana'}]}]
    checkpoint = tmp_path / '_batches' / 'batch.json'
    batches = [(payload, checkpoint)]
    assert client.assemble_deck(tmp_path, 'it', 'deck', 'source-hash', batches) == 0
    assert not (tmp_path / 'it' / 'deck.json').exists()
    client.save(checkpoint, {'response': result, 'human_review': False})
    assert client.assemble_deck(tmp_path, 'it', 'deck', 'source-hash', batches) == 1
    deck = json.loads((tmp_path / 'it' / 'deck.json').read_text())
    assert deck['source_sha256'] == 'source-hash'
    assert deck['human_review'] is False
    assert deck['rows'][0]['sentence'] == 'Ana legge.'


def test_v2_rejects_shifted_token_surfaces_even_when_indices_match():
    items = [{'id': 'pt:0', 'text': 'Estou na varanda.', 'translation_de': 'Ich bin auf dem Balkon.',
              'tokens': [{'idx': 1, 'surface': 'na', 'start_pos': 6, 'end_pos': 8},
                         {'idx': 2, 'surface': 'varanda', 'start_pos': 9, 'end_pos': 16}]}]
    output = {'items': [{'id': 'pt:0', 'tokens': [
        {'idx': 1, 'surface': 'na', 'lemma': 'em', 'pos': 'ADP', 'gloss_de': 'auf', 'context_gloss_de': 'auf dem'},
        {'idx': 2, 'surface': 'varanda', 'lemma': 'varanda', 'pos': 'NOUN', 'gloss_de': 'Balkon', 'context_gloss_de': 'Balkon'}]}]}
    assert client.validate(items, output)[0]['tokens'][1]['surface'] == 'varanda'
    output['items'][0]['tokens'][0]['surface'] = 'varanda'
    output['items'][0]['tokens'][1]['surface'] = 'na'
    with pytest.raises(ValueError, match='surface alignment'):
        client.validate(items, output)
    del output['items'][0]['tokens'][0]['surface']
    with pytest.raises(ValueError, match='annotation fields'):
        client.validate(items, output)


def test_v2_combined_usage_and_legacy_ledger_survive_resume(tmp_path):
    payload, result = envelope()
    result['usage'] = {'input_tokens': 200000, 'output_tokens': 16000}
    assert client.usage_cost(payload, result) == pytest.approx(.028)
    result['contract'] = 'editorial-token-annotation-v1'
    with pytest.raises(ValueError, match='contract'):
        client.usage_cost(payload, result)
    path = tmp_path / 'usage.jsonl'
    for entry in [{'kind': 'reservation', 'usd': .03}, {'kind': 'settlement', 'usd': -.029},
                  {'kind': 'reservation', 'usd': .04}, {'kind': 'settlement', 'usd': -.012}]:
        client.append_usage(path, entry)
    assert client.recorded_cost(path) == pytest.approx(.029)


class FakeTime:
    def __init__(self):
        self.now = 0.0
        self.cancelled = False
        self.waits = []
    def clock(self):
        return self.now
    def is_set(self):
        return self.cancelled
    def wait(self, seconds):
        self.waits.append(seconds)
        self.now += seconds
        return self.cancelled


def limited(complete=True, used=0):
    return {'code': 'PROVIDER_RATE_LIMIT', 'provider_status': 429,
            'retry_after_seconds': 12,
            'rate_limits': {'requests-limit': 60},
            'provider_calls': 2, 'known_usage_calls': 2 if complete else 1,
            'usage_complete': complete,
            'usage': {'input_tokens': used, 'output_tokens': used}}


def test_pacer_uses_two_calls_and_token_limits_at_ninety_percent():
    clock = FakeTime()
    pacer = client.RatePacer(clock=clock.clock, wall=clock.clock)
    pacer.acquire(clock)
    pacer.acquire(clock)
    assert clock.now == pytest.approx(1)
    pacer.observe({'rate_limits': {'requests-limit': 60,
        'input-tokens-limit': 120000, 'output-tokens-limit': 60000,
        'untrusted-secret': 'ignored'}})
    assert pacer.interval == pytest.approx(60 * 4000 / (60000 * .9))
    before = clock.now
    pacer.acquire(clock)
    assert clock.now - before >= pacer.interval
    pacer.backoff(12)
    before = clock.now
    pacer.acquire(clock)
    assert clock.now - before == pytest.approx(12)
    clock.cancelled = True
    with pytest.raises(RuntimeError, match='stopped'):
        pacer.acquire(clock)


def test_rate_retry_settles_known_partial_usage_and_shares_backoff(monkeypatch, tmp_path):
    payload, success = envelope()
    clock = FakeTime()
    pacer = client.RatePacer(clock=clock.clock, wall=clock.clock)
    starts = []
    responses = [Mock(status_code=429), Mock(status_code=200)]
    responses[0].json.return_value = limited(used=100)
    responses[1].json.return_value = success
    def post(*args, **kwargs):
        starts.append(clock.now)
        return responses[len(starts) - 1]
    monkeypatch.setattr(client.requests, 'post', post)
    path = tmp_path / 'usage.jsonl'
    def reserve(attempt):
        client.append_usage(path, {'kind': 'reservation', 'usd': .04})
    def settle(attempt, cost, usage):
        client.append_usage(path, {'kind': 'settlement', 'usd': cost - .04})
    result = client.request_annotation('https://synthetic.invalid', {}, payload,
        reserve, clock, pacer=pacer, settle=settle)
    assert result == success
    assert starts[1] - starts[0] >= 12
    # First call costs only its known pass; final success is still reserved here.
    assert client.recorded_cost(path) == pytest.approx(.04006)
    assert all(r.close.call_count == 1 for r in responses)


def test_incomplete_usage_keeps_reservation_and_retry_count_stays_bounded(monkeypatch):
    clock = FakeTime()
    pacer = client.RatePacer(clock=clock.clock, wall=clock.clock)
    response = Mock(status_code=429)
    response.json.return_value = limited(complete=False, used=100)
    post = Mock(return_value=response)
    monkeypatch.setattr(client.requests, 'post', post)
    reserved, settled = [], []
    with pytest.raises(RuntimeError, match='three attempts'):
        client.request_annotation('https://synthetic.invalid', {}, {}, reserved.append,
            clock, pacer=pacer, settle=lambda *args: settled.append(args))
    assert reserved == [0, 1, 2]
    assert settled == []
    assert post.call_count == 3
    assert clock.now >= 24
    assert client.error_usage(limited(used=0)) == 0
    malformed = limited(); malformed['known_usage_calls'] = True
    assert client.error_usage(malformed) is None
    malformed = limited(); malformed['usage']['input_tokens'] = -1
    assert client.error_usage(malformed) is None


def test_pacer_measured_window_lowers_estimates_and_keeps_spikes_for_32_batches():
    clock = FakeTime()
    pacer = client.RatePacer(clock=clock.clock, wall=clock.clock)
    details = {'rate_limits': {'requests-limit': 1000,
        'input-tokens-limit': 500000, 'output-tokens-limit': 80000}}
    pacer.observe(details)
    initial = pacer.interval
    pacer.observe(details, {'input_tokens': 2000, 'output_tokens': 1000})
    assert pacer.input_estimate == 2200
    assert pacer.output_estimate == 1100
    assert pacer.interval < initial
    assert pacer.interval >= 60 * 1100 / (80000 * .9)
    assert pacer.interval >= 60 * 2 / (1000 * .9)
    pacer.observe(details, {'input_tokens': 6000, 'output_tokens': 8000})
    spike_interval = pacer.interval
    assert pacer.output_estimate == 8800
    for _ in range(31):
        pacer.observe(details, {'input_tokens': 2000, 'output_tokens': 1000})
    assert pacer.output_estimate == 8800
    assert pacer.interval == spike_interval
    pacer.observe(details, {'input_tokens': 2000, 'output_tokens': 1000})
    assert len(pacer.usage_window) == 32
    assert pacer.output_estimate == 1100
    assert pacer.interval < spike_interval
    assert pacer.interval >= 60 * 1100 / (80000 * .9)


@pytest.mark.parametrize('diagnostic,expected', [
    ({'phase': 'review', 'check': 'REVIEW_TOKEN_SURFACE'}, 'review:REVIEW_TOKEN_SURFACE'),
    ({'phase': 'first', 'check': 'TOKEN_POS'}, 'first:TOKEN_POS'),
    ({'phase': 'secret', 'check': 'TOKEN_POS'}, 'HTTP 502 MODEL_INVALID'),
    ({'phase': 'first', 'check': 'secret'}, 'HTTP 502 MODEL_INVALID'),
    ({'phase': 'first', 'check': ['secret']}, 'HTTP 502 MODEL_INVALID'),
])
def test_static_model_diagnostics_never_reflect_arbitrary_content(monkeypatch, diagnostic, expected):
    response = Mock(status_code=502)
    response.json.return_value = {'code': 'MODEL_INVALID', 'diagnostic': diagnostic, 'raw': 'secret'}
    monkeypatch.setattr(client.requests, 'post', Mock(return_value=response))
    stop = Mock()
    stop.is_set.return_value = False
    stop.wait.return_value = False
    with pytest.raises(RuntimeError) as error:
        client.request_annotation('https://synthetic.invalid', {}, {}, lambda _: None, stop)
    assert str(error.value).endswith(expected)
    assert 'secret' not in str(error.value)


def test_main_finishes_other_batches_reports_safe_failure_list_and_exits_nonzero(monkeypatch, tmp_path, capsys):
    (tmp_path / 'inventory.json').write_text('{}')
    monkeypatch.setattr(client, 'CORPUS', tmp_path)
    row = {'sentence': 'Ana legge.', 'translation_de': 'Ana liest.', '_gap': (0, 3)}
    monkeypatch.setattr(client, 'corpus', lambda *_: [
        ({'slug': 'failed'}, [row], 'source-failed'),
        ({'slug': 'success'}, [row], 'source-success')])
    monkeypatch.setattr(client.subprocess, 'run', Mock(return_value=Mock(
        returncode=0, stdout=json.dumps([{'name': 'service_role', 'api_key': 'synthetic-key'}]))))
    monkeypatch.setattr(client, 'configure_admin', Mock())
    monkeypatch.setattr(sys, 'argv', ['annotation', '--cli', 'synthetic-cli', '--project', 'synthetic',
                                     '--lang', 'it', '--workers', '1'])
    attempts = []
    def annotate(_url, _headers, payload, reserve, stopped, **_kwargs):
        item = payload['items'][0]
        attempts.append(item['id'])
        assert not stopped.is_set()
        if item['id'].startswith('failed:'):
            for attempt in range(3):
                reserve(attempt)
            raise client.AnnotationBatchError('Annotation transient failure after three attempts: HTTP 502 MODEL_INVALID first:TOKEN_COUNT')
        reserve(0)
        _, result = envelope()
        result['input_sha256'] = hashlib.sha256(json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
        result['items'] = [{'id': item['id'], 'tokens': [
            {'idx': token['idx'], 'surface': token['surface'], 'lemma': 'Ana' if token['surface'] == 'Ana' else 'leggere',
             'pos': 'PROPN' if token['surface'] == 'Ana' else 'VERB', 'gloss_de': 'Ana' if token['surface'] == 'Ana' else 'lesen',
             'context_gloss_de': 'Ana' if token['surface'] == 'Ana' else 'liest'} for token in item['tokens']]}]
        return result
    monkeypatch.setattr(client, 'request_annotation', annotate)
    with pytest.raises(SystemExit) as error:
        client.main()
    assert error.value.code == 1
    assert attempts == ['failed:0', 'success:0']
    folder = tmp_path / 'annotations'
    assert not (folder / 'it/failed.json').exists()
    assert (folder / 'it/success.json').exists()
    assert len(list((folder / '_batches/it').glob('*.json'))) == 1
    assert client.recorded_cost(folder / 'usage.jsonl') == pytest.approx(.12011)
    output = capsys.readouterr().out
    assert 'continuing' in output and 'Failed batches: 1' in output
    assert 'first:TOKEN_COUNT' in output and 'synthetic-key' not in output
    failure = json.loads(output.splitlines()[-1])
    assert set(failure) == {'lang', 'batch', 'error'} and failure['lang'] == 'it'
    assert len(failure['batch']) == 64 and all(c in '0123456789abcdef' for c in failure['batch'])


@pytest.mark.parametrize('provider_status,provider_error', [
    (400, 'INSUFFICIENT_CREDITS'), (401, 'authentication_error'), (402, 'billing_error'),
    (403, 'permission_error'), (404, 'not_found_error'), (413, 'request_too_large'),
])
def test_permanent_provider_errors_stop_before_any_retry_without_reflecting_body(monkeypatch, provider_status, provider_error):
    response = Mock(status_code=502)
    response.json.return_value = {'code': 'MODEL_FAILED', 'provider_status': provider_status,
        'provider_error': provider_error, 'message': 'do-not-disclose-secret'}
    post = Mock(return_value=response)
    monkeypatch.setattr(client.requests, 'post', post)
    reserved = []
    with pytest.raises(RuntimeError, match='permanent provider failure') as error:
        client.request_annotation('https://synthetic.invalid', {}, {}, reserved.append, threading.Event())
    assert not isinstance(error.value, client.AnnotationBatchError)
    assert reserved == [0] and post.call_count == 1 and response.close.call_count == 1
    assert f'provider_http={provider_status}' in str(error.value)
    assert f'provider_error={provider_error}' in str(error.value) and 'secret' not in str(error.value)


@pytest.mark.parametrize('body', [
    {'code': 'MODEL_FAILED', 'provider_status': ['secret'], 'provider_error': 'secret'},
    {'code': ['secret'], 'provider_status': True, 'provider_error': ['secret']},
])
def test_untrusted_provider_diagnostics_never_reflect_arbitrary_values(monkeypatch, body):
    response = Mock(status_code=502); response.json.return_value = body
    monkeypatch.setattr(client.requests, 'post', Mock(return_value=response))
    stop = Mock(); stop.is_set.return_value = False; stop.wait.return_value = False
    with pytest.raises(client.AnnotationBatchError) as error:
        client.request_annotation('https://synthetic.invalid', {}, {}, lambda _: None, stop)
    assert 'secret' not in str(error.value) and 'provider_http=' not in str(error.value)


@pytest.mark.parametrize('pattern,circuit', [([False] * 5, True), ([False, False, True, False, False, True], False)])
def test_main_circuit_breaks_after_three_consecutive_batches_and_success_resets_counter(monkeypatch, tmp_path, capsys, pattern, circuit):
    (tmp_path / 'inventory.json').write_text('{}')
    monkeypatch.setattr(client, 'CORPUS', tmp_path)
    row = {'sentence': 'Ana legge.', 'translation_de': 'Ana liest.', '_gap': (0, 3)}
    monkeypatch.setattr(client, 'corpus', lambda *_: [({'slug': f'd{i}'}, [row], f'source-{i}') for i in range(len(pattern))])
    monkeypatch.setattr(client.subprocess, 'run', Mock(return_value=Mock(returncode=0,
        stdout=json.dumps([{'name': 'service_role', 'api_key': 'synthetic-key'}]))))
    monkeypatch.setattr(client, 'configure_admin', Mock())
    monkeypatch.setattr(sys, 'argv', ['annotation', '--cli', 'synthetic-cli', '--project', 'synthetic', '--lang', 'it', '--workers', '1'])
    visited = []
    def annotate(_url, _headers, payload, reserve, stopped, **_kwargs):
        assert not stopped.is_set()
        number = int(payload['items'][0]['id'].split(':')[0][1:]); visited.append(number); reserve(0)
        if not pattern[number]:
            raise client.AnnotationBatchError('Annotation transient failure after three attempts: HTTP 502 MODEL_INVALID first:TOKEN_COUNT')
        _, result = envelope()
        result['input_sha256'] = hashlib.sha256(json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
        result['items'] = [{'id': item['id'], 'tokens': [{'idx': token['idx'], 'surface': token['surface'],
            'lemma': 'Ana' if token['surface'] == 'Ana' else 'leggere', 'pos': 'PROPN' if token['surface'] == 'Ana' else 'VERB',
            'gloss_de': 'Ana' if token['surface'] == 'Ana' else 'lesen',
            'context_gloss_de': 'Ana' if token['surface'] == 'Ana' else 'liest'} for token in item['tokens']]} for item in payload['items']]
        return result
    monkeypatch.setattr(client, 'request_annotation', annotate)
    if circuit:
        with pytest.raises(RuntimeError, match='circuit breaker'):
            client.main()
        assert visited == [0, 1, 2]
        assert client.recorded_cost(tmp_path / 'annotations/usage.jsonl') == pytest.approx(.12)
        assert 'Failed batches before circuit breaker: 3' in capsys.readouterr().out
    else:
        with pytest.raises(SystemExit) as error:
            client.main()
        assert error.value.code == 1 and visited == list(range(len(pattern)))
        assert 'Failed batches: 4' in capsys.readouterr().out
