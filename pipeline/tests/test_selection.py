import copy
import json
from pathlib import Path

import pytest

from sprachpipe.cli import main, run_generate
from sprachpipe.config import load_config
from sprachpipe.export import export_sqlite
from sprachpipe.pack import build_rows
from sprachpipe.selection import plan_selection, partition_selection, print_plan

FIXTURE = Path(__file__).parent / 'fixtures' / 'mini_pack.json'


@pytest.fixture
def inputs(tmp_path):
    pack = json.loads(FIXTURE.read_text(encoding='utf-8'))
    db = tmp_path / 'content.sqlite'
    export_sqlite(pack, db)
    entry = {'form':'vase','lemma':'vase','pos':'NOUN','form_kind':'base',
             'proposed_sense_key':'vase#gefaess','sense_key':None,
             'target_meaning_de':'Möbel zum Essen','translation_de':'Tisch',
             'form_label_de':'Substantiv, Singular','cefr_band':'anfaenger',
             'topic':'Haushalt','reason':'Konkreter Alltagsgegenstand',
             'frequency':{'rank':958}}
    data = {'version':1,'lang':'en','entries':[entry]}
    path = tmp_path / 'selection.json'
    path.write_text(json.dumps(data), encoding='utf-8')
    return path, db, data


def test_missing_definition_visible_and_duplicate_rejected(inputs, tmp_path):
    path, db, data = inputs
    plan = plan_selection(path, db, inventory_path=tmp_path/'absent.json')
    assert len(plan['selected']) == 1
    assert plan['reused_sense_keys'] == 0
    del data['entries'][0]['target_meaning_de']
    path.write_text(json.dumps(data), encoding='utf-8')
    plan = plan_selection(path, db, inventory_path=tmp_path/'absent.json')
    assert plan['missing_definitions'][0]['fields'] == ['target_meaning_de']
    assert not plan['selected']
    data['entries'].append(copy.deepcopy(data['entries'][0]))
    path.write_text(json.dumps(data), encoding='utf-8')
    with pytest.raises(ValueError, match='conflicts'):
        plan_selection(path, db)


def test_existing_exact_card_reused_not_another_sense(inputs):
    path, db, data = inputs
    e = data['entries'][0]
    e.update(form='left',lemma='left',pos='ADJ',sense_key='left#links',proposed_sense_key=None)
    path.write_text(json.dumps(data), encoding='utf-8')
    plan = plan_selection(path, db)
    assert len(plan['covered']) == 1
    assert not plan['selected']
    rows = build_rows(json.loads(FIXTURE.read_text(encoding='utf-8')))
    assert plan['covered'][0]['card_id'] in {r['id'] for r in rows['cards']}
    e.update(sense_key=None,proposed_sense_key='left#remaining')
    path.write_text(json.dumps(data), encoding='utf-8')
    with pytest.raises(ValueError, match='different meaning'):
        plan_selection(path, db)


def test_dry_run_never_initializes_llm_or_writes(inputs, tmp_path, monkeypatch, capsys):
    from sprachpipe import llm
    monkeypatch.setattr(llm, 'Llm', lambda *a, **kw: pytest.fail('LLM initialized'))
    path, db, _ = inputs
    run = tmp_path / 'new-run'
    argv = ['generate','--selection',str(path),'--existing-pack',str(db),
            '--run-dir',str(run),'--out',str(run/'pack.json'),'--max-usd','3','--dry-run']
    assert main(argv) == 0
    assert not run.exists()
    assert 'Cards planned: 1' in capsys.readouterr().out
    argv[argv.index('3')] = '3.01'
    assert main(argv) == 2


