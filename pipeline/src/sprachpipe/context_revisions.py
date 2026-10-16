"""Schema-5 immutable exercise contexts, built by the existing pack pipeline.

Legacy IDs and display semantics are frozen, including SQLite's ASCII lower().
No user database, provider, network, or authoring approval is involved here.
"""
from __future__ import annotations

import copy
import json
import sqlite3
from collections import defaultdict

from .ids import stable_id, form_norm
from .word_registry import digest

CONTEXT_FIELDS = ('lemma', 'pos', 'sense_key', 'definition_de', 'function', 'form_label_de')


def sentence_identity(lang, sentence):
    revision = sentence.get('revision_sha256')
    if revision is None:
        return stable_id('sentences', lang=lang, text=sentence['text'])
    return stable_id('sentence_revisions', lang=lang,
                     root_sentence_id=sentence['root_sentence_id'], revision_sha256=revision)


def legacy_displays(rows):
    """Execute the old reader's actual lookup semantics on an in-memory copy.

Both historical and active exercise lookup and the separate story lookup are
    snapshotted: they need not agree in an old pack. Never guess missing glosses.
    """
    from .schema import columns_for
    from .export import _ddl, _value
    columns = columns_for(4)
    db = sqlite3.connect(':memory:')
    db.row_factory = sqlite3.Row
    db.create_function('formnorm', 1, form_norm)
    try:
        for table in ('sentences', 'sentence_tokens', 'senses', 'lemmas', 'cards', 'dictionary_forms'):
            db.execute(_ddl(table, columns))
            names = [k for k, _ in columns[table]]
            db.executemany(f'INSERT INTO {table} VALUES ({",".join("?" for _ in names)})',
                           [[_value(tp, r.get(k)) for k, tp in columns[table]] for r in rows[table]])
        db.execute('CREATE INDEX glossary ON dictionary_forms(sense_id,form_norm,rank,id)')
        result = {}
        for historical in (False, True):
            def active(a): return '' if historical else f' AND {a}.removed_in IS NULL'
            query = f'''SELECT t.id,
                COALESCE(c.translation_de, (SELECT df.gloss_de FROM dictionary_forms df
                 WHERE df.sense_id=t.sense_id AND df.form_norm=lower(t.surface)
                 AND s.id IS NOT NULL {active('df')} ORDER BY df.rank,df.id LIMIT 1),s.gloss_de) gloss
                FROM sentence_tokens t
                LEFT JOIN senses s ON s.id=t.sense_id {active('s')}
                LEFT JOIN cards c ON c.id=t.card_id AND c.sense_id=s.id
                 AND c.form_norm=lower(t.surface) {active('c')}'''
            for r in db.execute(query):
                result.setdefault(r['id'], {})['historical' if historical else 'active'] = r['gloss']
        query = '''SELECT t.id,l.lemma,l.pos,s.sense_key,COALESCE(s.definition_de,s.gloss_de) definition_de,
            CASE WHEN (SELECT count(*) FROM dictionary_forms df WHERE df.lang=sn.lang
             AND df.form_norm=formnorm(t.surface) AND df.sense_id=t.sense_id
             AND df.removed_in IS NULL)=1 THEN (SELECT df.gloss_de FROM dictionary_forms df WHERE df.lang=sn.lang
             AND df.form_norm=formnorm(t.surface) AND df.sense_id=t.sense_id
             AND df.removed_in IS NULL LIMIT 1) ELSE NULL END story_gloss
            FROM sentence_tokens t JOIN sentences sn ON sn.id=t.sentence_id
            LEFT JOIN lemmas l ON l.id=t.lemma_id AND l.removed_in IS NULL
            LEFT JOIN senses s ON s.id=t.sense_id AND s.lemma_id=t.lemma_id AND s.removed_in IS NULL'''
        for r in db.execute(query):
            result[r['id']].update(dict(r))
        return result
    finally:
        db.close()


