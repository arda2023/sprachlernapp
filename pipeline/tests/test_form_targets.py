import copy
import hashlib
import json
import sqlite3
import sys
from pathlib import Path
import pytest
from sprachpipe.pack import build_rows
from sprachpipe.export import export_sqlite
from sprachpipe.form_targets import validate_form_selection
from sprachpipe.authoring_context import prepare_form_continuation
from sprachpipe.word_registry import digest
from form_fixture import fixture, delivery
sys.path.insert(0,str(Path(__file__).parents[1]/'scripts'))
from import_editorial_patch import create_content, export_offline, main
from finalize_curation import check_sqlite
from export_authoring_context import export, verify_zip


def workflow(tmp_path, *, zips=False):
    source,raw,selection,registry,sentences,reviews=fixture()
    original=copy.deepcopy(source)
    for batch in (1,2,3):
        base=tmp_path/f'base{batch}';base.mkdir()
        (base/'pack.json').write_bytes(raw);export_sqlite(source,base/'content.sqlite')
        selection.update(source_pack={'path':str(base/'pack.json'),'sqlite_path':str(base/'content.sqlite'),'sqlite_sha256':hashlib.sha256((base/'content.sqlite').read_bytes()).hexdigest()},registry_path=str(base/'registry.json'))
        (base/'registry.json').write_text(json.dumps(registry));(base/'selection.json').write_text(json.dumps(selection))
        result=validate_form_selection(source,selection,registry,source_hash=hashlib.sha256(raw).hexdigest())
        assert (result['imported'],result['current'],result['future'])==((batch-1)*3,3,(3-batch)*3)
        if zips:
            archive=base/'authoring.zip';export(base/'selection.json',archive,batch)
            assert len(verify_zip(archive)['partitions']['current'])==3
        entry=delivery(selection,registry,sentences,reviews)
        final=create_content(source,entry,registry,source_hash=hashlib.sha256(raw).hexdigest())
        out=tmp_path/f'out{batch}'
        if zips:
            (base/'delivery.json').write_text(json.dumps(entry))
            assert main(['--source',str(base/'pack.json'),'--create',str(base/'delivery.json'),'--registry',str(base/'registry.json'),'--out',str(out)])==0
        else:
            export_offline(final,out)
        assert check_sqlite(out/'content.sqlite',build_rows(final))['form_targets']==batch*3
        assert final['cards'][0]==original['cards'][0] and final['card_sentences'][0]==original['card_sentences'][0]
        assert final['sentence_tokens'][:len(original['sentence_tokens'])]==original['sentence_tokens']
        source=final;raw=(out/'pack.json').read_bytes()
        if batch<3:
            selection,registry=prepare_form_continuation(source,selection,registry,source_bytes=raw,source_path=out/'pack.json',sqlite_path=out/'content.sqlite',sqlite_sha256=hashlib.sha256((out/'content.sqlite').read_bytes()).hexdigest(),batch=batch+1)
    return final,out


def test_complete_form_workflow_and_continuation(tmp_path):
    final,out=workflow(tmp_path,zips=True)
    rows=build_rows(final)
    assert len(rows['cards'])==len(rows['form_targets'])==9
    assert len(rows['deck_words'])==6
    assert len(rows['lexical_targets'])==3
    assert len(rows['deck_practice_targets'])==12
    assert len({r['id'] for r in rows['cards'] if r['form']=='cut'})==3
    assert len({r['id'] for r in rows['cards'] if r['form']=='run'})==2


