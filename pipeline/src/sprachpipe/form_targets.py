"""Schema-4 form metadata. Pure validators shared by pack, selection and import.

No SRS, sentence generation, ownership allocation or database writes here.
"""
from collections import defaultdict
from .ids import stable_id, form_norm
from .word_registry import digest

FUNCTIONS = {'base', 'past', 'past_participle'}
DECK_FUNCTIONS = {'verb_base': 'base', 'verb_past': 'past', 'verb_participle': 'past_participle'}
TABLES = ('lexical_targets', 'card_lexical_targets', 'form_targets', 'deck_practice_targets')


def require(ok, message):
    if not ok:
        raise ValueError('forms: ' + message)


def card_id(lang, card, sense_id):
    function = card.get('identity_function')
    if function is None:
        return stable_id('cards', lang=lang, form=card['form'], sense_id=sense_id)
    require(function in FUNCTIONS, 'unknown identity_function')
    require(card.get('introduction_scope') == 'form_only', 'new form identity requires form_only')
    return stable_id('form_cards', lang=lang, form=card['form'], sense_id=sense_id, function=function)


def reject_legacy_extensions(pack):
    require(not any(pack.get(t) for t in TABLES), 'schema 4 required for form tables')
    for table, keys in [('cards', ('identity_function', 'introduction_scope')), ('decks', ('practice_kind',)), ('sentence_tokens', ('form_target',))]:
        require(not any(any(k in r for k in keys) for r in pack.get(table, [])), 'schema 4 required for '+table+' metadata')


def extend_rows(pack, rows, cards, senses, decks):
    lang = pack['lang']
    def ref(index, name):
        require(name in index, 'unknown reference '+str(name))
        return index[name]
    for table in TABLES:
        values = pack.get(table, [])
        if table in ('lexical_targets', 'form_targets'):
            require(len({r['ref'] for r in values}) == len(values), 'duplicate '+table+' ref')
    lexical = {r['ref']: stable_id('lexical_targets', lang=lang, anchor_key=r['anchor_key']) for r in pack.get('lexical_targets', [])}
    forms = {r['ref']: stable_id('form_targets', lang=lang, sense_id=ref(senses, r['sense']), form=r['form'], function=r['function']) for r in pack.get('form_targets', [])}
    tomb = lambda r: {k:r[k] for k in ('removed_in', 'replaced_by') if k in r}
    for r in pack.get('lexical_targets', []):
        rows['lexical_targets'].append(dict(id=lexical[r['ref']], lang=lang, anchor_key=r['anchor_key'], note=r['note'], **tomb(r)))
    for r in pack.get('card_lexical_targets', []):
        cid = ref(cards, r['card'])
        rows['card_lexical_targets'].append(dict(id=stable_id('card_lexical_targets', card_id=cid), lang=lang, card_id=cid, lexical_target_id=ref(lexical, r['lexical_target']), note=r['note'], **tomb(r)))
    for r in pack.get('form_targets', []):
        rows['form_targets'].append(dict(id=forms[r['ref']], lang=lang, sense_id=ref(senses, r['sense']), form=r['form'], form_norm=form_norm(r['form']), function=r['function'], card_id=ref(cards, r['card']), lexical_target_id=ref(lexical, r['lexical_target']), note=r['note'], **tomb(r)))
    for r in pack.get('deck_practice_targets', []):
        did, fid = ref(decks, r['deck']), ref(forms, r['form_target'])
        rows['deck_practice_targets'].append(dict(id=stable_id('deck_practice_targets', deck_id=did, form_target_id=fid), deck_id=did, form_target_id=fid, position=r['position'], **tomb(r)))
    for raw, row in zip(pack['cards'], rows['cards']):
        row.update(identity_function=raw.get('identity_function'), introduction_scope=raw.get('introduction_scope', 'ordinary'))
    for raw, row in zip(pack['decks'], rows['decks']):
        row['practice_kind'] = raw.get('practice_kind', 'ordinary')
    for raw, row in zip(pack['sentence_tokens'], rows['sentence_tokens']):
        row['form_target_id'] = ref(forms, raw['form_target']) if raw.get('form_target') else None