def migrate_schema5(pack):
    """Return a copy; existing IDs and all legacy visible translations survive."""
    from .pack import build_rows
    if pack['release']['schema_version'] == 5:
        return copy.deepcopy(pack)
    if pack['release']['schema_version'] != 4:
        raise ValueError('Editorbasis benötigt Schema 4 oder 5; Legacy-Import bleibt separat verfügbar.')
    before = build_rows(pack)
    displays = legacy_displays(before)
    work = copy.deepcopy(pack)
    work['release']['schema_version'] = 5
    work['story_context_corrections'] = []
    for raw, row in zip(work['sentence_tokens'], before['sentence_tokens']):
        display = displays[row['id']]
        raw['context_gloss_de'] = display['historical']
        raw['context_snapshot'] = {
            'legacy': True, 'legacy_active_gloss': display['active'],
            'legacy_historical_gloss': display['historical'], 'story_gloss': display['story_gloss'],
            **{k: display.get(k) for k in CONTEXT_FIELDS},
        }
    work.setdefault('editor_history', {'story_source_snapshots': [], 'baseline_gaps': []})
    work['editor_history']['baseline_gaps']=[
        {'token_id':row['id'],'sentence_id':row['sentence_id'],'surface':row['surface'],
         'missing':[key for key in ('active','historical','story_gloss') if displays[row['id']][key] is None]}
        for row in before['sentence_tokens'] if any(c.isalpha() for c in row['surface']) and
        any(displays[row['id']][key] is None for key in ('active','historical','story_gloss'))]
    # Existing QA correction payloads are kept verbatim; the reader still consumes
    # those as legacy edges. Newly generated cumulative edges never replace them.
    after = build_rows(work)
    assert_history_preserved(before, after)
    return work


def extend_context_rows(pack, rows):
    """Only schema 5 emits the additional columns and correction table."""
    for raw, row in zip(pack['sentences'], rows['sentences']):
        row.update(root_sentence_id=raw.get('root_sentence_id'), revision_sha256=raw.get('revision_sha256'))
    for raw, row in zip(pack['sentence_tokens'], rows['sentence_tokens']):
        row.update(context_gloss_de=raw.get('context_gloss_de'), context_snapshot=raw.get('context_snapshot'))
    rows['story_context_corrections'] = copy.deepcopy(pack.get('story_context_corrections', []))


def context_payload(rows, sentence_id):
    sentence = next(s for s in rows['sentences'] if s['id'] == sentence_id)
    tokens = sorted((t for t in rows['sentence_tokens'] if t['sentence_id'] == sentence_id), key=lambda t:t['idx'])
    links = sorted((c for c in rows['card_sentences'] if c['sentence_id'] == sentence_id), key=lambda c:c['card_id'])
    fields = ('idx', 'start_pos', 'end_pos', 'surface', 'lemma_id', 'sense_id',
              'card_id', 'form_target_id', 'context_gloss_de', 'context_snapshot')
    link_fields = ('card_id', 'position', 'gap_start', 'gap_end', 'accepted', 'valid_alternatives')
    from .language_profiles import get_profile
    return {'lang': sentence['lang'], 'profile_sha256':get_profile(sentence['lang']).sha256,
            'text': sentence['text'],
            'translation_de': sentence['translation_de'],
            'tokens': [{k:t.get(k) for k in fields} for t in tokens],
            'links': [{k:c.get(k) for k in link_fields} for c in links]}


def validate_context_rows(rows):
    """Extra invariants; ordinary ownership/form checks still run unchanged."""
    sentences = {s['id']:s for s in rows['sentences']}
    for t in rows['sentence_tokens']:
        snapshot = t.get('context_snapshot')
        if not isinstance(snapshot, dict):
            raise ValueError(f'{t["id"]}: missing context snapshot')
        if snapshot.get('legacy') and sentences[t['sentence_id']].get('revision_sha256') is not None:
            raise ValueError('New context cannot claim legacy display rules')
        if any(c.isalpha() for c in t['surface']) and not snapshot.get('legacy'):
            if not isinstance(t.get('context_gloss_de'), str) or not t['context_gloss_de'].strip():
                raise ValueError(f'{t["id"]}: missing context gloss')
    for s in sentences.values():
        revision = s.get('revision_sha256')
        if revision is None:
            if s.get('root_sentence_id') is not None or s['id'] != stable_id('sentences', lang=s['lang'], text=s['text']):
                raise ValueError('legacy sentence identity changed')
        elif (len(revision) != 64 or not s.get('root_sentence_id') or
              revision != digest(context_payload(rows, s['id'])) or
              s['id'] != stable_id('sentence_revisions', lang=s['lang'],
                                  root_sentence_id=s['root_sentence_id'], revision_sha256=revision)):
            raise ValueError(f'{s["id"]}: invalid immutable context revision')
    successors = {}
    for edge in rows['story_context_corrections']:
        key = (edge['lang'], edge['source_key'], edge['previous_fingerprint'])
        if key in successors or edge['previous_fingerprint'] == edge['next_fingerprint']:
            raise ValueError('ambiguous/cyclic story correction')
        for field in ('previous_context', 'next_context'):
            if not isinstance(edge[field], dict) or not edge[field]:
                raise ValueError('missing story correction snapshot')
            validate_story_snapshot(edge[field])
        expected=correction_edge(edge['previous_context'],edge['next_context'],edge['introduced_in'],edge['reason'])
        if edge!=expected:raise ValueError('story correction payload differs from identity')
        successors[key] = edge['next_fingerprint']
    for lang, source, start in successors:
        seen = set()
        while (lang, source, start) in successors:
            if start in seen:
                raise ValueError('cyclic story corrections')
            seen.add(start)
            start = successors[(lang, source, start)]


