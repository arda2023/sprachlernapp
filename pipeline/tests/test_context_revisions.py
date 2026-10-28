import copy
import json
from pathlib import Path

import pytest

from sprachpipe.context_revisions import (migrate_schema5, legacy_displays,
    assert_history_preserved, revise_context, context_payload)
from sprachpipe.pack import build_rows
from sprachpipe.export import export_sqlite
from sprachpipe.word_registry import digest
from targeted_fixture import fixture


@pytest.fixture
def base(tmp_path):
    return fixture(tmp_path)[0]


def test_schema5_preserves_old_ids_and_exact_reader_glosses(base, tmp_path):
    original = copy.deepcopy(base)
    old = build_rows(base)
    displays = legacy_displays(old)
    migrated = migrate_schema5(base)
    rows = build_rows(migrated)
    assert len(rows) == 23
    assert base == original
    assert_history_preserved(old, rows)
    for token in rows['sentence_tokens']:
        assert token['context_gloss_de'] == displays[token['id']]['historical']
        assert token['context_snapshot']['legacy_active_gloss'] == displays[token['id']]['active']
        assert token['context_snapshot']['story_gloss'] == displays[token['id']]['story_gloss']
    export_sqlite(migrated, tmp_path/'schema5.sqlite')
    assert migrate_schema5(migrated) == migrated


def test_translation_and_context_gloss_are_new_context_not_new_learning(base):
    work = migrate_schema5(base)
    before = build_rows(work)
    link = next(l for l in work['card_sentences'] if l['card']=='cut-other')
    sn = next(s for s in work['sentences'] if s['ref']==link['sentence'])
    tokens = copy.deepcopy([t for t in work['sentence_tokens'] if t['sentence']==sn['ref']])
    for token in tokens:
        token['context_snapshot'].pop('legacy', None)
    target = next(t for t in tokens if t.get('card')=='cut-other')
    target['context_gloss_de'] = 'hier kürzen'
    spec = {'text':sn['text'], 'translation_de':'Geänderte synthetische Übersetzung.',
            'tokens':tokens, 'gap':{'start_pos':link['gap_start'],'end_pos':link['gap_end']},
            'valid_alternatives':['run']}
    revise_context(work,'cut-other',spec,'editor-test')
    after = build_rows(work)
    assert before['cards'] == after['cards']
    assert len(after['sentences']) == len(before['sentences'])+1
    assert_history_preserved(before, after)
    new = after['sentences'][-1]
    assert new['revision_sha256'] == digest(context_payload(after,new['id']))
    assert new['text'] == sn['text'] and new['id'] != before['sentences'][-2]['id']
    bad=copy.deepcopy(work);bad['sentences'][-1]['translation_de']='tampered'
    with pytest.raises(ValueError,match='context revision'): build_rows(bad)
    after['sentence_tokens'][0]['context_gloss_de']='overwritten'
    with pytest.raises(ValueError,match='HISTORY_LOSS'): assert_history_preserved(before,after)


def test_legacy_export_shape_is_unchanged(base,tmp_path):
    import sqlite3
    export_sqlite(base,tmp_path/'legacy.sqlite')
    with sqlite3.connect(tmp_path/'legacy.sqlite') as db:
        assert len(db.execute("select name from sqlite_master where type='table'").fetchall())==22
        assert 'context_gloss_de' not in {r[1] for r in db.execute('pragma table_info(sentence_tokens)')}
    assert len(build_rows(base))==22


def test_cumulative_origins_and_skipped_release_preserve_edges(base):
    from sprachpipe.context_revisions import revise_story_context,correction_edge
    origins=json.loads(Path('test/fixtures/editor_story_origins.json').read_text())
    work=migrate_schema5(base);work['editor_history']['story_source_snapshots']=copy.deepcopy(origins)
    tokens=copy.deepcopy([t for t in base['sentence_tokens'] if t['sentence']=='other-story'])
    spec={'text':'They cut yesterday.','translation_de':'Synthetische Änderung C.',
          'tokens':tokens,'gap':{'start_pos':9,'end_pos':18},'reason':'Synthetic regression'}
    c=revise_story_context(work,origins[0]['source_key'],spec,'C',digest(origins[0]))
    first=copy.deepcopy(work['story_context_corrections']);assert len(first)==2
    assert {e['previous_revision'] for e in first}=={'synthetic-editor-a','synthetic-editor-b'}
    spec['translation_de']='Synthetische Endrevision D.'
    d=revise_story_context(work,origins[0]['source_key'],spec,'D',digest(c))
    assert len(work['story_context_corrections'])==3
    assert work['story_context_corrections'][:2]==first
    assert work['story_context_corrections'][-1]['previous_fingerprint']==c['source_fingerprint']
    assert work['story_context_corrections'][-1]['next_fingerprint']==d['source_fingerprint']
    build_rows(work)
    bad=copy.deepcopy(c);bad['practice_context']['sentence']['translation']='forged'
    with pytest.raises(ValueError,match='fingerprint'):correction_edge(bad,d,'D','bad')


def test_batch_freeze_matches_individual_context_hashes(base):
    from sprachpipe.authoring_service import freeze_new_context, freeze_new_contexts
    one=migrate_schema5(base)
    batch=copy.deepcopy(one)
    refs={s['ref'] for s in one['sentences']}
    for ref in refs:freeze_new_context(one,ref)
    freeze_new_contexts(batch,refs)
    assert one['sentences']==batch['sentences']
    assert one['sentence_tokens']==batch['sentence_tokens']


def test_registered_portuguese_v1_context_remains_valid_after_v2_default(monkeypatch):
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as author
    from sprachpipe.language_profiles import PROFILES,get_profile
    base=author.empty_pack('pt-BR','Portugiesisch')
    current=PROFILES['pt-BR']
    monkeypatch.setitem(PROFILES,'pt-BR',get_profile('pt-BR','pt-BR-editorial-v1'))
    work=author.materialize_draft(draft(base),base)
    before=build_rows(work)
    monkeypatch.setitem(PROFILES,'pt-BR',current)
    assert build_rows(work)==before
    work['sentences'][0]['translation_de']='Tampered.'
    with pytest.raises(ValueError,match='context revision'):build_rows(work)
