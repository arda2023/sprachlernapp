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
    continuation = selection.get('continuation')
    imported_refs = set()
    if continuation:
        require(continuation['format_version'] == 1, 'continuation version')
        original = continuation['original_selection']
        require(digest(original) == continuation['original_selection_sha256'], 'original selection hash')
        require(entries == original['entries'], 'original identities/definitions changed')
        require(selection['owner_deck_ref'] == original['owner_deck_ref'], 'original owner changed')
        batch = continuation['authoring_batch']
        require(type(batch) is int and batch > 1, 'continuation batch')
        expected_parts = partition_batches(entries, batch)
        require(continuation['partitions'] == expected_parts, 'continuation partitions')
        imported_refs = {e['card_ref'] for e in entries if e['authoring_batch'] < batch}
        require(bool(imported_refs) and bool(expected_parts['current']), 'empty continuation')
        require(registry['words'] == parent['words'], 'continuation must not append reservations')
    else:
        require(len(registry['words']) == len(parent['words'])+len(entries), 'reservation delta')
    require(0 < len(entries) <= 300, 'selection size')
    require(digest(groups['existing']) == groups['parent_sha256'], 'group parent')
    index = index_registry(registry)
    validate_selection(entries, parent, lang=pack['lang'], owner=selection['owner_deck_ref'], allow_reserved=bool(continuation))
    validate_selection(entries, registry, lang=pack['lang'], owner=selection['owner_deck_ref'], allow_reserved=True)
    present, missing = partition_selection(entries, pack)
    require({e['card_ref'] for e in present} == imported_refs and len(missing) == len(entries)-len(imported_refs), 'existing target partition')
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
    require(len(reserved) == len(groups['reserved_cards']) == len(entries)-len(imported_refs), 'planned group count')
    lemmas = {l['ref']:l for l in pack['lemmas']}
    senses = {s['ref']:s for s in pack['senses']}
    used_senses = {c['sense'] for c in pack['cards']}
    existing_forms = {form_norm(c['form']) for c in pack['cards']}
    alternatives = {form_norm(a) for c in pack['card_sentences'] for a in c.get('valid_alternatives', [])}
    planned = []
    seen_ids, seen_forms, positions, identifiers = set(), set(), set(), set()
    batch_topics = {}
    used_equivalences = set()
    for e in entries:
        for field in ('form','lemma','pos','target_meaning_de','translation_de','reason','topic','selection_id'):
            require(isinstance(e.get(field), str) and e[field].strip(), 'missing '+field)
        require(e['review']['status'] == 'resolved' and e['review']['ambiguity'] == e['target_meaning_de'], 'unresolved definition')
        require(e['form_norm'] == form_norm(e['form']), 'normalization')
        imported = e['card_ref'] in imported_refs
        if not imported:
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
        if not imported:
            require(e['sense_ref'] not in used_senses, 'sense already taught')
        if e['sense_key']:
            s = senses.get(e['sense_ref'])
            require(s is not None and (s['lemma'],s['sense_key'],s['gloss_de'],s.get('definition_de')) ==
                    (e['lemma_ref'],key,e['gloss_de'],e['definition_de']), 'reused sense changed')
        else:
            require(e['definition_de'] == e['target_meaning_de'], 'new sense definition')
            if continuation and e['sense_ref'] in senses:
                s = senses[e['sense_ref']]
                require((s['lemma'],s['sense_key'],s['gloss_de']) == (e['lemma_ref'],key,e['gloss_de']), 'promoted sense identity/gloss: '+e['form'])
                if s.get('definition_de') != e['definition_de']:
                    review = continuation.get('definition_equivalences', {}).get(e['sense_ref'], {})
                    require(review.get('reserved_definition') == e['definition_de'] and
                            review.get('existing_definition') == s.get('definition_de') and
                            review.get('existing_sense_sha256') == digest(s) and
                            review.get('decision') == 'same_meaning' and bool(review.get('reason')),
                            'promoted sense definition conflict: '+e['form'])
                    used_equivalences.add(e['sense_ref'])
            else:
                require(e['sense_ref'] not in senses, 'new sense already exists')
        require(e['position'] == e['editorial_position'] and e['position'] > 0 and e['position'] not in positions, 'editorial positions')
        require(e['selection_id'] not in identifiers and cid not in seen_ids and e['form_norm'] not in seen_forms, 'duplicate identity')
        positions.add(e['position']); identifiers.add(e['selection_id']); seen_ids.add(cid); seen_forms.add(e['form_norm'])
        word = index[(pack['lang'],e['form_norm'])][1]
        require((word['primary_card_ref'],word['primary_card_id'],word['position'],word['aliases']) ==
                (e['card_ref'],cid,e['position'],e['ownership_aliases']), 'reservation identity/aliases/position')
        require(e['learning']['primary_card_id'] == cid and e['learning']['group_id'] == 'en:card:'+cid, 'new independent head')
        if imported:
            card = oldcards[e['card_ref']]
            require(card['form'] == e['form'] and card['sense'] == e['sense_ref'] and
                    card['translation_de'] == e['translation_de'] and card['learning'] == e['learning'] and
                    card.get('form_kind') == e['form_kind'] and card.get('form_label_de') == e['form_label_de'], 'imported target changed')
            dw = [w for w in pack['deck_words'] if w['primary_card'] == e['card_ref'] and not w.get('removed_in')]
            dc = [w for w in pack['deck_cards'] if w['card'] == e['card_ref'] and not w.get('removed_in')]
            require(len(dw) == len(dc) == 1 and dw[0]['deck'] == dc[0]['deck'] == e['owner_deck_ref'] and
                    dw[0]['form_norm'] == e['form_norm'] and dw[0]['position'] == dc[0]['position'], 'imported owner/membership')
            require(continuation['imported_sentences'].get(e['card_ref']) == sentence_binding(pack,e['card_ref']), 'imported sentence changed')
        else:
            g = reserved.get(e['card_ref'])
            require(g is not None and {k:g[k] for k in learning_keys} == e['learning'] and g['card_id'] == cid and g['primary_card_ref'] == e['card_ref'], 'planned group reference')
            planned.append({'id':cid,'lang':pack['lang'],'learning':e['learning']})
        require(isinstance(e['authoring_batch'],int) and e['authoring_batch']>0, 'authoring batch')
        batch_topics.setdefault(e['authoring_batch'], []).append(e['topic'])
    for e in entries:
        variants = e['ownership_aliases']+e['synonym_candidates_not_separate_targets']
        # Imported targets may own the exact alternatives already checked for
        # their own fixed sentence. This exception never applies to future cards.
        own_alternatives = set()
        if e['card_ref'] in imported_refs:
            own_alternatives = {form_norm(a) for link in pack['card_sentences'] if link['card']==e['card_ref'] for a in link.get('valid_alternatives',[])}
        require(not ({form_norm(v) for v in variants} & (seen_forms | existing_forms | (alternatives-own_alternatives))), 'alias/synonym target conflict')
    require(all(len(t) <= 100 and len(set(t)) > 1 for t in batch_topics.values()), 'unmixed/oversize batch')
    validate_learning(rows['cards']+planned)
    work = copy.deepcopy(pack)
    work['word_registry'] = {'sha256':digest(registry),'snapshot':registry}
    require(build_rows(work) == rows, 'reservation changes content rows')
    if continuation:
        require(set(continuation.get('definition_equivalences',{})) == used_equivalences, 'unused definition equivalence')
        require(set(continuation['imported_sentences']) == imported_refs, 'sentence binding coverage')
        require(groups['partitions'] == continuation['partitions'], 'group partitions')
        require(digest(groups['previous_snapshot']) == groups['previous_snapshot_sha256'] == continuation['original_selection']['learning_groups_sha256'], 'previous groups binding')
        validate_display_plan(pack, selection, continuation['display_plan'], registry)
    return {'status':'PASS','selected':len(entries),'excluded':len(selection['excluded']),
            **({'partition_counts':{k:len(v) for k,v in continuation['partitions'].items()},
                'reused_proposed_senses':sum(bool(e['proposed_sense_key']) and e['sense_ref'] in senses for e in missing)} if continuation else {}),
            'batches':{str(b):len(t) for b,t in sorted(batch_topics.items())},
            'topics_per_batch':{str(b):dict(Counter(t)) for b,t in sorted(batch_topics.items())},
            'existing_senses':sum(bool(e['sense_key']) for e in entries),
            'new_senses':sum(bool(e['proposed_sense_key']) for e in entries),
            'existing_cards':len(rows['cards']),'existing_groups':len({r['learning']['group_id'] for r in rows['cards']}),
            'new_groups':len(planned),'registry_words':len(registry['words']),
            'partition_selection':f'PASS: {len(present)} present','validate_selection':'PASS: parent and exact reservations',
            'index_registry':'PASS','validate_learning':'PASS: existing and planned',
            'build_rows':'PASS: reservation-only rows unchanged','semantic_review':'explicit editorial decisions, no automatic equivalence inference'}


