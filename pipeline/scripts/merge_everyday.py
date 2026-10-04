"""Offline, preconditioned merge using the existing curation/finalization path."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from sprachpipe.config import PIPELINE_DIR
from sprachpipe.curate import curate, derive_dictionary
from sprachpipe.export import export_sqlite
from sprachpipe.pack import build_rows
from finalize_curation import (
    INTERNAL_NOTE, OPEN_EDITORIAL, OLD_IDS_NOTE, check_pack, check_sqlite, finalize_state,
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--curation', type=Path, default=PIPELINE_DIR / 'data/curation/everyday_merge_v1.json')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--legacy', action='store_true', help='explicit replay of historical schema-1 curation')
    args = parser.parse_args()
    if args.out.exists():
        parser.error(f'output already exists: {args.out}')
    curation = json.loads(args.curation.read_text(encoding='utf8'))
    packs = {}
    for name, relative in curation['sources'].items():
        raw = (PIPELINE_DIR.parent / relative).read_bytes()
        if hashlib.sha256(raw).hexdigest() != curation['source_sha256'][name]:
            raise ValueError(f'source hash mismatch: {name}')
        packs[name] = json.loads(raw)
    if any(p.get('release', {}).get('schema_version') == 1 for p in packs.values()) and not args.legacy:
        parser.error('historical schema-1 merge requires --legacy; new content uses schema-2 Create')
    work, log = curate(packs, curation, curation['card_meta'])
    final, summary, before = finalize_state(
        work, {'inputs': {'curation_log': log}}, curation['dictionary_resolutions'])
    rows = check_pack(final, before)
    final_ids = {r['id'] for r in rows['cards']}
    for name, source in packs.items():
        if not {r['id'] for r in build_rows(source)['cards']} <= final_ids:
            raise ValueError(f'card IDs lost from {name}')
    # Keep provenance for every dictionary entry, not only conflicting keys.
    dictionary = derive_dictionary(work, curation['dictionary_resolutions']['resolutions'])
    report = dict(summary, status='failed', internal_test_pack=True, note=INTERNAL_NOTE,
                  old_ids_publication=OLD_IDS_NOTE, open_editorial_cases=OPEN_EDITORIAL,
                  sources=curation['sources'], source_sha256=curation['source_sha256'],
                  runs=curation['runs'], curation_log=log,
                  dictionary_provenance=dictionary['entries'],
                  selection_status=curation['selection_status'], exclusions=curation['exclusions'],
                  editorial_scope=curation['editorial_scope'], ai_cost_usd=0)
    args.out.mkdir(parents=True, exist_ok=False)
    try:
        path = args.out / 'pack.json'
        path.write_text(json.dumps(final, ensure_ascii=False, indent=1) + '\n', encoding='utf8')
        exported = export_sqlite(final, args.out / 'content.sqlite')
        report['sqlite_counts'] = check_sqlite(args.out / 'content.sqlite', rows)
        if exported != report['sqlite_counts'] or json.loads(path.read_text(encoding='utf8')) != final:
            raise ValueError('export mismatch')
        report['status'] = 'ok'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out / 'finalization_report.json').write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    print(f"status ok: {summary['cards']} cards, {summary['sentences']} sentences, "
          f"{summary['card_sentences']} links; all source card IDs retained")
    for table, count in report['sqlite_counts'].items():
        print(f'  sqlite {table}: {count} (= build_rows)')
    print(f"Offline cost: 0 USD; internal only; {len(OPEN_EDITORIAL)} old editorial groups remain")


if __name__ == '__main__':
    main()