def validate_form_rows(rows):
    maps = {t:{r['id']:r for r in rows[t]} for t in (*TABLES, 'cards', 'decks', 'senses')}
    live = lambda r: r.get('removed_in') is None
    def get(table, key, lang=None):
        r = maps[table].get(key)
        require(r is not None and live(r), 'missing/retired '+table+' reference '+str(key))
        require(lang is None or r.get('lang') == lang, 'foreign language '+table)
        return r
    def text(v): return isinstance(v, str) and bool(v.strip())
    lexical_keys = set()
    for l in rows['lexical_targets']:
        if not live(l): continue
        require(text(l['anchor_key']) and text(l['note']), 'empty lexical metadata')
        key = l['lang'], l['anchor_key']
        require(key not in lexical_keys, 'duplicate lexical anchor'); lexical_keys.add(key)
    cm = {}
    for m in rows['card_lexical_targets']:
        if not live(m): continue
        get('cards', m['card_id'], m['lang']); get('lexical_targets', m['lexical_target_id'], m['lang'])
        require(text(m['note']) and m['card_id'] not in cm, 'duplicate/empty card lexical mapping')
        cm[m['card_id']] = m['lexical_target_id']
    # A mapped learning group is mapped completely. No explicit/fallback split.
    groups = defaultdict(list)
    for c in rows['cards']:
        if live(c): groups[c['learning']['group_id']].append(c['id'])
    for members in groups.values():
        assigned = {cm[c] for c in members if c in cm}
        require(not assigned or (len(assigned) == 1 and all(c in cm for c in members)), 'partial/conflicting lexical learning-group mapping')
    # An explicit lexical concept also covers every active card of its sense;
    # otherwise an old unclassified inflection could retain a second fallback key.
    sense_members = defaultdict(list)
    for c in rows['cards']:
        if live(c): sense_members[(c['lang'], c['sense_id'])].append(c['id'])
    for members in sense_members.values():
        assigned = {cm[c] for c in members if c in cm}
        require(not assigned or (len(assigned) == 1 and all(c in cm for c in members)), 'partial/conflicting lexical sense mapping')
    by_card, identities, sense_lexical = {}, set(), {}
    for f in rows['form_targets']:
        if not live(f): continue
        require(f['function'] in FUNCTIONS and text(f['note']), 'invalid form function/note')
        c = get('cards', f['card_id'], f['lang']); get('senses', f['sense_id'], f['lang'])
        require(c['pos'] in ('VERB', 'AUX'), 'verb form target requires verbal sense')
        get('lexical_targets', f['lexical_target_id'], f['lang'])
        require((f['form'], f['form_norm'], f['sense_id']) == (c['form'], c['form_norm'], c['sense_id']), 'form/card identity mismatch')
        require(cm.get(c['id']) == f['lexical_target_id'], 'form lexical mapping mismatch')
        key = f['lang'], f['sense_id'], f['form_norm'], f['function']
        require(key not in identities and c['id'] not in by_card, 'duplicate active form identity/card')
        identities.add(key); by_card[c['id']] = f
        old = sense_lexical.setdefault(f['sense_id'], f['lexical_target_id'])
        require(old == f['lexical_target_id'], 'same sense split across lexical targets')
        require(c.get('identity_function') in (None, f['function']), 'card identity_function mismatch')
    for c in rows['cards']:
        if not live(c): continue
        require(c['introduction_scope'] in ('ordinary', 'form_only'), 'invalid introduction_scope')
        require(c.get('identity_function') in FUNCTIONS | {None}, 'invalid identity_function')
        if c['introduction_scope'] == 'form_only' or c.get('identity_function'):
            require(c['id'] in by_card, 'form card without canonical target')
        if c.get('identity_function'):
            require(c['introduction_scope'] == 'form_only', 'form identity must be form_only')
            require(c['learning']['primary_card_id'] == c['id'] and len(groups[c['learning']['group_id']]) == 1, 'new form card must have singleton learning group')
        # An old unclassified homograph must be explicitly reviewed before adding
        # a competing form identity. It cannot silently be assumed another tense.
        if c.get('identity_function'):
            for old in rows['cards']:
                if live(old) and old['id'] != c['id'] and (old['lang'], old['form_norm'], old['sense_id']) == (c['lang'], c['form_norm'], c['sense_id']):
                    require(old['id'] in by_card, 'unclassified competing card')
    positions = defaultdict(list)
    for d in rows['decks']:
        require(d['practice_kind'] in {'ordinary', *DECK_FUNCTIONS}, 'unknown practice_kind')
    for m in rows['deck_practice_targets']:
        if not live(m): continue
        d = get('decks', m['deck_id']); f = get('form_targets', m['form_target_id'], d['lang'])
        require(DECK_FUNCTIONS.get(d['practice_kind']) == f['function'], 'wrong function for practice deck')
        require(type(m['position']) is int and m['position'] > 0, 'invalid practice position')
        positions[d['id']].append(m['position'])
    for pos in positions.values():
        require(sorted(pos) == list(range(1, len(pos)+1)), 'practice positions must be 1..n')
    for t in rows['sentence_tokens']:
        if not live(t) or not t.get('form_target_id'): continue
        f = get('form_targets', t['form_target_id'])
        require((t.get('card_id'), t.get('sense_id'), form_norm(t['surface'])) == (f['card_id'], f['sense_id'], f['form_norm']), 'token form reference mismatch')
    for df in rows['dictionary_forms']:
        if not live(df) or not df.get('card_id'): continue
        c = get('cards', df['card_id'], df['lang'])
        require((c['form_norm'], c['sense_id']) == (df['form_norm'], df['sense_id']), 'dictionary card mismatch')
    # Every new form card's fixed target token must explicitly name its function.
    for link in rows['card_sentences']:
        if live(link) and link['card_id'] in by_card:
            f = by_card[link['card_id']]
            c = maps['cards'][link['card_id']]
            if c.get('identity_function'):
                require(any(t.get('form_target_id') == f['id'] and t['sentence_id'] == link['sentence_id'] and t['start_pos'] == link['gap_start'] and t['end_pos'] == link['gap_end'] for t in rows['sentence_tokens'] if live(t)), 'new form target token missing function')