def partition_batches(entries, batch):
    return {name:[e['selection_id'] for e in entries if predicate(e['authoring_batch'])]
            for name,predicate in [('imported',lambda b:b<batch),('current',lambda b:b==batch),('future',lambda b:b>batch)]}


def sentence_binding(pack, ref):
    links=[l for l in pack['card_sentences'] if l['card']==ref and not l.get('removed_in')]
    require(len(links)==1, 'imported fixed sentence count')
    link=links[0]
    sentences=[s for s in pack['sentences'] if s['ref']==link['sentence'] and not s.get('removed_in')]
    require(len(sentences)==1,'imported sentence missing')
    return {'link':copy.deepcopy(link),'sentence':copy.deepcopy(sentences[0]),
            'tokens_sha256':digest([t for t in pack['sentence_tokens'] if t['sentence']==link['sentence']])}


def display_plan(pack, entries, batch, owner):
    current=sorted((e for e in entries if e['authoring_batch']==batch),key=lambda e:e['position'])
    existing=sorted((w for w in pack['deck_words'] if w['deck']==owner and not w.get('removed_in')),key=lambda w:w['position'])
    expected={w['primary_card']:w['position'] for w in existing}
    appended=[{'card_ref':e['card_ref'],'form_norm':e['form_norm'],'original_position':e['position'],
               'append_position':len(existing)+i} for i,e in enumerate(current,1)]
    expected.update({m['card_ref']:m['append_position'] for m in appended})
    combined=sorted((e for e in entries if e['authoring_batch']<=batch),key=lambda e:e['position'])
    return {'existing':[{'card_ref':w['primary_card'],'form_norm':w['form_norm'],'position':w['position']} for w in existing],
            'append':appended,'rows':[{'card_ref':e['card_ref'],'form_norm':e['form_norm'],'original_position':e['position'],
                'expected_position':expected[e['card_ref']],'position':i} for i,e in enumerate(combined,1)]}


