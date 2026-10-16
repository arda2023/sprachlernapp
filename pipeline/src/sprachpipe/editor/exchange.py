"""Bounded, non-executable exchange containers. Content checks live in authoring_service."""
from __future__ import annotations

import copy
import hashlib
import io
import json
import stat
import uuid
import zipfile
from pathlib import PurePosixPath, Path

from ..authoring_service import AuthoringError, normalize_delivery, require, base_fingerprint, target_identity, TABLES
from ..word_registry import digest
from ..language_profiles import get_profile, UnsupportedLanguage

JSON_LIMIT = 25 * 1024 * 1024
ARCHIVE_LIMIT = 50 * 1024 * 1024
EXPANDED_LIMIT = 200 * 1024 * 1024
FORMAT = """# Lokale redaktionelle Lieferung

delivery.json ist die kanonische Lieferung. Keine Skripte werden ausgeführt.
Felder dürfen als Entwurf unvollständig bleiben; fehlende Angaben verhindern ein Release.
Jedes Lernziel braucht eine Bedeutung, einen Satz, eine deutsche Übersetzung,
eine eindeutige Lücke und ausdrücklich geprüfte Wortbindungen und Kontextglossen.
Prüfbehauptungen aus Dateien ersetzen keine lokale redaktionelle Bestätigung.
Maximal 1.500 Ziele je Lieferung, Verarbeitung in Blöcken von höchstens 100.
Vorhandene Identitäten nicht ändern. Eine neue Lieferung erhält eine neue delivery_id.
XLSX-Formeln, Makros und eingebettete Objekte sind nicht erlaubt.
"""


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False)+'\n').encode('utf-8')


def archive_entries(raw, *, xlsx=False):
    require(len(raw)<=ARCHIVE_LIMIT,'UPLOAD_LIMIT','Archiv überschreitet 50 MiB.',status=413)
    try:
        archive=zipfile.ZipFile(io.BytesIO(raw))
        entries=archive.infolist()
        require(len(entries)<=2000,'UPLOAD_LIMIT','Archiv enthält mehr als 2.000 Einträge.',status=413)
        total=0;seen=set();result={}
        for item in entries:
            name=item.filename;path=PurePosixPath(name)
            require(name not in seen and '\\' not in name and not path.is_absolute() and
                    '..' not in path.parts and ':' not in name and '\x00' not in name,
                    'ARCHIVE_PATH','Unsicherer oder doppelter Archivpfad: '+name)
            seen.add(name)
            require(not stat.S_ISLNK(item.external_attr>>16),'ARCHIVE_PATH','Symbolische Verknüpfungen sind nicht erlaubt.')
            require(not item.flag_bits&1,'FORMAT_UNSUPPORTED','Verschlüsselte Archive sind nicht erlaubt.')
            total+=item.file_size
            require(total<=EXPANDED_LIMIT and item.file_size<=max(1,item.compress_size)*100,
                    'UPLOAD_LIMIT','Entpackte Größe oder Kompressionsverhältnis überschritten.',status=413)
            if item.is_dir():continue
            if xlsx:
                lower=name.lower()
                require(not any(x in lower for x in ('vbaproject','externallinks/','embeddings/','activex/','oleobject')),
                        'XLSX_OBJECT','Makros, externe Verknüpfungen und eingebettete Objekte sind nicht erlaubt.')
            else:
                require(name in {'delivery.json','FORMAT.md','editorial_content_v4.schema.json',
                                'authoring_context.json','files.sha256.json','editor.xlsx'},
                        'ARCHIVE_ENTRY','Nicht erlaubter Archiveintrag: '+name)
            # The central-directory bounds are checked before any decompression.
            data=archive.read(item)
            require(len(data)==item.file_size,'FORMAT_INVALID','Archivgröße stimmt nicht überein.')
            result[name]=data
        return result
    except (zipfile.BadZipFile,RuntimeError,NotImplementedError) as e:
        raise AuthoringError('FORMAT_INVALID','Archiv kann nicht gelesen werden: '+str(e)) from e


def read_delivery(raw, filename, lang, *, source=None):
    extension=Path(filename).suffix.lower()
    if extension=='.json':
        require(len(raw)<=JSON_LIMIT,'UPLOAD_LIMIT','JSON überschreitet 25 MiB.',status=413)
        return normalize_delivery(raw,language=lang)
    if extension=='.xlsx':
        from .xlsx import read_workbook
        return normalize_delivery(read_workbook(raw,lang),language=lang)
    require(extension=='.zip','FORMAT_UNSUPPORTED','JSON, ZIP oder XLSX auswählen.')
    entries=archive_entries(raw)
    require('delivery.json' in entries,'FORMAT_INVALID','delivery.json fehlt.')
    if 'files.sha256.json' in entries:
        try: hashes=json.loads(entries['files.sha256.json'])
        except (ValueError,UnicodeError):raise AuthoringError('FORMAT_INVALID','Hashverzeichnis ist ungültig.') from None
        require(set(hashes)==set(entries)-{'files.sha256.json'},'ARCHIVE_HASH','Hashverzeichnis ist unvollständig.')
        for name,expected in hashes.items():
            require(hashlib.sha256(entries[name]).hexdigest()==expected,'ARCHIVE_HASH','Datei weicht vom Hash ab: '+name)
    delivery=normalize_delivery(entries['delivery.json'],language=lang)
    if 'editor.xlsx' in entries:
        from .xlsx import read_workbook
        alternative=normalize_delivery(read_workbook(entries['editor.xlsx'],lang),language=lang)
        if digest(alternative)!=digest(delivery):
            require(source in ('json','xlsx'),'SOURCE_CONFLICT','JSON und XLSX unterscheiden sich. Quelle ausdrücklich wählen.',status=409)
            if source=='xlsx':delivery=alternative
    return delivery


