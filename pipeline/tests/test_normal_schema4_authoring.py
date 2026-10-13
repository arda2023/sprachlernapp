"""Normal V2 authoring on nonempty form packs; synthetic content only."""
import copy
import hashlib
import json
import sys
import time
import zipfile
from pathlib import Path
from types import SimpleNamespace

import pytest
from form_fixture import fixture as form_fixture, delivery as form_delivery
from test_authoring_continuation import entry
from sprachpipe.authoring_context import prepare_form_continuation, prepare_continuation, validate_context
from sprachpipe.form_targets import TABLES
from sprachpipe.pack import build_rows
from sprachpipe.word_registry import digest
from sprachpipe.export import export_sqlite
sys.path.insert(0, str(Path(__file__).parents[1] / 'scripts'))
from import_editorial_patch import create_content, export_offline
from export_authoring_context import encode, export, verify_zip
import export_authoring_context as exporter
from finalize_curation import check_sqlite


def form_base():
    source, raw, selection, registry, sentences, reviews = form_fixture()
    for batch in (1, 2, 3):
        source = create_content(source, form_delivery(selection, registry, sentences, reviews),
                                registry, source_hash=hashlib.sha256(raw).hexdigest())
        raw = encode(source)
        if batch < 3:
            selection, registry = prepare_form_continuation(source, selection, registry,
                source_bytes=raw, source_path='synthetic.json', sqlite_path='synthetic.sqlite',
                sqlite_sha256='0' * 64, batch=batch + 1)
    assert source['release']['schema_version'] == 4
    assert len(source['form_targets']) == 9
    assert source['form_targets'][1]['card'] == 'cut-old'
    return source


def normal_context(size, batch_size=90, *, first_two=False):
    source = form_base()
    raw = encode(source)
    # Balance odd catalogues without a one-goal, necessarily unmixed tail.
    remaining = size - 2 if first_two else size
    count = (remaining + batch_size - 1) // batch_size
    widths = ([2] if first_two else []) + [remaining // count + (b < remaining % count)
                                           for b in range(count)]
    batch_numbers = [b for b, width in enumerate(widths, 1) for _ in range(width)]
    entries = []
    for i in range(size):
        form, lemma = ('cats', 'cat') if i == 0 else ('rest', 'rest') if i == 1 else (f'syntheticgoal{i}', f'syntheticgoal{i}')
        e = entry(form, lemma, 'NOUN' if i != 1 else 'VERB', lemma + '#fixture',
                  'Synthetic definition.', 'topic-a' if i % 2 == 0 else 'topic-b',
                  batch_numbers[i], i + 1)
        entries.append(e)
    registry = copy.deepcopy(source['word_registry']['snapshot'])
    registry.update(parent_sha256=digest(registry), source_pack_sha256=hashlib.sha256(raw).hexdigest())
    registry['words'] += [dict(lang='en', form_norm=e['form_norm'], aliases=[],
        owner_deck_ref='animals', primary_card_ref=e['card_ref'], primary_card_id=e['card_id'],
        position=e['position']) for e in entries]
    rows = build_rows(source)
    refs = {r['id']: c['ref'] for c, r in zip(source['cards'], rows['cards'])}
    existing = {'cards': [dict(card_ref=c['ref'], card_id=r['id'],
        primary_card_ref=refs[c['learning']['primary_card_id']], **c['learning'])
        for c, r in zip(source['cards'], rows['cards'])]}
    groups = dict(existing=existing, parent_sha256=digest(existing),
        source_pack_sha256=hashlib.sha256(raw).hexdigest(), reserved_cards=[
            dict(card_ref=e['card_ref'], card_id=e['card_id'], primary_card_ref=e['card_ref'], **e['learning'])
            for e in entries])
    selection = dict(version=1, lang='en', title_de='Synthetic normal deck', owner_deck_ref='animals',
        entries=entries, excluded=[], source_pack=dict(path='pack.json', schema_version=4,
            sha256=hashlib.sha256(raw).hexdigest(), canonical_sha256=digest(source)),
        registry_path='registry.json', registry_sha256=digest(registry),
        learning_groups_path='groups.json', learning_groups_sha256=digest(groups))
    return source, raw, selection, registry, groups


