"""Sentence linter (docs/pipeline.md, QA rules). No AI calls."""

from __future__ import annotations

import re
from dataclasses import dataclass
from functools import lru_cache

SUBCLAUSE_DEPS = {"advcl", "relcl", "ccomp", "csubj", "acl:relcl"}
CONTENT_POS = {"NOUN", "VERB", "ADJ", "ADV"}


@dataclass(frozen=True)
class Finding:
    level: str  # "error" or "warn"
    rule: str
    message: str


@lru_cache(maxsize=1)
def _nlp(model: str = "en_core_web_sm"):
    import spacy

    return spacy.load(model, disable=["ner"])


def _whole_token_count(text: str, form: str) -> int:
    pattern = r"(?<!\w)" + re.escape(form) + r"(?!\w)"
    return len(re.findall(pattern, text, flags=re.IGNORECASE))


def lint_sentence(
    sentence: str,
    form: str,
    gap_start: int,
    gap_end: int,
    min_zipf: float,
    *,
    lang: str = "en",
    names: list[str] | tuple[str, ...] = (),
    zipf=None,
    max_words: int = 14,
    max_subclauses: int = 1,
    nlp=None,
) -> list[Finding]:
    """Findings for one card sentence; i+1 uses the higher Zipf value."""
    findings: list[Finding] = []
    doc = (nlp or _nlp())(sentence)

    if sentence[gap_start:gap_end].casefold() != form.casefold():
        findings.append(Finding("error", "gap", f"text[{gap_start}:{gap_end}] is "
                                f"{sentence[gap_start:gap_end]!r}, expected {form!r}"))

    if _whole_token_count(sentence, form) > 1:
        findings.append(Finding("error", "repeat", f"{form!r} occurs more than once"))

    words = [w for w in sentence.split() if re.search(r"\w", w)]
    if len(words) > max_words:
        findings.append(Finding("error", "length", f"{len(words)} words, max {max_words}"))

    subclauses = [t.text for t in doc if t.dep_ in SUBCLAUSE_DEPS]
    if len(subclauses) > max_subclauses:
        findings.append(Finding("error", "subclauses",
                                f"{len(subclauses)} subordinate clauses, max {max_subclauses}"))

    if not re.search(r'[.?!]["”’\x27)\]]*\s*$', sentence):
        findings.append(Finding("error", "ending", "sentence must end with . ? or !"))

    if any(ch.isdigit() for ch in sentence):
        findings.append(Finding("warn", "digits", "sentence contains digits"))

    if zipf is None:
        from wordfreq import zipf_frequency
        zipf = zipf_frequency
    name_set = {name.casefold() for name in names}
    for tok in doc:
        if tok.idx >= gap_start and tok.idx < gap_end:
            continue
        if tok.pos_ not in CONTENT_POS or tok.like_num or tok.text.casefold() in name_set:
            continue
        lemma = tok.lemma_.lower()
        frequency = max(zipf(lemma, lang), zipf(tok.text.lower(), lang))
        if frequency < min_zipf:
            findings.append(Finding("warn", "i+1",
                                    f"{lemma!r}/{tok.text.lower()!r} Zipf {frequency:.2f} below {min_zipf:.1f}"))
    return findings
