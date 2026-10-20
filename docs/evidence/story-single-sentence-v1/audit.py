"""Read-only comparison of every exported table and all historical identities."""
import json
import hashlib
from pathlib import Path
import sqlite3
import sys
ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT/'pipeline/src'), str(ROOT/'pipeline/scripts')]
from sprachpipe.pack import build_rows
from sprachpipe.schema import primary_key
from finalize_curation import check_sqlite

old = build_rows(json.loads((ROOT/'pipeline/out/story_contexts_v1/pack.json').read_text()))
out = ROOT/'pipeline/out/story_single_sentence_v1'
new = build_rows(json.loads((out/'pack.json').read_text()))
counts = check_sqlite(out/'content.sqlite', new)
changes = {}
for table in old:
    if table == 'content_releases': continue
    key = primary_key(table)
    a = {r[key]:r for r in old[table]}; b = {r[key]:r for r in new[table]}
    assert a.keys() == b.keys(), table
    changed = []
    for k in a:
        if a[k] == b[k]: continue
        assert table == 'sentences'
        expected = dict(b[k]); qa = dict(expected['qa_report']); qa['story_practice_contexts'] = a[k]['qa_report']['story_practice_contexts']
        expected['qa_report'] = qa
        assert expected == a[k]
        changed.append(k)
    changes[table] = changed
assert len(changes['sentences']) == 5
assert len(new['deck_practice_targets']) == 402
assert sum(bool(r.get('removed_in')) for r in new['card_sentences']) == 530

def missing(rows):
    ids = {r['id'] for r in rows['sentences']}
    return [r['qa_report']['historical_source_sentence_id'] for r in rows['sentences']
            if (r.get('qa_report') or {}).get('historical_source_sentence_id') not in ids
            and (r.get('qa_report') or {}).get('historical_source_sentence_id')]
assert missing(old) == missing(new) and len(missing(new)) == 137
with sqlite3.connect(f'file:{out / "content.sqlite"}?mode=ro', uri=True) as db:
    indexes = {r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='index'")}
assert {'idx_sentence_tokens_active_sentence_idx','idx_dictionary_forms_active_lookup'} <= indexes
report = json.loads((out/'finalization_report.json').read_text())
assert report['status'] == 'ok' and report['lint']['errors'] == 0
print(json.dumps({'status':'passed','tables':counts,'changed_ids':changes,
    'form_memberships':402,'historical_links':530,'unchanged_old_provenance_gaps':137,
    'sha256':hashlib.sha256((out/'content.sqlite').read_bytes()).hexdigest()}, indent=2))
