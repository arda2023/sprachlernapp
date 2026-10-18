"""Build/verify documentation artifacts only; no real store, pack or cloud writes."""
from pathlib import Path
import copy
import hashlib
import io
import json
import tempfile
import zipfile

import jsonschema
from sprachpipe import authoring_service as author
from sprachpipe.editor.exchange import authoring_context, json_bytes, read_delivery, write_zip, archive_entries
from sprachpipe.editor.xlsx import write_workbook, read_workbook, VISIBLE, SHEETS
from sprachpipe.editor.service import EditorService
from sprachpipe.word_registry import digest

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'build/portuguese_authoring_contract_v1.zip'
LANGUAGE = {'lang': 'pt-BR', 'display_name': 'Portugiesisch (Brasilien)',
            'name_native': 'Português do Brasil', 'translation_lang': 'de'}
base = author.empty_pack('pt-BR', LANGUAGE['display_name'])
base['languages'][0]['name_native'] = LANGUAGE['name_native']
refs = [f'ptbr-pilot-slot-{n:02d}' for n in range(1, 21)]
deck = {'op_id': 'pilot-deck', 'kind': 'create_deck', 'lang': 'pt-BR',
        'target_ref': 'ptbr-allgemeine-sprache', 'expect': {'absent': True},
        'reason': 'PLANENTWURF: leerer vertikaler Testlauf, keine Freigabe.',
        'payload': {'ref': 'ptbr-allgemeine-sprache', 'slug': 'allgemeine-sprache',
                    'title_de': 'Allgemeine Sprache', 'description_de': 'Redaktioneller 20-Ziele-Pilot für Brasilianisches Portugiesisch.',
                    'practice_kind': 'ordinary', 'cefr_band': 'anfaenger', 'sort': 1}}

def target(ref):
    return {'op_id': 'create-'+ref, 'kind': 'create_target', 'lang': 'pt-BR',
            'target_ref': ref, 'expect': {'absent': True}, 'reason': 'Unvollständiger Refslot; nicht freigeben.',
            'payload': {'deck_ref': deck['target_ref'], 'topic': 'allgemeine-sprache',
                        'card': {'form': None, 'sense': None, 'translation_de': None,
                                 'cefr_band': 'anfaenger', 'introduction_scope': 'ordinary'},
                        'context': {'text': None, 'translation_de': None,
                                    'gap': {'start_pos': None, 'end_pos': None},
                                    'tokens': [], 'valid_alternatives': [], 'reason': 'Redaktionelle Prüfung offen.'}}}

