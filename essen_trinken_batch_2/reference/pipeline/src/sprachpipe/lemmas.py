"""Lemma selection: wordfreq word forms → spaCy lemma + POS → frequency rank.

Forms are grouped by (lemma, POS); a group's frequency is the sum of its
forms. Ranks count only groups that pass the filter (pilot: NOUN, VERB, ADJ,
ADV; proper nouns and numbers out). Function words stay out on purpose
(open decision, docs/pipeline.md).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Iterable

# analyze(word) → (lemma, pos, is_number), or None if the word is skipped.
Analyzer = Callable[[str], "tuple[str, str, bool] | None"]


def as_text(value: object) -> str:
    """Words are always text. Guards against parsers that turned the
    headwords "null", "true", "false" into None/bool."""
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


@dataclass
class LemmaGroup:
    lemma: str
    pos: str
    freq: float
    forms: dict[str, float]


def spacy_analyzer(model: str = "en_core_web_sm") -> Analyzer:
    import spacy

    nlp = spacy.load(model, disable=["parser", "ner"])

    def analyze(word: str):
        doc = nlp(word)
        if len(doc) != 1:  # contractions and fragments ("don't" → do + n't)
            return None
        tok = doc[0]
        return tok.lemma_.lower(), tok.pos_, tok.like_num
    return analyze


def select_lemmas(
    words: Iterable[tuple[object, float]],
    analyze: Analyzer,
    pos_allowed: Iterable[str],
    max_rank: int,
) -> list[dict]:
    """Groups (word, frequency) pairs into ranked lemmas; returns at most
    [max_rank] entries as JSON-ready dicts."""
    allowed = set(pos_allowed)
    groups: dict[tuple[str, str], LemmaGroup] = {}
    for raw, freq in words:
        word = as_text(raw)
        result = analyze(word)
        if result is None:
            continue
        lemma, pos, is_number = result
        lemma = as_text(lemma)
        if is_number or pos in ("PROPN", "NUM") or pos not in allowed:
            continue
        if not word.isalpha():
            continue
        g = groups.setdefault((lemma, pos), LemmaGroup(lemma, pos, 0.0, {}))
        g.freq += freq
        g.forms[word] = g.forms.get(word, 0.0) + freq

    ranked = sorted(groups.values(), key=lambda g: (-g.freq, g.lemma, g.pos))
    return [
        {
            "lemma": g.lemma,
            "pos": g.pos,
            "freq_rank": rank,
            "forms": [
                {"form": f, "freq": fq}
                for f, fq in sorted(g.forms.items(), key=lambda kv: (-kv[1], kv[0]))
            ],
        }
        for rank, g in enumerate(ranked[:max_rank], start=1)
    ]


def wordfreq_words(lang: str, top_n: int) -> list[tuple[str, float]]:
    from wordfreq import top_n_list, word_frequency

    return [(w, word_frequency(w, lang)) for w in top_n_list(lang, top_n)]
