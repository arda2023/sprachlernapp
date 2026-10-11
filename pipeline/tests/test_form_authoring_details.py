"""Planned form groups and sentence-task handoff, including tamper rejection."""
import copy
import hashlib
import json
import sys
import zipfile
from pathlib import Path

import pytest
from form_fixture import fixture, delivery
from sprachpipe.export import export_sqlite
from sprachpipe.word_registry import digest
sys.path.insert(0, str(Path(__file__).parents[1] / 'scripts'))
from export_authoring_context import (encode, export, verify_zip,
    form_authoring_details, export_form_continuation)
from import_editorial_patch import create_content, export_offline


def test_tasks_separate_reuse_and_include_all_future_groups():
    source, _, selection, _, _, _ = fixture()
    original = copy.deepcopy(source)
    groups, tasks = form_authoring_details(source, selection)
    assert len(groups['cards']) == 9
    assert len(tasks['new_sentence_pairs']) == 2
    assert len(tasks['unchanged_reuse']) == 1
    assert tasks['unchanged_reuse'][0]['evidence'] == selection['entries'][1]['reuse']
    assert tasks['unchanged_reuse'][0]['context']
    assert source == original
    assert not any('sentences' in d for d in selection['batches'].values())


def test_bound_groups_zip_tamper_and_continuation(tmp_path):
    source, raw, selection, registry, sentences, reviews = fixture()
    base = tmp_path / 'base'; base.mkdir()
    (base / 'pack.json').write_bytes(raw)
    export_sqlite(source, base / 'content.sqlite')
    selection.update(source_pack={'path': str(base / 'pack.json'),
        'sqlite_path': str(base / 'content.sqlite'),
        'sqlite_sha256': hashlib.sha256((base / 'content.sqlite').read_bytes()).hexdigest()},
        registry_path=str(base / 'registry.json'), learning_groups_path=str(base / 'groups.json'))
    groups, _ = form_authoring_details(source, selection)
    selection['learning_groups_sha256'] = digest(groups)
    for name, value in [('selection', selection), ('registry', registry), ('groups', groups)]:
        (base / (name + '.json')).write_bytes(encode(value))
    archive = base / 'authoring.zip'
    export(base / 'selection.json', archive, 1)
    assert verify_zip(archive)['zip_verification'] == 'PASS'
    with zipfile.ZipFile(archive) as z:
        data = {n: z.read(n) for n in z.namelist()}
    # Rehash the forged payload: semantic verification, not only file hashes,
    # must catch a dropped future group and a reused card turned into a task.
    for filename in ('planned_learning_groups.json', 'current_authoring_tasks.json'):
        forged = dict(data)
        obj = json.loads(forged['authoring/' + filename])
        if filename.startswith('planned'):
            obj['cards'].pop()
        else:
            obj['new_sentence_pairs'].append(obj['unchanged_reuse'].pop())
        forged['authoring/' + filename] = encode(obj)
        manifest = json.loads(forged['authoring/manifest.json'])
        manifest['files'][filename] = hashlib.sha256(forged['authoring/' + filename]).hexdigest()
        forged['authoring/manifest.json'] = encode(manifest)
        bad = base / ('bad-' + filename + '.zip')
        with zipfile.ZipFile(bad, 'w') as z:
            for name, payload in forged.items():
                z.writestr(name, payload)
        with pytest.raises(ValueError, match='planned form learning|current form authoring'):
            verify_zip(bad)
    final = create_content(source, delivery(selection, registry, sentences, reviews),
                           registry, source_hash=hashlib.sha256(raw).hexdigest())
    out = tmp_path / 'imported'; export_offline(final, out)
    continuation = tmp_path / 'continuation'
    export_form_continuation(base / 'selection.json', out / 'pack.json',
                             out / 'content.sqlite', continuation, 2, 'test')
    result = export(continuation / 'selection.json', tmp_path / 'batch2.zip', 2)
    assert len(result['partitions']['current']) == 3
    assert verify_zip(tmp_path / 'batch2.zip')['zip_verification'] == 'PASS'
