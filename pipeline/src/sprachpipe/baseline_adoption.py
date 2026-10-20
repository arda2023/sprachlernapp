"""Narrow, offline adoption of the manifest-bound internal baseline; no review."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from .authoring_service import ROOT, require, _build_verified_bundle
from .word_registry import digest

KIND = 'internal-baseline-adoption-v1'
NOTICE = 'Übernimmt den bereits verwendeten internen Bestand. Damit bestätigst du keine neue sprachliche Gesamtprüfung.'
ANCHOR = ROOT/'supabase/functions/_shared/internal_baseline_source.json'


def anchor():
    return json.loads(ANCHOR.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def converted_digest(pack):
    # The timestamp is checked separately against the fixed technical build
    # timestamp. Every content field, QA payload and history edge is covered.
    value=copy.deepcopy(pack)
    value['release'].pop('created_at',None)
    return digest(value)


def verify_converted(pack):
    spec=anchor()
    require(converted_digest(pack)==spec['converted_content_sha256'] and
            pack['release'].get('created_at')==spec['converted_created_at'],
            'ADOPTION_CONTENT_CHANGED','Inhalt oder technische Konvertierung weicht vom gebundenen Bestand ab.')


def resolve_source(asset_directory):
    asset_directory=Path(asset_directory)
    manifest_path=asset_directory/'content.manifest.json'
    require(manifest_path.is_file(),'ADOPTION_SOURCE_MISSING','App-Manifest fehlt.')
    spec=anchor();binding=spec['source']
    require(sha(manifest_path)==binding['manifest_sha256'],'ADOPTION_SOURCE_CHANGED','App-Manifest weicht von der unterstützten Erstübernahme ab.')
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    source=(ROOT/manifest['source']['path']).resolve()
    require(source.is_relative_to(ROOT/'pipeline/out') and source.name=='content.sqlite',
            'ADOPTION_SOURCE_INVALID','Manifestquelle liegt außerhalb der unterstützten Pipelineausgabe.')
    paths={'sqlite_sha256':source,'asset_sha256':asset_directory/'content.sqlite',
           'pack_bytes_sha256':source.with_name('pack.json'),
           'finalization_sha256':source.with_name('finalization_report.json')}
    require(all(p.is_file() and sha(p)==binding[k] for k,p in paths.items()),
            'ADOPTION_SOURCE_CHANGED','Quelldateien oder App-Asset stimmen nicht mit den gebundenen Nachweisen überein.')
    pack=json.loads(paths['pack_bytes_sha256'].read_text(encoding='utf-8'))
    require(digest(pack)==binding['pack_canonical_sha256'] and
            digest(pack['word_registry']['snapshot'])==binding['registry_sha256'],
            'ADOPTION_SOURCE_CHANGED','Pack oder Registry abweichend.')
    return pack,spec


def preview(asset_directory):
    pack,spec=resolve_source(asset_directory)
    value={'kind':KIND,'source':spec['source'],'version':spec['version'],
           'counts':spec['counts'],'existing_evidence':spec['existing_evidence'],
           'open_findings':spec['open_findings'],'notice':NOTICE,'cloud_state':'not_checked'}
    value['sha256']=digest(value)
    return value


def confirmation(asset_directory,data):
    require(set(data)=={'preview_sha256','accepted'} and data['accepted'] is True,
            'ADOPTION_CONFIRMATION_REQUIRED','Interne Bestandsübernahme ausdrücklich bestätigen.')
    view=preview(asset_directory)
    require(data['preview_sha256']==view['sha256'],'ADOPTION_PREVIEW_CHANGED','Quelle geändert. Vorschau erneut öffnen.',status=409)
    from .editor.store import utc_now
    return {**view,'confirmation':{'accepted':True,'at':utc_now(),'scope':KIND}}


def verify_receipt(receipt,manifest,report,reviews,pack):
    spec=anchor()
    require(manifest.get('publication_kind')==KIND and manifest.get('parent_release_id') is None
            and manifest.get('lang')=='en' and manifest.get('internal_test_pack') is True,
            'ADOPTION_INVALID','Unzulässige Bestandsübernahme.')
    require(isinstance(receipt,dict),'ADOPTION_INVALID','Übernahmebeleg fehlt.')
    expected={'kind':KIND,'source':spec['source'],'version':spec['version'],
              'counts':spec['counts'],'existing_evidence':spec['existing_evidence'],
              'open_findings':spec['open_findings'],'notice':NOTICE,'cloud_state':'not_checked'}
    expected['sha256']=digest(expected)
    require({k:v for k,v in receipt.items() if k!='confirmation'}==expected,
            'ADOPTION_INVALID','Quellenbindung oder Befunde wurden verändert.')
    c=receipt.get('confirmation',{})
    from datetime import datetime
    try:valid_time=isinstance(c.get('at'),str) and datetime.fromisoformat(c['at'].replace('Z','+00:00')).tzinfo is not None
    except ValueError:valid_time=False
    require(set(c)=={'accepted','at','scope'} and c.get('accepted') is True and c.get('scope')==KIND and valid_time,
            'ADOPTION_CONFIRMATION_REQUIRED','Übernahmebestätigung fehlt.')
    v=report.get('validation',{})
    unsigned={k:value for k,value in v.items() if k!='sha256'}
    require(reviews==[] and v.get('editorial')=='existing-evidence-only' and v.get('technical')=='valid'
            and v.get('findings')==[] and v.get('base_sha256')==spec['source']['pack_canonical_sha256']
            and v.get('content_sha256')==spec['converted_content_sha256'] and v.get('sha256')==digest(unsigned)
            and report.get('status')=='ok' and report.get('history_superset') is True and report.get('internal_test_pack') is True
            and manifest.get('adoption_sha256')==digest(receipt)==report.get('adoption_sha256'),
            'ADOPTION_INVALID','Übernahmebeleg oder technische Prüfung ungültig.')
    require(manifest.get('sha256')==spec['converted_sqlite_sha256'] and
            manifest.get('size_bytes')==spec['converted_sqlite_size'] and
            report.get('sqlite_counts')==spec['counts'],
            'ADOPTION_CONTENT_CHANGED','SQLite oder Tabellenumfang weicht vom gebundenen Bestand ab.')
    verify_converted(pack)


def build(asset_directory,directory,receipt,progress):
    base,spec=resolve_source(asset_directory)
    view=preview(asset_directory)
    require({k:v for k,v in receipt.items() if k!='confirmation'}==view,
            'ADOPTION_SOURCE_CHANGED','Quelle seit Bestätigung geändert.')
    validation={'technical':'valid','editorial':'existing-evidence-only','findings':[],
                'content_sha256':spec['converted_content_sha256'],'base_sha256':digest(base)}
    validation['sha256']=digest(validation)
    # This is an internal build input, never stored as a draft or review.
    build_input={'base':{'release_id':None},'reviews':[],'provenance':[receipt]}
    result=_build_verified_bundle(build_input,base,directory,version=spec['version'],
                                  validation=validation,progress=progress,adoption=receipt)
    from .editor.store import read_json
    verify_receipt(receipt,result['manifest'],read_json(Path(directory)/'finalization_report.json'),[],result['pack'])
    return result
