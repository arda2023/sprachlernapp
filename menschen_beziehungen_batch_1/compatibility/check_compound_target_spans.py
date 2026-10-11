"""Meaningful checks against the real tokenizer, using supplied offline model weights."""
import argparse,sys
from pathlib import Path

def main():
 a=argparse.ArgumentParser();a.add_argument('--source',type=Path,required=True);a.add_argument('--model',type=Path,required=True);args=a.parse_args()
 sys.path.insert(0,str(args.source/'pipeline/src'))
 import spacy
 from sprachpipe.annotate import tokenize
 nlp=spacy.load(args.model,disable=['ner']);checks=0
 for form,text in [('sister-in-law','My sister-in-law is here.'),('son-in-law','Our son-in-law is coming.'),('open-minded','They are open-minded.')]:
  start=text.index(form);end=start+len(form);ts=tokenize(text,nlp,lexical_spans=[(start,end)])
  target=[t for t in ts if t['start_pos']==start and t['end_pos']==end]
  assert len(target)==1 and target[0]['surface']==form and target[0]['is_word']
  assert [t['idx']for t in ts]==list(range(len(ts)))
  assert all(text[t['start_pos']:t['end_pos']]==t['surface']for t in ts)
  assert ''.join(text[t['start_pos']:t['end_pos']]for t in ts).replace(' ','')==text.replace(' ','')
  checks+=1
 for text in ["My father's book is here.",'An open-minded sister-in-law is here.','We practise speaking English.']:
  doc=nlp(text);old=[{'idx':t.i,'start_pos':t.idx,'end_pos':t.idx+len(t.text),'surface':t.text,'pos':t.pos_,'is_word':any(c.isalpha()for c in t.text)}for t in doc]
  assert tokenize(text,nlp)==old;checks+=1
 text='An open-minded sister-in-law is here.'
 spans=[(text.index(f),text.index(f)+len(f))for f in ['open-minded','sister-in-law']]
 ts=tokenize(text,nlp,lexical_spans=spans)
 assert [t['surface']for t in ts]==['An','open-minded','sister-in-law','is','here','.'];checks+=1
 for spans in [[(-1,2)],[(3,99)],[(4,8)],[(3,14),(8,14)],[(35,36)],[(3,3)]]:
  try:tokenize(text,nlp,lexical_spans=spans)
  except (ValueError,TypeError):checks+=1
  else:raise AssertionError(('invalid span accepted',spans))
 text='A friend is here.';start=text.index('friend')
 assert tokenize(text,nlp,lexical_spans=[(start,start+6)])==tokenize(text,nlp);checks+=1
 print(f'PASS {checks} tokenizer checks: compounds, offsets, default compatibility, malformed spans')
if __name__=='__main__':main()
