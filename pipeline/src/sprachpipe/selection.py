"""Offline planning of exact editorial targets; never expands meanings or writes inventory."""
from __future__ import annotations

import json
import sqlite3
import unicodedata
from collections import Counter
from pathlib import Path

from .inventory import MeaningInventory


def norm(value):
    return unicodedata.normalize('NFC', value.strip()).lower().replace('’', "'")


def partition_selection(entries, pack):
    """Compare exact learning-card identities, never calls or annotation senses.

    Return original entry objects in original order; do not modify definitions.
    """
    from .pack import build_rows
    rows = build_rows(pack)
    lemmas = {r['id']: r for r in rows['lemmas']}
    senses = {r['id']: r for r in rows['senses']}
    packed = {(norm(c['form']), norm(lemmas[c['lemma_id']]['lemma']), c['pos'],
               senses[c['sense_id']]['sense_key']) for c in rows['cards']}
    present, missing, seen = [], [], set()
    for entry in entries:
        identity = (norm(entry['form']), norm(entry['lemma']), entry['pos'],
                    entry.get('sense_key') or entry.get('proposed_sense_key'))
        if not identity[-1] or identity in seen:
            raise ValueError(f'duplicate or undefined selection identity: {identity}')
        seen.add(identity)
        (present if identity in packed else missing).append(entry)
    return present, missing


def plan_selection(path, existing_pack, *, inventory_path=None):
    data = json.loads(Path(path).read_text(encoding='utf-8'))
    if data.get('version') != 1 or data.get('lang') != 'en' or not data.get('entries'):
        raise ValueError('selection requires version 1, lang en and entries')
    from .word_registry import load_registry, validate_selection
    inventory = MeaningInventory(data['lang'], inventory_path)
    db = sqlite3.connect(Path(existing_pack).resolve().as_uri() + '?mode=ro', uri=True)
    db.row_factory = sqlite3.Row
    try:
        senses = {(r['lemma'], r['pos'], r['sense_key']): dict(r) for r in db.execute(
            'SELECT s.*, l.lemma, l.pos FROM senses s JOIN lemmas l ON l.id=s.lemma_id')}
        cards = {(r['form_norm'], r['lemma'], r['pos'], r['sense_key']): r['id']
                 for r in db.execute('SELECT c.id,c.form_norm,l.lemma,l.pos,s.sense_key '
                     'FROM cards c JOIN senses s ON s.id=c.sense_id '
                     'JOIN lemmas l ON l.id=c.lemma_id WHERE c.removed_in IS NULL')}
        locations = {}
        for r in db.execute('SELECT c.form_norm,c.id,d.slug,dc.position FROM cards c '
                            'JOIN deck_cards dc ON dc.card_id=c.id JOIN decks d ON d.id=dc.deck_id '
                            'WHERE c.removed_in IS NULL AND dc.removed_in IS NULL'):
            locations.setdefault(r['form_norm'], []).append(
                f"pack deck {r['slug']} position {r['position']} card {r['id']}")
    finally:
        db.close()
    selection_entries = []
    owner = data.get('owner_deck_ref', 'allgemeine-sprache')
    for i, e in enumerate(data['entries']):
        identity = (norm(e['form']), norm(e['lemma']), e['pos'], e.get('sense_key') or e.get('proposed_sense_key'))
        if identity not in cards and any(k[0] == identity[0] for k in cards):
            raise ValueError(f"word {e['form']}: {locations.get(identity[0], ['existing pack'])} "
                             f"conflicts with selection[{i}] owner {owner}; different meaning")
        selection_entries.append({'form': e['form'], 'card_id': cards.get(identity)})
    validate_selection(selection_entries, load_registry(), lang=data['lang'], owner=owner, allow_reserved=True)
    selected, covered, missing = {}, [], []
    lemmas, surfaces = set(), set()
    reused_keys = inventory_definitions = 0
    for e in data['entries']:
        for field in ('form', 'lemma', 'pos', 'reason', 'topic'):
            if not isinstance(e.get(field), str) or not e[field].strip():
                raise ValueError(f'missing {field}: {e}')
        form, lemma = norm(e['form']), norm(e['lemma'])
        if lemma in lemmas or form in surfaces:
            raise ValueError(f'duplicate lemma or surface: {form}/{lemma}')
        lemmas.add(lemma)
        surfaces.add(form)
        if e['pos'] not in {'NOUN', 'VERB', 'ADJ'} or form != lemma or e.get('form_kind') != 'base':
            raise ValueError(f'exact base content-word target required: {form}')
        key = e.get('sense_key') or e.get('proposed_sense_key')
        if not key or bool(e.get('sense_key')) == bool(e.get('proposed_sense_key')):
            raise ValueError(f'exactly one existing or proposed sense key required: {form}')
        found = inventory.get(form) or []
        canonical = next((m for m in found if m['sense_key'] == key), None)
        packed_sense = senses.get((lemma, e['pos'], key))
        if canonical and (canonical['lemma'] != lemma or canonical['pos'] != e['pos']):
            raise ValueError(f'inventory identity mismatch: {key}')
        if canonical and canonical.get('status') == 'excluded':
            raise ValueError(f'excluded inventory sense: {key}')
        if packed_sense and packed_sense.get('removed_in'):
            raise ValueError(f'retired pack sense: {key}')
        if e.get('sense_key') and not (canonical or packed_sense):
            raise ValueError(f'claimed existing sense not found: {key}')
        reused_keys += bool(canonical or packed_sense)
        inventory_definitions += bool(canonical)
        identity = (form, lemma, e['pos'], key)
        if identity in cards:
            covered.append({'form': form, 'sense_key': key, 'card_id': cards[identity]})
            continue
        absent = [f for f in ('target_meaning_de', 'translation_de', 'form_label_de', 'cefr_band')
                  if not isinstance(e.get(f), str) or not e[f].strip()]
        if absent:
            missing.append({'form': form, 'fields': absent})
            continue
        if e['cefr_band'] not in {'anfaenger', 'mittel', 'fortgeschritten'}:
            raise ValueError(f'invalid cefr_band: {form}')
        sense_index = (found.index(canonical) + 1 if canonical else
                       (packed_sense['sense_index'] or 1) if packed_sense else len(found) + 1)
        selected[form] = [{
            'lemma': lemma, 'pos': e['pos'], 'sense_key': key,
            'gloss_de': e['target_meaning_de'], 'translation_de': e['translation_de'],
            'form_kind': 'base', 'form_label_de': e['form_label_de'],
            'cefr_band': e['cefr_band'], 'sense_index': sense_index,
            'usage': 'haupt', 'status': 'active',
        }]
    existing_lemmas = {identity[1] for identity in cards}
    return {'entries': len(data['entries']), 'pos': dict(Counter(e['pos'] for e in data['entries'])),
            'new_lemmas': len(lemmas - existing_lemmas),
            'selected': selected, 'covered': covered, 'missing_definitions': missing,
            'reused_sense_keys': reused_keys, 'inventory_definitions': inventory_definitions,
            'editorial_definitions': len(selected),
            'forms': [(norm(e['form']), e.get('frequency', {}).get('rank') or 5001)
                      for e in data['entries'] if norm(e['form']) in selected]}


