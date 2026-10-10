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
from sprachpipe.authoring_context import validate_context, require
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
    result = validate_context(pack,selection,registry,groups,source_bytes=source_raw)
    batch_entries = [e for e in selection['entries'] if e['authoring_batch'] == batch]
    require(bool(batch_entries), 'empty batch')
    cfg = load_config(); nlp = _nlp()
    env = {'python':platform.python_version(),'platform':platform.platform(),
           'packages':{k:importlib.metadata.version(k) for k in ('spacy','en_core_web_sm','wordfreq','PyYAML','python-dotenv','google-genai')},
           'model':'en_core_web_sm','model_version':nlp.meta['version'],'disabled_pipes':list(nlp.disabled),
           'linter':cfg['linter'],'names':cfg['generate']['names'],
           'offline_model_path':'runtime/en_core_web_sm','sources':'pipeline/src/sprachpipe',
           'runtime_note':'Python packages are specified by pyproject.toml and requirements.lock; installed interpreter/venv not bundled. Model data bundled. No network or provider access needed for tokenize/lint.'}
    context = {'format':'sprachapp.authoring-context','format_version':2,'authoring_batch':batch,
               'base_pack':selection['source_pack'],'registry':{'path':'registry.json','sha256':digest(registry)},
               'learning_groups':{'path':'learning_groups.json','sha256':digest(groups)},
               'artifact_paths':{selection['source_pack']['path']:'pack.json',staged['source']['path']:'content.sqlite',
                   selection['registry_path']:'registry.json',selection['learning_groups_path']:'learning_groups.json'},
               'entries':batch_entries,'new_deck':{'ref':selection['owner_deck_ref'],'slug':selection['owner_deck_ref'],'title_de':selection['title_de']},
               'import_contract':{'format':'sprachapp.editorial-content','format_version':2,'content_schema_version':3,
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
    payload['README.txt'] = f'''ALLTAG & ZUHAUSE – Authoring-Gruppe {batch}, {len(batch_entries)} von {len(selection['entries'])} Zielen
Basis: {pack['release']['version']}, Schema 3, Rohbyte-SHA256 {sha(source_raw)}.
Nur die entries in authoring_context.json redigieren. Es wurden noch keine Sätze erstellt.
Alle Identitäten, Ausschlüsse, Definitionen und Entscheidungen stehen in selection.json.
Das vollständige aktuelle Wörterbuch steht in dictionary_context.json und pack.json.
Gruppen sind unabhängig vom Wortbesitz: learning_groups.json enthält unveränderte
Altentscheidungen und separat reservierte neue Köpfe. Der historische Hash in
existing beschreibt die frühere Umstellung; der äußere Hash bindet an diese Basis.
Schema 3 verlangt cards.learning unverändert aus dem jeweiligen Auswahlziel.
Keine Variante/Synonymgruppe automatisch als gültige Lückenantwort freigeben.
Die vorhandene Satzprüfung (reviewer, reviews, Token-/Linkhashes und geprüfte
Alternativen) bleibt Teil des Imports; keine zusätzliche formelle Freigabe nötig.

Ergebnisformat: editorial_content_v2.schema.json im Pfad pipeline/data/curation/.
Genau ein neuer fester Übungssatz je ausgewählter Karte, vollständige Tokenabdeckung,
Wörterbuchglossen für jedes Wort, getrennte Kontextprüfung für Story-Lernziele.
Keine bestehenden Zeilen ändern. Benötigte neue Begleitwort-Senses explizit definieren.
Neue Karten referenzieren neue oder wiederverwendete Senses; keine alten Senses ändern.
Die erste Gruppe legt ausschließlich den neuen Stapel alltag-zuhause an.
combined_display_mapping.json enthält die Mitgliedschaftspositionen dieser Gruppe.
Die Redaktion darf weder Originalpositionen noch stabile IDs umnummerieren.
Lernreihenfolge bestimmt später die App, nicht die Reihenfolge in dieser ZIP.

Tokenizer: sprachpipe.annotate.tokenize(text, nlp). Linter: sprachpipe.linter.lint_sentence.
Modell offline: spacy.load('runtime/en_core_web_sm', disable=['ner']).
Echte Quellen, Modellgewichte, Konfiguration und Versionsangaben sind enthalten.
Python-Pakete müssen in passender lokaler Umgebung vorhanden sein; keine Venv enthalten.
Nur tokenize/lint/import verwenden, keine Generierungsfunktionen starten.

ZIP-Prüfung im Projekt (gleicher Befehl in PowerShell und macOS-Terminal bei aktivierter Pipeline-Umgebung):
python pipeline/scripts/export_authoring_context.py --verify-zip {output.relative_to(ROOT).as_posix()}
Späterer Import, erst nach Satzredaktion, mit dem bestehenden Importer:
python pipeline/scripts/import_editorial_patch.py --source {source_path.relative_to(ROOT).as_posix()} --create <redaktion.json> --registry {selection['registry_path']} --out <neues-Ausgabeverzeichnis>
Keine Zugangsdaten, Lernstände, Cloud-Aufrufe oder automatisches Staging.
manifest.json listet alle Nutzdateien mit SHA256; der ZIP-Gesamthash steht im Prüfbericht.
'''.encode('utf8')
    payload['manifest.json'] = encode({'format':'sprachapp.authoring-hash-manifest','format_version':1,
                                      'files':{name:sha(raw) for name,raw in sorted(payload.items())}})
    output.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(output,'x',compression=zipfile.ZIP_DEFLATED) as z:
        for name,raw in sorted(payload.items()):z.writestr(output.stem+'/'+name,raw)
    return {'export':'PASS','zip':str(output),'files':len(payload),**result}


def verify_zip(path):
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
    require(set(data)==set(manifest['files'])|{'manifest.json'},'manifest completeness')
    require(all(sha(data[n])==h for n,h in manifest['files'].items()),'file hashes')
    forbidden={'.env','user.db','credentials.json','application_default_credentials.json'}
    require(not any(set(PurePosixPath(n).parts)&forbidden or n.endswith(('.pem','.key')) for n in data),'private file')
    for name,raw in data.items():
        if name.startswith(('pipeline/src/','pipeline/scripts/')) or name in ('pipeline/data/curation/editorial_content_v2.schema.json','pipeline/config.yaml','pipeline/pyproject.toml','pipeline/requirements.lock'):
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
    require(context['artifact_paths']=={selection['source_pack']['path']:'pack.json',obj('staged_manifest.json')['source']['path']:'content.sqlite',
            selection['registry_path']:'registry.json',selection['learning_groups_path']:'learning_groups.json'},'provenance path mapping')
    require(context['entries']==[e for e in selection['entries'] if e['authoring_batch']==batch],'batch definitions')
    require(context['import_contract']['source_sha256']==sha(data['pack.json']) and context['import_contract']['registry_sha256']==digest(registry),'import binding')
    require(context['import_contract']['content_schema_version']==3 and context['import_contract']['learning_required'] is True,'schema-3 contract')
    require(obj('combined_display_mapping.json')==mapping(selection['entries'],batch),'batch positions')
    require(obj('all_batch_display_mappings.json')=={str(b):mapping(selection['entries'],b) for b in sorted({e['authoring_batch'] for e in selection['entries']})},'all positions')
    staged=obj('staged_manifest.json')
    require(sha(data['content.sqlite'])==staged['sha256'] and pack['release']['version']==staged['version'],'SQLite manifest binding')
    require(read(ROOT/'assets/content/en/content.manifest.json')==staged,'staged manifest changed')
    require((ROOT/selection['source_pack']['path']).read_bytes()==data['pack.json'],'actual base source changed')
    from finalize_curation import check_sqlite
    with tempfile.TemporaryDirectory(prefix='authoring-verify-') as td:
        sqlite_path=Path(td)/'content.sqlite';sqlite_path.write_bytes(data['content.sqlite'])
        counts=check_sqlite(sqlite_path,build_rows(pack))
    require(result==obj('validation.json'),'stale validation report')
    return {'zip_verification':'PASS','zip_sha256':sha(path.read_bytes()),'hashed_files':len(manifest['files']),
            'sqlite_tables':len(counts),'sqlite_cards':counts['cards'],'credentials_and_learning_states':'none; explicit content/source/model whitelist',**result}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--selection',type=Path);p.add_argument('--out',type=Path)
    p.add_argument('--batch',type=int,default=1);p.add_argument('--verify-zip',type=Path)
    a=p.parse_args()
    if a.verify_zip:result=verify_zip(a.verify_zip.resolve())
    else:
        if not a.selection or not a.out:p.error('--selection and --out required')
        result=export(a.selection.resolve(),a.out.resolve(),a.batch)
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
