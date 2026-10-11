from pathlib import Path
import json,sys,copy,hashlib,sqlite3,collections,jsonschema,unicodedata
P=Path(__file__).parent;C=P/'alltagssprache_redewendungen_authoring_batch_2';O=P/'output/alltagssprache_redewendungen_batch_2'
sys.path.insert(0,str(C/'pipeline/src'))
from sprachpipe.pack import build_rows
from sprachpipe.ids import stable_id,form_norm
from sprachpipe.word_registry import digest,index_registry
read=lambda p:json.loads(p.read_text());canonical=lambda x:json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode();sha=lambda x:hashlib.sha256(canonical(x)).hexdigest()
a=read(C/'authoring_context.json');base=read(C/'pack.json');d=read(O/'editorial_content_v2.json');registry=read(C/'registry.json');tokens=read(P/'tokens.json')
jsonschema.validate(d,read(C/'pipeline/data/curation/editorial_content_v2.schema.json'))
assert d['source_sha256']==hashlib.sha256((C/'pack.json').read_bytes()).hexdigest()
assert digest(registry)==d['registry_sha256'];index_registry(registry)
assert len(d['add']['cards'])==len(a['entries'])==89
assert[d['ref']for d in d['add']['cards']]==[e['card_ref']for e in a['entries']]
for e,card in zip(a['entries'],d['add']['cards']):
 for key in ['form','translation_de','form_kind','form_label_de','learning']:assert e[key]==card[key]
 assert card['sense']==e['sense_ref'];assert stable_id('cards',lang='en',form=card['form'],sense_id=e['sense_id'])==e['card_id']
work=copy.deepcopy(base)
for table,rows in d['add'].items():
 work.setdefault(table,[]).extend(copy.deepcopy(rows))
 for field in ['ref'] if table in ['lemmas','senses','cards','decks','sentences']else[]:assert len({r[field]for r in work[table]})==len(work[table])
work['release']=dict(version=d['version'],schema_version=4,notes='INTERNES TEST-PACK: validation in memory only')
work['word_registry']=dict(sha256=digest(registry),snapshot=registry)
rows=build_rows(work);old=build_rows(base)
for tab in ['lexical_targets','card_lexical_targets','form_targets','deck_practice_targets']:assert work[tab]==base[tab];assert rows[tab]==old[tab]
# Every old exported row stays intact, aside from replacement release metadata.
for tab,oldrows in old.items():
 if tab=='content_releases':continue
 keyed={canonical(r)for r in rows[tab]}
 assert all(canonical(r)in keyed for r in oldrows),tab
from sprachpipe.deck_display import apply_deck_display_patch
patch=read(O/'deck_display_patch.json')
final=apply_deck_display_patch(work,patch,source_sha256=d['source_sha256'],create_sha256=hashlib.sha256((O/'editorial_content_v2.json').read_bytes()).hexdigest(),registry_sha256=d['registry_sha256'])
for table in work:
 if table not in ['deck_cards','deck_words']:assert final[table]==work[table],table
for table in ['deck_cards','deck_words']:
 for before,after in zip(work[table],final[table]):
  assert {k:v for k,v in before.items()if k!='position'}=={k:v for k,v in after.items()if k!='position'}
  if before['deck']!=a['existing_deck']:assert before==after
 assert sorted(x['position']for x in final[table]if x['deck']==a['existing_deck'])==list(range(1,179))
rows=build_rows(final)
# Every proposed alternative is checked against all selection forms, aliases and source ownership.
identities=read(C/'all_selection_identities.json')
selection_forms={form_norm(x['form'])for x in identities}
owned={form_norm(x['form_norm'])for x in base['deck_words']}
aliases={form_norm(x['form_norm'])for x in base['word_aliases']}
for link in d['add']['card_sentences']:
 for alt in link['valid_alternatives']:
  assert form_norm(alt)==alt
  assert alt not in selection_forms|owned|aliases,('alternative collision',alt)
assert 'in my opinion'not in selection_forms
assert len(identities)==441

ss={s['ref']:s for s in work['senses']};forms={(x['form'],x['sense'])for x in work['dictionary_forms']}
for e,s,r in zip(a['entries'],d['add']['sentences'],d['reviews']):
 ts=[t for t in d['add']['sentence_tokens']if t['sentence']==s['ref']];links=[l for l in d['add']['card_sentences']if l['sentence']==s['ref']];link=links[0];expected=tokens[e['form']]
 assert len(links)==1 and link['position']==1
 assert s['text'][link['gap_start']:link['gap_end']].lower()==e['form'].lower()
 assert link['accepted']==[e['form']]
 assert [{k:t[k]for k in ['idx','surface','start_pos','end_pos']}for t in ts]==[{k:t[k]for k in ['idx','surface','start_pos','end_pos']}for t in expected]
 for t,x in zip(ts,expected):
  if x['is_word']:assert t['sense']in ss and t['lemma']==ss[t['sense']]['lemma'] and(form_norm(t['surface']),t['sense'])in forms
  else:assert t['sense']is None and t['lemma']is None
 assert r['checked']==dict(text=s['text'],translation_de=s['translation_de'],tokens_sha256=sha(ts),links_sha256=sha(links))
 assert r['alternatives_checked']==[dict(card=link['card'],alternative=x,text=s['text'][:link['gap_start']]+x+s['text'][link['gap_end']:])for x in link['valid_alternatives']]
