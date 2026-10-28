"""Checkpointed admin-only annotation of synthetic, already reviewed corpus.

Credentials are captured from the authenticated Supabase CLI in memory only.
The Anthropic key stays in the Edge Function. Never logs response bodies on errors.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import deque
import hashlib
from datetime import datetime, timezone
import math
import os
from contextlib import contextmanager
import json
from pathlib import Path
import secrets
import tempfile
import subprocess
import threading
import time
import unicodedata

import requests

from build_multilingual_deck_drafts import CORPUS, POS, corpus
from sprachpipe.language_profiles import get_profile


def configure_admin(cli, project, token):
    """CLI reads its env file twice; a private FIFO keeps bytes off disk."""
    if os.name == 'nt':
        raise RuntimeError('This admin credential transport requires macOS or another POSIX host')
    with tempfile.TemporaryDirectory(prefix='editorial-admin-') as directory:
        fifo = Path(directory) / 'credentials.pipe'
        os.mkfifo(fifo, 0o600)
        stop = threading.Event()
        def feed():
            while not stop.is_set():
                try:
                    fd = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
                    try:
                        os.write(fd, ('EDITORIAL_ADMIN_TOKEN=' + token + '\n').encode())
                    finally:
                        os.close(fd)
                except OSError:
                    pass
                stop.wait(.2)
        writer = threading.Thread(target=feed, daemon=True)
        writer.start()
        try:
            result = subprocess.run([cli, 'secrets', 'set', '--env-file', str(fifo),
                                     '--project-ref', project], capture_output=True,
                                    text=True, timeout=60)
            if result.returncode:
                raise RuntimeError('Temporary editorial admin authentication setup failed')
        finally:
            stop.set()
            writer.join(timeout=2)


@contextmanager
def process_lock(path):
    """OS advisory lock survives crashes without stale-lock deletion races."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a+b') as handle:
        handle.seek(0, 2)
        if handle.tell() == 0:
            handle.write(b'0'); handle.flush()
        handle.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise RuntimeError('Another editorial annotation process is active') from None
        try:
            yield
        finally:
            handle.seek(0)
            if os.name == 'nt':
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def usage_cost(payload, result):
    if not isinstance(result, dict) or result.get('model') != 'claude-haiku-5-5' or result.get('contract') != 'editorial-token-annotation-v3':
        raise ValueError('Unexpected annotation contract')
    digest = hashlib.sha256(json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    if result.get('input_sha256') != digest:
        raise ValueError('Annotation input binding differs')
    return meter_cost(result.get('usage'))


def meter_cost(usage):
    if not isinstance(usage, dict) or set(usage) != {'input_tokens', 'output_tokens'}:
        raise ValueError('Missing annotation usage')
    for field, maximum in [('input_tokens', 200000), ('output_tokens', 16000)]:
        if type(usage[field]) is not int or not 0 <= usage[field] <= maximum:
            raise ValueError('Invalid annotation usage')
    return (usage['input_tokens'] * .1 + usage['output_tokens'] * .5) / 1e6


def recorded_cost(path):
    if not path.exists():
        return 0.0
    total = 0.0
    for line in path.read_text().splitlines():
        entry = json.loads(line)
        value = entry.get('usd')
        if type(value) not in (int, float) or not math.isfinite(value):
            raise ValueError('Invalid recorded annotation cost')
        kind = entry.get('kind')
        if kind == 'reservation' and value not in (.03, .04):
            raise ValueError('Invalid recorded reservation')
        if kind == 'settlement' and not -.04 <= value <= 0:
            raise ValueError('Invalid recorded settlement')
        if kind not in ('reservation', 'settlement'):
            raise ValueError('Unknown annotation ledger entry')
        total += value
        if total < -1e-8:
            raise ValueError('Negative annotation ledger balance')
    return max(0.0, total)


def append_usage(path, entry):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a') as handle:
        handle.write(json.dumps(entry) + '\n')
        handle.flush()
        os.fsync(handle.fileno())


class RatePacer:
    """Shared start pacing, two provider calls per batch, with global backoff."""
    def __init__(self, clock=time.monotonic, wall=time.time):
        self.clock, self.wall = clock, wall
        self.lock = threading.Lock()
        self.next_start = self.blocked_until = 0.0
        self.interval = 1.0
        self.input_estimate, self.output_estimate = 6000, 4000
        self.usage_window = deque(maxlen=32)
        self.limits = {}

    def acquire(self, stopped):
        while True:
            if stopped.is_set():
                raise RuntimeError('Annotation run stopped')
            with self.lock:
                now = self.clock()
                delay = max(self.next_start, self.blocked_until) - now
                if delay <= 0:
                    self.next_start = now + self.interval
                    return
            if stopped.wait(min(delay, 1.0)):
                raise RuntimeError('Annotation run stopped')

    def backoff(self, seconds):
        with self.lock:
            self.blocked_until = max(self.blocked_until, self.clock() + seconds)

    def observe(self, details, usage=None):
        if not isinstance(details, dict):
            return
        rates = details.get('rate_limits', {})
        if not isinstance(rates, dict):
            return
        with self.lock:
            if usage is not None:
                meter_cost(usage)
                self.usage_window.append((usage['input_tokens'], usage['output_tokens']))
                self.input_estimate = math.ceil(max(u[0] for u in self.usage_window) * 1.1)
                self.output_estimate = math.ceil(max(u[1] for u in self.usage_window) * 1.1)
            for family in ('requests', 'tokens', 'input-tokens', 'output-tokens'):
                for field in ('limit', 'remaining', 'reset'):
                    key = family + '-' + field
                    value = rates.get(key)
                    if field != 'reset':
                        if type(value) is int and 0 <= value <= 2 ** 53 - 1:
                            self.limits[key] = value
                    elif isinstance(value, str) and value.endswith('Z'):
                        try:
                            self.limits[key] = datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()
                        except ValueError:
                            pass
            estimates = {'requests': 2, 'input-tokens': self.input_estimate,
                         'output-tokens': self.output_estimate,
                         'tokens': self.input_estimate + self.output_estimate}
            interval = 1.0
            for family, estimate in estimates.items():
                limit = self.limits.get(family + '-limit', 0)
                if limit > 0:
                    interval = max(interval, 60 * estimate / (limit * .9))
                remaining = rates.get(family + '-remaining')
                reset = self.limits.get(family + '-reset')
                if type(remaining) is int and remaining < estimate and reset is not None:
                    delay = max(0, min(86400, reset - self.wall()))
                    self.blocked_until = max(self.blocked_until, self.clock() + delay)
            if interval > self.interval:
                self.next_start = max(self.next_start, self.clock() + interval)
            self.interval = interval


def error_usage(body):
    """Only a provider 429 explicitly accounting for every call releases cost."""
    if not isinstance(body, dict) or body.get('provider_status') != 429 or body.get('code') != 'PROVIDER_RATE_LIMIT':
        return None
    calls, known = body.get('provider_calls'), body.get('known_usage_calls')
    if body.get('usage_complete') is not True or type(calls) is not int or type(known) is not int or not 0 <= calls == known <= 2:
        return None
    try:
        return meter_cost(body.get('usage'))
    except ValueError:
        return None


def retry_delay(body, default=60.0):
    value = body.get('retry_after_seconds') if isinstance(body, dict) else None
    return float(value) if type(value) in (int, float) and math.isfinite(value) and 0 <= value <= 86400 else default


class AnnotationBatchError(RuntimeError):
    """Safe, bounded failure of one batch after all three attempts."""


def request_annotation(url, headers, payload, reserve, stopped, *, pacer=None, settle=None):
    for attempt in range(3):
        if stopped.is_set():
            raise RuntimeError('Annotation run stopped')
        if pacer is not None:
            pacer.acquire(stopped)
        if stopped.is_set():
            raise RuntimeError('Annotation run stopped')
        reserve(attempt)
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=115)
        except (requests.Timeout, requests.ConnectionError):
            if attempt == 2:
                raise AnnotationBatchError('Annotation transport failed after three attempts') from None
            if stopped.wait(2 ** (attempt + 1)):
                raise RuntimeError('Annotation run stopped') from None
            continue
        try:
            status = response.status_code
            if status in (429, 502, 503, 504):
                try:
                    body = response.json()
                except ValueError:
                    body = None
                code = body.get('code') if isinstance(body, dict) else None
                safe_code = code if isinstance(code, str) and code in {'PROVIDER_RATE_LIMIT', 'MODEL_FAILED', 'MODEL_INVALID', 'DEADLINE', 'REQUEST_FAILED', 'NOT_CONFIGURED'} else 'UNCLASSIFIED'
                provider_status = body.get('provider_status') if isinstance(body, dict) else None
                provider_error = body.get('provider_error') if isinstance(body, dict) else None
                provider_detail = ''
                if type(provider_status) is int and 400 <= provider_status <= 599:
                    provider_detail = f' provider_http={provider_status}'
                if isinstance(provider_error, str) and provider_error in {
                    'UNCLASSIFIED', 'INSUFFICIENT_CREDITS', 'invalid_request_error', 'authentication_error',
                    'billing_error', 'permission_error', 'not_found_error', 'conflict_error', 'request_too_large',
                    'rate_limit_error', 'api_error', 'timeout_error', 'overloaded_error',
                }:
                    provider_detail += f' provider_error={provider_error}'
                if safe_code == 'MODEL_FAILED' and type(provider_status) is int and 400 <= provider_status < 500 and provider_status != 429:
                    raise RuntimeError(f'Annotation permanent provider failure: HTTP {status} {safe_code}{provider_detail}')
                if pacer is not None:
                    pacer.observe(body)
                if status == 429:
                    cost = error_usage(body)
                    if cost is not None and settle is not None:
                        settle(attempt, cost, body['usage'])
                    delay = retry_delay(body)
                    if pacer is not None:
                        pacer.backoff(delay)
                else:
                    delay = 2 ** (attempt + 1)
                if attempt == 2:
                    diagnostic = body.get('diagnostic') if isinstance(body, dict) else None
                    safe_detail = ''
                    allowed_checks = {
                        'OUTPUT_SHAPE', 'ITEM_COUNT', 'ITEM_SHAPE', 'ITEM_ID', 'TOKEN_COUNT',
                        'TOKEN_SHAPE', 'TOKEN_IDX', 'TOKEN_SURFACE', 'TOKEN_POS', 'TOKEN_LEMMA',
                        'TOKEN_GLOSS', 'TOKEN_CONTEXT_GLOSS', 'TUPLE_SHAPE', 'REVIEW_CHECKED_IDS',
                        'REVIEW_ITEM_SHAPE', 'REVIEW_ITEM_ID', 'REVIEW_DUPLICATE_IDX',
                        'REVIEW_TOKEN_IDX', 'REVIEW_TOKEN_SURFACE', 'PROVIDER_JSON', 'PROVIDER_MODEL',
                        'PROVIDER_STOP_REASON', 'PROVIDER_CONTENT', 'PROVIDER_USAGE', 'ANNOTATION_JSON',
                    }
                    if (isinstance(diagnostic, dict)
                            and diagnostic.get('phase') in ('first', 'review')
                            and isinstance(diagnostic.get('check'), str)
                            and diagnostic['check'] in allowed_checks):
                        safe_detail = f" {diagnostic['phase']}:{diagnostic['check']}"
                    raise AnnotationBatchError(f'Annotation transient failure after three attempts: HTTP {status} {safe_code}{provider_detail}{safe_detail}')
                if (pacer is None or status != 429) and stopped.wait(delay):
                    raise RuntimeError('Annotation run stopped')
                continue
            if status != 200:
                raise RuntimeError(f'Annotation HTTP {status}; body withheld')
            try:
                result = response.json()
            except ValueError:
                raise RuntimeError('Annotation response is not valid JSON; body withheld') from None
            if pacer is not None:
                usage_cost(payload, result)
                pacer.observe(result.get('usage_limits'), result['usage'])
            return result
        finally:
            response.close()
    raise RuntimeError('Annotation retry limit reached')


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    tmp.replace(path)


