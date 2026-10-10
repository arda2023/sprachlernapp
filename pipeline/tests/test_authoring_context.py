import copy
import hashlib
import json
import sys
import zipfile
from pathlib import Path
import pytest
from test_content_contract import fixture
from sprachpipe.authoring_context import validate_context
from sprachpipe.word_registry import digest


def context_fixture():
    base, _, _, _ = fixture()
    base['release']['schema_version'] = 3
    raw = json.dumps(base).encode()
    selection = json.loads((Path(__file__).parents[1]/'data/selection/alltag_zuhause_v1.json').read_bytes())
    entries = [copy.deepcopy(e) for e in selection['entries'] if e['form'] in ('house','broom')]
    for e in entries:
        e.update(authoring_batch=1,proposed_sense_key=e['sense_key'] or e['proposed_sense_key'],sense_key=None,
                 sense_source='proposed_new',definition_de=e['target_meaning_de'])
    registry = copy.deepcopy(base['word_registry']['snapshot'])
    registry.update(parent_sha256=digest(registry),source_pack_sha256=hashlib.sha256(raw).hexdigest())
    registry['words'] = [{'lang':'en','form_norm':e['form_norm'],'aliases':e['ownership_aliases'],
        'owner_deck_ref':'alltag-zuhause','primary_card_ref':e['card_ref'],'primary_card_id':e['card_id'],'position':e['position']} for e in entries]
    old={'cards':[]}
    groups={'existing':old,'parent_sha256':digest(old),'source_pack_sha256':hashlib.sha256(raw).hexdigest(),
            'reserved_cards':[dict(card_ref=e['card_ref'],card_id=e['card_id'],primary_card_ref=e['card_ref'],**e['learning']) for e in entries]}
    selection.update(entries=entries,excluded=[],source_pack={'sha256':hashlib.sha256(raw).hexdigest(),'canonical_sha256':digest(base)},
                     registry_sha256=digest(registry),learning_groups_sha256=digest(groups))
    return base, selection, registry, groups, raw


@pytest.mark.parametrize('failure',[None,'source_hash','id','definition','reservation','alias','head','mixed_batch'])
def test_context_checks_independent_targets_and_reservations(failure):
    base,s,r,g,raw=context_fixture()
    if failure=='source_hash':raw+=b' '
    if failure=='id':s['entries'][0]['card_id']='bad'
    if failure=='definition':s['entries'][0]['definition_de']=''
    if failure=='reservation':r['words'][0]['position']+=1
    if failure=='alias':r['words'][0]['aliases']=[r['words'][1]['form_norm']]
    if failure=='head':s['entries'][0]['learning']['primary_card_id']=s['entries'][1]['card_id']
    if failure=='mixed_batch':s['entries'][0]['topic']=s['entries'][1]['topic']
    s['registry_sha256']=digest(r);s['learning_groups_sha256']=digest(g)
    if failure:
        with pytest.raises(ValueError):validate_context(base,s,r,g,source_bytes=raw)
    else:
        assert validate_context(base,s,r,g,source_bytes=raw)['selected']==2


@pytest.mark.parametrize('failure',['hash','private','path','missing'])
def test_archive_validation_rejects_tampering_and_private_files(tmp_path,failure):
    sys.path.insert(0,str(Path(__file__).parents[1]/'scripts'))
    from export_authoring_context import verify_zip
    name='.env' if failure=='private' else '../file' if failure=='path' else 'pack.json'
    payload={name:b'{}'}
    manifest={'files':{name:hashlib.sha256(payload[name]).hexdigest()}}
    if failure=='hash':payload[name]=b'{ }'
    zpath=tmp_path/'test.zip'
    with zipfile.ZipFile(zpath,'w') as z:
        for n,raw in payload.items():z.writestr('context/'+n,raw)
        z.writestr('context/manifest.json',json.dumps(manifest))
    with pytest.raises(ValueError):verify_zip(zpath)


