"""Synthetic continuations, reusing the existing Cats rest. fixture text only."""
import copy
import hashlib
import json
import pytest
from test_content_contract import pack as fixture_pack
from sprachpipe.ids import stable_id
from sprachpipe.word_registry import digest
from sprachpipe.pack import build_rows
from sprachpipe.authoring_context import prepare_continuation, validate_context, validate_display_plan


def entry(form,lemma,pos,key,meaning,topic,batch,position):
    lid=stable_id('lemmas',lang='en',lemma=lemma,pos=pos)
    sid=stable_id('senses',lemma_id=lid,sense_key=key)
    cid=stable_id('cards',lang='en',form=form,sense_id=sid)
    return dict(selection_id=form,form=form,form_norm=form,lemma=lemma,pos=pos,
        lemma_ref=lemma+'/'+pos,lemma_id=lid,sense_ref=lemma+'/'+pos+'|'+key,sense_id=sid,
        sense_key=None,proposed_sense_key=key,card_ref=form+'|'+lemma+'/'+pos+'|'+key,card_id=cid,
        target_meaning_de=meaning,definition_de=meaning,translation_de=meaning,gloss_de=meaning,
        reason='Synthetic target',topic=topic,review={'status':'resolved','ambiguity':meaning},
        form_kind='base',form_label_de='Base',owner_deck_ref='animals',position=position,editorial_position=position,
        authoring_batch=batch,ownership_aliases=[],synonym_candidates_not_separate_targets=[],
        learning={'group_id':'en:card:'+cid,'primary_card_id':cid,'topic':topic,'related':[],'note':'Independent synthetic target.'})


def fixture(batch=2, promote_current=False):
    p=fixture_pack();p['release']['schema_version']=3
    entries=[entry('cats','cat','NOUN','cat#animal','Ein kleines Haustier.','pets',1,1),
             entry('rest','rest','VERB','rest#verb','Sich ausruhen.','actions',1,4),
             entry('house','house','NOUN','house#building','Wohngebäude.','home',2,2),
             entry('broom','broom','NOUN','broom#tool','Kehrgerät.','household',2,5),
             entry('roof','roof','NOUN','roof#top','Gebäudedach.','home',3,3),
             entry('mop','mop','NOUN','mop#tool','Wischgerät.','household',3,6)]
    refmap={'cat':'cat/NOUN','rest':'rest/VERB','cat-animal':entries[0]['sense_ref'],'rest-verb':entries[1]['sense_ref'],
            'cats':entries[0]['card_ref']}
    for table in ['lemmas','senses','dictionary_forms','sentence_tokens']:
        for r in p[table]:
            for k in ('ref','lemma','sense','card'):
                if table=='lemmas' and k=='lemma':continue
                if k in r:r[k]=refmap.get(r[k],r[k])
    p['cards']=[];p['deck_cards']=[];p['deck_words']=[];p['card_sentences']=[]
    for i,e in enumerate(entries[:2],1):
        p['cards'].append({'ref':e['card_ref'],'form':e['form'],'sense':e['sense_ref'],'form_kind':'base','form_label_de':'Base',
                           'translation_de':e['translation_de'],'cefr_band':'anfaenger','learning':e['learning']})
        p['deck_cards'].append({'deck':'animals','card':e['card_ref'],'position':i})
        p['deck_words'].append({'deck':'animals','primary_card':e['card_ref'],'form_norm':e['form_norm'],'position':i})
        p['card_sentences'].append({'card':e['card_ref'],'sentence':'s1','position':1,'gap_start':0 if i==1 else 5,
                                   'gap_end':4 if i==1 else 9,'accepted':[e['form']],'valid_alternatives':[]})
        for t in p['sentence_tokens']:
            if t.get('sense')==e['sense_ref']:t['card']=e['card_ref']
    # Canonical IDs are unchanged; exact planned sense definitions are present.
    for s,e in zip(p['senses'],entries):s['gloss_de']=e['gloss_de'];s['definition_de']=e['definition_de']
    # A dictionary-only companion exists for a current target, but no learning card.
    e=entries[2];p['lemmas'].append({'ref':e['lemma_ref'],'lemma':e['lemma'],'pos':e['pos']})
    p['senses'].append({'ref':e['sense_ref'],'lemma':e['lemma_ref'],'sense_key':e['proposed_sense_key'],'gloss_de':e['gloss_de'],'definition_de':e['definition_de']})
    if promote_current:
        # Deliberately artificial parser fixture, never app/authoring content.
        p['sentences'].append({'ref':'synthetic-current','text':'house broom.', 'translation_de':'Synthetische Testwörter.'})
        for i,e in enumerate(entries[2:4]):
            if not any(l['ref']==e['lemma_ref'] for l in p['lemmas']):
                p['lemmas'].append({'ref':e['lemma_ref'],'lemma':e['lemma'],'pos':e['pos']})
                p['senses'].append({'ref':e['sense_ref'],'lemma':e['lemma_ref'],'sense_key':e['proposed_sense_key'],
                                    'gloss_de':e['gloss_de'],'definition_de':e['definition_de']})
            p['cards'].append({'ref':e['card_ref'],'form':e['form'],'sense':e['sense_ref'],'translation_de':e['translation_de'],
                               'form_kind':'base','form_label_de':'Base','learning':e['learning'],'cefr_band':'anfaenger'})
            p['deck_cards'].append({'deck':'animals','card':e['card_ref'],'position':i+3})
            p['deck_words'].append({'deck':'animals','primary_card':e['card_ref'],'form_norm':e['form_norm'],'position':i+3})
            p['card_sentences'].append({'card':e['card_ref'],'sentence':'synthetic-current','position':1,'gap_start':i*6,
                                       'gap_end':i*6+5,'accepted':[e['form']],'valid_alternatives':[]})
            p['sentence_tokens'].append({'sentence':'synthetic-current','idx':i,'surface':e['form'],'start_pos':i*6,'end_pos':i*6+5,
                                        'lemma':e['lemma_ref'],'sense':e['sense_ref'],'card':e['card_ref']})
            p['dictionary_forms'].append({'form':e['form'],'sense':e['sense_ref'],'gloss_de':e['gloss_de'],'rank':1})
        p['sentence_tokens'].append({'sentence':'synthetic-current','idx':2,'surface':'.','start_pos':11,'end_pos':12})
        order={e['card_ref']:i for i,e in enumerate(sorted(entries[:4],key=lambda e:e['position']),1)}
        for table,key in [('deck_cards','card'),('deck_words','primary_card')]:
            for row in p[table]:row['position']=order[row[key]]
    parent=copy.deepcopy(p['word_registry']['snapshot'])
    parent['words']=[{'lang':'en','form_norm':e['form_norm'],'aliases':[],'owner_deck_ref':'animals',
                      'primary_card_ref':e['card_ref'],'primary_card_id':e['card_id'],'position':e['position']} for e in entries]
    p['word_registry']={'snapshot':parent,'sha256':digest(parent)}
    oldgroups={'version':'original','cards':[]}
    original={'entries':entries,'excluded':[],'owner_deck_ref':'animals','lang':'en','learning_groups_sha256':digest(oldgroups)}
    raw=json.dumps(p).encode()
    s,r,g=prepare_continuation(p,original,oldgroups,source_bytes=raw,source_path='synthetic.json',batch=batch,
                              version='test-v2',registry_path='registry.json',groups_path='groups.json',original_path='original.json')
    return p,s,r,g,raw


