"""Offline authoring handoff checks, composing the existing content validators.

Semantic decisions remain explicit editorial data, never inferred from a German
gloss. This module cannot create or import learning sentences.
"""
import copy
import hashlib
import json
from collections import Counter
from .ids import form_norm, stable_id
from .word_registry import digest, index_registry, validate_selection
from .selection import partition_selection
from .learning_groups import validate_learning
from .pack import build_rows


def require(condition, message):
    if not condition:
        raise ValueError('authoring: '+message)


def validate_context(pack, selection, registry, groups, *, source_bytes):
    """Check all reservations, not only the first authoring batch."""
    require(pack['release']['schema_version'] == 3, 'schema 3 required')
    require(hashlib.sha256(source_bytes).hexdigest() == selection['source_pack']['sha256'], 'source bytes hash')
    require(digest(pack) == selection['source_pack']['canonical_sha256'], 'source canonical hash')
    require(digest(registry) == selection['registry_sha256'], 'registry hash')
    require(digest(groups) == selection['learning_groups_sha256'], 'groups hash')
    parent = pack['word_registry']['snapshot']
    require(registry['parent_sha256'] == digest(parent) == pack['word_registry']['sha256'], 'registry parent')
    require(registry['source_pack_sha256'] == groups['source_pack_sha256'] == selection['source_pack']['sha256'], 'source binding')
    require(registry['words'][:len(parent['words'])] == parent['words'], 'old ownership changed')
    entries = selection['entries']
    require(0 < len(entries) <= 300, 'selection size')
    require(len(registry['words']) == len(parent['words'])+len(entries), 'reservation delta')
    require(digest(groups['existing']) == groups['parent_sha256'], 'group parent')
    index = index_registry(registry)
    validate_selection(entries, parent, lang=pack['lang'], owner=selection['owner_deck_ref'])
    validate_selection(entries, registry, lang=pack['lang'], owner=selection['owner_deck_ref'], allow_reserved=True)
    present, missing = partition_selection(entries, pack)
    require(not present and len(missing) == len(entries), 'existing target')
    rows = build_rows(pack)
    validate_learning(rows['cards'])
    oldcards = {c['ref']: c for c in pack['cards']}
    groupcards = groups['existing']['cards']
    require(len(groupcards) == len(oldcards) and {c['card_ref'] for c in groupcards} == set(oldcards), 'existing group coverage')
    learning_keys = {'group_id', 'primary_card_id', 'topic', 'related', 'note'}
    rowids = {c['ref']: r['id'] for c, r in zip(pack['cards'], rows['cards'])}
    for g in groupcards:
        require({k:g[k] for k in learning_keys} == oldcards[g['card_ref']]['learning'], 'old group metadata')
        require(rowids[g['card_ref']] == g['card_id'] and rowids[g['primary_card_ref']] == g['primary_card_id'], 'old group refs')
    reserved = {c['card_ref']: c for c in groups['reserved_cards']}
    require(len(reserved) == len(groups['reserved_cards']) == len(entries), 'planned group count')
    lemmas = {l['ref']:l for l in pack['lemmas']}
    senses = {s['ref']:s for s in pack['senses']}
    used_senses = {c['sense'] for c in pack['cards']}
    existing_forms = {form_norm(c['form']) for c in pack['cards']}
    alternatives = {form_norm(a) for c in pack['card_sentences'] for a in c.get('valid_alternatives', [])}
    planned = []
    seen_ids, seen_forms, positions, identifiers = set(), set(), set(), set()
    batch_topics = {}
    for e in entries:
        for field in ('form','lemma','pos','target_meaning_de','translation_de','reason','topic','selection_id'):
            require(isinstance(e.get(field), str) and e[field].strip(), 'missing '+field)
        require(e['review']['status'] == 'resolved' and e['review']['ambiguity'] == e['target_meaning_de'], 'unresolved definition')
        require(e['form_norm'] == form_norm(e['form']), 'normalization')
        require(e['form_norm'] not in existing_forms | alternatives, 'already offered word')
        require(e['lemma_ref'] == e['lemma']+'/'+e['pos'], 'lemma ref')
        if e['lemma_ref'] in lemmas:
            require(lemmas[e['lemma_ref']]['lemma'] == e['lemma'] and lemmas[e['lemma_ref']]['pos'] == e['pos'], 'existing lemma')
        lid = stable_id('lemmas', lang=pack['lang'], lemma=e['lemma'], pos=e['pos'])
        require(bool(e.get('sense_key')) != bool(e.get('proposed_sense_key')), 'exact sense key')
        key = e.get('sense_key') or e['proposed_sense_key']
        sid = stable_id('senses', lemma_id=lid, sense_key=key)
        cid = stable_id('cards', lang=pack['lang'], form=e['form'], sense_id=sid)
        require((lid,sid,cid) == (e['lemma_id'],e['sense_id'],e['card_id']), 'stable IDs')
        require(e['sense_ref'] == e['lemma_ref']+'|'+key and e['card_ref'] == e['form']+'|'+e['sense_ref'], 'target refs')
        require(e['sense_ref'] not in used_senses, 'sense already taught')
        if e['sense_key']:
            s = senses.get(e['sense_ref'])
            require(s is not None and (s['lemma'],s['sense_key'],s['gloss_de'],s.get('definition_de')) ==
                    (e['lemma_ref'],key,e['gloss_de'],e['definition_de']), 'reused sense changed')
        else:
            require(e['sense_ref'] not in senses and e['definition_de'] == e['target_meaning_de'], 'new sense definition')
        require(e['position'] == e['editorial_position'] and e['position'] > 0 and e['position'] not in positions, 'editorial positions')
        require(e['selection_id'] not in identifiers and cid not in seen_ids and e['form_norm'] not in seen_forms, 'duplicate identity')
        positions.add(e['position']); identifiers.add(e['selection_id']); seen_ids.add(cid); seen_forms.add(e['form_norm'])
        word = index[(pack['lang'],e['form_norm'])][1]
        require((word['primary_card_ref'],word['primary_card_id'],word['position'],word['aliases']) ==
                (e['card_ref'],cid,e['position'],e['ownership_aliases']), 'reservation identity/aliases/position')
        require(e['learning']['primary_card_id'] == cid and e['learning']['group_id'] == 'en:card:'+cid, 'new independent head')
        g = reserved.get(e['card_ref'])
        require(g is not None and {k:g[k] for k in learning_keys} == e['learning'] and g['card_id'] == cid and g['primary_card_ref'] == e['card_ref'], 'planned group reference')
        planned.append({'id':cid,'lang':pack['lang'],'learning':e['learning']})
        require(isinstance(e['authoring_batch'],int) and e['authoring_batch']>0, 'authoring batch')
        batch_topics.setdefault(e['authoring_batch'], []).append(e['topic'])
    for e in entries:
        variants = e['ownership_aliases']+e['synonym_candidates_not_separate_targets']
        require(not ({form_norm(v) for v in variants} & (seen_forms | existing_forms | alternatives)), 'alias/synonym target conflict')
    require(all(len(t) <= 100 and len(set(t)) > 1 for t in batch_topics.values()), 'unmixed/oversize batch')
    validate_learning(rows['cards']+planned)
    work = copy.deepcopy(pack)
    work['word_registry'] = {'sha256':digest(registry),'snapshot':registry}
    require(build_rows(work) == rows, 'reservation changes content rows')
    return {'status':'PASS','selected':len(entries),'excluded':len(selection['excluded']),
            'batches':{str(b):len(t) for b,t in sorted(batch_topics.items())},
            'topics_per_batch':{str(b):dict(Counter(t)) for b,t in sorted(batch_topics.items())},
            'existing_senses':sum(bool(e['sense_key']) for e in entries),
            'new_senses':sum(bool(e['proposed_sense_key']) for e in entries),
            'existing_cards':len(rows['cards']),'existing_groups':len({r['learning']['group_id'] for r in rows['cards']}),
            'new_groups':len(planned),'registry_words':len(registry['words']),
            'partition_selection':'PASS: 0 present','validate_selection':'PASS: parent and exact reservations',
            'index_registry':'PASS','validate_learning':'PASS: existing and planned',
            'build_rows':'PASS: reservation-only rows unchanged','semantic_review':'explicit editorial decisions, no automatic equivalence inference'}
