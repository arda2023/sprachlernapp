"""Real manifest source, synthetic confirmation, isolated local workspace only."""
import json,time,uuid
from pathlib import Path
from sprachpipe.authoring_service import ROOT
from sprachpipe.editor.service import EditorService
from sprachpipe.editor.publisher import inspect_bundle
from sprachpipe.baseline_adoption import resolve_source
root=ROOT/'build/baseline_adoption'/('real-isolated-'+uuid.uuid4().hex)
source=ROOT/'assets/content/en';pack,spec=resolve_source(source)
manifest=json.loads((source/'content.manifest.json').read_text())
service=EditorService(root,source=(ROOT/manifest['source']['path']).with_name('pack.json'),asset_directory=source)
try:
 before=service.store.get('heads','en');draft=service.new_draft('en','allgemeine-sprache')
 preview=service.adoption_preview();job=service.adopt_baseline({'accepted':True,'preview_sha256':preview['sha256']})
 last=None
 while True:
  job=service.store.get('jobs',job['job_id'])
  if job['message']!=last:print(job['message'],flush=True);last=job['message']
  if job['state'] not in ('running','queued'):break
  time.sleep(.2)
 assert job['state']=='succeeded',job
 record=job['result'];bundle=root/record['path'];m,objects=inspect_bundle(bundle,record,None)
 assert before==service.store.get('heads','en') and draft==service.store.load_draft(draft['draft_id'])
 result={'synthetic_confirmation_only':True,'workspace':str(root),'bundle':str(bundle),'manifest':m,'objects':objects,'tables':23,'draft_unchanged':True,'head_unchanged':True}
 (ROOT/'build/baseline_adoption/real-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({k:v for k,v in result.items() if k not in ('manifest','objects')},indent=2),flush=True)
finally:service.close()
