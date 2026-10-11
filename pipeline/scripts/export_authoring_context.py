"""Export/verify an offline handoff using the Reisen context layout and import path.

Never creates content rows, practice sentences, or staged assets.
"""
import argparse
import hashlib
import importlib.metadata
import json
import platform
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT/'pipeline/src'), str(ROOT/'pipeline/scripts')]
from sprachpipe.authoring_context import validate_context, require, prepare_continuation, partition_batches
from sprachpipe.word_registry import digest
from sprachpipe.pack import build_rows


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2)+'\n').encode('utf8')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    return json.loads(path.read_bytes())


def mapping(entries, batch):
    selected = sorted((e for e in entries if e['authoring_batch'] <= batch), key=lambda e:e['position'])
    return [{'card_ref':e['card_ref'],'form_norm':e['form_norm'],'original_position':e['position'],
             'display_position':i,'authoring_batch':e['authoring_batch']} for i,e in enumerate(selected,1)]


def export(selection_path, output, batch):
    from sprachpipe.config import load_config
    from sprachpipe.linter import _nlp
    require(not output.exists(), 'output already exists')
    selection = read(selection_path)
    if selection.get('format') == 'sprachapp.form-selection':
        require(batch == selection['authoring_batch'], 'form snapshot batch mismatch')
        return export_form_context(selection_path, output)
    continuation = selection.get('continuation')
    if not continuation:
        require(batch == 1, 'later batches require a continuation snapshot')
    if continuation:
        require(continuation['authoring_batch'] == batch, 'snapshot batch mismatch')
        require(read(ROOT/continuation['original_selection_path']) == continuation['original_selection'], 'original selection differs from repository')
    manifest_path = ROOT/'assets/content/en/content.manifest.json'
    staged = read(manifest_path)
    sqlite_path = ROOT/staged['source']['path']
    source_path = sqlite_path.with_name('pack.json')
    require(source_path == ROOT/selection['source_pack']['path'], 'selection is not based on staged manifest')
    require(sha(sqlite_path.read_bytes()) == staged['sha256'], 'staged source SQLite hash')
    asset = manifest_path.with_name('content.sqlite')
    require(sha(asset.read_bytes()) == staged['sha256'], 'actual staged SQLite hash')
    source_raw = source_path.read_bytes(); pack = json.loads(source_raw)
    require(pack['release']['version'] == staged['version'], 'staged release version')
    registry = read(ROOT/selection['registry_path']); groups = read(ROOT/selection['learning_groups_path'])
    if continuation:
        require(registry['source_sqlite_sha256']==staged['sha256'],'continuation SQLite hash')
    result = validate_context(pack,selection,registry,groups,source_bytes=source_raw)
    batch_entries = [e for e in selection['entries'] if e['authoring_batch'] == batch]
    require(bool(batch_entries), 'empty batch')
    cfg = load_config(); nlp = _nlp()
    env = {'python':platform.python_version(),'platform':platform.platform(),
           'packages':{k:importlib.metadata.version(k) for k in ('spacy','en_core_web_sm','wordfreq','PyYAML','python-dotenv','google-genai','jsonschema')},
           'model':'en_core_web_sm','model_version':nlp.meta['version'],'disabled_pipes':list(nlp.disabled),
           'linter':cfg['linter'],'names':cfg['generate']['names'],
           'offline_model_path':'runtime/en_core_web_sm','sources':'pipeline/src/sprachpipe',
           'runtime_note':'Python packages are specified by pyproject.toml and requirements.lock; installed interpreter/venv not bundled. Model data bundled. No network or provider access needed for tokenize/lint.'}
    context = {'format':'sprachapp.authoring-context','format_version':2,'authoring_batch':batch,
               'partitions':partition_batches(selection['entries'], batch),
               'base_pack':selection['source_pack'],'registry':{'path':'registry.json','sha256':digest(registry)},
               'learning_groups':{'path':'learning_groups.json','sha256':digest(groups)},
               'artifact_paths':{selection['source_pack']['path']:'pack.json',staged['source']['path']:'content.sqlite',
                   selection['registry_path']:'registry.json',selection['learning_groups_path']:'learning_groups.json'},
               'entries':batch_entries,'new_deck':{'ref':selection['owner_deck_ref'],'slug':selection['owner_deck_ref'],'title_de':selection['title_de']},
               'import_contract':{'format':'sprachapp.editorial-content','format_version':2,'content_schema_version':pack['release']['schema_version'],
                   'source_sha256':sha(source_raw),'registry_sha256':digest(registry),
                   'importer':'pipeline/scripts/import_editorial_patch.py','schema':'pipeline/data/curation/editorial_content_v2.schema.json',
                   'learning_required':True,'new_card_sentence_count':1,'existing_rows':'preserve byte-equivalent JSON values',
                   'alternatives':'Only individually sentence-reviewed valid_alternatives. Ownership aliases and learning-group members never become accepted answers automatically.',
                   'positions':'Original registry/selection positions are immutable. First batch creates its new deck and memberships at display positions in combined_display_mapping.json. Future batches append and use existing hash-bound --display-patch.',
                   'learning_order':'Authoring batches and editorial positions do not prescribe runtime learning order. Existing group-aware topic/contrast selection decides introductions.',
                   'definitions':'Use exact target_meaning_de and translation_de. Reused sense rows stay untouched, even when old glosses are inflected. Proposed senses use definition_de. Do not duplicate existing lemma/sense rows.',
                   'scope':'Only entries of this authoring_batch; other identities are reserved, not to be authored yet.'}}
    payload = {'pack.json':source_raw,'content.sqlite':sqlite_path.read_bytes(),'staged_manifest.json':manifest_path.read_bytes(),
               'registry.json':encode(registry),'learning_groups.json':encode(groups),'selection.json':encode(selection),
               'all_selection_identities.json':encode(selection['entries']),'authoring_context.json':encode(context),
               'dictionary_context.json':encode({'base_pack_canonical_sha256':digest(pack),**{k:pack[k] for k in ('lemmas','senses','dictionary_forms')}}),
               'combined_display_mapping.json':encode(mapping(selection['entries'],batch)),
               'all_batch_display_mappings.json':encode({str(b):mapping(selection['entries'],b) for b in sorted({e['authoring_batch'] for e in selection['entries']})}),
               'tokenizer_linter_environment.json':encode(env),'validation.json':encode(result)}
    if continuation:
        context['new_deck'] = None
        context['existing_deck'] = selection['owner_deck_ref']
        context['partitions'] = continuation['partitions']
        context['import_contract']['positions'] = ('Append only current targets at append_position from continuation_display_mapping.json. '
            'Then use the existing --display-patch contract with rows from that mapping. Bind to the actual source/create raw hashes, '
            'registry canonical hash and complete pre-patch deck_cards/deck_words hashes. Do not create another deck or reorder the base pack.')
        current_senses = {s['ref']:s for s in pack['senses']}
        context['sense_availability'] = {e['card_ref']:{'action':'reuse' if e['sense_ref'] in current_senses else 'create',
            'sense':current_senses.get(e['sense_ref']), 'reserved_definition':e['target_meaning_de']} for e in batch_entries}
        context['definition_equivalences'] = continuation.get('definition_equivalences',{})
        payload['authoring_context.json'] = encode(context)
        payload['original_selection.json'] = encode(continuation['original_selection'])
        payload['continuation_display_mapping.json'] = encode(continuation['display_plan'])
    # Explicit source whitelist, no .env, login files, caches, user DB or run logs.
    sources = list((ROOT/'pipeline/src/sprachpipe').glob('*.py'))
    sources += [ROOT/p for p in ('pipeline/scripts/import_editorial_patch.py','pipeline/scripts/finalize_curation.py',
        'pipeline/scripts/export_authoring_context.py','pipeline/data/curation/editorial_content_v2.schema.json',
        'pipeline/config.yaml','pipeline/pyproject.toml','pipeline/requirements.lock',
        'AGENTS.md','PRODUCT.md','docs/content-schema.md','docs/pipeline.md','docs/learning-groups-v1.md')]
    for p in sources: payload[p.relative_to(ROOT).as_posix()] = p.read_bytes()
    model = Path(nlp.path)
    for p in model.rglob('*'):
        if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc':
            payload['runtime/en_core_web_sm/'+p.relative_to(model).as_posix()] = p.read_bytes()
    payload['README.txt'] = f'''{selection['title_de']} – Authoring-Gruppe {batch}, {len(batch_entries)} von {len(selection['entries'])} Zielen
Basis: {pack['release']['version']}, Schema {pack['release']['schema_version']}, Rohbyte-SHA256 {sha(source_raw)}.
Nur die entries in authoring_context.json redigieren. Es wurden noch keine Sätze erstellt.
Alle Identitäten, Ausschlüsse, Definitionen und Entscheidungen stehen in selection.json.
Das vollständige aktuelle Wörterbuch steht in dictionary_context.json und pack.json.
Gruppen sind unabhängig vom Wortbesitz: learning_groups.json enthält unveränderte
Altentscheidungen und separat reservierte neue Köpfe. Der historische Hash in
existing beschreibt die frühere Umstellung; der äußere Hash bindet an diese Basis.
Schema {pack['release']['schema_version']} verlangt cards.learning unverändert aus dem jeweiligen Auswahlziel.
Keine Variante/Synonymgruppe automatisch als gültige Lückenantwort freigeben.
Die vorhandene Satzprüfung (reviewer, reviews, Token-/Linkhashes und geprüfte
Alternativen) bleibt Teil des Imports; keine zusätzliche formelle Freigabe nötig.

Ergebnisformat: editorial_content_v2.schema.json im Pfad pipeline/data/curation/.
Genau ein neuer fester Übungssatz je ausgewählter Karte, vollständige Tokenabdeckung,
Wörterbuchglossen für jedes Wort, getrennte Kontextprüfung für Story-Lernziele.
Keine bestehenden Zeilen ändern. Benötigte neue Begleitwort-Senses explizit definieren.
Neue Karten referenzieren neue oder wiederverwendete Senses; keine alten Senses ändern.
Die erste Gruppe legt ausschließlich den neuen Stapel {selection['owner_deck_ref']} an.
combined_display_mapping.json enthält die Mitgliedschaftspositionen dieser Gruppe.
Die Redaktion darf weder Originalpositionen noch stabile IDs umnummerieren.
Lernreihenfolge bestimmt später die App, nicht die Reihenfolge in dieser ZIP.

Tokenizer: sprachpipe.annotate.tokenize(text, nlp). Linter: sprachpipe.linter.lint_sentence.
Modell offline: spacy.load('runtime/en_core_web_sm', disable=['ner']).
Echte Quellen, Modellgewichte, Konfiguration und Versionsangaben sind enthalten.
Python-Pakete müssen in passender lokaler Umgebung vorhanden sein; keine Venv enthalten.
Nur tokenize/lint/import verwenden, keine Generierungsfunktionen starten.

ZIP-Prüfung im Projekt (gleicher Befehl in PowerShell und macOS-Terminal bei aktivierter Pipeline-Umgebung):
python pipeline/scripts/export_authoring_context.py --verify-zip <Pfad-zur-geschlossenen-ZIP>
Späterer Import, erst nach Satzredaktion, mit dem bestehenden Importer:
python pipeline/scripts/import_editorial_patch.py --source {source_path.relative_to(ROOT).as_posix()} --create <redaktion.json> --registry {selection['registry_path']} --out <neues-Ausgabeverzeichnis>
Keine Zugangsdaten, Lernstände, Cloud-Aufrufe oder automatisches Staging.
manifest.json listet alle Nutzdateien mit SHA256; der ZIP-Gesamthash steht im Prüfbericht.
'''.encode('utf8')
    if continuation:
        payload['README.txt'] = payload['README.txt'].replace(
            f"Die erste Gruppe legt ausschließlich den neuen Stapel {selection['owner_deck_ref']} an.\ncombined_display_mapping.json enthält die Mitgliedschaftspositionen dieser Gruppe.".encode('utf8'),
            'Der Stapel besteht bereits. combined_display_mapping.json enthält die gemeinsame endgültige Zuordnung nach dem künftigen Import; aktuelle Pack-Positionen bleiben unverändert.'.encode('utf8'))
        payload['README.txt'] += (f'\nFORTSETZUNG: {len(continuation["partitions"]["imported"])} importiert / '
            f'{len(continuation["partitions"]["current"])} aktuell / {len(continuation["partitions"]["future"])} später.\n'
            'Keinen Stapel anlegen. Nur aktuelle Karten hinzufügen; bestehende Satzbindungen sind in selection.json eingefroren.\n'
            'sense_availability bezeichnet wiederzuverwendende Begleitwort-Senses; die Originalauswahl bleibt unverändert.\n'
            'continuation_display_mapping.json trennt bestehende Positionen, Anhängepositionen und endgültige Display-Patch-Zeilen.\n'
            'Die endgültige Zuordnung gilt erst nach dem künftigen Import plus hashgebundenem --display-patch.\n').encode('utf8')
    payload['manifest.json'] = encode({'format':'sprachapp.authoring-hash-manifest','format_version':1,
                                      'files':{name:sha(raw) for name,raw in sorted(payload.items())}})
    output.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(output,'x',compression=zipfile.ZIP_DEFLATED) as z:
        for name,raw in sorted(payload.items()):z.writestr(output.stem+'/'+name,raw)
    return {'export':'PASS','zip':str(output),'files':len(payload),**result}