contract = {
    'contract_id': 'portuguese-authoring-contract-v1', 'status': 'PLAN_DRAFT_NOT_RELEASE_READY',
    'transport': {'format': 'sprachapp.editorial-content', 'format_version': 4,
                  'current_reader_accepts_draft': True, 'current_release_supported': False},
    'language': LANGUAGE, 'proposed_profile': {'id': 'pt-BR-editorial-v1', 'sha256': None, 'implemented': False},
    'scope': {'pilot_targets': 20, 'later_approximate_targets': 160, 'fill_required': False,
              'stories_required': False, 'practice_kind': 'ordinary', 'identity_function': None},
    'enums': {'pos': ['ADJ','ADP','ADV','AUX','CCONJ','DET','INTJ','NOUN','NUM','PART','PRON','PROPN','SCONJ','VERB'],
              'cefr_band_pilot': ['anfaenger'], 'binding_status_complete': ['confirmed'],
              'provenance_kind_pilot': ['manual'], 'alternatives_pilot': []},
    'required_fields': {
        'lemma': ['ref','lemma','pos'], 'sense': ['ref','lemma','sense_key','gloss_de','definition_de'],
        'dictionary_form': ['form','sense','gloss_de','rank'],
        'operation': ['op_id','kind','lang','target_ref','expect','payload','reason'],
        'card': ['form','sense','translation_de','cefr_band','introduction_scope'],
        'context': ['text','translation_de','gap','tokens','valid_alternatives','reason'],
        'token': ['idx','surface','start_pos','end_pos'],
        'word_token_additionally': ['lemma','sense','context_gloss_de','binding_status']},
    'offsets': {'unit': 'Unicode code points', 'interval': '[start_pos,end_pos)', 'normalization': 'NFC',
                'line_endings': 'LF', 'contiguous': True, 'target_occurrences': 1,
                'current_importer_fills_missing_offsets': False},
    'generated_by_import_materialization': ['content IDs','singleton learning group','owner bindings','positions',
                                           'sentence refs','accepted=[form]','context snapshots'],
    'never_guess': ['existing IDs','existing sense bindings','base hashes','profile hash','editorial approval'],
    'xlsx': {'version': 1, 'mode': 'full', 'meta_columns': ['key','value_json'],
             'visible_columns': list(VISIBLE), 'record_columns': ['_table','_index','payload_json'],
             'table_sheets': SHEETS, 'payload_shape': {'fields': {}, 'present': []}},
    'future_bootstrap_extension': {
        'status': 'NOT_ACCEPTED_BY_CURRENT_IMPORTER', 'format_version_proposal': 4,
        'optional_top_level_field': 'language_definition',
        'value': {**LANGUAGE, 'profile_id': 'pt-BR-editorial-v1', 'profile_sha256': None},
        'required_fields': [*LANGUAGE, 'profile_id','profile_sha256'],
        'additional_properties': False, 'purpose': 'new_deck',
        'preconditions': ['registered exact profile/hash','language absent OR exact metadata match',
                          'no English parent','preview on ephemeral deterministic empty seed'],
        'commit': 'explicit accepted preview hash; atomically persist language seed and import receipt under store mutex',
        'failure': 'no partially created language/head; conflicts never overwrite metadata',
        'current_failure_code': 'FORMAT_UNSUPPORTED'},
    'blockers': ['PROFILE_UNSUPPORTED','publisher English-only gate','mobile language switch absent',
                 'no atomic language creation from current delivery alone'],
}
context = authoring_context(base, topic='Allgemeine Sprache')
context['authoring_contract'] = contract

delivery = {'format': 'sprachapp.editorial-content', 'format_version': 4,
            'delivery_id': '90c80649-d2f1-4ec4-ae0c-9f99b1bc21c2', 'lang': 'pt-BR', 'translation_lang': 'de',
            'purpose': 'new_deck', 'base': author.base_fingerprint(base), 'context_sha256': None,
            'expected_target_refs': refs, 'selection': {'policy': 'editor-deck-v1', 'batches': [{'number':1,'target_refs':refs}]},
            'add': {'lemmas': [], 'senses': [], 'dictionary_forms': []},
            'operations': [deck, *[target(ref) for ref in refs]], 'provenance': [],
            'submitted_reviews': [], 'extensions': {}, 'completeness': 'draft'}
example = copy.deepcopy(delivery)
example.update(delivery_id='f0abcac4-0e52-4cd0-bd41-f9fc89a4bbf8', expected_target_refs=['synthetic-only'])
example['selection']['batches'] = [{'number':1,'target_refs':['synthetic-only']}]
example['operations'] = [copy.deepcopy(deck),target('synthetic-only')]
marker = 'SYNTHETIC_NON_PUBLISHABLE'
example['add'] = {
    'lemmas': [{'ref':'synthetic-lemma','lemma':marker,'pos':'NOUN'}],
    'senses': [{'ref':'synthetic-sense','lemma':'synthetic-lemma','sense_key':'synthetic#not-language-content',
                'gloss_de':'Synthetischer Strukturmarker','definition_de':'Kein portugiesisches Wort; niemals veröffentlichen.'}],
    'dictionary_forms': [{'form':marker,'sense':'synthetic-sense','gloss_de':'Synthetischer Strukturmarker','rank':0}]}