def print_plan(plan, cfg, max_usd):
    from .llm import model_price, reservation_usd
    print(f"Selection: {plan['entries']} distinct lemmas; POS {plan['pos']}")
    print(f"Cards planned: {len(plan['selected'])}; existing reused: {len(plan['covered'])}")
    print(f"Lemmas without any existing learning card: {plan['new_lemmas']}")
    print(f"Existing sense keys: {plan['reused_sense_keys']}; "
          f"new proposed keys: {plan['entries'] - plan['reused_sense_keys']}")
    print(f"Canonical inventory definitions: {plan['inventory_definitions']}; "
          f"explicit editorial targets: {plan['editorial_definitions']}; "
          f"missing definitions: {len(plan['missing_definitions'])}")
    print('Editorial targets are not sentence-validated. No inventory entries are added.')
    for entry in plan['missing_definitions']:
        print(f"  PREPARATION REQUIRED: {entry}")
    for entry in plan['covered']:
        print(f"  REUSE: {entry}")
    # Transparent planning scenario, not a measurement or upper bound.
    stages = [('sentences', 'generate', 1, 2500, 800, 400),
              ('blindtest', 'blindtest', 5, 500, 70, 0),
              ('meaning_check', 'meaning_check', 5, 900, 120, 200),
              ('alternative_check', 'alternative_check', 2, 900, 150, 200),
              ('annotate', 'generate', 1, 2500, 1600, 400)]
    per_card = reserved_per_card = 0.0
    print(f"Price snapshot from config.yaml: {cfg['prices']['as_of']} (not refreshed)")
    print('Assumption per card: first batch of 5 candidates, 1 accepted; no regeneration.')
    for step, role, calls, inp, out, thinking in stages:
        model = cfg['llm'][role + '_model']
        price = model_price(cfg['prices'], model)
        limit = cfg['llm']['max_output_tokens'][step]
        reserve = reservation_usd(price, 2 * (inp - 1), limit)
        reserved_per_card += calls * reserve
        per_card += calls * (inp * price['input_per_mtok_usd'] +
                            out * price['output_per_mtok_usd'] +
                            thinking * price['thinking_per_mtok_usd']) / 1e6
        print(f"  {step}: {model}, {cfg['llm'][role + '_thinking']}; "
              f"{calls} calls x {inp}/{out}/{thinking} input/output/thinking tokens; "
              f"configured max_output_tokens={limit}; reservation/call={reserve:.6f} USD")
    estimate = per_card * len(plan['selected'])
    print(f'Planning estimate: {estimate:.3f} USD; retry scenario (2.5x): {estimate * 2.5:.3f} USD')
    envelope = reserved_per_card * len(plan['selected'])
    print(f'Configured-limit scenario: {envelope:.3f} USD (same assumed inputs/call counts, '
          'full configured output limits, no retries). Reservations reconcile to actual usage; '
          'this total is not reserved upfront.')
    if envelope > max_usd:
        print('BUDGET RISK: configured-limit scenario exceeds the run budget; partial completion possible.')
    print(f'Not a guaranteed upper bound. Existing reservations enforce run budget {max_usd:.2f} USD; '
          'the run may stop before all cards pass QA. No cloud calls in dry-run.')
