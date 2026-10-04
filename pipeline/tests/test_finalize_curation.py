"""Offline finalization of a saved curation run (scripts/finalize_curation.py).
Synthetic packs and a simulated run; no out/, no network."""

import copy
import importlib.util
import json
import sqlite3

import pytest

from sprachpipe.config import PIPELINE_DIR
from sprachpipe.curate import curate

from test_complete_curation import CFG, FakeLlm, Inventory, script as complete
from test_curate import CURATION, META, PACKS

SCRIPT = PIPELINE_DIR / "scripts" / "finalize_curation.py"
spec = importlib.util.spec_from_file_location("finalize_curation", SCRIPT)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)

WENT = ("went", "go/VERB|go#gehen")


def finished_run():
    """Simulated completed run: only dictionary_forms open, one known conflict
    on 'went' ('ging' from the sources vs. 'ging (gehen)' from the annotation)."""
    packs = copy.deepcopy(PACKS)
    entries = [{"form": "went", "sense": WENT[1], "card": None, "gloss_de": "ging", "rank": 1},
               {"form": "at", "sense": "at/ADP|at#zeit", "card": "at|at/ADP|at#zeit",
                "gloss_de": "um", "rank": 1},
               {"form": "up", "sense": "up/ADV|up#hinauf", "card": "up|up/ADV|up#hinauf",
                "gloss_de": "hinauf", "rank": 1}]
    packs["base"]["dictionary_forms"], packs["extra"]["dictionary_forms"] = entries, []
    work, log = curate(packs, CURATION, META)
    cards = {c["ref"]: complete.card_info(work, Inventory(), c["ref"]) for c in work["cards"]}
    report, aborted = complete.run(FakeLlm(), CFG, work, cards, lambda w, r: None)
    assert aborted is None and [p["kind"] for p in work["curation"]["pending"]] == ["dictionary_forms"]
    return work, dict(report, inputs={"curation_log": log})


def resolutions(**change):
    r = {"form": WENT[0], "sense": WENT[1], "gloss_de": "ging (gehen)",
         "expected_variants": ["ging", "ging (gehen)"], "reason": "erklärend vs. kurz"}
    r.update(change)
    work, _ = finished_run()
    keys = len({(t["surface"].lower(), t["sense"]) for t in work["sentence_tokens"] if t["sense"]})
    return {"version": "test-res-v1", "applies_to": "test-curation-v1",
            "expect": {"cards": 3, "card_sentences": 9, "dictionary_keys": keys}, "resolutions": [r]}


def test_editorial_form_gloss_keeps_all_source_variants_and_checks_preconditions():
    work, report = finished_run()
    r = resolutions(gloss_de='ging / begab sich', editorial=True, reason='Formgerechte Präzisierung')
    final, summary, _ = script.finalize_state(work, report, r)
    resolved = summary['resolved_conflicts'][0]
    assert resolved['origin']['editorial'] is True
    assert {x['gloss_de'] for x in resolved['origin']['resolution']['rejected']} == {'ging', 'ging (gehen)'}
    assert next(d for d in final['dictionary_forms'] if d['form'] == 'went')['gloss_de'] == 'ging / begab sich'
    r['resolutions'][0]['expected_variants'].append('unknown')
    with pytest.raises(script.FinalizeError, match='variants'):
        script.finalize_state(work, report, r)


def test_exact_resolution_resolves_only_its_conflict_and_keeps_origin():
    work, report = finished_run()
    snapshot = copy.deepcopy((work, report))
    final, summary, _ = script.finalize_state(work, report, resolutions())
    assert (work, report) == snapshot   # inputs untouched
    went = next(d for d in final["dictionary_forms"] if (d["form"], d["sense"]) == WENT)
    assert went["gloss_de"] == "ging (gehen)" and went["rank"] == 1
    [resolved] = summary["resolved_conflicts"]
    assert resolved["origin"]["resolution"]["rejected"][0]["gloss_de"] == "ging"
    assert resolved["origin"]["resolution"]["rejected"][0]["sources"]["base"]["rank"] == 1
    others = {(d["form"], d["sense"]): d["gloss_de"] for d in final["dictionary_forms"]}
    assert others[("at", "at/ADP|at#zeit")] == "um" and "curation" not in final
    # sense glosses unchanged
    assert next(s for s in final["senses"] if s["ref"] == WENT[1])["gloss_de"] == "go#gehen"
    assert final["release"]["notes"].startswith("INTERNES TEST-PACK")


@pytest.mark.parametrize("change,message", [
    ({"expected_variants": ["ging", "gingen"]}, "variants"),
    ({"gloss_de": "gingen"}, "choice missing"),
    ({"sense": "go/VERB|go#laufen"}, "not in the token set"),
])
def test_unknown_or_changed_variants_abort(change, message):
    work, report = finished_run()
    with pytest.raises(script.FinalizeError, match=message):
        script.finalize_state(work, report, resolutions(**change))


