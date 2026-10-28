"""Build reviewable editorial deliveries from the multilingual sentence corpus.

No model calls, publication, release approval, or guessed token translations.
Imports use the existing editor preview/receipt flow. Every language is first
roundtripped through an isolated editor store. Existing heads remain immutable.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import tempfile
import time
import unicodedata
import uuid

import jsonschema

from sprachpipe import authoring_service as author
from sprachpipe.editor.service import EditorService
from sprachpipe.editor.store import default_directory
from sprachpipe.ids import form_norm
from sprachpipe.form_targets import DECK_FUNCTIONS
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / 'editorial_review/multilingual_decks_20261027'
NAMES = {'pt-BR': ('Portugiesisch (Brasilien)', 'Português do Brasil'),
         'nb': ('Norwegisch', 'Norsk bokmål'), 'it': ('Italienisch', 'Italiano'),
         'es': ('Spanisch', 'Español')}
POS = set('ADJ ADP ADV AUX CCONJ DET INTJ NOUN NUM PART PRON PROPN SCONJ VERB'.split())
POS_ALIASES = {'noun': 'NOUN', 'verb': 'VERB', 'adjective': 'ADJ',
               'adverb': 'ADV', 'preposition': 'ADP', 'pronoun': 'PRON',
               'conjunction': 'CCONJ', 'interjection': 'INTJ', 'determiner': 'DET'}


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def identifier(*parts):
    return 'ml27-' + hashlib.sha256('\0'.join(parts).encode()).hexdigest()[:24]


def corpus(lang, inventory):
    result = []
    ordinary = set()
    for deck in inventory['decks']:
        path = CORPUS / lang / (deck['slug'] + '.json')
        raw = json.loads(path.read_text())
        rows = copy.deepcopy(raw if isinstance(raw, list) else raw['rows'])
        assert len(rows) == deck['target_count'], (lang, deck['slug'], len(rows))
        for i, row in enumerate(rows):
            for key in ('form', 'lemma', 'gloss_de', 'sentence', 'translation_de'):
                row[key] = unicodedata.normalize('NFC', row[key]).strip()
                assert row[key], (path, i, key)
            row['pos'] = POS_ALIASES.get(row['pos'], row['pos'].upper())
            assert row['pos'] in POS, (path, i, row['pos'])
            for key in ('sentence', 'translation_de'):
                text = row[key]
                assert not any(c == ';' or unicodedata.category(c) == 'Pd' or c in '\u00ad\u2212' for c in text), (path, i, key)
                # Spanish inverted punctuation is part of a single sentence.
                assert re.fullmatch(r'[^.!?\n]+[.!?]', text), (path, i, key)
            assert len(re.findall(r"\w+(?:['’]\w+)*", row['sentence'])) <= 14, (path, i)
            matches = list(re.finditer(r'(?<!\w)' + re.escape(row['form']) + r'(?!\w)', row['sentence'], re.I))
            assert len(matches) == 1, (path, i, 'target occurrence')
            row['_gap'] = matches[0].span()
            if deck['kind'] == 'ordinary':
                norm = form_norm(row['form'])
                assert norm not in ordinary, (path, i, 'ordinary duplicate', norm)
                ordinary.add(norm)
        result.append((deck, rows, hashlib.sha256(path.read_bytes()).hexdigest()))
    verbs = [{r['lemma'] for r in rows} for d, rows, _ in result if d['kind'] != 'ordinary']
    assert all(len(v) == 134 and v == verbs[0] for v in verbs)
    return result


def tokens(lang, row, lemma_ref, sense_ref, card_ref, function):
    start, end = row['_gap']
    text = row['sentence']
    if lang == 'pt-BR':
        items = get_profile(lang).tokenize(text, (start, end))
        items = [{k: t[k] for k in ('idx', 'surface', 'start_pos', 'end_pos')} for t in items]
    else:
        # Draft offsets only: not a substitute for an approved language profile.
        spans = []
        for lo, hi in ((0, start), (end, len(text))):
            spans.extend((lo+m.start(), lo+m.end()) for m in re.finditer(r"\w+(?:['’]\w+)*|[^\w\s]", text[lo:hi]))
        spans.append((start, end))
        items = [{'idx': i, 'surface': text[a:b], 'start_pos': a, 'end_pos': b}
                 for i, (a, b) in enumerate(sorted(spans))]
    for token in items:
        if (token['start_pos'], token['end_pos']) == (start, end):
            token.update(lemma=lemma_ref, sense=sense_ref, card=card_ref,
                         context_gloss_de=row['gloss_de'], binding_status='confirmed')
            if function:
                token['form_target'] = card_ref
        elif any(c.isalpha() for c in token['surface']):
            token['binding_status'] = 'unresolved'
    return items


def build(lang, base, records):
    result = []
    existing_decks = {d['slug']: d['ref'] for d in base['decks']}
    known_lemmas = {l['ref']: l for l in base['lemmas']}
    known_senses = {s['ref']: s for s in base['senses']}
    added_lemmas, added_senses = set(known_lemmas), set(known_senses)
    owned = {w['form_norm'] for w in base['deck_words']}
    verb_bases = {r['lemma']: r for d, rs, _ in records if d['kind'] == 'verb_base' for r in rs}
    for order, (deck, rows, source_sha) in enumerate(records, 1):
        add = {}
        operations, refs = [], []
        deck_ref = existing_decks.get(deck['slug'], identifier(lang, 'deck', deck['slug']))
        if deck['slug'] not in existing_decks:
            add['decks'] = [{'ref': deck_ref, 'slug': deck['slug'], 'title_de': deck['title_de'],
                             'practice_kind': deck['kind'], 'sort': order, 'cefr_band': 'mittel'}]
        function = DECK_FUNCTIONS.get(deck['kind'])
        for position, row in enumerate(rows, 1):
            existing_ref = row.get('existing_card_ref')
            card_ref = existing_ref or identifier(lang, deck['slug'], str(position), row['lemma'], row['form'])
            refs.append(card_ref)
            existing = next((c for c in base['cards'] if c['ref'] == existing_ref), None) if existing_ref else None
            if existing:
                sense_ref = existing['sense']
                lemma_ref = known_senses[sense_ref]['lemma']
            else:
                lemma_ref = identifier(lang, 'lemma', row['lemma'], row['pos'])
                sense_scope = 'verb-family' if function else deck['slug']
                sense_ref = identifier(lang, 'sense', row['lemma'], row['pos'], sense_scope)
                base_gloss = verb_bases[row['lemma']]['gloss_de'] if function else row['gloss_de']
                if lemma_ref not in added_lemmas:
                    add.setdefault('lemmas', []).append({'ref': lemma_ref, 'lemma': row['lemma'], 'pos': row['pos']})
                    added_lemmas.add(lemma_ref)
                if sense_ref not in added_senses:
                    add.setdefault('senses', []).append({'ref': sense_ref, 'lemma': lemma_ref,
                        'sense_key': sense_scope + ':' + row['lemma'], 'gloss_de': base_gloss,
                        'definition_de': base_gloss})
                    added_senses.add(sense_ref)
                add.setdefault('dictionary_forms', []).append({'form': row['form'], 'sense': sense_ref,
                    'gloss_de': row['gloss_de'], 'rank': 0})
                card = {'ref': card_ref, 'form': row['form'], 'sense': sense_ref,
                        'translation_de': row['gloss_de'], 'cefr_band': 'mittel',
                        'introduction_scope': 'form_only' if function else 'ordinary'}
                if function:
                    card.update(identity_function=function, form_kind=function,
                                form_label_de=row.get('form_note_de') or row.get('note_de') or deck['title_de'])
                add.setdefault('cards', []).append(card)
                if not function and form_norm(row['form']) not in owned:
                    add.setdefault('deck_words', []).append({'form_norm': form_norm(row['form']), 'deck': deck_ref,
                                                            'primary_card': card_ref, 'position': position})
                    owned.add(form_norm(row['form']))
                add.setdefault('deck_cards', []).append({'deck': deck_ref, 'card': card_ref, 'position': position})
            context = {'text': row['sentence'], 'translation_de': row['translation_de'],
                       'gap': {'start_pos': row['_gap'][0], 'end_pos': row['_gap'][1]},
                       'tokens': tokens(lang, row, lemma_ref, sense_ref, card_ref, function),
                       'valid_alternatives': [], 'reason': 'KI-redaktionell geprüft, keine menschliche Freigabe.'}
            if existing:
                expect = author.target_view(base, card_ref)['expect']
                operations.extend([
                    {'op_id': identifier(lang, card_ref, 'context'), 'kind': 'revise_context', 'lang': lang,
                     'target_ref': card_ref, 'expect': expect, 'payload': context},
                    {'op_id': identifier(lang, card_ref, 'hint'), 'kind': 'set_solution_hint', 'lang': lang,
                     'target_ref': card_ref, 'expect': expect, 'payload': {'translation_de': row['gloss_de']}}])
            else:
                sn = card_ref + '-sentence'
                add.setdefault('sentences', []).append({'ref': sn, 'text': row['sentence'],
                    'translation_de': row['translation_de'], 'origins': ['deck'], 'qa_status': 'draft'})
                add.setdefault('sentence_tokens', []).extend(dict(t, sentence=sn) for t in context['tokens'])
                add.setdefault('card_sentences', []).append({'card': card_ref, 'sentence': sn, 'position': 1,
                    'gap_start': row['_gap'][0], 'gap_end': row['_gap'][1], 'accepted': [row['form']],
                    'valid_alternatives': []})
            if function:
                lexical = identifier(lang, 'lexical', row['lemma'])
                if function == 'base':
                    add.setdefault('lexical_targets', []).append({'ref': lexical,
                        'anchor_key': lang + ':multilingual27:' + row['lemma'],
                        'note': 'Gemeinsames Verb für drei Formübungen.'})
                add.setdefault('card_lexical_targets', []).append({'card': card_ref, 'lexical_target': lexical})
                add.setdefault('form_targets', []).append({'ref': card_ref, 'card': card_ref,
                    'sense': sense_ref, 'lexical_target': lexical, 'form': row['form'], 'function': function,
                    'note': row.get('form_note_de') or row.get('note_de') or deck['title_de']})
                add.setdefault('deck_practice_targets', []).append({'deck': deck_ref,
                    'form_target': card_ref, 'position': position})
        payload = {'format': 'sprachapp.editorial-content', 'format_version': 4,
            'delivery_id': str(uuid.uuid5(uuid.NAMESPACE_URL, 'sprachapp:multilingual27:' + lang + ':' + deck['slug'] + ':' + source_sha)),
            'lang': lang, 'translation_lang': 'de', 'purpose': 'append',
            'base': author.base_fingerprint(base), 'context_sha256': None,
            'expected_target_refs': refs, 'selection': {'policy': 'editor-deck-v1',
                'batches': [{'number': 1, 'target_refs': refs}]}, 'add': add, 'operations': operations,
            'provenance': [{'kind': 'ai_editorial', 'source_file': lang + '/' + deck['slug'] + '.json',
                            'sha256': source_sha, 'human_review': False}],
            'submitted_reviews': [], 'extensions': {}, 'completeness': 'draft'}
        author.normalize_delivery(payload, language=lang)
        result.append((deck, payload))
    return result


def import_deliveries(service, lang, deliveries):
    draft_id = None
    receipts = []
    previous = {r['receipt']['delivery_id']: r['receipt']
                for r in service.store.list('imports') if r.get('receipt') and r['lang'] == lang}
    matches = [previous.get(p['delivery_id']) for _, p in deliveries]
    pending = deliveries
    if any(matches):
        # accept_import reuses global receipts even when another draft was
        # requested. Never append revised subsets to a prior author's draft.
        assert all(matches), 'Mixed old/new deliveries: refusing to modify an existing draft.'
        assert len({r['draft_id'] for r in matches}) == 1, 'Deliveries belong to different drafts.'
        for (_, payload), receipt in zip(deliveries, matches):
            assert receipt['payload_sha256'] == digest(payload), 'Previously imported payload changed.'
        draft_id = matches[0]['draft_id']
        prior = service.store.load_draft(draft_id)
        assert prior['revision'] == max(r['draft_revision'] for r in matches), 'Existing draft was edited after import.'
        assert prior['state'] == 'draft', 'Existing draft is no longer editable.'
        receipts = matches
        pending = []
    for deck, payload in pending:
        job = service.preview_upload(json.dumps(payload, ensure_ascii=False).encode(), deck['slug'] + '.json', lang)
        while job['state'] not in ('succeeded', 'failed', 'cancelled'):
            time.sleep(.1)
            job = service.store.get('jobs', job['job_id'])
        assert job['state'] == 'succeeded', job
        preview = job['result']
        assert not preview['preview']['inventory']['conflicting_refs'], preview['preview']['inventory']
        draft = service.store.load_draft(draft_id) if draft_id else None
        receipt = service.accept_import(preview['import_id'], preview['preview_sha256'],
            draft_id=draft_id, etag=service.store.etag(draft) if draft else None)
        draft_id = receipt['draft_id']
        receipts.append(receipt)
    draft = service.store.load_draft(draft_id)
    projection = service.projection(draft)
    counts = {}
    for deck, payload in deliveries:
        actual = next(d for d in projection['decks'] if d['slug'] == deck['slug'])
        table = 'deck_words' if deck['kind'] == 'ordinary' else 'deck_practice_targets'
        counts[deck['slug']] = sum(r['deck'] == actual['ref'] and not r.get('removed_in') for r in projection[table])
        assert counts[deck['slug']] == deck['target_count'], (lang, deck['slug'], counts[deck['slug']])
        expected_cards = {c['ref']: c for c in payload['add'].get('cards', [])}
        expected_sentences = {s['ref']: s for s in payload['add'].get('sentences', [])}
        expected_links = {l['card']: l for l in payload['add'].get('card_sentences', [])}
        revised = {o['target_ref']: o['payload'] for o in payload['operations'] if o['kind'] == 'revise_context'}
        for ref in payload['expected_target_refs']:
            view = author.target_view(projection, ref)
            expected = revised.get(ref)
            if expected is None:
                expected = expected_sentences[expected_links[ref]['sentence']]
                for field in ('form', 'translation_de', 'sense'):
                    assert view['card'][field] == expected_cards[ref][field], (ref, field)
            for field in ('text', 'translation_de'):
                assert view['context'][field] == expected[field], (ref, field)
    assert len(draft['target_refs']) == 3830
    return {'draft_id': draft_id, 'revision': draft['revision'], 'deck_counts': counts,
            'target_count': len(draft['target_refs']), 'receipts': receipts,
            'human_review': False, 'state': 'draft', 'release_ready': False,
            'remaining_release_work': ['Nichtzielwörter semantisch annotieren',
                'Sprachprofile und Formfunktionen für Freigabe unterstützen', 'Menschliche redaktionelle Freigabe']}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', required=True, choices=list(NAMES))
    parser.add_argument('--apply', action='store_true', help='Import into the local editor after isolated verification')
    args = parser.parse_args()
    inventory = json.loads((CORPUS / 'inventory.json').read_text())
    records = corpus(args.lang, inventory)
    store_root = default_directory()
    head = store_root / 'heads' / (args.lang + '.json')
    if head.exists():
        fp = json.loads(head.read_text())
        base = json.loads((store_root / 'bases' / (fp['pack_canonical_sha256'] + '.json')).read_text())
    else:
        base = author.empty_pack(args.lang, NAMES[args.lang][0])
        base['languages'][0]['name_native'] = NAMES[args.lang][1]
    deliveries = build(args.lang, base, records)
    out = CORPUS / 'deliveries' / args.lang
    schema = json.loads((ROOT / 'pipeline/data/curation/editorial_content_v4.schema.json').read_text())
    for deck, payload in deliveries:
        jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker()).validate(payload)
        write(out / (deck['slug'] + '.json'), payload)
    with tempfile.TemporaryDirectory(prefix='multilingual-decks-') as tmp:
        source = Path(tmp) / 'seed.json'
        write(source, base)
        service = EditorService(Path(tmp) / 'store', source=source)
        try:
            report = import_deliveries(service, args.lang, deliveries)
        finally:
            service.close()
    report['verification'] = 'isolated_editor_preview_import_projection_passed'
    report['applied_to_local_editor'] = False
    if args.apply:
        service = EditorService()
        try:
            if args.lang not in {l['lang'] for l in service.languages()}:
                service.create_language({'lang': args.lang, 'display_name': NAMES[args.lang][0],
                                         'name_native': NAMES[args.lang][1], 'translation_lang': 'de'})
            before = service.store.get('heads', args.lang)
            report = {**report, **import_deliveries(service, args.lang, deliveries)}
            assert before == service.store.get('heads', args.lang)
            report['applied_to_local_editor'] = True
        finally:
            service.close()
    write(out / 'import-report.json', report)
    print(json.dumps({k: report[k] for k in ('target_count', 'deck_counts', 'verification',
        'applied_to_local_editor', 'state', 'release_ready')}, ensure_ascii=False))


if __name__ == '__main__':
    main()
