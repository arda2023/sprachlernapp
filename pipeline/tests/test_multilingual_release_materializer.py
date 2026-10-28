"""Exercise shared word ownership and independent inflection practice end to end."""
import importlib.util
import json
from pathlib import Path
import re
import sys

import pytest

SCRIPTS=Path(__file__).resolve().parents[1]/'scripts'
sys.path.insert(0,str(SCRIPTS))
from materialize_multilingual_release import prepare, check_counts
from sprachpipe import authoring_service as author
from sprachpipe.language_profiles import get_profile


def fixture_draft(tmp_path):
    profile=get_profile('pt-BR');records=[]
    examples=[('ordinary','ordinary','ser','Ele quer ser professor.','Er möchte Lehrer sein.','sein'),
        ('irregular_verbs_base','verb_base','ser','Eu quero ser professor.','Ich möchte Lehrer sein.','sein'),
        ('irregular_verbs_past','verb_past','foi','Ele foi professor.','Er war Lehrer.','war'),
        ('irregular_verbs_participle','verb_participle','sido','Ele tem sido professor.','Er ist Lehrer gewesen.','gewesen')]
    lex={'Ele':('ele','PRON','er'),'quer':('querer','VERB','möchte'),'professor':('professor','NOUN','Lehrer'),
         'Eu':('eu','PRON','ich'),'quero':('querer','VERB','möchte'),'tem':('ter','AUX','hat')}
    (tmp_path/'pt-BR').mkdir()
    for slug,kind,form,text,translation,gloss in examples:
        gap=re.search(r'\b'+form+r'\b',text).span()
        row=dict(form=form,lemma='ser',pos='VERB',sentence=text,translation_de=translation,gloss_de=gloss,_gap=gap)
        records.append((dict(slug=slug,kind=kind,title_de=slug,target_count=1),[row],'fixture'))
        tokens=[]
        for t in profile.tokenize(text,gap):
            if not t['is_word']:continue
            lemma,pos,g=lex.get(t['surface'],('ser','VERB',gloss))
            tokens.append({**{k:t[k] for k in ('idx','surface','start_pos','end_pos')},
                           'lemma':lemma,'pos':pos,'gloss_de':g,'context_gloss_de':g})
        (tmp_path/'pt-BR'/(slug+'.json')).write_text(json.dumps(dict(lang='pt-BR',slug=slug,
            rows=[dict(id=slug+':0',sentence=text,translation_de=translation,tokens=tokens)])))
    return author.empty_pack('pt-BR','Portugiesisch'),records


def test_forms_share_surface_owner_but_keep_practice_and_srs(tmp_path):
    base,records=fixture_draft(tmp_path)
    draft,stats=prepare('pt-BR',base,records,tmp_path)
    result=author.validate_draft(draft,base)
    assert result['technical']=='valid'
    assert result['editorial']=='open'
    pack=author.materialize_draft(draft,base)
    assert len(pack['cards'])==4
    assert len(pack['deck_words'])==3
    assert len(pack['deck_practice_targets'])==3
    assert set(check_counts(pack,records).values())=={1}
    assert len({c['learning']['group_id'] for c in pack['cards']})==4
    assert len(pack['lexical_targets'])==1
    assert len(pack['card_lexical_targets'])==4


@pytest.mark.parametrize('field',['surface','start_pos','sentence','translation_de'])
def test_annotations_must_match_exact_corpus(tmp_path,field):
    base,records=fixture_draft(tmp_path)
    path=tmp_path/'pt-BR/ordinary.json';data=json.loads(path.read_text());row=data['rows'][0]
    if field in ('sentence','translation_de'):row[field]+=' Changed.'
    elif field=='surface':row['tokens'][0][field]='Other'
    else:row['tokens'][0][field]=9
    path.write_text(json.dumps(data))
    with pytest.raises(AssertionError):prepare('pt-BR',base,records,tmp_path)


def test_review_overlay_is_exact_bound_and_preserves_originals(tmp_path):
    base,records=fixture_draft(tmp_path)
    path=tmp_path/'pt-BR/ordinary.json';original=path.read_bytes()
    row=json.loads(original)['rows'][0];token=row['tokens'][0]
    batch=tmp_path/'_batches/pt-BR';batch.mkdir(parents=True)
    response=dict(input_sha256='a'*64,items=[row])
    source=batch/'original.json';source.write_text(json.dumps({'response':response}))
    source_bytes=source.read_bytes()
    fields=('lemma','pos','gloss_de','context_gloss_de')
    before={k:token[k] for k in fields};after={**before,'context_gloss_de':'Er'}
    correction=dict(lang='pt-BR',slug='ordinary',id=row['id'],idx=token['idx'],surface=token['surface'],
        input_sha256='a'*64,before=before,after=after,reason='Contextual capitalization')
    overlay=tmp_path/'review-corrections.json'
    overlay.write_text(json.dumps(dict(format=1,reviewer='AI second review',human_review=False,corrections=[correction])))
    draft,_=prepare('pt-BR',base,records,tmp_path)
    assert any(t.get('context_gloss_de')=='Er' for t in draft['add']['sentence_tokens'])
    audit=next(p for p in draft['provenance'] if p['kind']=='ai_token_review_overlay')
    assert audit['human_review'] is False and audit['correction_count']==1
    assert path.read_bytes()==original and source.read_bytes()==source_bytes
    correction['before']['lemma']='wrong'
    overlay.write_text(json.dumps(dict(format=1,reviewer='AI second review',human_review=False,corrections=[correction])))
    with pytest.raises(AssertionError,match='source before mismatch'):prepare('pt-BR',base,records,tmp_path)