def reuse_evidence(pack, card_ref, function, reason):
    """Explicit caller decision bound to exact old card, link, sentence, tokens."""
    from .authoring_context import sentence_binding
    card = next(c for c in pack['cards'] if c['ref'] == card_ref)
    return {'card': card_ref, 'function': function, 'card_sha256': digest(card),
            'context_sha256': digest(sentence_binding(pack, card_ref)), 'reason': reason}


def validate_reuse(pack, evidence, card_ref, function):
    require(isinstance(evidence, dict) and isinstance(evidence.get('reason'), str) and bool(evidence['reason'].strip()), 'missing reuse reason')
    require(evidence == reuse_evidence(pack, card_ref, function, evidence['reason']), 'stale reuse function/context evidence')


def validate_form_selection(source, selection, registry, *, source_hash):
    """Version-2 form selection: a frozen metadata catalogue, no sentences.

Each batch declares its exact additive metadata delta. The importer binds the
current delta, while sentence/token/dictionary reviews retain the create path.
"""
    from .pack import build_rows
    from .word_registry import index_registry
    require(selection.get('format') == 'sprachapp.form-selection' and selection.get('format_version') == 2, 'unsupported form selection version')
    require(source_hash == selection.get('source_sha256'), 'selection source hash')
    require(digest(registry) == selection.get('registry_sha256'), 'selection registry hash')
    require(source['release']['schema_version'] in (3, 4), 'form selection needs schema 3/4')
    parent = source['word_registry']
    require(registry.get('parent_sha256') == parent['sha256'] and registry['words'][:len(parent['snapshot']['words'])] == parent['snapshot']['words'], 'selection ownership parent changed')
    index = index_registry(registry)
    rows = build_rows(source)
    oldcards = {c['ref']:c for c in source['cards']}
    lemmas = {r['ref']:r for r in source['lemmas']}; senses = {r['ref']:r for r in source['senses']}
    cards = dict(oldcards); lex = {r['ref']:r for r in source.get('lexical_targets', [])}
    forms = {r['ref']:r for r in source.get('form_targets', [])}
    decks = {r['ref']:r for r in source['decks']}
    allowed = {'lemmas','senses','cards','decks','deck_words','deck_cards','word_aliases',*TABLES}
    from pathlib import Path
    import json
    import jsonschema
    spec=json.loads((Path(__file__).resolve().parents[2]/'data/curation/editorial_content_v3.schema.json').read_bytes())
    deltas = selection.get('batches', {})
    require(deltas and set(deltas) == {str(i) for i in range(1,len(deltas)+1)}, 'selection batches must be 1..n')
    all_add = {t:[] for t in allowed}
    for delta in deltas.values():
        require(isinstance(delta, dict) and set(delta) <= allowed, 'selection metadata tables')
        for table, values in delta.items():
            require(isinstance(values, list) and all(isinstance(v,dict) and not v.get('removed_in') and not v.get('replaced_by') for v in values), 'invalid selection delta')
            try:
                jsonschema.validate(values, spec['properties']['add']['properties'][table])
            except jsonschema.ValidationError as error:
                raise ValueError('forms: metadata schema '+error.message) from None
            all_add[table].extend(values)
    for table, target in [('lemmas',lemmas),('senses',senses),('cards',cards),('lexical_targets',lex),('decks',decks),('form_targets',forms)]:
        # Already-imported declarations must be exactly equal, not reinserted.
        seen = set()
        for r in all_add[table]:
            require(r['ref'] not in seen, 'duplicate planned '+table); seen.add(r['ref'])
            require(r['ref'] not in target or target[r['ref']] == r, 'changed imported metadata '+r['ref'])
            target[r['ref']] = r
    ids = {}
    for ref, c in cards.items():
        require(c['sense'] in senses, 'missing planned sense')
        se = senses[c['sense']]; require(se['lemma'] in lemmas, 'missing planned lemma')
        lm = lemmas[se['lemma']]
        sid = stable_id('senses', lemma_id=stable_id('lemmas',lang=source['lang'],lemma=lm['lemma'],pos=lm['pos']),sense_key=se['sense_key'])
        ids[ref] = card_id(source['lang'], c, sid)
    entries = selection.get('entries', [])
    require(entries, 'empty form selection')
    keys, refs, current_refs = set(), set(), set()
    present_forms = {r['ref']:r for r in source.get('form_targets', []) if not r.get('removed_in')}
    batch = selection.get('authoring_batch')
    require(type(batch) is int and str(batch) in deltas, 'invalid authoring batch')
    counts = {'imported':0, 'current':0, 'future':0, 'reused_cards':0, 'new_form_targets':0}
    for e in entries:
        require(set(e) == {'form_target','authoring_batch','reuse'}, 'selection entry fields')
        require(e['form_target'] in forms and e['form_target'] not in refs, 'duplicate/missing selected form')
        refs.add(e['form_target']); f = forms[e['form_target']]
        require(type(e['authoring_batch']) is int and str(e['authoring_batch']) in deltas, 'invalid entry batch')
        require(f['function'] in FUNCTIONS and f['card'] in cards and f['lexical_target'] in lex, 'incomplete form metadata')
        c=cards[f['card']]
        require((f['form'],f['sense']) == (c['form'],c['sense']), 'selection form/card mismatch')
        key=(form_norm(f['form']),f['sense'],f['function'])
        require(key not in keys, 'duplicate selected form identity');keys.add(key)
        owner=index.get((source['lang'],form_norm(f['form'])))
        require(owner is not None, 'unreserved form surface')
        if owner[1]['form_norm'] != form_norm(f['form']):
            require(c.get('introduction_scope')=='form_only', 'alias only for explicit form card')
        if c.get('identity_function') is None:
            require(f['card'] in oldcards, 'ordinary form target must reuse source card')
            validate_reuse(source,e['reuse'],f['card'],f['function']);counts['reused_cards']+=1
        else:
            require(e['reuse'] is None, 'new form card cannot claim old reuse')
        category='imported' if e['authoring_batch']<batch else 'current' if e['authoring_batch']==batch else 'future'
        require((f['ref'] in present_forms) == (category=='imported'), 'form continuation partition mismatch')
        counts[category]+=1
        if category=='current':current_refs.add(f['ref'])
        if category!='imported':counts['new_form_targets']+=1
    declared={f['ref'] for f in all_add['form_targets']}
    require(refs == declared, 'selection must cover declared form targets exactly')
    for number, delta in deltas.items():
        require({f['ref'] for f in delta.get('form_targets',[])} == {e['form_target'] for e in entries if e['authoring_batch']==int(number)}, 'batch form declarations mismatch')
        for m in delta.get('deck_practice_targets',[]):
            require(m['deck'] in decks and m['form_target'] in forms, 'missing practice membership reference')
            require(DECK_FUNCTIONS.get(decks[m['deck']].get('practice_kind'))==forms[m['form_target']]['function'], 'wrong selection deck function')
    counts['new_lexical_targets']=len(set(lex)-{r['ref'] for r in source.get('lexical_targets',[])})
    counts['new_surface_reservations']=len(registry['words'])-len(parent['snapshot']['words'])
    counts['new_cards']=len(set(cards)-set(oldcards))
    # Validate the complete pending metadata catalogue through the same builder
    # and form validator, without pretending that pending sentences exist.
    import copy
    from .pack import _build_rows
    from .content_contract import validate_registry
    from .learning_groups import validate_learning
    prospective=copy.deepcopy(source)
    prospective['release']['schema_version']=4
    prospective['word_registry']={'snapshot':registry,'sha256':digest(registry)}
    for table, values in all_add.items():
        existing=prospective.setdefault(table, [])
        existing.extend(copy.deepcopy(r) for r in values if r not in existing)
    metadata=_build_rows(prospective)
    for table, values in metadata.items():
        key='code' if table=='languages' else 'id'
        require(len({r[key] for r in values})==len(values), 'duplicate planned '+table+' identity')
    validate_learning(metadata['cards'])
    validate_form_rows(metadata)
    validate_registry(prospective,metadata)
    # Positions are ownership inventory, independent of practice positions.
    owners={}
    for w in metadata['deck_words']:
        if w.get('removed_in'): continue
        key=w['lang'],w['form_norm']
        require(key not in owners,'duplicate planned owner');owners[key]=w
    for c in metadata['cards']:
        if c.get('removed_in'):continue
        binding=index.get((c['lang'],c['form_norm']))
        require(binding is not None and (c['lang'],binding[1]['form_norm']) in owners,'planned card without owner')
    expected={(w['deck_id'],w['primary_card_id'],w['position']) for w in owners.values()}
    actual=[(m['deck_id'],m['card_id'],m['position']) for m in metadata['deck_cards'] if not m.get('removed_in')]
    require(set(actual)==expected and len(actual)==len(expected),'planned primary ownership mismatch')
    return counts


def form_partitions(selection):
    batch=selection['authoring_batch']
    return {key:[e['form_target'] for e in selection['entries'] if predicate(e['authoring_batch'])]
            for key,predicate in [('imported',lambda n:n<batch),('current',lambda n:n==batch),('future',lambda n:n>batch)]}
