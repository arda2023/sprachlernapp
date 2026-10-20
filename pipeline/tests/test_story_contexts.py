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


@pytest.fixture(scope='module')
def single_sentence_reviewed():
    raw = Path('pipeline/out/story_contexts_v1/pack.json').read_bytes()
    patch = json.loads(Path('pipeline/data/curation/story_single_sentence_v1.json').read_text())
    return raw, patch, apply_targeted_patch(raw, patch)


def test_single_sentence_all_fourteen_exact_originals_and_eight_exact_corrections(single_sentence_reviewed):
    raw, patch, final = single_sentence_reviewed
    old = json.loads(raw)
    corrections = 0
    for op in patch['operations']:
        source = next(s for s in final['sentences'] if s['ref'] == op['expect_sentence']['ref'])
        previous = op['expect_sentence']['qa_report']['story_practice_contexts']['bindings']
        qa = source['qa_report']['story_practice_contexts']
        assert qa['format_version'] == 2
        for binding in qa['bindings']:
            context = binding['context']
            assert context['text'] == source['text']
            assert context['translation'] == source['translation_de']
            target = context['tokens'][context['target_index']]
            assert target['start_pos'] == binding['source_start']
            assert target['end_pos'] == binding['source_end']
            before = next(b for b in previous if b['token_index'] == binding['token_index'])
            if before['context'] != context:
                corrections += 1
                assert binding['correction'] == {'version':'story_single_sentence_v1',
                    'revision':'story_contexts_v1', 'context':before['context']}
            else:
                assert 'correction' not in binding
    assert corrections == 8
    for key in old:
        if key not in ('release','sentences'):
            assert old[key] == final[key], key
    for a,b in zip(old['sentences'],final['sentences']):
        if a != b:
            restored=copy.deepcopy(b)
            restored['qa_report']['story_practice_contexts']=a['qa_report']['story_practice_contexts']
            assert restored == a


@pytest.mark.parametrize('original', ['early.', 'early, early.', '😀 early.'])
def test_short_original_requires_fully_reviewed_replacement(single_sentence_reviewed, original):
    import hashlib
    from sprachpipe.annotate import tokenize
    raw, _, _ = single_sentence_reviewed
    pack=json.loads(raw)
    source=next(s for s in pack['sentences'] if s['ref']=='open-pocket/s1')
    replacement=copy.deepcopy(source)
    original_tokens=[t for t in pack['sentence_tokens'] if t['sentence']==source['ref']]
    early=next(t for t in original_tokens if t['surface']=='early')
    source.update(text=original,translation_de='Früh.' if original.count('early')==1 else 'Früh, früh.',qa_report={})
    ts=[]
    for t in tokenize(original):
        row={k:t[k] for k in ('idx','surface','start_pos','end_pos')}
        row['sentence']=source['ref']
        if t['is_word']: row.update(lemma=early['lemma'],sense=early['sense'])
        ts.append(row)
    pack['sentence_tokens']=[t for t in pack['sentence_tokens'] if t['sentence']!=source['ref']]+ts
    rows=build_rows(pack)
    sid=next(r['id'] for s,r in zip(pack['sentences'],rows['sentences']) if s['ref']==source['ref'])
    idx=next(t['idx'] for t in ts if t['surface']=='early')
    review={'token_index':idx,'surface':'early','sense':early['sense'],
        'reason':'Synthetischer Kurzsatz; early bedeutet früh.', 'sentence_refs':[source['ref']]}
    op={'op':'story_single_sentence_contexts','story_id':rows['stories'][0]['id'],
        'sentence_id':sid,'expect_sentence':copy.deepcopy(source),'expect_tokens':ts,
        'reason':'Synthetischer Kurzsatz-Test, keine reale Lieferung.','contexts':[review]}
    raw=json.dumps(pack,ensure_ascii=False).encode()
    patch={'format':'sprachapp.targeted-curation','format_version':1,
        'source_sha256':hashlib.sha256(raw).hexdigest(),'version':'synthetic-single',
        'reviewer':'Synthetische Testredaktion','operations':[op]}
    with pytest.raises(ValueError,match='requires reviewed replacement'): apply_targeted_patch(raw,patch)
    review.pop('sentence_refs')
    review['replacement']={'text':replacement['text'],'translation_de':replacement['translation_de'],
        'tokens':original_tokens,'target_index':early['idx'],
        'reason':'Frühe Ankunft am Bahnhof zeigt exakt early#frueh.',
        'justification':{'kind':'short_original','evidence':'Ein bzw. zwei Wörter im Original, keine vollständige Satzübung.'}}
    final=apply_targeted_patch(raw,patch)
    binding=next(s for s in final['sentences'] if s['ref']==source['ref'])['qa_report']['story_practice_contexts']['bindings'][0]
    assert binding['context']['text']=='Maya arrives at the station early.'
    target=binding['context']['tokens'][binding['context']['target_index']]
    assert binding['context']['text'][target['start_pos']:target['end_pos']]=='early'
    review['replacement']['tokens']=copy.deepcopy(original_tokens)
    review['replacement']['tokens'][early['idx']].pop('sense')
    with pytest.raises(ValueError): apply_targeted_patch(raw,patch)


@pytest.mark.parametrize('text', ['She walks home.', 'Then she walks.', 'She puts it inside.', 'Dr. Smith walks home.', '😀 She walks home.', 'They take off.'])
def test_three_words_pronouns_then_abbreviation_unicode_are_not_replacement_reasons(text):
    from sprachpipe.curate import _validate_story_single_sentence
    _validate_story_single_sentence({'ref':'s','text':text},{'sentence_refs':['s']},text)


@pytest.mark.parametrize('text', ['Take off.', 'Go!', 'Go, go!'])
def test_unmerged_multiword_target_and_punctuation_do_not_bypass_short_rule(text):
    from sprachpipe.curate import _validate_story_single_sentence
    with pytest.raises(ValueError,match='requires reviewed replacement'):
        _validate_story_single_sentence({'ref':'s','text':text},{'sentence_refs':['s']},text)


def test_neighbors_multiple_sentences_and_pronoun_only_replacement_are_rejected():
    from sprachpipe.curate import _validate_story_single_sentence
    source={'ref':'s','text':'Then she walks home.'}
    with pytest.raises(ValueError,match='unchanged original'):
        _validate_story_single_sentence(source,{'sentence_refs':['previous','s']},'Maya arrives. Then she walks home.')
    for kind in ('pronoun','narrative_context','style','short_original'):
        with pytest.raises(ValueError,match='justification kind'):
            _validate_story_single_sentence(source,{'replacement':{'justification':{'kind':kind,'evidence':'She refers to Maya.'}}},'Maya walks home.')
    with pytest.raises(ValueError,match='exactly one sentence'):
        _validate_story_single_sentence({'ref':'s','text':'Go!'}, {'replacement':{'justification':{'kind':'short_original','evidence':'One word.'}}}, 'We go home. We go early.')
