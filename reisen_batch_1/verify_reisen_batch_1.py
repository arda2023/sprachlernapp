"""Read-only delivery validation. --repo also uses the actual project's tokenizer/importer."""
import argparse,copy,hashlib,json,re,sys
from pathlib import Path
from collections import Counter
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path);args=p.parse_args()
here=Path(__file__).resolve().parent
read=lambda path:json.loads(path.read_text('utf8'))
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
def digest(x):return hashlib.sha256(json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
c=read(here/'reference/authoring_context.json');dic=read(here/'reference/dictionary_context.json');r=read(here/'reference/registry.json');d=read(here/'reisen_batch_1.editorial.json');a=d['add']
def display_mapping(selected):
 assert len({e['card_ref'] for e in selected})==len(selected),'duplicate selected card'
 assert len({e['position'] for e in selected})==len(selected),'duplicate original position'
 return {e['card_ref']:i for i,e in enumerate(sorted(selected,key=lambda e:e['position']),1)}
entries=sorted([e for e in c['entries'] if e['authoring_batch']==1],key=lambda e:e['position'])
positions=display_mapping(entries)
# Exercise later interleaving without generating cards or changing source rows.
expanded=[e for e in c['entries'] if e['authoring_batch'] in (1,2)]
expanded_positions=display_mapping(expanded)
assert sorted(expanded_positions.values())==list(range(1,201))
assert [expanded_positions[e['card_ref']] for e in entries]==sorted(expanded_positions[e['card_ref']] for e in entries)
assert positions[entries[5]['card_ref']]==6 and entries[5]['position']==26
assert expanded_positions[entries[5]['card_ref']]==11
print('PASS deterministic display mapping: batch 1=1..100; batches 1+2=1..200; original order retained')
assert len(entries)==100
assert d['source_sha256']==c['base_pack']['uploaded_json_sha256']
assert digest(r)==d['registry_sha256']==c['registry']['sha256']
try:
 import jsonschema
 jsonschema.validate(d,read(here/'reference/editorial_content_v2.schema.json'))
 print('PASS JSON Schema')
except ImportError:
 # Dependency-free adapter for every keyword used by the supplied schema.
 # Fail closed if the schema grows; never silently skip a constraint.
 def validate_schema(value,schema,path='$'):
  supported={'$schema','title','type','const','required','properties','additionalProperties','items','minItems','maxItems','uniqueItems','minLength','minimum','pattern'}
  assert not(set(schema)-supported),('unsupported schema keyword',path,set(schema)-supported)
  types={'object':lambda x:isinstance(x,dict),'array':lambda x:isinstance(x,list),
         'string':lambda x:isinstance(x,str),'integer':lambda x:isinstance(x,int) and not isinstance(x,bool),
         'boolean':lambda x:isinstance(x,bool),'null':lambda x:x is None,
         'number':lambda x:isinstance(x,(int,float)) and not isinstance(x,bool)}
  if 'type' in schema:
   names=schema['type'] if isinstance(schema['type'],list) else [schema['type']]
   assert all(n in types for n in names) and any(types[n](value) for n in names),('schema type',path)
  if 'const' in schema:assert type(value)==type(schema['const']) and value==schema['const'],('schema const',path)
  if isinstance(value,dict):
   assert set(schema.get('required',[]))<=set(value),('schema required',path)
   props=schema.get('properties',{})
   if schema.get('additionalProperties') is False:assert set(value)<=set(props),('schema additional properties',path)
   for key,v in value.items():
    if key in props:validate_schema(v,props[key],path+'.'+key)
  if isinstance(value,list):
   assert len(value)>=schema.get('minItems',0) and len(value)<=schema.get('maxItems',float('inf')),('schema item count',path)
   if schema.get('uniqueItems'):assert len({digest(v) for v in value})==len(value),('schema unique items',path)
   for i,v in enumerate(value):
    if 'items' in schema:validate_schema(v,schema['items'],path+'['+str(i)+']')
  if isinstance(value,str):
   assert len(value)>=schema.get('minLength',0),('schema length',path)
   if 'pattern' in schema:assert re.search(schema['pattern'],value),('schema pattern',path)
  if 'minimum' in schema:assert value>=schema['minimum'],('schema minimum',path)
 validate_schema(d,read(here/'reference/editorial_content_v2.schema.json'))
 print('PASS supplied schema constraints (strict local adapter; jsonschema package unavailable)')
for name,key in [('cards','ref'),('sentences','ref'),('lemmas','ref'),('senses','ref')]:
 assert len(a[name])==len({x[key] for x in a[name]}),(name,'duplicate')
assert len(a['cards'])==len(a['sentences'])==len(a['card_sentences'])==len(d['reviews'])==100
assert len({s['text'] for s in a['sentences']})==100
for e,card,dc,dw in zip(entries,a['cards'],a['deck_cards'],a['deck_words']):
 assert (card['ref'],card['form'],card['sense'])==(e['card_ref'],e['form'],e['sense_ref'])
 assert card['translation_de']==e['translation_de']
 assert dc=={'deck':'reisen','card':e['card_ref'],'position':positions[e['card_ref']]}
 assert dw=={'form_norm':e['form_norm'],'deck':'reisen','primary_card':e['card_ref'],'position':positions[e['card_ref']]}
 registered=next(x for x in r['words'] if x['lang']=='en' and x['form_norm']==e['form_norm'])
 assert registered['owner_deck_ref']=='reisen' and registered['primary_card_id']==e['card_id']
 assert registered['position']==e['position'] and registered['primary_card_ref']==e['card_ref']
assert [w['position'] for w in a['deck_words']]==list(range(1,101))
assert a['word_aliases']==[{'form_norm':al,'word':e['form_norm']} for e in entries for al in e['ownership_aliases']]
ls={x['ref']:x for x in dic['lemmas']};ss={x['ref']:x for x in dic['senses']}
assert not(set(ls)&{x['ref'] for x in a['lemmas']})
assert not(set(ss)&{x['ref'] for x in a['senses']})
ls.update({x['ref']:x for x in a['lemmas']});ss.update({x['ref']:x for x in a['senses']})
assert all(s['lemma'] in ls for s in ss.values())
base_pairs={(x['form'].lower(),x['sense']) for x in dic['dictionary_forms']}
new_pairs={(x['form'].lower(),x['sense']) for x in a['dictionary_forms']}
assert len(new_pairs)==len(a['dictionary_forms']) and not(base_pairs&new_pairs)
pairs=base_pairs|new_pairs
assert all(x['sense'] in ss for x in a['dictionary_forms'])
word_counts=[]
for s,review in zip(a['sentences'],d['reviews']):
 ts=[t for t in a['sentence_tokens'] if t['sentence']==s['ref']]
 links=[l for l in a['card_sentences'] if l['sentence']==s['ref']];assert len(links)==1
 link=links[0];card=next(c for c in a['cards'] if c['ref']==link['card']);words=[]
 assert [t['idx'] for t in ts]==list(range(len(ts)))
 covered=[]
 for t in ts:
  assert s['text'][t['start_pos']:t['end_pos']]==t['surface']
  covered.extend(range(t['start_pos'],t['end_pos']))
  if any(ch.isalpha() for ch in t['surface']):
   words.append(t);assert t['sense'] in ss and t['lemma']==ss[t['sense']]['lemma']
   assert (t['surface'].lower(),t['sense']) in pairs
  else:assert t['lemma'] is t['sense'] is t['card'] is None
 assert len(covered)==len(set(covered))
 assert set(covered)=={i for i,ch in enumerate(s['text']) if not ch.isspace()}
 assert 1<=len(words)<=20
 word_counts.append(len(words))
 assert sum(t['surface'].lower()==card['form'] for t in words)==1
 assert s['text'][link['gap_start']:link['gap_end']].lower()==card['form']
 targets=[t for t in words if t['card']==card['ref']];assert len(targets)==1
 t=targets[0];assert (t['start_pos'],t['end_pos'],t['sense'])==(link['gap_start'],link['gap_end'],card['sense'])
 assert link['accepted']==[card['form']] and link['position']==1
 assert all(x==x.strip().lower() and x!=card['form'] for x in link['valid_alternatives'])
 assert len(set(link['valid_alternatives']))==len(link['valid_alternatives'])
 assert review['sentence']==s['ref'] and review['decision']=='approved'
 assert review['checked']=={'text':s['text'],'translation_de':s['translation_de'],'tokens_sha256':digest(ts),'links_sha256':digest(links)}
 assert review['alternatives_checked']==[{'card':card['ref'],'alternative':alt,'text':s['text'][:link['gap_start']]+alt+s['text'][link['gap_end']:]} for alt in link['valid_alternatives']]
print('PASS 100 authoritative batch-1 identities, positions and reservations; 1 ownership alias')
print(f'PASS 100 sentences and gaps; {len(a["sentence_tokens"])} complete tokens; words/sentence {min(word_counts)}–{max(word_counts)}')
print('PASS sense references, dictionary coverage, immutable existing rows, 100 review hashes')
print('PASS literal alternative substitutions:',sum(len(l['valid_alternatives']) for l in a['card_sentences']))
if (here/'manifest.json').exists():
 for name,h in read(here/'manifest.json')['files'].items():assert sha(here/name)==h,('hash mismatch',name)
 print('PASS delivery file hashes')
if args.repo:
 root=args.repo.resolve();basepath=root/c['base_pack']['path'];base=read(basepath)
 assert sha(basepath)==d['source_sha256'],'Wrong base pack; do not rewrite the hash.'
 assert digest(base)==c['base_pack']['canonical_json_sha256']
 assert read(root/c['registry']['path'])==r,'Wrong reservation registry.'
 assert read(root/'pipeline/data/selection/reisen_500_v1.json')['entries']==c['entries'],'Selection changed.'
 assert (root/'pipeline/data/curation/editorial_content_v2.schema.json').read_bytes()==(here/'reference/editorial_content_v2.schema.json').read_bytes(),'Schema changed; inspect before import.'
 sys.path[:0]=[str(root/'pipeline/src'),str(root/'pipeline/scripts')]
 from sprachpipe.annotate import tokenize
 from sprachpipe.pack import build_rows
 from sprachpipe.ids import stable_id
 from import_editorial_patch import create_content
 for s in a['sentences']:
  actual=[(t['idx'],t['surface'],t['start_pos'],t['end_pos']) for t in tokenize(s['text'])]
  provided=[(t['idx'],t['surface'],t['start_pos'],t['end_pos']) for t in a['sentence_tokens'] if t['sentence']==s['ref']]
  assert actual==provided,('tokenizer mismatch',s['ref'])
 for e in entries:
  lid=stable_id('lemmas',lang='en',lemma=e['lemma'],pos=e['pos'])
  sid=stable_id('senses',lemma_id=lid,sense_key=e['sense_key'] or e['proposed_sense_key'])
  assert (lid,sid,stable_id('cards',lang='en',form=e['form'],sense_id=sid))==(e['lemma_id'],e['sense_id'],e['card_id'])
 before=digest(base);d_before=digest(d);r_before=digest(r)
 print('PASS actual project tokenizer and all recomputed stable IDs',flush=True)
 work=create_content(copy.deepcopy(base),copy.deepcopy(d),copy.deepcopy(r),source_hash=sha(basepath))
 rows=build_rows(work)
 assert len(rows['cards'])==364 and len(rows['sentences'])==898
 assert len(rows['deck_words'])==260 and len(rows['card_sentences'])==892
 assert digest(base)==before and digest(d)==d_before and digest(r)==r_before
 print('PASS actual tokenizer, recomputed IDs, create_content, build_rows: 364 cards / 898 sentence texts / 260 primary words')
 print('No export, staging, cloud calls or database writes.')
else:
 import spacy
 nlp=spacy.blank('en')
 for s in a['sentences']:
  actual=[(t.i,t.text,t.idx,t.idx+len(t.text)) for t in nlp(s['text'])]
  provided=[(t['idx'],t['surface'],t['start_pos'],t['end_pos']) for t in a['sentence_tokens'] if t['sentence']==s['ref']]
  assert actual==provided,('token boundary mismatch',s['ref'])
 print('PASS spaCy English tokenizer boundaries (blank en, no automatic POS judgments)')
 print('NOT RUN: current project create_content/build_rows/export; use --repo for local acceptance.')
