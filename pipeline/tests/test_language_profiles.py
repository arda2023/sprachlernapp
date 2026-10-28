import pytest
from sprachpipe.language_profiles import get_profile, UnsupportedLanguage, canonical_language, utf16_to_codepoint, canonical_text


def test_unknown_language_does_not_use_english():
    for lang in ('fr','en-US','qaa'):
        with pytest.raises(UnsupportedLanguage):get_profile(lang)
    assert get_profile('en').manifest['answer_policy']=='legacy-target-alternative-form-typo-wrong-v1'
    assert canonical_language('de-ch')=='de-CH'
    with pytest.raises(ValueError):canonical_language('../en')


def test_unicode_and_gaps():
    assert canonical_text('e\u0301')=='é'
    assert utf16_to_codepoint('😀 test',3)==2
    with pytest.raises(ValueError):utf16_to_codepoint('😀 test',1)
    with pytest.raises(ValueError):canonical_text('\ud800')
    profile=get_profile('en')
    assert profile.gap('They look after me.',5,15,'look after')['surface']=='look after'
    with pytest.raises(ValueError):profile.gap('They cut and cut.',5,8,'cut')


def test_explicit_test_only_adapter_exports_separate_language(tmp_path,monkeypatch):
    import sqlite3
    from sprachpipe.language_profiles import LanguageProfile,PROFILES
    from sprachpipe import authoring_service as author
    from sprachpipe.export import export_sqlite
    from sprachpipe.word_registry import digest
    class SyntheticProfile(LanguageProfile):
        def gap(self,text,start,end,form):
            assert text[start:end]==form
            return {'start_pos':start,'end_pos':end}
        def validate_sentence(self,*args,**kwargs):return []
    profile=SyntheticProfile(lang='qaa',id='test-only-qaa',model='none',model_version='0')
    assert 'qaa' not in PROFILES
    monkeypatch.setitem(PROFILES,'qaa',profile)
    base=author.empty_pack('qaa','Synthetic');english=author.empty_pack('en','English');before=digest(english)
    words=[('test',0,4),('cut',5,8),('sample',9,15)]
    add={'lemmas':[{'ref':w,'lemma':w,'pos':'NOUN'} for w,_,_ in words],
         'senses':[{'ref':w,'lemma':w,'sense_key':w+'#synthetic','gloss_de':'Test','definition_de':'Nur synthetisch.'} for w,_,_ in words],
         'dictionary_forms':[{'form':w,'sense':w,'gloss_de':'Test','rank':0} for w,_,_ in words]}
    tokens=[{'idx':i,'surface':w,'start_pos':s,'end_pos':e,'sense':w,'lemma':w,'context_gloss_de':'Test','binding_status':'confirmed'} for i,(w,s,e) in enumerate(words)]
    tokens.append({'idx':3,'surface':'.','start_pos':15,'end_pos':16})
    operations=[{'op_id':'deck','kind':'create_deck','lang':'qaa','target_ref':'synthetic','expect':{'absent':True},'payload':{'ref':'synthetic','slug':'synthetic','title_de':'Synthetic','cefr_band':'anfaenger','sort':1}},
      {'op_id':'target','kind':'create_target','lang':'qaa','target_ref':'cut','expect':{'absent':True},'payload':{'deck_ref':'synthetic','card':{'form':'cut','sense':'cut','translation_de':'Test','cefr_band':'anfaenger'},'context':{'text':'test cut sample.','translation_de':'Nur synthetisch.','tokens':tokens,'gap':{'start_pos':5,'end_pos':8},'valid_alternatives':[]}}}]
    work=author.materialize_draft({'add':add,'operations':operations},base,profile)
    export_sqlite(work,tmp_path/'qaa.sqlite')
    with sqlite3.connect(tmp_path/'qaa.sqlite') as db:
        assert db.execute('SELECT lang FROM cards').fetchall()==[('qaa',)]
        assert db.execute('SELECT code FROM languages').fetchall()==[('qaa',)]
    assert digest(english)==before and author.target_identity(work,work['cards'][0])!=author.target_identity({**work,'lang':'en'},work['cards'][0])


