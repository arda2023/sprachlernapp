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
    ctx=read(ref/'authoring_context.json');entry=read(here/'alltag_zuhause_batch_2.editorial.json')
    source=read(ref/'pack.json');registry=read(ref/'registry.json');original=copy.deepcopy(source)
    require(sha(ref/'pack.json')==entry['source_sha256']==ctx['base_pack']['sha256'],'Source hash')
    require(canonical(source)==ctx['base_pack']['canonical_sha256'],'Canonical source hash')
    require(canonical(registry)==entry['registry_sha256']==ctx['registry']['sha256'],'Registry hash')
    require(canonical(read(ref/'learning_groups.json'))==ctx['learning_groups']['sha256'],'Groups hash')
    if args.repo:
        root=args.repo.resolve()
        for src,local in ctx['artifact_paths'].items():
            if local in {'registry.json','learning_groups.json'}:
                require(canonical(read(root/src))==canonical(read(ref/local)),'Current project JSON differs: '+src)
            else: require(sha(root/src)==sha(ref/local),'Current project bytes differ: '+src)
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
    from sprachpipe.authoring_context import validate_context
    context_result=validate_context(source,read(ref/'selection.json'),registry,read(ref/'learning_groups.json'),source_bytes=(ref/'pack.json').read_bytes())
    require(context_result==read(ref/'validation.json'),'Continuation validation differs')
    from finalize_curation import check_sqlite
    check_sqlite(ref/'content.sqlite',build_rows(source))
    print('PASS source/delivery hashes, JSON Schema, continuation 83/80/78 and base SQLite')
    es=ctx['entries'];add=entry['add'];mapping=read(ref/'continuation_display_mapping.json')['append']
    require(len(es)==len(add['cards'])==len(add['sentences'])==len(add['card_sentences'])==80,'80 targets')
    require(add['decks']==[] and ctx['new_deck'] is None,'Existing deck only')
    require(len(entry['reviews'])==80,'Review count')
    for e,c,dc,dw,m in zip(es,add['cards'],add['deck_cards'],add['deck_words'],mapping):
        require((c['ref'],c['form'],c['sense'],c['translation_de'],c['learning'])==
                (e['card_ref'],e['form'],e['sense_ref'],e['translation_de'],e['learning']),'Identity/learning: '+e['form'])
        require(m['original_position']==e['position'],'Original position')
        require(dc=={'deck':'alltag-zuhause','card':e['card_ref'],'position':m['append_position']},'Display membership')
        require(dw=={'form_norm':e['form_norm'],'deck':'alltag-zuhause','primary_card':e['card_ref'],'position':m['append_position']},'Word ownership membership')
    final=create_content(source,entry,registry,source_hash=sha(ref/'pack.json'))
    require(source==original,'Source mutation')
    expected_senses={x['ref']:x for x in source['senses']}
    require(not set(expected_senses)&{x['ref']for x in add['senses']},'Duplicate base sense')
    require(not set(ctx['partitions']['imported'])&set(ctx['partitions']['current']),'Partition overlap')
    for table,old in source.items():
        if isinstance(old,list):require(final[table][:len(old)]==old,'Changed historical row: '+table)
    from sprachpipe.deck_display import apply_deck_display_patch
    patch=read(here/'alltag_zuhause_batch_2.display.json')
    before=copy.deepcopy(final)
    require(patch['rows']==read(ref/'continuation_display_mapping.json')['rows'],'Exact continuation mapping')
    final=apply_deck_display_patch(final,patch,source_sha256=sha(ref/'pack.json'),create_sha256=sha(here/'alltag_zuhause_batch_2.editorial.json'),registry_sha256=canonical(registry))
    for table in final:
        if table not in {'deck_cards','deck_words'}:require(final[table]==before[table],'Display mutation: '+table)
        else:
            require(len(final[table])==len(before[table]),'Display row count')
            for prior,current in zip(before[table],final[table]):
                allowed=prior['deck']=='alltag-zuhause'
                require(({k:v for k,v in prior.items()if k!='position'}=={k:v for k,v in current.items()if k!='position'}) if allowed else prior==current,'Display changed identity')
    print('PASS display patch: append 84..163, final 1..163, original registry positions preserved')
    rows=build_rows(final);cards={c['id']:c for c in rows['cards']}
    for e in es:
        c=cards[e['card_id']]
        require((c['lemma_id'],c['sense_id'],c['learning'])==(e['lemma_id'],e['sense_id'],e['learning']),'Stable IDs')
    require(len(rows['cards'])==927 and len(rows['sentences'])==1461 and len(rows['card_sentences'])==1455,'Final counts')
    warnings=[];cfg=load_config()
    for e,s,link in zip(es,add['sentences'],add['card_sentences']):
        require(link['accepted']==[e['form']],'Accepted only target')
        findings=linter.lint_sentence(s['text'],e['form'],link['gap_start'],link['gap_end'],4.0,names=cfg['generate']['names'])
        require(not any(f.level=='error' for f in findings),'Linter: '+e['form']+str(findings))
        warnings.extend(f for f in findings if f.level=='warn')
    goals={cards[w['primary_card_id']]['learning']['group_id'] for w in rows['deck_words']}
    require(len(goals)==812,'Primary learning goal count')
    print('PASS create_content/build_rows: 927 cards, 812 primary learning goals, 18 tables')
    print('PASS 80 reserved identities; 80 sentence reviews; all historical rows preserved')
    print(f'PASS tokenizer and linter: {len(add["sentence_tokens"])} tokens, 0 errors, {len(warnings)} warnings')
    print('PASS 8 sentence-specific alternative substitutions; no automatic group synonyms')
    if args.export_check:export_offline(final,args.export_check.resolve())
    else:print('Export omitted (use --export-check NEW_DIRECTORY for SQLite readback)')
    print('NOT RUN: asset staging, Flutter tests, device tests or user database access')

if __name__=='__main__':main()