def assert_history_preserved(before, after):
    """All old identities survive; old context display payloads are immutable."""
    for table, old_rows in before.items():
        if table == 'content_releases':
            continue
        key = 'code' if table == 'languages' else 'id'
        current = {r[key]:r for r in after[table]}
        for row in old_rows:
            if row[key] not in current:
                raise ValueError(f'HISTORY_LOSS: {table}/{row[key]}')
            if table in ('sentences', 'sentence_tokens', 'card_sentences', 'story_context_corrections'):
                ignored = {'removed_in', 'replaced_by'}
                for field, value in row.items():
                    if field not in ignored and current[row[key]].get(field) != value:
                        raise ValueError(f'HISTORY_LOSS: {table}/{row[key]}/{field}')


def history_inventory(rows, pack):
    def immutable(row):
        return {k:v for k,v in row.items() if k not in ('removed_in','replaced_by')}
    return {'format_version': 1, 'lang':pack['lang'],
            'tables': {t: {r.get('id', r.get('code')):digest(immutable(r)) for r in rs}
                       for t,rs in rows.items() if t != 'content_releases'},
            **copy.deepcopy(pack.get('editor_history', {'story_source_snapshots':[], 'baseline_gaps':[]}))}


def revise_context(pack, card_ref, spec, version):
    """Apply an already explicitly annotated context to a working copy."""
    from .pack import _build_rows
    links = [l for l in pack['card_sentences'] if l['card'] == card_ref and not l.get('removed_in')]
    if len(links) != 1:
        raise ValueError('exactly one current context required')
    old = links[0]
    sentence = next(s for s in pack['sentences'] if s['ref'] == old['sentence'])
    root = sentence.get('root_sentence_id') or sentence_identity(pack['lang'], sentence)
    temporary_ref = 'editor-revision:' + digest(spec)
    new = {'ref':temporary_ref, 'text':spec['text'], 'translation_de':spec['translation_de'],
           'origins':['deck'], 'model':None, 'qa_status':'editorial_reviewed',
           'qa_report':{'editor_revision':{'reason':spec.get('reason','Redaktionelle Korrektur')}},
           'root_sentence_id':root, 'revision_sha256':'0'*64}
    tokens = [dict(t, sentence=temporary_ref) for t in copy.deepcopy(spec['tokens'])]
    card = next(c for c in pack['cards'] if c['ref'] == card_ref)
    new_link = {'card':card_ref, 'sentence':temporary_ref, 'position':1,
                'gap_start':spec['gap']['start_pos'], 'gap_end':spec['gap']['end_pos'],
                'accepted':[card['form']], 'valid_alternatives':list(spec.get('valid_alternatives', []))}
    old['removed_in'] = version
    pack['sentences'].append(new)
    pack['sentence_tokens'].extend(tokens)
    pack['card_sentences'].append(new_link)
    provisional = _build_rows(pack)
    sid = sentence_identity(pack['lang'], new)
    new['revision_sha256'] = digest(context_payload(provisional, sid))
    sid = sentence_identity(pack['lang'], new)
    final_ref = 'context:' + sid
    existing = next((s for s in pack['sentences'][:-1] if sentence_identity(pack['lang'],s) == sid), None)
    if existing:
        pack['sentences'].remove(new)
        pack['sentence_tokens'] = [t for t in pack['sentence_tokens'] if t['sentence'] != temporary_ref]
        pack['card_sentences'].remove(new_link)
        prior = next(l for l in pack['card_sentences'] if l['card']==card_ref and l['sentence']==existing['ref'])
        prior.pop('removed_in', None); prior.pop('replaced_by', None)
        if old is prior: return
    else:
        new['ref'] = final_ref
        new_link['sentence'] = final_ref
        for t in tokens: t['sentence'] = final_ref
    rows = _build_rows(pack)
    cid = next(r['id'] for r,c in zip(rows['cards'],pack['cards']) if c['ref']==card_ref)
    old['replaced_by'] = stable_id('card_sentences', card_id=cid, sentence_id=sid)


