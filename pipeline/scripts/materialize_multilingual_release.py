"""Materialize reviewed multilingual corpora in a new isolated release workspace.

Reads the editor's immutable base, never its mutable drafts. Annotations are
required for every word token. The regular validator, immutable-history checks,
SQLite readback and real Dart reader remain mandatory before installing assets.
"""
from __future__ import annotations

import argparse
import copy
from collections import Counter, defaultdict
import hashlib
import json
import re
import unicodedata
from pathlib import Path
import shutil
import uuid

from sprachpipe import authoring_service as author
from sprachpipe.editor.store import default_directory, atomic_json, utc_now
from sprachpipe.editor.publisher import FILES
from sprachpipe.ids import form_norm
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest
from build_multilingual_deck_drafts import CORPUS, ROOT, NAMES, corpus, build, identifier


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def load_base(lang, path=None):
    if path:
        base=read(path)
    else:
        store=default_directory();head=store/'heads'/(lang+'.json')
        if head.exists():
            fingerprint=read(head)
            base=read(store/'bases'/(fingerprint['pack_canonical_sha256']+'.json'))
            assert digest(base)==fingerprint['pack_canonical_sha256'], 'Editor base hash changed'
        else:
            base=author.empty_pack(lang,NAMES[lang][0])
            base['languages'][0]['name_native']=NAMES[lang][1]
    assert base['lang']==lang
    return base



def annotation_overlay(lang, records, annotation_root):
    """Bind explicit AI corrections to immutable original batch response tokens."""
    root=Path(annotation_root);path=root/('review-corrections-'+lang+'.json')
    legacy=root/'review-corrections.json'
    if lang=='pt-BR' and legacy.exists():
        assert not path.exists(), 'Both per-language and legacy PT correction overlays exist'
        path=legacy
    if not path.exists():return {},None
    overlay=read(path)
    assert overlay.get('format')==1 and overlay.get('human_review') is False
    assert isinstance(overlay.get('reviewer'),str) and overlay['reviewer'].strip()
    slugs={deck['slug'] for deck,_,_ in records}
    selected=[c for c in overlay['corrections'] if c['lang']==lang and c['slug'] in slugs]
    if not selected:return {},None
    wanted={(c['input_sha256'],c['id']) for c in selected};originals={};sources={}
    for source in sorted((root/'_batches'/lang).glob('*.json')):
        response=read(source)['response']
        for row in response['items']:
            key=(response['input_sha256'],row['id'])
            if key in wanted:
                assert key not in originals, ('duplicate batch binding',key)
                originals[key]=row;sources[str(source.relative_to(root))]=sha(source)
    assert set(originals)==wanted, 'Missing original review batch binding'
    fields={'lemma','pos','gloss_de','context_gloss_de'};corrections={}
    for c in selected:
        assert c['id'].startswith(c['slug']+':') and isinstance(c['reason'],str) and c['reason'].strip()
        assert set(c['before'])==fields and set(c['after'])==fields
        assert all(isinstance(v,str) and v.strip() and not any(ord(ch)<32 for ch in v) for v in c['after'].values())
        assert c['after']['pos'] in {'ADJ','ADP','ADV','AUX','CCONJ','DET','INTJ','NOUN','NUM','PART','PRON','PROPN','SCONJ','VERB'}
        original=originals[(c['input_sha256'],c['id'])]
        tokens=[t for t in original['tokens'] if t['idx']==c['idx']]
        assert len(tokens)==1 and tokens[0]['surface']==c['surface']
        assert {k:tokens[0][k] for k in fields}==c['before'], ('source before mismatch',c['id'],c['idx'])
        key=(c['id'],c['idx']);assert key not in corrections, ('duplicate correction',key)
        corrections[key]=c
    return corrections,{'kind':'ai_token_review_overlay','source_file':str(path),'sha256':sha(path),
        'reviewer':overlay['reviewer'],'human_review':False,'correction_count':len(selected),'batch_sources':sources}