@pytest.mark.parametrize('failure',['owner','identity','deck','sense','zero','two','retired','missing','lexical','unclassified','token','dictionary'])
def test_schema4_rejects_invalid_content(tmp_path,failure):
    p,_=workflow(tmp_path);p=copy.deepcopy(p)
    if failure=='owner':p['deck_words'].append(copy.deepcopy(p['deck_words'][0]))
    if failure=='identity':p['form_targets'].append(dict(p['form_targets'][0],ref='duplicate'))
    if failure=='deck':p['deck_practice_targets'][0]['deck']='past'
    if failure=='sense':p['form_targets'][0]['sense']='cut'
    if failure=='zero':p['card_sentences'].pop()
    if failure=='two':p['card_sentences'].append(copy.deepcopy(p['card_sentences'][-1]))
    if failure=='retired':p['lexical_targets'][0]['removed_in']='gone'
    if failure=='missing':p['form_targets'][0]['lexical_target']='absent'
    if failure=='lexical':p['card_lexical_targets'].pop()
    if failure=='unclassified':p['form_targets']=[f for f in p['form_targets'] if f['ref']!='cut-base']
    if failure=='token':p['sentence_tokens'][-3]['form_target']='cut-base'
    if failure=='dictionary':p['dictionary_forms'][0]['card']='run-base'
    sentinel=tmp_path/'protected.sqlite';sentinel.write_bytes(b'keep')
    with pytest.raises(ValueError):export_sqlite(p,sentinel)
    assert sentinel.read_bytes()==b'keep'


@pytest.mark.parametrize('failure',['hash','format','reuse','selection','unknown','missing'])
def test_v3_fail_closed(failure):
    source,raw,selection,registry,sentences,reviews=fixture();entry=delivery(selection,registry,sentences,reviews)
    if failure=='hash':entry['source_sha256']='0'*64
    if failure=='format':entry['format_version']=99
    if failure=='reuse':
        entry['selection']['entries'][1]['reuse']['context_sha256']='0'*64
        entry['selection_sha256']=digest(entry['selection'])
    if failure=='selection':entry['add']['cards'].pop()
    if failure=='unknown':entry['add']['cards'][0]['unrecognized']=True
    if failure=='missing':entry['reviews'].pop()
    before=copy.deepcopy(source)
    with pytest.raises(ValueError):create_content(source,entry,registry,source_hash=hashlib.sha256(raw).hexdigest())
    assert before==source


def test_alias_ownership_does_not_accept_the_owner_surface(tmp_path):
    p,_=workflow(tmp_path)
    p=copy.deepcopy(p)
    p['deck_words']=[w for w in p['deck_words'] if w['form_norm']!='ran']
    p['deck_cards']=[m for m in p['deck_cards'] if m['card']!='run-past']
    registry=p['word_registry']['snapshot']
    registry['words']=[w for w in registry['words'] if w['form_norm']!='ran']
    next(w for w in registry['words'] if w['form_norm']=='run')['aliases']=['ran']
    p['word_aliases']=[{'form_norm':'ran','word':'run'}]
    for i,w in enumerate(p['deck_words'],1):
        w['position']=i
        next(m for m in p['deck_cards'] if m['card']==w['primary_card'])['position']=i
        next(r for r in registry['words'] if r['form_norm']==w['form_norm'])['position']=i
    p['word_registry']['sha256']=digest(registry)
    rows=build_rows(p)
    ran=next(c for c in rows['cards'] if c['form']=='ran')
    link=next(l for l in rows['card_sentences'] if l['card_id']==ran['id'])
    assert link['accepted']==['ran'] and link['valid_alternatives']==[]
    next(l for l in p['card_sentences'] if l['card']=='run-past')['accepted']=['run']
    with pytest.raises(ValueError,match='accepted'):build_rows(p)
    next(l for l in p['card_sentences'] if l['card']=='run-past')['accepted']=['ran']
    p['word_aliases'][0]['word']='missing'
    with pytest.raises(ValueError):build_rows(p)


def test_partial_group_mapping_and_old_reuse_duplicates_rejected(tmp_path):
    p,_=workflow(tmp_path)
    # Put two old-compatible cards in the same group; lexical coverage cannot
    # map only the head while the second member falls back to the old group id.
    old=p['cards'][0];other=p['cards'][1]
    other['identity_function']=None;other['introduction_scope']='ordinary'
    from sprachpipe.form_targets import card_id
    # Rebuild this altered fixture's head metadata to avoid testing only ID errors.
    other['learning']=copy.deepcopy(old['learning'])
    p['card_lexical_targets']=[m for m in p['card_lexical_targets'] if m['card']!=other['ref']]
    with pytest.raises(ValueError,match='lexical learning-group'):build_rows(p)


