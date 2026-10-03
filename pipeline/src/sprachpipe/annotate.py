"""Token annotation: spaCy offsets and one model call for a card's sentences."""

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


CARD_SCHEMA = {
    "type": "object", "properties": {"sentences": {"type": "array", "minItems": 3,
        "maxItems": 3, "items": {"type": "object", "properties": {
            "sentence_idx": {"type": "integer"},
            "tokens": ANNOTATE_SCHEMA["properties"]["tokens"]},
            "required": ["sentence_idx", "tokens"]}}}, "required": ["sentences"]}


def annotate_card(llm, cfg: dict, card: dict, finals: list[dict], nlp=None) -> None:
    """Annotate exactly three accepted sentences in one request, then validate each token."""
    if len(finals) != 3:
        raise ValueError("annotation needs three accepted sentences")
    g, c = cfg["generate"], cfg["llm"]
    tokenized = [tokenize(a["text"], nlp) for a in finals]
    blocks = []
    for i, (a, tokens) in enumerate(zip(finals, tokenized)):
        words = [t for t in tokens if t["is_word"]]
        card_idx = next((t["idx"] for t in tokens if t["start_pos"] == a["gap"][0]
                         and t["end_pos"] == a["gap"][1]), None)
        blocks.append(f"Sentence {i}: {a['text']}\nGerman translation: {a['translation_de']}\n"
                      f"Tokens (index: surface):\n" + "\n".join(f"{t['idx']}: {t['surface']}" for t in words)
                      + f"\nTarget token: {card_idx}\n")
    _, tpl = load_prompt("annotate")
    prompt = tpl.format(lang_name=LANG_NAMES[g["lang"]], sentences="\n".join(blocks),
                        form=card.get("display_form", card["form"]), lemma=card["lemma"],
                        gloss_de=card["gloss_de"])
    result = llm.generate_json(prompt, CARD_SCHEMA, model=c["generate_model"],
                               thinking=c["generate_thinking"], step="annotate",
                               max_output_tokens=c["max_output_tokens"]["annotate"])
    groups = result["sentences"]
    if len(groups) != 3 or {a["sentence_idx"] for a in groups} != {0, 1, 2}:
        raise ValueError("annotation must return sentence_idx 0, 1, 2 once each")
    for group in groups:
        i = group["sentence_idx"]
        a, tokens = finals[i], tokenized[i]
        words = {t["idx"]: t for t in tokens if t["is_word"]}
        card_idx = next((t["idx"] for t in tokens if t["start_pos"] == a["gap"][0]
                         and t["end_pos"] == a["gap"][1]), None)
        problems = []
        if card_idx is None:
            problems.append(f"gap {a['gap']} is not one spaCy token")
        for item in group["tokens"]:
            t = words.get(item["token_idx"])
            if t is None:
                problems.append(f"token_idx {item['token_idx']} does not exist")
            elif item["surface"] != t["surface"]:
                problems.append(f"token {item['token_idx']}: surface {item['surface']!r} != {t['surface']!r}")
            elif item["lemma"].strip() and item["gloss_de"].strip():
                t.update(lemma=item["lemma"].strip(), gloss_de=item["gloss_de"].strip())
        if card_idx in words:
            words[card_idx].update(lemma=card["lemma"], gloss_de=card["gloss_de"],
                                   pos=card["pos"], card=True)
        missing = [idx for idx, t in words.items() if "gloss_de" not in t]
        if missing:
            problems.append(f"no gloss for tokens {missing}")
        a["tokens"], a["annotate_problems"] = tokens, problems