def sentence_translation_overlay(lang, records, annotation_root):
    """Review German sentence edits without rewriting provider inputs or sources."""
    path=Path(annotation_root)/('sentence-translation-corrections-'+lang+'.json')
    if not path.exists():return {},None
    overlay=read(path)
    assert overlay.get('format')==1 and overlay.get('human_review') is False
    assert isinstance(overlay.get('reviewer'),str) and overlay['reviewer'].strip()
    sources={deck['slug']:(rows,source_sha) for deck,rows,source_sha in records}
    corrections={}
    for c in overlay['corrections']:
        assert c['lang']==lang, 'Wrong sentence correction language'
        if c['slug'] not in sources:continue
        rows,source_sha=sources[c['slug']]
        assert c['source_file']==lang+'/'+c['slug']+'.json'
        assert re.fullmatch('[0-9a-f]{64}',c['source_sha256']) and c['source_sha256']==source_sha, 'Sentence correction source hash changed'
        prefix=c['slug']+':'
        assert c['id'].startswith(prefix) and c['id'][len(prefix):].isdigit()
        index=int(c['id'][len(prefix):]);assert c['id']==prefix+str(index) and index<len(rows)
        assert rows[index]['translation_de']==c['before'], 'Sentence correction before mismatch'
        value=c['after']
        assert isinstance(value,str) and value==unicodedata.normalize('NFC',value).strip()
        assert re.fullmatch(r'[^.!?\n]+[.!?]',value), 'Sentence correction must be one standalone sentence'
        assert not any(ch==';' or unicodedata.category(ch)=='Pd' or ch in '\u00ad\u2212' or ord(ch)<32 for ch in value), 'Sentence correction contains forbidden punctuation'
        assert isinstance(c['reason'],str) and c['reason'].strip()
        assert c['id'] not in corrections, 'Duplicate sentence correction'
        corrections[c['id']]=c
    if not corrections:return {},None
    return corrections,{'kind':'ai_sentence_translation_overlay','source_file':str(path),
        'sha256':sha(path),'reviewer':overlay['reviewer'],'human_review':False,
        'correction_count':len(corrections),'corpus_sources':{c['source_file']:c['source_sha256'] for c in corrections.values()}}


def target_gloss_overlay(lang, records, annotation_root, field='gloss_de'):
    """Bind reviewed target gloss or POS edits to the unchanged source."""
    assert field in ('gloss_de','pos')
    kind='gloss' if field=='gloss_de' else 'pos'
    path=Path(annotation_root)/('target-'+kind+'-corrections-'+lang+'.json')
    if not path.exists():return {},None
    overlay=read(path)
    assert overlay.get('format')==1 and overlay.get('human_review') is False
    assert isinstance(overlay.get('reviewer'),str) and overlay['reviewer'].strip()
    sources={deck['slug']:(rows,source_sha) for deck,rows,source_sha in records}
    corrections={};fields={'form','lemma','pos','gloss_de'}
    for c in overlay['corrections']:
        assert c['lang']==lang, 'Wrong target gloss correction language'
        assert c['slug'] in sources, 'Unknown target gloss correction deck'
        rows,source_sha=sources[c['slug']]
        assert c['source_file']==lang+'/'+c['slug']+'.json'
        assert re.fullmatch('[0-9a-f]{64}',c['source_sha256']) and c['source_sha256']==source_sha, 'Target gloss source hash changed'
        prefix=c['slug']+':'
        assert c['id'].startswith(prefix) and c['id'][len(prefix):].isdigit()
        index=int(c['id'][len(prefix):]);assert c['id']==prefix+str(index) and index<len(rows)
        assert set(c['before'])==fields and c['before']=={k:rows[index][k] for k in fields}, 'Target gloss before mismatch'
        value=c['after']
        assert isinstance(value,str) and value and value==unicodedata.normalize('NFC',value).strip()
        assert not any(ord(ch)<32 for ch in value), 'Target gloss contains control characters'
        if field=='pos':
            assert value in {'ADJ','ADP','ADV','AUX','CCONJ','DET','INTJ','NOUN','NUM','PART','PRON','PROPN','SCONJ','VERB'}, 'Invalid target POS'
        assert value!=c['before'][field], 'Target correction is a no-op'
        assert isinstance(c['reason'],str) and c['reason'].strip()
        assert c['id'] not in corrections, 'Duplicate target gloss correction'
        corrections[c['id']]=c
    if not corrections:return {},None
    return corrections,{'kind':'ai_target_'+kind+'_overlay','source_file':str(path),
        'sha256':sha(path),'reviewer':overlay['reviewer'],'human_review':False,
        'correction_count':len(corrections),'corpus_sources':{c['source_file']:c['source_sha256'] for c in corrections.values()}}