def test_unresolved_conflict_and_wrong_key_count_abort():
    work, report = finished_run()
    res = resolutions()
    with pytest.raises(script.FinalizeError, match="unresolved"):
        script.finalize_state(work, report, dict(res, resolutions=[]))
    with pytest.raises(script.FinalizeError, match="dictionary keys"):
        script.finalize_state(work, report, dict(res, expect=dict(res["expect"], dictionary_keys=1)))


def test_open_qa_annotation_or_abort_prevent_finalization():
    work, report = finished_run()
    res = resolutions()
    open_qa = copy.deepcopy(work)
    open_qa["curation"]["pending"].insert(0, {"kind": "sentence_qa", "sentence": "x"})
    with pytest.raises(script.FinalizeError, match="only dictionary_forms"):
        script.finalize_state(open_qa, report, res)
    with pytest.raises(script.FinalizeError, match="aborted"):
        script.finalize_state(work, dict(report, aborted="BudgetExceeded: x"), res)
    changed = copy.deepcopy(work)
    s = next(s for s in changed["sentences"] if s["text"] == "Ben went home after work.")
    s["translation_de"] = "geändert"
    with pytest.raises(script.FinalizeError, match="does not match"):
        script.finalize_state(changed, report, res)
    no_tokens = copy.deepcopy(work)
    no_tokens["sentence_tokens"] = [t for t in no_tokens["sentence_tokens"] if t["sentence"] != s["ref"]]
    with pytest.raises(script.FinalizeError, match="without tokens"):
        script.finalize_state(no_tokens, report, res)


def test_removed_alternative_and_replaced_card_stay_removed():
    work, report = finished_run()
    back = copy.deepcopy(work)
    cs = next(c for c in back["card_sentences"]
              if any(s["ref"] == c["sentence"] and s["text"] == "We went to the park."
                     for s in back["sentences"]))
    cs["valid_alternatives"] = ["walked", "ran"]
    with pytest.raises(script.FinalizeError, match="is back"):
        script.finalize_state(back, report, resolutions())


def write_inputs(tmp_path, work, report, res):
    paths = {}
    for name, data in (("state", work), ("report", report), ("res", res)):
        paths[name] = tmp_path / f"{name}.json"
        paths[name].write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    return ["--state", str(paths["state"]), "--report", str(paths["report"]),
            "--resolutions", str(paths["res"])], paths


def test_main_writes_json_and_sqlite_with_the_same_data(tmp_path):
    work, report = finished_run()
    args, paths = write_inputs(tmp_path, work, report, resolutions())
    before = {k: p.read_bytes() for k, p in paths.items()}
    assert script.main(args + ["--out", str(tmp_path / "pack")]) == 0
    assert before == {k: p.read_bytes() for k, p in paths.items()}
    out = tmp_path / "pack"
    pack = json.loads((out / "pack.json").read_text(encoding="utf-8"))
    rep = json.loads((out / "finalization_report.json").read_text(encoding="utf-8"))
    assert rep["status"] == "ok" and rep["internal_test_pack"] and rep["ai_cost_usd"] == 0.0
    assert rep["open_editorial_cases"] and "ungeklärt" in rep["old_ids_publication"]
    conn = sqlite3.connect(out / "content.sqlite")
    try:
        db = dict(conn.execute("SELECT form_norm || '|' || rank, gloss_de FROM dictionary_forms"))
        assert conn.execute("SELECT count(*) FROM cards").fetchone()[0] == len(pack["cards"]) == 3
        assert conn.execute("SELECT count(*) FROM card_sentences").fetchone()[0] == 9
    finally:
        conn.close()
    assert db == {f"{d['form']}|{d['rank']}": d["gloss_de"] for d in pack["dictionary_forms"]}
    # existing folder refused, nothing overwritten
    assert script.main(args + ["--out", str(out)]) == 2


def test_failing_input_writes_no_success_report(tmp_path):
    work, report = finished_run()
    args, _ = write_inputs(tmp_path, work, report, dict(resolutions(), resolutions=[]))
    assert script.main(args + ["--out", str(tmp_path / "pack")]) == 2
    assert not (tmp_path / "pack").exists()


def test_export_error_is_reported_as_failed(tmp_path, monkeypatch):
    work, report = finished_run()
    args, _ = write_inputs(tmp_path, work, report, resolutions())

    def broken(pack, path):
        raise OSError("disk full")
    monkeypatch.setattr("sprachpipe.export.export_sqlite", broken)
    assert script.main(args + ["--out", str(tmp_path / "pack")]) == 3
    rep = json.loads((tmp_path / "pack" / "finalization_report.json").read_text(encoding="utf-8"))
    assert rep["status"] == "failed" and "disk full" in rep["error"]