def test_portuguese_profile_golden_and_english_pin():
    import unicodedata
    from sprachpipe.ids import form_norm
    p=get_profile('pt-BR','pt-BR-editorial-v1')
    assert get_profile('en').sha256=='59eec37d0a4f322d666701e00bc1bf4cfb44d19b183b1742d16b443989a505cf'
    assert p.sha256=='7c59364c0d1ef562ee5a6a679b7d895e0ebec6bf2ad47d8eae56afdcba87fe32'
    for lang in ('pt','pt-PT'):
        with pytest.raises(UnsupportedLanguage):get_profile(lang)
    text='😀 Na ação do teste: ã, õ, ç!'
    assert [t['surface'] for t in p.tokenize(text)]==['😀','Na','ação','do','teste',':','ã',',','õ',',','ç','!']
    assert canonical_text(unicodedata.normalize('NFD',text))==text
    assert form_norm('AÇÃO')==form_norm('AC\u0327A\u0303O')=='ação'
    assert form_norm('ação')!=form_norm('acao')
    assert p.gap(text,5,9,'ação')['surface']=='ação'
    assert utf16_to_codepoint(text,6)==5
    assert p.tokenize(text,(5,12))[2]['surface']=='ação do'
    for span in [(6,9),(5,8)]:
        with pytest.raises(ValueError):p.tokenize(text,span)
    with pytest.raises(ValueError):p.gap('ação ação.',0,4,'ação')
    findings=p.validate_sentence('Na ação do teste.', 'ação',3,7)
    assert [f.rule for f in findings]==['manual-pt-BR-editorial-v1']
    assert not p.manifest['automatic_grammar'] and not p.manifest['automatic_frequency']


def test_portuguese_bindings_and_review_are_explicit():
    import copy
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch (Brasilien)');d=draft(base)
    v=a.validate_draft(d,base)
    assert v['technical']=='valid',v
    assert v['editorial']=='open'
    d['reviews']=[{'decision':'approved','payload_sha256':a.draft_content_hash(d)}]
    assert a.validate_draft(d,base)['editorial']=='open'
    broken=copy.deepcopy(d);broken['operations'][1]['payload']['context']['tokens'].pop(0)
    assert a.validate_draft(broken,base)['technical']=='invalid'
    broken=copy.deepcopy(d);broken['operations'][1]['payload']['context']['tokens'][2].pop('sense')
    assert a.validate_draft(broken,base)['technical']=='invalid'
    assert a.release_parent_id(base) is None
    assert a.release_parent_id(a.empty_pack('en','English'))=='empty-en'
    changed=copy.deepcopy(base);changed['release']['notes']='not an empty seed'
    assert a.release_parent_id(changed)=='empty-pt-BR'


def test_portuguese_requires_confirmed_bindings_and_ordinary_decks():
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch (Brasilien)')
    d=draft(base);d['operations'][1]['payload']['context']['tokens'][2].pop('binding_status')
    assert a.validate_draft(d,base)['technical']=='invalid'
    d=draft(base);d['operations'][0]['payload']['practice_kind']='verb_past'
    assert a.validate_draft(d,base,profile=get_profile('pt-BR','pt-BR-editorial-v1'))['technical']=='invalid'


def test_portuguese_word_flag_cannot_bypass_manual_binding():
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch (Brasilien)');d=draft(base)
    token=d['operations'][1]['payload']['context']['tokens'][2]
    token['is_word']=False;token['binding_status']='suggested'
    assert a.validate_draft(d,base)['technical']=='invalid'


