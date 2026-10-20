"""Synthetic confirmations are confined to pytest temporary workspaces."""
import copy
import json
from pathlib import Path

import pytest

from test_editor_service import setup,wait
from sprachpipe import authoring_service as author
from sprachpipe import baseline_adoption as adoption
from sprachpipe.editor.publisher import inspect_bundle
from sprachpipe.editor.store import atomic_json,read_json
from sprachpipe.word_registry import digest


class Progress:
    def progress(self,*args):pass
    def check_cancelled(self):pass


@pytest.fixture
def baseline(setup,monkeypatch,tmp_path):
    service,base=setup
    # Establish an independent synthetic expected conversion, never a production
    # receipt. The production allowlist is neither edited nor extended.
    directory=tmp_path/'reference';directory.mkdir()
    expected=author._build_verified_bundle({'base':{'release_id':None},'reviews':[]},base,directory,
        version='synthetic-baseline',validation={},progress=Progress())
    expected['pack']['release']['notes']='INTERNES TEST-PACK · Bestandsübernahme ohne neue Sprachprüfung'
    from sprachpipe.export import export_sqlite
    export_sqlite(expected['pack'],directory/'expected-adoption.sqlite')
    spec={'version':'synthetic-baseline','source':{'pack_canonical_sha256':digest(base)},
          'converted_content_sha256':adoption.converted_digest(expected['pack']),
          'converted_created_at':expected['pack']['release']['created_at'],
          'converted_sqlite_sha256':adoption.sha(directory/'expected-adoption.sqlite'),
          'converted_sqlite_size':(directory/'expected-adoption.sqlite').stat().st_size,
          'counts':expected['counts'],'existing_evidence':{'qa_scope':'Synthetic only'},
          'open_findings':['Synthetic pre-existing gap']}
    monkeypatch.setattr(adoption,'anchor',lambda:spec)
    monkeypatch.setattr(adoption,'resolve_source',lambda directory:(copy.deepcopy(base),spec))
    return service,spec


def test_preview_confirmation_release_and_draft_head_preservation(baseline):
    service,spec=baseline
    draft=service.new_draft('en');head=service.store.get('heads','en')
    preview=service.adoption_preview()
    assert preview['cloud_state']=='not_checked' and preview['kind']==adoption.KIND
    for data in [{},{'accepted':False,'preview_sha256':preview['sha256']},
                 {'accepted':True,'preview_sha256':'bad'},
                 {'accepted':True,'preview_sha256':preview['sha256'],'path':'anything'}]:
        with pytest.raises(author.AuthoringError):service.adopt_baseline(data)
    job=wait(service,service.adopt_baseline({'accepted':True,'preview_sha256':preview['sha256']}))
    assert job['state']=='succeeded',job
    record=job['result'];directory=service.store.root/record['path']
    assert 'draft_id' not in record and record['publication_kind']==adoption.KIND
    manifest,objects=inspect_bundle(directory,record,None)
    assert len(objects)==9 and manifest['parent_release_id'] is None
    report=read_json(directory/'finalization_report.json')
    assert len(report['sqlite_counts'])==23
    assert report['validation']['editorial']=='existing-evidence-only'
    assert read_json(directory/'editorial_reviews.json')==[]
    assert service.store.load_draft(draft['draft_id'])==draft
    assert service.store.get('heads','en')==head
    retry=wait(service,service.adopt_baseline({'accepted':True,'preview_sha256':preview['sha256']}))
    assert retry['result']['release_id']==record['release_id']
    assert len(service.store.list('releases'))==1
    from test_editor_publisher import Remote
    remote=Remote();remote.fail_upload=False;service.publisher=remote
    remote.channel=lambda lang:{'generation':1,'release_id':'occupied','manifest_sha256':'0'*64,'manifest':{}}
    blocked=wait(service,service.publish_release(record['release_id'],'upload'))
    assert blocked['state']=='failed' and not remote.calls
    remote.channel=lambda lang:{'generation':0,'release_id':None,'manifest_sha256':None,'manifest':None}
    assert wait(service,service.publish_release(record['release_id'],'upload'))['state']=='succeeded'
    assert wait(service,service.publish_release(record['release_id'],'finalize'))['state']=='succeeded'
    assert wait(service,service.publish_release(record['release_id'],'commit'))['state']=='succeeded'
    proof=read_json(directory/'provenance.json')
    for changed in [[],[{}],[{**proof[0],'confirmation':{}}],[{**proof[0],'open_findings':[]}]]:
        atomic_json(directory/'provenance.json',changed)
        with pytest.raises(author.AuthoringError):inspect_bundle(directory,record,None)
    atomic_json(directory/'provenance.json',proof)
    atomic_json(directory/'editorial_reviews.json',[{'decision':'approved','scope':'draft'}])
    with pytest.raises(author.AuthoringError):inspect_bundle(directory,record,None)
    atomic_json(directory/'editorial_reviews.json',[])
    # Every content field, including technical gloss snapshots, is pinned.
    pack=read_json(directory/'pack.json');pack['cards'][0]['translation_de']='injected'
    atomic_json(directory/'pack.json',pack)
    with pytest.raises(author.AuthoringError,match='Konvertierung'):inspect_bundle(directory,record,None)


def test_failed_build_leaves_no_release_and_can_retry(baseline,monkeypatch):
    service,spec=baseline;preview=service.adoption_preview()
    correct=spec['converted_content_sha256'];spec['converted_content_sha256']='0'*64
    job=wait(service,service.adopt_baseline({'accepted':True,'preview_sha256':preview['sha256']}))
    assert job['state']=='failed' and job['error']['code']=='ADOPTION_CONTENT_CHANGED'
    assert service.store.list('releases')==[]
    assert not list((service.store.root/'staging').iterdir())
    spec['converted_content_sha256']=correct
    job=wait(service,service.adopt_baseline({'accepted':True,'preview_sha256':preview['sha256']}))
    assert job['state']=='succeeded',job


def test_source_pin_blocks_changed_manifest_and_missing_evidence(tmp_path):
    with pytest.raises(author.AuthoringError,match='fehlt'):adoption.resolve_source(tmp_path)
    (tmp_path/'content.manifest.json').write_text('{}')
    with pytest.raises(author.AuthoringError,match='Manifest weicht'):adoption.resolve_source(tmp_path)


def test_normal_release_still_requires_review(setup,tmp_path):
    service,base=setup;draft=service.new_draft('en')
    draft['validation']=author.validate_draft(draft,base)
    with pytest.raises(author.AuthoringError) as error:
        author.build_release(draft,base,tmp_path,version='blocked',
            expected_validation=draft['validation']['sha256'],progress=Progress())
    assert error.value.code=='RELEASE_BLOCKED'