def verify_zip(path, *, historical=False):
    # Reopen the ZIP, do not trust the in-memory exporter validation report.
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None,'ZIP CRC')
        names=z.namelist()
        require(len(names)==len(set(names)), 'duplicate ZIP entries')
        require(all(not PurePosixPath(n).is_absolute() and '..' not in PurePosixPath(n).parts and '\\' not in n for n in names), 'unsafe ZIP path')
        roots={n.split('/')[0] for n in names};require(len(roots)==1,'ZIP root')
        data={n.split('/',1)[1]:z.read(n) for n in names}
    require('manifest.json' in data,'missing manifest')
    manifest=json.loads(data['manifest.json'])
    require(manifest.get('format_version', 1)==1, 'unknown hash manifest version')
    require(set(data)==set(manifest['files'])|{'manifest.json'},'manifest completeness')
    require(all(sha(data[n])==h for n,h in manifest['files'].items()),'file hashes')
    forbidden={'.env','user.db','credentials.json','application_default_credentials.json'}
    require(not any(set(PurePosixPath(n).parts)&forbidden or n.endswith(('.pem','.key')) for n in data),'private file')
    if json.loads(data.get('authoring_context.json', b'{}')).get('format_version') == 3:
        return verify_form_context(path, data)
    for name,raw in data.items():
        if name.startswith(('pipeline/src/','pipeline/scripts/')) or name in ('pipeline/data/curation/editorial_content_v2.schema.json','pipeline/config.yaml','pipeline/pyproject.toml','pipeline/requirements.lock'):
            if historical: continue  # snapshot hashes checked; archived code is never executed
            require((ROOT/name).is_file() and raw==(ROOT/name).read_bytes(),'stale source/environment: '+name)
    required={'pack.json','content.sqlite','registry.json','learning_groups.json','selection.json','authoring_context.json',
              'all_selection_identities.json','dictionary_context.json','combined_display_mapping.json','all_batch_display_mappings.json',
              'tokenizer_linter_environment.json','staged_manifest.json','pipeline/src/sprachpipe/annotate.py',
              'pipeline/src/sprachpipe/linter.py','pipeline/scripts/import_editorial_patch.py','pipeline/data/curation/editorial_content_v2.schema.json',
              'runtime/en_core_web_sm/config.cfg','runtime/en_core_web_sm/tokenizer','runtime/en_core_web_sm/meta.json'}
    require(required <= set(data),'missing context files: '+str(required-set(data)))
    obj=lambda name:json.loads(data[name])
    pack=obj('pack.json');selection=obj('selection.json');registry=obj('registry.json');groups=obj('learning_groups.json')
    result=validate_context(pack,selection,registry,groups,source_bytes=data['pack.json'])
    require(obj('all_selection_identities.json')==selection['entries'],'all identities')
    dictionary=obj('dictionary_context.json')
    require(dictionary=={'base_pack_canonical_sha256':digest(pack),**{k:pack[k] for k in ('lemmas','senses','dictionary_forms')}},'dictionary')
    context=obj('authoring_context.json');batch=context['authoring_batch']
    if not selection.get('continuation'):
        require(batch == 1, 'initial context must be batch 1')
        require(context['partitions'] == partition_batches(selection['entries'], batch), 'initial context partitions')
        require(context['new_deck'] == {'ref':selection['owner_deck_ref'], 'slug':selection['owner_deck_ref'], 'title_de':selection['title_de']}, 'new deck contract')
    if selection.get('continuation'):
        c=selection['continuation']
        require(c['authoring_batch']==batch and context['partitions']==c['partitions'],'context partitions')
        require(obj('original_selection.json')==c['original_selection']==read(ROOT/c['original_selection_path']),'original immutable selection')
        require(obj('continuation_display_mapping.json')==c['display_plan'],'continuation display mapping')
        require(context['new_deck'] is None and context['existing_deck']==selection['owner_deck_ref'],'existing deck contract')
        senses={s['ref']:s for s in pack['senses']}
        require(context['sense_availability']=={e['card_ref']:{'action':'reuse' if e['sense_ref'] in senses else 'create',
            'sense':senses.get(e['sense_ref']), 'reserved_definition':e['target_meaning_de']} for e in context['entries']},'sense availability')
        require(context['definition_equivalences']==c.get('definition_equivalences',{}),'definition review mismatch')
    require(context['artifact_paths']=={selection['source_pack']['path']:'pack.json',obj('staged_manifest.json')['source']['path']:'content.sqlite',
            selection['registry_path']:'registry.json',selection['learning_groups_path']:'learning_groups.json'},'provenance path mapping')
    require(context['entries']==[e for e in selection['entries'] if e['authoring_batch']==batch],'batch definitions')
    require(context['import_contract']['source_sha256']==sha(data['pack.json']) and context['import_contract']['registry_sha256']==digest(registry),'import binding')
    require(context['import_contract']['format']=='sprachapp.editorial-content' and context['import_contract']['format_version']==2,
            'normal V2 import contract')
    require(context['import_contract']['content_schema_version']==pack['release']['schema_version'] and context['import_contract']['learning_required'] is True,
            'normal content-schema contract')
    require(obj('combined_display_mapping.json')==mapping(selection['entries'],batch),'batch positions')
    require(obj('all_batch_display_mappings.json')=={str(b):mapping(selection['entries'],b) for b in sorted({e['authoring_batch'] for e in selection['entries']})},'all positions')
    staged=obj('staged_manifest.json')
    if selection.get('continuation'):
        require(registry['source_sqlite_sha256']==staged['sha256'],'continuation SQLite binding')
    require(sha(data['content.sqlite'])==staged['sha256'] and pack['release']['version']==staged['version'],'SQLite manifest binding')
    if not historical:
        require(read(ROOT/'assets/content/en/content.manifest.json')==staged,'staged manifest changed')
        require((ROOT/selection['source_pack']['path']).read_bytes()==data['pack.json'],'actual base source changed')
    from finalize_curation import check_sqlite
    with tempfile.TemporaryDirectory(prefix='authoring-verify-') as td:
        sqlite_path=Path(td)/'content.sqlite';sqlite_path.write_bytes(data['content.sqlite'])
        counts=check_sqlite(sqlite_path,build_rows(pack))
    require(result==obj('validation.json'),'stale validation report')
    return {'zip_verification':'PASS','zip_sha256':sha(path.read_bytes()),'hashed_files':len(manifest['files']),
            'sqlite_tables':len(counts),'sqlite_cards':counts['cards'],'credentials_and_learning_states':'none; explicit content/source/model whitelist',**result}