def test_portuguese_raw_table_import_cannot_infer_binding_confirmation():
    import copy
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch (Brasilien)');d=draft(base)
    work=a.materialize_draft(d,base)
    d['operations']=[];d['add']={t:copy.deepcopy(work[t]) for t in a.TABLES if work.get(t)}
    for token in d['add']['sentence_tokens']:
        if any(c.isalpha() for c in token['surface']):token['binding_status']='confirmed'
    assert a.validate_draft(d,base)['technical']=='valid'
    d['add']['sentence_tokens'][2].pop('binding_status')
    assert a.validate_draft(d,base)['technical']=='invalid'


@pytest.mark.parametrize('lang,text,form', [
    ('pt-BR', 'Minha irmã escreveu uma carta.', 'escreveu'),
    ('nb', 'Hun skrev et brev i går.', 'skrev'),
    ('it', 'Mia sorella scrisse una lettera.', 'scrisse'),
    ('es', 'Mi hermana escribió una carta.', 'escribió'),
])
def test_editorial_profiles_pin_forms_and_sentence_contract(lang,text,form):
    p=get_profile(lang);start=text.index(form);end=start+len(form)
    assert p.manifest['allowed_functions']==['base','past','past_participle']
    assert p.manifest['practice_kinds']==['ordinary','verb_base','verb_past','verb_participle']
    assert not p.manifest['automatic_grammar'] and not p.manifest['automatic_frequency']
    assert not [f for f in p.validate_sentence(text,form,start,end) if f.level=='error']
    assert p.gap(text,start,end,form)['surface']==form
    assert any(f.rule=='sentence_count' for f in p.validate_sentence(text+' Sim.',form,start,end))
    assert any(f.rule=='sentence_punctuation' for f in p.validate_sentence(text[:-1]+'; sim.',form,start,end))
    with pytest.raises(UnsupportedLanguage):get_profile(lang,'en-legacy-v1')


def test_portuguese_v2_form_capability_does_not_change_v1():
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch');d=draft(base)
    d['operations'][0]['payload']['practice_kind']='verb_past'
    assert a.validate_draft(d,base)['technical']=='valid'
    assert a.validate_draft(d,base,profile=get_profile('pt-BR','pt-BR-editorial-v1'))['technical']=='invalid'
    p=get_profile('pt-BR')
    assert p.id=='pt-BR-editorial-v2'
    d['reviews']=[{'decision':'approved','payload_sha256':a.draft_content_hash(d),
        'profile_sha256':get_profile('pt-BR','pt-BR-editorial-v1').sha256,
        'editorial_policy':'manual-pt-BR-editorial-v1'}]
    assert a.validate_draft(d,base)['editorial']=='open'



def test_ai_editorial_approval_requires_truthful_explicit_provenance():
    from portuguese_fixture import draft
    from sprachpipe import authoring_service as a
    base=a.empty_pack('pt-BR','Portugiesisch');d=draft(base);p=get_profile('pt-BR')
    review={'decision':'approved','payload_sha256':a.draft_content_hash(d),
        'profile_sha256':p.sha256,'editorial_policy':p.manifest['editorial_policy']}
    d['reviews']=[review]
    assert a.validate_draft(d,base)['editorial']=='open'
    review.update(human_review=False, reviewer='Codex AI editorial review',user_requested_private_device_test=True)
    assert a.validate_draft(d,base)['editorial']=='approved'
    for field,value in [('human_review',True),('user_requested_private_device_test',False),('reviewer',' ')]:
        previous=review[field];review[field]=value
        assert a.validate_draft(d,base)['editorial']=='open'
        review[field]=previous


def test_editorial_empty_seeds_have_no_published_parent():
    from sprachpipe.authoring_service import empty_pack, release_parent_id
    for lang in ('pt-BR','nb','it','es'):
        seed=empty_pack(lang,'Test')
        assert release_parent_id(seed) is None
        seed['release']['version']='published-v1'
        assert release_parent_id(seed)=='published-v1'
    assert release_parent_id(empty_pack('en','English'))=='empty-en'
