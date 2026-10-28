"""Shared, offline authoring application layer; HTTP and files are adapters.

A draft may be incomplete. Only this layer can turn it into a release, through
existing pack, ownership, grouping, linter and SQLite validators.
"""
from __future__ import annotations

import copy
import hashlib
import json
import unicodedata
from collections import defaultdict
from pathlib import Path

from .ids import form_norm, stable_id
from .form_targets import card_id
from .word_registry import digest
from .language_profiles import get_profile, canonical_text, UnsupportedLanguage
from .context_revisions import migrate_schema5, revise_context, assert_history_preserved

ROOT = Path(__file__).resolve().parents[3]
TABLES = ('lemmas','senses','cards','dictionary_forms','decks','deck_cards','deck_words',
          'word_aliases','sentences','sentence_tokens','card_sentences','stories','story_sentences',
          'lexical_targets','card_lexical_targets','form_targets','deck_practice_targets',
          'exercises','grammar_rules','audio_assets','story_context_corrections')


class AuthoringError(ValueError):
    def __init__(self, code, message, *, field=None, record_ref=None, status=422):
        super().__init__(message)
        self.code, self.message, self.field, self.record_ref, self.status = code,message,field,record_ref,status

    def finding(self):
        return {'code':self.code,'message':self.message,'severity':'error',
                'location':{'record_ref':self.record_ref,'field':self.field},'retryable':False}


def require(ok, code, message, **where):
    if not ok: raise AuthoringError(code,message,**where)


def empty_pack(lang, display_name):
    from .schema import columns_for
    registry={'format_version':1,'normalization':'NFC-lower-apostrophe-v1','words':[]}
    return {'lang':lang, **{t:[] for t in columns_for(4) if t!='content_releases'},
            'languages':[{'code':lang,'name_native':display_name,'name_de':display_name,'gloss_lang':'de'}],
            'release':{'version':'empty-'+lang,'schema_version':4,'notes':'Lokaler Entwurf ohne Lerninhalt'},
            'word_registry':{'snapshot':registry,'sha256':digest(registry)}}


def base_fingerprint(pack, raw=None, sqlite_sha256=None):
    try: profile_sha256=get_profile(pack['lang']).sha256
    except UnsupportedLanguage: profile_sha256=None
    return {'release_id':pack['release']['version'],'version':pack['release']['version'],
            'pack_bytes_sha256':hashlib.sha256(raw).hexdigest() if raw is not None else digest(pack),
            'pack_canonical_sha256':digest(pack),'sqlite_sha256':sqlite_sha256,
            'registry_sha256':pack['word_registry']['sha256'],
            'profile_sha256':profile_sha256}


def release_parent_id(base):
    # Only exact empty editorial seeds are local anchors, never published parents.
    # Do not infer this from a version prefix or alter legacy English semantics.
    if base['lang'] in ('pt-BR','nb','it','es'):
        seed=empty_pack(base['lang'],base['languages'][0]['name_de'])
        seed['languages']=base['languages']
        if base==seed:return None
    return base['release']['version']


def normalize_delivery(raw, format='json', language=None):
    """Validate transport shape only. Missing draft annotations stay missing."""
    if format!='json': raise AuthoringError('FORMAT_UNSUPPORTED','Transportadapter muss zuerst JSON liefern.')
    if isinstance(raw,(bytes,str)):
        def pairs(items):
            result={}
            for k,v in items:
                require(k not in result,'DUPLICATE_KEY','Doppeltes JSON-Feld: '+k)
                result[k]=v
            return result
        try: value=json.loads(raw, object_pairs_hook=pairs, parse_constant=lambda x: (_ for _ in ()).throw(ValueError(x)))
        except (UnicodeError,json.JSONDecodeError,ValueError) as e: raise AuthoringError('FORMAT_INVALID',str(e)) from e
    else: value=copy.deepcopy(raw)
    require(isinstance(value,dict),'FORMAT_INVALID','Die Lieferung muss ein JSON-Objekt sein.')
    require(value.get('format')=='sprachapp.editorial-content','FORMAT_UNSUPPORTED','Unbekanntes Lieferformat.')
    version=value.get('format_version')
    require(type(version) is int and version in (2,3,4),'FORMAT_UNSUPPORTED','Lieferformat 2, 3 oder 4 erforderlich.')
    if version in (2,3):
        # Original is kept for exact CLI replay. No review assertion is trusted.
        value={'format':'sprachapp.editorial-content','format_version':4,
               'delivery_id':value.get('operation_id') or digest(value),
               'lang':language or 'en','translation_lang':'de','purpose':'append',
               'base':{'pack_bytes_sha256':value.get('source_sha256'),
                       'registry_sha256':value.get('registry_sha256')},
               'context_sha256':value.get('source_sha256'),
               'expected_target_refs':[r['ref'] for r in value.get('add',{}).get('cards',[])],
               'add':value.get('add',{}),'operations':[],'provenance':[],
               'submitted_reviews':value.get('reviews',[]),'legacy_delivery':value,
               'selection':{'policy':'editor-deck-v1','batches':[]},'extensions':{}}
    allowed={'format','format_version','delivery_id','supersedes_delivery_id','lang','translation_lang',
             'purpose','base','context_sha256','expected_target_refs','selection','add','operations',
             'provenance','submitted_reviews','extensions','legacy_delivery','completeness','locations'}
    require(not set(value)-allowed,'FORMAT_UNSUPPORTED','Unbekannte Lieferfelder: '+', '.join(sorted(set(value)-allowed)))
    require(isinstance(value.get('delivery_id'),str) and value['delivery_id'].strip(),'DELIVERY_ID_MISSING','Lieferungsreferenz fehlt.')
    require(value.get('translation_lang')=='de','PROFILE_UNSUPPORTED','Übersetzungssprache muss zunächst Deutsch sein.')
    require(language is None or value.get('lang')==language,'LANGUAGE_MISMATCH','Die Lieferung gehört zu einer anderen Lernsprache.')
    refs=value.get('expected_target_refs',[])
    require(isinstance(refs,list) and all(isinstance(r,str) and r for r in refs) and len(set(refs))==len(refs),
            'TARGET_REFS_INVALID','Zielreferenzen fehlen oder sind doppelt.')
    require(len(refs)<=1500,'UPLOAD_LIMIT','Maximal 1.500 Lernziele pro Lieferung; Datei ausdrücklich aufteilen.')
    add=value.setdefault('add',{})
    require(isinstance(add,dict) and set(add)<=set(TABLES),'FORMAT_UNSUPPORTED','Unbekannte Inhaltstabelle.')
    for table,records in add.items():
        require(isinstance(records,list) and all(isinstance(r,dict) for r in records),'FORMAT_INVALID',table+' muss Datensätze enthalten.')
        for record in records:
            if 'lang' in record: require(record['lang']==value['lang'],'LANGUAGE_MISMATCH','Fremdsprachiger Datensatz.',record_ref=record.get('ref'))
    value.setdefault('operations',[]);value.setdefault('provenance',[])
    require(isinstance(value['operations'],list),'FORMAT_INVALID','Operationen müssen eine Liste sein.')
    require(not value.get('extensions'),'FORMAT_UNSUPPORTED','Unbekannte Erweiterungen werden nicht still entfernt.')
    return value


