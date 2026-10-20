"""Explicit local seed/template preparation. No content, reviews or publication.

Run only after package-1 gates, with the editor stopped. Existing files are
snapshotted under its process lock and checked again under the service lock.
"""
from pathlib import Path
from contextlib import contextmanager
import argparse
import copy
import hashlib
import json
import os
import shutil
import uuid
import zipfile

import jsonschema
from sprachpipe import authoring_service as author
from sprachpipe.editor.service import EditorService
from sprachpipe.editor.store import default_directory
from sprachpipe.editor.exchange import archive_entries, json_bytes, read_delivery, write_zip
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
LANGUAGE={'lang':'pt-BR','display_name':'Portugiesisch (Brasilien)',
          'name_native':'Português do Brasil','translation_lang':'de'}


def hashes(root):
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob('*')) if p.is_file() and p.name!='process.lock'}


@contextmanager
def exclusive(root):
    with (root/'process.lock').open('r+b') as lock:
        if os.name=='nt':
            import msvcrt
            msvcrt.locking(lock.fileno(),msvcrt.LK_NBLCK,1)
        else:
            import fcntl
            fcntl.flock(lock.fileno(),fcntl.LOCK_EX|fcntl.LOCK_NB)
        try:yield
        finally:
            if os.name=='nt':
                lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)
            else:fcntl.flock(lock.fileno(),fcntl.LOCK_UN)


def verify(path):
    entries=archive_entries(Path(path).read_bytes())
    context=json.loads(entries['authoring_context.json'])
    delivery=read_delivery(Path(path).read_bytes(),Path(path).name,'pt-BR')
    jsonschema.Draft202012Validator(json.loads(entries['editorial_content_v4.schema.json']),
        format_checker=jsonschema.FormatChecker()).validate(delivery)
    assert delivery['context_sha256']==digest(context)
    assert context['profile']==get_profile('pt-BR').manifest
    assert delivery['base']==author.base_fingerprint(context['source_pack'])
    assert len(delivery['expected_target_refs'])==20
    assert not context['source_pack']['cards'] and not context['ownership']['words']
    assert not delivery['submitted_reviews']
    assert [o['target_ref'] for o in delivery['operations'][1:]]==delivery['expected_target_refs']
    assert all(o['payload']['card']['form'] is None and o['payload']['context']['text'] is None
               for o in delivery['operations'][1:])
    print('PASS: existing ZIP/JSON/XLSX verifier, schema, source/profile/context hashes, 20 empty refs')
    return delivery,context


