"""Technical exchange/annotation risks; synthetic three-sentence fixture only."""
import copy
import hashlib
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from import_editorial_patch import (
    annotate_local, digest, make_plan, verify_exchange, validate_work, main, save, import_patch,
)
from sprachpipe.curate import CurationError, curate, finalize
from sprachpipe.ids import stable_id
from sprachpipe.pack import build_rows
from sprachpipe.generate import gap_offsets
from test_curate import make_pack, GO


def fixture():
    source = make_pack([GO])
    source['cards'][0]['translation_de'] = 'ging'
    source['audio_assets'] = [{'owner_kind': 'sentence', 'owner_id': stable_id(
        'sentences', lang='en', text=source['sentences'][0]['text']), 'path': 'old.wav'}]
    raw = json.dumps(source, ensure_ascii=False).encode()
    rows = build_rows(source)
    card = source['cards'][0]
    operations, records = [], []
    for i, (s, cs) in enumerate(zip(source['sentences'], source['card_sentences'])):
        before = {k: s[k] for k in ('text', 'translation_de')}
        before.update({k: cs[k] for k in ('gap_start', 'gap_end', 'accepted', 'valid_alternatives')})
        after = copy.deepcopy(before)
        if i == 0:
            after.update(text='She went to town.', translation_de='Sie ging in die Stadt.', valid_alternatives=[])
            after['gap_start'], after['gap_end'] = gap_offsets(after['text'], card['form'])
        elif i == 1:
            after.update(translation_de='Wir gingen zum Park.', valid_alternatives=[])
        else:
            after['valid_alternatives'] = ['walked']
        sid = stable_id('sentences', lang='en', text=after['text'])
        op = {'op_id': f'op{i}', 'card_ref': card['ref'], 'sentence_ref': s['ref'],
              'card_id': rows['cards'][0]['id'], 'sense_id': rows['senses'][0]['id'],
              'lemma_id': rows['lemmas'][0]['id'], 'sentence_position': cs['position'],
              'old_sentence_id': rows['sentences'][i]['id'], 'new_sentence_id': sid,
              'new_card_sentence_id': stable_id('card_sentences', card_id=rows['cards'][0]['id'], sentence_id=sid),
              'expect': before, 'new': after, 'expect_sentence_row_sha256': digest(s),
              'expect_link_row_sha256': digest(cs), 'reason': 'Synthetic editorial decision',
              'changed_fields': [k for k in before if before[k] != after[k]]}
        operations.append(op)
        records.append({'card_ref': card['ref'], 'sentence_ref': s['ref'], 'card_id': op['card_id'],
                        'old_sentence_id': op['old_sentence_id'], 'proposed_sentence_id': sid,
                        'before': before, 'after': after, 'status': ['rewrite', 'translation', 'alternatives'][i]})
    stats = {'sentence_pairs_read': 3, 'sentence_records_changed': 3, 'english_replacements': 1,
             'unchanged_sentence_records': 0, 'held_sentence_records': 0,
             'translation_only_or_translation_and_alternatives': 1, 'alternatives_only': 1, 'metadata_changes': 1}
    patch = {'format': 'sprachapp.editorial-patch', 'format_version': 1,
             'source': {'sha256': hashlib.sha256(raw).hexdigest(), 'canonical_json_sha256': digest(source),
                        'release': source['release'], 'lang': 'en',
                        'counts': {k: len(v) for k, v in source.items() if isinstance(v, list)}},
             'reviewer': 'model, not human', 'patch_id': 'fixture', 'stats': stats,
             'sentence_operations': operations, 'card_recommendations': [],
             'metadata_operations': [{'table': 'cards', 'ref': card['ref'], 'field': 'translation_de',
                                      'expect': 'ging', 'new': 'ging (Vergangenheit)', 'reason': 'fixture',
                                      'affected_card_refs': [card['ref']]}]}
    corpus = {'source_sha256': patch['source']['sha256'], 'stats': stats, 'records': records}
    return source, raw, patch, corpus


def working():
    source, raw, patch, corpus = fixture()
    verify_exchange(raw, patch, corpus)
    plan = make_plan(source, patch)
    work, log = curate({'source': source}, plan, plan['card_meta'])
    return source, patch, work, log


def test_exact_or_canonical_source_but_no_fuzzy_matching():
    source, raw, patch, corpus = fixture()
    assert verify_exchange(raw, patch, corpus)[1] == {'rewrite': 1, 'translation': 1, 'alternatives': 1}
    assert verify_exchange(json.dumps(source, indent=4).encode(), patch, corpus)[0] == source
    source['sentences'][0]['translation_de'] += '!'
    with pytest.raises(CurationError, match='hash mismatch'):
        verify_exchange(json.dumps(source).encode(), patch, corpus)