def validate_display_plan(pack, selection, plan, registry):
    from .deck_display import apply_deck_display_patch
    batch=selection['continuation']['authoring_batch'];owner=selection['owner_deck_ref']
    require(plan == display_plan(pack,selection['entries'],batch,owner),'display mapping changed')
    # Exercise the existing pure display contract on membership-only copies.
    # No new cards/sentences are generated and no resulting pack is exported.
    simulated=copy.deepcopy(pack)
    simulated['word_registry']={'snapshot':registry,'sha256':digest(registry)}
    for m in plan['append']:
        simulated['deck_cards'].append({'deck':owner,'card':m['card_ref'],'position':m['append_position']})
        simulated['deck_words'].append({'deck':owner,'primary_card':m['card_ref'],'form_norm':m['form_norm'],'position':m['append_position']})
    patch={'format':'sprachapp.deck-display-patch','format_version':1,'operation_id':'validate-authoring-positions',
           'deck':owner,'source_sha256':selection['source_pack']['sha256'],'create_sha256':'0'*64,
           'registry_sha256':digest(registry),'expected_before_sha256':{t:digest([w for w in simulated[t] if w['deck']==owner]) for t in ('deck_cards','deck_words')},'rows':plan['rows']}
    apply_deck_display_patch(simulated,patch,source_sha256=patch['source_sha256'],create_sha256=patch['create_sha256'],registry_sha256=patch['registry_sha256'])


def prepare_continuation(pack, original, previous_groups, *, source_bytes, source_path,
                         batch, version, registry_path, groups_path, original_path,
                         definition_equivalences=None, source_sqlite_sha256=None):
    """Create new snapshots without editing prior versions or app content."""
    require('continuation' not in original, 'use immutable initial selection')
    registry=copy.deepcopy(pack['word_registry']['snapshot'])
    registry.update(version=version,parent_sha256=digest(registry),source_pack_sha256=hashlib.sha256(source_bytes).hexdigest(),
                    reservation_status=f'continuation_batch_{batch}')
    registry.pop('source_sqlite_sha256',None)
    if source_sqlite_sha256 is not None:
        registry['source_sqlite_sha256']=source_sqlite_sha256
    rows=build_rows(pack); ids={c['ref']:r['id'] for c,r in zip(pack['cards'],rows['cards'])}
    refs={v:k for k,v in ids.items()}
    existing={'version':version,'source_pack_sha256':hashlib.sha256(source_bytes).hexdigest(),
              'cards':[dict(card_ref=c['ref'],card_id=ids[c['ref']],primary_card_ref=refs[c['learning']['primary_card_id']],**c['learning']) for c in pack['cards']]}
    entries=original['entries'];parts=partition_batches(entries,batch)
    groups={'version':version,'status':'continuation_not_imported','source_pack_sha256':hashlib.sha256(source_bytes).hexdigest(),
            'parent_sha256':digest(existing),'existing':existing,'previous_snapshot':copy.deepcopy(previous_groups),
            'previous_snapshot_sha256':digest(previous_groups),'partitions':parts,
            'reserved_cards':[dict(card_ref=e['card_ref'],card_id=e['card_id'],primary_card_ref=e['card_ref'],**e['learning']) for e in entries if e['authoring_batch']>=batch]}
    selection=copy.deepcopy(original)
    selection.update(source_pack={'path':source_path,'version':pack['release']['version'],'schema_version':3,
                     'sha256':hashlib.sha256(source_bytes).hexdigest(),'canonical_sha256':digest(pack)},
                     registry_path=registry_path,registry_sha256=digest(registry),learning_groups_path=groups_path,learning_groups_sha256=digest(groups))
    selection['continuation']={'format_version':1,'authoring_batch':batch,'original_selection_path':original_path,
        'original_selection':copy.deepcopy(original),'original_selection_sha256':digest(original),'partitions':parts,
        'definition_equivalences':definition_equivalences or {},
        'imported_sentences':{e['card_ref']:sentence_binding(pack,e['card_ref']) for e in entries if e['authoring_batch']<batch},
        'display_plan':display_plan(pack,entries,batch,original['owner_deck_ref'])}
    validate_context(pack,selection,registry,groups,source_bytes=source_bytes)
    return selection,registry,groups
