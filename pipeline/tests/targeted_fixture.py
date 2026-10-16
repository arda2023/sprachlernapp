"""Shared synthetic Python-import / Dart-reader fixture, never production data."""
import copy
import hashlib
import json
from sprachpipe.ids import stable_id
from sprachpipe.annotate import tokenize
from sprachpipe.pack import build_rows
from sprachpipe.word_registry import digest
from test_form_targets import workflow


def fixture(tmp_path):
    source, _ = workflow(tmp_path)
    # A different meaning of 'cut' with no ownership and a historical singleton.
    source['senses'].append({'ref': 'cut-other', 'lemma': 'cut', 'sense_key': 'cut#other', 'gloss_de': 'kürzen', 'definition_de': 'Eine andere synthetische Bedeutung.'})
    source['dictionary_forms'].append({'form': 'cut', 'sense': 'cut-other', 'gloss_de': 'kürzen', 'rank': 1})
    sid = stable_id('senses', lemma_id=stable_id('lemmas', lang='en', lemma='cut', pos='VERB'), sense_key='cut#other')
    cid = stable_id('cards', lang='en', form='cut', sense_id=sid)
    retired = {'ref': 'cut-other', 'form': 'cut', 'sense': 'cut-other', 'translation_de': 'kürzen', 'cefr_band': 'anfaenger', 'learning': {'group_id': 'en:card:'+cid, 'primary_card_id': cid, 'topic': 'test', 'related': [], 'note': 'synthetic singleton'}}
    source['cards'].append(retired)
    # Another active card shares the old cut/base sentence at a different span.
    sid2 = stable_id('senses', lemma_id=stable_id('lemmas', lang='en', lemma='they', pos='PRON'), sense_key='they#fixture')
    cid2 = stable_id('cards', lang='en', form='they', sense_id=sid2)
    source['cards'].append({'ref': 'they', 'form': 'they', 'sense': 'they', 'translation_de': 'sie', 'cefr_band': 'anfaenger', 'learning': {'group_id': 'en:card:'+cid2, 'primary_card_id': cid2, 'topic': 'test', 'related': [], 'note': 'shared sentence'}})
    source['card_sentences'].append({'card':'they', 'sentence':'cut-old-sentence', 'position':1, 'gap_start':0, 'gap_end':4, 'accepted':['they'], 'valid_alternatives':[]})
    next(t for t in source['sentence_tokens'] if t['sentence']=='cut-old-sentence' and t['idx']==0)['card']='they'
    pos=len(source['deck_words'])+1
    source['deck_words'].append({'form_norm':'they','deck':'owner','primary_card':'they','position':pos})
    source['deck_cards'].append({'deck':'owner','card':'they','position':pos})
    registry=source['word_registry']['snapshot']
    registry['words'].append({'lang':'en','form_norm':'they','aliases':[],'owner_deck_ref':'owner','primary_card_ref':'they','primary_card_id':cid2,'position':pos})
    source['word_registry']['sha256']=digest(registry)
    def tokens(ref,text,card=None,other=False,form=None):
        result=[]
        for t in tokenize(text):
            row={k:t[k] for k in ('idx','surface','start_pos','end_pos')};row['sentence']=ref
            if t['is_word']:
                norm=t['surface'].lower(); lemma={'went':'go','gone':'go','ran':'run'}.get(norm,norm)
                row.update(lemma=lemma,sense='cut-other' if other and norm=='cut' else lemma)
                if card and norm=='cut':
                    row['card']=card
                    if form:row['form_target']=form
            result.append(row)
        return result
    for ref,text,card in [('other-exercise','They cut daily.','cut-other'),('other-story','They cut yesterday.',None)]:
        source['sentences'].append({'ref':ref,'text':text,'translation_de':'Synthetischer Satz.','origins':['story' if card is None else 'deck']})
        source['sentence_tokens']+=tokens(ref,text,card,True)
    source['card_sentences'].append({'card':'cut-other','sentence':'other-exercise','position':1,'gap_start':5,'gap_end':8,'accepted':['cut'],'valid_alternatives':['run']})
    source['stories'].append({'ref':'retirement-story','slug':'retirement-story','title':'Retirement fixture','kind':'story','cefr_band':'anfaenger','minutes':1})
    source['story_sentences'].append({'story':'retirement-story','sentence':'other-story','idx':0,'paragraph_idx':0})
    rows=build_rows(source)
    ids={c['ref']:r['id'] for c,r in zip(source['cards'],rows['cards'])}
    sids={s['ref']:r['id'] for s,r in zip(source['sentences'],rows['sentences'])}
    ops=[]
    def op(kind,ref):
        return {'op':kind,'card_id':ids[ref],'expect_card':copy.deepcopy(next(c for c in source['cards'] if c['ref']==ref)),'reason':'Synthetic test only'}
    for ref,text in [('cut-old','They cut paper daily.'),('cut-past','They cut paper yesterday.')]:
        old=next(l for l in source['card_sentences'] if l['card']==ref and not l.get('removed_in'))
        sn=next(s for s in source['sentences'] if s['ref']==old['sentence'])
        newref=ref+'-replacement'
        o=op('replace_sentence',ref)
        o.update(sentence_id=sids[sn['ref']],expect_sentence=copy.deepcopy(sn),expect_link=copy.deepcopy(old),
                 sentence={'ref':newref,'text':text,'translation_de':'Sie schneiden Papier.'},
                 tokens=tokens(newref,text,ref,form='cut-past' if ref=='cut-past' else None),
                 link={**copy.deepcopy(old),'sentence':newref,'gap_start':5,'gap_end':8},alternatives_checked=[])
        ops.append(o)
    o=op('card_gloss','run-past_participle');o['translation_de']='gelaufen';ops.append(o)
    ops.append(op('retire_card','cut-other'))
    raw=(json.dumps(source,ensure_ascii=False,indent=2)+'\n').encode()
    patch={'format':'sprachapp.targeted-curation','format_version':1,'source_sha256':hashlib.sha256(raw).hexdigest(),'version':'synthetic-targeted-v1','reviewer':'automated synthetic fixture','operations':ops}
    return source,raw,patch