def form_authoring_details(pack, selection):
    """Derive planned groups and current tasks without creating sentence rows."""
    import copy
    from sprachpipe.pack import _build_rows
    from sprachpipe.authoring_context import sentence_binding
    work = copy.deepcopy(pack)
    work['release']['schema_version'] = 4
    for delta in selection['batches'].values():
        for table, values in delta.items():
            existing = work.setdefault(table, [])
            existing.extend(copy.deepcopy(r) for r in values if r not in existing)
    rows = _build_rows(work)
    refs = {r['id']: c['ref'] for c, r in zip(work['cards'], rows['cards'])}
    groups = {'version': 'en.learning_groups.v1', 'status': 'planned-form-metadata-only',
              'source_pack_sha256': selection['source_sha256'],
              'cards': [dict(card_ref=c['ref'], card_id=r['id'],
                             primary_card_ref=refs[r['learning']['primary_card_id']], **c['learning'])
                        for c, r in zip(work['cards'], rows['cards'])]}
    cards = {c['ref']: c for c in work['cards']}
    senses = {s['ref']: s for s in work['senses']}
    forms = {f['ref']: f for f in work['form_targets']}
    tasks = {'new_sentence_pairs': [], 'unchanged_reuse': []}
    for entry in selection['entries']:
        if entry['authoring_batch'] != selection['authoring_batch']:
            continue
        target = forms[entry['form_target']]
        task = {'form_target': target, 'card': cards[target['card']],
                'sense': senses[target['sense']]}
        if entry['reuse'] is not None:
            task.update(evidence=entry['reuse'], context=sentence_binding(pack, target['card']))
            tasks['unchanged_reuse'].append(task)
        else:
            tasks['new_sentence_pairs'].append(task)
    return groups, tasks


