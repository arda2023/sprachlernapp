"""Deck contexts vs. story single-sentence policy, finding scope and review scope."""
import copy
import json
from pathlib import Path

import pytest

from sprachpipe.authoring_service import (AuthoringError, apply_operations, changed_refs,
    draft_content_hash, target_view, validate_draft)
from sprachpipe.editor.service import EditorService
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest
from targeted_fixture import fixture

DIALOGUE = 'Paper? They cut paper.'  # one fixed context, two grammatical sentences


@pytest.fixture
def setup(tmp_path):
    base = fixture(tmp_path)[0]
    source = tmp_path / 'source.json'
    source.write_text(json.dumps(base))
    service = EditorService(tmp_path / 'editor', source=source, asset_directory=tmp_path / 'assets')
    yield service, base
    service.close()


def dialogue_spec(base, text=DIALOGUE):
    """Reuses the confirmed fixture bindings of 'They cut paper.' at new offsets."""
    old = {t['surface']: t for t in target_view(base, 'cut-old')['context']['tokens']}
    tokens, pos = [], 0
    for i, surface in enumerate(['Paper', '?', 'They', 'cut', 'paper', '.']):
        if surface not in text[pos:]:
            continue
        start = text.index(surface, pos)
        source = old.get(surface) or old.get(surface.lower()) or old['.']
        token = {k: copy.deepcopy(v) for k, v in source.items() if k not in ('idx', 'start_pos', 'end_pos', 'surface')}
        token.update(idx=len(tokens), surface=surface, start_pos=start, end_pos=start + len(surface),
                     binding_status='confirmed', is_word=surface.isalpha())
        if surface != 'cut':
            token['card'] = None
        tokens.append(token)
        pos = start + len(surface)
    gap = text.index(' cut ') + 1
    return {'text': text, 'translation_de': 'Papier? Sie schneiden Papier.', 'tokens': tokens,
            'gap': {'start_pos': gap, 'end_pos': gap + 3}, 'valid_alternatives': [], 'reason': 'Regression'}


def revise(base, spec):
    return {'op_id': 'revise-dialogue', 'kind': 'revise_context', 'lang': 'en', 'target_ref': 'cut-old',
            'expect': target_view(base, 'cut-old')['expect'], 'payload': spec}


def test_profile_separates_story_single_sentence_from_deck_context():
    profile = get_profile('en')
    story = profile.validate_sentence(DIALOGUE, 'cut', 12, 15)
    deck = profile.validate_sentence(DIALOGUE, 'cut', 12, 15, single_sentence=False)
    assert [f.rule for f in story if f.level == 'error'] == ['sentence_count']
    assert [f for f in deck if f.level == 'error'] == []
    # Structural sentence rules are not relaxed for deck contexts.
    assert 'ending' in {f.rule for f in profile.validate_sentence('Paper? They cut paper', 'cut', 12, 15, single_sentence=False)}
    long = 'Paper? They cut paper for the school, the office, the shop and all the friends.'
    assert 'length' in {f.rule for f in profile.validate_sentence(long, 'cut', 12, 15, single_sentence=False)}
    assert 'gap' in {f.rule for f in profile.validate_sentence(DIALOGUE, 'cut', 7, 11, single_sentence=False)}


def test_story_correction_still_requires_exactly_one_sentence(base):
    from sprachpipe.context_revisions import migrate_schema5, revise_story_context
    origins = json.loads(Path('test/fixtures/editor_story_origins.json').read_text())
    work = migrate_schema5(base)
    work['editor_history']['story_source_snapshots'] = copy.deepcopy(origins)
    tokens = copy.deepcopy([t for t in base['sentence_tokens'] if t['sentence'] == 'other-story'])
    spec = {'text': 'They cut yesterday. It worked.', 'translation_de': 'Zwei Sätze.',
            'tokens': tokens, 'gap': {'start_pos': 9, 'end_pos': 18}, 'reason': 'Regression'}
    with pytest.raises(AuthoringError, match='Genau ein Übungssatz'):
        revise_story_context(work, origins[0]['source_key'], spec, 'C', digest(origins[0]))


@pytest.fixture
def base(tmp_path):
    return fixture(tmp_path)[0]


def test_fixed_two_part_deck_context_is_accepted_and_invalid_one_blocked(base):
    work = apply_operations(base, [revise(base, dialogue_spec(base))])
    assert target_view(work, 'cut-old')['context']['text'] == DIALOGUE
    draft = {'lang': 'en', 'translation_lang': 'de', 'revision': 1, 'base': {'pack_canonical_sha256': digest(base)},
             'add': {}, 'operations': [revise(base, dialogue_spec(base))], 'target_refs': ['cut-old'], 'reviews': []}
    result = validate_draft(draft, base)
    assert result['technical'] == 'valid', result['findings']
    assert not any(f['code'] == 'sentence_count' for f in result['findings'])
    assert result['changed_refs'] == ['cut-old']
    with pytest.raises(AuthoringError, match='must end'):
        apply_operations(base, [revise(base, dialogue_spec(base, 'Paper? They cut paper'))])


def test_unchanged_scope_keeps_base_status_and_review_covers_only_changes(setup):
    service, base = setup
    draft = service.new_draft('en', 'owner')
    assert len(draft['target_refs']) > 1
    view = target_view(base, 'cut-old')
    draft = service.save_operations(draft['draft_id'], [{'kind': 'set_solution_hint', 'lang': 'en', 'target_ref': 'cut-old',
        'expect': view['expect'], 'payload': {'translation_de': 'schneiden (korrigiert)'}}], service.store.etag(draft))
    assert changed_refs(draft) == ['cut-old']
    validation = validate_draft(draft, base)
    assert validation['technical'] == 'valid', validation['findings']
    # Synthetic report entries for unchanged tasks: attributed to that task only.
    findings = [{'code': 'i+1', 'severity': 'warn', 'message': 'Hinweis', 'location': {'record_ref': 'go-base'}},
                {'code': 'length', 'severity': 'error', 'message': 'Fehler', 'location': {'record_ref': 'run-base'}}]
    stored = dict(draft, validation=dict(validation, findings=findings, technical='invalid'))
    stored = service.store.save_draft(stored, service.store.etag(draft))
    items = {i['ref']: i for i in service.catalog('en', draft_id=draft['draft_id'], deck='owner', limit=100)['items']}
    assert (items['cut-old']['edited'], items['cut-old']['technical'], items['cut-old']['editorial']) == (True, 'valid', 'open')
    assert (items['go-base']['technical'], items['go-base']['warnings'], items['go-base']['editorial']) == ('base', 1, 'base')
    assert (items['run-base']['technical'], items['run-base']['editorial']) == ('invalid', 'base')
    assert items['they']['technical'] == 'base'
    # Real report again, then local editorial confirmation.
    stored = service.store.save_draft(dict(stored, validation=validation), service.store.etag(stored))
    reviewed = service.review(draft['draft_id'], {'reviewer': 'Test', 'reason': 'Nur Lösungshinweis geprüft.',
        'payload_sha256': draft_content_hash(stored)}, service.store.etag(stored))
    assert reviewed['reviews'][-1]['record_refs'] == ['cut-old']
    assert reviewed['validation']['editorial'] == 'approved'
    assert set(reviewed['target_refs']) - {'cut-old'}
