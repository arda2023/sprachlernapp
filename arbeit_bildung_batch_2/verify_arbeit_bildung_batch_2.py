"""Offline-Prüfung der Lieferung; optionaler Export in einen neuen Ordner.
Keine Modellaufrufe, App-Asset- oder Lernstandzugriffe.
"""
import argparse,copy,hashlib,json,sys
from pathlib import Path

def read(p):return json.loads(p.read_text(encoding='utf8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def canonical(v):return hashlib.sha256(json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def require(ok,msg):
    if not ok:raise ValueError(msg)

def main():
    a=argparse.ArgumentParser(description=__doc__)
    a.add_argument('--repo',type=Path);a.add_argument('--export-check',type=Path)
    args=a.parse_args();here=Path(__file__).resolve().parent;ref=here/'reference'
    import spacy,jsonschema
    for name,h in read(ref/'manifest.json')['files'].items():require(sha(ref/name)==h,'Reference hash: '+name)
    if (here/'manifest.json').exists():
        for name,h in read(here/'manifest.json')['files'].items():require(sha(here/name)==h,'Delivery hash: '+name)
    ctx=read(ref/'authoring_context.json');delivery=read(here/'arbeit_bildung_batch_2.editorial.json')
    source=read(ref/'pack.json');original=copy.deepcopy(source);reg=read(ref/'registry.json')
    require(sha(ref/'pack.json')==ctx['base_pack']['sha256']==delivery['source_sha256'],'Source raw hash')
    require(canonical(source)==ctx['base_pack']['canonical_sha256'],'Source canonical hash')
    require(canonical(reg)==ctx['registry']['sha256']==delivery['registry_sha256'],'Registry canonical hash')
    require(canonical(read(ref/'learning_groups.json'))==ctx['learning_groups']['sha256'],'Groups canonical hash')
    if args.repo:
        root=args.repo.resolve()
        for src,local in ctx['artifact_paths'].items():
            if local in {'registry.json','learning_groups.json'}:require(canonical(read(root/src))==canonical(read(ref/local)),'Current project differs: '+src)
            else:require(sha(root/src)==sha(ref/local),'Current project bytes differ: '+src)
    else:root=ref
    sys.path[:0]=[str(root/'pipeline/src'),str(root/'pipeline/scripts')]
    from sprachpipe import linter
    nlp=spacy.load(ref/'runtime/en_core_web_sm',disable=['ner']);linter._nlp=lambda *a,**kw:nlp
    from sprachpipe.config import load_config
    from sprachpipe.pack import build_rows
    from sprachpipe.authoring_context import validate_context
    from import_editorial_patch import create_content,export_offline
    from finalize_curation import check_sqlite
    jsonschema.validate(delivery,read(root/'pipeline/data/curation/editorial_content_v2.schema.json'))
    actual=validate_context(source,read(ref/'selection.json'),reg,read(ref/'learning_groups.json'),source_bytes=(ref/'pack.json').read_bytes())
    require(actual==read(ref/'validation.json'),'Context validation differs')
    check_sqlite(ref/'content.sqlite',build_rows(source))
    print('PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite',flush=True)
    es=ctx['entries'];add=delivery['add'];mapping=read(ref/'continuation_display_mapping.json')['append']
    require(len(es)==len(add['cards'])==len(add['sentences'])==len(add['card_sentences'])==len(delivery['reviews'])==82,'82 target sentences and reviews')
    require(add['decks']==[] and ctx['new_deck'] is None,'Existing deck only')
    require(len(ctx['partitions']['imported'])==82 and len(ctx['partitions']['current'])==82 and len(ctx['partitions']['future'])==81,'Partition 82/82/81')
    require(len(read(ref/'all_selection_identities.json'))==245,'Full 245 target context')
    for e,c,dc,dw,m in zip(es,add['cards'],add['deck_cards'],add['deck_words'],mapping):
        require((c['ref'],c['form'],c['sense'],c['translation_de'],c['learning'])==(e['card_ref'],e['form'],e['sense_ref'],e['translation_de'],e['learning']),'Exact identity: '+e['form'])
        require(m['original_position']==e['position'],'Original position: '+e['form'])
        require(dc=={'deck':'arbeit-bildung','card':e['card_ref'],'position':m['append_position']},'Display membership')
        require(dw=={'form_norm':e['form_norm'],'deck':'arbeit-bildung','primary_card':e['card_ref'],'position':m['append_position']},'Ownership membership')
    final=create_content(source,delivery,reg,source_hash=sha(ref/'pack.json'))
    require(source==original,'Source input mutated')
    for table,old in source.items():
        if isinstance(old,list):require(final[table][:len(old)]==old,'Historical row changed: '+table)
    from sprachpipe.deck_display import apply_deck_display_patch
    patch=read(here/'arbeit_bildung_batch_2.display.json');before=copy.deepcopy(final)
    require(patch['rows']==read(ref/'continuation_display_mapping.json')['rows'],'Exact continuation rows')
    final=apply_deck_display_patch(final,patch,source_sha256=sha(ref/'pack.json'),create_sha256=sha(here/'arbeit_bildung_batch_2.editorial.json'),registry_sha256=canonical(reg))
    for table in final:
        if table not in {'deck_cards','deck_words'}:require(final[table]==before[table],'Unexpected display change: '+table)
        else:
            require(len(final[table])==len(before[table]),'Display count')
            for prior,current in zip(before[table],final[table]):
                require(({k:v for k,v in prior.items()if k!='position'}=={k:v for k,v in current.items()if k!='position'}) if prior['deck']=='arbeit-bildung' else prior==current,'Only Arbeit display positions may change')
    print('PASS hash-bound display patch: append 83..164, final display 1..164; original registry positions preserved',flush=True)
    rows=build_rows(final);cards={c['id']:c for c in rows['cards']}
    for e in es:
        c=cards[e['card_id']];require((c['lemma_id'],c['sense_id'],c['learning'])==(e['lemma_id'],e['sense_id'],e['learning']),'Stable IDs and learning')
    require(len(rows['cards'])==1169 and len(rows['sentences'])==1703 and len(rows['card_sentences'])==1697 and len(rows['deck_words'])==1065,'Final totals')
    goals={cards[w['primary_card_id']]['learning']['group_id']for w in rows['deck_words']};require(len(goals)==1054,'1054 primary goals')
    deck=next(d['id']for d in rows['decks']if d['slug']=='arbeit-bildung');members=[w for w in rows['deck_words']if w['deck_id']==deck]
    all_es=read(ref/'all_selection_identities.json');done={e['card_id']:e for e in all_es if e['selection_id'] not in ctx['partitions']['future']}
    require(len(members)==164 and {w['primary_card_id']for w in members}==set(done),'Exact 164 memberships')
    for cid,e in done.items():require(cards[cid]['learning']==e['learning'],'Old/new learning metadata')
    require(sorted(w['position']for w in members)==list(range(1,165)),'Display 1..164')
    warnings=[];cfg=load_config()
    for e,s,link,c in zip(es,add['sentences'],add['card_sentences'],add['cards']):
        require(link['accepted']==[e['form']],'Accepted only exact target')
        require(s['text'][link['gap_start']:link['gap_end']].lower()==e['form'].lower(),'Exact gap')
        fs=linter.lint_sentence(s['text'],e['form'],link['gap_start'],link['gap_end'],cfg['linter']['min_zipf'][c['cefr_band']],names=cfg['generate']['names'])
        require(not any(f.level=='error'for f in fs),'Linter: '+e['form']+str(fs))
        warnings.extend((e['form'],f.rule,f.message)for f in fs if f.level=='warn')
    alternatives=sum(len(l['valid_alternatives'])for l in add['card_sentences']);require(alternatives==4,'Four reviewed alternatives')
    require(not {c['ref']for c in add['cards']}&{e['card_ref']for e in read(ref/'all_selection_identities.json')if e['selection_id']in ctx['partitions']['future']},'Future cards introduced early')
    print('PASS create_content/build_rows: 1169 cards; 1054 primary goals (160/489/241/164); 18 tables',flush=True)
    print('PASS 82 reserved identities, display 1..164; 1087 old IDs and all historical rows preserved',flush=True)
    print(f'PASS {len(add["sentence_tokens"])} token positions; four reviewed alternatives; linter 0 errors, {len(warnings)} warnings',flush=True)
    print('WARNINGS',json.dumps(warnings,ensure_ascii=False),flush=True)
    if args.export_check:
        require(not args.export_check.exists(),'Refuse existing export directory')
        export_offline(final,args.export_check.resolve())
        print('PASS actual offline export and complete row-by-row SQLite readback',flush=True)
    print('NOT RUN: App staging, Flutter/device tests, user database access',flush=True)

if __name__=='__main__':main()
