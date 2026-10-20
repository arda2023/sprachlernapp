import copy
import json
import sqlite3
import pytest
from pathlib import Path
from targeted_fixture import fixture
from sprachpipe.curate import apply_targeted_patch
from sprachpipe.pack import build_rows
from sprachpipe.export import export_sqlite
from sprachpipe.learning_groups import validate_learning
from import_editorial_patch import main


@pytest.fixture(scope='module')
def data(tmp_path_factory):
    return fixture(tmp_path_factory.mktemp('targeted'))


def test_cli_history_form_only_and_unchanged_rows(data, tmp_path):
    source,raw,patch=data
    original=copy.deepcopy(patch)
    final=apply_targeted_patch(raw,patch)
    assert patch==original and json.loads(raw)==source
    assert final==apply_targeted_patch(raw,patch)
    old,new=build_rows(source),build_rows(final)
    for table in ('deck_words','word_aliases','deck_cards','form_targets','deck_practice_targets','card_lexical_targets','lexical_targets'):
        assert old[table]==new[table]
    for table in old:
        if table=='content_releases':continue
        assert {r.get('id',r.get('code')) for r in old[table]} <= {r.get('id',r.get('code')) for r in new[table]}
    for op in patch['operations'][:2]:
        historic=next(l for l in new['card_sentences'] if l['sentence_id']==op['sentence_id'] and l['card_id']==op['card_id'])
        assert historic['removed_in']==patch['version'] and historic['replaced_by']
        assert len([l for l in new['card_sentences'] if l['card_id']==op['card_id'] and not l.get('removed_in')])==1
        for table in ('sentences','sentence_tokens'):
            rows=[r for r in old[table] if r.get('sentence_id',r.get('id'))==op['sentence_id']]
            assert rows and all(r in new[table] for r in rows)
    assert next(c for c in final['cards'] if c['ref']=='cut-past')['introduction_scope']=='form_only'
    before=tmp_path/'before.json';before.write_bytes(raw)
    path=tmp_path/'patch.json';path.write_text(json.dumps(patch))
    out=tmp_path/'export'
    assert main(['--source',str(before),'--targeted',str(path),'--out',str(out)])==0
    with sqlite3.connect(out/'content.sqlite') as db:
        assert {r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='index'")} >= {'idx_sentence_tokens_active_sentence_idx','idx_dictionary_forms_active_lookup'}
    assert main(['--source',str(out/'pack.json'),'--targeted',str(path),'--out',str(tmp_path/'repeat')])==2
    assert not (tmp_path/'repeat').exists()
    # Checked-in SQL fixtures consumed by Dart are exact exports of this path.
    for name,pack in [('before',source),('after',final)]:
        file=tmp_path/(name+'.sqlite');export_sqlite(pack,file)
        with sqlite3.connect(file) as db:
            db.execute("UPDATE content_releases SET created_at='2026-10-16T00:00:00Z'")
            dump='\n'.join(db.iterdump())+'\n'
        assert dump==Path('test/fixtures/targeted_curation_'+name+'.sql').read_text()


@pytest.mark.parametrize('case', ['hash','card','sentence','link','duplicate','unknown','unknown_op','missing_target','annotation','unknown_token','form_function','no_ops'])
def test_rejects_invalid_patch(data,case):
    _,raw,original=data;patch=copy.deepcopy(original);op=patch['operations'][0]
    if case=='hash':patch['source_sha256']='0'*64
    elif case=='card':op['expect_card']['translation_de']='stale'
    elif case=='sentence':op['expect_sentence']['text']='stale'
    elif case=='link':op['expect_link']['position']=9
    elif case=='duplicate':patch['operations'].append(copy.deepcopy(op))
    elif case=='unknown':op['implicit_approval']=True
    elif case=='unknown_op':op['op']='merge'
    elif case=='missing_target':op['card_id']='absent'
    elif case=='annotation':op['tokens'].pop()
    elif case=='unknown_token':op['tokens'][0]['unknown']='bad'
    elif case=='form_function':next(t for t in patch['operations'][1]['tokens'] if t.get('form_target')).pop('form_target')
    elif case=='no_ops':patch['operations']=[]
    with pytest.raises(ValueError):apply_targeted_patch(raw,patch)


def test_retired_groups_stay_strict(data):
    source,_,_=data;cards=build_rows(source)['cards'];card=copy.deepcopy(cards[-2])
    card['removed_in']='test';validate_learning([card])
    for bad in ('replacement','other_member','active_child','foreign_head'):
        rows=[copy.deepcopy(card)]
        if bad=='replacement':rows[0]['replaced_by']='other'
        elif bad in ('other_member','active_child'):
            other=copy.deepcopy(card);other['id']='other'
            if bad=='active_child':other.pop('removed_in')
            rows.append(other)
        else:rows[0]['learning']['primary_card_id']='absent'
        with pytest.raises(ValueError):validate_learning(rows)


def test_atomic_invalid_and_unfinished_never_replace(data,tmp_path):
    source,raw,patch=data;path=tmp_path/'good.sqlite';export_sqlite(source,path);before=path.read_bytes()
    final=apply_targeted_patch(raw,patch)
    final['curation']={'pending':[{'kind':'annotation'}]}
    with pytest.raises(ValueError):export_sqlite(final,path)
    assert path.read_bytes()==before
    final.pop('curation');next(c for c in final['cards'] if c.get('removed_in'))['learning']['primary_card_id']='absent'
    with pytest.raises(ValueError):export_sqlite(final,path)
    assert path.read_bytes()==before


@pytest.mark.parametrize('case', ['group','owner','shared','format','pending'])
def test_retirement_scope_and_version_are_explicit(data,case):
    import hashlib
    source,_,patch=data;source=copy.deepcopy(source);patch=copy.deepcopy(patch)
    target=next(c for c in source['cards'] if c['ref']=='cut-other')
    if case=='group':
        other=next(c for c in source['cards'] if c['ref']=='they')
        other['learning']=copy.deepcopy(target['learning'])
    elif case=='owner':
        target=next(c for c in source['cards'] if c['ref']=='they')
        patch['operations']=[{'op':'retire_card','card_id':target['learning']['primary_card_id'],'expect_card':copy.deepcopy(target),'reason':'test'}]
    elif case=='shared':
        source['story_sentences'][-1]['sentence']='other-exercise'
    elif case=='format':patch['format_version']=True
    else:source['curation']={'pending':['unreviewed']}
    raw=json.dumps(source).encode();patch['source_sha256']=hashlib.sha256(raw).hexdigest()
    original=copy.deepcopy(patch)
    with pytest.raises(ValueError):apply_targeted_patch(raw,patch)
    assert patch==original


def test_gloss_changes_only_addressed_metadata(data):
    source,raw,patch=data;patch=copy.deepcopy(patch);patch['operations']=[patch['operations'][2]]
    final=apply_targeted_patch(raw,patch)
    final['release']=copy.deepcopy(source['release'])
    c=next(c for c in final['cards'] if c['ref']=='run-past_participle');c['translation_de']=patch['operations'][0]['expect_card']['translation_de']
    assert final==source