def learning_hash(values):
    """Dart learningHash uses compact arrays, not sorted object fields."""
    import hashlib
    return hashlib.sha256(json.dumps(values,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()


def story_fingerprints(source):
    sentence=source['sentence'];token=next(t for t in sentence['tokens'] if t['index']==source['token_index'])
    function=token.get('function')
    identity=learning_hash(['learning-identity-v1',source['lang'],form_norm(token['surface']),token['sense_id']]
        if function is None else ['form-learning-identity-v1',source['lang'],form_norm(token['surface']),token['sense_id'],function])
    values=[source['story_id'],source['revision'],sentence['id'],token['index'],sentence['text'],sentence['translation'],token['start'],token['end'],identity]
    context=source.get('practice_context')
    if context:
        sn=context['sentence']
        values.append(learning_hash([sn['id'],sn['text'],sn['translation'],context['token_index'],
            *[[t['start'],t['end'],t['surface'],t.get('lemma_id'),t.get('sense_id'),t.get('gloss'),t.get('function')] for t in sn['tokens']]]))
    return {'identity_key':identity,'source_fingerprint':learning_hash(values),
            'source_key':learning_hash([source['story_id'],sentence['id'],token['index'],identity])}


def validate_story_snapshot(source):
    if not isinstance(source,dict) or any(source.get(k)!=v for k,v in story_fingerprints(source).items()):
        raise ValueError('Story snapshot fingerprint mismatch')
    for number,sentence in enumerate([source['sentence'],*([source['practice_context']['sentence']] if source.get('practice_context') else [])]):
        text=sentence['text'];encoded=text.encode('utf-16-le');cursor=0
        for index,t in enumerate(sentence['tokens']):
            if t['index']!=index or not cursor<=t['start']<t['end']<=len(encoded)//2:
                raise ValueError('Story snapshot offsets invalid')
            if encoded[t['start']*2:t['end']*2].decode('utf-16-le')!=t['surface']:
                raise ValueError('Story snapshot surface mismatch')
            if encoded[cursor*2:t['start']*2].decode('utf-16-le').strip():
                raise ValueError('Story snapshot annotation incomplete')
            if (number > 0 or not source.get('practice_context') or index == source['token_index']) and any(c.isalpha() for c in t['surface']) and not all(t.get(k) for k in ('lemma_id','lemma','pos','sense_id','sense_key','gloss','definition')):
                raise ValueError('Story snapshot meaning incomplete')
            cursor=t['end']
        if encoded[cursor*2:].decode('utf-16-le').strip():raise ValueError('Story snapshot trailing annotation missing')


def correction_edge(previous,current,version,reason):
    validate_story_snapshot(previous);validate_story_snapshot(current)
    if previous['identity_key']!=current['identity_key'] or previous['source_key']!=current['source_key'] or previous['lang']!=current['lang']:
        raise ValueError('Story correction changes learning identity or provenance')
    fields={'lang':previous['lang'],'source_key':previous['source_key'],
            'previous_fingerprint':previous['source_fingerprint'],'next_fingerprint':current['source_fingerprint']}
    return {'id':stable_id('story_context_corrections',**fields),**fields,
            'identity_key':previous['identity_key'],'previous_revision':previous['revision'],
            'next_revision':current['revision'],'previous_context':copy.deepcopy(previous),
            'next_context':copy.deepcopy(current),'introduced_in':version,'reason':reason}


def add_correction(pack,previous,current,version,reason):
    edge=correction_edge(previous,current,version,reason)
    old=next((e for e in pack['story_context_corrections'] if e['source_key']==edge['source_key'] and e['previous_fingerprint']==edge['previous_fingerprint']),None)
    if old:
        if old['next_fingerprint']!=edge['next_fingerprint']:raise ValueError('Existing story correction cannot be replaced')
        return
    pack['story_context_corrections'].append(edge)


def seed_story_history(pack,reader):
    history=pack.setdefault('editor_history',{'story_source_snapshots':[],'baseline_gaps':[]})
    catalog=history['story_source_snapshots'];known={s['source_fingerprint'] for s in catalog}
    sources=list(reader['story_source_snapshots'])
    for correction in reader['story_corrections']:
        previous,current=correction['previous'],correction['next']
        add_correction(pack,previous,current,correction['version'],'Belegte historische QA-Korrektur')
        sources.extend([previous,current])
    for source in sources:
        if source['source_fingerprint'] not in known:
            validate_story_snapshot(source);catalog.append(copy.deepcopy(source));known.add(source['source_fingerprint'])


def revise_story_context(pack,source_key,spec,version,expected):
    """Append edges for every known eligible origin release, retaining old chains."""
    from .authoring_service import clean_tokens,require
    from .pack import _build_rows
    from .language_profiles import get_profile
    catalog=pack['editor_history']['story_source_snapshots']
    sources=[s for s in catalog if s['source_key']==source_key]
    selected=next((s for s in sources if digest(s)==expected),None)
    require(selected is not None,'ENTITY_CHANGED','Storyherkunft hat sich geändert oder ist nicht belegt.',status=409)
    source_token=next(t for t in selected['sentence']['tokens'] if t['index']==selected['token_index'])
    profile=get_profile(pack['lang']);gap=spec['gap']
    profile.gap(spec['text'],gap['start_pos'],gap['end_pos'],source_token['surface'])
    errors=[f for f in profile.validate_sentence(spec['text'],source_token['surface'],gap['start_pos'],gap['end_pos']) if f.level=='error']
    require(not errors,'CONTEXT_INVALID',errors[0].message if errors else '')
    require(all(t.get('binding_status') not in ('unresolved','suggested') for t in spec['tokens']),'TOKEN_REVIEW_OPEN','Storywortbindungen ausdrücklich bestätigen.')
    tokens=clean_tokens(pack,spec);rows=_build_rows(pack)
    lemma_ids={r['ref']:row['id'] for r,row in zip(pack['lemmas'],rows['lemmas'])}
    sense_ids={r['ref']:row['id'] for r,row in zip(pack['senses'],rows['senses'])}
    def utf16(point):return len(spec['text'][:point].encode('utf-16-le'))//2
    resolved=[];target=None
    for t in tokens:
        snapshot=t['context_snapshot'];is_target=(t['start_pos'],t['end_pos'])==(gap['start_pos'],gap['end_pos'])
        if is_target:target=t['idx']
        resolved.append({'index':t['idx'],'start':utf16(t['start_pos']),'end':utf16(t['end_pos']),
            'surface':t['surface'],'card_id':None,'lemma_id':lemma_ids.get(t.get('lemma')),
            'lemma':snapshot.get('lemma'),'pos':snapshot.get('pos'),'sense_id':sense_ids.get(t.get('sense')),
            'sense_key':snapshot.get('sense_key'),'gloss':t.get('context_gloss_de'),'definition':snapshot.get('definition_de'),
            'function':source_token.get('function') if is_target else None,
            'lexical_id':source_token.get('lexical_id') if is_target else None,'context_approved':False})
    require(target is not None,'GAP_MISSING','Storylücke muss exakt einem annotierten Token entsprechen.')
    require(resolved[target]['sense_id']==source_token['sense_id'] and resolved[target]['lemma_id']==source_token['lemma_id'],
            'IDENTITY_CHANGED','Storykorrektur darf Lernbedeutung und Grundform nicht ändern.')
    content={'text':spec['text'],'translation':spec['translation_de'],'paragraph':0,'tokens':resolved}
    content['id']='context:'+digest({'lang':pack['lang'],'profile':profile.sha256,'context':content,'target':target})
    current=copy.deepcopy(selected);current['revision']=version;current['practice_context']={'sentence':content,'token_index':target}
    current.update(story_fingerprints(current));validate_story_snapshot(current)
    edges={e['previous_fingerprint'] for e in pack['story_context_corrections'] if e['source_key']==source_key}
    for source in sources:
        if source['source_fingerprint'] in edges or source['source_fingerprint']==current['source_fingerprint']:continue
        # Same practice snapshot from another release needs no correction yet,
        # but remains catalogued so a later correction can cover it exactly.
        if source.get('practice_context')==current.get('practice_context'):continue
        add_correction(pack,source,current,version,spec.get('reason','Redaktionelle Storykontextkorrektur'))
    if not any(s['source_fingerprint']==current['source_fingerprint'] for s in catalog):catalog.append(current)
    return current