def test_bundled_cursor_requires_exact_cloud_base_and_stays_separate(tmp_path,monkeypatch):
    import materialize_multilingual_release as release
    from sprachpipe.word_registry import digest
    monkeypatch.setattr(release,'ROOT',tmp_path)
    base=author.empty_pack('pt-BR','Português');base['release']['version']='published'
    cloud=dict(lang='pt-BR',channel='internal',generation=7,release_id='cloud-id',pack_canonical_sha256=digest(base))
    cloud_hash=digest(cloud)
    state=tmp_path/'state.json';state.write_text(json.dumps([dict(lang='pt-BR',generation=7,release_id='cloud-id',manifest_sha256=cloud_hash)]))
    evidence=tmp_path/'evidence.json';evidence.write_text(json.dumps([dict(lang='pt-BR',generation=7,release_id='cloud-id',manifest=cloud,manifest_sha256=cloud_hash)]))
    directory=tmp_path/'bundle';directory.mkdir()
    for name in ('content.sqlite','history_inventory.json','content.manifest.json'):(directory/name).write_text('test')
    bundle=dict(manifest=dict(lang='pt-BR',parent_release_id='published',sha256='content-hash'),pack=base)
    offer=release.install_assets('pt-BR',directory,bundle,state,base,evidence)
    assert offer['manifest']['origin']=='bundle'
    assert offer['manifest']['generation']==1
    assert offer['manifest']['cloud_generation']==7
    assert offer['manifest']['cloud_manifest_sha256']==cloud_hash
    assert offer['manifest_sha256']==digest(offer['manifest'])
    assert 'origin' not in bundle['manifest']
    second=release.install_assets('pt-BR',directory,bundle,state,base,evidence)
    assert second['manifest']['generation']==2
    assert second['manifest']['cloud_generation']==7
    assert second['manifest']['cloud_manifest_sha256']==cloud_hash
    assert second['manifest']['release_id']!=offer['manifest']['release_id']
    assert release.install_assets('pt-BR',directory,bundle,state,base,evidence,2)==second
    bundle['manifest']['version']='changed'
    with pytest.raises(AssertionError,match='already belongs'):
        release.install_assets('pt-BR',directory,bundle,state,base,evidence,2)
    with pytest.raises(AssertionError,match='already belongs'):
        release.install_assets('pt-BR',directory,bundle,state,base,evidence,1)
    with pytest.raises(AssertionError,match='must be positive'):
        release.install_assets('pt-BR',directory,bundle,state,base,evidence,0)
    base['release']['version']='different'
    with pytest.raises(AssertionError,match='Local base differs'):
        release.install_assets('pt-BR',directory,bundle,state,base,evidence)


def test_language_overlay_selection_is_unambiguous(tmp_path):
    from materialize_multilingual_release import annotation_overlay
    value=dict(format=1,reviewer='AI review',human_review=False,corrections=[])
    legacy=tmp_path/'review-corrections.json';legacy.write_text(json.dumps(value))
    assert annotation_overlay('nb',[],tmp_path)==({},None)
    local=tmp_path/'review-corrections-pt-BR.json';local.write_text(json.dumps(value))
    with pytest.raises(AssertionError,match='Both per-language'):
        annotation_overlay('pt-BR',[],tmp_path)
    legacy.unlink()
    assert annotation_overlay('pt-BR',[],tmp_path)==({},None)


def sentence_correction_fixture(tmp_path):
    base,records=fixture_draft(tmp_path)
    records=[(deck,rows,'b'*64) for deck,rows,_ in records]
    row=records[0][1][0]
    correction=dict(lang='pt-BR',slug='ordinary',id='ordinary:0',source_file='pt-BR/ordinary.json',
        source_sha256='b'*64,before=row['translation_de'],after='Er will Lehrer sein.',reason='Reviewed equivalent translation')
    path=tmp_path/'sentence-translation-corrections-pt-BR.json'
    value=dict(format=1,reviewer='Independent AI review',human_review=False,corrections=[correction])
    path.write_text(json.dumps(value))
    return base,records,path,value


