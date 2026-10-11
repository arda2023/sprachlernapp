"""Synthetic form workflow fixtures, never a production vocabulary selection."""
import copy
import hashlib
import json
import re
from sprachpipe.ids import stable_id, form_norm
from sprachpipe.form_targets import card_id, reuse_evidence
from sprachpipe.word_registry import digest


def fixture():
    words={'go':('go','VERB'),'went':('go','VERB'),'gone':('go','VERB'),'cut':('cut','VERB'),
           'run':('run','VERB'),'ran':('run','VERB'),'they':('they','PRON'),'paper':('paper','NOUN'),
           'home':('home','NOUN'),'yesterday':('yesterday','ADV'),'have':('have','AUX'),'daily':('daily','ADV')}
    source={'lang':'en','release':{'version':'synthetic-base','schema_version':3,'notes':'INTERNES TEST-PACK: synthetic'},
            'languages':[{'code':'en','name_native':'English','name_de':'Englisch','gloss_lang':'de'}],
            **{t:[] for t in ('lemmas','senses','cards','decks','deck_cards','deck_words','word_aliases','sentences','sentence_tokens','card_sentences','dictionary_forms','stories','story_sentences')}}
    sense_ids={}
    for lemma,pos in sorted(set(words.values())):
        source['lemmas'].append({'ref':lemma,'lemma':lemma,'pos':pos})
        source['senses'].append({'ref':lemma,'lemma':lemma,'sense_key':lemma+'#fixture','gloss_de':'Test','definition_de':'Synthetische Testbedeutung'})
        sense_ids[lemma]=stable_id('senses',lemma_id=stable_id('lemmas',lang='en',lemma=lemma,pos=pos),sense_key=lemma+'#fixture')
    for form,(lemma,_) in words.items():source['dictionary_forms'].append({'form':form,'sense':lemma,'gloss_de':'Test','rank':1})
    source['decks']=[{'ref':'owner','slug':'owner','title_de':'Synthetischer Besitzer','sort':1}]
    def card(ref,form,lemma,function=None):
        c={'ref':ref,'form':form,'sense':lemma,'translation_de':'Test','form_kind':function or 'base','form_label_de':'Verb, '+(function or 'Grundform'),'cefr_band':'anfaenger'}
        if function:c.update(identity_function=function,introduction_scope='form_only')
        cid=card_id('en',c,sense_ids[lemma]);c['learning']={'group_id':'en:card:'+cid,'primary_card_id':cid,'topic':'test','related':['family:'+lemma],'note':'synthetic'}
        return c
    old=card('cut-old','cut','cut');source['cards'].append(old)
    source['deck_words']=[{'form_norm':'cut','deck':'owner','primary_card':'cut-old','position':1}]
    source['deck_cards']=[{'deck':'owner','card':'cut-old','position':1}]
    def sentence(c,text,form_target=None):
        target=c['form'];start=text.lower().index(target);ref=c['ref']+'-sentence'
        sn={'ref':ref,'text':text,'translation_de':'Synthetischer Testsatz.','origins':['deck']}
        tokens=[]
        for i,m in enumerate(re.finditer(r'\w+|[^\w\s]',text)):
            raw=m.group();norm=raw.lower();t={'sentence':ref,'idx':i,'surface':raw,'start_pos':m.start(),'end_pos':m.end()}
            if norm in words:t.update(lemma=words[norm][0],sense=words[norm][0])
            if m.start()==start:
                t['card']=c['ref']
                if form_target:t['form_target']=form_target
            tokens.append(t)
        link={'card':c['ref'],'sentence':ref,'position':1,'gap_start':start,'gap_end':start+len(target),'accepted':[target],'valid_alternatives':[]}
        review={'sentence':ref,'decision':'approved','reason':'Synthetic test review, not production content','checked':{'text':text,'translation_de':sn['translation_de'],'tokens_sha256':digest(tokens),'links_sha256':digest([link])},'alternatives_checked':[]}
        return sn,tokens,link,review
    sn,ts,link,_=sentence(old,'They cut paper.');source['sentences']=[sn];source['sentence_tokens']=ts;source['card_sentences']=[link]
    registry={'format_version':1,'normalization':'NFC-lower-apostrophe-v1','words':[{'lang':'en','form_norm':'cut','aliases':[],'owner_deck_ref':'owner','primary_card_ref':'cut-old','primary_card_id':old['learning']['primary_card_id'],'position':1}]}
    source['word_registry']={'snapshot':copy.deepcopy(registry),'sha256':digest(registry)}
    registry['parent_sha256']=digest(registry)
    batches={str(n):{} for n in (1,2,3)};entries=[];deliveries={str(n):{'sentences':[],'sentence_tokens':[],'card_sentences':[]} for n in (1,2,3)};reviews={str(n):[] for n in (1,2,3)}
    def add(batch,t,r):batches[str(batch)].setdefault(t,[]).append(r)
    for lemma in ('go','cut','run'):add(1,'lexical_targets',{'ref':lemma,'anchor_key':'fixture:'+lemma,'note':'synthetic lexical identity'})
    for n,fun in enumerate(('base','past','past_participle'),1):
        add(1,'decks',{'ref':fun,'slug':fun,'title_de':'Test '+fun,'practice_kind':{'base':'verb_base','past':'verb_past','past_participle':'verb_participle'}[fun],'sort':n+1})
    add(1,'decks',{'ref':'base-again','slug':'base-again','title_de':'Same exercise again','practice_kind':'verb_base','sort':5})
    examples=[('go','go','base','They go home.'),('cut','cut','base','They cut paper.'),('run','run','base','They run daily.'),
              ('go','went','past','They went home yesterday.'),('cut','cut','past','Yesterday they cut paper.'),('run','ran','past','They ran yesterday.'),
              ('go','gone','past_participle','They have gone home.'),('cut','cut','past_participle','They have cut paper.'),('run','run','past_participle','They have run daily.')]
    reserved={'cut'};ownerpos=1
    for i,(lemma,form,fun,text) in enumerate(examples):
        batch=i//3+1;ref=lemma+'-'+fun;reuse=lemma=='cut' and fun=='base';c=old if reuse else card(ref,form,lemma,fun)
        if not reuse:add(batch,'cards',c)
        add(batch,'card_lexical_targets',{'card':c['ref'],'lexical_target':lemma,'note':'synthetic'})
        f={'ref':ref,'form':form,'sense':lemma,'function':fun,'card':c['ref'],'lexical_target':lemma,'note':'synthetic function'}
        add(batch,'form_targets',f);add(batch,'deck_practice_targets',{'deck':fun,'form_target':ref,'position':i%3+1})
        if fun=='base':add(batch,'deck_practice_targets',{'deck':'base-again','form_target':ref,'position':i%3+1})
        entries.append({'form_target':ref,'authoring_batch':batch,'reuse':reuse_evidence(source,c['ref'],fun,'Existing exact synthetic base context') if reuse else None})
        if form not in reserved:
            reserved.add(form);ownerpos+=1
            registry['words'].append({'lang':'en','form_norm':form,'aliases':[],'owner_deck_ref':'owner','primary_card_ref':c['ref'],'primary_card_id':c['learning']['primary_card_id'],'position':ownerpos})
            add(batch,'deck_words',{'form_norm':form,'deck':'owner','primary_card':c['ref'],'position':ownerpos});add(batch,'deck_cards',{'deck':'owner','card':c['ref'],'position':ownerpos})
        if not reuse:
            sn,ts,link,r=sentence(c,text,ref);d=deliveries[str(batch)];d['sentences'].append(sn);d['sentence_tokens']+=ts;d['card_sentences'].append(link);reviews[str(batch)].append(r)
    deliveries['3']['stories']=[{'ref':'form-story','slug':'form-story','title':'Synthetic forms','kind':'story','cefr_band':'anfaenger','minutes':1}]
    deliveries['3']['story_sentences']=[{'story':'form-story','sentence':'run-past_participle-sentence','idx':0,'paragraph_idx':0}]
    raw=(json.dumps(source,ensure_ascii=False,indent=2)+'\n').encode()
    selection={'format':'sprachapp.form-selection','format_version':2,'authoring_batch':1,'source_sha256':hashlib.sha256(raw).hexdigest(),'registry_sha256':digest(registry),'entries':entries,'batches':batches}
    return source,raw,selection,registry,deliveries,reviews


def delivery(selection, registry, sentences, reviews):
    batch=str(selection['authoring_batch'])
    return {'format':'sprachapp.editorial-content','format_version':3,'version':'synthetic-form-'+batch,
            'operation_id':'synthetic-'+batch,'reviewer':'automated fixture, no production review',
            'source_sha256':selection['source_sha256'],'registry_sha256':digest(registry),
            'selection':copy.deepcopy(selection),'selection_sha256':digest(selection),
            'add':{**copy.deepcopy(selection['batches'][batch]),**copy.deepcopy(sentences[batch])},'reviews':copy.deepcopy(reviews[batch])}