def export_form_context(selection_path, output):
    from sprachpipe.authoring_context import form_context
    from sprachpipe.deck_display import form_display_mapping
    from sprachpipe.linter import _nlp
    from finalize_curation import check_sqlite
    import os
    selection=read(selection_path)
    source_path=ROOT/selection['source_pack']['path']
    raw=source_path.read_bytes();pack=json.loads(raw)
    registry=read(ROOT/selection['registry_path'])
    context=form_context(pack,selection,registry,source_bytes=raw)
    groups, tasks = form_authoring_details(pack, selection)
    if 'learning_groups_path' in selection:
        require(read(ROOT/selection['learning_groups_path']) == groups, 'planned form learning snapshot')
        require(digest(groups) == selection['learning_groups_sha256'], 'planned form learning hash')
    sqlite_path=ROOT/selection['source_pack']['sqlite_path']
    require(sha(sqlite_path.read_bytes())==selection['source_pack']['sqlite_sha256'],'form source SQLite hash')
    check_sqlite(sqlite_path,build_rows(pack))
    payload={'pack.json':raw,'content.sqlite':sqlite_path.read_bytes(),
             'selection.json':encode(selection),'registry.json':encode(registry),
             'authoring_context.json':encode(context),
             'display_mapping.json':encode(form_display_mapping(selection)),
             'dictionary_context.json':encode({k:pack[k] for k in ('lemmas','senses','dictionary_forms')}),
             'learning_groups.json':encode({c['ref']:c['learning'] for c in pack['cards']}),
             'planned_learning_groups.json':encode(groups),
             'current_authoring_tasks.json':encode(tasks),
             'README.txt':b'Schema 4 form authoring, editorial-content v3. The actual source schema is declared separately in authoring_context.json. Only current_metadata may be imported. current_authoring_tasks.json separates new_sentence_pairs from unchanged_reuse (including exact old context and evidence). Write exactly one sentence pair per new task, none for reuse. Function and meaning are in form_target.note; legacy card labels stay unchanged. selection.json contains every batch and any editorial_catalog/authoring_policy. planned_learning_groups.json includes future cards; learning_groups.json preserves source groups. Metadata validation does not approve missing sentences. Ownership aliases never approve answers. No model calls; no staging. Run the existing importer only after sentence-bound review.\n'}
    sources=list((ROOT/'pipeline/src/sprachpipe').glob('*.py'))+[ROOT/p for p in (
        'pipeline/scripts/import_editorial_patch.py','pipeline/scripts/finalize_curation.py',
        'pipeline/scripts/export_authoring_context.py','pipeline/data/curation/editorial_content_v3.schema.json',
        'pipeline/config.yaml','pipeline/pyproject.toml','pipeline/requirements.lock',
        'PRODUCT.md','docs/content-schema.md','docs/learning-groups-v1.md')]
    for p in sources:payload[p.relative_to(ROOT).as_posix()]=p.read_bytes()
    nlp=_nlp();model=Path(nlp.path)
    for p in model.rglob('*'):
        if p.is_file() and '__pycache__' not in p.parts and p.suffix!='.pyc':
            payload['runtime/en_core_web_sm/'+p.relative_to(model).as_posix()]=p.read_bytes()
    payload['tokenizer_linter_environment.json']=encode({'python':platform.python_version(),
        'packages':{k:importlib.metadata.version(k) for k in ('spacy','en_core_web_sm','wordfreq','jsonschema')},
        'model':'en_core_web_sm','model_version':nlp.meta['version'],'disabled_pipes':list(nlp.disabled)})
    payload['manifest.json']=encode({'format':'sprachapp.authoring-hash-manifest','format_version':1,
                                    'files':{n:sha(b) for n,b in sorted(payload.items())}})
    output.parent.mkdir(parents=True,exist_ok=True)
    # Closed temporary ZIP is verified before atomic publication.
    fd,name=tempfile.mkstemp(prefix='.form-authoring-',suffix='.zip',dir=output.parent);os.close(fd)
    tmp=Path(name)
    try:
        with zipfile.ZipFile(tmp,'w',compression=zipfile.ZIP_DEFLATED) as z:
            for n,b in sorted(payload.items()):z.writestr('authoring/'+n,b)
        result=verify_zip(tmp)
        require(not output.exists(),'output already exists')
        os.link(tmp,output)  # exclusive publication; never overwrite historical ZIP
        return result
    finally:tmp.unlink(missing_ok=True)


