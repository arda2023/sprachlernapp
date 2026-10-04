"""Read-only checks for corrections.json. Python standard library only.
Windows/macOS: python verify_editorial_patch.py --source /path/to/original/pack.json
This does not apply the patch, annotate words or certify linguistic quality.
"""
import argparse,collections,hashlib,json,re,unicodedata
from pathlib import Path

def sha(obj):
    return hashlib.sha256(json.dumps(obj,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def sid(table,*values):
    return hashlib.sha256('\x1f'.join([table]+[unicodedata.normalize('NFC',str(v)) for v in values]).encode()).digest()[:16].hex()

def check(source, patch):
    raw=Path(source).read_bytes();p=json.loads(raw)
    exact=hashlib.sha256(raw).hexdigest()==patch['source']['sha256']
    assert exact or sha(p)==patch['source']['canonical_json_sha256'],'Source pack differs'
    assert p['release']==patch['source']['release'],'Release differs'
    assert {k:len(v) for k,v in p.items() if isinstance(v,list)}==patch['source']['counts'],'Counts differ'
    cards={x['ref']:x for x in p['cards']};senses={x['ref']:x for x in p['senses']};lemmas={x['ref']:x for x in p['lemmas']};ss={s['ref']:s for s in p['sentences']}
    assert len(cards)==len(p['cards']) and len(ss)==len(p['sentences'])
    links={(l['card'],l['sentence']):l for l in p['card_sentences']}
    assert len(links)==len(p['card_sentences'])
    assert set(l['sentence'] for l in p['card_sentences'])==set(ss)
    for ref in cards:
        assert sorted(l['position'] for l in p['card_sentences'] if l['card']==ref)==[1,2,3]
    for l in p['card_sentences']:
        assert ss[l['sentence']]['text'][l['gap_start']:l['gap_end']].casefold()==cards[l['card']]['form'].casefold()
    for t in p['sentence_tokens']:
        assert ss[t['sentence']]['text'][t['start_pos']:t['end_pos']]==t['surface']
    touched=set();result_text={k:s['text'] for k,s in ss.items()}
    for op in patch['sentence_operations']:
        k=(op['card_ref'],op['sentence_ref']);assert k not in touched,'Duplicate operation';touched.add(k)
        l=links[k];s=ss[k[1]];c=cards[k[0]];sense=senses[c['sense']];lemma=lemmas[sense['lemma']]
        lid=sid('lemmas',p['lang'],lemma['lemma'],lemma['pos']);se=sid('senses',lid,sense['sense_key']);ci=sid('cards',p['lang'],c['form'],se)
        assert ci==op['card_id'] and se==op['sense_id'] and lid==op['lemma_id']
        actual={f:s[f] for f in ('text','translation_de')}
        actual.update({f:l.get(f,[]) for f in ('gap_start','gap_end','accepted','valid_alternatives')})
        assert actual==op['expect'],op['op_id']+' precondition'
        assert sha(s)==op['expect_sentence_row_sha256'] and sha(l)==op['expect_link_row_sha256']
        new=op['new'];assert new['accepted']==l['accepted']
        assert new['text'][new['gap_start']:new['gap_end']].casefold()==c['form'].casefold()
        assert op['old_sentence_id']==sid('sentences',p['lang'],s['text'])
        assert op['new_sentence_id']==sid('sentences',p['lang'],new['text'])
        assert op['new_card_sentence_id']==sid('card_sentences',ci,op['new_sentence_id'])
        if 'text' in op['changed_fields']:
            assert len(re.findall(r'(?<!\w)'+re.escape(c['form'])+r'(?!\w)',new['text'],re.I))==1
            assert len([w for w in new['text'].split() if re.search(r'\w',w)])<=14
            assert re.search(r'[.?!]["”’\x27)\]]*\s*$',new['text'])
        a=new['valid_alternatives'];assert len(a)==len(set(a))
        for alt in a:
            assert isinstance(alt,str) and alt and alt==unicodedata.normalize('NFC',alt).lower().replace('’',"'")
            assert alt!=c['form'].casefold()
        result_text[k[1]]=new['text']
    assert len(set(result_text.values()))==len(result_text),'Duplicate proposed sentence texts'
    metakeys=set()
    for op in patch['metadata_operations']:
        k=(op['table'],op['ref'],op['field']);assert k not in metakeys;metakeys.add(k)
        table=cards if op['table']=='cards' else senses
        assert table[op['ref']][op['field']]==op['expect']
        assert op['field'] in ('translation_de','gloss_de')
    for op in patch['card_recommendations']:
        assert op['card_ref'] in cards
        assert op['status']=='recommendation_not_applied'
    return {'source_sha256_exact':exact,'cards':len(cards),'sentences':len(ss),'original_alternatives':sum(len(l.get('valid_alternatives',[])) for l in p['card_sentences']),'sentence_operations':len(touched),'metadata_operations':len(metakeys),'unchanged_source':True,'new_english_annotation_status':'not_done','spacy_zipf_and_runtime_tests':'not_run'}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',required=True)
    parser.add_argument('--patch',default=str(Path(__file__).with_name('corrections.json')))
    args=parser.parse_args()
    try:
        result=check(args.source,json.loads(Path(args.patch).read_text(encoding='utf-8')))
    except (AssertionError,ValueError,KeyError,OSError) as exc:
        print('VALIDATION FAILED:',exc);raise SystemExit(1)
    print('VALIDATION OK')
    print(json.dumps(result,ensure_ascii=False,indent=2))