def test_sentence_overlay_preserves_original_annotation_and_binds_new_context(tmp_path):
    base,records,_,_=sentence_correction_fixture(tmp_path)
    annotation=tmp_path/'pt-BR/ordinary.json';original=annotation.read_bytes()
    draft,_=prepare('pt-BR',base,records,tmp_path)
    assert author.validate_draft(draft,base)['technical']=='valid'
    assert any(s['translation_de']=='Er will Lehrer sein.' for s in draft['add']['sentences'])
    assert records[0][1][0]['translation_de']=='Er möchte Lehrer sein.'
    assert annotation.read_bytes()==original
    audit=next(p for p in draft['provenance'] if p['kind']=='ai_sentence_translation_overlay')
    assert audit['corpus_sources']=={'pt-BR/ordinary.json':'b'*64}
    assert audit['human_review'] is False


@pytest.mark.parametrize('field,value',[
    ('source_sha256','c'*64),('before','Changed original.'),
    ('after','Er ist Lehrer. Er arbeitet.'),('after','Er ist Lehrer; er arbeitet.'),
    ('after','Er ist Lehrer – heute.'),
])
def test_sentence_overlay_rejects_stale_binding_and_invalid_sentence(tmp_path,field,value):
    base,records,path,overlay=sentence_correction_fixture(tmp_path)
    overlay['corrections'][0][field]=value;path.write_text(json.dumps(overlay))
    with pytest.raises(AssertionError):prepare('pt-BR',base,records,tmp_path)


def target_gloss_correction_fixture(tmp_path):
    base,records=fixture_draft(tmp_path)
    records=[(deck,rows,'b'*64) for deck,rows,_ in records]
    row=records[0][1][0]
    correction=dict(lang='pt-BR',slug='ordinary',id='ordinary:0',source_file='pt-BR/ordinary.json',
        source_sha256='b'*64,before={k:row[k] for k in ('form','lemma','pos','gloss_de')},
        after='existieren',reason='Reviewed correction to the target meaning')
    path=tmp_path/'target-gloss-corrections-pt-BR.json'
    overlay=dict(format=1,reviewer='Independent AI target review',human_review=False,corrections=[correction])
    path.write_text(json.dumps(overlay))
    return base,records,path,overlay


def test_target_gloss_overlay_updates_target_and_preserves_source_and_annotation(tmp_path):
    import copy
    base,records,_,_=target_gloss_correction_fixture(tmp_path)
    original=copy.deepcopy(records)
    annotation=tmp_path/'pt-BR/ordinary.json';annotation_bytes=annotation.read_bytes()
    draft,_=prepare('pt-BR',base,records,tmp_path)
    assert author.validate_draft(draft,base)['technical']=='valid'
    target=draft['target_refs'][0]
    card=next(c for c in draft['add']['cards'] if c['ref']==target)
    sense=next(s for s in draft['add']['senses'] if s['ref']==card['sense'])
    assert sense['gloss_de']=='existieren'
    assert any(t.get('card')==target and t['context_gloss_de']=='existieren' for t in draft['add']['sentence_tokens'])
    assert any(f['form']=='ser' and f['sense']==card['sense'] and f['gloss_de']=='existieren' for f in draft['add']['dictionary_forms'])
    assert records==original and annotation.read_bytes()==annotation_bytes
    audit=next(p for p in draft['provenance'] if p['kind']=='ai_target_gloss_overlay')
    assert audit['human_review'] is False and audit['correction_count']==1
    assert audit['corpus_sources']=={'pt-BR/ordinary.json':'b'*64}


@pytest.mark.parametrize('field,value',[
    ('source_sha256','c'*64),('lang','es'),('slug','missing'),('id','ordinary:00'),
    ('before',dict(form='ser',lemma='ser',pos='VERB',gloss_de='wrong')),
    ('after',''),('after',' changed '),('after','new\nline'),('after','sein'),
    ('after',dict(lemma='changed')),
])
def test_target_gloss_overlay_rejects_stale_or_invalid_correction(tmp_path,field,value):
    base,records,path,overlay=target_gloss_correction_fixture(tmp_path)
    overlay['corrections'][0][field]=value;path.write_text(json.dumps(overlay))
    with pytest.raises(AssertionError):prepare('pt-BR',base,records,tmp_path)


def test_target_gloss_overlay_rejects_duplicate_target(tmp_path):
    base,records,path,overlay=target_gloss_correction_fixture(tmp_path)
    overlay['corrections'].append(overlay['corrections'][0].copy())
    path.write_text(json.dumps(overlay))
    with pytest.raises(AssertionError,match='Duplicate target gloss'):prepare('pt-BR',base,records,tmp_path)


