"""Bundle existing editorial stories without inventing dictionary annotations."""
from pathlib import Path
import json, math

root=Path(__file__).resolve().parents[1]
r=root/'story_library';manifest=json.loads((r/'manifest.json').read_text()); originals=json.loads((r/'originals.json').read_text())
for lang in manifest['languages']:
 rows=[]
 for item in manifest['items']+ [x for x in originals if x['language']==lang]:
  p=r/lang/(item['id']+'.txt')
  if not p.exists():continue
  title,body=p.read_text().split('\n',1)
  rows.append(dict(id=f"library:{lang}:{item['id']}",title=title,topic=item.get('category') or {'video_08':'Wirtschaft','video_09':'Wirtschaft','video_34':'Gesundheit','video_35':'Gesundheit','video_36':'Kriminalfälle','video_38':'Gesellschaft','video_39':'Gesundheit','video_40':'Wissenschaft'}[item['id']],body=body.strip(),minutes=math.ceil(len(body.split())/120)))
 (root/f'assets/content/{lang}/stories.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
 print(lang,len(rows),'bundled stories')
