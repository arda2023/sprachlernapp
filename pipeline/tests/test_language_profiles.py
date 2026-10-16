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
