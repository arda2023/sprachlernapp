import copy
import json
import time
import uuid
import pytest
from sprachpipe.authoring_service import AuthoringError,base_fingerprint,target_view,target_identity,draft_content_hash,validate_draft
from sprachpipe.editor.service import EditorService
from sprachpipe.editor.store import EditorStore
from sprachpipe.word_registry import digest
from targeted_fixture import fixture


def delivery_250(base):
    """250 explicitly synthetic meanings, sharing a real fixture owner/spelling."""
    identifier=str(uuid.uuid4());add={'cards':[],'senses':[],'dictionary_forms':[],'sentences':[],'sentence_tokens':[],'card_sentences':[]}
    old=target_view(base,'cut-old')
    source_sentence=next(s for s in base['sentences'] if s['ref']==old['sentence_ref'])
    for n in range(250):
        ref=f'synthetic-target-{n:03}';sense=f'synthetic-sense-{n:03}';sn=f'synthetic-sentence-{n:03}'
        add['senses'].append({'ref':sense,'lemma':'cut','sense_key':f'cut#synthetic-{n:03}',
            'gloss_de':f'Testbedeutung {n:03}','definition_de':f'Ausschließlich synthetische Testbedeutung {n:03}.'})
        add['dictionary_forms'].append({'form':'cut','sense':sense,'gloss_de':f'Testbedeutung {n:03}','rank':0})
        card={'ref':ref,'form':'cut','sense':sense,'translation_de':f'Testhinweis {n:03}','cefr_band':'anfaenger'}
        identity=target_identity({**base,'senses':base['senses']+add['senses']},card)
        card['learning']={'group_id':'en:card:'+identity,'primary_card_id':identity,'topic':'synthetic-test','related':[],'note':'Synthetic acceptance only'}
        add['cards'].append(card)
        add['sentences'].append({'ref':sn,'text':source_sentence['text'],'translation_de':f'Synthetische Übersetzung {n:03}.','origins':['deck']})
        tokens=copy.deepcopy(old['context']['tokens'])
        for token in tokens:
            token['sentence']=sn
            if token.get('card')=='cut-old':token['card']=ref;token['sense']=sense;token['context_gloss_de']=f'Testbedeutung {n:03}'
            # A shared global card token is still explicitly bound to its real sense.
            token['binding_status']='confirmed'
        add['sentence_tokens'].extend(tokens)
        add['card_sentences'].append({'card':ref,'sentence':sn,'position':1,
            'gap_start':old['context']['gap']['start_pos'],'gap_end':old['context']['gap']['end_pos'],
            'accepted':['cut'],'valid_alternatives':[]})
    return {'format':'sprachapp.editorial-content','format_version':4,'delivery_id':identifier,
        'lang':'en','translation_lang':'de','purpose':'append','base':base_fingerprint(base),
        'context_sha256':digest(base),'expected_target_refs':[c['ref'] for c in add['cards']],
        'selection':{'policy':'editor-deck-v1','batches':[]},'add':add,'operations':[],
        'provenance':[{'ref':'synthetic','kind':'manual','source_label':'Automated synthetic acceptance','notes':'Not learning content'}],
        'submitted_reviews':[{'decision':'approved','reviewer':'untrusted file'}],'extensions':{}}


def wait(service,job):
    deadline=time.monotonic()+90
    while time.monotonic()<deadline:
        current=service.store.get('jobs',job['job_id'])
        if current['state'] not in ('queued','running'):return current
        time.sleep(.02)
    raise AssertionError('job did not finish')


@pytest.fixture
def setup(tmp_path):
    base=fixture(tmp_path)[0];source=tmp_path/'source.json';source.write_text(json.dumps(base))
    service=EditorService(tmp_path/'editor',source=source,asset_directory=tmp_path/'assets')
    yield service,base
    service.close()


def test_draft_etag_isolation_and_restart(setup):
    service,base=setup
    draft=service.new_draft('en');etag=service.store.etag(draft);view=target_view(base,'cut-old')
    updated=service.save_operations(draft['draft_id'],[{'kind':'set_solution_hint','lang':'en','target_ref':'cut-old','expect':view['expect'],'payload':{'translation_de':'Testhinweis geändert'}}],etag)
    with pytest.raises(AuthoringError,match='anderer Tab'):service.save_operations(draft['draft_id'],[],etag)
    assert service.store.load_draft(draft['draft_id'])==updated
    assert base['cards'][0]['translation_de']!='Testhinweis geändert'
    with pytest.raises(AuthoringError,match='bereits'):EditorStore(service.store.root)
    root=service.store.root;source=service.source;service.close()
    restarted=EditorService(root,source=source)
    assert restarted.store.load_draft(draft['draft_id'])==updated
    restarted.close()