payload=example['operations'][1]['payload']
payload['card'].update(form=marker,sense='synthetic-sense',translation_de='Kein Lerninhalt')
payload['context'].update(text=marker+'.',translation_de='Nur synthetische Strukturprobe.',
    gap={'start_pos':0,'end_pos':len(marker)},tokens=[
        {'idx':0,'surface':marker,'start_pos':0,'end_pos':len(marker),'lemma':'synthetic-lemma',
         'sense':'synthetic-sense','context_gloss_de':'Synthetischer Strukturmarker','binding_status':'unresolved'},
        {'idx':1,'surface':'.','start_pos':len(marker),'end_pos':len(marker)+1}])
context['synthetic_example_delivery']=example
# Example is embedded reference material, not a second delivery authority.
delivery['context_sha256']=digest(context)
schema=json.loads((ROOT/'pipeline/data/curation/editorial_content_v4.schema.json').read_text())
for name,value in [('template',delivery),('synthetic-example',example)]:
    jsonschema.Draft202012Validator(schema,format_checker=jsonschema.FormatChecker()).validate(value)
    assert read_delivery(json_bytes(value),name+'.json','pt-BR')==value
    assert read_workbook(write_workbook(value),'pt-BR')==value
    draft={'lang':'pt-BR','translation_lang':'de','revision':0,'base':author.base_fingerprint(base),
           'add':value['add'],'operations':value['operations'],'target_refs':value['expected_target_refs'],'reviews':[]}
    result=author.validate_draft(draft,base)
    assert result['technical']=='unsupported' and result['editorial']=='open',result
    print(name, 'SCHEMA/JSON/XLSX PASS; release blocked:',result['technical'],[f['code'] for f in result['findings']])

# Prove the current importer cannot define a language via delivery fields.
for change in [{'language_definition':contract['future_bootstrap_extension']['value']},
               {'add':{'languages':[base['languages'][0]]}}]:
    try: author.normalize_delivery({**delivery,**change},language='pt-BR')
    except author.AuthoringError as error: assert error.code=='FORMAT_UNSUPPORTED'
    else: raise AssertionError('unexpected bootstrap support')

# Use actual service only against an isolated, disposable empty store.
with tempfile.TemporaryDirectory(prefix='ptbr-contract-') as tmp:
    temp=Path(tmp);source=temp/'empty-en.json'
    source.write_bytes(json_bytes(author.empty_pack('en','English synthetic seed')))
    service=EditorService(temp/'store',source=source,asset_directory=temp/'assets')
    try:
        english_before=digest(service.base('en'))
        language=service.create_language(LANGUAGE)
        assert language['state']=='draft' and language['profile'] is None
        assert digest(service.base('en'))==english_before
        assert service.base('pt-BR')==base
    finally:service.close()
print('isolated create_language pt-BR PASS; English seed unchanged; no content reserved')

entries=archive_entries(write_zip(delivery,context))
entries['FORMAT.md']=(HERE/'FORMAT.md').read_bytes()
entries['files.sha256.json']=json_bytes({n:hashlib.sha256(b).hexdigest() for n,b in entries.items() if n!='files.sha256.json'})
OUT.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(OUT,'w',compression=zipfile.ZIP_DEFLATED) as archive:
    for name,data in entries.items():archive.writestr(name,data)
assert read_delivery(OUT.read_bytes(),OUT.name,'pt-BR')==delivery
for name,value in [('contract.json',contract),('template.delivery.json',delivery),('synthetic-example.delivery.json',example),('authoring_context.json',context)]:
    (HERE/name).write_bytes(json_bytes(value))
print('ZIP read_delivery/hash/source-consistency PASS; 20 empty slots;',OUT.name,OUT.stat().st_size,'bytes')
print('ZIP_SHA256',hashlib.sha256(OUT.read_bytes()).hexdigest())
