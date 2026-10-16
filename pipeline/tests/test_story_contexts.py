"""Controlled context update on the real internal story, without cloud calls."""
import copy
import json
from pathlib import Path
import pytest
from sprachpipe.curate import apply_targeted_patch
from sprachpipe.pack import build_rows

SOURCE = Path('pipeline/out/context_quality_applied_v1/pack.json')
PATCH = Path('pipeline/data/curation/story_contexts_v1.json')

@pytest.fixture(scope='module')
def reviewed():
    raw = SOURCE.read_bytes()
    patch = json.loads(PATCH.read_text())
    return raw, patch, apply_targeted_patch(raw, patch)


def test_only_five_sentence_review_fields_change_and_all_identities_survive(reviewed):
    raw, patch, final = reviewed
    old = json.loads(raw)
    for table in old:
        if table not in ('release', 'sentences'):
            assert final[table] == old[table], table
    changed = []
    for a, b in zip(old['sentences'], final['sentences']):
        if a != b:
            changed.append(a['ref'])
            original = copy.deepcopy(b)
            original['qa_report'].pop('story_practice_contexts')
            assert original == a
    assert len(changed) == 5
    assert sum(len(o['contexts']) for o in patch['operations']) == 14
    assert apply_targeted_patch(raw, patch) == final
    rows = build_rows(final)
    assert len(rows['deck_practice_targets']) == 402
    assert sum(bool(r.get('removed_in')) for r in rows['card_sentences']) == 530


@pytest.mark.parametrize('case', ['stale_tokens', 'stale_sentence', 'bad_index', 'wrong_sense', 'duplicate', 'noncontiguous', 'missing_annotation', 'wrong_target', 'no_translation', 'too_long', 'unknown_field'])
def test_invalid_context_updates_fail_closed(reviewed, case):
    raw, original, _ = reviewed
    patch = copy.deepcopy(original)
    op = patch['operations'][0]
    if case == 'stale_tokens': op['expect_tokens'][1]['start_pos'] += 1
    elif case == 'stale_sentence': op['expect_sentence']['translation_de'] = 'stale'
    elif case == 'bad_index': op['contexts'][0]['token_index'] = True
    elif case == 'wrong_sense': op['contexts'][0]['sense'] = 'other'
    elif case == 'duplicate': patch['operations'].append(copy.deepcopy(op))
    elif case == 'noncontiguous': op['contexts'][0]['sentence_refs'] = ['open-pocket/s1', 'open-pocket/s3']
    elif case == 'unknown_field': op['contexts'][0]['approved'] = True
    else:
        r = patch['operations'][-1]['contexts'][0]['replacement']
        if case == 'missing_annotation': r['tokens'][1].pop('sense')
        elif case == 'wrong_target': r['target_index'] = 0
        elif case == 'no_translation': r['translation_de'] = ''
        elif case == 'too_long':
            op['contexts'][0]['sentence_refs'] = ['open-pocket/s1','open-pocket/s2','open-pocket/s3']
    with pytest.raises(ValueError):
        apply_targeted_patch(raw, patch)


def test_source_window_offsets_and_same_identity_are_not_first_text_match(reviewed):
    _, _, final = reviewed
    sentence = next(s for s in final['sentences'] if s['ref'] == 'open-pocket/s5')
    bindings = sentence['qa_report']['story_practice_contexts']['bindings']
    for b in bindings:
        c = b['context']; t = c['tokens'][c['target_index']]
        assert c['text'][t['start_pos']:t['end_pos']] == b['surface']
        assert t['sense_id'] == b['sense_id']
        if b['surface'] != 'thanks':
            assert c['text'].startswith('Her train ticket')
            assert t['start_pos'] > b['source_start']


def test_future_authoring_gap_report_is_explicit_and_does_not_approve(reviewed):
    from sprachpipe.curate import story_authoring_gaps
    raw, _, final = reviewed
    source = json.loads(raw)
    before = copy.deepcopy(source)
    gaps = story_authoring_gaps(source)
    assert len([g for g in gaps if g['kind'] == 'editorial_context_missing']) == 14
    assert source == before
    assert [g['surface'] for g in story_authoring_gaps(final)] == ['Maya', 'Maya']