def number_token_overlay(lang, records, annotation_root):
    """Read explicitly reviewed numbers omitted by the provider word filter."""
    path=Path(annotation_root)/('reviewed-number-tokens-'+lang+'.json')
    if not path.exists():return {},None
    overlay=read(path)
    assert overlay.get('format')==1 and overlay.get('human_review') is False
    assert isinstance(overlay.get('reviewer'),str) and overlay['reviewer'].strip()
    sources={d['slug']:(rows,h) for d,rows,h in records};profile=get_profile(lang);tokens={}
    for c in overlay['tokens']:
        assert c['lang']==lang and c['slug'] in sources
        rows,h=sources[c['slug']];prefix=c['slug']+':'
        assert c['source_file']==lang+'/'+c['slug']+'.json'
        assert re.fullmatch('[0-9a-f]{64}',c['source_sha256']) and c['source_sha256']==h, 'Number token source hash changed'
        assert c['id'].startswith(prefix) and c['id'][len(prefix):].isdigit()
        i=int(c['id'][len(prefix):]);assert c['id']==prefix+str(i) and i<len(rows)
        assert type(c['before'].get('idx')) is int
        canonical=[t for t in profile.tokenize(rows[i]['sentence'],rows[i]['_gap']) if t['idx']==c['before']['idx']]
        assert len(canonical)==1 and canonical[0]==c['before'], 'Number token boundary mismatch'
        raw=canonical[0]
        assert not raw['is_word'] and raw['surface'].isdecimal()
        assert (raw['start_pos'],raw['end_pos'])!=tuple(rows[i]['_gap'])
        after=c['after'];assert set(after)=={'lemma','pos','gloss_de','context_gloss_de'}
        assert after['lemma']==raw['surface'] and after['pos']=='NUM'
        assert all(isinstance(v,str) and v and v==unicodedata.normalize('NFC',v).strip() and not any(ord(ch)<32 for ch in v) for v in after.values())
        assert isinstance(c['reason'],str) and c['reason'].strip()
        key=(c['id'],raw['idx']);assert key not in tokens, 'Duplicate reviewed number token'
        tokens[key]=c
    if not tokens:return {},None
    return tokens,{'kind':'ai_editorial_number_token_review','source_file':str(path),'sha256':sha(path),
        'reviewer':overlay['reviewer'],'human_review':False,'token_count':len(tokens),
        'provider_annotated':False,'corpus_sources':{c['source_file']:c['source_sha256'] for c in tokens.values()}}