def test_new_deck_export_has_own_title_and_verified_initial_partition(tmp_path, monkeypatch):
    from types import SimpleNamespace
    import export_authoring_context as exporter
    from sprachpipe import linter
    from sprachpipe.export import export_sqlite

    base, selection, registry, groups, raw = context_fixture()
    selection.update(owner_deck_ref='arbeit-bildung', title_de='Arbeit & Bildung')
    for e in selection['entries']:
        e['owner_deck_ref'] = 'arbeit-bildung'
    for w in registry['words']:
        w['owner_deck_ref'] = 'arbeit-bildung'
    selection.update(registry_sha256=digest(registry), registry_path='registry.json',
                     learning_groups_path='groups.json')
    selection['source_pack']['path'] = 'pack.json'
    real_root = exporter.ROOT
    for relative in ['pipeline/scripts/import_editorial_patch.py', 'pipeline/scripts/finalize_curation.py',
                     'pipeline/scripts/export_authoring_context.py', 'pipeline/data/curation/editorial_content_v2.schema.json',
                     'pipeline/config.yaml', 'pipeline/pyproject.toml', 'pipeline/requirements.lock',
                     'AGENTS.md', 'PRODUCT.md', 'docs/content-schema.md', 'docs/pipeline.md', 'docs/learning-groups-v1.md']:
        dest = tmp_path/relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes((real_root/relative).read_bytes())
    for src in (real_root/'pipeline/src/sprachpipe').glob('*.py'):
        dest = tmp_path/'pipeline/src/sprachpipe'/src.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(src.read_bytes())
    (tmp_path/'pack.json').write_bytes(raw)
    for name, value in [('registry.json', registry), ('groups.json', groups), ('selection.json', selection)]:
        (tmp_path/name).write_bytes(exporter.encode(value))
    export_sqlite(base, tmp_path/'content.sqlite')
    assets = tmp_path/'assets/content/en'
    assets.mkdir(parents=True)
    sqlite = (tmp_path/'content.sqlite').read_bytes()
    (assets/'content.sqlite').write_bytes(sqlite)
    (assets/'content.manifest.json').write_bytes(exporter.encode({
        'sha256': exporter.sha(sqlite), 'version': base['release']['version'],
        'source': {'path': 'content.sqlite'}}))
    model = tmp_path/'model'
    model.mkdir()
    for name in ('config.cfg', 'tokenizer', 'meta.json'):
        (model/name).write_text('synthetic model fixture')
    monkeypatch.setattr(linter, '_nlp', lambda: SimpleNamespace(path=model, meta={'version':'test'}, disabled=[]))
    monkeypatch.setattr(exporter, 'ROOT', tmp_path)
    output = tmp_path/'handoff.zip'
    exporter.export(tmp_path/'selection.json', output, 1)
    assert exporter.verify_zip(output)['status'] == 'PASS'
    with zipfile.ZipFile(output) as archive:
        payload = {n: archive.read(n) for n in archive.namelist()}
    readme = payload['handoff/README.txt'].decode('utf8')
    assert readme.startswith('Arbeit & Bildung')
    assert 'neuen Stapel arbeit-bildung' in readme
    assert 'alltag-zuhause' not in readme
    context = json.loads(payload['handoff/authoring_context.json'])
    assert context['partitions'] == {'imported': [], 'current': [e['selection_id'] for e in selection['entries']], 'future': []}
    with pytest.raises(ValueError, match='continuation snapshot'):
        exporter.export(tmp_path/'selection.json', tmp_path/'wrong-batch.zip', 2)
    context['partitions']['future'] = ['invented']
    payload['handoff/authoring_context.json'] = exporter.encode(context)
    manifest = json.loads(payload['handoff/manifest.json'])
    manifest['files']['authoring_context.json'] = exporter.sha(payload['handoff/authoring_context.json'])
    payload['handoff/manifest.json'] = exporter.encode(manifest)
    corrupted = tmp_path/'corrupted.zip'
    with zipfile.ZipFile(corrupted, 'x') as archive:
        for name, value in payload.items():
            archive.writestr(name, value)
    with pytest.raises(ValueError, match='initial context partitions'):
        exporter.verify_zip(corrupted)
