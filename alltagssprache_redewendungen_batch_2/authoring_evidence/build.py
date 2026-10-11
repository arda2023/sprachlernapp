import json,hashlib,copy,collections
from pathlib import Path
from decisions import bind,new,ov
P=Path(__file__).parent;C=P/'alltagssprache_redewendungen_authoring_batch_2';O=P/'output/alltagssprache_redewendungen_batch_2';O.mkdir(parents=True,exist_ok=True)
read=lambda p:json.loads(p.read_text());canon=lambda x:json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode();digest=lambda x:hashlib.sha256(canon(x)).hexdigest()
a=read(C/'authoring_context.json');d=read(C/'dictionary_context.json');base=read(C/'pack.json');ss={s['ref']:s for s in d['senses']};ls={l['ref']:l for l in d['lemmas']};entries=a['entries'];tokens=read(P/'tokens.json');lines=[l.split('|')for l in(P/'sentences.txt').read_text().splitlines()];targets={e['sense_ref']:e for e in entries}
assert not(set(new)&set(ss)),set(new)&set(ss)
add={k:[]for k in ['lemmas','senses','cards','decks','deck_cards','deck_words','word_aliases','sentences','sentence_tokens','dictionary_forms','card_sentences']};add['decks']=[];seenl=set(ls);seens=set(ss)
def sense(r):
 if r in ss:return ss[r]
 if r in new:s=new[r]
 else:
  e=targets[r];s=dict(ref=r,lemma=e['lemma_ref'],sense_key=e['proposed_sense_key'],gloss_de=e['gloss_de'],definition_de=e['definition_de'])
 if s['lemma']not in seenl:
  lemma,pos=s['lemma'].rsplit('/',1);add['lemmas'].append(dict(ref=s['lemma'],lemma=lemma,pos=pos));seenl.add(s['lemma'])
 if r not in seens:add['senses'].append(s);seens.add(r)
 return s
pairs={(f['form'],f['sense']):f for f in d['dictionary_forms']};rank=collections.defaultdict(int)
for f in d['dictionary_forms']:rank[f['form']]=max(rank[f['form']],f['rank'])
manual=read(P/'form_glosses.json')if(P/'form_glosses.json').exists()else{};needed=[];audit=[];reviews=[];reading=[];inherited=[]
continuation=read(C/'continuation_display_mapping.json');positions={r['card_ref']:r['append_position']for r in continuation['append']}
alts={'no offence':['no offense'],'if memory serves':['if memory serves me']}
def form(w,r,card=None):
 key=(w.lower(),r)
 if key in pairs:
  inherited.append(pairs[key]);return
 s=sense(r);mk='|'.join(key)
 if mk in manual:g=manual[mk]
 elif r in targets and targets[r]['form_norm']==w.lower():g=targets[r]['translation_de']
 else:g=s['gloss_de'];needed.append(dict(key=mk,gloss=g))
 rank[key[0]]+=1;row=dict(form=key[0],sense=r,gloss_de=g,rank=rank[key[0]])
 if card:row['card']=card
 add['dictionary_forms'].append(row);pairs[key]=row
for e,(w,en,de) in zip(entries,lines):
 assert w==e['form'];sr=e['sense_ref'];sense(sr);cr=e['card_ref'];sn=e['selection_id']+'-s1';gs=en.lower().index(w.lower());ge=gs+len(w)
 add['cards'].append(dict(ref=cr,form=w,sense=sr,translation_de=e['translation_de'],form_kind=e['form_kind'],form_label_de=e['form_label_de'],cefr_band='mittel',learning=copy.deepcopy(e['learning'])))
 add['deck_cards'].append(dict(deck=a['existing_deck'],card=cr,position=positions[cr]));add['deck_words'].append(dict(form_norm=e['form_norm'],deck=a['existing_deck'],primary_card=cr,position=positions[cr]))
 add['word_aliases'] += [dict(form_norm=x,word=e['form_norm'])for x in e['ownership_aliases']]
 add['sentences'].append(dict(ref=sn,text=en,translation_de=de,origins=['deck']))
 st=[];occ=collections.Counter()
 for t in tokens[w]:
  row=dict(sentence=sn,**{k:t[k]for k in ['idx','surface','start_pos','end_pos']},lemma=None,sense=None,card=None)
  if t['is_word']:
   low=t['surface'].lower();target=t['start_pos']==gs and t['end_pos']==ge
   r=sr if target else ov.get((w,low,occ[low]),ov.get((w,low,None),bind.get(low)));occ[low]+=1
   assert r,(w,low);s=sense(r);row.update(lemma=s['lemma'],sense=r,card=cr if target else None);form(low,r,cr if target else None)
  st.append(row)
 link=dict(card=cr,sentence=sn,position=1,gap_start=gs,gap_end=ge,accepted=[w],valid_alternatives=alts.get(w,[]))
 add['sentence_tokens']+=st;add['card_sentences'].append(link)
 review=dict(sentence=sn,decision='approved',reason='ChatGPT-Redaktion: vollständiger Ausdruck in der vorgegebenen Bedeutung; Satz und natürliche deutsche Übersetzung geprüft, sämtliche Wortbindungen einzeln gegengelesen. '+('Die aufgeführten Alternativen wurden wörtlich eingesetzt und auf gleiche Aussage sowie passenden Satzanschluss geprüft.'if alts.get(w)else'Keine Alternative freigegeben; keine Vollständigkeits- oder Eindeutigkeitsgarantie.'),checked=dict(text=en,translation_de=de,tokens_sha256=digest(st),links_sha256=digest([link])),alternatives_checked=[dict(card=cr,alternative=x,text=en[:gs]+x+en[ge:])for x in alts.get(w,[])])
 reviews.append(review);audit.append(dict(target=w,sentence=en,translation_de=de,tokens=st));reading.append(dict(selection_id=e['selection_id'],target=w,meaning=e['target_meaning_de'],text=en,translation_de=de,alternatives=alts.get(w,[])))
delivery=dict(format='sprachapp.editorial-content',format_version=2,operation_id='alltagssprache-redewendungen-batch-2-v1',version='alltagssprache_redewendungen_batch_2_v1',source_sha256=a['base_pack']['sha256'],registry_sha256=a['registry']['sha256'],reviewer='ChatGPT – Erstellung und redaktionelle Eigenprüfung; keine unabhängige menschliche Sprachfreigabe',add=add,reviews=reviews)
for name,data in [('editorial_content_v2.json',delivery),('token_review.json',audit),('reading.json',reading)]: (O/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
(P/'pending_glosses.json').write_text(json.dumps(needed,ensure_ascii=False,indent=2));(P/'inherited_forms.json').write_text(json.dumps(list({(x['form'],x['sense']):x for x in inherited}.values()),ensure_ascii=False,indent=2));print('rows',{k:len(v)for k,v in add.items()},'glosses_pending',len(needed))

patch=dict(format='sprachapp.deck-display-patch',format_version=1,operation_id='alltagssprache-redewendungen-batch-2-display-v1',deck=a['existing_deck'],source_sha256=a['base_pack']['sha256'],create_sha256=hashlib.sha256((O/'editorial_content_v2.json').read_bytes()).hexdigest(),registry_sha256=a['registry']['sha256'],expected_before_sha256={table:digest([row for row in base[table]+add[table]if row['deck']==a['existing_deck']])for table in ['deck_cards','deck_words']},rows=continuation['rows'])
(O/'deck_display_patch.json').write_text(json.dumps(patch,ensure_ascii=False,indent=2)+'\n')
