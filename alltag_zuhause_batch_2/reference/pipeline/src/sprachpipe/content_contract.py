"""Shared schema-2 contract. Run before any export, including offline imports."""
from __future__ import annotations
from collections import defaultdict
from .ids import form_norm


def sentence_count(pack):
    version = pack.get('release', {}).get('schema_version')
    if version not in (1, 2, 3):
        raise ValueError(f'unsupported content schema {version!r}; supported: 1 (legacy), 2, 3')
    return 3 if version == 1 else 1


def transition(source, registry, selection, *, source_hash):
    """Hash-bound, text-preserving schema-1 -> schema-2 transition."""
    import copy
    from .pack import build_rows
    from .word_registry import index_registry, digest
    if source_hash != registry['source_pack_sha256'] or source_hash != selection['source_pack_sha256']:
        raise ValueError('single sentence source hash mismatch')
    index_registry(registry)
    old = build_rows(source)
    ids = {c['ref']: r['id'] for c, r in zip(source['cards'], old['cards'])}
    sids = {s['ref']: r['id'] for s, r in zip(source['sentences'], old['sentences'])}
    picked = {c['card_ref']: c for c in selection['cards']}
    if set(picked) != set(ids) or len(picked) != len(selection['cards']):
        raise ValueError('sentence selection must cover every card exactly once')
    work = copy.deepcopy(source)
    version = selection['version']
    for cs in work['card_sentences']:
        choice = picked[cs['card']]
        if choice['card_id'] != ids[cs['card']]: raise ValueError('selection card identity mismatch')
        if cs['sentence'] == choice['selected_sentence_ref']:
            sn = next(s for s in source['sentences'] if s['ref'] == cs['sentence'])
            if cs != choice['expect_link'] or sn['text'] != choice['text'] or sn['translation_de'] != choice['translation_de'] or sids[cs['sentence']] != choice['selected_sentence_id']:
                raise ValueError(f'selection precondition: {cs["card"]}')
            cs['position'] = 1
        else:
            cs['removed_in'] = version
    words = registry['words']
    primary = {w['primary_card_ref']: w for w in words}
    for dc in work['deck_cards']:
        if dc['card'] in primary:
            dc['position'] = primary[dc['card']]['position']
        else: dc['removed_in'] = version
    work['deck_words'] = [{'form_norm': w['form_norm'], 'deck': w['owner_deck_ref'],
        'primary_card': w['primary_card_ref'], 'position': w['position']} for w in words]
    work['word_aliases'] = [{'form_norm': a, 'word': w['form_norm']} for w in words for a in w['aliases']]
    work['word_registry'] = {'sha256': digest(registry), 'snapshot': registry}
    work['release'] = {'version': version, 'schema_version': 2,
        'notes': 'INTERNES TEST-PACK: fixed existing editorial sentences; 160 primary words; preserved history; no new Vertex QA.'}
    new = build_rows(work)
    for table in ('cards', 'sentences', 'sentence_tokens', 'card_sentences', 'deck_cards'):
        if {r['id'] for r in old[table]} != {r['id'] for r in new[table]}:
            raise ValueError(f'transition changed {table} identities')
    return work


def validate_registry(pack, rows):
    from .word_registry import digest, index_registry
    bound = pack.get('word_registry')
    if not bound or digest(bound['snapshot']) != bound['sha256']:
        raise ValueError('schema 2 requires a hash-bound word registry snapshot')
    index = index_registry(bound['snapshot'])
    decks = {d['id']: d for d in rows['decks']}
    refs = {d['ref']: d['slug'] for d in pack['decks']}
    expected_aliases = set()
    for w in rows['deck_words']:
        if w.get('removed_in'): continue
        match = index.get((w['lang'], w['form_norm']))
        if not match: raise ValueError(f'word {w["form_norm"]}: missing registry reservation')
        r = match[1]
        expected_aliases.update((w['lang'], a, w['id']) for a in r.get('aliases', []))
        if r.get('primary_card_id') != w['primary_card_id'] or refs.get(r['owner_deck_ref']) != decks[w['deck_id']]['slug']:
            raise ValueError(f'word {w["form_norm"]}: registry owner {r["owner_deck_ref"]} conflicts with export owner {decks[w["deck_id"]]["slug"]}/primary {w["primary_card_id"]}')
    actual_aliases = {(a['lang'], a['form_norm'], a['word_id']) for a in rows['word_aliases'] if not a.get('removed_in')}
    if actual_aliases != expected_aliases:
        raise ValueError('export aliases differ from hash-bound registry reservations')