def test_continuation_reuses_reservations_and_dictionary_only_sense():
    p,s,r,g,raw=fixture()
    result=validate_context(p,s,r,g,source_bytes=raw)
    assert result['partition_counts']=={'imported':2,'current':2,'future':2}
    assert result['reused_proposed_senses']==1
    assert r['words']==p['word_registry']['snapshot']['words']
    assert s['entries']==s['continuation']['original_selection']['entries']
    plan=s['continuation']['display_plan']
    assert [m['append_position'] for m in plan['append']]==[3,4]
    assert [m['position'] for m in plan['rows']]==[1,2,3,4]
    assert [m['expected_position'] for m in plan['rows']]==[1,3,2,4]


@pytest.mark.parametrize('failure',['source','parent','id','definition','duplicate','owner','head','reimport','display','sentence','companion_definition'])
def test_continuation_rejects_conflicts(failure):
    p,s,r,g,raw=fixture()
    if failure=='source':raw+=b' '
    elif failure=='parent':r['parent_sha256']='0'*64
    elif failure=='id':s['entries'][2]['card_id']='bad'
    elif failure=='definition':s['entries'][2]['target_meaning_de']='Different meaning'
    elif failure=='duplicate':r['words'].append(copy.deepcopy(r['words'][-1]))
    elif failure=='owner':r['words'][2]['owner_deck_ref']='foreign'
    elif failure=='head':g['reserved_cards'][0]['primary_card_id']='missing'
    elif failure=='reimport':s['continuation']['partitions']['current'].append('cats')
    elif failure=='display':s['continuation']['display_plan']['rows'][0]['position']=2
    elif failure=='sentence':s['continuation']['imported_sentences'][s['entries'][0]['card_ref']]['sentence']['text']='Changed'
    elif failure=='companion_definition':
        p['senses'][-1]['definition_de']='Unrelated meaning'
        raw=json.dumps(p).encode();s['source_pack'].update(sha256=hashlib.sha256(raw).hexdigest(),canonical_sha256=digest(p))
        r['source_pack_sha256']=g['source_pack_sha256']=s['source_pack']['sha256']
    s['registry_sha256']=digest(r);s['learning_groups_sha256']=digest(g)
    with pytest.raises(ValueError):validate_context(p,s,r,g,source_bytes=raw)


def test_batch3_requires_batch2_to_be_actually_imported():
    with pytest.raises(ValueError):fixture(batch=3)


def test_batch3_after_second_import_has_no_future_targets():
    p,s,r,g,raw=fixture(batch=3,promote_current=True)
    result=validate_context(p,s,r,g,source_bytes=raw)
    assert result['partition_counts']=={'imported':4,'current':2,'future':0}
    assert len(s['continuation']['display_plan']['rows'])==6


def test_explicit_same_meaning_review_is_bound_to_both_exact_definitions():
    p,s,r,g,raw=fixture()
    original=s['continuation']['original_selection']
    sense=p['senses'][-1];sense['definition_de']='Ein Gebäude zum Wohnen.'
    raw=json.dumps(p).encode()
    review={sense['ref']:{'reserved_definition':'Wohngebäude.','existing_definition':sense['definition_de'],
                        'existing_sense_sha256':digest(sense),'decision':'same_meaning','reason':'Synthetic equivalent wording.'}}
    s,r,g=prepare_continuation(p,original,g['previous_snapshot'],source_bytes=raw,source_path='synthetic.json',batch=2,
                              version='review',registry_path='registry.json',groups_path='groups.json',original_path='original.json',
                              definition_equivalences=review)
    assert validate_context(p,s,r,g,source_bytes=raw)['status']=='PASS'
    s['continuation']['definition_equivalences'][sense['ref']]['reserved_definition']='A changed target'
    with pytest.raises(ValueError,match='definition conflict'):validate_context(p,s,r,g,source_bytes=raw)
