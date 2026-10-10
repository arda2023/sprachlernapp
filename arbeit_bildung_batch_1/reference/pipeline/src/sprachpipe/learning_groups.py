"""Offline, hash-bound learning-target extension. No state migration or AI."""
import copy
import hashlib


def validate_learning(cards):
    by_id = {c['id']: c for c in cards}
    groups = {}
    for c in cards:
        m = c.get('learning')
        if not isinstance(m, dict) or set(m) != {'group_id', 'primary_card_id', 'topic', 'related', 'note'}:
            raise ValueError('learning: missing or malformed metadata')
        if any(not isinstance(m[k], str) or not m[k].strip() for k in ('group_id', 'primary_card_id', 'topic', 'note')):
            raise ValueError('learning: empty identity/topic/note')
        if not isinstance(m['related'], list) or any(not isinstance(x, str) or not x for x in m['related']) or len(set(m['related'])) != len(m['related']):
            raise ValueError('learning: invalid related tags')
        head = by_id.get(m['primary_card_id'])
        if not head or head.get('removed_in') or head['lang'] != c['lang']:
            raise ValueError('learning: missing/retired/foreign primary')
        hm = head.get('learning') or {}
        if hm.get('group_id') != m['group_id'] or hm.get('primary_card_id') != head['id']:
            raise ValueError('learning: inconsistent primary membership')
        old = groups.setdefault(m['group_id'], m['primary_card_id'])
        if old != m['primary_card_id']:
            raise ValueError('learning: multiple heads')


def apply_learning_groups(source_bytes, registry):
    import json
    from .pack import build_rows
    if registry.get('version') != 'en.learning_groups.v1':
        raise ValueError('learning: unsupported registry version')
    if hashlib.sha256(source_bytes).hexdigest() != registry['source_pack_sha256']:
        raise ValueError('learning: source hash mismatch')
    source = json.loads(source_bytes)
    before = build_rows(source)
    work = copy.deepcopy(source)
    entries = {e['card_ref']: e for e in registry['cards']}
    if len(entries) != len(registry['cards']) or set(entries) != {c['ref'] for c in work['cards']}:
        raise ValueError('learning: coverage must include every card exactly once')
    ids = {c['ref']: r['id'] for c, r in zip(source['cards'], before['cards'])}
    for c in work['cards']:
        e = entries[c['ref']]
        if e['card_id'] != ids[c['ref']] or e['primary_card_id'] != ids.get(e['primary_card_ref']):
            raise ValueError('learning: old identity mismatch')
        c['learning'] = {k: e[k] for k in ('group_id', 'primary_card_id', 'topic', 'related', 'note')}
        if c['ref'] == 'fasten|fasten/VERB|fasten#schliessen':
            c['translation_de'] = 'anschnallen'
    work['release'] = {'version': 'learning_groups_v1', 'schema_version': 3,
        'notes': 'INTERNES TEST-PACK: editorial learning groups v1; preserved cards and sentences; offline, no new AI QA.'}
    after = build_rows(work)
    for table in before:
        if table == 'content_releases':
            continue
        key = 'code' if table == 'languages' else 'id'
        if {r[key] for r in before[table]} != {r[key] for r in after[table]}:
            raise ValueError('learning: changed historical identities')
    for table in ('sentences', 'sentence_tokens', 'card_sentences', 'deck_cards', 'deck_words', 'word_aliases'):
        if before[table] != after[table]:
            raise ValueError('learning: changed immutable content')
    return work