@pytest.mark.parametrize('mutation', ['row', 'op_duplicate', 'meta_duplicate', 'coverage', 'status', 'id'])
def test_exchange_rejects_inconsistent_evidence(mutation):
    _, raw, patch, corpus = fixture()
    if mutation == 'row':
        patch['sentence_operations'][0]['expect_sentence_row_sha256'] = 'wrong'
    elif mutation == 'op_duplicate':
        patch['sentence_operations'].append(copy.deepcopy(patch['sentence_operations'][0]))
    elif mutation == 'meta_duplicate':
        patch['metadata_operations'].append(copy.deepcopy(patch['metadata_operations'][0]))
    elif mutation == 'coverage':
        corpus['records'].pop()
    elif mutation == 'status':
        corpus['records'][0]['status'] = 'keep'
    else:
        patch['sentence_operations'][0]['card_id'] = 'wrong'
    with pytest.raises(CurationError):
        verify_exchange(raw, patch, corpus)


def test_new_english_drops_old_evidence_but_translation_preserves_identity_tokens():
    source, patch, work, log = working()
    changed = work['sentences'][0]
    assert changed['model'] is None and changed['qa_status'] == 'editorial_reviewed'
    assert 'alternative_check' not in changed['qa_report']
    assert not any(t['sentence'] == changed['ref'] for t in work['sentence_tokens'])
    assert work['audio_assets'] == []
    assert log['sentence_operations'][0]['history']['audio'][0]['path'] == 'old.wav'
    assert log['sentence_operations'][0]['history']['sentence']['qa_status'] == 'ok'
    original = source['sentences'][1]
    translated = work['sentences'][1]
    assert stable_id('sentences', lang='en', text=original['text']) == stable_id(
        'sentences', lang='en', text=translated['text'])
    assert [dict(t, sentence='source/'+t['sentence']) for t in source['sentence_tokens'] if t['sentence'] == original['ref']] == [
        t for t in work['sentence_tokens'] if t['sentence'] == translated['ref']]
    assert [cs['accepted'] for cs in work['card_sentences']] == [cs['accepted'] for cs in source['card_sentences']]
    assert [cs['valid_alternatives'] for cs in work['card_sentences']] == [[], [], ['walked']]
    assert source['sentences'][0]['qa_status'] == 'ok'  # input not mutated
    with pytest.raises(CurationError, match='pending'):
        finalize(work)
    with pytest.raises(ValueError, match='pending'):
        build_rows(work)


def test_surface_candidates_are_never_automatically_accepted():
    source, patch, work, _ = working()
    records, pending = annotate_local(work, source, [])
    went = next(r for r in pending if r['surface'] == 'went')
    assert went['target'] and len(went['candidates']) == 1
    assert all(t['sense'] is None for t in work['sentence_tokens'] if t['sentence'] == went['sentence'])
    assert len(pending) == 4
    assert validate_work(work, source, patch)['changed_sentence_ids'] == 1


def test_explicit_target_assignment_and_stale_assignment_rejected():
    source, patch, work, _ = working()
    op = patch['sentence_operations'][0]
    choice = {'op_id': 'op0', 'idx': 1, 'surface': 'went', 'sentence_id': op['new_sentence_id'],
              'lemma': 'go/VERB', 'sense': 'go/VERB|go#gehen', 'gloss_de': 'ging', 'reason': 'context'}
    _, pending = annotate_local(work, source, [choice])
    assert len(pending) == 3
    token = next(t for t in work['sentence_tokens'] if t['sentence'].startswith('chat_editorial_v1/') and t['surface'] == 'went')
    assert token['card'] == source['cards'][0]['ref']
    source, patch, work, _ = working()
    choice['sentence_id'] = 'old'
    with pytest.raises(CurationError, match='precondition'):
        annotate_local(work, source, [choice])


def test_new_form_gloss_uses_existing_annotation_constructor():
    source, patch, work, _ = working()
    op = patch['sentence_operations'][0]
    choice = {'op_id': 'op0', 'idx': 3, 'surface': 'town', 'sentence_id': op['new_sentence_id'],
              'annotation': {'lemma': 'town', 'pos': 'NOUN', 'gloss_de': 'Stadt'}, 'reason': 'local context'}
    annotate_local(work, source, [choice])
    assert any(s['ref'] == 'town/NOUN|town#stadt' for s in work['senses'])
    assert work['curation']['annotation_glosses'][0]['gloss_de'] == 'Stadt'


