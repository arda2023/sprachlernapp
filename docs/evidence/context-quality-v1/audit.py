"""Read-only audit of the bound review; never imports/stages content.

Run with the pipeline Python from the repository root. --out must be new.
The output is evidence of a BLOCKED curation, never a finalization report.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / 'pipeline/scripts'), str(ROOT / 'pipeline/src')]
from import_editorial_patch import digest, make_plan, verify_exchange
from finalize_curation import check_sqlite
from sprachpipe.config import load_config
from sprachpipe.linter import lint_sentence
from sprachpipe.pack import build_rows

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
assert not args.out.exists(), 'output directory already exists'
review = json.loads((ROOT / 'docs/evidence/context-quality-v1/review.json').read_text())
patch = json.loads((ROOT / 'pipeline/data/curation/context_quality_v1.json').read_text())
source_path = ROOT / patch['source']['file_name']
raw = source_path.read_bytes()
source = json.loads(raw)
asset = ROOT / 'assets/content/en/content.sqlite'
assert hashlib.sha256(raw).hexdigest() == review['source_sha256'] == patch['source']['sha256']
assert digest(source) == patch['source']['canonical_json_sha256']
assert hashlib.sha256(asset.read_bytes()).hexdigest() == review['asset_sha256']
manifest = json.loads((ROOT / 'assets/content/en/content.manifest.json').read_text())
assert manifest['sha256'] == review['asset_sha256']
assert manifest['size_bytes'] == asset.stat().st_size
rows = build_rows(source)
counts = check_sqlite(asset, rows)
assert len(counts) == 22

with sqlite3.connect(asset.resolve().as_uri() + '?mode=ro', uri=True) as db:
    db.row_factory = sqlite3.Row
    active = [dict(r) for r in db.execute(review['query'])]
    indexes = {r['name']: r['sql'] for r in db.execute("SELECT name,sql FROM sqlite_master WHERE type='index'")}
assert 'WHERE removed_in IS NULL' in indexes['idx_sentence_tokens_active_sentence_idx']
assert 'WHERE removed_in IS NULL' in indexes['idx_dictionary_forms_active_lookup']
assert len(active) == review['searched']
legacy_refs = {s['ref'] for s in source['sentences']
               if re.search(r'pilot_60_v1/s(\d+)$', s['ref'])
               and int(re.search(r'/s(\d+)$', s['ref'])[1]) in review['legacy_sentence_numbers']}
legacy_cards = {link['card'] for link in source['card_sentences'] if link['sentence'] in legacy_refs}
legacy_ids = {r['id'] for c, r in zip(source['cards'], rows['cards']) if c['ref'] in legacy_cards}
expected = set()
for item in active:
    if (any(re.search(pattern, item['text']) for pattern in review['patterns'].values() if pattern)
            or item['sense_key'] == 'so#auf_diese_weise'
            or item['sense_key'] in review['legacy'] + review['legacy_gloss_keys']
            or item['card_id'] in legacy_ids):
        expected.add(item['card_id'])
assert expected == {r['card_id'] for r in review['candidates']}, 'review misses search candidates'
assert len(expected) == len(review['candidates'])
active_by_card = {r['card_id']: r for r in active}
for record in review['candidates']:
    actual = active_by_card[record['card_id']]
    assert all(record[k] == v for k, v in actual.items()), 'review source changed'
    substitutions = [record['text'][:record['gap_start']] + a + record['text'][record['gap_end']:]
                     for a in json.loads(record['valid_alternatives'])]
    assert substitutions == record['substitutions']
    assert record['decision'] in ('confirmed', 'borderline', 'unproblematic') and record['reason']

# Use the existing exchange validator for every proposed operation and every
# actually read record. Do not label the remaining 4185 links as "read/keep".
operations = {(o['card_ref'], o['sentence_ref']): o for o in patch['sentence_operations']}
corpus = {'source_sha256': patch['source']['sha256'], 'stats': patch['stats'], 'records': []}
for record in review['candidates']:
    before = {k: record[k] for k in ('text', 'translation_de', 'gap_start', 'gap_end')}
    link = next(l for l in source['card_sentences']
                if l['card'] == record['card_ref'] and l['sentence'] == record['sentence_ref'])
    before.update(accepted=link['accepted'], valid_alternatives=link.get('valid_alternatives', []))
    operation = operations.get((record['card_ref'], record['sentence_ref']))
    corpus['records'].append(dict(card_ref=record['card_ref'], sentence_ref=record['sentence_ref'],
        card_id=record['card_id'], old_sentence_id=record['sentence_id'], before=before,
        after=operation['new'] if operation else before,
        proposed_sentence_id=operation['new_sentence_id'] if operation else record['sentence_id'],
        status='rewrite' if operation else ('hold_recommended' if record['number'] == 3 else 'keep')))
blockers = {}
try:
    verify_exchange(raw, patch, corpus)
except ValueError as error:
    assert str(error) == 'corpus does not cover every sentence link'
    blockers['exchange_scope'] = str(error)
else:
    raise AssertionError('expected documented full-corpus requirement')
for operation in patch['metadata_operations']:
    found = [r for r in source[operation['table']] if r['ref'] == operation['ref']]
    assert len(found) == 1 and found[0][operation['field']] == operation['expect']
    assert operation['affected_card_refs'] == [found[0]['ref']]
assert patch['card_recommendations'][0]['card_id'] == review['candidates'][2]['card_id']
assert patch['card_recommendations'][0]['status'] == 'recommendation_not_applied'

# Independent, in-memory counterexample to "just set removed_in".
probe = copy.deepcopy(source)
next(c for c in probe['cards'] if c['ref'] == patch['card_recommendations'][0]['card_ref'])['removed_in'] = 'context_quality_v1'
try:
    build_rows(probe)
except ValueError as error:
    assert str(error) == 'learning: missing/retired/foreign primary'
    blockers['single_card_tombstone'] = str(error)
else:
    raise AssertionError('retired self-headed group unexpectedly accepted')
try:
    make_plan(source, patch)
except KeyError as error:
    blockers['legacy_make_plan'] = str(error)
else:
    raise AssertionError('legacy plan now supports complete ownership; revisit blocker')
assert digest(source) == patch['source']['canonical_json_sha256'], 'probe mutated source'

cfg = load_config()
proposed_lint = []
for operation in patch['sentence_operations']:
    new = operation['new']
    findings = lint_sentence(new['text'], new['accepted'][0], new['gap_start'], new['gap_end'],
        cfg['linter']['min_zipf']['anfaenger'], lang='en', names=cfg['generate']['names'],
        max_words=cfg['linter']['max_words'], max_subclauses=cfg['linter']['max_subclauses'])
    proposed_lint += [{'level': f.level, 'rule': f.rule, 'message': f.message} for f in findings]
assert not any(f['level'] == 'error' for f in proposed_lint), proposed_lint
result = {'status': 'blocked_not_applied', 'searched_active_links': len(active),
          'editorially_read_active_pairs': len(expected), 'source_sha256': review['source_sha256'],
          'unchanged_asset_sha256': review['asset_sha256'], 'source_table_counts': counts,
          'performance_indexes': {k: v for k, v in indexes.items() if k.startswith('idx_')},
          'blockers': blockers, 'proposed_sentence_lint': proposed_lint,
          'exported': False, 'staged': False, 'cloud_calls': 0}
args.out.mkdir(parents=True, exist_ok=False)
(args.out / 'review_audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
