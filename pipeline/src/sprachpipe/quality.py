"""Deterministic sentence diversity and frequency warnings."""

from __future__ import annotations

import re
from collections import Counter
from functools import lru_cache

from .linter import CONTENT_POS, _nlp


def duplicate(text: str, gap: tuple[int, int], accepted: list[dict]) -> bool:
    def keys(value: str, span: tuple[int, int]) -> tuple[tuple[str, ...], tuple[str, ...]]:
        tokens = list(re.finditer(r"\b[\w']+\b", value.lower()))
        words = [m.group() for m in tokens]
        index = next((i for i, m in enumerate(tokens) if m.start() <= span[0] < m.end()), -1)
        window = tuple(words[max(0, index - 2):index + 3]) if index >= 0 else ()
        return window, tuple(words[:4])
    window, prefix = keys(text, gap)
    for a in accepted:
        other_window, other_prefix = keys(a["text"], a["gap"])
        if window == other_window or prefix == other_prefix:
            return True
    return False


def content_lemmas(text: str, form: str, *, nlp=None) -> set[str]:
    return {t.lemma_.lower() for t in (nlp or _nlp())(text)
            if t.pos_ in CONTENT_POS and t.text.lower() != form.lower()}


def common_lemmas(cards: list[dict]) -> list[str]:
    counts: Counter[str] = Counter()
    for card in cards:
        if len(card.get("accepted", [])) == 3:
            for a in card["accepted"]:
                counts.update(content_lemmas(a["text"], card["form"]))
    return [lemma for lemma, _ in counts.most_common(15)]


def overused_lemmas(cards: list[dict]) -> list[tuple[str, int, int]]:
    counts: Counter[str] = Counter()
    n = 0
    for card in cards:
        if card.get("packed"):
            for a in card["accepted"]:
                n += 1
                counts.update(content_lemmas(a["text"], card["form"]))
    limit = max(4, n * 0.05)
    return [(word, count, n) for word, count in counts.most_common() if count > limit]


def lemma_ranks(cfg: dict) -> dict[str, int]:
    """Rank the top wordfreq forms after lemma grouping as in lemmas.py."""
    c = cfg["lemmas"]
    return _cached_lemma_ranks(c["lang"], c["top_n"], c["spacy_model"],
                               tuple(c["pos_allowed"]))


@lru_cache(maxsize=4)
def _cached_lemma_ranks(lang: str, top_n: int, model: str,
                        pos_allowed: tuple[str, ...]) -> dict[str, int]:
    from .lemmas import select_lemmas, spacy_analyzer, wordfreq_words

    selected = select_lemmas(wordfreq_words(lang, top_n),
                             spacy_analyzer(model), pos_allowed, top_n)
    return {entry["lemma"]: entry["freq_rank"] for entry in selected}
