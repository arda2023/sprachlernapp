"""Token annotation: spaCy tokens with character offsets, one model call per
sentence for lemma + gloss in context, checked against the tokens."""

from __future__ import annotations

from .generate import LANG_NAMES, load_prompt
from .linter import _nlp

ANNOTATE_SCHEMA = {
    "type": "object",
    "properties": {"tokens": {"type": "array", "items": {
        "type": "object",
        "properties": {"token_idx": {"type": "integer"}, "surface": {"type": "string"},
                       "lemma": {"type": "string"}, "gloss_de": {"type": "string"}},
        "required": ["token_idx", "surface", "lemma", "gloss_de"]}}},
    "required": ["tokens"],
}


def tokenize(text: str, nlp=None) -> list[dict]:
    """All spaCy tokens: idx, start_pos, end_pos, surface, pos, is_word."""
    doc = (nlp or _nlp())(text)
    return [{"idx": t.i, "start_pos": t.idx, "end_pos": t.idx + len(t.text),
             "surface": t.text, "pos": t.pos_, "is_word": any(ch.isalpha() for ch in t.text)}
            for t in doc]


def annotate(llm, cfg: dict, text: str, translation_de: str, card: dict,
             gap: tuple[int, int], nlp=None) -> tuple[list[dict], list[str]]:
    """Returns (tokens, problems). Word tokens get lemma, pos and gloss_de;
    the token at the gap gets the card's lemma, pos and gloss."""
    g, c = cfg["generate"], cfg["llm"]
    tokens = tokenize(text, nlp)
    words = {t["idx"]: t for t in tokens if t["is_word"]}
    card_idx = next((t["idx"] for t in tokens if t["start_pos"] == gap[0]), None)
    problems: list[str] = []
    if card_idx is None or tokens[card_idx]["end_pos"] != gap[1]:
        problems.append(f"gap {gap} is not one spaCy token")

    _, tpl = load_prompt("annotate")
    prompt = tpl.format(
        lang_name=LANG_NAMES[g["lang"]], text=text, translation_de=translation_de,
        tokens="\n".join(f"{i}: {t['surface']}" for i, t in words.items()),
        card_idx=card_idx, form=card["form"], lemma=card["lemma"], gloss_de=card["gloss_de"])
    result = llm.generate_json(prompt, ANNOTATE_SCHEMA, model=c["generate_model"],
                               thinking=c["generate_thinking"], step="annotate",
                               max_output_tokens=c["max_output_tokens"]["annotate"])

    for a in result["tokens"]:
        t = words.get(a["token_idx"])
        if t is None:
            problems.append(f"token_idx {a['token_idx']} does not exist")
        elif a["surface"] != t["surface"]:
            problems.append(f"token {a['token_idx']}: surface {a['surface']!r} != {t['surface']!r}")
        elif a["lemma"].strip() and a["gloss_de"].strip():
            t["lemma"], t["gloss_de"] = a["lemma"].strip(), a["gloss_de"].strip()
    if card_idx is not None and card_idx in words:
        words[card_idx].update(lemma=card["lemma"], gloss_de=card["gloss_de"], pos=card["pos"],
                               card=True)
    missing = [i for i, t in words.items() if "gloss_de" not in t]
    if missing:
        problems.append(f"no gloss for tokens {missing}")
    return tokens, problems
