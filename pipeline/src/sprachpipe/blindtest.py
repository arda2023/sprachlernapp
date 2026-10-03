"""Blind test: a second model sees a gap, translation and gloss, then names the form."""

from __future__ import annotations

import re

from .generate import LANG_NAMES, load_prompt

BLIND_SCHEMA = {"type": "object", "properties": {
    "answer": {"type": "string"},
    "alternatives": {"type": "array", "maxItems": 3, "items": {
        "type": "object", "properties": {"answer": {"type": "string"},
                                          "reason": {"type": "string"}},
        "required": ["answer", "reason"], "additionalProperties": False}}},
    "required": ["answer", "alternatives"], "additionalProperties": False}


def gapped(text: str, gap_start: int, gap_end: int) -> str:
    return text[:gap_start] + "___" + text[gap_end:]


def ask(llm, cfg: dict, text: str, gap: tuple[int, int], translation_de: str,
        gloss_de: str) -> dict:
    g, c = cfg["generate"], cfg["llm"]
    _, tpl = load_prompt("blindtest")
    prompt = tpl.format(lang_name=LANG_NAMES[g["lang"]], gapped=gapped(text, *gap),
                        translation_de=translation_de, gloss_de=gloss_de)
    result = llm.generate_json(prompt, BLIND_SCHEMA, model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="blindtest",
                               max_output_tokens=c["max_output_tokens"]["blindtest"])
    return normalize(result)


def clean(answer: str) -> str:
    return answer.strip().strip(".,!?;:\"'“”‘’").strip()


def normalize(result) -> dict:
    """Validate model output; an empty answer is a failed, invalid response."""
    invalid = {"answer": "", "alternatives": []}
    if (type(result) is not dict or set(result) != {"answer", "alternatives"}
            or not isinstance(result["answer"], str) or not clean(result["answer"])
            or type(result["alternatives"]) is not list or len(result["alternatives"]) > 3):
        return invalid
    alternatives, seen = [], set()
    for item in result["alternatives"]:
        if (type(item) is not dict or set(item) != {"answer", "reason"}
                or not isinstance(item["answer"], str) or not clean(item["answer"])
                or not isinstance(item["reason"], str) or not item["reason"].strip()):
            return invalid
        answer = clean(item["answer"])
        if answer.casefold() not in seen:
            seen.add(answer.casefold())
            alternatives.append({"answer": answer, "reason": item["reason"].strip()})
    return {"answer": clean(result["answer"]), "alternatives": alternatives}


def alternatives_for(result: dict, form: str) -> list[dict]:
    return [a for a in normalize(result)["alternatives"]
            if a["answer"].casefold() != form.casefold()]


def judge(answer: str | dict, form: str, accepted: list[str], lemma: str, lemma_of,
          is_word) -> str:
    """Only the target form passes, ignoring case; accepted[] is not extended."""
    if isinstance(answer, dict):
        result = normalize(answer)
        if not result["answer"]:
            return "failed"
        if alternatives_for(result, form):
            return "ambiguous"
        return "passed" if result["answer"].casefold() == form.casefold() else "failed"
    return "passed" if isinstance(answer, str) and clean(answer).casefold() == form.casefold() else "failed"


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