def test_250_import_is_complete_idempotent_and_preserves_local_edits(setup):
    service,base=setup;delivery=delivery_250(base);raw=json.dumps(delivery).encode()
    job=wait(service,service.preview_upload(raw,'synthetic.json','en'))
    assert job['state']=='succeeded',job
    preview=job['result'];inv=preview['preview']['inventory']
    assert (inv['expected'],inv['parsed'],inv['processed'])==(250,250,250)
    assert [len(c['expected_refs']) for c in inv['chunks']]==[100,100,50]
    assert len(inv['new_refs'])==250
    receipt=service.accept_import(preview['import_id'],preview['preview_sha256'])
    draft=service.store.load_draft(receipt['draft_id'])
    assert draft['reviews']==[]
    view=service.target(draft['draft_id'],'synthetic-target-000')
    view['context']['translation_de']='Lokal korrigiert.'
    updated=service.update_target(draft['draft_id'],view['ref'],{'context':view['context'],'translation_de':view['card']['translation_de']},service.store.etag(draft))
    assert service.accept_import(preview['import_id'],preview['preview_sha256'])==receipt
    assert service.store.load_draft(draft['draft_id'])==updated
    delivery['add']['cards'][0]['translation_de']='Different same ID'
    other=wait(service,service.preview_upload(json.dumps(delivery).encode(),'changed.json','en'))['result']
    with pytest.raises(AuthoringError,match='Liefer-ID'):service.accept_import(other['import_id'],other['preview_sha256'])


def test_supported_validation_and_unsupported_language_draft(setup):
    service,base=setup;draft=service.new_draft('en')
    view=target_view(base,'cut-old')
    draft=service.save_operations(draft['draft_id'],[{'kind':'set_solution_hint','lang':'en','target_ref':'cut-old','expect':view['expect'],'payload':{'translation_de':'Testhinweis'}}],service.store.etag(draft))
    result=validate_draft(draft,base)
    assert result['technical']=='valid',result
    assert result['editorial']=='open'
    language=service.create_language({'lang':'qaa','display_name':'Synthetisch','name_native':'Synthetic'})
    assert language['profile'] is None
    second=service.new_draft('qaa')
    assert validate_draft(second,service.base('qaa'))['technical']=='unsupported'
    assert service.catalog('qaa')['total']==0
    with pytest.raises(AuthoringError,match='anderer Sprache'):service.save_operations(second['draft_id'],[{'kind':'create_deck','lang':'en'}],service.store.etag(second))


def test_imported_250_targets_validate_as_one_transaction(setup):
    service,base=setup;delivery=delivery_250(base)
    draft=service.new_draft('en');draft.update(add=delivery['add'],target_refs=delivery['expected_target_refs'])
    result=validate_draft(draft,base)
    assert result['technical']=='valid',result['findings'][:5]


def test_saved_base_tampering_rejected_even_after_cached_read(setup):
    from sprachpipe.editor.store import atomic_json
    service,base=setup;draft=service.new_draft('en')
    service.base('en');changed=copy.deepcopy(base);changed['cards'][0]['translation_de']='tampered'
    atomic_json(service.store.path('bases',draft['base']['pack_canonical_sha256']).with_suffix('.json'),changed)
    with pytest.raises(AuthoringError,match='Basis ist verändert'):service.base('en')


def test_roundtrip_created_target_counts_towards_full_batch(setup):
    from sprachpipe.authoring_service import preview_import
    from sprachpipe.editor.exchange import delivery_for_draft
    service,base=setup;draft=service.new_draft('en');view=target_view(base,'cut-other')
    draft['operations']=[{'kind':'create_target','op_id':'new','target_ref':'new-context','lang':'en','expect':{'absent':True},'payload':{'deck_ref':'owner','card':{'form':'cut','sense':'cut-other','translation_de':'Test'},'context':view['context']}}]
    draft['target_refs']=['new-context']
    preview=preview_import(base,delivery_for_draft(draft))
    assert preview['inventory']['expected']==preview['inventory']['processed']==1


