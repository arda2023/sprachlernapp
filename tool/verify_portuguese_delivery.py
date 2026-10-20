"""Orchestrates existing exchange, profile and editor validators only.

Run from the repository root with the configured pipeline Python environment.
The input archive remains byte-identical. An explicit acceptance applies only
to a new isolated temporary store; never to the personal editor store.
"""
from pathlib import Path
import hashlib,json,shutil,tempfile,time
import jsonschema
from sprachpipe.editor.exchange import archive_entries,read_delivery
from sprachpipe.editor.service import EditorService
from sprachpipe import authoring_service as a
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest
import argparse
parser=argparse.ArgumentParser(description='Read-only BR delivery checks; import only into a new temporary editor store. No review or release.')
parser.add_argument('delivery',type=Path)
parser.add_argument('--output',type=Path,default=Path('build/portuguese_package_2'))
args=parser.parse_args()
root=args.output;root.mkdir(exist_ok=True,parents=True)
src=args.delivery
backup=root/src.name
if not backup.exists():shutil.copyfile(src,backup)
assert src.read_bytes()==backup.read_bytes()
raw=backup.read_bytes(); entries=archive_entries(raw);d=read_delivery(raw,backup.name,'pt-BR')
c=json.loads(entries['authoring_context.json'])
schema=json.loads(Path('pipeline/data/curation/editorial_content_v4.schema.json').read_text())
assert json.loads(entries['editorial_content_v4.schema.json'])==schema, 'Supplied schema differs from repository schema'
jsonschema.Draft202012Validator(schema,format_checker=jsonschema.FormatChecker()).validate(d)
assert d['context_sha256']==digest(c)
assert c['profile']==get_profile('pt-BR').manifest
assert d['base']==a.base_fingerprint(c['source_pack'])
assert len([o for o in d['operations'] if o['kind']=='create_target'])==20
assert len([o for o in d['operations'] if o['kind']=='create_deck'])==1
assert d['lang']=='pt-BR' and c['translation_lang']=='de'
assert not c['source_pack']['cards'] and not c['ownership']['words']
assert not d['submitted_reviews'], 'Delivery must not claim editorial approval'
assert 'editor.xlsx' not in entries
profile=get_profile('pt-BR'); findings=[]
for op in d['operations']:
 if op['kind']!='create_target':continue
 p=op['payload'];ctx=p['context'];g=ctx['gap']
 try:
  profile.gap(ctx['text'],g['start_pos'],g['end_pos'],p['card']['form'])
  expected=profile.tokenize(ctx['text'],(g['start_pos'],g['end_pos']))
  assert [{k:t[k] for k in ('idx','surface','start_pos','end_pos')} for t in ctx['tokens']]==[{k:t[k] for k in ('idx','surface','start_pos','end_pos')} for t in expected]
 except Exception as e:findings.append({'target_ref':op['target_ref'],'field':'payload.context.tokens/gap','error':str(e)})
assert not findings,findings
assert {o['target_ref'] for o in d['operations'] if o['kind']=='create_target'}==set(d['expected_target_refs'])
seed=root/'seed.json';seed.write_text(json.dumps(c['source_pack'],ensure_ascii=False))
store=Path(tempfile.mkdtemp(prefix='ptbr-import-'));service=EditorService(store,source=seed)
def wait(job):
 while job['state'] in ('queued','running','cancelling'):
  time.sleep(.05);job=service.store.get('jobs',job['job_id'])
 assert job['state']=='succeeded',job
 return job['result']
try:
 preview=wait(service.preview_upload(raw,backup.name,'pt-BR'))
 receipt=service.accept_import(preview['import_id'],preview['preview_sha256'])
 draft=service.store.load_draft(receipt['draft_id'])
 validation=wait(service.validate(draft['draft_id'],service.store.etag(draft)))['validation']
 assert not service.store.load_draft(draft['draft_id'])['reviews']
 result={'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'entries':list(entries),'store':str(store),'receipt':receipt,'validation':validation,'token_gap_errors':findings,'real_review':False,'release_created':False}
 (root/'delivery-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
 print(json.dumps({'sha256':result['sha256'],'bytes':result['bytes'],'technical':validation['technical'],'editorial':validation['editorial'],'token_gap_errors':findings,'store':str(store),'real_review':False,'release_created':False},ensure_ascii=False,indent=2))
finally:service.close()
