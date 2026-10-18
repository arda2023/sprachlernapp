"""Adopting a published release as editing base (local simulation; no cloud)."""
import copy
import hashlib
import json
import time
import uuid
from pathlib import Path

import pytest

from sprachpipe.authoring_service import AuthoringError, base_fingerprint, target_view, validate_draft
from sprachpipe.editor.published_base import INBOX
from sprachpipe.editor.publisher import FILES
from sprachpipe.editor.service import EditorService
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest
from targeted_fixture import fixture


class Channel:
    """Stands in for the publisher's read-only channel query."""
    def __init__(self, value): self.value = value
    def status(self): return {'configured': True, 'signed_in': True, 'expires_at': None}
    def channel(self, lang):
        if isinstance(self.value, Exception): raise self.value
        return copy.deepcopy(self.value)


def wait(service, job):
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        current = service.store.get('jobs', job['job_id'])
        if current['state'] not in ('queued', 'running'): return current
        time.sleep(.02)
    raise AssertionError('job did not finish')


def write_bundle(directory, pack):
    """Original-bundle layout with a server-style final manifest for the channel."""
    directory.mkdir(parents=True)
    profile = get_profile('en')
    raw = json.dumps(pack, ensure_ascii=False, indent=1).encode()
    registry, inventory, reviews = pack['word_registry']['snapshot'], {'tables': {}}, []
    files = {'content.sqlite': b'synthetic sqlite bytes', 'pack.json': raw,
             'registry.json': json.dumps(registry).encode(), 'history_inventory.json': json.dumps(inventory).encode(),
             'editorial_reviews.json': b'[]', 'provenance.json': b'[]', 'finalization_report.json': b'{}',
             'reader_report.json': b'{}'}
    local = {'format': 2, 'lang': 'en', 'translation_lang': 'de', 'version': pack['release']['version'],
             'schema_version': 5, 'profile_id': profile.id, 'profile_sha256': profile.sha256,
             'sha256': hashlib.sha256(files['content.sqlite']).hexdigest(), 'size_bytes': len(files['content.sqlite']),
             'pack_json_sha256': hashlib.sha256(raw).hexdigest(), 'registry_sha256': pack['word_registry']['sha256'],
             'history_inventory_sha256': digest(inventory), 'editorial_reviews_sha256': digest(reviews),
             'internal_test_pack': True, 'parent_release_id': None, 'required_features': ['immutable-contexts-v1'],
             'min_reader_version': 5, 'local_only': True}
    files['content.manifest.json'] = json.dumps(local).encode()
    assert set(files) == set(FILES)
    for name, data in files.items(): (directory / name).write_bytes(data)
    release_id = str(uuid.uuid4())
    final = {**{k: v for k, v in local.items() if k != 'local_only'}, 'pack_canonical_sha256': digest(pack),
             'release_id': release_id, 'channel': 'internal', 'generation': 1, 'parent_release_id': None,
             'parent_manifest_sha256': None, 'created_at': '2026-10-17T00:00:00Z'}
    return {'lang': 'en', 'channel': 'internal', 'generation': 1, 'release_id': release_id,
            'manifest_sha256': digest(final), 'manifest': final}


@pytest.fixture
def setup(tmp_path):
    base = fixture(tmp_path)[0]
    assert base['word_registry']['sha256'] == digest(base['word_registry']['snapshot'])
    source = tmp_path / 'source.json'
    source.write_text(json.dumps(base))
    service = EditorService(tmp_path / 'editor', source=source, asset_directory=tmp_path / 'assets')
    published = copy.deepcopy(base)
    published['release']['version'] = 'published-baseline-v1'
    channel = write_bundle(service.store.root / INBOX / 'windows-bundle', published)
    service.publisher = Channel(channel)
    yield service, base, published, channel
    service.close()


def draft_with_hint(service, base):
    draft = service.new_draft('en', 'owner')
    view = target_view(base, 'cut-old')
    return service.save_operations(draft['draft_id'], [{'kind': 'set_solution_hint', 'lang': 'en', 'target_ref': 'cut-old',
        'expect': view['expect'], 'payload': {'translation_de': 'schneiden (korrigiert)'}}], service.store.etag(draft))


def snapshot(root):
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in sorted((root / 'drafts').rglob('*')) if p.is_file()}


def test_verified_preview_then_explicit_adoption_keeps_drafts(setup):
    service, base, published, channel = setup
    draft = draft_with_hint(service, base)
    head, drafts = service.store.get('heads', 'en'), snapshot(service.store.root)
    job = wait(service, service.published_base_preview('en'))
    assert job['state'] == 'succeeded', job
    view = job['result']
    assert view['channel'] == {'generation': 1, 'release_id': channel['release_id'],
                               'manifest_sha256': channel['manifest_sha256'], 'version': 'published-baseline-v1'}
    assert view['fingerprint']['pack_canonical_sha256'] == digest(published) and not view['already_head']
    assert [d['draft_id'] for d in view['drafts_to_rebase']] == [draft['draft_id']]
    assert service.store.get('heads', 'en') == head  # preview never switches
    with pytest.raises(AuthoringError, match='ausdrücklich'):
        service.adopt_published_base({'preview_sha256': view['sha256'], 'accepted': False})
    done = wait(service, service.adopt_published_base({'preview_sha256': view['sha256'], 'accepted': True}))
    assert done['state'] == 'succeeded', done
    assert service.store.get('heads', 'en') == view['fingerprint'] == base_fingerprint(
        published, (service.store.root / INBOX / 'windows-bundle' / 'pack.json').read_bytes(), channel['manifest']['sha256'])
    assert digest(service.base('en')) == channel['manifest']['pack_canonical_sha256']
    assert snapshot(service.store.root) == drafts  # no draft rewritten
    again = wait(service, service.adopt_published_base({'preview_sha256': view['sha256'], 'accepted': True}))
    assert again['result']['status'] == 'already_head'