def validate(items, result):
    output = result['items']
    if not isinstance(output, list) or [x['id'] for x in output] != [x['id'] for x in items]:
        raise ValueError('item IDs differ')
    checked = []
    for source, annotated in zip(items, output):
        expected = source['tokens']
        actual = annotated['tokens']
        if not isinstance(actual, list) or [x['idx'] for x in actual] != [x['idx'] for x in expected]:
            raise ValueError('token coverage differs')
        tokens = []
        for token, entry in zip(expected, actual):
            if set(entry) != {'idx', 'surface', 'lemma', 'pos', 'gloss_de', 'context_gloss_de'}:
                raise ValueError('invalid token annotation fields')
            if entry['surface'] != token['surface']:
                raise ValueError('token surface alignment differs')
            clean = dict(token)
            for field in ('lemma', 'pos', 'gloss_de', 'context_gloss_de'):
                raw = entry[field]
                if not isinstance(raw, str) or any(ord(c) < 32 or ord(c) == 127 for c in raw):
                    raise ValueError('invalid annotation')
                value = unicodedata.normalize('NFC', raw).strip()
                if not value or len(value) > 200:
                    raise ValueError('invalid annotation')
                clean[field] = value
            if clean['pos'] not in POS:
                raise ValueError('invalid UD POS')
            tokens.append(clean)
        checked.append({'id': source['id'], 'sentence': source['text'],
                        'translation_de': source['translation_de'], 'tokens': tokens})
    return checked


