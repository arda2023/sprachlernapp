"""Synthetic technical fixture, never an editorial language approval."""
import copy
from sprachpipe import authoring_service as author
from sprachpipe.language_profiles import get_profile


def delivery(base):
    profile=get_profile('pt-BR');text='😀 Na ação do teste.'
    tokens=profile.tokenize(text,(5,9));words=[t['surface'].lower() for t in tokens if t['is_word']]
    for t in tokens:
        if t['is_word']:
            ref=t['surface'].lower();t.update(lemma=ref,sense=ref,context_gloss_de='Synthetische Testbindung',binding_status='confirmed')
    return {'format':'sprachapp.editorial-content','format_version':4,
        'delivery_id':'d16c6307-9b86-4803-b387-03429dd0194f','lang':'pt-BR','translation_lang':'de',
        'purpose':'new_deck','base':author.base_fingerprint(base),'context_sha256':None,
        'expected_target_refs':['synthetic-acao'],'selection':{'policy':'editor-deck-v1','batches':[{'number':1,'target_refs':['synthetic-acao']}]},
        'add':{'lemmas':[{'ref':w,'lemma':w,'pos':'NOUN'} for w in words],
          'senses':[{'ref':w,'lemma':w,'sense_key':w+'#synthetic','gloss_de':'Test','definition_de':'Nur synthetische Strukturprüfung.'} for w in words],
          'dictionary_forms':[{'form':w,'sense':w,'gloss_de':'Test','rank':0} for w in words]},
        'operations':[{'kind':'create_deck','op_id':'deck','lang':'pt-BR','target_ref':'synthetic','expect':{'absent':True},
          'payload':{'ref':'synthetic','slug':'synthetic','title_de':'SYNTHETISCH – NICHT VERÖFFENTLICHEN','practice_kind':'ordinary','cefr_band':'anfaenger','sort':1}},
          {'kind':'create_target','op_id':'target','lang':'pt-BR','target_ref':'synthetic-acao','expect':{'absent':True},
           'payload':{'deck_ref':'synthetic','card':{'form':'ação','sense':'ação','translation_de':'Test','cefr_band':'anfaenger','introduction_scope':'ordinary'},
            'context':{'text':text,'translation_de':'Synthetischer Test, keine Übersetzungsfreigabe.','gap':{'start_pos':5,'end_pos':9},'tokens':tokens,'valid_alternatives':[]}}}],
        'provenance':[],'submitted_reviews':[],'extensions':{},'completeness':'full'}


def draft(base):
    d=delivery(base)
    return {'lang':'pt-BR','translation_lang':'de','revision':0,'base':d['base'],
        'add':d['add'],'operations':d['operations'],'target_refs':d['expected_target_refs'],'reviews':[]}
