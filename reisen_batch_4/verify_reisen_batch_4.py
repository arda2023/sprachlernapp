"""Read-only checks of the delivery; --repo additionally runs current project contracts.

No pip installation, cloud calls, export, staging, or writes to a user database.
"""
import argparse
import ast
import copy
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path
def digest(x): return hashlib.sha256(json.dumps(x,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode('utf8')).hexdigest()


def read(path): return json.loads(path.read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def require(ok, message):
    if not ok: raise ValueError(message)


def check_schema(obj, schema, path='$'):
    # Strict adapter for every validation keyword in the supplied schema. Never ignore unknown keywords.
    known = {'$schema', 'title', 'type', 'required', 'additionalProperties', 'properties',
             'const', 'minLength', 'pattern', 'items', 'minimum', 'minItems', 'maxItems', 'uniqueItems'}
    require(not set(schema) - known, f'{path}: unsupported schema keywords {set(schema)-known}')
    if 'type' in schema:
        types = {'object': dict, 'array': list, 'string': str, 'integer': int}
        require(schema['type'] in types, f'{path}: unsupported schema type')
        require(type(obj) is types[schema['type']], f'{path}: wrong type')
    if 'const' in schema: require(type(obj) is type(schema['const']) and obj == schema['const'], f'{path}: const')
    if 'minimum' in schema: require(obj >= schema['minimum'], f'{path}: minimum')
    if 'minLength' in schema: require(len(obj) >= schema['minLength'], f'{path}: minLength')
    if 'pattern' in schema: require(re.search(schema['pattern'], obj) is not None, f'{path}: pattern')
    if isinstance(obj, dict):
        require(set(schema.get('required', [])) <= set(obj), f'{path}: required fields')
        props = schema.get('properties', {})
        if schema.get('additionalProperties') is False: require(set(obj) <= set(props), f'{path}: extra fields')
        for k,v in obj.items():
            if k in props: check_schema(v, props[k], f'{path}.{k}')
    if isinstance(obj, list):
        if 'minItems' in schema: require(len(obj) >= schema['minItems'], f'{path}: minItems')
        if 'maxItems' in schema: require(len(obj) <= schema['maxItems'], f'{path}: maxItems')
        if schema.get('uniqueItems'): require(len({digest(x) for x in obj}) == len(obj), f'{path}: uniqueItems')
        if 'items' in schema:
            for i,x in enumerate(obj): check_schema(x, schema['items'], f'{path}[{i}]')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--repo', type=Path);args=parser.parse_args()
    here=Path(__file__).resolve().parent;ref=here/'reference'
    d=read(here/'reisen_batch_4.editorial.json');a=d['add'];c=read(ref/'authoring_context.json')
    base=read(ref/'pack.json');registry=read(ref/'registry.json');dic=read(ref/'dictionary_context.json')
    patch=read(here/'deck_display_patch.json');entries=c['entries']
    check_schema(d,read(ref/'editorial_content_v2.schema.json'))
    print('PASS supplied JSON Schema (strict standard-library adapter)')
    require(len(entries)==100 and all(e['authoring_batch']==4 for e in entries),'batch selection')
    require(sha(ref/'pack.json')==d['source_sha256']==c['base_pack']['uploaded_json_sha256'],'base raw hash')
    require(digest(base)==c['base_pack']['canonical_json_sha256'],'base canonical hash')
    require(digest(registry)==d['registry_sha256']==c['registry']['sha256'],'registry hash')
    require(patch['create_sha256']==sha(here/'reisen_batch_4.editorial.json'),'create/patch hash')
    for name,h in read(ref/'manifest.json')['files'].items(): require(sha(ref/name)==h,f'reference hash {name}')
    require(not a['decks'],'existing deck must not be created twice')
    for tab in ['cards','sentences','card_sentences']:
        require(len(a[tab])==100,tab+' count')
    require(len(d['reviews'])==100,'review count')
    for tab in ['lemmas','senses','cards','sentences']:
        newrefs=[r['ref']for r in a[tab]]
        require(len(set(newrefs))==len(newrefs),tab+' duplicate')
        require(not set(newrefs)&{r['ref']for r in base[tab]},tab+' overwrites base')
    allids={r['card_ref']:r for r in read(ref/'all_500_identities.json')}
    reserved={r['form_norm']:r for r in registry['words']if r['lang']=='en'}
    for i,(e,card,dc,dw) in enumerate(zip(entries,a['cards'],a['deck_cards'],a['deck_words']),301):
        require((card['ref'],card['form'],card['sense'],card['translation_de'])==
                (e['card_ref'],e['form'],e['sense_ref'],e['translation_de']),e['form']+' identity')
        require(dc=={'deck':'reisen','card':e['card_ref'],'position':i},'append position')
        require(dw=={'form_norm':e['form_norm'],'deck':'reisen','primary_card':e['card_ref'],'position':i},'word append position')
        reg=reserved[e['form_norm']]
        require(reg['owner_deck_ref']=='reisen' and reg['primary_card_id']==e['card_id'],'ownership')
    require(a['word_aliases']==[{'form_norm':al,'word':e['form_norm']}for e in entries for al in e['ownership_aliases']],'aliases')
    ls={r['ref']:r for r in dic['lemmas']+a['lemmas']};ss={r['ref']:r for r in dic['senses']+a['senses']}
    oldpairs={(r['form'],r['sense'])for r in dic['dictionary_forms']};newpairs={(r['form'],r['sense'])for r in a['dictionary_forms']}
    require(len(newpairs)==len(a['dictionary_forms']) and not oldpairs&newpairs,'form pairs overlap/duplicate')
    require(all(r['sense']in ss and r['gloss_de'].strip()for r in a['dictionary_forms']),'form references')
    require(all(r['lemma']in ls for r in a['senses']),'lemma references')
    pairs=oldpairs|newpairs
    # Same pipeline NLP/model, not blank English. Load only the supplied pure linter and tokenize function.
    if args.repo:
        root=args.repo.resolve();sys.path[:0]=[str(root/'pipeline/src'),str(root/'pipeline/scripts')]
        from sprachpipe.annotate import tokenize
        from sprachpipe.linter import lint_sentence, _nlp
    else:
        spec=importlib.util.spec_from_file_location('supplied_linter',ref/'linter.py')
        m=importlib.util.module_from_spec(spec);sys.modules[spec.name]=m;spec.loader.exec_module(m)
        lint_sentence=m.lint_sentence;_nlp=m._nlp
        tree=ast.parse((ref/'annotate.py').read_text('utf-8'))
        fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='tokenize')
        namespace={'_nlp':_nlp}
        exec(compile(ast.Module(body=[fn],type_ignores=[]),str(ref/'annotate.py'),'exec'),namespace)
        tokenize=namespace['tokenize']
    import spacy
    nlp=_nlp();env=read(ref/'tokenizer_linter_environment.json')
    require(spacy.__version__==env['spacy_version'],'spaCy version differs')
    require(nlp.meta['version']==env['model_version'],'model version differs')
    errors=[];warnings=[];wordcounts=[]
    require(len({s['text']for s in a['sentences']})==100,'duplicate sentence text')
    for s,rev in zip(a['sentences'],d['reviews']):
        ts=[t for t in a['sentence_tokens']if t['sentence']==s['ref']]
        links=[l for l in a['card_sentences']if l['sentence']==s['ref']];require(len(links)==1,'sentence links')
        l=links[0];card=next(r for r in a['cards']if r['ref']==l['card'])
        actual=[{k:t[k]for k in ['idx','surface','start_pos','end_pos']}for t in tokenize(s['text'],nlp=nlp)]
        require(actual==[{k:t[k]for k in ['idx','surface','start_pos','end_pos']}for t in ts],s['ref']+' tokenizer')
        words=[t for t in ts if any(ch.isalpha()for ch in t['surface'])];wordcounts.append(len(words))
        for t in ts:
            if any(ch.isalpha()for ch in t['surface']):
                require(t['sense']in ss and t['lemma']==ss[t['sense']]['lemma'],s['ref']+' binding')
                require((t['surface'].lower(),t['sense'])in pairs,s['ref']+' dictionary gap')
            else: require(t['lemma'] is t['sense'] is t['card'] is None,'punctuation binding')
        targets=[t for t in ts if t['card']==card['ref']]
        require(len(targets)==1,'target token count')
        t=targets[0];require((t['start_pos'],t['end_pos'],t['sense'])==(l['gap_start'],l['gap_end'],card['sense']),'target binding')
        require(l['accepted']==[card['form']] and l['position']==1,'accepted/position')
        require(all(x==x.strip().lower() and x!=card['form']for x in l['valid_alternatives']),'alternatives normalized')
        require(rev['sentence']==s['ref'] and rev['decision']=='approved','review binding')
        require(rev['checked']=={'text':s['text'],'translation_de':s['translation_de'],'tokens_sha256':digest(ts),'links_sha256':digest(links)},'review hashes')
        require(rev['alternatives_checked']==[{'card':card['ref'],'alternative':alt,'text':s['text'][:l['gap_start']]+alt+s['text'][l['gap_end']:]}for alt in l['valid_alternatives']],'substitutions')
        fs=lint_sentence(s['text'],card['form'],l['gap_start'],l['gap_end'],env['linter']['min_zipf'][card['cefr_band']],names=env['names'],max_words=14,max_subclauses=1,nlp=nlp)
        errors.extend((s['ref'],f.rule,f.message)for f in fs if f.level=='error')
        warnings.extend((s['ref'],f.rule,f.message)for f in fs if f.level=='warn')
    require(not errors,str(errors))
    print(f'PASS 100 sentences, {len(a["sentence_tokens"])} tokens, {min(wordcounts)}-{max(wordcounts)} words; 100 review hashes')
    print(f'PASS actual tokenizer and linter: 0 errors, {len(warnings)} frequency warnings')
    print('PASS literal reviewed alternatives:',sum(len(x['valid_alternatives'])for x in a['card_sentences']))
    expected_mapping=read(ref/'combined_display_mapping.json')
    for row,m in zip(patch['rows'],expected_mapping):
        require((row['card_ref'],row['position'],row['original_position'])==(m['card_ref'],m['display_position'],m['original_position']),'mapping drift')
        require(row['original_position']==allids[row['card_ref']]['position'],'original position drift')
    require(len(patch['rows'])==len(expected_mapping)==400,'mapping count')
    work=copy.deepcopy(base)
    for tab,rows in a.items():work.setdefault(tab,[]).extend(copy.deepcopy(rows))
    before=copy.deepcopy(work)
    hashes={'source_sha256':sha(ref/'pack.json'),'create_sha256':sha(here/'reisen_batch_4.editorial.json'),'registry_sha256':digest(registry)}
    # Independent arithmetic preview, not execution of the project's registry validator.
    positions={r['card_ref']:r['position']for r in patch['rows']}
    old_positions={r['card']:r['position']for r in work['deck_cards']if r['deck']=='reisen'}
    for field,h in hashes.items():require(patch[field]==h,'patch binding '+field)
    require(set(positions)==set(old_positions),'complete mapping')
    for r in patch['rows']:
        reg=reserved[r['form_norm']]
        require(r['expected_position']==old_positions[r['card_ref']],'expected position')
        require((reg['primary_card_ref'],reg['owner_deck_ref'],reg['position'])==(r['card_ref'],'reisen',r['original_position']),'registry position')
    for tab in ['deck_cards','deck_words']:
        require(digest([r for r in work[tab]if r['deck']=='reisen'])==patch['expected_before_sha256'][tab],'before hash '+tab)
    after=copy.deepcopy(work)
    for tab,key in [('deck_cards','card'),('deck_words','primary_card')]:
        for r in after[tab]:
            if r['deck']=='reisen':r['position']=positions[r[key]]
    require(work==before,'input mutated')
    for tab,key in [('deck_cards','card'),('deck_words','primary_card')]:
        selected=sorted([r for r in after[tab]if r['deck']=='reisen'],key=lambda r:r['position'])
        require([r['position']for r in selected]==list(range(1,401)),'dense order')
        require([r[key]for r in selected]==[r['card_ref']for r in expected_mapping],'wrong travel order')
        for newrow,oldrow in zip(after[tab],before[tab]):
            if oldrow['deck']=='reisen': newrow['position']=oldrow['position']
    require(after==before,'change outside permitted position fields')
    print('PASS in-memory 400-word display mapping; all other data unchanged')
    if args.repo:
        require(sha(root/c['base_pack']['path'])==d['source_sha256'],'local source drift')
        require(read(root/c['registry']['path'])==registry,'local registry drift')
        from import_editorial_patch import create_content
        from sprachpipe.pack import build_rows
        from sprachpipe.ids import stable_id
        from sprachpipe.deck_display import apply_deck_display_patch as project_apply
        for e in entries:
            lid=stable_id('lemmas',lang='en',lemma=e['lemma'],pos=e['pos'])
            sid=stable_id('senses',lemma_id=lid,sense_key=e['sense_key']or e['proposed_sense_key'])
            cid=stable_id('cards',lang='en',form=e['form'],sense_id=sid)
            require((lid,sid,cid)==(e['lemma_id'],e['sense_id'],e['card_id']),'stable IDs')
        protected=copy.deepcopy((base,d,registry))
        created=create_content(base,d,registry,source_hash=hashes['source_sha256'])
        require((base,d,registry)==protected,'create mutates inputs')
        result=project_apply(created,patch,**hashes)
        expected=copy.deepcopy(created)
        for tab,key in [('deck_cards','card'),('deck_words','primary_card')]:
            for r in expected[tab]:
                if r['deck']=='reisen':r['position']=positions[r[key]]
        require(result==expected,'project reordering differs from position-only expectation')
        rows=build_rows(result)
        for tab,n in [('cards',664),('sentences',1198),('card_sentences',1192),('deck_words',560)]:require(len(rows[tab])==n,tab+' total')
        print('PASS current project create_content, stable IDs, display patch and build_rows: 664 cards / 1198 texts / 1192 links / 560 primary words')
    else:print('NOT RUN: current repository importer/build_rows, SQLite export, staging or device tests')
    if (here/'manifest.json').exists():
        for name,h in read(here/'manifest.json')['files'].items():require(sha(here/name)==h,'delivery hash '+name)
        print('PASS delivery file hashes')
    print('No export, staging, cloud calls or database writes.')


if __name__=='__main__':main()