def verify_form_context(path, data):
    from sprachpipe.authoring_context import form_context
    from sprachpipe.deck_display import form_display_mapping
    from finalize_curation import check_sqlite
    required={'pack.json','content.sqlite','selection.json','registry.json','authoring_context.json',
              'display_mapping.json','dictionary_context.json','learning_groups.json',
              'pipeline/data/curation/editorial_content_v3.schema.json',
              'pipeline/scripts/import_editorial_patch.py','tokenizer_linter_environment.json',
              'runtime/en_core_web_sm/config.cfg','runtime/en_core_web_sm/tokenizer','runtime/en_core_web_sm/meta.json'}
    require(required<=set(data),'incomplete form context')
    obj=lambda n:json.loads(data[n])
    pack=obj('pack.json');selection=obj('selection.json');registry=obj('registry.json')
    context=form_context(pack,selection,registry,source_bytes=data['pack.json'])
    require(obj('authoring_context.json')==context,'stale form context/version')
    require(obj('display_mapping.json')==form_display_mapping(selection),'form display mapping')
    require(obj('dictionary_context.json')=={k:pack[k] for k in ('lemmas','senses','dictionary_forms')},'form dictionary context')
    require(obj('learning_groups.json')=={c['ref']:c['learning'] for c in pack['cards']},'form learning context')
    # Older form archives remain verifiable; new declared snapshots are mandatory.
    if 'planned_learning_groups.json' in data or 'learning_groups_path' in selection:
        groups, tasks = form_authoring_details(pack, selection)
        require('planned_learning_groups.json' in data and 'current_authoring_tasks.json' in data,
                'missing planned form authoring context')
        require(obj('planned_learning_groups.json') == groups, 'planned form learning snapshot')
        require(obj('current_authoring_tasks.json') == tasks, 'current form authoring tasks')
        if 'learning_groups_path' in selection:
            require(digest(groups) == selection['learning_groups_sha256'], 'planned form learning hash')
    require(sha(data['content.sqlite'])==selection['source_pack']['sqlite_sha256'],'form SQLite hash')
    with tempfile.TemporaryDirectory(prefix='form-context-verify-') as td:
        p=Path(td)/'content.sqlite';p.write_bytes(data['content.sqlite'])
        counts=check_sqlite(p,build_rows(pack))
    return {'zip_verification':'PASS','zip_sha256':sha(path.read_bytes()),'content_schema_version':4,
            'sqlite_tables':len(counts),'partitions':context['partitions'],'counts':context['counts']}


