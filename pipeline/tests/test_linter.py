import pytest

from sprachpipe.linter import lint_sentence

RANKS = {"go": 1, "home": 2, "work": 3, "house": 4, "leave": 5, "see": 6, "big": 7}


def rules(findings, level=None):
    return {f.rule for f in findings if level is None or f.level == level}


def lint(sentence, form, **kw):
    start = sentence.find(form)
    return lint_sentence(sentence, form, start, start + len(form), kw.pop("allowed_rank", 60), **kw)


GOOD = "She went home after work."


def test_good_sentence_has_no_errors():
    assert rules(lint(GOOD, "went"), "error") == set()


def test_gap_offsets():
    assert "gap" not in rules(lint_sentence(GOOD, "went", 4, 8, 60))
    assert "gap" in rules(lint_sentence(GOOD, "went", 3, 7, 60), "error")


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


def test_digits_warn():
    assert "digits" not in rules(lint(GOOD, "went"))
    assert "digits" in rules(lint("She went home at 7.", "went"), "warn")


@pytest.mark.parametrize("sentence", ["She went home after work."])
def test_i_plus_one_ok(sentence):
    assert "i+1" not in rules(lint(sentence, "went", ranks=RANKS, allowed_rank=10))


def test_i_plus_one_warns_on_rare_word():
    findings = lint("She went home after the negotiation.", "went", ranks=RANKS, allowed_rank=10)
    assert "i+1" in rules(findings, "warn")
    assert "i+1" not in rules(findings, "error")


def test_i_plus_one_ignores_the_gap_word():
    # "went" itself is unknown to RANKS-less lemma lists; the gap is never checked.
    findings = lint("She went home.", "went", ranks={"home": 1}, allowed_rank=10)
    assert "i+1" not in rules(findings)