def test_rebase_keeps_change_and_drops_old_validation_and_review(setup):
    service, base, published, channel = setup
    draft = draft_with_hint(service, base)
    job = wait(service, service.validate(draft['draft_id'], service.store.etag(draft)))
    assert job['result']['validation']['technical'] == 'valid', job
    draft = service.store.load_draft(draft['draft_id'])
    draft = service.review(draft['draft_id'], {'reviewer': 'Test', 'reason': 'Synthetisch',
        'payload_sha256': job['result']['validation']['content_sha256']}, service.store.etag(draft))
    assert draft['validation']['editorial'] == 'approved'
    view = wait(service, service.published_base_preview('en'))['result']
    wait(service, service.adopt_published_base({'preview_sha256': view['sha256'], 'accepted': True}))
    rebased = service.rebase(draft['draft_id'], service.store.etag(draft))
    assert rebased['base'] == view['fingerprint'] and rebased['operations'] == draft['operations']
    assert rebased['validation'] is None and rebased['reviews'] == []
    result = validate_draft(rebased, service.base('en'))
    assert (result['technical'], result['editorial'], result['changed_refs']) == ('valid', 'open', ['cut-old'])
    assert result['base_sha256'] == channel['manifest']['pack_canonical_sha256']


def failed(service, job):
    result = wait(service, job)
    assert result['state'] == 'failed', result
    return result['error']['code']


def test_wrong_missing_or_damaged_bases_are_rejected(setup):
    service, base, published, channel = setup
    bundle = service.store.root / INBOX / 'windows-bundle'
    service.publisher = Channel(AuthoringError('AUTH_REQUIRED', 'Zuerst anmelden.', status=401))
    assert failed(service, service.published_base_preview('en')) == 'AUTH_REQUIRED'
    service.publisher = Channel({'generation': 0, 'release_id': None, 'manifest_sha256': None, 'manifest': None})
    assert failed(service, service.published_base_preview('en')) == 'PUBLISHED_BASE_NONE'
    service.publisher = Channel({**channel, 'manifest_sha256': '0' * 64})
    assert failed(service, service.published_base_preview('en')) == 'PUBLISHED_CHANNEL_INVALID'
    wrong = copy.deepcopy(channel); wrong['manifest']['profile_sha256'] = '1' * 64; wrong['manifest_sha256'] = digest(wrong['manifest'])
    service.publisher = Channel(wrong)
    assert failed(service, service.published_base_preview('en')) == 'PROFILE_UNSUPPORTED'
    service.publisher = Channel(channel)
    original = (bundle / 'pack.json').read_bytes()
    (bundle / 'pack.json').write_bytes(original + b' ')
    assert failed(service, service.published_base_preview('en')) == 'PUBLISHED_BUNDLE_MISMATCH'
    (bundle / 'pack.json').write_bytes(original)
    (bundle / 'reader_report.json').unlink()
    assert failed(service, service.published_base_preview('en')) == 'PUBLISHED_BUNDLE_INCOMPLETE'
    bundle.rename(bundle.with_name('elsewhere'))
    (service.store.root / INBOX).rename(service.store.root / 'not-inbox')
    assert failed(service, service.published_base_preview('en')) == 'PUBLISHED_BUNDLE_MISSING'
    assert service.store.get('heads', 'en')['version'] == base['release']['version']


def test_adoption_aborts_without_replacing_base(setup, monkeypatch):
    service, base, published, channel = setup
    head = service.store.get('heads', 'en')
    view = wait(service, service.published_base_preview('en'))['result']
    adopt = lambda: service.adopt_published_base({'preview_sha256': view['sha256'], 'accepted': True})
    # Newer publication between preview and confirmation.
    newer = copy.deepcopy(channel); newer['generation'] = newer['manifest']['generation'] = 2
    newer['manifest_sha256'] = digest(newer['manifest']); service.publisher = Channel(newer)
    assert failed(service, adopt()) == 'PUBLISHED_CHANNEL_CHANGED'
    service.publisher = Channel(channel)
    # Bundle bytes replaced after preview.
    registry = service.store.root / INBOX / 'windows-bundle' / 'registry.json'
    original = registry.read_bytes(); registry.write_bytes(b'{"words":[]}')
    assert failed(service, adopt()) == 'PUBLISHED_BUNDLE_MISMATCH'
    registry.write_bytes(original)
    # Interrupted write: the head pointer is the commit point.
    put = service.store.put
    def broken(kind, identifier, value):
        if kind == 'heads': raise OSError('disk full')
        return put(kind, identifier, value)
    monkeypatch.setattr(service.store, 'put', broken)
    assert wait(service, adopt())['state'] == 'failed'
    monkeypatch.setattr(service.store, 'put', put)
    assert service.store.get('heads', 'en') == head
    # Local head changed after preview.
    other = copy.deepcopy(base); other['release']['version'] = 'other-local'
    service.install_base(other)
    assert failed(service, adopt()) == 'BASE_CHANGED'
    with pytest.raises(AuthoringError, match='Vorschau'):
        service.adopt_published_base({'preview_sha256': 'f' * 64, 'accepted': True})