def normal_delivery(source, raw, selection, registry):
    # Existing natural fixture text only. Two ordinary targets, one shared sentence.
    entries = [e for e in selection['entries'] if e['authoring_batch'] == 1]
    assert len(entries) == 2
    add = {t: [] for t in ('lemmas', 'senses', 'cards', 'decks', 'deck_words', 'deck_cards',
                          'dictionary_forms', 'sentences', 'sentence_tokens', 'card_sentences')}
    add['decks'] = [dict(ref='animals', slug='animals', title_de='Synthetic normal deck', sort=6)]
    add['sentences'] = [dict(ref='normal-sentence', text='Cats rest.', translation_de='Synthetischer Testsatz.')]
    for i, e in enumerate(entries):
        add['lemmas'].append(dict(ref=e['lemma_ref'], lemma=e['lemma'], pos=e['pos']))
        add['senses'].append(dict(ref=e['sense_ref'], lemma=e['lemma_ref'],
            sense_key=e['proposed_sense_key'], gloss_de=e['gloss_de'], definition_de=e['definition_de']))
        add['cards'].append(dict(ref=e['card_ref'], form=e['form'], sense=e['sense_ref'],
            translation_de=e['translation_de'], form_kind=e['form_kind'],
            form_label_de=e['form_label_de'], cefr_band='anfaenger', learning=e['learning']))
        add['deck_words'].append(dict(deck='animals', primary_card=e['card_ref'],
                                      form_norm=e['form_norm'], position=i + 1))
        add['deck_cards'].append(dict(deck='animals', card=e['card_ref'], position=i + 1))
        add['dictionary_forms'].append(dict(form=e['form'], sense=e['sense_ref'],
                                            card=e['card_ref'], gloss_de=e['gloss_de'], rank=1))
        start, end, surface = (0, 4, 'Cats') if i == 0 else (5, 9, 'rest')
        add['sentence_tokens'].append(dict(sentence='normal-sentence', idx=i,
            surface=surface, start_pos=start, end_pos=end, lemma=e['lemma_ref'],
            sense=e['sense_ref'], card=e['card_ref']))
        add['card_sentences'].append(dict(card=e['card_ref'], sentence='normal-sentence',
            position=1, gap_start=start, gap_end=end, accepted=[e['form']], valid_alternatives=[]))
    add['sentence_tokens'].append(dict(sentence='normal-sentence', idx=2, surface='.', start_pos=9, end_pos=10))
    review = dict(sentence='normal-sentence', decision='approved', reason='Synthetic fixture review only.',
        checked=dict(text='Cats rest.', translation_de='Synthetischer Testsatz.',
            tokens_sha256=digest(add['sentence_tokens']), links_sha256=digest(add['card_sentences'])),
        alternatives_checked=[])
    return dict(format='sprachapp.editorial-content', format_version=2, operation_id='normal-synthetic',
        version='normal-synthetic-v2', source_sha256=hashlib.sha256(raw).hexdigest(),
        registry_sha256=digest(registry), reviewer='Synthetic regression, not production', add=add, reviews=[review])


@pytest.mark.parametrize('size,batch_size', [(300,90), (301,90), (450,90), (451,90),
    (1500,100), (1501,100), (100,100), (101,101)])
def test_normal_catalogue_boundaries_use_real_metadata_validator(size, batch_size):
    source, raw, selection, registry, groups = normal_context(size, batch_size)
    if size == 1501 or batch_size == 101:
        message = '1..1500' if size == 1501 else 'unmixed/oversize batch'
        with pytest.raises(ValueError, match=message):
            validate_context(source, selection, registry, groups, source_bytes=raw)
    else:
        result = validate_context(source, selection, registry, groups, source_bytes=raw)
        assert result['selected'] == size and result['existing_cards'] == 9
        assert all(len([e for e in selection['entries'] if e['authoring_batch'] == b]) <= batch_size
                   for b in {e['authoring_batch'] for e in selection['entries']})