def export_form_continuation(selection_path, source_path, sqlite_path, out, batch, version):
    """Publish fresh, local snapshots against the explicit partial-import output."""
    from sprachpipe.authoring_context import prepare_form_continuation
    from finalize_curation import check_sqlite
    original=read(selection_path)
    require(not out.exists(), 'continuation output already exists')
    source_bytes=source_path.read_bytes();pack=json.loads(source_bytes)
    check_sqlite(sqlite_path,build_rows(pack))
    registry=read(ROOT/original['registry_path'])
    selection,registry=prepare_form_continuation(pack,original,registry,source_bytes=source_bytes,
        source_path=source_path.resolve(),sqlite_path=sqlite_path.resolve(),
        sqlite_sha256=sha(sqlite_path.read_bytes()),batch=batch)
    selection['registry_path']=str((out/'registry.json').resolve())
    selection['snapshot_version']=version
    groups = None
    if 'learning_groups_path' in selection:
        groups, _ = form_authoring_details(pack, selection)
        selection['learning_groups_path'] = str((out/'learning_groups.json').resolve())
        selection['learning_groups_sha256'] = digest(groups)
    # Validate before publishing either file; no asset-manifest dependency.
    from sprachpipe.authoring_context import form_context
    context=form_context(pack,selection,registry,source_bytes=source_bytes)
    out.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='form-continuation-',dir=out.parent) as td:
        staging=Path(td)/'snapshots';staging.mkdir()
        (staging/'selection.json').write_bytes(encode(selection))
        (staging/'registry.json').write_bytes(encode(registry))
        if groups is not None:
            (staging/'learning_groups.json').write_bytes(encode(groups))
        staging.rename(out)
    return {'snapshots':'PASS','selection':str(out/'selection.json'),'registry':str(out/'registry.json'),
            'partition_counts':{k:len(v) for k,v in context['partitions'].items()}}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--historical',action='store_true',help='Validate archived hashes/content with current validators, without requiring current staged/source bytes')
    p.add_argument('--selection',type=Path);p.add_argument('--out',type=Path)
    p.add_argument('--batch',type=int,default=1);p.add_argument('--verify-zip',type=Path)
    p.add_argument('--prepare-continuation', metavar='VERSION', help='Write fresh versioned snapshots against the staged pack; requires original --selection and --batch')
    p.add_argument('--source-pack',type=Path,help='Form continuation: explicit partial-import pack.json')
    p.add_argument('--source-sqlite',type=Path,help='Form continuation: matching content.sqlite')
    p.add_argument('--definition-equivalences',type=Path,help='Explicit hash-bound editorial decisions for equivalent definition wording')
    a=p.parse_args()
    if a.prepare_continuation:
        if not a.selection or a.batch < 2:p.error('continuation needs original --selection and --batch >= 2')
        version=a.prepare_continuation
        require(version.replace('_','').replace('-','').isalnum(),'unsafe snapshot version')
        original=read(a.selection)
        if original.get('format')=='sprachapp.form-selection':
            if not a.out or not a.source_pack or not a.source_sqlite:
                p.error('form continuation needs --out, --source-pack and --source-sqlite')
            result=export_form_continuation(a.selection,a.source_pack,a.source_sqlite,a.out,a.batch,version)
            print(json.dumps(result,ensure_ascii=False,indent=2));return
        staged=read(ROOT/'assets/content/en/content.manifest.json')
        require(sha((ROOT/staged['source']['path']).read_bytes())==staged['sha256'] and
                sha((ROOT/'assets/content/en/content.sqlite').read_bytes())==staged['sha256'],'staged SQLite differs')
        source=Path(staged['source']['path']).with_name('pack.json')
        source_bytes=(ROOT/source).read_bytes();pack=json.loads(source_bytes)
        paths={'selection':f'pipeline/data/selection/{version}.json','registry':f'pipeline/data/words/en.{version}.json',
               'groups':f'pipeline/data/learning_groups/en.{version}.json'}
        require(all(not (ROOT/path).exists() for path in paths.values()),'snapshot output exists')
        s,r,g=prepare_continuation(pack,original,read(ROOT/original['learning_groups_path']),source_bytes=source_bytes,
             source_path=source.as_posix(),batch=a.batch,version=version,registry_path=paths['registry'],groups_path=paths['groups'],
             original_path=a.selection.resolve().relative_to(ROOT).as_posix(),
             definition_equivalences=read(a.definition_equivalences) if a.definition_equivalences else None,
             source_sqlite_sha256=staged['sha256'])
        for path,value in zip(paths.values(),(s,r,g)):(ROOT/path).write_bytes(encode(value))
        result={'snapshots':'PASS','paths':paths,'partition_counts':{k:len(v) for k,v in s['continuation']['partitions'].items()}}
    elif a.verify_zip:result=verify_zip(a.verify_zip.resolve(), historical=a.historical)
    else:
        if not a.selection or not a.out:p.error('--selection and --out required')
        result=export(a.selection.resolve(),a.out.resolve(),a.batch)
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