def test_target_pos_overlay_preserves_source_and_gloss(tmp_path):
    import copy
    base,records,path,overlay=target_gloss_correction_fixture(tmp_path)
    original=copy.deepcopy(records);path.unlink()
    overlay['corrections'][0]['after']='AUX'
    (tmp_path/'target-pos-corrections-pt-BR.json').write_text(json.dumps(overlay))
    draft,_=prepare('pt-BR',base,records,tmp_path)
    assert author.validate_draft(draft,base)['technical']=='valid'
    card=next(c for c in draft['add']['cards'] if c['ref']==draft['target_refs'][0])
    sense=next(s for s in draft['add']['senses'] if s['ref']==card['sense'])
    lemma=next(l for l in draft['add']['lemmas'] if l['ref']==sense['lemma'])
    assert lemma['pos']=='AUX' and sense['gloss_de']=='sein'
    assert records==original
    audit=next(p for p in draft['provenance'] if p['kind']=='ai_target_pos_overlay')
    assert audit['human_review'] is False and audit['correction_count']==1


@pytest.mark.parametrize('value',['UNKNOWN',' AUX ','','VERB'])
def test_target_pos_overlay_rejects_invalid_or_unchanged_pos(tmp_path,value):
    base,records,path,overlay=target_gloss_correction_fixture(tmp_path)
    path.unlink();overlay['corrections'][0]['after']=value
    (tmp_path/'target-pos-corrections-pt-BR.json').write_text(json.dumps(overlay))
    with pytest.raises(AssertionError):prepare('pt-BR',base,records,tmp_path)


def number_token_fixture(tmp_path):
    base,records=fixture_draft(tmp_path)
    records=[(d,rows,'d'*64) for d,rows,_ in records]
    row=records[0][1][0];row['sentence']='Ele quer ser professor em 2010.'
    path=tmp_path/'pt-BR/ordinary.json';annotation=json.loads(path.read_text())
    ar=annotation['rows'][0];ar['sentence']=row['sentence']
    canonical=get_profile('pt-BR').tokenize(row['sentence'],row['_gap'])
    em=next(t for t in canonical if t['surface']=='em')
    ar['tokens'].append({**{k:em[k] for k in ('idx','surface','start_pos','end_pos')},
        'lemma':'em','pos':'ADP','gloss_de':'in','context_gloss_de':'in'})
    path.write_text(json.dumps(annotation))
    raw=next(t for t in canonical if t['surface']=='2010')
    review=dict(lang='pt-BR',slug='ordinary',id='ordinary:0',source_file='pt-BR/ordinary.json',
        source_sha256='d'*64,before=raw,after=dict(lemma='2010',pos='NUM',
        gloss_de='zweitausendzehn',context_gloss_de='zweitausendzehn'),reason='Year individually reviewed')
    overlay=dict(format=1,reviewer='Independent AI number review',human_review=False,tokens=[review])
    return base,records,path,overlay


def test_explicit_number_review_materializes_sense_and_dictionary_without_provider_claim(tmp_path):
    import copy
    base,records,annotation,overlay=number_token_fixture(tmp_path)
    original=copy.deepcopy(records);provider_bytes=annotation.read_bytes()
    (tmp_path/'reviewed-number-tokens-pt-BR.json').write_text(json.dumps(overlay))
    draft,_=prepare('pt-BR',base,records,tmp_path)
    assert author.validate_draft(draft,base)['technical']=='valid'
    token=next(t for t in draft['add']['sentence_tokens'] if t['surface']=='2010')
    assert token['context_gloss_de']=='zweitausendzehn' and token['sense'] and token['lemma']
    assert next(l for l in draft['add']['lemmas'] if l['ref']==token['lemma'])['pos']=='NUM'
    assert any(f['form']=='2010' and f['sense']==token['sense'] for f in draft['add']['dictionary_forms'])
    assert records==original and annotation.read_bytes()==provider_bytes
    audit=next(p for p in draft['provenance'] if p['kind']=='ai_editorial_number_token_review')
    assert audit['provider_annotated'] is False and audit['human_review'] is False


def test_unreviewed_number_fails_before_export(tmp_path):
    base,records,_,_=number_token_fixture(tmp_path)
    with pytest.raises(AssertionError,match='Missing explicit number'):prepare('pt-BR',base,records,tmp_path)


@pytest.mark.parametrize('field,value',[('source_sha256','e'*64),('before',dict(idx=5,surface='2011'))])
def test_number_review_rejects_stale_source_or_boundaries(tmp_path,field,value):
    base,records,_,overlay=number_token_fixture(tmp_path)
    overlay['tokens'][0][field]=value
    (tmp_path/'reviewed-number-tokens-pt-BR.json').write_text(json.dumps(overlay))
    with pytest.raises(AssertionError):prepare('pt-BR',base,records,tmp_path)