def test_v2_delta_keeps_nonempty_form_tables_and_every_existing_sql_value(tmp_path):
    source, raw, selection, registry, groups = normal_context(6, batch_size=2)
    original = copy.deepcopy(source)
    final = create_content(source, normal_delivery(source, raw, selection, registry),
                           registry, source_hash=hashlib.sha256(raw).hexdigest())
    assert source == original and final['release']['schema_version'] == 4
    for table, values in source.items():
        if isinstance(values, list):
            assert final[table][:len(values)] == values
    for table in TABLES:
        assert final[table] and final[table] == source[table]
    before, after = build_rows(source), build_rows(final)
    for table, rows in before.items():
        if table == 'content_releases':
            continue
        key = 'code' if table == 'languages' else 'id'
        index = {r[key]: r for r in after[table]}
        assert all(index[r[key]] == r for r in rows)
    assert len(after) == 22 and len(after['cards']) == 11
    assert all(c['identity_function'] is None and c['introduction_scope'] == 'ordinary'
               for c in after['cards'][-2:])
    out = tmp_path / 'normal-output'
    export_offline(final, out)
    assert check_sqlite(out / 'content.sqlite', after)['form_targets'] == 9
    new_raw = (out / 'pack.json').read_bytes()
    second, reserved, next_groups = prepare_continuation(final, selection, groups,
        source_bytes=new_raw, source_path=str(out / 'pack.json'), batch=2, version='normal-next',
        registry_path='registry.json', groups_path='groups.json', original_path='original.json',
        source_sqlite_sha256=hashlib.sha256((out / 'content.sqlite').read_bytes()).hexdigest())
    assert second['source_pack']['schema_version'] == 4
    assert second['source_pack']['sha256'] == hashlib.sha256(new_raw).hexdigest()
    assert validate_context(final, second, reserved, next_groups, source_bytes=new_raw)['partition_counts'] == {
        'imported': 2, 'current': 2, 'future': 2}
    assert second['entries'] == selection['entries']
    with pytest.raises(ValueError, match='source bytes hash'):
        validate_context(final, second, reserved, next_groups, source_bytes=raw)
    bad = copy.deepcopy(second)
    bad['entries'][2]['card_ref'] = bad['entries'][0]['card_ref']
    with pytest.raises(ValueError):
        validate_context(final, bad, reserved, next_groups, source_bytes=new_raw)


def setup_zip_root(tmp_path, monkeypatch, source, raw, selection, registry, groups):
    import export_authoring_context as exporter
    from sprachpipe import linter
    real_root = exporter.ROOT
    paths = ['pipeline/scripts/import_editorial_patch.py', 'pipeline/scripts/finalize_curation.py',
        'pipeline/scripts/export_authoring_context.py', 'pipeline/data/curation/editorial_content_v2.schema.json',
        'pipeline/config.yaml', 'pipeline/pyproject.toml', 'pipeline/requirements.lock',
        'AGENTS.md', 'PRODUCT.md', 'docs/content-schema.md', 'docs/pipeline.md', 'docs/learning-groups-v1.md']
    paths += [p.relative_to(real_root).as_posix() for p in (real_root / 'pipeline/src/sprachpipe').glob('*.py')]
    for name in paths:
        dest = tmp_path / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes((real_root / name).read_bytes())
    (tmp_path / 'pack.json').write_bytes(raw)
    for name, value in [('selection.json', selection), ('registry.json', registry), ('groups.json', groups)]:
        (tmp_path / name).write_bytes(encode(value))
    export_sqlite(source, tmp_path / 'content.sqlite')
    assets = tmp_path / 'assets/content/en'; assets.mkdir(parents=True)
    sqlite = (tmp_path / 'content.sqlite').read_bytes()
    (assets / 'content.sqlite').write_bytes(sqlite)
    (assets / 'content.manifest.json').write_bytes(encode(dict(sha256=hashlib.sha256(sqlite).hexdigest(),
        version=source['release']['version'], source={'path': 'content.sqlite'})))
    model = tmp_path / 'model'; model.mkdir()
    for name in ('config.cfg', 'tokenizer', 'meta.json'):
        (model / name).write_text('Synthetic model fixture')
    monkeypatch.setattr(linter, '_nlp', lambda: SimpleNamespace(path=model, meta={'version':'test'}, disabled=[]))
    monkeypatch.setattr(exporter, 'ROOT', tmp_path)


