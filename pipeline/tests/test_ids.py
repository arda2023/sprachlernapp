import copy
import hashlib
import json
from pathlib import Path

import pytest

from sprachpipe.ids import canonical_string, form_norm, stable_id
from sprachpipe.pack import build_rows

FIXTURE = Path(__file__).parent / "fixtures" / "mini_pack.json"

# Fixed vectors: changing ids.py must never change these.
VECTORS = [
    (("lemmas", {"lang": "en", "lemma": "go", "pos": "VERB"}), "d9ce94d26140d06c4037860a9e525be1"),
    (("senses", {"lemma_id": "x", "sense_key": "bank#ufer"}), "258d3d613733c71b1e09dee2ad230231"),
    (("cards", {"lang": "en", "form": "went", "sense_id": "abc"}), "2bcd29e176b3d195896ae0a0e1261188"),
    (("sentence_tokens", {"sentence_id": "s", "idx": 3}), "ddf24f141adaeaf788a0667f65bf4357"),
    (("decks", {"lang": "en", "slug": "travel"}), "afe5077c45631f4048516136db70ab04"),
    (("stories", {"lang": "en", "slug": "travel"}), "f515e22eebe22bec2bb92646b10405b4"),
]


@pytest.mark.parametrize(("args", "expected"), VECTORS)
def test_fixed_vectors(args, expected):
    table, fields = args
    assert stable_id(table, **fields) == expected


def test_rule_spelled_out():
    expected = hashlib.sha256("lemmas\u001fen\u001fgo\u001fVERB".encode()).digest()[:16].hex()
    assert stable_id("lemmas", lang="en", lemma="go", pos="VERB") == expected


def test_keyword_order_does_not_matter():
    assert stable_id("cards", sense_id="abc", form="went", lang="en") == VECTORS[2][1]


def test_nfc_normalization():
    composed = "café"
    decomposed = "café"
    assert stable_id("decks", lang="en", slug=composed) == stable_id("decks", lang="en", slug=decomposed)


def test_same_key_in_different_tables_differs():
    assert VECTORS[4][1] != VECTORS[5][1]


def test_gloss_is_not_a_key_field():
    with pytest.raises(ValueError):
        stable_id("senses", lemma_id="x", sense_key="bank#ufer", gloss_de="Ufer")


def test_changing_gloss_keeps_sense_id():
    pack = json.loads(FIXTURE.read_text(encoding="utf-8"))
    changed = copy.deepcopy(pack)
    changed["senses"][0]["gloss_de"] = "laufen (korrigiert)"
    before = build_rows(pack)["senses"][0]
    after = build_rows(changed)["senses"][0]
    assert before["gloss_de"] != after["gloss_de"]
    assert before["id"] == after["id"]


def test_missing_or_none_fields_rejected():
    with pytest.raises(ValueError):
        stable_id("lemmas", lang="en", lemma="go")
    with pytest.raises(ValueError):
        stable_id("lemmas", lang="en", lemma=None, pos="VERB")


def test_canonical_string_order():
    assert canonical_string("senses", sense_key="k", lemma_id="l") == "senses\u001fl\u001fk"


def test_form_norm():
    assert form_norm("Don’t") == "don't"
    assert form_norm("Café") == "café"