def prepare(root,backup_root,output):
    root=Path(root).resolve();backup_root=Path(backup_root).resolve();output=Path(output).resolve()
    assert root.is_dir() and not backup_root.is_relative_to(root)
    backup=backup_root/('editor-backup-'+uuid.uuid4().hex)
    with exclusive(root):
        for p in (root/'jobs').glob('*.json'):
            assert json.loads(p.read_text())['state'] not in ('queued','running','cancelling'), 'Unfinished editor job; resolve before backup'
        before=hashes(root)
        shutil.copytree(root,backup)
        assert hashes(backup)==before
    # No writer can run while the service is open. A writer racing the lock
    # handoff is detected before any intentional service mutation.
    service=EditorService(root)
    try:
        assert hashes(root)==before, 'Store changed after backup; stop without creating a language'
        expected=author.empty_pack('pt-BR',LANGUAGE['display_name'])
        expected['languages'][0]['name_native']=LANGUAGE['name_native']
        languages=service.languages();existing=next((l for l in languages if l['lang']=='pt-BR'),None)
        if existing:
            assert all(existing.get(k)==v for k,v in LANGUAGE.items()), 'Existing language metadata conflict'
            assert service.base('pt-BR')==expected, 'Existing pt-BR is not the exact empty seed; do not overwrite'
            assert existing['base']==author.base_fingerprint(expected), 'Existing profile/base binding conflict'
        else:service.create_language(LANGUAGE)
        # New, empty preparation draft. Import the eventual complete delivery
        # as a NEW draft; do not append a duplicate create_deck operation here.
        deck={'kind':'create_deck','op_id':'ptbr-allgemeine-sprache','lang':'pt-BR',
            'target_ref':'ptbr-allgemeine-sprache','expect':{'absent':True},
            'reason':'Leerer redaktioneller Vorbereitungsschritt; keine Inhaltsfreigabe.',
            'payload':{'ref':'ptbr-allgemeine-sprache','slug':'allgemeine-sprache',
                'title_de':'Allgemeine Sprache','description_de':'Brasilianisches Portugiesisch mit deutschen Übersetzungen.',
                'practice_kind':'ordinary','cefr_band':'anfaenger','sort':1}}
        draft=service.new_draft('pt-BR')
        draft=service.save_operations(draft['draft_id'],[deck],service.store.etag(draft))
        artifact=service.template('pt-BR',20,'Allgemeine Sprache')
        exported,_=service.store.artifact_path(artifact['artifact_id'])
        entries=archive_entries(exported.read_bytes())
        delivery=json.loads(entries['delivery.json']);context=json.loads(entries['authoring_context.json'])
        context.update(language=LANGUAGE,source_pack=service.base('pt-BR'),
            preparation_draft_id=draft['draft_id'],authoring_contract=json.loads((HERE/'contract.json').read_text()),
            status='AUTHORING_TEMPLATE_NOT_CONTENT_NOT_RELEASE',import_mode='new_draft')
        delivery['add']={'lemmas':[],'senses':[],'dictionary_forms':[]}
        delivery['operations']=[copy.deepcopy(deck)]
        for ref in delivery['expected_target_refs']:
            delivery['operations'].append({'kind':'create_target','op_id':'create-'+ref,'lang':'pt-BR',
                'target_ref':ref,'expect':{'absent':True},'reason':'Unvollständiger redaktioneller Zielslot.',
                'payload':{'deck_ref':deck['target_ref'],'topic':'allgemeine-sprache',
                    'card':{'form':None,'sense':None,'translation_de':None,'cefr_band':'anfaenger','introduction_scope':'ordinary'},
                    'context':{'text':None,'translation_de':None,'gap':{'start_pos':None,'end_pos':None},
                               'tokens':[],'valid_alternatives':[],'reason':'Redaktionelle Prüfung offen.'}}})
        delivery['completeness']='draft';delivery['context_sha256']=digest(context)
        entries=archive_entries(write_zip(delivery,context));entries['FORMAT.md']=(HERE/'FORMAT.md').read_bytes()
        entries['files.sha256.json']=json_bytes({n:hashlib.sha256(b).hexdigest() for n,b in entries.items() if n!='files.sha256.json'})
        output.parent.mkdir(parents=True,exist_ok=True)
        with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_STORED) as z:
            for n,b in entries.items():z.writestr(n,b)
        verify(output)
        after=hashes(root)
        assert all(after.get(k)==v for k,v in before.items()), 'Existing editor file changed'
        assert service.base('pt-BR')==expected and not draft['reviews'] and not draft['target_refs']
        receipt={'backup':str(backup),'draft_id':draft['draft_id'],'base':delivery['base'],
            'profile_sha256':get_profile('pt-BR').sha256,'output':str(output),
            'archive_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
            'existing_files_unchanged':len(before),'new_files':sorted(set(after)-set(before)),
            'real_content_created':False,'reviews_created':False}
        (output.parent/'portuguese_authoring_batch_1.receipt.json').write_bytes(json_bytes(receipt))
        print(json.dumps(receipt,ensure_ascii=False,indent=2))
    finally:service.close()


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify',type=Path)
    parser.add_argument('--prepare',action='store_true')
    parser.add_argument('--store',type=Path,default=default_directory())
    parser.add_argument('--backup-root',type=Path,default=ROOT/'build/portuguese_package_1')
    parser.add_argument('--output',type=Path,default=ROOT/'build/portuguese_authoring_batch_1.zip')
    args=parser.parse_args()
    if args.verify:verify(args.verify)
    elif args.prepare:prepare(args.store,args.backup_root,args.output)
    else:parser.error('Choose --verify FILE or explicit --prepare after local gates')