def test_existing_output_is_never_modified(tmp_path):
    sentinel = tmp_path/'keep.txt'
    sentinel.write_text('keep')
    assert main(['--out', str(tmp_path)]) == 2
    assert sentinel.read_text() == 'keep'


def test_offline_partial_import_persists_precise_blockers_and_refuses_export(tmp_path, monkeypatch):
    source, raw, patch, corpus = fixture()
    source_path, patch_path, corpus_path, plan_path = [tmp_path/n for n in
        ('source.json', 'patch.json', 'corpus.json', 'plan.json')]
    source_path.write_bytes(raw)
    save(patch_path, patch)
    save(corpus_path, corpus)
    plan = make_plan(source, patch)
    work, _ = curate({'source': source}, plan, plan['card_meta'])
    _, missing = annotate_local(work, source, [])
    save(plan_path, {'curation': plan, 'token_decisions': [], 'dictionary_resolutions': [],
        'exchange_sha256': hashlib.sha256(patch_path.read_bytes()).hexdigest(),
        'corpus_sha256': hashlib.sha256(corpus_path.read_bytes()).hexdigest(),
        'open_token_decisions': [{k: t[k] for k in ('op_id', 'idx', 'surface')} | {'reason': 'unreviewed context'}
                                 for t in missing]})
    monkeypatch.setitem(sys.modules, 'sprachpipe.llm', None)
    out = tmp_path/'new'
    assert import_patch(source_path, patch_path, corpus_path, plan_path, out) == 1
    assert source_path.read_bytes() == raw
    assert not (out/'pack.json').exists() and not (out/'content.sqlite').exists()
    report = json.loads((out/'import_report.json').read_text(encoding='utf8'))
    assert report['annotation']['open_words'] == 4
    assert report['ai_calls'] == 0 and not report['dictionary_complete']
    assert all(t['reason'] == 'unreviewed context' for t in json.loads(
        (out/'open_annotations.json').read_text(encoding='utf8')))


def finish_fixture(tmp_path):
    source, raw, patch, corpus = fixture()
    plan = make_plan(source, patch)
    work, _ = curate({'source': source}, plan, plan['card_meta'])
    _, missing = annotate_local(work, source, [])
    saved = {'curation': plan, 'token_decisions': [], 'dictionary_resolutions': [],
             'open_token_decisions': [{k: t[k] for k in ('op_id', 'idx', 'surface')} | {'reason': 'open'}
                                     for t in missing]}
    op = patch['sentence_operations'][0]
    text = 'She went home.'
    start, end = gap_offsets(text, 'went')
    sid = stable_id('sentences', lang='en', text=text)
    vocabulary = {
        'lemmas': [{'ref': 'she/PRON', 'lemma': 'she', 'pos': 'PRON'},
                   {'ref': 'home/ADV', 'lemma': 'home', 'pos': 'ADV'}],
        'senses': [
            {'ref': 'she/PRON|she#feminine', 'lemma': 'she/PRON', 'sense_key': 'she#feminine',
             'gloss_de': 'sie', 'definition_de': 'Eine weibliche Person als Subjekt.'},
            {'ref': 'home/ADV|home#homeward', 'lemma': 'home/ADV', 'sense_key': 'home#homeward',
             'gloss_de': 'heimwärts', 'definition_de': 'Richtung zum eigenen Zuhause.'}],
        'forms': [{'form': 'she', 'sense': 'she/PRON|she#feminine', 'gloss_de': 'sie'},
                  {'form': 'home', 'sense': 'home/ADV|home#homeward', 'gloss_de': 'nach Hause'}],
    }
    choices = []
    for idx, surface, sense, gloss in [(0, 'She', 'she/PRON|she#feminine', 'sie'),
                                      (1, 'went', source['cards'][0]['sense'], 'ging'),
                                      (2, 'home', 'home/ADV|home#homeward', 'nach Hause')]:
        choices.append({'op_id': 'op0', 'idx': idx, 'surface': surface, 'sentence_id': sid,
                        'lemma': sense.split('|')[0], 'sense': sense, 'gloss_de': gloss, 'reason': 'context'})
    supplement = {'format': 'sprachapp.editorial-finish', 'format_version': 1, 'version': 'test_finish',
                  'base_plan_sha256': digest(saved), 'working_state_sha256': digest(work),
                  'working_state_path': str(tmp_path/'old_work.json'), 'provenance': {'new_vertex_qa': False},
                  'sentence_replacements': [{'op_id': 'op0', 'source_ref': op['sentence_ref'],
                    'expected_sentence_id': op['new_sentence_id'], 'expect': op['new'],
                    'new': {'text': text, 'translation_de': 'Sie ging nach Hause.', 'gap_start': start,
                            'gap_end': end, 'accepted': ['went'], 'valid_alternatives': []}, 'reason': 'new wording'}],
                  'token_decisions': choices, 'token_replacements': [],
                  'resolved_open_tokens': saved['open_token_decisions'], 'vocabulary': vocabulary}
    return source, raw, patch, corpus, saved, work, supplement


