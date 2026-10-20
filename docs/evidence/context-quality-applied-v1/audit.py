"""Read-only, source-bound audit of the three approved production deltas."""
import hashlib
import json
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / 'pipeline/src'), str(ROOT / 'pipeline/scripts')]
from sprachpipe.pack import build_rows
from sprachpipe.schema import primary_key
from sprachpipe.curate import sentence_id
from sprachpipe.generate import gap_offsets
from finalize_curation import check_sqlite

source_path = ROOT / 'pipeline/out/business_email_batch_6_perf_v1/pack.json'
out = ROOT / 'pipeline/out/context_quality_applied_v1'
patch = json.loads((ROOT / 'pipeline/data/curation/context_quality_apply_v1.json').read_text())
assert hashlib.sha256(source_path.read_bytes()).hexdigest() == patch['source_sha256']
source = json.loads(source_path.read_text())
after = json.loads((out / 'pack.json').read_text())
before_rows, after_rows = build_rows(source), build_rows(after)
assert len(before_rows) == len(after_rows) == 22
counts = check_sqlite(out / 'content.sqlite', after_rows)
check_sqlite(ROOT / 'pipeline/out/business_email_batch_6_perf_v1/content.sqlite', before_rows)
A, B, C = [op['card_id'] for op in patch['operations']]
version = 'context_quality_applied_v1'
assert after['release']['version'] == version
old_sid = 'dd8ab9cfb2023421fe9e62249c9e509a'
new_sid = sentence_id('en', "The kitchen is clean. Let's keep it that way.")
assert new_sid == 'ffc8ac9d8c30d444dc471a2c1425bbf4'
assert gap_offsets(patch['operations'][1]['sentence']['text'], "let's keep it that way") == (22, 44)
contexts = {t['sentence_id'] for t in before_rows['sentence_tokens'] if t.get('card_id') == A}
assert contexts == {'1e047de6e0a0f09136a14753a634cb52','6b16d298c448ea845b600cfd8eb27637','d35bd278154554f67175421eda5326d1'}
changes = {}
for table, old_rows in before_rows.items():
    key = primary_key(table)
    old = {r[key]: r for r in old_rows}
    new = {r[key]: r for r in after_rows[table]}
    if table == 'content_releases':
        changes[table] = {'before':len(old),'after':len(new),'release_replaced':True}
        continue
    assert old.keys() <= new.keys(), (table, 'deleted IDs')
    added = [r for k,r in new.items() if k not in old]
    edited = []
    for k, row in old.items():
        if row == new[k]: continue
        fields = {f for f in row.keys() | new[k].keys() if row.get(f) != new[k].get(f)}
        if table == 'cards':
            assert (k == A and fields == {'removed_in'} and new[k]['removed_in']==version) or (k == C and fields=={'translation_de'} and new[k]['translation_de']=='so (umgangssprachlich als Zitateinleitung)')
        elif table == 'card_sentences':
            assert row['card_id'] in {A,B} and not row.get('removed_in')
            assert fields == ({'removed_in'} if row['card_id']==A else {'removed_in','replaced_by'})
            assert new[k]['removed_in']==version
        elif table in {'sentences','sentence_tokens'}:
            sid = k if table=='sentences' else row['sentence_id']
            assert sid in contexts and fields=={'removed_in'} and new[k]['removed_in']==version
        elif table == 'dictionary_forms':
            assert row.get('card_id') == A and fields=={'removed_in'} and new[k]['removed_in']==version
        else: raise AssertionError((table,k,fields))
        edited.append({'id':k,'fields':sorted(fields)})
    if added:
        assert table in {'sentences','sentence_tokens','card_sentences'}
        for row in added:
            assert (row['id'] if table=='sentences' else row['sentence_id'])==new_sid
        assert len(added)=={'sentences':1,'sentence_tokens':7,'card_sentences':1}[table]
    changes[table]={'before':len(old),'after':len(new),'added':[r[key] for r in added],'edited':edited,'unchanged':len(old)-len(edited)}
assert [r for r in before_rows['sentences'] if r['id']==old_sid] == [r for r in after_rows['sentences'] if r['id']==old_sid]
assert [r for r in before_rows['sentence_tokens'] if r['sentence_id']==old_sid] == [r for r in after_rows['sentence_tokens'] if r['sentence_id']==old_sid]
old_gaps=[]
new_gaps=[]
for rows, gaps in [(before_rows,old_gaps),(after_rows,new_gaps)]:
    ids={r['id'] for r in rows['sentences']}
    for r in rows['sentences']:
        q=r.get('qa_report') or {}
        old=q.get('historical_source_sentence_id')
        if old and old not in ids:gaps.append(old)
assert old_gaps==new_gaps and len(old_gaps)==137
conn=sqlite3.connect(f'file:{out / "content.sqlite"}?mode=ro',uri=True)
indexes={r[0]:r[1] for r in conn.execute("SELECT name,sql FROM sqlite_master WHERE type='index' AND sql IS NOT NULL")}
assert {'idx_sentence_tokens_active_sentence_idx','idx_dictionary_forms_active_lookup'} <= indexes.keys()
conn.close()
finalization=json.loads((out/'finalization_report.json').read_text())
assert finalization['status']=='ok' and finalization['lint']['errors']==0
result={'status':'content_export_audit_pass','pending':0,'tables':changes,'sqlite_counts':counts,'indexes':indexes,'old_provenance_gaps_unchanged':137,'active_cards_before':sum(not r.get('removed_in') for r in before_rows['cards']),'active_cards_after':sum(not r.get('removed_in') for r in after_rows['cards']),'historical_links_before':sum(bool(r.get('removed_in')) for r in before_rows['card_sentences']),'historical_links_after':sum(bool(r.get('removed_in')) for r in after_rows['card_sentences']),'sha256':hashlib.sha256((out/'content.sqlite').read_bytes()).hexdigest()}
print(json.dumps(result,ensure_ascii=False,indent=2))