def test_rebase_preserves_changes_but_reopens_review(setup):
    service,base=setup;draft=service.new_draft('en');view=target_view(base,'cut-other')
    draft=service.save_operations(draft['draft_id'],[{'kind':'set_solution_hint','lang':'en','target_ref':'cut-other','expect':view['expect'],'payload':{'translation_de':'lokal'}}],service.store.etag(draft))
    new=copy.deepcopy(base);new['release']['version']='new-base';service.install_base(new)
    rebased=service.rebase(draft['draft_id'],service.store.etag(draft))
    assert rebased['base']['version']=='new-base' and rebased['operations']==draft['operations']
    assert rebased['reviews']==[] and rebased['validation'] is None
    new['cards'][-2]['translation_de']='concurrent';service.install_base(new)
    with pytest.raises(AuthoringError,match='Konflikte'):service.rebase(rebased['draft_id'],service.store.etag(rebased))


def test_new_meaning_and_previously_created_target_are_one_transaction(setup):
    from sprachpipe.language_profiles import get_profile
    service,base=setup;draft=service.new_draft('en')
    tokens=get_profile('en').tokenize('They fold paper.')
    for t in tokens:
        t.update(binding_status='confirmed')
        if t['is_word']:
            ref=t['surface'].lower();t.update(lemma=ref,sense=ref,context_gloss_de='Test')
            if ref=='fold':t['card']='fold-target'
    context={'text':'They fold paper.','translation_de':'Sie falten Papier.','tokens':tokens,'gap':{'start_pos':5,'end_pos':9},'valid_alternatives':[]}
    operations=[{'kind':'create_target','target_ref':'fold-target','lang':'en','expect':{'absent':True},'payload':{'deck_ref':'owner','card':{'form':'fold','sense':'fold','translation_de':'falten','cefr_band':'anfaenger'},'context':context}},
        {'kind':'add_vocabulary','target_ref':'fold','lang':'en','expect':{'absent':True},'payload':{'lemmas':[{'ref':'fold','lemma':'fold','pos':'VERB'}],'senses':[{'ref':'fold','lemma':'fold','sense_key':'fold#test','gloss_de':'falten','definition_de':'Synthetische Testbedeutung.'}],'dictionary_forms':[{'form':'fold','sense':'fold','gloss_de':'falten','rank':0}]}}]
    draft=service.save_operations(draft['draft_id'],operations,service.store.etag(draft))
    result=validate_draft(draft,base)
    assert result['technical']=='valid',result


def test_incomplete_spreadsheet_row_can_be_completed_without_json(setup):
    import io
    from openpyxl import Workbook
    service,base=setup;book=Workbook();book.active.title='Meta';book.active.append(['key','value_json']);book.active.append(['xlsx_mode','"draft"'])
    sheet=book.create_sheet('Ziele');sheet.append(['form','translation_de','sentence','sentence_translation_de']);sheet.append(['paper','Papier','They cut paper.','Sie schneiden Papier.'])
    raw=io.BytesIO();book.save(raw)
    preview=wait(service,service.preview_upload(raw.getvalue(),'incomplete.xlsx','en'))['result']
    assert any(f['location'].get('sheet')=='Ziele' and f['location'].get('row')==2 for f in preview['preview']['findings'])
    receipt=service.accept_import(preview['import_id'],preview['preview_sha256']);draft=service.store.load_draft(receipt['draft_id']);ref=draft['target_refs'][0]
    view=target_view(base,'cut-old');context=view['context'];context['gap']={'start_pos':9,'end_pos':14}
    saved=service.update_target(draft['draft_id'],ref,{'form':'paper','sense':'paper','deck_ref':'owner','translation_de':'Papier','context':context},service.store.etag(draft))
    assert saved['add']['cards']==[] and saved['operations'][0]['kind']=='create_target'
    result=validate_draft(saved,base);assert result['technical']=='valid',result


def test_operation_identity_is_idempotent_and_rejects_changed_payload(setup):
    service,base=setup;draft=service.new_draft('en');view=target_view(base,'cut-other')
    op={'op_id':'exact-operation','kind':'set_solution_hint','lang':'en','target_ref':'cut-other','expect':view['expect'],'payload':{'translation_de':'Test'}}
    saved=service.save_operations(draft['draft_id'],[op],service.store.etag(draft))
    assert service.save_operations(draft['draft_id'],[op],service.store.etag(saved))==saved
    bad=copy.deepcopy(op);bad['payload']['translation_de']='changed'
    with pytest.raises(AuthoringError,match='Operationsreferenz'):service.save_operations(draft['draft_id'],[bad],service.store.etag(saved))