# Read-only 22-table source SQLite row comparison, including JSON and array columns.
con=sqlite3.connect(f'file:{(C/"content.sqlite").resolve()}?mode=ro',uri=True);con.row_factory=sqlite3.Row
assert con.execute('pragma integrity_check').fetchone()[0]=='ok'
for tab,rr in old.items():
 actual=[dict(x)for x in con.execute('SELECT * FROM "'+tab+'"')]
 expected=[{k:json.dumps(v,ensure_ascii=False)if isinstance(v,(list,dict))else int(v)if isinstance(v,bool)else v for k,v in x.items()}for x in rr]
 columns=[x[1]for x in con.execute('PRAGMA table_info("'+tab+'")')]
 expected=[{k:x.get(k)for k in columns}for x in expected]
 if tab=='content_releases':
  assert len(actual)==1 and actual[0]['created_at']
  for x in actual+expected:x.pop('created_at',None)
 # Structured values compare semantically, not serialization whitespace.
 def norm(x):
  for k,v in x.items():
   if isinstance(v,str)and v[:1]in '[{':
    try:x[k]=json.loads(v)
    except json.JSONDecodeError:pass
  return x
 actual=sorted((norm(x)for x in actual),key=canonical);expected=sorted((norm(x)for x in expected),key=canonical);assert actual==expected,tab
con.close()
# Execute the unmodified create_content function in memory with the exact source tokenizer.
# Extract pure functions by AST, avoiding unrelated model-client import chains.
import ast,spacy
nlp=spacy.load(C/'runtime/en_core_web_sm',disable=['ner'])
ns={'ROOT':C,'read':read,'digest':sha,'copy':copy,'stable_id':stable_id,'form_norm':form_norm,'build_rows':build_rows,'CurationError':ValueError,'_nlp':lambda:nlp}
for filename,names in [('pipeline/src/sprachpipe/annotate.py',{'tokenize'}),('pipeline/scripts/import_editorial_patch.py',{'require','create_content'})]:
 tree=ast.parse((C/filename).read_text())
 body=[n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name in names]
 assert {n.name for n in body}==names
 exec(compile(ast.Module(body=body,type_ignores=[]),filename,'exec'),ns)
base_before=canonical(base);delivery_before=canonical(d)
created=ns['create_content'](base,d,registry,source_hash=d['source_sha256'])
assert canonical(base)==base_before and canonical(d)==delivery_before
created=apply_deck_display_patch(created,patch,source_sha256=d['source_sha256'],create_sha256=hashlib.sha256((O/'editorial_content_v2.json').read_bytes()).hexdigest(),registry_sha256=d['registry_sha256'])
created_rows=build_rows(created)
assert {t:len(v)for t,v in created_rows.items()}=={t:len(v)for t,v in rows.items()}

f=read(P/'linter.json');assert not[x for x in f if x['level']=='error']
report=dict(status='PASS',input_hashed_files=len(read(C/'manifest.json')['files']),source_sqlite_tables_compared=len(old),source_comparison_exception='content_releases.created_at is export-generated; presence checked, omitted from value comparison',new_cards=89,new_sentences=89,token_positions=len(d['add']['sentence_tokens']),word_tokens=sum(t['sense']is not None for t in d['add']['sentence_tokens']),alternatives=sum(len(l['valid_alternatives'])for l in d['add']['card_sentences']),new_senses=len(d['add']['senses']),new_dictionary_forms=len(d['add']['dictionary_forms']),linter_errors=0,linter_warnings=f,in_memory_create_content='PASS: unmodified source function extracted by AST, exact source tokenizer; no CLI/export',in_memory_build_rows='PASS',display_patch='PASS: only deck positions changed; final 1..178',alternative_selection_owner_alias_scan='PASS: all 441 selection identities and current ownership',selection_count=441,batch_partition=[89,89,263],source_rows_preserved='PASS',schema4_form_tables_unchanged='PASS',result_table_counts={k:len(v)for k,v in rows.items()},production_import_executed=False,staging_executed=False,flutter_tests_executed=False,device_test_executed=False,cloud_model_calls=0,limitations=['No independent human language review.','Full repository import/export and device acceptance remain local tasks.'])
(O/'validation_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False,indent=2))