def merge_additions(base, add):
    """All dependent rows enter one working copy; final validators are shared."""
    work=copy.deepcopy(base)
    for table,records in add.items():
        target=work.setdefault(table,[])
        for record in records:
            ref=record.get('ref')
            old=next((r for r in target if ref and r.get('ref')==ref),None)
            if old is not None:
                clean={k:v for k,v in record.items() if k not in ('existing_id','expected_sha256')}
                require(clean==old,'ENTITY_CHANGED','Vorhandene Referenz hat abweichenden Inhalt.',record_ref=ref)
                continue
            clean={k:v for k,v in record.items() if k not in ('existing_id','expected_sha256')}
            if clean in target: continue
            target.append(copy.deepcopy(clean))
    return work


def target_identity(pack, card):
    senses={s.get('ref'):s for s in pack.get('senses',[])}
    lemmas={l.get('ref'):l for l in pack.get('lemmas',[])}
    sense=senses.get(card.get('sense'),{});lemma=lemmas.get(sense.get('lemma'),{})
    if not all((card.get('form'),sense.get('sense_key'),lemma.get('lemma'),lemma.get('pos'))): return None
    sid=stable_id('senses',lemma_id=stable_id('lemmas',lang=pack['lang'],lemma=lemma['lemma'],pos=lemma['pos']),sense_key=sense['sense_key'])
    return card_id(pack['lang'],card,sid)


def target_view(pack, ref):
    card=next(c for c in pack.get('cards',[]) if c.get('ref')==ref)
    links=[l for l in pack.get('card_sentences',[]) if l.get('card')==ref and not l.get('removed_in')]
    link=links[0] if links else {}
    sentence=next((s for s in pack.get('sentences',[]) if s.get('ref')==link.get('sentence')), {})
    tokens=sorted([copy.deepcopy(t) for t in pack.get('sentence_tokens',[]) if t.get('sentence')==sentence.get('ref')],key=lambda t:t.get('idx',0))
    senses={s.get('ref'):s for s in pack.get('senses',[])};lemmas={l.get('ref'):l for l in pack.get('lemmas',[])}
    dictionary={(form_norm(d.get('form') or ''),d.get('sense')):d for d in pack.get('dictionary_forms',[]) if not d.get('removed_in')}
    for token in tokens:
        sense=senses.get(token.get('sense'),{});lemma=lemmas.get(token.get('lemma'),{})
        form=dictionary.get((form_norm(token.get('surface','')),token.get('sense')), {})
        token.setdefault('context_gloss_de',form.get('gloss_de'))
        token.setdefault('binding_status','confirmed' if token.get('sense') and form.get('gloss_de') else 'unresolved')
        token['is_word']=any(c.isalpha() for c in token.get('surface',''))
        token['form_gloss_de']=form.get('gloss_de');token['sense_gloss_de']=sense.get('gloss_de')
        token['definition_de']=sense.get('definition_de');token['lemma_text']=lemma.get('lemma')
    owner=next((w for w in pack.get('deck_words',[]) if w.get('form_norm')==form_norm(card.get('form') or '') and not w.get('removed_in')), {})
    return {'ref':ref,'card':copy.deepcopy(card),'identity':target_identity(pack,card),
            'owner_deck':owner.get('deck'),'sentence_ref':sentence.get('ref'),
            'context':{'text':sentence.get('text',''),'translation_de':sentence.get('translation_de',''),
                       'tokens':tokens,'gap':{'start_pos':link.get('gap_start'),'end_pos':link.get('gap_end')},
                       'valid_alternatives':copy.deepcopy(link.get('valid_alternatives',[])),
                       'reason':'Redaktionelle Bearbeitung'},
            'expect':{'card_sha256':digest(card),'sentence_sha256':digest(sentence),'link_sha256':digest(link)}}


