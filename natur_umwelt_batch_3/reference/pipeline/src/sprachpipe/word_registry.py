"""Versioned word ownership, independent of sense-specific learning IDs."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from .ids import form_norm

DEFAULT_REGISTRY = Path(__file__).resolve().parents[2] / 'data/words/en.v1.json'


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':')).encode('utf8')).hexdigest()


def load_registry(path=DEFAULT_REGISTRY, *, expected_hash=None):
    registry = json.loads(Path(path).read_text(encoding='utf8'))
    if expected_hash is not None and digest(registry) != expected_hash:
        raise ValueError('word registry base hash mismatch')
    index_registry(registry)
    return registry


def index_registry(registry):
    if registry.get('format_version') != 1 or registry.get('normalization') != 'NFC-lower-apostrophe-v1':
        raise ValueError('unsupported word registry format/normalization')
    index = {}
    for i, word in enumerate(registry['words']):
        lang, norm = word['lang'], word['form_norm']
        if not norm or norm != form_norm(norm.strip()) or not word.get('owner_deck_ref'):
            raise ValueError(f'invalid registry word {i}: {word}')
        for alias in [norm, *word.get('aliases', [])]:
            if alias != form_norm(alias.strip()) or not alias:
                raise ValueError(f'unnormalized alias {alias!r}')
            key = lang, alias
            if key in index:
                old = index[key]
                raise ValueError(f'word {alias!r}: registry[{old[0]}] owner {old[1]["owner_deck_ref"]} '
                                 f'conflicts with registry[{i}] owner {word["owner_deck_ref"]}')
            index[key] = (i, word)
    return index


def validate_selection(entries, registry, *, lang, owner, allow_reserved=False):
    """Reject even different senses/casing; only an exact reserved card may proceed."""
    index = index_registry(registry)
    seen = {}
    for i, entry in enumerate(entries):
        form = entry['form']
        if form != form.strip() or not form:
            raise ValueError(f'invalid selection[{i}] form {form!r}')
        key = lang, form_norm(form)
        canonical = index.get(key, (None, {'form_norm': key[1]}))[1]['form_norm']
        if canonical in seen:
            raise ValueError(f'word {form!r}: selection[{seen[canonical]}] owner {owner} '
                             f'conflicts with selection[{i}] owner {owner}')
        seen[canonical] = i
        if key in index:
            n, word = index[key]
            if not (allow_reserved and word['owner_deck_ref'] == owner
                    and entry.get('card_id') == word.get('primary_card_id')):
                raise ValueError(f'word {form!r}: registry[{n}] owner {word["owner_deck_ref"]} '
                                 f'conflicts with selection[{i}] owner {owner}')


def bind_new_pack(pack, registry=None):
    """Reproducible reservation delta; never rewrites the central source file."""
    import copy
    from .ids import stable_id
    registry = copy.deepcopy(registry if registry is not None else load_registry())
    parent = digest(registry)
    cards = {r['ref']: r for r in pack['cards']}
    senses = {r['ref']: r for r in pack['senses']}
    lemmas = {r['ref']: r for r in pack['lemmas']}
    groups = {}
    for w in pack['deck_words']:
        c = cards[w['primary_card']]
        groups.setdefault(w['deck'], []).append(c)
    # Validate the complete proposal before mutating even this in-memory copy.
    for deck, values in groups.items():
        validate_selection(values, registry, lang=pack['lang'], owner=deck)
    for w in pack['deck_words']:
        c = cards[w['primary_card']]; se = senses[c['sense']]; lm = lemmas[se['lemma']]
        lid = stable_id('lemmas', lang=pack['lang'], lemma=lm['lemma'], pos=lm['pos'])
        sid = stable_id('senses', lemma_id=lid, sense_key=se['sense_key'])
        registry['words'].append({'lang': pack['lang'], 'form_norm': w['form_norm'], 'aliases': [],
            'owner_deck_ref': w['deck'], 'primary_card_ref': c['ref'],
            'primary_card_id': stable_id('cards', lang=pack['lang'], form=c['form'], sense_id=sid)})
    registry['parent_sha256'] = parent
    index_registry(registry)
    pack['word_registry'] = {'sha256': digest(registry), 'snapshot': registry}