def test_source_and_failed_output_preserved_on_invalid_v3(tmp_path):
    source,raw,s,r,sentences,reviews=fixture();entry=delivery(s,r,sentences,reviews)
    for name,value in [('entry.json',entry),('registry.json',r)]: (tmp_path/name).write_text(json.dumps(value))
    (tmp_path/'source.json').write_bytes(raw+b' ')
    out=tmp_path/'out'
    assert main(['--source',str(tmp_path/'source.json'),'--create',str(tmp_path/'entry.json'),'--registry',str(tmp_path/'registry.json'),'--out',str(out)])==2
    assert not out.exists() and (tmp_path/'source.json').read_bytes()==raw+b' '


def test_committed_dart_fixture_matches_full_python_readback(tmp_path):
    final,_=workflow(tmp_path)
    db=sqlite3.connect(tmp_path/'dart.sqlite')
    db.executescript((Path(__file__).parents[2]/'test/fixtures/form_content_v4.sql').read_text())
    db.close()
    assert len(check_sqlite(tmp_path/'dart.sqlite',build_rows(final)))==22


def test_form_continuation_cli_snapshots_are_new_and_partitioned(tmp_path):
    import subprocess
    _,out=workflow(tmp_path)
    # Source after batch 1, immutable initial selection; no staged asset involved.
    target=tmp_path/'continuation'
    command=[sys.executable,str(Path(__file__).parents[1]/'scripts/export_authoring_context.py'),
        '--prepare-continuation','synthetic-batch-2','--selection',str(tmp_path/'base1/selection.json'),
        '--source-pack',str(tmp_path/'out1/pack.json'),'--source-sqlite',str(tmp_path/'out1/content.sqlite'),
        '--batch','2','--out',str(target)]
    result=subprocess.run(command,capture_output=True,text=True)
    assert result.returncode==0,result.stderr
    assert json.loads(result.stdout)['partition_counts']=={'imported':3,'current':3,'future':3}
    before=(target/'selection.json').read_bytes()
    assert subprocess.run(command,capture_output=True).returncode!=0
    assert (target/'selection.json').read_bytes()==before
    export(target/'selection.json',tmp_path/'next.zip',2)
    assert verify_zip(tmp_path/'next.zip')['counts']['imported']==3


def test_explicit_lexical_sense_cannot_leave_an_old_group_on_fallback(tmp_path):
    from sprachpipe.form_targets import validate_form_rows
    p,_=workflow(tmp_path)
    rows=build_rows(p)
    old=copy.deepcopy(rows['cards'][0])
    old.update(id='old-other-form',form='cuts',form_norm='cuts')
    old['learning'].update(group_id='old-other-group',primary_card_id=old['id'])
    rows['cards'].append(old)
    with pytest.raises(ValueError,match='lexical sense mapping'):validate_form_rows(rows)


def test_new_card_cannot_replace_a_canonical_reused_form(tmp_path):
    from sprachpipe.form_targets import card_id
    p,_=workflow(tmp_path)
    old=p['cards'][0];c=copy.deepcopy(old)
    c.update(ref='unnecessary-cut-base',identity_function='base',introduction_scope='form_only')
    rows=build_rows(p)
    sense=next(r['sense_id'] for r in rows['cards'] if r['id']==old['learning']['primary_card_id'])
    cid=card_id('en',c,sense)
    c['learning'].update(group_id='new-unnecessary',primary_card_id=cid)
    p['cards'].append(c)
    p['card_lexical_targets'].append({'card':c['ref'],'lexical_target':'cut','note':'synthetic'})
    f=next(f for f in p['form_targets'] if f['ref']=='cut-base')
    p['form_targets'].append(dict(f,ref='unnecessary-target',card=c['ref']))
    with pytest.raises(ValueError):build_rows(p)


@pytest.mark.parametrize('failure',['foreign_language','non_verbal'])
def test_form_rows_reject_wrong_card_language_and_pos(tmp_path,failure):
    from sprachpipe.form_targets import validate_form_rows
    p,_=workflow(tmp_path);rows=build_rows(p)
    rows['cards'][0]['lang' if failure=='foreign_language' else 'pos']='de' if failure=='foreign_language' else 'NOUN'
    with pytest.raises(ValueError):validate_form_rows(rows)