def validate_rows(rows, version):
    if version not in (1, 2, 3):
        raise ValueError(f'unsupported content schema {version}')
    if version == 1:
        return  # Explicit legacy release: old artifacts remain inspectable.
    if version == 3:
        from .learning_groups import validate_learning
        validate_learning(rows['cards'])
    maps = {}
    for table, entries in rows.items():
        key = 'code' if table == 'languages' else 'id'
        maps[table] = {r[key]: r for r in entries}
        if len(maps[table]) != len(entries):
            raise ValueError(f'{table}: duplicate identity')
    def live(row): return not row.get('removed_in')
    def ref(table, key, where):
        if key not in maps[table]:
            raise ValueError(f'{where}: unknown {table} reference {key}')
        return maps[table][key]
    cards = maps['cards']
    for c in cards.values():
        se = ref('senses', c['sense_id'], c['id'])
        lm = ref('lemmas', c['lemma_id'], c['id'])
        if se['lemma_id'] != lm['id'] or c['lang'] != lm['lang'] or c['pos'] != lm['pos']:
            raise ValueError(f'card {c["id"]}: inconsistent sense/lemma')
        if c['form'] != c['form'].strip() or c['form_norm'] != form_norm(c['form']):
            raise ValueError(f'card {c["id"]}: invalid form normalization')
    links = defaultdict(list)
    for cs in rows['card_sentences']:
        c = ref('cards', cs['card_id'], cs['id'])
        s = ref('sentences', cs['sentence_id'], cs['id'])
        start, end = cs['gap_start'], cs['gap_end']
        if not (isinstance(start, int) and isinstance(end, int) and 0 <= start < end <= len(s['text'])
                and form_norm(s['text'][start:end]) == c['form_norm']):
            raise ValueError(f'{cs["id"]}: gap does not match {c["form"]}')
        if cs['accepted'] != [c['form']]:
            raise ValueError(f'{cs["id"]}: accepted must contain only the target form')
        if live(cs) and live(c):
            if not live(s): raise ValueError(f'{cs["id"]}: active link to retired sentence')
            links[c['id']].append(cs)
    for c in cards.values():
        if live(c) and [r['position'] for r in links[c['id']]] != [1]:
            raise ValueError(f'card {c["id"]}: exactly one active sentence at position 1 required')
    owners, primary, positions = {}, set(), defaultdict(list)
    for w in rows['deck_words']:
        if not live(w): continue
        key = w['lang'], w['form_norm']
        d = ref('decks', w['deck_id'], w['id'])
        c = ref('cards', w['primary_card_id'], w['id'])
        if key in owners:
            old = owners[key]
            raise ValueError(f'word {key}: {old["id"]} owner {old["deck_id"]} '
                             f'conflicts with {w["id"]} owner {w["deck_id"]}')
        if not live(d) or not live(c) or key != (c['lang'], c['form_norm']) or d['lang'] != w['lang']:
            raise ValueError(f'{w["id"]}: invalid primary owner/card')
        owners[key] = w
        primary.add((w['deck_id'], w['primary_card_id'], w['position']))
        positions[w['deck_id']].append(w['position'])
    aliases = set(owners)
    for a in rows['word_aliases']:
        w = ref('deck_words', a['word_id'], a['id'])
        if not live(a): continue
        key = a['lang'], a['form_norm']
        if key in aliases or not live(w) or a['lang'] != w['lang'] or a['form_norm'] != form_norm(a['form_norm'].strip()):
            raise ValueError(f'alias {key}: duplicate or invalid owner {w["deck_id"]}')
        aliases.add(key)
    for c in cards.values():
        if live(c) and (c['lang'], c['form_norm']) not in owners:
            raise ValueError(f'word {c["form"]}: missing owner')
    actual = []
    for dc in rows['deck_cards']:
        ref('cards', dc['card_id'], dc['id']); ref('decks', dc['deck_id'], dc['id'])
        if live(dc): actual.append((dc['deck_id'], dc['card_id'], dc['position']))
    if set(actual) != primary or len(actual) != len(primary):
        raise ValueError('active deck_cards must match primary word ownership exactly')
    for deck, pos in positions.items():
        if sorted(pos) != list(range(1, len(pos)+1)):
            raise ValueError(f'deck {deck}: positions must be 1..n')
    tokens = defaultdict(list)
    for t in rows['sentence_tokens']:
        s = ref('sentences', t['sentence_id'], t['id'])
        if not live(t): continue
        if not (0 <= t['start_pos'] < t['end_pos'] <= len(s['text'])
                and s['text'][t['start_pos']:t['end_pos']] == t['surface']):
            raise ValueError(f'{t["id"]}: invalid token offset/surface')
        if t.get('sense_id'):
            se = ref('senses', t['sense_id'], t['id'])
            if se['lemma_id'] != t.get('lemma_id'): raise ValueError(f'{t["id"]}: token sense/lemma mismatch')
        if t.get('lemma_id'): ref('lemmas', t['lemma_id'], t['id'])
        if t.get('card_id'):
            c = ref('cards', t['card_id'], t['id'])
            if c['sense_id'] != t['sense_id'] or c['form_norm'] != form_norm(t['surface']):
                raise ValueError(f'{t["id"]}: token card mismatch')
        tokens[s['id']].append(t)
    for sid, ts in tokens.items():
        ts.sort(key=lambda t:t['idx'])
        if [t['idx'] for t in ts] != list(range(len(ts))) or any(a['end_pos'] > b['start_pos'] for a,b in zip(ts,ts[1:])):
            raise ValueError(f'{sid}: token order/overlap')
    for cs in rows['card_sentences']:
        if not any(t['start_pos'] == cs['gap_start'] and t['end_pos'] == cs['gap_end']
                   and t.get('card_id') == cs['card_id'] for t in tokens[cs['sentence_id']]):
            raise ValueError(f'{cs["id"]}: missing target token annotation')
    for df in rows['dictionary_forms']:
        ref('senses', df['sense_id'], df['id'])
        if df.get('card_id'): ref('cards', df['card_id'], df['id'])
    glosses = {(d['lang'], d['form_norm'], d['sense_id']) for d in rows['dictionary_forms']
               if live(d) and isinstance(d.get('gloss_de'), str) and d['gloss_de'].strip()}
    for s in rows['sentences']:
        ts = sorted(tokens[s['id']], key=lambda t:t['start_pos'])
        if not isinstance(s.get('translation_de'), str) or not s['translation_de'].strip():
            raise ValueError(f'{s["id"]}: missing sentence translation')
        cursor = 0
        for t in ts:
            if s['text'][cursor:t['start_pos']].strip():
                raise ValueError(f'{s["id"]}: incomplete token coverage')
            cursor = t['end_pos']
            if any(ch.isalpha() for ch in t['surface']) and (s['lang'], form_norm(t['surface']), t.get('sense_id')) not in glosses:
                raise ValueError(f'{t["id"]}: missing contextual form gloss')
        if s['text'][cursor:].strip():
            raise ValueError(f'{s["id"]}: incomplete token coverage')
    story_positions = defaultdict(list)
    for ss in rows['story_sentences']:
        story = ref('stories', ss['story_id'], ss['id'])
        s = ref('sentences', ss['sentence_id'], ss['id'])
        if not live(ss): continue
        if not live(story) or not live(s) or not s.get('translation_de') or not tokens[s['id']] or ss['paragraph_idx'] < 0:
            raise ValueError(f'{ss["id"]}: invalid story sentence/translation/annotation')
        story_positions[story['id']].append(ss['idx'])
    for story in rows['stories']:
        if live(story):
            pos = sorted(story_positions[story['id']])
            if not pos or pos != list(range(len(pos))): raise ValueError(f'{story["id"]}: story sentence order')