def test_selected_generation_bypasses_other_meanings_preserves_ids(tmp_path, monkeypatch):
    from test_generate import FakeVertex, WENT
    from sprachpipe import generate
    cfg = load_config()
    cfg['generate']['concurrency'] = 1
    inv = tmp_path / 'meanings.json'
    other = {**WENT, 'sense_key':'go#work', 'gloss_de':'funktionieren'}
    inv.write_text(json.dumps({'lang':'en','forms':{'went':[WENT, other]}}), encoding='utf-8')
    before = inv.read_bytes()
    monkeypatch.setattr(generate, 'meanings', lambda *a, **kw: pytest.fail('meaning expansion'))
    fake = FakeVertex(cfg, tmp_path/'ledger.csv', 3)
    aborted = run_generate(fake, cfg, [('went',50)], tmp_path/'pack.json', tmp_path,
        max_usd=3, label='exact', inventory_path=inv, selected_meanings={'went':[WENT]})
    assert aborted is None
    pack = json.loads((tmp_path/'pack.json').read_text(encoding='utf-8'))
    assert len(pack['cards']) == 1
    assert pack['cards'][0]['sense'].endswith('go#gehen')
    assert 'meanings' not in fake.calls
    assert 'annotate' in fake.calls and 'sense_key' in fake.calls
    assert inv.read_bytes() == before
    actual = build_rows(pack)['cards'][0]['id']
    fixture = build_rows(json.loads(FIXTURE.read_text(encoding='utf-8')))
    assert actual == next(r['id'] for r in fixture['cards'] if r['form']=='went')


def test_versioned_editorial_selection_has_100_distinct_targets():
    path = Path(__file__).parents[1]/'data'/'selection'/'everyday_v1.json'
    entries = json.loads(path.read_text(encoding='utf-8'))['entries']
    assert len(entries) == len({e['lemma'] for e in entries}) == 100
    assert {p:sum(e['pos']==p for e in entries) for p in ['NOUN','VERB','ADJ']} == {
        'NOUN':60,'VERB':25,'ADJ':15}
    for form, tr in [('table','Tisch'),('speaker','Lautsprecher'),('bandage','Verband')]:
        assert next(e['translation_de'] for e in entries if e['form']==form) == tr
    assert all(e['target_meaning_de'] and e['form'] == e['lemma'] and
               e['definition_status']=='editorial_proposal_not_sentence_validated' for e in entries)
    missing = json.loads(path.with_name('everyday_v1_missing.json').read_text(encoding='utf-8'))['entries']
    assert len(missing) == len({e['lemma'] for e in missing}) == 13
    assert all(e == next(original for original in entries if original['lemma']==e['lemma'])
               for e in missing)


def test_partition_uses_form_lemma_pos_and_sense_not_surface():
    pack = json.loads(FIXTURE.read_text(encoding='utf-8'))
    entries = [
        {'form':'left','lemma':'left','pos':'ADJ','sense_key':'left#links','target_meaning_de':'links'},
        {'form':'left','lemma':'left','pos':'ADJ','proposed_sense_key':'left#remaining','target_meaning_de':'übrig'},
        {'form':'left','lemma':'other','pos':'ADJ','sense_key':'left#links'},
        {'form':'left','lemma':'left','pos':'NOUN','sense_key':'left#links'},
        {'form':'leaving','lemma':'leave','pos':'VERB','sense_key':'leave#verlassen'},
    ]
    before = copy.deepcopy(entries)
    present, missing = partition_selection(entries, pack)
    assert present == entries[:1] and missing == entries[1:]
    assert entries == before and all(a is b for a,b in zip(missing, entries[1:]))
    assert len(present)+len(missing)==len(entries)
    # Annotation/meaning rows alone are not packed learning cards.
    pack['cards'] = []
    pack['card_sentences'] = []
    pack['deck_cards'] = []
    pack['dictionary_forms'] = []
    pack['sentence_tokens'] = []
    assert partition_selection(entries, pack) == ([], entries)


def test_dry_run_reports_actual_limit_reservations(inputs, tmp_path, capsys):
    path, db, _ = inputs
    plan = plan_selection(path, db)
    cfg = load_config()
    print_plan(plan, cfg, 1)
    current = capsys.readouterr().out
    assert 'configured max_output_tokens=4096; reservation/call=0.016035 USD' in current
    cfg['llm']['max_output_tokens']['meaning_check'] = 1024
    print_plan(plan, cfg, 1)
    old = capsys.readouterr().out
    assert 'configured max_output_tokens=1024; reservation/call=0.004515 USD' in old


def test_selection_refuses_existing_output_directory(inputs, tmp_path, monkeypatch):
    from sprachpipe import llm
    monkeypatch.setattr(llm, 'Llm', lambda *a, **kw: pytest.fail('LLM initialized'))
    path, db, _ = inputs
    run = tmp_path/'already-exists'
    run.mkdir()
    assert main(['generate','--selection',str(path),'--existing-pack',str(db),
                 '--run-dir',str(run),'--out',str(run/'pack.json'),'--max-usd','1','--dry-run']) == 2
    assert not list(run.iterdir())