def preview_import(base, delivery):
    require(delivery['lang']==base['lang'],'LANGUAGE_MISMATCH','Andere Sprache als die gewählte Basis.')
    expected=delivery['expected_target_refs'];records=list(delivery['add'].get('cards',[]))
    creates=[o for o in delivery.get('operations',[]) if o.get('kind')=='create_target']
    records.extend(dict(o['payload']['card'],ref=o['target_ref']) for o in creates)
    refs=[r.get('ref') for r in records]
    require(len(refs)==len(set(refs)),'TARGET_REFS_INVALID','Doppelte Zielreferenz in der Lieferung.')
    inventory={'expected':len(expected),'parsed':len(refs),'processed':len(refs),'unresolved':0,
               'new_refs':[],'existing_refs':[],'conflicting_refs':[],'incomplete_refs':[],'chunks':[]}
    old={c['ref']:c for c in base['cards']};ids={target_identity(base,c):c['ref'] for c in base['cards']}
    work=copy.deepcopy(base)
    for t,rs in delivery['add'].items():work.setdefault(t,[]).extend(rs)
    for op in creates:
        ref=op['target_ref'];spec=op['payload']['context'];sn='preview:'+ref
        work['cards'].append(dict(op['payload']['card'],ref=ref))
        work['sentences'].append({'ref':sn,'text':spec.get('text'),'translation_de':spec.get('translation_de')})
        work['sentence_tokens'].extend(dict(t,sentence=sn) for t in spec.get('tokens',[]))
        work['card_sentences'].append({'card':ref,'sentence':sn,'position':1,'gap_start':spec.get('gap',{}).get('start_pos'),'gap_end':spec.get('gap',{}).get('end_pos'),'valid_alternatives':spec.get('valid_alternatives',[])})
    findings=[]
    for ref in expected:
        card=next((c for c in records if c.get('ref')==ref),old.get(ref))
        if card is None:
            inventory['incomplete_refs'].append(ref);continue
        clean={k:v for k,v in card.items() if k not in ('existing_id','expected_sha256')}
        identity=target_identity(work,card)
        if ref in old:
            group='existing_refs' if clean==old[ref] else 'conflicting_refs'
        elif identity and identity in ids:group='conflicting_refs'
        else:group='new_refs'
        inventory[group].append(ref)
        view=target_view(work,ref)
        missing=target_findings(work,view,linguistic=False)
        if missing:inventory['incomplete_refs'].append(ref);findings.extend(missing)
    extra=set(refs)-set(expected)
    if extra:findings.append(AuthoringError('TARGET_REFS_INVALID','Nicht deklarierte Zielzeilen: '+', '.join(sorted(extra))).finding())
    inventory['parsed']=inventory['processed']=sum(ref in refs or ref in old for ref in expected)
    inventory['unresolved']=len(set(inventory['incomplete_refs'])|set(inventory['conflicting_refs']))
    for finding in findings:
        location=finding.get('location',{});source=delivery.get('locations',{}).get(location.get('record_ref'),{})
        location.update(source)
        if source:finding['message']=f"{source.get('sheet')}, Zeile {source.get('row')}: "+finding['message']
    for i in range(0,len(expected),100):
        chunk=expected[i:i+100];inventory['chunks'].append({'number':i//100+1,'expected_refs':chunk,'state':'parsed','report_sha256':digest(chunk)})
    return {'inventory':inventory,'findings':findings,'payload_sha256':digest(delivery)}


def target_findings(pack, view, *, linguistic=True, profile=None):
    errors=[];ref=view['ref'];card=view['card'];context=view['context']
    def fail(code,message,field):errors.append(AuthoringError(code,message,field=field,record_ref=ref).finding())
    for field,val in [('form',card.get('form')),('translation_de',card.get('translation_de')),
                      ('context.text',context.get('text')),('context.translation_de',context.get('translation_de'))]:
        if not isinstance(val,str) or not val.strip():fail('FIELD_REQUIRED','Pflichtangabe fehlt.',field)
    sense=next((s for s in pack.get('senses',[]) if s.get('ref')==card.get('sense')),None)
    if not sense:fail('SENSE_MISSING','Bedeutung ausdrücklich auswählen oder anlegen.','sense')
    gap=context.get('gap') or {}
    if any(type(gap.get(k)) is not int for k in ('start_pos','end_pos')):fail('GAP_MISSING','Ziellücke auswählen.','context.gap')
    for token in context.get('tokens',[]):
        if (any(c.isalpha() for c in token.get('surface','')) if pack['lang'] in ('pt-BR','nb','it','es') else
                token.get('is_word',any(c.isalpha() for c in token.get('surface','')))):
            if not token.get('sense'):fail('AMBIGUOUS_SENSE','Bedeutung für „'+token.get('surface','')+'“ auswählen.','tokens.'+str(token.get('idx'))+'.sense')
            if not token.get('context_gloss_de'):fail('TOKEN_GLOSS_MISSING','Kontextübersetzung für „'+token.get('surface','')+'“ fehlt.','tokens.'+str(token.get('idx'))+'.context_gloss_de')
            if token.get('binding_status') not in (('confirmed',) if pack['lang'] in ('pt-BR','nb','it','es') else (None,'confirmed')):fail('TOKEN_REVIEW_OPEN','Wortbindung ausdrücklich bestätigen.','tokens.'+str(token.get('idx')))
    if context.get('text') and not context.get('tokens'):fail('TOKENS_MISSING','Tokenannotation fehlt.','context.tokens')
    if linguistic:
        try:
            profile=profile or get_profile(pack['lang'])
            if profile.manifest.get('editorial_policy'):
                if card.get('identity_function') and card['identity_function'] not in profile.manifest['allowed_functions']:
                    fail('PROFILE_FUNCTION_UNSUPPORTED','Diese Formfunktion wird vom Profil nicht unterstützt.','card')
                if not profile.manifest['allowed_functions'] and card.get('introduction_scope','ordinary')!='ordinary':
                    fail('PROFILE_FUNCTION_UNSUPPORTED','Dieses Profil unterstützt nur gewöhnliche Lernziele.','card')
                if not errors:
                    expected=profile.tokenize(context['text'],(gap['start_pos'],gap['end_pos']))
                    fields=('idx','surface','start_pos','end_pos')
                    if [{k:t.get(k) for k in fields} for t in context['tokens']] != [{k:t[k] for k in fields} for t in expected]:
                        fail('TOKENIZATION_MISMATCH','Tokenliste muss exakt dem Profil und der Ziellücke entsprechen.','context.tokens')
            if not errors:
                profile.gap(context['text'],gap['start_pos'],gap['end_pos'],card['form'])
                for f in profile.validate_sentence(context['text'],card['form'],gap['start_pos'],gap['end_pos'],card.get('cefr_band','anfaenger'),single_sentence=False):
                    errors.append({'code':f.rule,'message':f.message,'severity':f.level,'location':{'record_ref':ref,'field':'context.text'}})
        except UnsupportedLanguage as e:fail(e.code,str(e),'lang')
        except ValueError as e:fail('CONTEXT_INVALID',str(e),'context.gap')
    return errors


def clean_tokens(pack, spec):
    """Resolve only supplied senses; dictionary values are explicit source data."""
    senses={s['ref']:s for s in pack['senses']};lemmas={l['ref']:l for l in pack['lemmas']}
    dictionaries={(form_norm(d['form']),d['sense']):d for d in pack['dictionary_forms'] if not d.get('removed_in')}
    result=[]
    for token in spec['tokens']:
        row={k:copy.deepcopy(token[k]) for k in ('idx','surface','start_pos','end_pos','lemma','sense','card','form_target') if k in token}
        sense=senses.get(row.get('sense'),{});lemma=lemmas.get(row.get('lemma'),{})
        word=any(c.isalpha() for c in row['surface'])
        dictionary=dictionaries.get((form_norm(row['surface']),row.get('sense')), {})
        gloss=token.get('context_gloss_de') if 'context_gloss_de' in token else dictionary.get('gloss_de')
        require(not word or (sense and lemma and dictionary.get('gloss_de') and gloss),
                'TOKEN_GLOSS_MISSING','Vollständige Bedeutungsbindung und Form-/Kontextübersetzung erforderlich.',field='tokens.'+str(row['idx']))
        row['context_gloss_de']=gloss
        row['context_snapshot']={'lemma':lemma.get('lemma'),'pos':lemma.get('pos'),
            'sense_key':sense.get('sense_key'),'definition_de':sense.get('definition_de') or sense.get('gloss_de'),
            'function':token.get('function'),'form_label_de':token.get('form_label_de')}
        result.append(row)
    return result


def apply_operations(base, operations, profile=None):
    """Atomic working copy. No source write and no partial valid release."""
    work=migrate_schema5(base)
    profile=profile or get_profile(work['lang'])
    seen=set()
    for op in operations:
        require(op.get('op_id') and op['op_id'] not in seen,'OPERATION_ID_CONFLICT','Doppelte oder fehlende Operation.');seen.add(op['op_id'])
        require(op.get('lang')==work['lang'],'LANGUAGE_MISMATCH','Operation gehört zu einer anderen Sprache.')
        kind=op.get('kind');payload=op.get('payload',{});ref=op.get('target_ref');expect=op.get('expect',{})
        original=next((c for c in base.get('cards',[]) if c['ref']==ref),None)
        if original is not None:
            require(expect.get('card_sha256')==digest(original),'ENTITY_CHANGED','Die Aufgabe hat sich seit der Bearbeitung geändert.',record_ref=ref,status=409)
        if kind=='add_vocabulary':
            for table in ('lemmas','senses','dictionary_forms'):
                addition=payload.get(table,[])
                work=merge_additions(work,{table:addition})
        elif kind=='create_deck':
            require(expect.get('absent') is True and not any(d['ref']==ref for d in work['decks']),'ENTITY_CHANGED','Stapelreferenz bereits vorhanden.',status=409)
            work['decks'].append(copy.deepcopy(payload))
        elif kind=='create_target':
            require(expect.get('absent') is True and original is None,'ENTITY_CHANGED','Lernziel bereits vorhanden.',status=409)
            _create_target(work,ref,payload)
        elif kind=='set_solution_hint':
            require(original is not None,'TARGET_MISSING','Aufgabe fehlt.')
            require(isinstance(payload.get('translation_de'),str) and payload['translation_de'].strip(),'FIELD_REQUIRED','Lösungshinweis fehlt.')
            next(c for c in work['cards'] if c['ref']==ref)['translation_de']=payload['translation_de']
        elif kind=='revise_context':
            require(original is not None,'TARGET_MISSING','Aufgabe fehlt.')
            before=target_view(base,ref)
            require(all(expect.get(k)==before['expect'][k] for k in ('sentence_sha256','link_sha256')),'ENTITY_CHANGED','Satzbindung hat sich geändert.',status=409)
            spec=copy.deepcopy(payload)
            view={'ref':ref,'card':next(c for c in work['cards'] if c['ref']==ref),'context':spec}
            issues=[f for f in target_findings(work,view) if f['severity']=='error']
            require(not issues,'CONTEXT_INVALID',issues[0]['message'] if issues else '')
            spec['tokens']=clean_tokens(work,spec)
            revise_context(work,ref,spec,work['release']['version'])
        elif kind=='set_shared_gloss':
            _shared_gloss(work,base,op)
        elif kind=='retire_target':
            _retire_target(work,base,op)
        elif kind=='correct_story_context':
            from .context_revisions import revise_story_context
            revise_story_context(work,ref,payload,work['release']['version'],expect.get('source_sha256'))
        else:
            raise AuthoringError('OPERATION_UNSUPPORTED','Operation noch nicht definiert: '+str(kind))
    return work


def _create_target(work,ref,payload):
    card=copy.deepcopy(payload['card']);card['ref']=ref
    require(target_identity(work,card) is not None,'SENSE_MISSING','Lemma und Bedeutung fehlen.')
    cid=target_identity(work,card)
    require(not any(target_identity(work,c)==cid for c in work['cards']),'IDENTITY_CONFLICT','Diese Lernidentität besteht bereits.')
    card.setdefault('learning',{'group_id':work['lang']+':card:'+cid,'primary_card_id':cid,
                               'topic':payload.get('topic','redaktion'),'related':[],'note':'Eigenständiges redaktionelles Lernziel.'})
    owner=next((w for w in work['deck_words'] if w['form_norm']==form_norm(card['form']) and not w.get('removed_in')),None)
    deck=payload['deck_ref'];require(any(d['ref']==deck and not d.get('removed_in') for d in work['decks']),'DECK_MISSING','Stapel fehlt.')
    require(owner is None or owner['deck']==deck,'OWNER_CONFLICT','Diese Schreibweise gehört bereits zu einem anderen Stapel. Bestehenden Besitzer verwenden.')
    position=1+sum(1 for w in work['deck_words'] if w['deck']==deck and not w.get('removed_in'))
    work['cards'].append(card)
    if owner is None:
        work['deck_words'].append({'form_norm':form_norm(card['form']),'deck':deck,'primary_card':ref,'position':position})
        work['deck_cards'].append({'deck':deck,'card':ref,'position':position})
    registry=work['word_registry']['snapshot']
    if owner is None:
        registry['words'].append({'lang':work['lang'],'form_norm':form_norm(card['form']),'aliases':[],
            'owner_deck_ref':deck,'primary_card_ref':ref,'primary_card_id':cid,'position':position})
    work['word_registry']['sha256']=digest(registry)
    spec=payload['context']
    issues=[f for f in target_findings(work,{'ref':ref,'card':card,'context':spec}) if f['severity']=='error']
    if issues:
        first=issues[0]
        raise AuthoringError(first['code'],first['message'],record_ref=ref,field=first['location'].get('field'))
    tokens=clean_tokens(work,spec)
    sentence_ref='new:'+ref
    work['sentences'].append({'ref':sentence_ref,'text':spec['text'],'translation_de':spec['translation_de'],
                             'origins':['deck'],'model':None,'qa_status':'editorial_reviewed'})
    for t in tokens:
        t['sentence']=sentence_ref
        if (t['start_pos'],t['end_pos'])==(spec['gap']['start_pos'],spec['gap']['end_pos']):t['card']=ref
    work['sentence_tokens'].extend(tokens)
    work['card_sentences'].append({'card':ref,'sentence':sentence_ref,'position':1,
        'gap_start':spec['gap']['start_pos'],'gap_end':spec['gap']['end_pos'],'accepted':[card['form']],
        'valid_alternatives':spec.get('valid_alternatives',[])})
    freeze_new_context(work,sentence_ref)


def freeze_new_context(pack, sentence_ref):
    """A new sentence also uses the revision namespace, including equal texts."""
    from .pack import _build_rows
    from .context_revisions import sentence_identity,context_payload
    sentence=next(s for s in pack['sentences'] if s['ref']==sentence_ref)
    sentence['root_sentence_id']=stable_id('sentences',lang=pack['lang'],text=sentence['text'])
    sentence['revision_sha256']='0'*64
    rows=_build_rows(pack)
    sentence['revision_sha256']=digest(context_payload(rows,sentence_identity(pack['lang'],sentence)))


def freeze_new_contexts(pack, sentence_refs):
    """Freeze a batch with identical payload hashing and one row projection."""
    from .pack import _build_rows
    from .context_revisions import sentence_identity, context_payload
    from collections import defaultdict
    selected = [s for s in pack['sentences'] if s['ref'] in sentence_refs]
    for sentence in selected:
        sentence['root_sentence_id'] = stable_id('sentences', lang=pack['lang'], text=sentence['text'])
        # Distinct temporary IDs prevent equal texts with different target bindings
        # from sharing tokens while their final content hashes are computed.
        sentence['revision_sha256'] = digest({'temporary_sentence_ref': sentence['ref']})
    rows = _build_rows(pack)
    tokens, links = defaultdict(list), defaultdict(list)
    for row in rows['sentence_tokens']: tokens[row['sentence_id']].append(row)
    for row in rows['card_sentences']: links[row['sentence_id']].append(row)
    sentences = {s['id']: s for s in rows['sentences']}
    for sentence in selected:
        sid = sentence_identity(pack['lang'], sentence)
        subset = {'sentences': [sentences[sid]], 'sentence_tokens': tokens[sid], 'card_sentences': links[sid]}
        sentence['revision_sha256'] = digest(context_payload(subset, sid))


def materialize_draft(draft,base,profile=None,*,release_version=None):
    """One atomic authoring transaction, including meanings, owner reservations and contexts."""
    work=migrate_schema5(base)
    if release_version:work['release']['version']=release_version
    if draft.get('source_history'):
        from .context_revisions import seed_story_history
        seed_story_history(work,draft['source_history'])
    additions=draft.get('add',{})
    require(not additions.get('story_context_corrections'),'OPERATION_REQUIRED','Storykorrekturen müssen als geprüfte Operation erfasst werden.')
    work=merge_additions(work,additions)
    # Meanings and their new contexts form one transaction regardless of the
    # order in which the editor saved the draft's individual operations.
    for op in draft.get('operations',[]):
        if op.get('kind')=='add_vocabulary':work=merge_additions(work,op['payload'])
    old_sentences={s['ref'] for s in base['sentences']}
    old_words={w['form_norm'] for w in base['deck_words']}
    registry=work['word_registry']['snapshot']
    reservations={(w['lang'],w['form_norm']) for w in registry['words']}
    for owner in work['deck_words']:
        if owner['form_norm'] in old_words:continue
        key=work['lang'],owner['form_norm']
        require(key not in reservations,'OWNER_CONFLICT','Schreibweise ist bereits reserviert: '+owner['form_norm'])
        card=next(c for c in work['cards'] if c['ref']==owner['primary_card'])
        cid=target_identity(work,card)
        require(cid is not None,'SENSE_MISSING','Bedeutungsbindung der neuen Aufgabe fehlt.')
        registry['words'].append({'lang':work['lang'],'form_norm':owner['form_norm'],'aliases':[],
             'owner_deck_ref':owner['deck'],'primary_card_ref':card['ref'],'primary_card_id':cid,'position':owner['position']})
        reservations.add(key)
    work['word_registry']['sha256']=digest(registry)
    new_sentences={s['ref'] for s in work['sentences']} - old_sentences
    tokens=[t for t in work['sentence_tokens'] if t['sentence'] in new_sentences]
    for token in tokens:
        require(not (token.get('context_snapshot') or {}).get('legacy'),'HISTORY_FORGED','Neue Kontexte dürfen sich nicht als Altdaten ausgeben.')
        if work['lang'] in ('pt-BR','nb','it','es') and any(c.isalpha() for c in token['surface']):
            require(token.get('binding_status')=='confirmed','TOKEN_REVIEW_OPEN','Importierte Wortbindung ausdrücklich bestätigen.')
        require(token.get('binding_status') not in ('unresolved','suggested'),'TOKEN_REVIEW_OPEN','Importierte Wortbindung noch nicht bestätigt.')
    for token,new in zip(tokens,clean_tokens(work,{'tokens':tokens})):token.update(new)
    if new_sentences:freeze_new_contexts(work,new_sentences)
    return apply_operations(work,draft.get('operations',[]),profile)


def shared_gloss_impact(pack, table, ref):
    require(table in ('senses','dictionary_forms'),'FIELD_INVALID','Nur Bedeutungs- oder Formglosse wählbar.')
    row=next((r for r in pack[table] if r.get('ref')==ref),None)
    if table=='dictionary_forms' and row is None:
        row=next((r for r in pack[table] if digest(r)==ref),None)
    require(row is not None,'TARGET_MISSING','Geteilte Glosse nicht gefunden.')
    sense_ref=ref if table=='senses' else row['sense']
    refs=sorted({t['sentence'] for t in pack['sentence_tokens'] if t.get('sense')==sense_ref and
                 (table=='senses' or form_norm(t['surface'])==form_norm(row['form']))})
    return {'row':row,'sentence_refs':refs,'sha256':digest({'row':row,'sentence_refs':refs})}


def _shared_gloss(work,base,op):
    payload=op['payload'];impact=shared_gloss_impact(base,payload['table'],op['target_ref'])
    require(op['expect'].get('impact_sha256')==impact['sha256'],'ENTITY_CHANGED','Wirkungsliste hat sich geändert.',status=409)
    require(payload.get('confirmed') is True and payload.get('gloss_de'),'REVIEW_OPEN','Geteilte Änderung ausdrücklich bestätigen.')
    row=next(r for r in work[payload['table']] if r==impact['row']);row['gloss_de']=payload['gloss_de']
    # Existing contexts are frozen. Each chosen active context is a separate
    # revise_context operation; global metadata never rewrites old snapshots.


def retirement_impact(pack,ref):
    card=next(c for c in pack['cards'] if c['ref']==ref)
    members=[c['ref'] for c in pack['cards'] if c['learning']['group_id']==card['learning']['group_id']]
    dependencies={t:[r for r in pack.get(t,[]) if not r.get('removed_in') and r.get(field)==ref]
                  for t,field in [('deck_words','primary_card'),('deck_cards','card'),('form_targets','card'),('card_lexical_targets','card')]}
    sentence_refs={t['sentence'] for t in pack['sentence_tokens'] if t.get('card')==ref}
    shared=[l for l in pack['card_sentences'] if l['sentence'] in sentence_refs and l['card']!=ref and not l.get('removed_in')]
    stories=[l for l in pack['story_sentences'] if l['sentence'] in sentence_refs and not l.get('removed_in')]
    result={'members':members,'dependencies':dependencies,'shared_contexts':shared,'story_contexts':stories}
    return {**result,'sha256':digest(result)}


def _retire_target(work,base,op):
    ref=op['target_ref'];impact=retirement_impact(base,ref);payload=op['payload']
    require(op['expect'].get('impact_sha256')==impact['sha256'],'ENTITY_CHANGED','Rückstellungsfolgen haben sich geändert.',status=409)
    require(payload.get('confirmed') is True,'REVIEW_OPEN','Rückstellung bestätigen.')
    require(len(impact['members'])==1,'RETIREMENT_DECISION_REQUIRED','Lerngruppe hat weitere Mitglieder: zuerst ausdrücklich gültigen Gruppenkopf festlegen.')
    require(not impact['shared_contexts'] and not impact['story_contexts'],'RETIREMENT_DECISION_REQUIRED','Andere aktive Aufgaben oder Stories verwenden diese Bindung: zuerst deren Tokenbindungen korrigieren.')
    version=work['release']['version']
    next(c for c in work['cards'] if c['ref']==ref)['removed_in']=version
    retired_forms={r['ref'] for r in work.get('form_targets',[]) if r['card']==ref}
    for table,field in [('deck_words','primary_card'),('deck_cards','card'),('form_targets','card'),('card_lexical_targets','card'),('dictionary_forms','card'),('card_sentences','card')]:
        for row in work.get(table,[]):
            if row.get(field)==ref: row['removed_in']=version
    for row in work.get('deck_practice_targets',[]):
        if row['form_target'] in retired_forms:row['removed_in']=version
    refs={t['sentence'] for t in work['sentence_tokens'] if t.get('card')==ref}
    for row in work['sentences']:
        if row['ref'] in refs:row['removed_in']=version
    for row in work['sentence_tokens']:
        if row['sentence'] in refs:row['removed_in']=version
    for alias in work['word_aliases']:
        if any(w['form_norm']==alias['word'] and w.get('removed_in') for w in work['deck_words']):alias['removed_in']=version
    # Reservation is retained. Display positions of remaining primary places
    # are recomputed, their identities and immutable registry history stay put.
    for deck in work['decks']:
        words=sorted([w for w in work['deck_words'] if w['deck']==deck['ref'] and not w.get('removed_in')],key=lambda w:w['position'])
        for i,w in enumerate(words,1):
            w['position']=i
            for dc in work['deck_cards']:
                if dc['deck']==deck['ref'] and dc['card']==w['primary_card'] and not dc.get('removed_in'):dc['position']=i


def validate_draft(draft, base, profile=None):
    from .pack import build_rows
    findings=[];working=None
    require(draft['lang']==base['lang'],'LANGUAGE_MISMATCH','Entwurf und Basis haben verschiedene Sprachen.')
    if draft['base'].get('pack_canonical_sha256')!=digest(base):
        findings.append(AuthoringError('BASE_CHANGED','Die Inhaltsbasis hat sich geändert.',status=409).finding())
    try:
        profile=profile or get_profile(draft['lang'])
        working=materialize_draft(draft,base,profile)
        if profile.manifest.get('editorial_policy'):
            require(all(d.get('practice_kind','ordinary') in profile.manifest['practice_kinds'] for d in working['decks']) and
                    all(f['function'] in profile.manifest['allowed_functions'] for f in working.get('form_targets',[])),
                    'PROFILE_FUNCTION_UNSUPPORTED','Stapelart oder Formfunktion wird vom Sprachprofil nicht unterstützt.')
        for card in working['cards']:
            if not card.get('removed_in'):
                view=target_view(working,card['ref'])
                # Only new/edited contexts get editorial linguistic checks;
                # legacy provenance is not silently re-approved.
                if card['ref'] in draft.get('target_refs',[]): findings.extend(target_findings(working,view,profile=profile))
        before=build_rows(base);after=build_rows(working)
        assert_history_preserved(before,after)
    except (AuthoringError,UnsupportedLanguage,ValueError,KeyError,TypeError) as e:
        findings.append(e.finding() if isinstance(e,AuthoringError) else AuthoringError(
            getattr(e,'code','CONTENT_INVALID'),str(e)).finding())
    coverage=draft.get('import_inventory',{})
    if coverage and (coverage.get('processed')!=coverage.get('expected') or coverage.get('conflicting_refs')):
        findings.append(AuthoringError('INCOMPLETE_BATCH','Die Lieferung ist noch nicht vollständig und konfliktfrei verarbeitet.').finding())
    review_hash=draft_content_hash(draft)
    approved=any(r.get('payload_sha256')==review_hash and r.get('decision')=='approved' and
        (draft['lang'] not in ('pt-BR','nb','it','es') or (r.get('profile_sha256')==profile.sha256 and
         r.get('editorial_policy')==profile.manifest['editorial_policy'] and
         (profile.manifest['editorial_policy']!='ai-editorial-reviewed-v1' or
          (r.get('human_review') is False and r.get('user_requested_private_device_test') is True and
           isinstance(r.get('reviewer'),str) and bool(r['reviewer'].strip()))))) for r in draft.get('reviews',[]))
    result={'draft_revision':draft['revision'],'base_sha256':digest(base),'validator_version':'editor-1',
            'technical':'unsupported' if any(f['code']=='PROFILE_UNSUPPORTED' for f in findings) else
                        'invalid' if any(f['severity']=='error' for f in findings) else 'valid',
            'editorial':'approved' if approved else 'open','findings':findings,'coverage':coverage,
            'content_sha256':review_hash,'changed_refs':changed_refs(draft)}
    result['sha256']=digest(result)
    return result


def changed_refs(draft):
    """Records this draft actually edits or adds; the remaining target_refs are
    only the selected scope and keep their base provenance and approvals."""
    refs=[op.get('target_ref') for op in draft.get('operations',[])]
    refs+=[c.get('ref') for c in draft.get('add',{}).get('cards',[])]
    return sorted({r for r in refs if isinstance(r,str) and r})


def draft_content_hash(draft):
    return digest({k:draft.get(k) for k in ('lang','translation_lang','base','add','operations','target_refs','import_inventory','source_history')})


def run_dart(arguments):
    """Fixed executable and entry point; never a browser-supplied command line."""
    import shutil
    import subprocess
    executable=shutil.which('dart')
    require(executable is not None,'DART_UNAVAILABLE','Dart ist nicht im lokalen PATH verfügbar.')
    result=subprocess.run([executable,'run',str(ROOT/'tool/editor_content_pack.dart'),*arguments],
                          cwd=ROOT,capture_output=True,text=True,shell=False)
    require(result.returncode==0,'DART_READER_FAILED','Dart-Readerprüfung fehlgeschlagen: '+result.stderr[-3000:])
    return result.stdout


def sqlite_readback(path,rows):
    import sqlite3
    from .schema import columns_for,primary_key
    from .export import _value
    columns=columns_for(5)
    with sqlite3.connect('file:'+Path(path).as_posix()+'?mode=ro',uri=True) as db:
        require(db.execute('PRAGMA integrity_check').fetchone()[0]=='ok','SQLITE_INVALID','SQLite-Integrität fehlgeschlagen.')
        names={r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")}
        require(names==set(columns),'SQLITE_TABLES','SQLite enthält nicht genau die 23 Schema-5-Tabellen.')
        for table,fields in columns.items():
            actual_columns=[r[1] for r in db.execute(f'PRAGMA table_info("{table}")')]
            require(actual_columns==[n for n,_ in fields],'SQLITE_COLUMNS','Spalten weichen ab: '+table)
            actual=list(db.execute(f'SELECT * FROM "{table}" ORDER BY "{primary_key(table)}"'))
            expected=[tuple(_value(tp,r.get(n)) for n,tp in fields) for r in sorted(rows[table],key=lambda r:r[primary_key(table)])]
            require(actual==expected,'SQLITE_READBACK','Zeileninhalt weicht ab: '+table)
    return {t:len(rs) for t,rs in rows.items()}


def build_release(draft,base,directory,*,version,expected_validation,progress):
    """Validate, export and inspect an entire immutable release; no asset writes."""
    progress.progress('Entwurf und lokale Freigabe erneut prüfen …')
    validation=validate_draft(draft,base)
    # Saving the validation/review increments the draft revision, not its content.
    prior=draft.get('validation') or {}
    require(prior.get('sha256')==expected_validation,'REVIEW_STALE','Prüfbericht wurde seit Auswahl ersetzt.',status=409)
    require(validation['technical']=='valid' and validation['editorial']=='approved',
            'RELEASE_BLOCKED','Technische Prüfung und lokale redaktionelle Freigabe sind erforderlich.')
    require(prior.get('content_sha256')==validation['content_sha256'],'REVIEW_STALE','Entwurfsinhalt hat sich geändert.',status=409)
    return _build_verified_bundle(draft,base,directory,version=version,validation=validation,progress=progress)


def _build_verified_bundle(draft,base,directory,*,version,validation,progress,adoption=None):
    """Shared mechanics; callers must enforce their distinct admission contract."""
    from .pack import build_rows
    from .export import export_sqlite
    from .context_revisions import history_inventory
    from .editor.store import atomic_json,read_json,utc_now
    directory=Path(directory)
    # Materialize the exact old reader first. This is the authority for legacy
    # correction edges, not a delivery's self-reported history.
    progress.progress('Bisherige Readeransichten und Storyherkünfte erfassen …')
    export_sqlite(base,directory/'baseline.sqlite')
    run_dart(['--from',str(directory/'baseline.sqlite'),'--out',str(directory/'baseline-reader.json'),'--lang',base['lang']])
    baseline_reader=read_json(directory/'baseline-reader.json')
    if draft.get('source_history'):
        require(digest(draft['source_history'])==digest(baseline_reader),'BASE_CHANGED','Storyherkunft stimmt nicht mehr mit dem Reader überein.',status=409)
    enriched=copy.deepcopy(draft);enriched['source_history']=baseline_reader
    old_version=base['release']['version']
    work=materialize_draft(enriched,base,release_version=version)
    # Lifecycle stamps introduced by this draft refer to this new release.
    for table in TABLES:
        originals={digest(r) for r in base.get(table,[])}
        for row in work.get(table,[]):
            if row.get('removed_in')==old_version and digest(row) not in originals:row['removed_in']=version
    work['release']['notes']=('INTERNES TEST-PACK · Bestandsübernahme ohne neue Sprachprüfung'
                            if adoption else 'INTERNES TEST-PACK · Lokaler redaktioneller Export')
    work['release']['created_at']=utc_now()
    if adoption:
        from .baseline_adoption import anchor
        work['release']['created_at']=anchor()['converted_created_at']
    before=build_rows(base);rows=build_rows(work);assert_history_preserved(before,rows)
    progress.progress('Alle 23 Tabellen exportieren und vollständig zurücklesen …')
    export_sqlite(work,directory/'content.sqlite')
    counts=sqlite_readback(directory/'content.sqlite',rows)
    atomic_json(directory/'finalization_report.json',{'status':'ok','internal_test_pack':True,'sqlite_counts':counts})
    progress.progress('Echten Dart-Reader und historische Ansichten prüfen …')
    output=run_dart(['--from',str(directory/'content.sqlite'),'--out',str(directory/'reader_report.json'),'--lang',work['lang']])
    reader=read_json(directory/'reader_report.json')
    old_contexts={(r['card_id'],r['sentence_id']):r for r in baseline_reader['historical']}
    new_contexts={(r['card_id'],r['sentence_id']):r for r in reader['historical']}
    require(all(new_contexts.get(key)==value for key,value in old_contexts.items()),'HISTORY_LOSS','Historische Dart-Readeranzeige wurde verändert.')
    require(reader['story_display']==baseline_reader['story_display'],'HISTORY_LOSS','Bisherige Storyanzeige wurde verändert.')
    if adoption:
        require(reader['current']==baseline_reader['current'],'ADOPTION_READER_CHANGED',
                'Aktive Readeransichten weichen vom übernommenen Bestand ab.')
    # Source snapshots are version-specific and append-only, even if texts match.
    history=work.setdefault('editor_history',{'story_source_snapshots':[],'baseline_gaps':[]})
    known={r['source_fingerprint'] for r in history['story_source_snapshots']}
    for source in reader['story_source_snapshots']:
        if source['source_fingerprint'] not in known:history['story_source_snapshots'].append(source);known.add(source['source_fingerprint'])
    if adoption:
        from .baseline_adoption import verify_converted
        verify_converted(work)
    inventory=history_inventory(rows,work)
    (directory/'baseline.sqlite').unlink();(directory/'baseline-reader.json').unlink()
    atomic_json(directory/'pack.json',work);atomic_json(directory/'registry.json',work['word_registry']['snapshot'])
    atomic_json(directory/'history_inventory.json',inventory)
    atomic_json(directory/'editorial_reviews.json',draft['reviews'])
    atomic_json(directory/'provenance.json',draft.get('provenance',[]))
    sqlite_file=directory/'content.sqlite'
    manifest={'format':2,'lang':work['lang'],'translation_lang':'de','version':version,'schema_version':5,
        'profile_id':get_profile(work['lang']).id,'profile_sha256':get_profile(work['lang']).sha256,
        'sha256':hashlib.sha256(sqlite_file.read_bytes()).hexdigest(),'size_bytes':sqlite_file.stat().st_size,
        'pack_json_sha256':hashlib.sha256((directory/'pack.json').read_bytes()).hexdigest(),
        'registry_sha256':work['word_registry']['sha256'],'history_inventory_sha256':digest(inventory),
        'editorial_reviews_sha256':digest(draft['reviews']),'internal_test_pack':True,
        'parent_release_id':release_parent_id(base),'required_features':['immutable-contexts-v1'],
        'min_reader_version':5,'local_only':True}
    if adoption:
        manifest.update(publication_kind=adoption['kind'],adoption_sha256=digest(adoption),parent_release_id=None)
    atomic_json(directory/'content.manifest.json',manifest)
    atomic_json(directory/'finalization_report.json',{'status':'ok','internal_test_pack':True,
        'sqlite_counts':counts,'validation':validation,'reader_output':output.strip(),
        'history_superset':True,'baseline_gaps':history['baseline_gaps'],
        **({'adoption_sha256':digest(adoption)} if adoption else {})})
    progress.check_cancelled()
    return {'pack':work,'manifest':manifest,'counts':counts}


def roundtrip_records(base, delivery):
    """Hash-bound dependency closure. All mutable rows stay in the shared core."""
    result=copy.deepcopy(delivery);selected=set(delivery['expected_target_refs'])
    sentences={l['sentence'] for l in base['card_sentences'] if l['card'] in selected and not l.get('removed_in')}
    tokens=[t for t in base['sentence_tokens'] if t['sentence'] in sentences]
    senses={t.get('sense') for t in tokens}|{c['sense'] for c in base['cards'] if c['ref'] in selected}
    lemmas={s['lemma'] for s in base['senses'] if s['ref'] in senses}
    decks={r['deck'] for r in base['deck_cards'] if r['card'] in selected}
    rows={'cards':[r for r in base['cards'] if r['ref'] in selected],
          'sentences':[r for r in base['sentences'] if r['ref'] in sentences],
          'sentence_tokens':tokens,'card_sentences':[r for r in base['card_sentences'] if r['card'] in selected and r['sentence'] in sentences and not r.get('removed_in')],
          'senses':[r for r in base['senses'] if r['ref'] in senses],
          'lemmas':[r for r in base['lemmas'] if r['ref'] in lemmas],
          'dictionary_forms':[r for r in base['dictionary_forms'] if r['sense'] in senses],
          'decks':[r for r in base['decks'] if r['ref'] in decks]}
    for table in ('deck_cards','deck_words','word_aliases','lexical_targets','card_lexical_targets','form_targets','deck_practice_targets'):
        # Complete hash-bound bindings are cheap and allow exact base resolution.
        rows[table]=base.get(table,[])
    for table,records in rows.items():
        for record in records:
            item=copy.deepcopy(record);item['existing_id']=digest(record);item['expected_sha256']=digest(record)
            result['add'].setdefault(table,[]).append(item)
    # Represent current ordinary edits in visible cells as well as operations.
    for op in delivery['operations']:
        ref=op.get('target_ref');kind=op['kind'];payload=op['payload']
        if ref not in selected:continue
        if kind=='set_solution_hint':
            next(r for r in result['add']['cards'] if r['ref']==ref)['translation_de']=payload['translation_de']
        if kind=='revise_context':
            link=next(r for r in result['add']['card_sentences'] if r['card']==ref)
            sentence=next(r for r in result['add']['sentences'] if r['ref']==link['sentence'])
            # A shared sentence cannot carry two target-specific variants in one
            # row. The complete operation remains authoritative in this case.
            if sum(r['sentence']==link['sentence'] for r in result['add']['card_sentences'])>1:continue
            sentence.update(text=payload['text'],translation_de=payload['translation_de'])
            link.update(gap_start=payload['gap']['start_pos'],gap_end=payload['gap']['end_pos'],valid_alternatives=payload.get('valid_alternatives',[]))
            existing=[t for t in result['add']['sentence_tokens'] if t['sentence']==link['sentence']]
            for old,new in zip(existing,payload['tokens']):
                if len(existing)==len(payload['tokens']):old.update({k:v for k,v in new.items() if k!='sentence'})
    return result


def resolve_roundtrip(base, delivery):
    """Convert edited base rows to guarded operations; never overwrite history."""
    result=copy.deepcopy(delivery);bound={};changed={};ops=result['operations']
    for table,records in list(result['add'].items()):
        originals={digest(r):r for r in base.get(table,[])};remaining=[]
        for record in records:
            if 'existing_id' not in record:remaining.append(record);continue
            original=originals.get(record['existing_id'])
            require(original is not None and record.get('expected_sha256')==digest(original),'ENTITY_CHANGED','Roundtrip-Basisobjekt stimmt nicht mehr überein.',record_ref=record.get('ref'),status=409)
            clean={k:v for k,v in record.items() if k not in ('existing_id','expected_sha256')}
            bound.setdefault(table,[]).append(clean)
            if clean!=original:changed.setdefault(table,[]).append((original,clean))
        result['add'][table]=remaining
    def put(kind,ref,payload,expect):
        old=next((o for o in ops if o['kind']==kind and o.get('target_ref')==ref),None)
        value={'op_id':old['op_id'] if old else 'roundtrip:'+digest([kind,ref,payload]),'kind':kind,'lang':base['lang'],'target_ref':ref,'expect':expect,'payload':payload}
        if old:ops[ops.index(old)]=value
        else:ops.append(value)
    context_sentences=set()
    for table,changes in changed.items():
        for original,clean in changes:
            if table=='cards':
                require({k:v for k,v in clean.items() if k!='translation_de'}=={k:v for k,v in original.items() if k!='translation_de'},'IDENTITY_CHANGED','Identität nicht überschreiben: neue Aufgabe anlegen und bisherige gesondert zurückstellen.',record_ref=original['ref'])
                put('set_solution_hint',original['ref'],{'translation_de':clean['translation_de']},target_view(base,original['ref'])['expect'])
            elif table in ('sentences','sentence_tokens','card_sentences'):
                context_sentences.add(original['ref'] if table=='sentences' else original['sentence'])
            elif table in ('senses','dictionary_forms'):
                require(False,'SHARED_REVIEW_REQUIRED','Geteilte Änderungen im Browser über die Wirkungsliste bestätigen.',record_ref=original.get('ref'))
            else:require(False,'IDENTITY_CHANGED','Hashgebundene Bestandsbindung wurde verändert.',record_ref=original.get('ref'))
    for sn in context_sentences:
        sentence=next(s for s in bound.get('sentences',[]) if s['ref']==sn)
        tokens=[t for t in bound.get('sentence_tokens',[]) if t['sentence']==sn]
        # A pure translation edit retains exact, previously bound token displays.
        baseline_tokens={t['idx']:t for t in target_view(base,next(l['card'] for l in bound['card_sentences'] if l['sentence']==sn))['context']['tokens']}
        tokens=[{**baseline_tokens.get(t['idx'],{}),**t} for t in tokens]
        old_sentence=next(s for s in base['sentences'] if s['ref']==sn)
        for link in bound.get('card_sentences',[]):
            if link['sentence']!=sn:continue
            ref=link['card'];view=target_view(base,ref)
            # Text edits cannot inherit confirmation of old offsets/bindings.
            if sentence['text']!=old_sentence['text']:
                for t in tokens:t['binding_status']='unresolved'
            payload={'text':sentence['text'],'translation_de':sentence.get('translation_de'),
                     'tokens':copy.deepcopy(tokens),'gap':{'start_pos':link.get('gap_start'),'end_pos':link.get('gap_end')},
                     'valid_alternatives':link.get('valid_alternatives',[]),'reason':'Redaktioneller Roundtrip'}
            put('revise_context',ref,payload,view['expect'])
    return result