@pytest.mark.parametrize('size,current', [(450,90), (1500,100)])
def test_450_goal_normal_zip_carries_22_tables_and_only_90_current_tasks(tmp_path, monkeypatch, size, current):
    started = time.perf_counter()
    source, raw, selection, registry, groups = normal_context(size, current)
    setup_zip_root(tmp_path, monkeypatch, source, raw, selection, registry, groups)
    archive = tmp_path / f'normal-{size}.zip'
    export(tmp_path / 'selection.json', archive, 1)
    result = verify_zip(archive)
    assert result['sqlite_tables'] == 22 and result['selected'] == size
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        context = json.loads(z.read(f'normal-{size}/authoring_context.json'))
        assert context['format_version'] == 2
        assert context['import_contract']['format_version'] == 2
        assert context['import_contract']['content_schema_version'] == 4
        assert {k: len(v) for k, v in context['partitions'].items()} == {'imported': 0, 'current': current, 'future': size-current}
        assert len(context['entries']) == current
        assert len(json.loads(z.read(f'normal-{size}/all_selection_identities.json'))) == size
        assert z.read(f'normal-{size}/pack.json') == raw
        assert 'Schema 4' in z.read(f'normal-{size}/README.txt').decode()
        data = {n: z.read(n) for n in z.namelist()}
        print(f'SYNTHETIC ZIP goals={size} current={current} compressed={archive.stat().st_size} '
              f'uncompressed={sum(i.file_size for i in z.infolist())} seconds={time.perf_counter()-started:.3f}')
    with pytest.raises(ValueError, match='output already exists'):
        export(tmp_path / 'selection.json', archive, 1)
    # A false downgrade, even with recomputed file hashes, must fail semantically.
    context['import_contract']['content_schema_version'] = 3
    data[f'normal-{size}/authoring_context.json'] = encode(context)
    manifest = json.loads(data[f'normal-{size}/manifest.json'])
    manifest['files']['authoring_context.json'] = hashlib.sha256(data[f'normal-{size}/authoring_context.json']).hexdigest()
    data[f'normal-{size}/manifest.json'] = encode(manifest)
    bad = tmp_path / 'false-schema.zip'
    with zipfile.ZipFile(bad, 'w') as z:
        for name, payload in data.items():
            z.writestr(name, payload)
    with pytest.raises(ValueError, match='content-schema contract'):
        verify_zip(bad)


@pytest.mark.parametrize('size', [6, 1500])
def test_normal_cli_continuation_exports_verified_schema4_context(tmp_path, monkeypatch, size):
    source, raw, selection, registry, groups = normal_context(size, batch_size=2 if size == 6 else 100, first_two=True)
    final = create_content(source, normal_delivery(source, raw, selection, registry),
                           registry, source_hash=hashlib.sha256(raw).hexdigest())
    for table in TABLES:
        assert final[table] == source[table]
    before, after = build_rows(source), build_rows(final)
    for table, old_rows in before.items():
        if table != 'content_releases':
            assert all(row in after[table] for row in old_rows)
    for table, values in source.items():
        if isinstance(values, list):
            assert final[table][:len(values)] == values
    # The actual CLI reads the new synthetic staged source, not the old base.
    setup_zip_root(tmp_path, monkeypatch, final, encode(final), selection, registry, groups)
    for folder in ('selection', 'words', 'learning_groups'):
        (tmp_path / 'pipeline/data' / folder).mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(sys, 'argv', ['export_authoring_context.py', '--selection',
        str(tmp_path / 'selection.json'), '--prepare-continuation', 'synthetic-next', '--batch', '2'])
    exporter.main()
    path = tmp_path / 'pipeline/data/selection/synthetic-next.json'
    continued = json.loads(path.read_bytes())
    assert continued['source_pack']['schema_version'] == 4
    assert continued['source_pack']['sha256'] == hashlib.sha256(encode(final)).hexdigest()
    archive = tmp_path / 'normal-batch2.zip'
    export(path, archive, 2)
    result = verify_zip(archive)
    assert result['sqlite_tables'] == 22
    current = sum(e['authoring_batch'] == 2 for e in selection['entries'])
    assert result['partition_counts'] == {'imported': 2, 'current': current, 'future': size-2-current}
    print(f'CONTINUATION goals={size} partitions={result["partition_counts"]} tables=22; old values/form tables unchanged')
    with zipfile.ZipFile(archive) as z:
        context = json.loads(z.read('normal-batch2/authoring_context.json'))
        assert context['new_deck'] is None and context['existing_deck'] == 'animals'
        assert context['import_contract']['format_version'] == 2
        assert context['import_contract']['content_schema_version'] == 4


