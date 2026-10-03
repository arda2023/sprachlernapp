import pytest

from sprachpipe.linter import lint_sentence

def rules(findings, level=None):
    return {f.rule for f in findings if level is None or f.level == level}


def lint(sentence, form, **kw):
    start = sentence.find(form)
    return lint_sentence(sentence, form, start, start + len(form), kw.pop("min_zipf", 4.0), **kw)


GOOD = "She went home after work."


def test_good_sentence_has_no_errors():
    assert rules(lint(GOOD, "went"), "error") == set()


def test_gap_offsets():
    assert "gap" not in rules(lint_sentence(GOOD, "went", 4, 8, 4.0))
    assert "gap" in rules(lint_sentence(GOOD, "went", 3, 7, 4.0), "error")


def test_form_repeated():
    assert "repeat" not in rules(lint(GOOD, "went"))
    assert "repeat" in rules(lint("She went home and went out.", "went"), "error")


def test_whole_token_only_for_repeat():
    # "wentworth" is not the token "went"
    assert "repeat" not in rules(lint("She went to Wentworth Street.", "went"))


def test_length():
    assert "length" not in rules(lint(GOOD, "went"))
    long = "She went to the old shop on the corner of the street near the big park."
    assert "length" in rules(lint(long, "went"), "error")


def test_length_is_configurable():
    assert "length" in rules(lint(GOOD, "went", max_words=3), "error")


def test_subclauses():
    assert "subclauses" not in rules(lint("She went home because it rained.", "went"))
    bad = "The man who lives here said that he went home because it rained."
    assert "subclauses" in rules(lint(bad, "went"), "error")


def test_ending():
    assert "ending" not in rules(lint("Did she go home?", "go"))
    assert "ending" in rules(lint("She went home", "went"), "error")


@pytest.mark.parametrize("sentence", ['She said "Go."', 'She asked "Go?"', 'Go!)'])
def test_ending_allows_closing_quotes_and_brackets(sentence):
    assert "ending" not in rules(lint(sentence, "Go", zipf=lambda word, lang: 5.0), "error")


def test_ending_rejects_closer_without_punctuation():
    assert "ending" in rules(lint('She said "Go"', "Go"), "error")


def test_gap_allows_capital_i_in_sentence_middle():
    sentence = "Today I went home."
    assert "gap" not in rules(lint_sentence(sentence, "i", 6, 7, 4.0), "error")


def test_digits_warn():
    assert "digits" not in rules(lint(GOOD, "went"))
    assert "digits" in rules(lint("She went home at 7.", "went"), "warn")


@pytest.mark.parametrize("sentence", ["She went home after work."])
def test_i_plus_one_ok(sentence):
    assert "i+1" not in rules(lint(sentence, "went", zipf=lambda word, lang: 5.0))


def test_i_plus_one_warns_on_rare_word():
    frequency = lambda word, lang: 3.0 if word == "negotiation" else 5.0
    findings = lint("She went home after the negotiation.", "went", zipf=frequency)
    assert "i+1" in rules(findings, "warn")
    assert "i+1" not in rules(findings, "error")


def test_i_plus_one_ignores_the_gap_word():
    frequency = lambda word, lang: 0.0 if word in ("went", "go") else 5.0
    findings = lint("She went home.", "went", zipf=frequency)
    assert "i+1" not in rules(findings)


def test_i_plus_one_uses_higher_of_lemma_and_surface_and_excludes_names_numbers():
    values = {"good": 3.0, "best": 4.2, "book": 4.1, "mia": 0.0, "7": 0.0}
    frequency = lambda word, lang: values.get(word, 5.0)
    findings = lint("Mia went to the best book at 7.", "went", zipf=frequency,
                    names=["Mia"])
    assert "i+1" not in rules(findings)
