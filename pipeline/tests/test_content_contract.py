import copy
import hashlib
import json
import sqlite3
import sys
from pathlib import Path
import pytest
from sprachpipe.pack import build_rows
from sprachpipe.export import export_sqlite
from sprachpipe.word_registry import bind_new_pack

sys.path.insert(0, str(Path(__file__).parents[1]/'scripts'))
from import_editorial_patch import create_content
from finalize_curation import check_sqlite

FIXTURE = Path(__file__).parent/'fixtures/editorial_create_v2'


def fixture():
    source = (FIXTURE/'base.json').read_bytes()
    return json.loads(source), json.loads((FIXTURE/'input.json').read_bytes()), json.loads((FIXTURE/'registry.json').read_bytes()), hashlib.sha256(source).hexdigest()


def pack():
    source, entry, registry, sha = fixture()
    return create_content(source, entry, registry, source_hash=sha)


def test_offline_create_story_and_sqlite_readback_without_credentials(tmp_path, monkeypatch):
    for name in ('GOOGLE_APPLICATION_CREDENTIALS','GOOGLE_CLOUD_PROJECT','GOOGLE_API_KEY'):
        monkeypatch.delenv(name, raising=False)
    value = pack(); rows = build_rows(value)
    counts = export_sqlite(value, tmp_path/'content.sqlite')
    assert check_sqlite(tmp_path/'content.sqlite', rows) == counts
    assert counts['cards'] == counts['card_sentences'] == counts['stories'] == counts['story_sentences'] == 1
    assert value['sentences'][0]['qa_status'] == 'editorial_reviewed'
    assert value['sentences'][0]['model'] is None


@pytest.mark.parametrize('change', ['zero','two','four','gap','accepted','token','ref','owner','case','story','registry','unreserved_alias'])
def test_invalid_export_is_blocked_and_target_preserved(tmp_path, change):
    value = pack()
    if change == 'zero': value['card_sentences'][0]['removed_in']='v2'
    if change in ('two','four'):
        for i in range(1, 2 if change=='two' else 4):
            sn = copy.deepcopy(value['sentences'][0]); sn['ref']=f's{i+1}';sn['text']+=' '*i
            value['sentences'].append(sn)
            value['card_sentences'].append(dict(value['card_sentences'][0],sentence=sn['ref'],position=i+1))
    if change == 'gap': value['card_sentences'][0]['gap_start']=1
    if change == 'accepted': value['card_sentences'][0]['accepted']=['cat']
    if change == 'token': value['sentence_tokens'][0]['end_pos']=3
    if change == 'ref': value['sentence_tokens'][0]['sense']='absent'
    if change == 'owner': value['deck_words'].append(dict(value['deck_words'][0]))
    if change == 'case': value['deck_words'].append(dict(value['deck_words'][0],form_norm='Cats'))
    if change == 'story': value['story_sentences'][0]['sentence']='absent'
    if change == 'registry': value['word_registry']['sha256']='0'*64
    if change == 'unreserved_alias': value['word_aliases']=[{'form_norm':'catz','word':'cats'}]
    target=tmp_path/'content.sqlite'; target.write_bytes(b'preserve')
    with pytest.raises(ValueError): export_sqlite(value,target)
    assert target.read_bytes()==b'preserve'


def test_historical_links_are_not_active_or_lost(tmp_path):
    value=pack(); sn=copy.deepcopy(value['sentences'][0]);sn.update(ref='old',text='Cats rest. ')
    value['sentences'].append(sn)
    value['sentence_tokens'] += [dict(t,sentence='old') for t in value['sentence_tokens'][:]]
    value['card_sentences'].append(dict(value['card_sentences'][0],sentence='old',removed_in='v2',position=1))
    rows=build_rows(value)
    assert len(rows['card_sentences'])==2
    assert rows['cards'][0].get('removed_in') is None
    assert sum(not r.get('removed_in') for r in rows['card_sentences'])==1
    export_sqlite(value,tmp_path/'content.sqlite')
    check_sqlite(tmp_path/'content.sqlite',rows)


@pytest.mark.parametrize('change',['hash','review','annotation','reservation','double','alternative'])
def test_create_fails_closed(change):
    source,entry,registry,sha=fixture()
    if change=='hash':sha='0'*64
    if change=='review':entry['reviews'][0]['checked']['text']='other'
    if change=='annotation':entry['add']['sentence_tokens'].pop()
    if change=='reservation':entry['add']['cards'][0]['form']='dogs'
    if change=='double':entry['add']['cards']*=2
    if change=='alternative':entry['reviews'][0]['alternatives_checked']=[{'alternative':'dogs'}]
    before=copy.deepcopy(source)
    with pytest.raises(ValueError):create_content(source,entry,registry,source_hash=sha)
    assert source==before


def test_500_synthetic_words_have_500_sentences_no_cloud():
    value=pack()
    value['stories']=[];value['story_sentences']=[]
    for key in ('cards','card_sentences','sentence_tokens','sentences','deck_cards','deck_words','dictionary_forms','lemmas','senses'):
        value[key]=[]
    for i in range(500):
        ref=f'word{i}';text=f'{ref}.'
        value['lemmas'].append({'ref':ref,'lemma':ref,'pos':'NOUN'})
        value['senses'].append({'ref':ref,'lemma':ref,'sense_key':ref+'#test','gloss_de':'Test'})
        value['cards'].append({'ref':ref,'form':ref,'sense':ref})
        value['sentences'].append({'ref':ref,'text':text,'translation_de':'Synthetischer Test.'})
        value['card_sentences'].append({'card':ref,'sentence':ref,'position':1,'gap_start':0,'gap_end':len(ref),'accepted':[ref]})
        value['sentence_tokens'].append({'sentence':ref,'idx':0,'surface':ref,'start_pos':0,'end_pos':len(ref),'lemma':ref,'sense':ref,'card':ref})
        value['sentence_tokens'].append({'sentence':ref,'idx':1,'surface':'.','start_pos':len(ref),'end_pos':len(ref)+1})
        value['dictionary_forms'].append({'form':ref,'sense':ref,'card':ref,'gloss_de':'Test','rank':1})
        value['deck_cards'].append({'deck':'animals','card':ref,'position':i+1})
        value['deck_words'].append({'deck':'animals','primary_card':ref,'form_norm':ref,'position':i+1})
    bind_new_pack(value, {'format_version':1,'normalization':'NFC-lower-apostrophe-v1','words':[]})
    rows=build_rows(value)
    assert len(rows['cards'])==len(rows['deck_words'])==len(rows['card_sentences'])==len(rows['sentences'])==500

@pytest.mark.parametrize('change', ['index', 'surface', 'sense', 'unapproved', 'duplicate'])
def test_story_learning_context_approval_is_bound_to_exact_token(change):
    source, entry, registry, sha = fixture()
    context = {'token_index': 1, 'surface': 'rest', 'sense': 'rest-verb', 'approved': True, 'reason': 'Exact sentence, translation and verb sense reviewed in fixture.'}
    entry['reviews'][0]['learning_contexts'] = [context]
    assert create_content(source, entry, registry, source_hash=sha)['sentences'][0]['qa_report']['editorial_create']['learning_contexts'] == [context]
    if change == 'index': context['token_index'] = 50
    if change == 'surface': context['surface'] = 'rests'
    if change == 'sense': context['sense'] = 'cat-animal'
    if change == 'unapproved': context['approved'] = False
    if change == 'duplicate': entry['reviews'][0]['learning_contexts'].append(context.copy())
    with pytest.raises(ValueError): create_content(source, entry, registry, source_hash=sha)