def prepare(lang, base, records, annotation_root):
    """Build complete additions without changing source rows or the editor store."""
    target_corrections,target_provenance=target_gloss_overlay(lang,records,annotation_root)
    target_pos_corrections,target_pos_provenance=target_gloss_overlay(lang,records,annotation_root,field='pos')
    number_tokens,number_provenance=number_token_overlay(lang,records,annotation_root)
    applied_numbers=set()
    if target_corrections or target_pos_corrections:
        records=copy.deepcopy(records)
        for deck,rows,_ in records:
            for i,row in enumerate(rows):
                correction=target_corrections.get(deck['slug']+':'+str(i))
                if correction:row['gloss_de']=correction['after']
                pos_correction=target_pos_corrections.get(deck['slug']+':'+str(i))
                if pos_correction:row['pos']=pos_correction['after']
    deliveries=build(lang,base,records)
    draft={'lang':lang,'translation_lang':'de','revision':0,'state':'draft',
        'draft_id':str(uuid.uuid4()),'base':author.base_fingerprint(base),'add':{},
        'operations':[],'target_refs':[],'reviews':[],'provenance':[]}
    if target_provenance:draft['provenance'].append(target_provenance)
    if target_pos_provenance:draft['provenance'].append(target_pos_provenance)
    if number_provenance:draft['provenance'].append(number_provenance)
    for _,delivery in deliveries:
        for table,rows in delivery['add'].items():draft['add'].setdefault(table,[]).extend(rows)
        draft['operations'].extend(delivery['operations'])
        draft['target_refs'].extend(delivery['expected_target_refs'])
        draft['provenance'].extend(delivery['provenance'])
    add=draft['add'];profile=get_profile(lang)
    corrections,overlay_provenance=annotation_overlay(lang,records,annotation_root)
    applied=set()
    sentence_corrections,sentence_provenance=sentence_translation_overlay(lang,records,annotation_root)
    applied_sentences=set()
    # Existing PT lemma references must keep their stable identities. A new
    # authoring ref with the same lemma/POS is a reference alias, not a new row.
    lemma_by_key={(r['lemma'],r['pos']):r['ref'] for r in base['lemmas']}
    remap={};unique=[]
    for row in add.get('lemmas',[]):
        key=(row['lemma'],row['pos'])
        if key in lemma_by_key:remap[row['ref']]=lemma_by_key[key]
        else:lemma_by_key[key]=row['ref'];unique.append(row)
    add['lemmas']=unique
    for sense in add.get('senses',[]):sense['lemma']=remap.get(sense['lemma'],sense['lemma'])
    for token in add.get('sentence_tokens',[]):
        if 'lemma' in token:token['lemma']=remap.get(token['lemma'],token['lemma'])
    for op in draft['operations']:
        for token in op['payload'].get('tokens',[]):
            if 'lemma' in token:token['lemma']=remap.get(token['lemma'],token['lemma'])
    senses={r['ref']:r for r in base['senses']+add.get('senses',[])}
    cards={r['ref']:r for r in base['cards']+add.get('cards',[])}
    links={r['card']:r for r in add.get('card_sentences',[])}
    sentences={r['ref']:r for r in add.get('sentences',[])}
    contexts={op['target_ref']:op['payload'] for op in draft['operations'] if op['kind']=='revise_context'}
    # All context senses are authored, keyed by lemma/POS and exact contextual
    # meaning. No dictionary guess, forced synonym, or inferred POS is used.
    annotation_counts=Counter()
    replacement_tokens=[]
    for (deck,rows,_),(_,delivery) in zip(records,deliveries):
        path=Path(annotation_root)/lang/(deck['slug']+'.json')
        annotation=read(path)
        assert annotation['lang']==lang and annotation['slug']==deck['slug'], path
        indexed={r['id']:r for r in annotation['rows']}
        expected={deck['slug']+':'+str(i) for i in range(len(rows))}
        assert set(indexed)==expected and len(indexed)==len(annotation['rows']), ('annotation coverage',path)
        for i,(row,card_ref) in enumerate(zip(rows,delivery['expected_target_refs'])):
            ar=indexed[deck['slug']+':'+str(i)]
            assert (ar['sentence'],ar['translation_de'])==(row['sentence'],row['translation_de']), (path,i,'stale text')
            expected_tokens=profile.tokenize(row['sentence'],row['_gap'])
            provided={t['idx']:t for t in ar['tokens']}
            word_tokens=[t for t in expected_tokens if t['is_word']]
            assert set(provided)=={t['idx'] for t in word_tokens} and len(provided)==len(ar['tokens']), (path,i,'token coverage')
            result=[];card=cards[card_ref];target_sense=senses[card['sense']]
            for raw in expected_tokens:
                token={k:raw[k] for k in ('idx','surface','start_pos','end_pos')}
                number_key=(ar['id'],raw['idx'])
                assert raw['is_word'] or not raw['surface'].isdecimal() or number_key in number_tokens, ('Missing explicit number token review',number_key)
                if raw['is_word'] or number_key in number_tokens:
                    if number_key in number_tokens:
                        supplied={**raw,**number_tokens[number_key]['after']};applied_numbers.add(number_key)
                    else:supplied=provided[raw['idx']]
                    assert all(supplied[k]==raw[k] for k in token), (path,i,'offset/surface',raw['idx'])
                    correction_key=(ar['id'],raw['idx'])
                    if correction_key in corrections:
                        correction=corrections[correction_key]
                        assert supplied['surface']==correction['surface']
                        assert {k:supplied[k] for k in correction['before']}==correction['before'], ('assembled before mismatch',correction_key)
                        assert (raw['start_pos'],raw['end_pos'])!=tuple(row['_gap']), ('target correction must edit corpus',correction_key)
                        supplied={**supplied,**correction['after']};applied.add(correction_key)
                    if (raw['start_pos'],raw['end_pos'])==tuple(row['_gap']):
                        token.update(lemma=target_sense['lemma'],sense=card['sense'],card=card_ref,
                                     context_gloss_de=row['gloss_de'],binding_status='confirmed')
                        if card.get('identity_function'):token['form_target']=card_ref
                    else:
                        for key in ('lemma','pos','gloss_de','context_gloss_de'):
                            assert isinstance(supplied.get(key),str) and supplied[key].strip(), (path,i,key,raw['idx'])
                        assert supplied['pos'] in {'ADJ','ADP','ADV','AUX','CCONJ','DET','INTJ','NOUN','NUM','PART','PRON','PROPN','SCONJ','VERB'}
                        lk=(supplied['lemma'],supplied['pos'])
                        if lk not in lemma_by_key:
                            lr=identifier(lang,'context-lemma',*lk);lemma_by_key[lk]=lr
                            add['lemmas'].append({'ref':lr,'lemma':lk[0],'pos':lk[1]})
                        lr=lemma_by_key[lk]
                        sr=identifier(lang,'context-sense',lr,supplied['context_gloss_de'])
                        if sr not in senses:
                            sense={'ref':sr,'lemma':lr,'sense_key':'context:'+supplied['context_gloss_de'],
                                   'gloss_de':supplied['context_gloss_de'],'definition_de':supplied['context_gloss_de']}
                            senses[sr]=sense;add.setdefault('senses',[]).append(sense)
                        add.setdefault('dictionary_forms',[]).append({'form':raw['surface'],'sense':sr,'gloss_de':supplied['gloss_de'],'rank':0})
                        token.update(lemma=lr,sense=sr,context_gloss_de=supplied['context_gloss_de'],binding_status='confirmed')
                    annotation_counts['word_tokens']+=1
                result.append(token)
            # Original source and annotation are still matched above. Only the
            # materialized German sentence receives the independently bound edit.
            if ar['id'] in sentence_corrections:
                value=sentence_corrections[ar['id']]['after']
                if card_ref in contexts:contexts[card_ref]['translation_de']=value
                else:sentences[links[card_ref]['sentence']]['translation_de']=value
                applied_sentences.add(ar['id'])
            if card_ref in contexts:contexts[card_ref]['tokens']=result
            else:
                sn=links[card_ref]['sentence']
                replacement_tokens.extend(dict(t,sentence=sn) for t in result)
        draft['provenance'].append({'kind':'ai_token_annotation','source_file':str(path.relative_to(CORPUS)) if path.is_relative_to(CORPUS) else str(path),
            'sha256':sha(path),'human_review':False})
    assert applied_sentences==set(sentence_corrections), 'Unapplied sentence corrections'
    assert applied_numbers==set(number_tokens), 'Unapplied number token reviews'
    if sentence_provenance:draft['provenance'].append(sentence_provenance)
    assert applied==set(corrections), 'Unapplied review corrections'
    if overlay_provenance:draft['provenance'].append(overlay_provenance)
    add['sentence_tokens']=replacement_tokens
    # Form spelling identity differs from its contextual gloss. Preserve each
    # context gloss while emitting exactly one dictionary row per stable ID.
    dictionary={(form_norm(r['form']),r['sense']) for r in base['dictionary_forms']}
    unique=[]
    for row in add['dictionary_forms']:
        key=(form_norm(row['form']),row['sense'])
        if key not in dictionary:dictionary.add(key);unique.append(row)
        else:annotation_counts['dictionary_duplicates_merged']+=1
    add['dictionary_forms']=unique
    # Explicit singleton exercises retain independent SRS state. Shared verbal
    # lexical anchors link the ordinary verb and its form exercises for counts.
    prospective={**base,'lemmas':base['lemmas']+add['lemmas'],'senses':list(senses.values())}
    for card in add['cards']:
        cid=author.target_identity(prospective,card)
        assert cid
        card['learning']={'group_id':lang+':card:'+cid,'primary_card_id':cid,'topic':'multilingual27',
            'related':[],'note':'Eigenständiges redaktionell geprüftes Lernziel.'}
    lemma_values={r['ref']:r for r in prospective['lemmas']}
    lexical={row['lemma']:identifier(lang,'lexical',row['lemma']) for d,rs,_ in records if d['kind']=='verb_base' for row in rs}
    already={r['card'] for r in base.get('card_lexical_targets',[])+add.get('card_lexical_targets',[])}
    for card_ref in draft['target_refs']:
        card=cards[card_ref];lm=lemma_values[senses[card['sense']]['lemma']]
        if card_ref not in already and lm['pos'] in ('VERB','AUX') and lm['lemma'] in lexical:
            add.setdefault('card_lexical_targets',[]).append({'card':card_ref,'lexical_target':lexical[lm['lemma']]})
            already.add(card_ref)
    for link in add.get('card_lexical_targets',[]):
        link.setdefault('note','Gemeinsamer lexikalischer Verbbegriff mit eigener Formübung.')
    # Word ownership is per surface, form membership is a separate relation.
    # Never append a second ordinary owner for an existing surface.
    owned={r['form_norm'] for r in base['deck_words']+add.get('deck_words',[])}
    owned.update(r['form_norm'] for r in base.get('word_aliases',[]))
    positions=Counter(r['deck'] for r in base['deck_words']+add.get('deck_words',[]))
    membership={r['card']:r['deck'] for r in add.get('deck_cards',[])}
    for card in add['cards']:
        norm=form_norm(card['form'])
        if norm not in owned:
            assert card.get('introduction_scope')=='form_only'
            deck_ref=membership[card['ref']];positions[deck_ref]+=1
            add.setdefault('deck_words',[]).append({'form_norm':norm,'deck':deck_ref,'primary_card':card['ref'],'position':positions[deck_ref]})
            owned.add(norm)
    add['deck_cards']=[{'deck':w['deck'],'card':w['primary_card'],'position':w['position']} for w in add['deck_words']]
    assert len(draft['target_refs'])==len(set(draft['target_refs']))
    draft['provenance'].append({'kind':'user_request','scope':'private_device_test',
        'actor':'Codex AI editorial review','human_review':False,
        'description':'Vom Nutzer angeforderter App- und iPhone-Test der KI-erstellten und vollständig nachgeprüften Stapel.'})
    return draft,dict(annotation_counts)