@pytest.mark.parametrize('failure', ['source', 'reference', 'owner', 'schema', 'source_schema', 'oversize_batch',
                                     'alternative', 'retired_alternative'])
def test_normal_schema4_still_rejects_invalid_contexts(failure):
    source, raw, selection, registry, groups = normal_context(6, batch_size=2)
    if failure == 'source': raw += b' '
    if failure == 'reference': groups['existing']['cards'][0]['primary_card_ref'] = 'missing'
    if failure == 'owner': registry['words'][-1]['form_norm'] = registry['words'][0]['form_norm']
    if failure == 'schema': source['release']['schema_version'] = 5
    if failure == 'source_schema': selection['source_pack']['schema_version'] = 3
    if failure == 'oversize_batch':
        source, raw, selection, registry, groups = normal_context(102, batch_size=102)
    if failure in ('alternative', 'retired_alternative'):
        link = source['card_sentences'][0]
        if failure == 'retired_alternative':
            # Preserve the required active sentence while adding historical evidence.
            old_ref = link['sentence']
            historical = copy.deepcopy(next(s for s in source['sentences'] if s['ref'] == old_ref))
            historical['ref'] = old_ref + '-historical'
            historical['text'] = historical['text'][:-1] + '!'
            source['sentences'].append(historical)
            source['sentence_tokens'] += [dict(t, sentence=historical['ref'],
                                               surface='!' if t['surface'] == '.' else t['surface'])
                                          for t in source['sentence_tokens'] if t['sentence'] == old_ref]
            link = dict(link, sentence=historical['ref'])
            link['removed_in'] = source['release']['version']
            source['card_sentences'].append(link)
        link['valid_alternatives'] = [selection['entries'][-1]['form']]
        raw = encode(source)
        selection['source_pack'].update(sha256=hashlib.sha256(raw).hexdigest(), canonical_sha256=digest(source))
        registry['source_pack_sha256'] = groups['source_pack_sha256'] = selection['source_pack']['sha256']
        selection['registry_sha256'] = digest(registry)
        selection['learning_groups_sha256'] = digest(groups)
        with pytest.raises(ValueError, match='already offered word'):
            validate_context(source, selection, registry, groups, source_bytes=raw)
        return
    if failure == 'reference': selection['learning_groups_sha256'] = digest(groups); groups['parent_sha256'] = digest(groups['existing']); selection['learning_groups_sha256'] = digest(groups)
    selection['registry_sha256'] = digest(registry)
    with pytest.raises((ValueError, KeyError)):
        validate_context(source, selection, registry, groups, source_bytes=raw)


def test_normal_v2_rejects_unknown_source_schema():
    source, raw, selection, registry, _ = normal_context(6, batch_size=2)
    source['release']['schema_version'] = 5
    raw = encode(source)
    with pytest.raises(ValueError, match='source schema incompatible'):
        create_content(source, normal_delivery(source, raw, selection, registry), registry,
                       source_hash=hashlib.sha256(raw).hexdigest())