def test_staging_rejects_bundle_changes_before_touching_assets(setup):
    import hashlib
    from sprachpipe.editor.store import atomic_json
    service,base=setup;directory=service.store.root/'bundles'/'synthetic';directory.mkdir(parents=True)
    (directory/'content.sqlite').write_bytes(b'synthetic');(directory/'pack.json').write_bytes(b'{}')
    for name,value in [('registry.json',{}),('history_inventory.json',{}),('editorial_reviews.json',[])]:atomic_json(directory/name,value)
    manifest={'sha256':hashlib.sha256(b'synthetic').hexdigest(),'pack_json_sha256':hashlib.sha256(b'{}').hexdigest(),'registry_sha256':digest({}),'history_inventory_sha256':digest({}),'editorial_reviews_sha256':digest([])}
    atomic_json(directory/'content.manifest.json',manifest)
    service.store.put('releases','synthetic',{'release_id':'synthetic','version':'test','lang':'en','path':'bundles/synthetic','manifest':manifest})
    service.staging_impact('synthetic')
    (directory/'content.sqlite').write_bytes(b'tampered')
    with pytest.raises(AuthoringError,match='nachträglich verändert'):service.staging_impact('synthetic')
    assert not service.asset_directory.exists()


def test_portuguese_first_and_followup_bundle_use_real_reader(tmp_path):
    from portuguese_fixture import delivery
    from sprachpipe import authoring_service as author
    from sprachpipe.editor.exchange import authoring_context,write_zip,read_delivery
    from sprachpipe.editor.xlsx import write_workbook,read_workbook
    source=tmp_path/'en.json';source.write_text(json.dumps(author.empty_pack('en','English')))
    service=EditorService(tmp_path/'editor',source=source,asset_directory=tmp_path/'assets')
    try:
        english=digest(service.base('en'))
        lang=service.create_language({'lang':'pt-BR','display_name':'Portugiesisch (Brasilien)','name_native':'Português do Brasil','translation_lang':'de'})
        assert lang['state']=='ready'
        base=service.base('pt-BR');d=delivery(base)
        assert read_workbook(write_workbook(d),'pt-BR')==d
        raw=write_zip(d,authoring_context(base))
        assert read_delivery(raw,'synthetic.zip','pt-BR')==d
        preview=wait(service,service.preview_upload(raw,'synthetic.zip','pt-BR'))
        assert preview['state']=='succeeded',preview
        p=preview['result'];receipt=service.accept_import(p['import_id'],p['preview_sha256'])
        draft=service.store.load_draft(receipt['draft_id'])
        def approve_and_build(draft,label):
            job=wait(service,service.validate(draft['draft_id'],service.store.etag(draft)))
            assert job['state']=='succeeded',job
            draft=job['result']['draft'];assert draft['validation']['technical']=='valid',draft['validation']
            assert draft['validation']['editorial']=='open'
            review={'payload_sha256':author.draft_content_hash(draft),
                'reviewer':'SYNTHETIC TEST ONLY','reason':'Technical fixture only; no linguistic approval or publication.'}
            with pytest.raises(AuthoringError,match='KI-Prüfung'):
                service.review(draft['draft_id'],review,service.store.etag(draft))
            review.update(human_review=False,user_requested_private_device_test=True)
            draft=service.review(draft['draft_id'],review,service.store.etag(draft))
            assert draft['reviews'][-1]['human_review'] is False
            assert draft['reviews'][-1]['editorial_policy']=='ai-editorial-reviewed-v1'
            assert draft['validation']['editorial']=='approved'
            job=wait(service,service.release(draft['draft_id'],{'version':label,'validation_sha256':draft['validation']['sha256']},service.store.etag(draft)))
            assert job['state']=='succeeded',job
            return job['result']
        first=approve_and_build(draft,'synthetic_ptbr_1')
        assert first['manifest']['parent_release_id'] is None
        first_pack=service.base('pt-BR');view=author.target_view(first_pack,'synthetic-acao')
        second=service.new_draft('pt-BR')
        context=copy.deepcopy(view['context']);context['translation_de']='Zweite synthetische Testrevision.'
        second=service.update_target(second['draft_id'],'synthetic-acao',{'context':context,'translation_de':view['card']['translation_de']},service.store.etag(second))
        follow=approve_and_build(second,'synthetic_ptbr_2')
        assert follow['manifest']['parent_release_id']=='synthetic_ptbr_1'
        report=json.loads((service.store.root/follow['path']/'reader_report.json').read_text())
        assert len(report['current'])==1 and len(report['historical'])==2
        assert digest(service.base('en'))==english
        assert service.base('pt-BR')['word_registry']['snapshot']==first_pack['word_registry']['snapshot']
    finally:service.close()
