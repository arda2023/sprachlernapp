"""Blind test: a second model sees a gap, translation and gloss, then names the form."""

from __future__ import annotations

import re

from .generate import LANG_NAMES, load_prompt

BLIND_SCHEMA = {"type": "object", "properties": {"answer": {"type": "string"}},
                "required": ["answer"]}


def gapped(text: str, gap_start: int, gap_end: int) -> str:
    return text[:gap_start] + "___" + text[gap_end:]


def ask(llm, cfg: dict, text: str, gap: tuple[int, int], translation_de: str,
        gloss_de: str) -> str:
    g, c = cfg["generate"], cfg["llm"]
    _, tpl = load_prompt("blindtest")
    prompt = tpl.format(lang_name=LANG_NAMES[g["lang"]], gapped=gapped(text, *gap),
                        translation_de=translation_de, gloss_de=gloss_de)
    result = llm.generate_json(prompt, BLIND_SCHEMA, model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="blindtest",
                               max_output_tokens=c["max_output_tokens"]["blindtest"])
    return result["answer"]


def clean(answer: str) -> str:
    return answer.strip().strip(".,!?;:\"'“”‘’").strip()


def judge(answer: str, form: str, accepted: list[str], lemma: str, lemma_of,
          is_word) -> str:
    """Only the exact form passes; accepted[] is never extended automatically."""
    return "passed" if clean(answer) == form else "failed"


def default_helpers(lang: str):
    """(lemma_of, is_word) from spaCy and wordfreq."""
    from wordfreq import word_frequency

    from .linter import _nlp

    def lemma_of(word: str) -> str:
        doc = _nlp()(word)
        return doc[0].lemma_ if len(doc) else word

    def is_word(word: str) -> bool:
        return bool(re.search(r"[^\W\d_]", word)) and word_frequency(word, lang) > 0
    return lemma_of, is_word
