import json

from sprachpipe.lemmas import as_text, select_lemmas

POS = ["NOUN", "VERB", "ADJ", "ADV"]

FAKE = {
    "go": ("go", "VERB", False),
    "went": ("go", "VERB", False),
    "goes": ("go", "VERB", False),
    "house": ("house", "NOUN", False),
    "houses": ("house", "NOUN", False),
    "the": ("the", "DET", False),
    "london": ("london", "PROPN", False),
    "ten": ("ten", "NUM", True),
    "true": ("true", "ADJ", False),
    "null": ("null", "ADJ", False),
    "false": ("false", "ADJ", False),
}


def fake_analyze(word):
    return FAKE.get(word)


def test_groups_forms_and_ranks_by_summed_frequency():
    words = [("the", 9.0), ("house", 1.0), ("go", 2.0), ("went", 1.5), ("houses", 0.5), ("goes", 0.2)]
    result = select_lemmas(words, fake_analyze, POS, 60)
    assert [(e["lemma"], e["pos"], e["freq_rank"]) for e in result] == [
        ("go", "VERB", 1), ("house", "NOUN", 2)]
    assert [f["form"] for f in result[0]["forms"]] == ["go", "went", "goes"]
    assert abs(sum(f["freq"] for f in result[0]["forms"]) - 3.7) < 1e-9


def test_function_words_proper_nouns_and_numbers_are_dropped():
    words = [("the", 9.0), ("london", 5.0), ("ten", 4.0), ("go", 1.0)]
    assert [e["lemma"] for e in select_lemmas(words, fake_analyze, POS, 60)] == ["go"]


def test_max_rank_limits_output():
    words = [("go", 2.0), ("house", 1.0)]
    assert len(select_lemmas(words, fake_analyze, POS, 1)) == 1


def test_literal_headwords_stay_text():
    # As a YAML/Excel parser might deliver them: True, None, False.
    words = [(True, 3.0), (None, 2.0), (False, 1.0)]
    result = select_lemmas(words, fake_analyze, POS, 60)
    assert [e["lemma"] for e in result] == ["true", "null", "false"]
    roundtrip = json.loads(json.dumps(result))
    assert all(isinstance(e["lemma"], str) for e in roundtrip)
    assert all(isinstance(f["form"], str) for e in roundtrip for f in e["forms"])


def test_as_text():
    assert as_text(True) == "true"
    assert as_text(False) == "false"
    assert as_text(None) == "null"
    assert as_text("null") == "null"