def assemble_deck(folder, lang, slug, source_sha256, batches):
    if not all(path.exists() for _, path in batches):
        return 0
    rows = []
    for payload, path in batches:
        result = json.loads(path.read_text())['response']
        usage_cost(payload, result)
        rows.extend(validate(payload['items'], result))
    save(folder / lang / (slug + '.json'), {'lang': lang, 'slug': slug,
         'source_sha256': source_sha256, 'rows': rows, 'human_review': False})
    return len(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cli', required=True)
    parser.add_argument('--project', required=True)
    parser.add_argument('--endpoint', default='editorial-annotate')
    parser.add_argument('--workers', type=int, default=6)
    parser.add_argument('--limit', type=int, default=0)
    parser.add_argument('--lang', choices=('pt-BR', 'nb', 'it', 'es'))
    parser.add_argument('--max-usd', type=float, default=8)
    args = parser.parse_args()
    if args.workers < 1 or args.workers > 32 or args.limit < 0 or not math.isfinite(args.max_usd) or args.max_usd <= 0:
        parser.error('workers must be 1..32, limit nonnegative and max-usd finite and positive')
    # stdout is never forwarded; only the service key is retained in memory.
    proc = subprocess.run([args.cli, 'projects', 'api-keys', '--project-ref', args.project,
                           '--output', 'json'], capture_output=True, text=True)
    if proc.returncode:
        raise RuntimeError('Authenticated Supabase CLI credential lookup failed')
    keys = json.loads(proc.stdout)
    secret = next(x['api_key'] for x in keys if x['name'] == 'service_role')
    del proc, keys
    admin_token = secrets.token_urlsafe(48)
    configure_admin(args.cli, args.project, admin_token)
    headers = {'Authorization': 'Bearer ' + secret, 'apikey': secret,
               'X-Editorial-Admin': admin_token}
    url = f'https://{args.project}.supabase.co/functions/v1/{args.endpoint}'
    inventory = json.loads((CORPUS / 'inventory.json').read_text())
    tasks, decks = [], []
    folder = CORPUS / 'annotations'
    for lang in ([args.lang] if args.lang else ('pt-BR', 'nb', 'it', 'es')):
        for deck, rows, sha in corpus(lang, inventory):
            items = []
            for index, row in enumerate(rows):
                tokens = [{k: t[k] for k in ('idx', 'surface', 'start_pos', 'end_pos')}
                          for t in get_profile(lang).tokenize(row['sentence'], row['_gap'])
                          if any(c.isalpha() for c in t['surface'])]
                items.append({'id': f'{deck["slug"]}:{index}', 'text': row['sentence'],
                              'translation_de': row['translation_de'], 'tokens': tokens})
            batches = []
            for offset in range(0, len(items), 4):
                part = items[offset:offset + 4]
                payload = {'lang': lang, 'items': part}
                digest = hashlib.sha256(json.dumps({'contract': 'editorial-token-annotation-v3', 'payload': payload}, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
                checkpoint = folder / '_batches' / lang / f'{digest}.json'
                task = (payload, checkpoint)
                batches.append(task)
                if not checkpoint.exists():
                    tasks.append(task)
                else:
                    cached = json.loads(checkpoint.read_text())['response']
                    usage_cost(payload, cached)
                    validate(part, cached)
            decks.append((lang, deck['slug'], sha, batches))
    deck_for_batch = {path: (lang, slug, sha, batches)
                      for lang, slug, sha, batches in decks for _, path in batches}
    for deck_args in decks:
        assemble_deck(folder, *deck_args)
    lock = threading.Lock()
    cost = 0.0
    completed = 0
    failures = []
    consecutive_failures = 0
    circuit_tripped = False
    usage_path = folder / 'usage.jsonl'
    if usage_path.exists():
        cost = recorded_cost(usage_path)
    stopped = threading.Event()
    pacer = RatePacer()
    def execute(task):
        nonlocal cost, completed, consecutive_failures, circuit_tripped
        payload, checkpoint = task
        def reserve(attempt):
            nonlocal cost
            with lock:
                if stopped.is_set():
                    raise RuntimeError('Annotation run stopped')
                if cost + .04 > args.max_usd:
                    stopped.set()
                    raise RuntimeError('Editorial budget reached')
                append_usage(usage_path, {'batch': checkpoint.stem, 'attempt': attempt,
                                         'kind': 'reservation', 'usd': .04})
                cost += .04
        def settle(attempt, usd, usage):
            nonlocal cost
            with lock:
                append_usage(usage_path, {'batch': checkpoint.stem, 'attempt': attempt,
                    'usage': usage, 'kind': 'settlement', 'reason': 'provider_rate_limit', 'usd': usd - .04})
                cost += usd - .04
        try:
            result = request_annotation(url, headers, payload, reserve, stopped, pacer=pacer, settle=settle)
            usd = usage_cost(payload, result)
            validate(payload['items'], result)
            with lock:
                # Persist output before releasing the conservative reservation.
                # A crash can overreserve cost, but never lose a paid checkpoint.
                save(checkpoint, {'response': result, 'human_review': False})
                append_usage(usage_path, {'batch': checkpoint.stem, 'usage': result['usage'],
                                         'kind': 'settlement', 'usd': usd - .04})
                cost += usd - .04
                assemble_deck(folder, *deck_for_batch[checkpoint])
                completed += 1
                if not circuit_tripped:
                    consecutive_failures = 0
                if completed % 25 == 0 or completed == 1:
                    print(f'Annotated {completed}/{len(tasks)} batches; recorded cost ${cost:.4f}', flush=True)
        except AnnotationBatchError as error:
            with lock:
                failures.append({'lang': payload['lang'], 'batch': checkpoint.stem,
                                 'error': str(error)})
                consecutive_failures += 1
                if consecutive_failures >= 3:
                    circuit_tripped = True
                    stopped.set()
                    raise RuntimeError('Annotation circuit breaker: three consecutive batches failed') from None
                print(f'Batch {checkpoint.stem} failed after bounded retries; continuing: {error}', flush=True)
        except Exception:
            stopped.set()
            raise
    selected = tasks[:args.limit] if args.limit else tasks
    print(f'Pending batches: {len(tasks)}; running: {len(selected)}', flush=True)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(execute, task) for task in selected]
        for future in as_completed(futures):
            try:
                future.result()
            except Exception:
                for queued in futures:
                    queued.cancel()
                if circuit_tripped:
                    print(f'Failed batches before circuit breaker: {len(failures)}', flush=True)
                    for failure in sorted(failures, key=lambda row: (row['lang'], row['batch'])):
                        print(json.dumps(failure, sort_keys=True), flush=True)
                    raise RuntimeError('Annotation circuit breaker: three consecutive batches failed') from None
                raise
    total = sum(assemble_deck(folder, *deck_args) for deck_args in decks)
    print(f'Persisted complete deck annotations for {total} sentences; cost ${cost:.4f}', flush=True)
    if failures:
        print(f'Failed batches: {len(failures)}; no output accepted for these batches', flush=True)
        for failure in sorted(failures, key=lambda row: (row['lang'], row['batch'])):
            print(json.dumps(failure, sort_keys=True), flush=True)
        raise SystemExit(1)


if __name__ == '__main__':
    with process_lock(CORPUS / 'annotations' / '.annotation.lock'):
        main()
