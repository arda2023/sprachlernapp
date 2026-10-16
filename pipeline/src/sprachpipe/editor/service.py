"""Local application service: durable drafts, imports, jobs and immutable releases."""
from __future__ import annotations

import copy
import hashlib
import json
import os
import shutil
import subprocess
import uuid
from pathlib import Path

from .. import authoring_service as author
from ..ids import form_norm
from ..language_profiles import canonical_language, get_profile, UnsupportedLanguage, canonical_text, utf16_to_codepoint
from ..word_registry import digest
from .store import EditorStore, atomic_json, read_json, utc_now
from .jobs import Jobs
from .exchange import read_delivery, delivery_for_draft, authoring_context, template_delivery, write_zip, json_bytes
from .xlsx import write_workbook


class EditorService:
    def __init__(self,root=None,*,source=None,asset_directory=None):
        self.store=EditorStore(root);self.jobs=Jobs(self.store);self._bases={}
        self.source=Path(source or author.ROOT/'pipeline/out/story_single_sentence_v1/pack.json').resolve()
        self.asset_directory=Path(asset_directory or author.ROOT/'assets/content/en').resolve()
        if not self.store.list('heads'):
            raw=self.source.read_bytes();base=json.loads(raw)
            self.install_base(base,raw)
        self._recover_receipts()

    def close(self):self.jobs.close();self.store.close()

    def install_base(self,base,raw=None):
        fingerprint=author.base_fingerprint(base,raw)
        key=fingerprint['pack_canonical_sha256']
        self.store.put('bases',key,base)
        self.store.put('heads',base['lang'],fingerprint)
        language=next(l for l in base['languages'] if l['code']==base['lang'])
        self.store.put('languages',base['lang'],{'lang':base['lang'],'display_name':language['name_de'],
             'name_native':language['name_native'],'translation_lang':'de','revision':1})
        self._bases[key]=base
        return fingerprint

    def base(self,lang,fingerprint=None):
        fp=fingerprint or self.store.get('heads',lang);key=fp['pack_canonical_sha256']
        # Re-read immutable bytes: an in-memory cache cannot detect disk tampering.
        base=self.store.get('bases',key)
        author.require(base['lang']==lang and digest(base)==key,'BASE_CHANGED','Gespeicherte Basis ist verändert.',status=409)
        return base

    def languages(self):
        result=[]
        for language in self.store.list('languages'):
            try:profile=get_profile(language['lang']);state='ready';manifest=profile.manifest
            except UnsupportedLanguage:state='draft';manifest=None
            result.append({**language,'state':state,'profile':manifest,'base':self.store.get('heads',language['lang'])})
        return result

    def create_language(self,data):
        lang=canonical_language(data['lang'])
        author.require(data.get('translation_lang','de')=='de','PROFILE_UNSUPPORTED','Zunächst nur deutsche Übersetzungen.')
        author.require(not any(l['lang']==lang for l in self.languages()),'LANGUAGE_EXISTS','Sprache besteht bereits.',status=409)
        name=canonical_text(data['display_name']).strip()
        author.require(bool(name),'FIELD_REQUIRED','Sprachname fehlt.')
        base=author.empty_pack(lang,name);base['languages'][0]['name_native']=data.get('name_native') or name
        self.install_base(base)
        return next(l for l in self.languages() if l['lang']==lang)

    def new_draft(self,lang,deck_ref=None):
        base=self.base(lang);identifier=str(uuid.uuid4());refs=[]
        if deck_ref:
            refs=[r['card'] for r in base['deck_cards'] if r['deck']==deck_ref and not r.get('removed_in')]
        draft={'format':'sprachapp.editor-draft','format_version':1,'draft_id':identifier,
               'exchange_delivery_id':str(uuid.uuid4()),'lang':lang,'translation_lang':'de','revision':0,
               'base':self.store.get('heads',lang),'deck_ref':deck_ref,'add':{},'operations':[],
               'target_refs':refs,'reviews':[],'delivery_ids':[],'provenance':[],
               'import_inventory':{},'created_at':utc_now(),'state':'draft','validation':None}
        return self.store.save_draft(draft)

    def checked(self,identifier,etag):
        draft=self.store.load_draft(identifier)
        author.require(etag is not None,'PRECONDITION_REQUIRED','Entwurfsrevision fehlt.',status=428)
        author.require(etag==self.store.etag(draft),'DRAFT_CHANGED','Ein anderer Tab hat diesen Entwurf geändert. Neu laden und vergleichen.',status=409)
        author.require(draft.get('state')!='discarded','DRAFT_DISCARDED','Entwurf wurde verworfen.',status=409)
        return draft

    def projection(self,draft):
        """Editable view, never a release or validation substitute."""
        base=self.base(draft['lang'],draft['base']);work=copy.deepcopy(base)
        for table,rows in draft.get('add',{}).items():
            old={r.get('ref') for r in work.get(table,[]) if r.get('ref')}
            work.setdefault(table,[]).extend(copy.deepcopy([r for r in rows if r.get('ref') not in old or not r.get('ref')]))
        for op in draft['operations']:
            kind=op['kind'];ref=op.get('target_ref');p=op['payload']
            if kind=='add_vocabulary':
                for t,rows in p.items():
                    if t in ('lemmas','senses','dictionary_forms'):work[t].extend(copy.deepcopy(rows))
            elif kind=='create_deck':work['decks'].append(copy.deepcopy(p))
            elif kind=='create_target':
                card=copy.deepcopy(p['card']);card['ref']=ref;work['cards'].append(card)
                work['deck_words'].append({'form_norm':form_norm(card.get('form') or ''),'deck':p['deck_ref'],'primary_card':ref,'position':999999})
                self._project_context(work,ref,p.get('context',{}))
            elif kind=='set_solution_hint':
                for card in work['cards']:
                    if card['ref']==ref:card['translation_de']=p['translation_de']
            elif kind=='revise_context':self._project_context(work,ref,p)
            elif kind=='retire_target':
                for card in work['cards']:
                    if card['ref']==ref:card['removed_in']='draft'
            elif kind=='set_shared_gloss':
                impact=author.shared_gloss_impact(work,p['table'],ref)
                impact['row']['gloss_de']=p['gloss_de']
        return work

    @staticmethod
    def _project_context(work,ref,context):
        sn='draft-context:'+ref
        work['sentences']=[s for s in work['sentences'] if s['ref']!=sn]
        work['sentence_tokens']=[t for t in work['sentence_tokens'] if t['sentence']!=sn]
        work['card_sentences']=[l for l in work['card_sentences'] if l['card']!=ref]
        work['sentences'].append({'ref':sn,'text':context.get('text',''),'translation_de':context.get('translation_de','')})
        work['sentence_tokens'].extend([dict(t,sentence=sn) for t in copy.deepcopy(context.get('tokens',[]))])
        gap=context.get('gap') or {}
        work['card_sentences'].append({'card':ref,'sentence':sn,'gap_start':gap.get('start_pos'),
            'gap_end':gap.get('end_pos'),'valid_alternatives':context.get('valid_alternatives',[]),'position':1})

    def catalog(self,lang,*,draft_id=None,query='',deck=None,cursor=0,limit=50,status='active'):
        limit=max(1,min(int(limit),100));cursor=max(0,int(cursor))
        draft=self.store.load_draft(draft_id) if draft_id else None
        author.require(draft is None or draft['lang']==lang,'LANGUAGE_MISMATCH','Entwurf gehört zu anderer Sprache.')
        work=self.projection(draft) if draft else self.base(lang)
        sentences={s['ref']:s for s in work['sentences']}
        links={l['card']:l for l in work['card_sentences'] if not l.get('removed_in')}
        owners={w['form_norm']:w['deck'] for w in work['deck_words'] if not w.get('removed_in')}
        entries=[];q=query.casefold()
        for card in work['cards']:
            if status=='active' and card.get('removed_in'):continue
            if status=='retired' and not card.get('removed_in'):continue
            owner=owners.get(form_norm(card.get('form') or ''))
            # Form practice decks have an independent membership.
            if deck and owner!=deck and not any(r.get('deck')==deck and r.get('card')==card['ref'] for r in work['deck_cards']):continue
            link=links.get(card['ref'],{});sentence=sentences.get(link.get('sentence'),{})
            if q and q not in ' '.join(str(x or '') for x in (card.get('form'),card.get('translation_de'),sentence.get('text'),sentence.get('translation_de'))).casefold():continue
            edited=draft and (card['ref'] in draft.get('target_refs',[]))
            validation=draft.get('validation') if draft else None
            entries.append({'ref':card['ref'],'form':card.get('form'),'translation_de':card.get('translation_de'),
                'text':sentence.get('text'),'sentence_translation_de':sentence.get('translation_de'),
                'owner_deck':owner,'retired':bool(card.get('removed_in')),
                'technical':validation['technical'] if edited and validation else 'open' if edited else 'base',
                'editorial':validation['editorial'] if edited and validation else 'open' if edited else 'base'})
        entries.sort(key=lambda r:((r['form'] or '').casefold(),r['ref']))
        return {'items':entries[cursor:cursor+limit],'total':len(entries),'cursor':cursor,'limit':limit,
                'decks':work['decks'],'base':draft['base'] if draft else self.store.get('heads',lang)}

    def target(self,identifier,ref):
        draft=self.store.load_draft(identifier);work=self.projection(draft)
        try:view=author.target_view(work,ref)
        except StopIteration:raise author.AuthoringError('NOT_FOUND','Aufgabe nicht gefunden.',status=404) from None
        base=self.base(draft['lang'],draft['base'])
        original=next((c for c in base['cards'] if c['ref']==ref),None)
        view['before']=author.target_view(base,ref) if original else None
        return view

    def save_operations(self,identifier,operations,etag):
        with self.store.mutex:
            draft=self.checked(identifier,etag)
            changed=False
            for op in operations:
                if op.get('op_id'):
                    prior=next((o for o in draft['operations'] if o['op_id']==op['op_id']),None)
                    if prior is not None:
                        author.require(prior==op,'OPERATION_ID_CONFLICT','Operationsreferenz mit abweichendem Inhalt wiederverwendet.',status=409)
                        continue
                changed=True
                author.require(op.get('lang')==draft['lang'],'LANGUAGE_MISMATCH','Operation gehört zu anderer Sprache.')
                author.require(op.get('kind') in {'add_vocabulary','create_deck','create_target','revise_context','set_solution_hint','set_shared_gloss','retire_target','correct_story_context'},'OPERATION_UNSUPPORTED','Unbekannte Bearbeitungsaktion.')
                op=copy.deepcopy(op);op.setdefault('op_id',str(uuid.uuid4()))
                existing=next((i for i,o in enumerate(draft['operations']) if o['kind']==op['kind'] and o.get('target_ref')==op.get('target_ref')),None)
                if existing is None:draft['operations'].append(op)
                else:draft['operations'][existing]=op
                if op['kind'] in ('create_target','revise_context','set_solution_hint','retire_target') and op['target_ref'] not in draft['target_refs']:draft['target_refs'].append(op['target_ref'])
            if not changed:return draft
            draft.update(validation=None,reviews=[])
            return self.store.save_draft(draft,etag)

    def update_target(self,identifier,ref,data,etag):
        with self.store.mutex:
            draft=self.checked(identifier,etag);base=self.base(draft['lang'],draft['base'])
            original=next((c for c in base['cards'] if c['ref']==ref),None)
            context=copy.deepcopy(data['context'])
            if original:
                before=author.target_view(base,ref)
                ops=[{'kind':'revise_context','target_ref':ref,'lang':draft['lang'],'expect':before['expect'],'payload':context},
                     {'kind':'set_solution_hint','target_ref':ref,'lang':draft['lang'],'expect':before['expect'],
                      'payload':{'translation_de':data.get('translation_de')}}]
                return self.save_operations(identifier,ops,etag)
            op=next((o for o in draft['operations'] if o['kind']=='create_target' and o['target_ref']==ref),None)
            if op:
                if data.get('deck_ref'):op['payload']['deck_ref']=data['deck_ref']
                if 'form' in data:op['payload']['card']['form']=data['form']
                op['payload']['context']=context;op['payload']['card']['translation_de']=data.get('translation_de')
                if 'sense' in data:op['payload']['card']['sense']=data['sense']
            else:
                card=next(c for c in draft.get('add',{}).get('cards',[]) if c['ref']==ref)
                card['translation_de']=data.get('translation_de')
                if 'form' in data:
                    author.require(not card.get('learning') or card.get('form')==data['form'],'IDENTITY_CHANGED','Deklarierte Lernidentität nicht ändern; neue Aufgabe anlegen.')
                    card['form']=data['form']
                if 'sense' in data:card['sense']=data['sense']
                if not card.get('learning') and data.get('deck_ref'):
                    # Turn an incomplete spreadsheet row into the same explicit
                    # creation operation as the browser's new-target dialog.
                    card.setdefault('cefr_band','anfaenger')
                    draft['add']['cards'].remove(card)
                    previous={l['sentence'] for l in draft['add'].get('card_sentences',[]) if l['card']==ref}
                    shared={l['sentence'] for l in draft['add'].get('card_sentences',[]) if l['card']!=ref}
                    for table in ('sentences','sentence_tokens'):
                        draft['add'][table]=[r for r in draft['add'].get(table,[]) if r.get('ref' if table=='sentences' else 'sentence') not in previous-shared]
                    draft['add']['card_sentences']=[r for r in draft['add'].get('card_sentences',[]) if r['card']!=ref]
                    draft['operations'].append({'op_id':str(uuid.uuid4()),'kind':'create_target','lang':draft['lang'],'target_ref':ref,'expect':{'absent':True},'payload':{'deck_ref':data['deck_ref'],'card':card,'context':context}})
                    draft.update(validation=None,reviews=[])
                    return self.store.save_draft(draft,etag)
                # Explicit user changes replace only this draft's unfinished annotations.
                sn='import-context:'+ref
                previous={l['sentence'] for l in draft['add'].get('card_sentences',[]) if l['card']==ref}
                shared={l['sentence'] for l in draft['add'].get('card_sentences',[]) if l['card']!=ref}
                disposable=previous-shared
                draft['add']['sentences']=[s for s in draft['add'].get('sentences',[]) if s['ref'] not in disposable]
                draft['add']['sentence_tokens']=[t for t in draft['add'].get('sentence_tokens',[]) if t['sentence'] not in disposable]
                draft['add']['card_sentences']=[l for l in draft['add'].get('card_sentences',[]) if l['card']!=ref]
                draft['add']['sentences'].append({'ref':sn,'text':context['text'],'translation_de':context['translation_de'],'origins':['deck']})
                draft['add']['sentence_tokens'].extend([dict(t,sentence=sn) for t in context.get('tokens',[])])
                draft['add']['card_sentences'].append({'card':ref,'sentence':sn,'position':1,
                     'gap_start':context.get('gap',{}).get('start_pos'),'gap_end':context.get('gap',{}).get('end_pos'),
                     'accepted':[card['form']],'valid_alternatives':context.get('valid_alternatives',[])})
            draft.update(validation=None,reviews=[])
            return self.store.save_draft(draft,etag)

    def vocabulary(self,identifier,surface):
        draft=self.store.load_draft(identifier);work=self.projection(draft)
        forms=[d for d in work['dictionary_forms'] if form_norm(d.get('form') or '')==form_norm(surface) and not d.get('removed_in')]
        senses={s['ref']:s for s in work['senses']};lemmas={l['ref']:l for l in work['lemmas']}
        return [{'sense':senses[f['sense']],'lemma':lemmas[senses[f['sense']]['lemma']],'form':f,'form_ref':digest(f)} for f in forms if f['sense'] in senses]

    def tokenize(self,identifier,data,etag):
        draft=self.checked(identifier,etag);profile=get_profile(draft['lang'])
        text=canonical_text(data['text']);gap=None
        if data.get('selection'):
            start,end=(utf16_to_codepoint(text,n) for n in data['selection'])
            gap=profile.gap(text,start,end,data['form']);span=(start,end)
        else:span=None
        tokens=profile.tokenize(text,span);work=self.projection(draft)
        senses={s['ref']:s for s in work['senses']};lemmas={l['ref']:l for l in work['lemmas']}
        forms={}
        for form in work['dictionary_forms']:
            if not form.get('removed_in'):
                forms.setdefault(form_norm(form['form']),[]).append(form)
        for token in tokens:
            candidates=[{'sense':senses[f['sense']],'lemma':lemmas[senses[f['sense']]['lemma']],'form':f}
                        for f in forms.get(form_norm(token['surface']),[]) if f['sense'] in senses] if token['is_word'] else []
            token['binding_status']='unresolved' if token['is_word'] else 'confirmed'
            if len(candidates)==1:
                c=candidates[0];token.update(lemma=c['lemma']['ref'],sense=c['sense']['ref'],context_gloss_de=c['form']['gloss_de'],binding_status='suggested')
        return {'text':text,'tokens':tokens,'gap':gap,'text_sha256':digest(text),'profile_sha256':profile.sha256}

    def preview_upload(self,raw,filename,lang,source=None):
        identifier=str(uuid.uuid4())
        def run(job):
            job.progress('Datei und Container prüfen …')
            quarantine=self.store.root/'quarantine'/identifier;quarantine.mkdir(parents=True)
            (quarantine/'upload.bin').write_bytes(raw)
            atomic_json(quarantine/'metadata.json',{'filename':Path(filename).name,'lang':lang,'sha256':hashlib.sha256(raw).hexdigest()})
            delivery=read_delivery(raw,filename,lang,source=source)
            base=self.base(lang)
            resolved=author.resolve_roundtrip(base,delivery)
            preview=author.preview_import(base,resolved);preview['payload_sha256']=digest(delivery)
            for chunk in preview['inventory']['chunks']:
                job.progress('Zielzeilen vollständig erfassen …',min(chunk['number']*100,preview['inventory']['expected']),preview['inventory']['expected'])
            record={'import_id':identifier,'lang':lang,'filename':Path(filename).name,'delivery':delivery,
                    'preview':preview,'base':self.store.get('heads',lang),'created_at':utc_now()}
            record['preview_sha256']=digest(record)
            job.check_cancelled();self.store.put('imports',identifier,record)
            return {'import_id':identifier,'preview_sha256':record['preview_sha256'],'preview':preview}
        return self.jobs.submit('import-preview',run)

    def accept_import(self,identifier,preview_hash,*,draft_id=None,etag=None):
        with self.store.mutex:
            record=self.store.get('imports',identifier)
            author.require(record['preview_sha256']==preview_hash,'ENTITY_CHANGED','Importvorschau hat sich geändert.',status=409)
            delivery=record['delivery'];payload_hash=record['preview']['payload_sha256']
            for old in self.store.list('imports'):
                receipt=old.get('receipt')
                if receipt and old['lang']==record['lang'] and receipt['delivery_id']==delivery['delivery_id']:
                    author.require(receipt['payload_sha256']==payload_hash,'DELIVERY_ID_REUSED','Diese Liefer-ID wurde bereits mit anderem Inhalt übernommen.',status=409)
                    return receipt
            if draft_id:draft=self.checked(draft_id,etag)
            else:
                # Recovery can identify an accepted draft even if the journal write was interrupted.
                draft=self.new_draft(record['lang']);etag=self.store.etag(draft)
            author.require(draft['base']['pack_canonical_sha256']==record['base']['pack_canonical_sha256'],'BASE_CHANGED','Basis seit Vorschau verändert.',status=409)
            supplied=delivery.get('base',{}).get('pack_canonical_sha256')
            author.require(supplied is None or supplied==draft['base']['pack_canonical_sha256'],'BASE_CHANGED','Lieferung bezieht sich auf eine andere Basis. Explizit auf der passenden Basis bearbeiten.',status=409)
            delivery=author.resolve_roundtrip(self.base(draft['lang'],draft['base']),delivery)
            for table,rows in delivery['add'].items():draft['add'].setdefault(table,[]).extend(copy.deepcopy(rows))
            draft['operations'].extend(copy.deepcopy(delivery['operations']))
            draft['target_refs']=list(dict.fromkeys(draft['target_refs']+delivery['expected_target_refs']))
            draft['delivery_ids'].append(delivery['delivery_id']);draft['provenance'].extend(delivery.get('provenance',[]))
            # Aggregate all deliveries, never release just a successful subset.
            draft['import_inventory']=author.preview_import(self.base(draft['lang'],draft['base']),{
                **delivery,'add':draft['add'],'expected_target_refs':draft['target_refs']})['inventory']
            receipt={'import_id':identifier,'delivery_id':delivery['delivery_id'],'payload_sha256':payload_hash,
                'base_sha256':record['base']['pack_canonical_sha256'],'draft_id':draft['draft_id'],
                'draft_revision':draft['revision']+1,'inventory':record['preview']['inventory'],'completed_at':utc_now()}
            draft.setdefault('import_receipts',[]).append(receipt);draft.update(validation=None,reviews=[])
            self.store.save_draft(draft,etag);record['receipt']=receipt;self.store.put('imports',identifier,record)
            return receipt

    def _recover_receipts(self):
        for draft in self.store.drafts():
            for receipt in draft.get('import_receipts',[]):
                record=self.store.get('imports',receipt['import_id'])
                if not record.get('receipt'):record['receipt']=receipt;self.store.put('imports',receipt['import_id'],record)

    def validate(self,identifier,etag):
        draft=self.checked(identifier,etag)
        def run(job):
            job.progress('Inhalt, Bindungen, Historie und Sprachregeln prüfen …')
            result=author.validate_draft(draft,self.base(draft['lang'],draft['base']))
            with self.store.mutex:
                current=self.checked(identifier,etag);job.check_cancelled();current['validation']=result
                saved=self.store.save_draft(current,etag)
            return {'validation':result,'draft':saved,'etag':self.store.etag(saved)}
        return self.jobs.submit('validate',run)

    def review(self,identifier,data,etag):
        with self.store.mutex:
            draft=self.checked(identifier,etag);sha=author.draft_content_hash(draft)
            author.require(data.get('payload_sha256')==sha,'REVIEW_STALE','Prüfung bezieht sich auf einen anderen Entwurfsinhalt.',status=409)
            author.require(bool(data.get('reviewer','').strip()) and bool(data.get('reason','').strip()),'FIELD_REQUIRED','Prüfperson und Prüfnotiz angeben.')
            author.require((draft.get('validation') or {}).get('technical')=='valid','CONTENT_INVALID','Zuerst technische Blocker lösen.')
            draft['reviews'].append({'scope':'draft','record_refs':draft['target_refs'],'payload_sha256':sha,
                'decision':'approved','reviewer':data['reviewer'],'reason':data['reason'],'reviewed_at':utc_now(),'origin':'local-editor'})
            draft['validation']=author.validate_draft(draft,self.base(draft['lang'],draft['base']))
            return self.store.save_draft(draft,etag)

    def exchange(self,identifier,format,etag):
        draft=self.checked(identifier,etag)
        author.require(format in ('zip','xlsx','json'),'FORMAT_UNSUPPORTED','ZIP, XLSX oder JSON auswählen.')
        base=self.base(draft['lang'],draft['base']);delivery=delivery_for_draft(draft,base)
        data=write_zip(delivery,authoring_context(base,selected_refs=draft['target_refs'])) if format=='zip' else write_workbook(delivery) if format=='xlsx' else json_bytes(delivery)
        path=self.store.root/'exports'/(str(uuid.uuid4())+'.'+format);path.parent.mkdir(exist_ok=True);path.write_bytes(data)
        return {'artifact_id':self.store.artifact(path,'redaktion-'+draft['lang']+'.'+format,'application/octet-stream')}

    def template(self,lang,count,topic=''):
        delivery,context=template_delivery(self.base(lang),count,topic)
        path=self.store.root/'exports'/(str(uuid.uuid4())+'.zip');path.parent.mkdir(exist_ok=True);path.write_bytes(write_zip(delivery,context))
        return {'artifact_id':self.store.artifact(path,'vorlage-'+lang+'.zip','application/zip')}

    def discard(self,identifier,etag):
        draft=self.checked(identifier,etag);draft['state']='discarded';return self.store.save_draft(draft,etag)

    def release(self,identifier,data,etag):
        draft=self.checked(identifier,etag)
        def run(job):
            base=self.base(draft['lang'],draft['base'])
            author.require(self.store.get('heads',draft['lang'])==draft['base'],'BASE_CHANGED','Neuere lokale Version vorhanden. Entwurf zuerst neu abgleichen.',status=409)
            release_id=str(uuid.uuid4());label=data['version'].strip()
            author.require(label and len(label)<=100 and all(c.isalnum() or c in '._-' for c in label),'VERSION_INVALID','Version: Buchstaben, Zahlen, Punkt, Bindestrich oder Unterstrich.')
            author.require(not any(r['lang']==draft['lang'] and r['version']==label for r in self.store.list('releases')),'VERSION_EXISTS','Versionslabel ist bereits vergeben.',status=409)
            temporary=self.store.root/'staging'/release_id;temporary.mkdir(parents=True)
            try:
                bundle=author.build_release(draft,base,temporary,version=label,expected_validation=data['validation_sha256'],progress=job)
                with self.store.mutex:
                    self.checked(identifier,etag)
                    author.require(self.store.get('heads',draft['lang'])==draft['base'],'BASE_CHANGED','Basis wurde während des Builds ersetzt.',status=409)
                    job.check_cancelled()
                    destination=self.store.root/'bundles'/release_id;destination.parent.mkdir(exist_ok=True);os.replace(temporary,destination)
                    record={'release_id':release_id,'lang':draft['lang'],'version':label,'path':str(destination.relative_to(self.store.root)),
                        'draft_id':identifier,'created_at':utc_now(),'manifest':bundle['manifest'],'status':'verified'}
                    self.store.put('releases',release_id,record)
                    self.install_base(bundle['pack'])
                archive=shutil.make_archive(str(destination),'zip',destination)
                record['artifact_id']=self.store.artifact(archive,'release-'+label+'.zip','application/zip')
                self.store.put('releases',release_id,record)
                return record
            finally:
                if temporary.exists():shutil.rmtree(temporary)
        return self.jobs.submit('release',run)

    def staging_impact(self,identifier):
        release=self.store.get('releases',identifier);directory=self.store.root/release['path']
        manifest=release['manifest']
        author.require(read_json(directory/'content.manifest.json')==manifest,'BUNDLE_CHANGED','Manifest des geprüften Bundles wurde verändert.',status=409)
        checks=[hashlib.sha256((directory/'content.sqlite').read_bytes()).hexdigest()==manifest['sha256'],
                hashlib.sha256((directory/'pack.json').read_bytes()).hexdigest()==manifest['pack_json_sha256'],
                digest(read_json(directory/'registry.json'))==manifest['registry_sha256'],
                digest(read_json(directory/'history_inventory.json'))==manifest['history_inventory_sha256'],
                digest(read_json(directory/'editorial_reviews.json'))==manifest['editorial_reviews_sha256']]
        author.require(all(checks),'BUNDLE_CHANGED','Geprüftes Bundle wurde nachträglich verändert.',status=409)
        files={name:hashlib.sha256((self.asset_directory/name).read_bytes()).hexdigest() if (self.asset_directory/name).exists() else None
               for name in ('content.sqlite','content.manifest.json')}
        impact={'release_id':identifier,'version':release['version'],'lang':release['lang'],'existing':files,
                'next_sqlite_sha256':hashlib.sha256((directory/'content.sqlite').read_bytes()).hexdigest(),
                'destination':'Temporäres Testasset' if self.asset_directory!=author.ROOT/'assets/content/en' else 'App-Entwicklungsasset'}
        impact['sha256']=digest(impact);return impact

    def stage(self,identifier,expected):
        impact=self.staging_impact(identifier)
        author.require(expected==impact['sha256'],'ENTITY_CHANGED','Asset oder Release seit Vorschau verändert.',status=409)
        release=self.store.get('releases',identifier);directory=self.store.root/release['path']
        author.require(release['lang']=='en','PROFILE_UNSUPPORTED','Kein App-Assetpfad für diese Sprache konfiguriert.')
        def run(job):
            job.progress('Asset sichern und separat prüfen …')
            author.require(self.staging_impact(identifier)['sha256']==expected,'ENTITY_CHANGED','Asset seit Freigabe verändert.',status=409)
            backup=self.store.root/'backups'/str(uuid.uuid4());backup.mkdir(parents=True)
            for name,value in impact['existing'].items():
                if value is not None:shutil.copy2(self.asset_directory/name,backup/name)
            staging=self.store.root/'staging'/str(uuid.uuid4());staging.mkdir(parents=True)
            adopted=False
            try:
                author.run_dart(['--stage-from',str(directory),'--stage-to',str(staging),'--lang',release['lang']])
                job.check_cancelled()
                author.require(self.staging_impact(identifier)['sha256']==expected,'ENTITY_CHANGED','Asset während Staging verändert.',status=409)
                self.asset_directory.mkdir(parents=True,exist_ok=True)
                # Explicit adoption; build_release never reaches this branch.
                adopted=True
                for name in impact['existing']:shutil.copy2(staging/name,self.asset_directory/name)
                author.run_dart(['--stage-from',str(directory),'--stage-to',str(self.asset_directory),'--lang',release['lang']])
                return {'status':'verified','backup_id':backup.name,'impact':impact}
            except Exception:
                if adopted:
                    for name,value in impact['existing'].items():
                        if value is not None:shutil.copy2(backup/name,self.asset_directory/name)
                        else:(self.asset_directory/name).unlink(missing_ok=True)
                raise
            finally:shutil.rmtree(staging)
        return self.jobs.submit('stage',run)

    def prepare_story_history(self,identifier,etag):
        draft=self.checked(identifier,etag)
        def run(job):
            from ..export import export_sqlite
            base=self.base(draft['lang'],draft['base'])
            directory=self.store.root/'staging'/str(uuid.uuid4());directory.mkdir(parents=True)
            try:
                job.progress('Zulässige Storyherkünfte mit dem echten Reader erfassen …')
                export_sqlite(base,directory/'content.sqlite')
                author.run_dart(['--from',str(directory/'content.sqlite'),'--out',str(directory/'reader.json'),'--lang',draft['lang']])
                history=read_json(directory/'reader.json')
                with self.store.mutex:
                    current=self.checked(identifier,etag);job.check_cancelled()
                    if current.get('source_history')!=history:current.update(source_history=history,validation=None,reviews=[])
                    saved=self.store.save_draft(current,etag)
                return {'draft':saved,'etag':self.store.etag(saved)}
            finally:shutil.rmtree(directory)
        return self.jobs.submit('story-history',run)

    def story_contexts(self,identifier):
        draft=self.store.load_draft(identifier)
        sources=(draft.get('source_history') or {}).get('story_source_snapshots',[])
        return [{'source_key':s['source_key'],'word':s['sentence']['tokens'][s['token_index']]['surface'],
                 'text':(s.get('practice_context') or {'sentence':s['sentence']})['sentence']['text']} for s in sources]

    def story_target(self,identifier,key):
        from ..pack import _build_rows
        draft=self.store.load_draft(identifier);work=self.projection(draft)
        source=next(s for s in draft['source_history']['story_source_snapshots'] if s['source_key']==key)
        rows=_build_rows(self.base(draft['lang'],draft['base']))
        lemmas={r['id']:raw['ref'] for r,raw in zip(rows['lemmas'],work['lemmas'])}
        senses={r['id']:raw['ref'] for r,raw in zip(rows['senses'],work['senses'])}
        practice=source.get('practice_context') or {'sentence':source['sentence'],'token_index':source['token_index']}
        sn=practice['sentence'];target=sn['tokens'][practice['token_index']]
        tokens=[{'idx':t['index'],'surface':t['surface'],'start_pos':utf16_to_codepoint(sn['text'],t['start']),
            'end_pos':utf16_to_codepoint(sn['text'],t['end']),'lemma':lemmas.get(t['lemma_id']),'sense':senses.get(t['sense_id']),
            'context_gloss_de':t['gloss'],'is_word':any(c.isalpha() for c in t['surface']),'binding_status':'confirmed'} for t in sn['tokens']]
        context={'text':sn['text'],'translation_de':sn['translation'],'tokens':tokens,
                 'gap':{'start_pos':utf16_to_codepoint(sn['text'],target['start']),'end_pos':utf16_to_codepoint(sn['text'],target['end'])},
                 'valid_alternatives':[],'reason':'Redaktionelle Storykorrektur'}
        op=next((o for o in draft['operations'] if o['kind']=='correct_story_context' and o['target_ref']==key),None)
        return {'ref':key,'story_source':True,'expect':{'source_sha256':digest(source)},
                'card':{'form':target['surface'],'translation_de':target['gloss'],'sense':senses.get(target['sense_id'])},
                'context':copy.deepcopy(op['payload'] if op else context),'before':{'context':context}}

    def rebase(self,identifier,etag):
        with self.store.mutex:
            draft=self.checked(identifier,etag);head=self.store.get('heads',draft['lang'])
            if head==draft['base']:return draft
            new=self.base(draft['lang']);old=self.base(draft['lang'],draft['base']);conflicts=[]
            for op in draft['operations']:
                ref=op.get('target_ref');kind=op['kind']
                if kind in ('set_solution_hint','revise_context','retire_target'):
                    try:view=author.target_view(new,ref)
                    except StopIteration:conflicts.append(ref);continue
                    if any(view['expect'].get(k)!=v for k,v in op.get('expect',{}).items() if k in view['expect']):conflicts.append(ref)
                elif kind=='correct_story_context':conflicts.append('Storyherkunft erneut prüfen')
                elif kind=='set_shared_gloss':
                    if author.shared_gloss_impact(new,op['payload']['table'],ref)['sha256']!=op['expect']['impact_sha256']:conflicts.append(ref)
                elif kind.startswith('create_') and any(r.get('ref')==ref for t in ('cards','decks') for r in new[t]):conflicts.append(ref)
            for table,records in draft.get('add',{}).items():
                prior={r.get('ref'):r for r in old.get(table,[]) if r.get('ref')}
                current={r.get('ref'):r for r in new.get(table,[]) if r.get('ref')}
                for r in records:
                    if r.get('ref') in current and current[r['ref']]!=prior.get(r['ref']):conflicts.append(r['ref'])
            author.require(not conflicts,'REBASE_CONFLICT','Neue Basis enthält Konflikte: '+', '.join(dict.fromkeys(conflicts))+'. Alten Entwurf vergleichen; betroffene Änderungen ausdrücklich neu erfassen.',status=409)
            draft.update(base=head,validation=None,reviews=[]);draft.pop('source_history',None)
            return self.store.save_draft(draft,etag)
