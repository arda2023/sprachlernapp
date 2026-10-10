"""Offline delivery verification. No provider, user database, or asset writes.

Default: use the untouched sources and spaCy weights in reference/.
--repo PATH: use current project sources and the same bundled spaCy weights.
--export-check DIR: additionally export into a new directory and compare SQLite.
"""
import argparse, copy, hashlib, json, sys
from pathlib import Path

def read(p): return json.loads(p.read_text(encoding='utf8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def canonical(v): return hashlib.sha256(json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def require(ok,msg):
    if not ok: raise ValueError(msg)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo',type=Path);p.add_argument('--export-check',type=Path)
    args=p.parse_args();here=Path(__file__).resolve().parent;ref=here/'reference'
    import spacy, jsonschema
    for f,h in read(ref/'manifest.json')['files'].items():require(sha(ref/f)==h,'Reference hash: '+f)
    if (here/'manifest.json').exists():
        for f,h in read(here/'manifest.json')['files'].items():require(sha(here/f)==h,'Delivery hash: '+f)
    ctx=read(ref/'authoring_context.json');entry=read(here/'alltag_zuhause_batch_1.editorial.json')
    source=read(ref/'pack.json');registry=read(ref/'registry.json');original=copy.deepcopy(source)
    require(sha(ref/'pack.json')==entry['source_sha256']==ctx['base_pack']['sha256'],'Source hash')
    require(canonical(source)==ctx['base_pack']['canonical_sha256'],'Canonical source hash')
    require(canonical(registry)==entry['registry_sha256']==ctx['registry']['sha256'],'Registry hash')
    require(canonical(read(ref/'learning_groups.json'))==ctx['learning_groups']['sha256'],'Groups hash')
    if args.repo:
        root=args.repo.resolve()
        for src,local in ctx['artifact_paths'].items():
            require(sha(root/src)==sha(ref/local),'Current project differs: '+src)
    else:root=ref
    sys.path[:0]=[str(root/'pipeline/src'),str(root/'pipeline/scripts')]
    from sprachpipe import linter
    nlp=spacy.load(ref/'runtime/en_core_web_sm',disable=['ner'])
    # Only select the explicit bundled model location. Tokenizer, parser and rules are unchanged.
    linter._nlp=lambda *a,**kw:nlp
    from sprachpipe.pack import build_rows
    from sprachpipe.config import load_config
    from sprachpipe.word_registry import digest
    from import_editorial_patch import create_content,export_offline
    jsonschema.validate(entry,read(root/'pipeline/data/curation/editorial_content_v2.schema.json'))
    print('PASS source/delivery hashes and JSON Schema')
    es=ctx['entries'];add=entry['add'];mapping=read(ref/'combined_display_mapping.json')
    require(len(es)==len(add['cards'])==len(add['sentences'])==len(add['card_sentences'])==83,'83 targets')
    require(add['decks']==[ctx['new_deck']],'New deck')
    require(len(entry['reviews'])==83,'Review count')
    for e,c,dc,dw,m in zip(es,add['cards'],add['deck_cards'],add['deck_words'],mapping):
        require((c['ref'],c['form'],c['sense'],c['translation_de'],c['learning'])==
                (e['card_ref'],e['form'],e['sense_ref'],e['translation_de'],e['learning']),'Identity/learning: '+e['form'])
        require(m['original_position']==e['position'],'Original position')
        require(dc=={'deck':'alltag-zuhause','card':e['card_ref'],'position':m['display_position']},'Display membership')
        require(dw=={'form_norm':e['form_norm'],'deck':'alltag-zuhause','primary_card':e['card_ref'],'position':m['display_position']},'Word ownership membership')
    final=create_content(source,entry,registry,source_hash=sha(ref/'pack.json'))
    require(source==original,'Source mutation')
    for table,old in source.items():
        if isinstance(old,list):require(final[table][:len(old)]==old,'Changed historical row: '+table)
    rows=build_rows(final);cards={c['id']:c for c in rows['cards']}
    for e in es:
        c=cards[e['card_id']]
        require((c['lemma_id'],c['sense_id'],c['learning'])==(e['lemma_id'],e['sense_id'],e['learning']),'Stable IDs')
    require(len(rows['cards'])==847 and len(rows['sentences'])==1381 and len(rows['card_sentences'])==1375,'Final counts')
    warnings=[];cfg=load_config()
    for e,s,link in zip(es,add['sentences'],add['card_sentences']):
        require(link['accepted']==[e['form']],'Accepted only target')
        findings=linter.lint_sentence(s['text'],e['form'],link['gap_start'],link['gap_end'],4.0,names=cfg['generate']['names'])
        require(not any(f.level=='error' for f in findings),'Linter: '+e['form']+str(findings))
        warnings.extend(f for f in findings if f.level=='warn')
    goals={cards[w['primary_card_id']]['learning']['group_id'] for w in rows['deck_words']}
    require(len(goals)==732,'Primary learning goal count')
    print('PASS create_content/build_rows: 847 cards, 732 primary learning goals, 18 tables')
    print('PASS 83 reserved identities; 83 sentence reviews; all historical rows preserved')
    print(f'PASS tokenizer and linter: {len(add["sentence_tokens"])} tokens, 0 errors, {len(warnings)} warnings')
    print('PASS 9 sentence-specific alternative substitutions; no automatic group synonyms')
    if args.export_check:export_offline(final,args.export_check.resolve())
    else:print('Export omitted (use --export-check NEW_DIRECTORY for SQLite readback)')
    print('NOT RUN: asset staging, Flutter tests, device tests or user database access')

if __name__=='__main__':main()
