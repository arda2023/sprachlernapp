"""Resumable editorial corpus production; never publishes or asserts human approval."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path

from sprachpipe.config import load_config
from sprachpipe.llm import Llm, MODEL


FIELDS = ('form', 'lemma', 'pos', 'gloss_de', 'sentence', 'translation_de')
SCHEMA = {'type': 'object', 'properties': {'rows': {'type': 'array', 'items': {
    'type': 'object', 'properties': {k: {'type': 'string'} for k in FIELDS},
    'required': list(FIELDS), 'additionalProperties': False}}},
    'required': ['rows'], 'additionalProperties': False}


def normalized(text):
    return unicodedata.normalize('NFC', text).casefold().replace('’', "'").strip()


def check(rows, excluded):
    errors = []
    seen = set(excluded)
    for i, row in enumerate(rows):
        form = normalized(row['form'])
        if not form or form in seen:
            errors.append(f'{i}: duplicate or empty target {form}')
        seen.add(form)
        if row['pos'] not in {'NOUN', 'VERB', 'ADJ', 'ADV', 'ADP', 'PRON', 'DET', 'CCONJ', 'SCONJ', 'NUM', 'INTJ', 'AUX', 'PART'}:
            errors.append(f'{i}: invalid UD part of speech')
        for key in ('sentence', 'translation_de'):
            text = row[key]
            if any(c == ';' or unicodedata.category(c) == 'Pd' or c in '\u00ad\u2212' for c in text):
                errors.append(f'{i}: forbidden punctuation in {key}')
            if not re.fullmatch(r'[^.!?\n]+[.!?]', text.strip()):
                errors.append(f'{i}: must be one complete sentence in {key}')
        if len(re.findall(r"\w+(?:['’]\w+)*", row['sentence'])) > 14:
            errors.append(f'{i}: more than 14 words')
        occurrences = list(re.finditer(r'(?<!\w)' + re.escape(form) + r'(?!\w)', normalized(row['sentence'])))
        if len(occurrences) != 1:
            errors.append(f'{i}: target must appear exactly once verbatim')
    return errors


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--lang', choices=['pt-BR', 'nb', 'it', 'es'], required=True)
    parser.add_argument('--provider', choices=['anthropic', 'vertex'], required=True)
    parser.add_argument('--max-usd', type=float, default=8)
    parser.add_argument('--limit-batches', type=int, default=0)
    args = parser.parse_args()
    inventory = json.loads((args.root / 'inventory.json').read_text())
    cfg = load_config()
    cfg['llm']['provider'] = args.provider
    folder = args.root / args.lang
    folder.mkdir(parents=True, exist_ok=True)
    llm = Llm(cfg, folder / f'{args.provider}-costs.csv', args.max_usd)
    language = inventory['languages'][args.lang]
    excluded = set()
    calls = 0
    policy = (f'Write authentic {language} learning material for German-speaking adults. '
              'Each target needs exactly ONE short complete standalone grammatical sentence, maximum 14 words, '
              'at most one subordinate clause. No dialogue, sentence fragments, unexplained references, '
              'hyphens, any dashes, semicolons or abbreviations. These punctuation rules apply to German translations too. '
              'Sentences should demonstrate meaning with concrete everyday context. '
              'The exact target form must occur once, contiguously, with the same spelling. '
              'Use natural native phrasing and faithful idiomatic German translations. '
              'form is the precise practiced form or natural expression, lemma the dictionary form, '
              'pos a UD part of speech, gloss_de its precise German meaning in this context. '
              'Do not create spelling variants or inflections merely to inflate the count. '
              'Prefer useful A1 to B2 vocabulary; specialized topics can include C1. '
              'For verbal expressions use authentic expressions of this language, not English calques. ')
    for deck in inventory['decks']:
        path = folder / (deck['slug'] + '.json')
        record = json.loads(path.read_text()) if path.exists() else {
            'lang': args.lang, 'deck': deck, 'rows': [], 'batches': [],
            'status': 'in_progress', 'human_review': False}
        excluded.update(normalized(r['form']) for r in record['rows'])
        while len(record['rows']) < deck['target_count']:
            n = min(12, deck['target_count'] - len(record['rows']))
            instruction = policy + f'\nDeck: {deck["title_de"]}. Create exactly {n} NEW distinct targets. '
            if deck['kind'] != 'ordinary':
                instruction += ('Use genuinely irregular verbs appropriate to this language and the indicated form category; '
                                'do not claim regular verbs are irregular. Use common compounds of irregular verbs where natural. ')
            instruction += '\nAlready reserved target forms, do not reuse: ' + json.dumps(sorted(excluded), ensure_ascii=False)
            result = llm.generate_json(instruction, SCHEMA, model=MODEL,
                                      thinking={'type': 'disabled'}, step='sentences', max_output_tokens=4096)
            rows = result['rows']
            raw_hash = hashlib.sha256(json.dumps(rows, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
            save(folder / 'raw' / f'{deck["slug"]}-{len(record["rows"]):04d}.json', rows)
            findings = check(rows, excluded)
            review_prompt = (policy + '\nAct as a meticulous native-language editor. Read and correct EVERY supplied row, '
                             'including grammar, idiomatic phrasing, standalone clarity, target sense, German gloss and '
                             'translation, and suitability for the deck. Return every corrected row, not just changes. '
                             f'Deck: {deck["title_de"]}. Return exactly {n} distinct useful rows. '
                             'Replace unusable or duplicate targets with suitable new ones. '
                             '\nReserved forms: ' + json.dumps(sorted(excluded), ensure_ascii=False) +
                             '\nTechnical findings: ' + json.dumps(findings, ensure_ascii=False) +
                             '\nRows: ' + json.dumps(rows, ensure_ascii=False))
            reviewed = llm.generate_json(review_prompt, SCHEMA, model=MODEL,
                                        thinking={'type': 'disabled'}, step='meaning_check', max_output_tokens=4096)['rows']
            errors = check(reviewed, excluded)
            if len(reviewed) != n:
                errors.append(f'Expected {n} rows, got {len(reviewed)}')
            if errors:
                save(folder / 'rejected' / f'{deck["slug"]}-{len(record["rows"]):04d}.json',
                     {'rows': reviewed, 'errors': errors})
                raise ValueError('Reviewed batch needs correction: ' + '; '.join(errors))
            start = len(record['rows'])
            record['rows'].extend(reviewed)
            record['batches'].append({'start': start, 'count': n, 'provider': args.provider,
                                     'model': MODEL, 'generation_sha256': raw_hash,
                                     'all_rows_second_pass': True, 'technical_findings': []})
            record['status'] = 'model_reviewed' if len(record['rows']) == deck['target_count'] else 'in_progress'
            save(path, record)
            excluded.update(normalized(r['form']) for r in reviewed)
            print(f'{args.lang} {deck["slug"]}: {len(record["rows"])}/{deck["target_count"]} reviewed', flush=True)
            calls += 1
            if args.limit_batches and calls >= args.limit_batches:
                return


if __name__ == '__main__':
    main()