def check_counts(pack, records):
    deck_refs={d['slug']:d['ref'] for d in pack['decks']};counts={}
    for d,_,_ in records:
        table='deck_words' if d['kind']=='ordinary' else 'deck_practice_targets'
        counts[d['slug']]=sum(r['deck']==deck_refs[d['slug']] and not r.get('removed_in') for r in pack[table])
        assert counts[d['slug']]==d['target_count'], (d['slug'],counts[d['slug']])
    return counts


class Progress:
    def progress(self,message,*args):print(message,flush=True)
    def check_cancelled(self):pass


def install_assets(lang, directory, bundle, channel_state, base, cloud_base_evidence=None, bundle_generation=None):
    channels=read(channel_state) if channel_state else []
    if isinstance(channels,dict):channels=[channels]
    previous=next((c for c in channels if c['lang']==lang),None)
    if previous:
        assert cloud_base_evidence is not None, 'Cloud base evidence required'
        evidence=read(cloud_base_evidence)
        if isinstance(evidence,dict):evidence=[evidence]
        matching=[e for e in evidence if e['lang']==lang]
        assert len(matching)==1, 'Ambiguous cloud base evidence'
        evidence=matching[0];published=evidence['manifest']
        assert digest(published)==evidence['manifest_sha256']==previous['manifest_sha256']
        assert published['pack_canonical_sha256']==digest(base), 'Local base differs from cloud base'
        assert published['release_id']==evidence['release_id']==previous['release_id']
        assert published['generation']==evidence['generation']==previous['generation']
        assert published['lang']==lang and published['channel']=='internal'
    destination=ROOT/'assets/content'/lang
    old_path=destination/'bundled-release.json';old=None
    if old_path.exists():
        old=read(old_path);m=old['manifest']
        assert m.get('origin')=='bundle' and m.get('lang')==lang, 'Existing asset offer has wrong origin or language'
        assert digest(m)==old['manifest_sha256'], 'Existing asset manifest hash is invalid'
        assert type(m.get('generation')) is int and m['generation']>0
        for name in ('content.sqlite','history_inventory.json'):
            descriptor=old['objects'][name];file=destination/name
            assert file.exists() and file.stat().st_size==descriptor['size_bytes'] and sha(file)==descriptor['sha256'], 'Existing bundle assets do not match offer'
    if bundle_generation is not None:
        assert type(bundle_generation) is int and bundle_generation>0, 'Bundle generation must be positive'
    generation=bundle_generation if bundle_generation is not None else old['manifest']['generation']+1 if old else 1
    manifest=copy.deepcopy(bundle['manifest'])
    if manifest['parent_release_id'] is not None and previous is None:
        raise ValueError('Published parent channel state required for an existing base')
    manifest.update(release_id=str(uuid.uuid5(uuid.NAMESPACE_URL,'sprachapp:bundled:'+lang+':'+str(generation)+':'+manifest['sha256'])),
        generation=generation,channel='internal',origin='bundle',
        cloud_generation=previous['generation'] if previous else 0,
        cloud_manifest_sha256=previous['manifest_sha256'] if previous else None,
        parent_release_id=previous['release_id'] if previous else None,
        parent_manifest_sha256=previous['manifest_sha256'] if previous else None,
        pack_canonical_sha256=digest(bundle['pack']),
        created_at=old['manifest']['created_at'] if old and generation==old['manifest']['generation'] else utc_now())
    objects={name:{'sha256':sha(directory/name),'size_bytes':(directory/name).stat().st_size}
             for name in ('content.sqlite','history_inventory.json')}
    offer={'manifest':manifest,'manifest_sha256':digest(manifest),'objects':objects}
    if old and generation<=old['manifest']['generation']:
        assert offer==old, 'Bundle generation already belongs to another candidate'
        return old
    destination.mkdir(parents=True,exist_ok=True)
    for name in ('content.sqlite','history_inventory.json','content.manifest.json'):
        temporary=destination/(name+'.new');shutil.copy2(directory/name,temporary);temporary.replace(destination/name)
    atomic_json(destination/'bundled-release.json',offer)
    return offer


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lang',required=True,choices=NAMES)
    parser.add_argument('--out',required=True,type=Path,help='New isolated workspace, must not exist')
    parser.add_argument('--base',type=Path)
    parser.add_argument('--annotations',type=Path,default=CORPUS/'annotations')
    parser.add_argument('--version',required=True)
    parser.add_argument('--prepare-only',action='store_true',help='Save complete draft for inspection, without approval/build')
    parser.add_argument('--install-assets',action='store_true')
    parser.add_argument('--bundle-generation',type=int,help='Positive offline generation, default previous verified asset generation plus one')
    parser.add_argument('--cloud-base-evidence',type=Path,default=CORPUS/'portuguese-cloud-base.json')
    parser.add_argument('--channel-state',type=Path,default=CORPUS/'channel-state.json')
    args=parser.parse_args()
    assert args.bundle_generation is None or args.bundle_generation>0, 'Bundle generation must be positive'
    assert not args.out.exists(), 'Release workspace already exists'
    inventory=read(CORPUS/'inventory.json');records=corpus(args.lang,inventory)
    base=load_base(args.lang,args.base);draft,annotation_counts=prepare(args.lang,base,records,args.annotations)
    args.out.mkdir(parents=True)
    atomic_json(args.out/'base.json',base);atomic_json(args.out/'draft.json',draft)
    if args.prepare_only:
        print(json.dumps({'state':'prepared','target_count':len(draft['target_refs']),**annotation_counts}));return
    validation=author.validate_draft(draft,base)
    atomic_json(args.out/'validation.json',validation)
    if validation['technical']!='valid':
        raise ValueError(json.dumps(validation['findings'][:20],ensure_ascii=False))
    p=get_profile(args.lang)
    draft['reviews']=[{'decision':'approved','payload_sha256':author.draft_content_hash(draft),
        'profile_sha256':p.sha256,'editorial_policy':p.manifest['editorial_policy'],
        'reviewer':'Codex AI editorial review','human_review':False,'user_requested_private_device_test':True,
        'reason':'KI-Erstellung und vollständige redaktionelle Nachprüfung; zusätzliche kontextuelle Tokenprüfung; ausdrücklich angeforderter privater Gerätetest.',
        'created_at':utc_now()}]
    draft['validation']=author.validate_draft(draft,base)
    assert draft['validation']['technical']=='valid' and draft['validation']['editorial']=='approved'
    atomic_json(args.out/'draft.json',draft)
    directory=args.out/'bundle';directory.mkdir()
    bundle=author.build_release(draft,base,directory,version=args.version,
        expected_validation=draft['validation']['sha256'],progress=Progress())
    assert {f.name for f in directory.iterdir()}==set(FILES), 'Incomplete release bundle'
    counts=check_counts(bundle['pack'],records)
    if args.install_assets:install_assets(args.lang,directory,bundle,args.channel_state,base,args.cloud_base_evidence,args.bundle_generation)
    report={'state':'verified','lang':args.lang,'deck_counts':counts,'target_count':len(draft['target_refs']),
        'base_sha256':digest(base),'files':{name:sha(directory/name) for name in FILES},
        'human_review':False,'private_device_test':True,'assets_installed':args.install_assets,**annotation_counts}
    atomic_json(args.out/'report.json',report)
    print(json.dumps(report,ensure_ascii=False))


if __name__=='__main__':main()
