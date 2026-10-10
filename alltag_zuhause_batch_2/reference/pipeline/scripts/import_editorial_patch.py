"""Hash-bound, offline editorial exchange adapter for the existing curation path.

Exit 0: verified export; 1: saved working state with precise blockers; 2: rejected
input/output path. Never imports an LLM client, installs content or edits sources.
"""
from __future__ import annotations

from sprachpipe.content_contract import sentence_count

import argparse
import copy
import hashlib
import json
from collections import Counter
from pathlib import Path

from sprachpipe.annotate import tokenize
from sprachpipe.config import PIPELINE_DIR, load_config
from sprachpipe.curate import CurationError, curate, derive_dictionary, finalize
from sprachpipe.ids import stable_id, form_norm
from sprachpipe.linter import lint_sentence
from sprachpipe.pack import build_rows, sentence_lint_items

ROOT = PIPELINE_DIR.parent


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':')).encode('utf8')).hexdigest()


def read(path):
    return json.loads(Path(path).read_text(encoding='utf8'))


def save(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf8')


def require(ok, message):
    if not ok:
        raise CurationError(message)


def verify_exchange(raw, patch, corpus):
    source = json.loads(raw)
    require(patch['format'] == 'sprachapp.editorial-patch' and patch['format_version'] == 1,
            'unsupported exchange format')
    require(hashlib.sha256(raw).hexdigest() == patch['source']['sha256']
            or digest(source) == patch['source']['canonical_json_sha256'], 'source hash mismatch')
    require(digest(source) == patch['source']['canonical_json_sha256'], 'canonical source mismatch')
    require(source['release'] == patch['source']['release'] and source['lang'] == patch['source']['lang'],
            'release/language mismatch')
    require({k: len(v) for k, v in source.items() if isinstance(v, list)} == patch['source']['counts'],
            'source counts mismatch')
    rows = build_rows(source)
    ids = {table: {r['ref']: row['id'] for r, row in zip(source[table], rows[table])}
           for table in ('cards', 'senses', 'lemmas', 'sentences')}
    cards = {r['ref']: r for r in source['cards']}
    senses = {r['ref']: r for r in source['senses']}
    sentences = {r['ref']: r for r in source['sentences']}
    links = {(r['card'], r['sentence']): r for r in source['card_sentences']}
    require(len(links) == len(source['card_sentences']), 'duplicate source links')
    operations = {}
    for op in patch['sentence_operations']:
        key = op['card_ref'], op['sentence_ref']
        require(key not in operations, f'duplicate operation {key}')
        operations[key] = op
        s, cs = sentences[key[1]], links[key]
        expected = {k: s[k] for k in ('text', 'translation_de')}
        expected.update({k: cs.get(k, []) for k in ('gap_start', 'gap_end', 'accepted', 'valid_alternatives')})
        require(expected == op['expect'], f"precondition {op['op_id']}")
        require(digest(s) == op['expect_sentence_row_sha256'] and digest(cs) == op['expect_link_row_sha256'],
                f"row hash {op['op_id']}")
        require(cs['position'] == op['sentence_position'], f"position {op['op_id']}")
        sense = cards[key[0]]['sense']
        require(op['card_id'] == ids['cards'][key[0]] and op['sense_id'] == ids['senses'][sense]
                and op['lemma_id'] == ids['lemmas'][senses[sense]['lemma']], 'card identity mismatch')
        sid = stable_id('sentences', lang=source['lang'], text=op['new']['text'])
        require(op['old_sentence_id'] == ids['sentences'][key[1]] and sid == op['new_sentence_id']
                and op['new_card_sentence_id'] == stable_id('card_sentences', card_id=op['card_id'],
                                                           sentence_id=sid), 'sentence identity mismatch')
        require(sorted(op['changed_fields']) == sorted(k for k in expected if expected[k] != op['new'][k]),
                'changed_fields mismatch')
    require(len({op['op_id'] for op in operations.values()}) == len(operations), 'duplicate op_id')
    metakeys = [(o['table'], o['ref'], o['field']) for o in patch['metadata_operations']]
    require(len(set(metakeys)) == len(metakeys), 'duplicate metadata operation')
    require(corpus['source_sha256'] == patch['source']['sha256'] and corpus['stats'] == patch['stats'],
            'corpus source/stats mismatch')
    records = {}
    for r in corpus['records']:
        key = r['card_ref'], r['sentence_ref']
        require(key not in records and key in links, 'corpus duplicate/unknown record')
        records[key] = r
        s, cs = sentences[key[1]], links[key]
        old = {k: s[k] for k in ('text', 'translation_de')}
        old.update({k: cs.get(k, []) for k in ('gap_start', 'gap_end', 'accepted', 'valid_alternatives')})
        require(r['before'] == old, f'corpus precondition {key}')
        require(r['after'] == (operations[key]['new'] if key in operations else old), f'corpus after {key}')
        require(r['card_id'] == ids['cards'][key[0]] and r['old_sentence_id'] == ids['sentences'][key[1]],
                f'corpus IDs {key}')
        require(r['proposed_sentence_id'] == stable_id('sentences', lang=source['lang'], text=r['after']['text']),
                f'corpus proposed ID {key}')
    require(set(records) == set(links), 'corpus does not cover every sentence link')
    stats = Counter(r['status'] for r in records.values())
    require(len(records) == patch['stats']['sentence_pairs_read']
            and len(operations) == patch['stats']['sentence_records_changed'], 'operation/coverage counts')
    require(sum('text' in o['changed_fields'] for o in operations.values()) == patch['stats']['english_replacements'],
            'English replacement count')
    require(stats.get('keep', 0) == patch['stats']['unchanged_sentence_records']
            and stats.get('hold_recommended', 0) == patch['stats']['held_sentence_records']
            and stats.get('rewrite', 0) == patch['stats']['english_replacements']
            and stats.get('translation', 0) == patch['stats']['translation_only_or_translation_and_alternatives']
            and stats.get('alternatives', 0) == patch['stats']['alternatives_only']
            and len(metakeys) == patch['stats']['metadata_changes'], 'status distribution mismatch')
    held = set()
    for rec in patch['card_recommendations']:
        require(rec['status'] == 'recommendation_not_applied' and rec['card_id'] == ids['cards'][rec['card_ref']],
                'invalid hold recommendation')
        require(rec['card_ref'] not in held, 'duplicate hold recommendation')
        held.add(rec['card_ref'])
    require({r['card_ref'] for r in records.values() if r['status'] == 'hold_recommended'} == held,
            'held corpus cards differ from recommendations')
    return source, dict(stats)


def make_plan(source, patch):
    # Existing deck_order_key: rank equal to the current position preserves all
    # memberships and positions, without reloading/changing the meaning inventory.
    positions = {d['card']: d['position'] for d in source['deck_cards']}
    provenance = {'reviewer': patch['reviewer'], 'patch_id': patch['patch_id'],
                  'source_sha256': patch['source']['sha256'], 'human_approval': False,
                  'vertex_validation': False}
    plan = {'version': 'chat_editorial_v1', 'lang': source['lang'], 'base': 'source',
            'sources': ['source'], 'card_operations': [], 'sentence_operations': [],
            'editorial_metadata': copy.deepcopy(patch['metadata_operations']),
            'expect': {'cards': len(source['cards']), 'card_sentences': len(source['card_sentences'])},
            'card_meta': {c['ref']: {'rank': positions[c['ref']], 'usage': 'haupt', 'sense_index': 1}
                          for c in source['cards']}, 'provenance': provenance}
    for op in patch['sentence_operations']:
        plan['sentence_operations'].append({
            'op': 'editorial_sentence', 'op_id': op['op_id'], 'source': 'source',
            'card': op['card_ref'], 'sentence_id': op['old_sentence_id'], 'label': op['sentence_ref'],
            'expect': {k: op['expect'][k] for k in ('text', 'translation_de')},
            'expect_link': {k: op['expect'][k] for k in ('gap_start', 'gap_end', 'accepted', 'valid_alternatives')},
            'new': copy.deepcopy(op['new']), 'reason': op['reason'], 'provenance': provenance})
    return plan


def apply_finish(source, patch, saved, supplement, previous):
    """Compose explicit, hash-bound corrections without mutating either input."""
    from sprachpipe.generate import gap_offsets
    require(supplement['format'] == 'sprachapp.editorial-finish' and supplement['format_version'] == 1,
            'unsupported finish format')
    require(digest(saved) == supplement['base_plan_sha256'] and
            digest(previous) == supplement['working_state_sha256'], 'finish source hash mismatch')
    def open_keys(items):
        return {(d['op_id'], d['idx'], d['surface']) for d in items}
    require(open_keys(saved.get('open_token_decisions', [])) == open_keys(supplement['resolved_open_tokens']),
            'finish original open-token coverage mismatch')
    patch, saved = copy.deepcopy(patch), copy.deepcopy(saved)
    ops = {o['op_id']: o for o in patch['sentence_operations']}
    decisions = {(d['op_id'], d['idx']): d for d in saved['token_decisions']}
    replaced, history = set(), []
    for change in supplement['sentence_replacements']:
        op = ops[change['op_id']]
        require(op['op_id'] not in replaced, 'duplicate finish sentence')
        require(op['sentence_ref'] == change['source_ref'] and op['new'] == change['expect'] and
                op['new_sentence_id'] == change['expected_sentence_id'], 'finish sentence precondition')
        old = next(s for s in previous['sentences'] if s['ref'] == 'chat_editorial_v1/source/'+op['sentence_ref'])
        require(old['text'] == change['expect']['text'], 'finish working text mismatch')
        history.append({'op_id': op['op_id'], 'sentence': old,
                        'tokens': [t for t in previous['sentence_tokens'] if t['sentence'] == old['ref']],
                        'link': next(c for c in previous['card_sentences'] if c['sentence'] == old['ref'])})
        new = change['new']
        form = op['expect']['accepted'][0]
        require(new['accepted'] == [form] and new['valid_alternatives'] == [], 'finish answer lists')
        require(tuple(new[k] for k in ('gap_start', 'gap_end')) == gap_offsets(new['text'], form),
                'finish gap mismatch')
        op['new'] = copy.deepcopy(new)
        op['new_sentence_id'] = stable_id('sentences', lang=source['lang'], text=new['text'])
        op['new_card_sentence_id'] = stable_id('card_sentences', card_id=op['card_id'], sentence_id=op['new_sentence_id'])
        op['changed_fields'] = [k for k in op['expect'] if op['expect'][k] != new[k]]
        op['reason'] += ' / ' + change['reason']
        replaced.add(op['op_id'])
    decisions = {k: v for k, v in decisions.items() if k[0] not in replaced}
    for replacement in supplement['token_replacements']:
        d = replacement['new']; key = d['op_id'], d['idx']
        require(decisions.get(key) == replacement['expect'], 'finish token precondition')
        decisions[key] = d
    for d in supplement['token_decisions']:
        key = d['op_id'], d['idx']
        require(key not in decisions, 'duplicate finish token')
        decisions[key] = d
    for d in saved.get('open_token_decisions', []):
        require(d['op_id'] in replaced or (d['op_id'], d['idx']) in decisions,
                'unresolved original token in finish')
    # New wording must have explicit new decisions for every word, bound to its ID.
    for op_id in replaced:
        op = ops[op_id]
        expected = {(op_id, t['idx']) for t in tokenize(op['new']['text']) if t['is_word']}
        actual = {k for k in decisions if k[0] == op_id}
        require(actual == expected, 'incomplete finish sentence annotation')
    saved['token_decisions'] = list(decisions.values())
    saved['open_token_decisions'] = []
    saved['dictionary_resolutions'] += supplement.get('dictionary_resolutions', [])
    return patch, saved, history


def annotation_catalogue(source, vocabulary):
    """Explicit dictionary additions only; never overwrite a shared source sense."""
    result = copy.deepcopy(source)
    for table in ('lemmas', 'senses'):
        existing = {r['ref']: r for r in result[table]}
        for row in vocabulary.get(table, []):
            require(row['ref'] not in existing, f'dictionary overwrite: {row["ref"]}')
            if table == 'senses':
                require(row.get('definition_de') and row.get('gloss_de') and
                        row['ref'] == row['lemma']+'|'+row['sense_key'], 'incomplete dictionary sense')
            existing[row['ref']] = copy.deepcopy(row)
        result[table] = list(existing.values())
    keys = {(form_norm(r['form']), r['sense']) for r in result['dictionary_forms']}
    for row in vocabulary.get('forms', []):
        key = form_norm(row['form']), row['sense']
        require(key not in keys and row.get('gloss_de'), 'dictionary form overwrite/empty gloss')
        keys.add(key)
        result['dictionary_forms'].append(copy.deepcopy(row))
    return result


def annotate_local(work, source, decisions, vocabulary=None):
    """Only explicitly reviewed per-token assignments; candidates are never approvals."""
    from sprachpipe.linter import _nlp
    from complete_curation import _token_rows
    nlp = _nlp()
    source = annotation_catalogue(source, vocabulary or {})
    source_senses = {s['ref']: s for s in source['senses']}
    source_lemmas = {s['ref']: s for s in source['lemmas']}
    dictionary = {(form_norm(d['form']), d['sense']): d['gloss_de'] for d in source['dictionary_forms']}
    cards = {c['ref']: c for c in work['cards']}
    senses = {s['ref']: s for s in work['senses']}
    lemmas = {s['ref']: s for s in work['lemmas']}
    sentences = {s['ref']: s for s in work['sentences']}
    choices = {(d['op_id'], d['idx']): d for d in decisions}
    require(len(choices) == len(decisions), 'duplicate token decision')
    used, records, pending = set(), [], []
    for step in list(work['curation']['pending']):
        if step['kind'] != 'editorial_annotation':
            continue
        s = sentences[step['sentence']]
        cs = next(c for c in work['card_sentences'] if c['sentence'] == s['ref'])
        tokens = tokenize(s['text'], nlp)
        doc = nlp(s['text'])
        unresolved = []
        for t in tokens:
            key = step['op_id'], t['idx']
            row = {k: t[k] for k in ('idx', 'start_pos', 'end_pos', 'surface')}
            row.update(sentence=s['ref'], lemma=None, sense=None, card=None)
            entry = dict(t, op_id=step['op_id'], sentence=s['ref'], text=s['text'],
                         translation_de=s['translation_de'], suggested_lemma=doc[t['idx']].lemma_,
                         target=t['start_pos'] == cs['gap_start'] and t['end_pos'] == cs['gap_end'])
            d = choices.get(key)
            if not t['is_word']:
                require(d is None, f'punctuation decision {key}')
                entry['status'] = 'punctuation'
            elif d:
                used.add(key)
                require(d['surface'] == t['surface'] and d['sentence_id'] == stable_id(
                    'sentences', lang=work['lang'], text=s['text']), f'token decision precondition {key}')
                require(bool(d.get('reason')), f'token decision needs context reason {key}')
                if 'annotation' in d:
                    require(not entry['target'], f'new target sense forbidden {key}')
                    a = d['annotation']
                    require(set(a) == {'lemma', 'pos', 'gloss_de'} and all(a.values()),
                            f'incomplete local annotation {key}')
                    # Same lemma/sense construction as normal pipeline annotation.
                    work['lemmas'], work['senses'] = list(lemmas.values()), list(senses.values())
                    new_rows, glosses = _token_rows(work, s['ref'], [dict(t, **a)], cards[step['card']])
                    row = new_rows[0]
                    work['curation'].setdefault('annotation_glosses', []).extend(glosses)
                    senses = {v['ref']: v for v in work['senses']}
                    lemmas = {v['ref']: v for v in work['lemmas']}
                else:
                    sense = source_senses.get(d['sense'])
                    require(sense is not None, f'unknown reviewed sense {key}')
                    lref = sense['lemma']
                    require(d['lemma'] == lref and d['gloss_de'] == dictionary.get((form_norm(t['surface']), d['sense'])),
                            f'not an existing concrete form gloss {key}')
                    if entry['target']:
                        require(d['sense'] == cards[step['card']]['sense'], f'target sense {key}')
                    senses.setdefault(sense['ref'], copy.deepcopy(sense))
                    lemmas.setdefault(lref, copy.deepcopy(source_lemmas[lref]))
                    row.update(lemma=lref, sense=d['sense'], card=step['card'] if entry['target'] else None)
                    work['curation'].setdefault('annotation_glosses', []).append({
                        'form': form_norm(t['surface']), 'sense': d['sense'], 'gloss_de': d['gloss_de'],
                        'sentence': s['ref'], 'idx': t['idx'], 'card': row['card']})
                entry.update(status='resolved', decision=d)
            else:
                entry['status'] = 'open_context_assignment'
                candidates = []
                for (form, sense), gloss in dictionary.items():
                    if form == form_norm(t['surface']):
                        sr = source_senses[sense]
                        lm = source_lemmas[sr['lemma']]
                        candidates.append({'lemma': sr['lemma'], 'sense': sense, 'gloss_de': gloss,
                                           'lemma_matches': lm['lemma'].casefold() == doc[t['idx']].lemma_.casefold(),
                                           'pos_matches': lm['pos'] == t['pos']})
                entry['candidates'] = candidates
                unresolved.append(entry)
            work['sentence_tokens'].append(row)
            records.append(entry)
        if unresolved:
            pending += unresolved
        else:
            work['curation']['pending'].remove(step)
            work['curation'].setdefault('completed', []).append(dict(step, result={
                'provenance': 'explicit local Codex token decisions, no Vertex call',
                'sentence_id': stable_id('sentences', lang=work['lang'], text=s['text']),
                'tokens': len(tokens)}))
    require(set(choices) == used, f'unused token decisions {sorted(set(choices)-used)}')
    work['lemmas'] = list(lemmas.values())
    work['senses'] = list(senses.values())
    return records, pending


def validate_work(work, source, patch):
    from sprachpipe.pack import _valid_alternatives
    cards = {c['ref']: c for c in work['cards']}
    sentences = {s['ref']: s for s in work['sentences']}
    senses = {s['ref']: s for s in work['senses']}
    lemmas = {l['ref']: l for l in work['lemmas']}
    tokens = {}
    for t in work['sentence_tokens']:
        require((t['sentence'], t['idx']) not in tokens, 'duplicate token index')
        tokens[t['sentence'], t['idx']] = t
        s = sentences[t['sentence']]
        require(s['text'][t['start_pos']:t['end_pos']] == t['surface'], 'token offset mismatch')
        if t.get('sense'):
            require(t['sense'] in senses and t['lemma'] in lemmas and senses[t['sense']]['lemma'] == t['lemma'],
                    'token reference mismatch')
        if t.get('card'):
            require(t['card'] in cards and t['sense'] == cards[t['card']]['sense'], 'token card mismatch')
    for c in work['cards']:
        require(sorted(cs['position'] for cs in work['card_sentences'] if cs['card'] == c['ref'] and not cs.get('removed_in')) == list(range(1, sentence_count(work)+1)),
                f'card positions {c["ref"]}')
    for cs in work['card_sentences']:
        s, card = sentences[cs['sentence']], cards[cs['card']]
        require(s['text'][cs['gap_start']:cs['gap_end']].casefold() == card['form'].casefold(), 'gap mismatch')
        require(cs['accepted'] == [card['form']], 'accepted mismatch')
        _valid_alternatives(cs, card['form'])
        if 'editorial' in (s.get('qa_report') or {}):
            now = {k: s[k] for k in ('text', 'translation_de')}
            now.update({k: cs[k] for k in ('gap_start', 'gap_end', 'accepted', 'valid_alternatives')})
            require(now == s['qa_report']['editorial']['checked'], 'stale editorial evidence')
            require(s['qa_status'] == 'editorial_reviewed', 'wrong editorial status')
    # Compare source/new identities without clearing pending or calling an export.
    def card_id(c, ss, ll):
        se = ss[c['sense']]; lm = ll[se['lemma']]
        lid = stable_id('lemmas', lang=work['lang'], lemma=lm['lemma'], pos=lm['pos'])
        sid = stable_id('senses', lemma_id=lid, sense_key=se['sense_key'])
        return stable_id('cards', lang=work['lang'], form=c['form'], sense_id=sid)
    os = {s['ref']: s for s in source['senses']}; ol = {l['ref']: l for l in source['lemmas']}
    require({card_id(c, senses, lemmas) for c in work['cards']} ==
            {card_id(c, os, ol) for c in source['cards']}, 'card IDs changed')
    require(work['deck_cards'] == source['deck_cards'], 'deck memberships/positions changed')
    require(len({s['text'] for s in work['sentences']}) == len(source['sentences']), 'duplicate/missing sentences')
    by_op = {o['sentence_ref']: o for o in patch['sentence_operations']}
    unchanged = changed = 0
    for old in source['sentences']:
        op = by_op.get(old['ref'])
        english_changed = op is not None and 'text' in op['changed_fields']
        ref = ('chat_editorial_v1/' if english_changed else '') + 'source/' + old['ref']
        current = sentences[ref]
        require(current['text'] == (op['new']['text'] if op else old['text']), 'unexpected text mutation')
        if english_changed:
            changed += 1
            require(current['model'] is None and set(current['qa_report']) ==
                    {'editorial', 'historical_source_sentence_id'}, 'old model evidence on new English')
        else:
            unchanged += 1
            original_tokens = [dict(t, sentence=ref) for t in source['sentence_tokens'] if t['sentence'] == old['ref']]
            require(original_tokens == [t for t in work['sentence_tokens'] if t['sentence'] == ref],
                    f'unchanged English tokens modified: {ref}')
            if op is None:
                require(dict(old, ref=ref) == current, f'unedited sentence mutated: {ref}')
        if op:
            cs = next(c for c in work['card_sentences'] if c['sentence'] == ref)
            require(cs['valid_alternatives'] == op['new']['valid_alternatives'], 'old alternatives returned')
        actual = [t for t in work['sentence_tokens'] if t['sentence'] == ref]
        if english_changed:
            expected = tokenize(current['text'])
            require([{k: t[k] for k in ('idx', 'start_pos', 'end_pos', 'surface')} for t in actual] ==
                    [{k: t[k] for k in ('idx', 'start_pos', 'end_pos', 'surface')} for t in expected],
                    f'incomplete new token coverage: {ref}')
    return {'cards_unchanged': len(cards), 'sentences': len(sentences),
            'changed_sentence_ids': changed, 'unchanged_sentence_ids': unchanged,
            'tokens_checked': len(tokens), 'accepted_unchanged': True, 'deck_memberships_unchanged': True}


def import_patch(source_path, patch_path, corpus_path, plan_path, out, finish_path=None):
    require(not out.exists(), f'output already exists: {out}')
    raw = source_path.read_bytes(); patch = read(patch_path); corpus = read(corpus_path)
    source, coverage = verify_exchange(raw, patch, corpus)
    saved = read(plan_path)
    require(saved['exchange_sha256'] == hashlib.sha256(patch_path.read_bytes()).hexdigest()
            and saved['corpus_sha256'] == hashlib.sha256(corpus_path.read_bytes()).hexdigest(), 'exchange file changed')
    plan = make_plan(source, patch)
    require(saved['curation'] == plan, 'versioned adapter plan differs from exchange')
    supplement, history = None, []
    if finish_path:
        supplement = read(finish_path)
        previous = read(ROOT/supplement['working_state_path'])
        patch, saved, history = apply_finish(source, patch, saved, supplement, previous)
        plan = make_plan(source, patch)
        plan['provenance']['finish_version'] = supplement['version']
        plan['provenance']['finish_sha256'] = digest(supplement)
        plan['provenance']['finish_review'] = supplement['provenance']
    work, log = curate({'source': source}, plan, plan['card_meta'])
    records, pending = annotate_local(work, source, saved['token_decisions'],
                                      supplement['vocabulary'] if supplement else None)
    open_decisions = {(d['op_id'], d['idx']): d for d in saved.get('open_token_decisions', [])}
    require(set(open_decisions) == {(d['op_id'], d['idx']) for d in pending}, 'open token decision list differs')
    for entry in pending:
        decision = open_decisions[entry['op_id'], entry['idx']]
        require(decision['surface'] == entry['surface'] and decision.get('reason'), 'open token precondition')
        entry['reason'] = decision['reason']
    checks = validate_work(work, source, patch)
    cfg = load_config()
    lint = []
    for cs, item in zip(work['card_sentences'], sentence_lint_items(work)):
        findings = lint_sentence(item['sentence'], item['form'], item['gap_start'], item['gap_end'],
            cfg['linter']['min_zipf'][item['cefr_band']], lang=work['lang'], names=cfg['generate']['names'],
            max_words=cfg['linter']['max_words'], max_subclauses=cfg['linter']['max_subclauses'])
        lint += [dict(sentence_ref=cs['sentence'], card_ref=cs['card'], text=item['sentence'],
                      level=f.level, rule=f.rule, message=f.message) for f in findings]
    if not any(f['level'] == 'error' for f in lint):
        work['curation']['pending'] = [p for p in work['curation']['pending'] if p['kind'] != 'editorial_validation']
    dictionary = derive_dictionary(work, saved.get('dictionary_resolutions', []))
    if not pending and not dictionary['missing'] and not dictionary['conflicts']:
        work['dictionary_forms'] = [{k: d[k] for k in ('form', 'sense', 'card', 'gloss_de', 'rank')}
                                    for d in dictionary['entries']]
        work['curation']['pending'] = [p for p in work['curation']['pending'] if p['kind'] != 'dictionary_forms']
    hold_plan = []
    for recommendation in patch['card_recommendations']:
        cref = recommendation['card_ref']
        hold_plan.append(dict(recommendation,
            source_memberships=[d for d in source['deck_cards'] if d['card'] == cref],
            source_sentences=[dict(cs, text=next(s['text'] for s in source['sentences']
                                               if s['ref'] == cs['sentence']))
                              for cs in source['card_sentences'] if cs['card'] == cref],
            proposed_membership_change={'action': 'remove_from_beginner_deck', 'applied': False},
            blocker='curate requires exactly one deck membership per card; membership removal alone '
                    'would not suppress existing mixed due/early reviews or user-state counters. '
                    'build_rows does not transport tombstones. No compatible content-only exclusion.',
            user_state_change=False))
    report = {'status': 'working_state', 'coverage': coverage, 'checks': checks,
              'provenance': plan['provenance'], 'source_sha256': hashlib.sha256(raw).hexdigest(),
              'curation_log': log, 'metadata_operations': len(plan['editorial_metadata']),
              'sentence_operations': len(plan['sentence_operations']),
              'annotation': {'changed_english_sentences': checks['changed_sentence_ids'], 'tokens': len(records),
                 'resolved_words': sum(r['status'] == 'resolved' for r in records),
                 'open_words': len(pending), 'punctuation': sum(r['status'] == 'punctuation' for r in records)},
              'lint': {'sentences_checked': len(work['card_sentences']),
                       'errors': sum(f['level'] == 'error' for f in lint),
                       'warnings': sum(f['level'] == 'warn' for f in lint), 'findings': lint},
              'card_recommendations': hold_plan,
              'dictionary_complete': not pending and not dictionary['missing'] and not dictionary['conflicts'],
              'ai_calls': 0, 'ai_cost_usd': 0}
    if supplement:
        work['release']['version'] = supplement['version']
        report['finish'] = {'version': supplement['version'], 'sha256': digest(supplement),
                            'superseded_editorial_history': history,
                            'resolved_original_tokens': len(supplement['resolved_open_tokens'])}
    out.mkdir(parents=True, exist_ok=False)
    save(out/'working_state.json', work)
    save(out/'annotation_review.json', records)
    save(out/'open_annotations.json', pending)
    save(out/'dictionary_report.json', dictionary)
    save(out/'hold_recommendations.json', hold_plan)
    if not work['curation']['pending']:
        # Existing export path, with all annotation/QA gates satisfied first.
        from sprachpipe.export import export_sqlite
        from finalize_curation import check_sqlite
        final = finalize(work)
        final['release']['notes'] = ('INTERNES TEST-PACK: offline editorial model review with explicit user '
                                    'corrections; no public release, human certification or new Vertex QA.')
        rows = build_rows(final)
        save(out/'pack.json', final)
        export_sqlite(final, out/'content.sqlite')
        report['sqlite_counts'] = check_sqlite(out/'content.sqlite', rows)
        report['status'] = 'ok'
        save(out/'finalization_report.json', {'status': 'ok', 'internal_test_pack': True,
             'note': final['release']['notes'], 'sqlite_counts': report['sqlite_counts'],
             'source_sha256': report['source_sha256'], 'provenance': report['provenance'],
             'ai_calls': 0, 'ai_cost_usd': 0, 'card_recommendations': hold_plan})
        print('export/readback: every SQLite table equals build_rows: ' + str(report['sqlite_counts']))
    report['pending_steps'] = work['curation']['pending']
    save(out/'import_report.json', report)
    print(f"status {report['status']}: {len(source['cards'])} cards, {len(corpus['records'])} sentence pairs; "
          f"{len(plan['sentence_operations'])} sentence / {len(plan['editorial_metadata'])} metadata operations")
    print(f"annotation: {report['annotation']}")
    print(f"lint: {report['lint']['sentences_checked']} sentences, {report['lint']['errors']} errors, {report['lint']['warnings']} warnings")
    print(f"dictionary: {len(dictionary['entries'])} resolved keys, {len(dictionary['missing'])} missing, {len(dictionary['conflicts'])} conflicts; complete={report['dictionary_complete']}")
    print(f"cloud calls 0; cost 0 USD; output {out}")
    return 0 if report['status'] == 'ok' else 1


def create_content(source, entry, registry, *, source_hash):
    """Offline schema-2/3 create, using the same rows, linter and exporter."""
    from sprachpipe.word_registry import digest as registry_digest, validate_selection
    require(entry.get('format') == 'sprachapp.editorial-content' and entry.get('format_version') == 2,
            'unsupported create format')
    spec = read(ROOT/'pipeline/data/curation/editorial_content_v2.schema.json')
    require(all(k in entry for k in spec['required']), 'missing required create field')
    for table, values in entry['add'].items():
        require(table in spec['properties']['add']['properties'], f'unsupported create table {table}')
        require(isinstance(values, list), f'{table} must be an array')
        required = spec['properties']['add']['properties'][table]['items']['required']
        for i, row in enumerate(values):
            require(isinstance(row, dict) and all(k in row for k in required),
                    f'create {table}[{i}]: required fields {required}')
    require(source_hash == entry['source_sha256'], 'create source hash mismatch')
    require(registry_digest(registry) == entry['registry_sha256'], 'create registry hash mismatch')
    schema_version = source['release']['schema_version']
    require(schema_version in (2, 3), 'create requires schema-2 or schema-3 base')
    require(registry.get('parent_sha256') == source['word_registry']['sha256'], 'registry must extend this base snapshot')
    old_words = source['word_registry']['snapshot']['words']
    require(all(w in registry['words'] for w in old_words), 'create registry changes existing ownership')
    require(entry.get('operation_id') and entry.get('reviewer'), 'operation_id/reviewer required')
    work = copy.deepcopy(source)
    tables = {'lemmas', 'senses', 'cards', 'decks', 'deck_cards', 'deck_words', 'word_aliases',
              'sentences', 'sentence_tokens', 'card_sentences', 'dictionary_forms', 'stories', 'story_sentences'}
    require(set(entry['add']) <= tables, 'unsupported create table')
    for table, values in entry['add'].items():
        require(isinstance(values, list), f'{table} must be an array')
        require(all(not r.get('removed_in') and not r.get('replaced_by') for r in values), 'create cannot retire content')
        work.setdefault(table, []).extend(copy.deepcopy(values))
    # Ref collisions must fail before build_rows can resolve an ambiguous reference.
    for table in ('lemmas', 'senses', 'cards', 'decks', 'sentences', 'stories'):
        refs = [r['ref'] for r in work.get(table, [])]
        require(len(refs) == len(set(refs)), f'duplicate {table} ref')
    require(entry['version'] != source['release']['version'], 'create needs a new pack version')
    work['release'] = {'version': entry['version'], 'schema_version': schema_version,
                       'notes': 'INTERNES TEST-PACK: offline editorial create; no Vertex QA.'}
    work['word_registry'] = {'sha256': registry_digest(registry), 'snapshot': copy.deepcopy(registry)}
    # Ownership reservation is checked before linguistic work, and again by build_rows.
    lemmas = {r['ref']: r for r in work['lemmas']}
    senses = {r['ref']: r for r in work['senses']}
    memberships = {r['card']: r['deck'] for r in entry['add'].get('deck_cards', [])}
    grouped = {}
    for card in entry['add'].get('cards', []):
        se = senses[card['sense']]; lm = lemmas[se['lemma']]
        sid = stable_id('senses', lemma_id=stable_id('lemmas', lang=work['lang'], lemma=lm['lemma'], pos=lm['pos']), sense_key=se['sense_key'])
        cid = stable_id('cards', lang=work['lang'], form=card['form'], sense_id=sid)
        require(card['ref'] in memberships, 'new card must have a reserved primary membership')
        grouped.setdefault(memberships[card['ref']], []).append({'form': card['form'], 'card_id': cid})
    for owner, cards in grouped.items():
        validate_selection(cards, registry, lang=work['lang'], owner=owner, allow_reserved=True)
    reviews = {r['sentence']: r for r in entry['reviews']}
    added_sentences = entry['add'].get('sentences', [])
    require(len(reviews) == len(entry['reviews']) == len(added_sentences), 'one review per new sentence required')
    require(set(reviews) == {s['ref'] for s in added_sentences}, 'review references differ from new sentences')
    known_senses = {r['ref']: r for r in work['senses']}
    dictionary_keys = {(form_norm(d['form']), d['sense']) for d in work['dictionary_forms'] if d.get('gloss_de')}
    for sn in added_sentences:
        r = reviews.get(sn['ref'])
        tokens = [t for t in work['sentence_tokens'] if t['sentence'] == sn['ref']]
        links = [c for c in work['card_sentences'] if c['sentence'] == sn['ref']]
        require(r and r.get('decision') == 'approved' and r.get('reason') and
                r['checked'] == {'text': sn['text'], 'translation_de': sn['translation_de'],
                                 'tokens_sha256': digest(tokens), 'links_sha256': digest(links)}, 'missing/stale editorial review')
        expected = tokenize(sn['text'])
        require([{k:t[k] for k in ('idx','surface','start_pos','end_pos')} for t in tokens] ==
                [{k:t[k] for k in ('idx','surface','start_pos','end_pos')} for t in expected], 'incomplete token coverage')
        for t, e in zip(tokens, expected):
            if e['is_word']:
                require(t.get('sense') in known_senses and t.get('lemma') and
                        (form_norm(t['surface']), t['sense']) in dictionary_keys, f'missing form gloss/meaning: {t["surface"]}')
        substitutions = [{'card': c['card'], 'alternative': a,
                          'text': sn['text'][:c['gap_start']] + a + sn['text'][c['gap_end']:]}
                         for c in links for a in c.get('valid_alternatives', [])]
        require(r.get('alternatives_checked', []) == substitutions, 'alternative substitution review incomplete')
        contexts = r.get('learning_contexts', [])
        seen_targets = set()
        for context in contexts:
            idx = context['token_index']
            require(idx not in seen_targets and 0 <= idx < len(tokens), 'duplicate/invalid learning target')
            seen_targets.add(idx)
            token = tokens[idx]
            require(context.get('approved') is True and context.get('reason') and
                    context.get('surface') == token['surface'] and context.get('sense') == token.get('sense'),
                    'learning context target/review mismatch')
            require(expected[idx]['is_word'] and len([t for t in expected if t['is_word']]) <= 20,
                    'learning context exceeds 20 words or targets punctuation')
            findings = lint_sentence(sn['text'], token['surface'], token['start_pos'], token['end_pos'],
                                     0, lang=work['lang'], names=load_config()['generate']['names'],
                                     max_words=20, max_subclauses=1)
            require(not any(f.level == 'error' for f in findings), 'invalid learning context: '+str(findings))
        target = next(s for s in work['sentences'] if s['ref'] == sn['ref'])
        target['model'] = None
        target['qa_status'] = 'editorial_reviewed'
        target['qa_report'] = {'editorial_create': {'reviewer': entry['reviewer'], 'operation_id': entry['operation_id'], **copy.deepcopy(r)}}
    build_rows(work)
    return work


def export_offline(final, out):
    from sprachpipe.export import export_sqlite
    from finalize_curation import check_sqlite
    require(not out.exists(), 'output directory already exists')
    rows = build_rows(final)
    cfg = load_config(); lc = cfg['linter']
    findings = []
    for item in sentence_lint_items(final):
        for f in lint_sentence(item['sentence'], item['form'], item['gap_start'], item['gap_end'],
                               lc['min_zipf'][item['cefr_band']], lang=final['lang'], names=cfg['generate']['names'],
                               max_words=lc['max_words'], max_subclauses=lc['max_subclauses']):
            findings.append({'card': item['card'], 'level': f.level, 'rule': f.rule, 'message': f.message})
    require(not any(f['level'] == 'error' for f in findings), 'offline export blocked by linter errors: '+str([f for f in findings if f['level']=='error']))
    out.mkdir(parents=True, exist_ok=False)
    report = {'status': 'failed', 'internal_test_pack': True, 'ai_calls': 0, 'ai_cost_usd': 0,
              'lint': {'sentences': len(final['card_sentences']), 'errors': 0, 'findings': findings}}
    try:
        save(out/'pack.json', final)
        counts = export_sqlite(final, out/'content.sqlite')
        report['sqlite_counts'] = check_sqlite(out/'content.sqlite', rows)
        require(counts == report['sqlite_counts'], 'SQLite readback mismatch')
        report['sha256'] = hashlib.sha256((out/'content.sqlite').read_bytes()).hexdigest()
        report['status'] = 'ok'
    finally:
        save(out/'finalization_report.json', report)
    print(json.dumps({k:v for k,v in report.items() if k != 'lint'}, ensure_ascii=False, indent=2))


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=Path, default=ROOT/'pipeline/out/curated_everyday_v1/pack.json')
    p.add_argument('--patch', type=Path, default=ROOT/'editorial_review/corrections.json')
    p.add_argument('--corpus', type=Path, default=ROOT/'editorial_review/reviewed_sentences.json')
    p.add_argument('--plan', type=Path, default=ROOT/'pipeline/data/curation/chat_editorial_v1.json')
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--single-sentence', type=Path, help='hash-bound existing-sentence selection')
    p.add_argument('--create', type=Path, help='schema-2/3 offline editorial create input')
    p.add_argument('--display-patch', type=Path, help='hash-bound deck positions after --create')
    p.add_argument('--registry', type=Path, default=ROOT/'pipeline/data/words/en.v1.json')
    p.add_argument('--legacy', action='store_true', help='explicit replay of schema-1 editorial artifacts')
    p.add_argument('--finish', type=Path, help='versioned, hash-bound offline completion supplement')
    a = p.parse_args(argv)
    if a.display_patch and not a.create:
        p.error('--display-patch requires --create')
    try:
        if a.single_sentence or a.create:
            require(not (a.single_sentence and a.create), 'choose transition or create')
            require(not a.out.exists(), 'output directory already exists')
            from sprachpipe.word_registry import load_registry
            from sprachpipe.content_contract import transition
            registry = load_registry(a.registry)
            raw = a.source.read_bytes()
            source = json.loads(raw)
            if a.single_sentence:
                final = transition(source, registry, read(a.single_sentence), source_hash=hashlib.sha256(raw).hexdigest())
            else:
                create_raw = a.create.read_bytes()
                final = create_content(source, json.loads(create_raw), registry, source_hash=hashlib.sha256(raw).hexdigest())
                if a.display_patch:
                    from sprachpipe.deck_display import apply_deck_display_patch
                    final = apply_deck_display_patch(
                        final, read(a.display_patch), source_sha256=hashlib.sha256(raw).hexdigest(),
                        create_sha256=hashlib.sha256(create_raw).hexdigest(), registry_sha256=digest(registry))
            export_offline(final, a.out)
            return 0
        require(a.legacy, 'schema-1 patch/finish replay requires --legacy; new content uses --create')
        return import_patch(a.source, a.patch, a.corpus, a.plan, a.out, a.finish)
    except (ValueError, KeyError, OSError) as e:
        print(f'rejected: {type(e).__name__}: {e}')
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