def authoring_context(base, *, topic='', selected_refs=()):
    try:profile=get_profile(base['lang']).manifest
    except UnsupportedLanguage:profile={'supported':False,'lang':base['lang']}
    sentences={l['sentence'] for l in base['card_sentences'] if l['card'] in selected_refs}
    relevant=({c.get('sense') for c in base['cards'] if c['ref'] in selected_refs}|{t.get('sense') for t in base['sentence_tokens'] if t['sentence'] in sentences}) if selected_refs else {s['ref'] for s in base['senses']}
    lemma_refs={s['lemma'] for s in base['senses'] if s['ref'] in relevant}
    return {'format_version':1,'lang':base['lang'],'translation_lang':'de','topic':topic,
            'base':base_fingerprint(base),'profile':profile,
            'identities':[{'ref':c['ref'],'id':target_identity(base,c),'form':c.get('form'),
                           'sense':c.get('sense'),'removed_in':c.get('removed_in'),
                           'learning':c.get('learning')} for c in base['cards']],
            'ownership':copy.deepcopy(base['word_registry']['snapshot']),
            'aliases':copy.deepcopy(base.get('word_aliases',[])),
            'lemmas':[l for l in base['lemmas'] if l['ref'] in lemma_refs],
            'senses':[s for s in base['senses'] if s['ref'] in relevant],
            'dictionary_forms':[d for d in base['dictionary_forms'] if d['sense'] in relevant],
            'reserved_refs':{t:[r['ref'] for r in base.get(t,[]) if 'ref' in r] for t in TABLES}}


def delivery_for_draft(draft,base=None):
    result = {'format':'sprachapp.editorial-content','format_version':4,
            'delivery_id':draft.get('exchange_delivery_id',draft['draft_id']),
            'lang':draft['lang'],'translation_lang':'de','purpose':'roundtrip',
            'base':copy.deepcopy(draft['base']),'context_sha256':draft.get('context_sha256'),
            'expected_target_refs':list(draft.get('target_refs',[])),
            'selection':{'policy':'editor-deck-v1','batches':[
                {'number':i//100+1,'target_refs':draft.get('target_refs',[])[i:i+100]}
                for i in range(0,len(draft.get('target_refs',[])),100)]},
            'add':copy.deepcopy(draft.get('add',{})),
            'operations':copy.deepcopy(draft.get('operations',[])),
            'provenance':copy.deepcopy(draft.get('provenance',[])),
            'submitted_reviews':[],'extensions':{}}

    # Candidate lists are transient selection aids, not chosen bindings.
    def strip_suggestions(value):
        if isinstance(value,dict):
            if 'surface' in value and 'idx' in value:value.pop('candidates',None)
            for child in value.values():strip_suggestions(child)
        elif isinstance(value,list):
            for child in value:strip_suggestions(child)
    strip_suggestions(result)
    if base is not None:
        from ..authoring_service import roundtrip_records
        result=roundtrip_records(base,result)
    return result


def write_zip(delivery, context, *, include_xlsx=True):
    schema=Path(__file__).resolve().parents[3]/'data'/'curation'/'editorial_content_v4.schema.json'
    entries={'delivery.json':json_bytes(delivery),'FORMAT.md':FORMAT.encode(),
             'authoring_context.json':json_bytes(context),'editorial_content_v4.schema.json':schema.read_bytes()}
    if include_xlsx:
        from .xlsx import write_workbook
        try:entries['editor.xlsx']=write_workbook(delivery)
        except AuthoringError as e:
            if e.code!='XLSX_CELL_LIMIT':raise
            entries['FORMAT.md']+=b'\nXLSX unavailable: cell limit exceeded. delivery.json retains all content.\n'
    entries['files.sha256.json']=json_bytes({n:hashlib.sha256(b).hexdigest() for n,b in entries.items()})
    buffer=io.BytesIO()
    # Stored entries make even repetitive templates safe under our ratio limit.
    with zipfile.ZipFile(buffer,'w',compression=zipfile.ZIP_STORED) as z:
        for name,data in entries.items():z.writestr(name,data)
    return buffer.getvalue()


def template_delivery(base, count, topic=''):
    require(type(count) is int and 1<=count<=1500,'UPLOAD_LIMIT','Vorlage mit 1 bis 1.500 Zielzeilen wählen.')
    identifier=str(uuid.uuid4());refs=[identifier+':'+str(i+1) for i in range(count)]
    context=authoring_context(base,topic=topic)
    draft={'draft_id':identifier,'lang':base['lang'],'base':base_fingerprint(base),
           'context_sha256':digest(context),'target_refs':refs,'operations':[],
           'add':{'cards':[{'ref':ref,'form':None,'sense':None,'translation_de':None} for ref in refs]}}
    result=delivery_for_draft(draft);result['purpose']='new_deck'
    return result,context