def test_finish_invalidates_interim_annotations_and_separates_definition(tmp_path):
    from import_editorial_patch import apply_finish
    source, _, patch, _, saved, old, finish = finish_fixture(tmp_path)
    before = copy.deepcopy(old)
    patch, saved, history = apply_finish(source, patch, saved, finish, old)
    plan = make_plan(source, patch)
    work, _ = curate({'source': source}, plan, plan['card_meta'])
    records, missing = annotate_local(work, source, saved['token_decisions'], finish['vocabulary'])
    assert not missing and old == before
    assert history[0]['sentence']['text'] == 'She went to town.'
    assert [r['surface'] for r in records] == ['She', 'went', 'home', '.']
    assert 'to' not in [r['surface'] for r in records]
    se = next(s for s in work['senses'] if s['ref'] == 'home/ADV|home#homeward')
    assert se['definition_de'] == 'Richtung zum eigenen Zuhause.'
    assert next(g for g in work['curation']['annotation_glosses'] if g['form'] == 'home')['gloss_de'] == 'nach Hause'
    assert work['sentences'][0]['qa_report']['editorial']['checked']['text'] == 'She went home.'
    assert work['sentences'][0]['model'] is None
    assert validate_work(work, source, patch)['cards_unchanged'] == 1


@pytest.mark.parametrize('mutation', ['hash', 'text', 'id', 'missing', 'stale', 'overwrite', 'open'])
def test_finish_rejects_inconsistent_or_stale_decisions(tmp_path, mutation):
    from import_editorial_patch import apply_finish
    source, _, patch, _, saved, old, finish = finish_fixture(tmp_path)
    if mutation == 'hash': finish['working_state_sha256'] = 'wrong'
    elif mutation == 'text': finish['sentence_replacements'][0]['expect'] = {}
    elif mutation == 'id': finish['sentence_replacements'][0]['expected_sentence_id'] = 'wrong'
    elif mutation == 'missing': finish['token_decisions'].pop()
    elif mutation == 'stale': finish['token_decisions'][0]['sentence_id'] = 'old'
    elif mutation == 'open': finish['resolved_open_tokens'] = []
    else: finish['vocabulary']['senses'].append(copy.deepcopy(source['senses'][0]))
    with pytest.raises(CurationError):
        patch, saved, _ = apply_finish(source, patch, saved, finish, old)
        plan = make_plan(source, patch)
        work, _ = curate({'source': source}, plan, plan['card_meta'])
        annotate_local(work, source, saved['token_decisions'], finish['vocabulary'])


def test_complete_finish_export_roundtrip_is_offline_and_source_preserving(tmp_path, monkeypatch):
    from finalize_curation import check_sqlite
    source, raw, patch, corpus, saved, old, finish = finish_fixture(tmp_path)
    paths = {name: tmp_path/(name+'.json') for name in ('source', 'patch', 'corpus', 'plan', 'finish')}
    paths['source'].write_bytes(raw)
    save(paths['patch'], patch); save(paths['corpus'], corpus)
    saved.update(exchange_sha256=hashlib.sha256(paths['patch'].read_bytes()).hexdigest(),
                 corpus_sha256=hashlib.sha256(paths['corpus'].read_bytes()).hexdigest())
    finish['base_plan_sha256'] = digest(saved)
    save(paths['plan'], saved); save(paths['finish'], finish)
    save(Path(finish['working_state_path']), old)
    monkeypatch.setitem(sys.modules, 'sprachpipe.llm', None)
    before = {p: p.read_bytes() for p in paths.values()}
    out = tmp_path/'export'
    assert import_patch(paths['source'], paths['patch'], paths['corpus'], paths['plan'], out, paths['finish']) == 0
    final = json.loads((out/'pack.json').read_text(encoding='utf8'))
    report = json.loads((out/'finalization_report.json').read_text(encoding='utf8'))
    assert final['release']['version'] == 'test_finish' and 'INTERNES TEST-PACK' in final['release']['notes']
    assert report['status'] == 'ok' and report['internal_test_pack'] and report['ai_calls'] == 0
    assert check_sqlite(out/'content.sqlite', build_rows(final)) == report['sqlite_counts']
    assert all(p.read_bytes() == b for p, b in before.items())
