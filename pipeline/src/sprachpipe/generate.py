"""Generation steps A (meanings per form) and B (sentences per card).

Candidates are wordfreq forms with their rank, never spaCy lemmas; part of
speech and meaning come from the model. Gap offsets are computed here,
never by the model.
"""

from __future__ import annotations

import re
import hashlib
from pathlib import Path

PROMPTS_DIR = Path(__file__).resolve().parents[2] / "prompts"
LANG_NAMES = {"en": "English"}
POS_TAGS = ["NOUN", "VERB", "ADJ", "ADV", "ADP", "PRON", "DET", "AUX", "CCONJ", "SCONJ",
            "PART", "INTJ"]
FORM_KINDS = ["base", "past", "past_participle", "present_participle", "third_person",
              "plural", "comparative", "superlative", "other"]
BANDS = ["anfaenger", "mittel", "fortgeschritten"]


def load_prompt(name: str) -> tuple[str, str]:
    """(version, template) of pipeline/prompts/<name>.md; first line is 'version: x'."""
    text = (PROMPTS_DIR / f"{name}.md").read_text(encoding="utf-8")
    first, _, body = text.partition("\n")
    if not first.startswith("version:"):
        raise ValueError(f"prompts/{name}.md: first line must be 'version: ...'")
    return first.split(":", 1)[1].strip(), body.strip() + "\n"


def candidate_forms(spec: str, cfg: dict) -> list[tuple[str, int | None]]:
    """[spec] is 'smoke', a number n (top n wordfreq forms) or 'a,b,c'.
    Returns (form, wordfreq rank) pairs."""
    from wordfreq import top_n_list

    g = cfg["generate"]
    ranked = top_n_list(g["lang"], g["top_n"])
    rank = {w: i for i, w in enumerate(ranked, start=1)}
    if spec == "smoke":
        forms = [str(f) for f in cfg["smoke_forms"]]
    elif spec.isdigit():
        forms = ranked[: int(spec)]
    else:
        forms = [f.strip() for f in spec.split(",") if f.strip()]
    return [(f, rank.get(f)) for f in forms]


MEANINGS_SCHEMA = {
    "type": "object",
    "properties": {"meanings": {"type": "array", "maxItems": 3, "items": {
        "type": "object",
        "properties": {
            "pos": {"type": "string", "enum": POS_TAGS},
            "lemma": {"type": "string"},
            "sense_key": {"type": "string"},
            "gloss_de": {"type": "string"},
            "form_kind": {"type": "string", "enum": FORM_KINDS},
            "form_label_de": {"type": "string"},
            "cefr_band": {"type": "string", "enum": BANDS},
            "translation_de": {"type": "string"},
        },
        "required": ["pos", "lemma", "sense_key", "gloss_de", "form_kind", "form_label_de",
                     "cefr_band", "translation_de"],
    }}},
    "required": ["meanings"],
}


def sentences_schema(count: int) -> dict:
    return {
        "type": "object",
        "properties": {"sentences": {
            "type": "array", "minItems": count, "maxItems": count,
            "items": {"type": "object",
                      "properties": {"text": {"type": "string"},
                                     "translation_de": {"type": "string"}},
                      "required": ["text", "translation_de"]}}},
        "required": ["sentences"],
    }


def meanings(llm, cfg: dict, form: str, rank: int | None) -> list[dict]:
    """Step A: at most 3 meanings; [] for fragments, proper names, numbers."""
    g, c = cfg["generate"], cfg["llm"]
    _, tpl = load_prompt("meanings")
    prompt = tpl.format(form=form, rank=rank if rank is not None else "unknown",
                        lang=g["lang"], lang_name=LANG_NAMES[g["lang"]])
    result = llm.generate_json(prompt, MEANINGS_SCHEMA, model=c["generate_model"],
                               thinking=c["generate_thinking"], step="meanings",
                               max_output_tokens=c["max_output_tokens"]["meanings"])
    seen, out = set(), []
    for m in result["meanings"][:3]:
        if m["sense_key"] not in seen:
            seen.add(m["sense_key"])
            out.append(m)
    return out


def slot_context(cfg: dict, card: dict, slot: int) -> tuple[str, str]:
    """Stable, distinct situations for up to eight candidate slots."""
    g = cfg["generate"]
    key = f"{card['form']}|{card['sense_key']}"
    def index(i: int, salt: str, size: int) -> int:
        digest = hashlib.sha256(f"{key}|{i}|{salt}".encode()).digest()
        return int.from_bytes(digest[:8], "big") % size
    situations = g["situations"]
    used = set()
    for i in range(slot + 1):
        pos = index(i, "situation", len(situations))
        while situations[pos] in used:
            pos = (pos + 1) % len(situations)
        used.add(situations[pos])
    return situations[pos], g["names"][index(slot, "name", len(g["names"]))]


def sentences(llm, cfg: dict, card: dict, count: int = 3, feedback: str = "",
              *, situation: str = "", name: str = "", avoid_words: list[str] | None = None) -> list[dict]:
    """Step B: [count] sentences {text, translation_de} for one card."""
    g, c = cfg["generate"], cfg["llm"]
    _, tpl = load_prompt("sentences")
    prompt = tpl.format(count=count, lang_name=LANG_NAMES[g["lang"]], feedback=feedback,
                        situation=situation, name=name,
                        avoid_words=", ".join(avoid_words or []) or "none",
                        **{k: card[k] for k in ("form", "pos", "lemma", "gloss_de",
                                                "form_label_de", "translation_de",
                                                "cefr_band")})
    result = llm.generate_json(prompt, sentences_schema(count), model=c["generate_model"],
                               thinking=c["generate_thinking"], step="sentences",
                               max_output_tokens=c["max_output_tokens"]["sentences"])
    out = [{"text": s["text"].strip(), "translation_de": s["translation_de"].strip()}
           for s in result["sentences"]]
    if len(out) != count:
        raise ValueError(f"expected {count} sentences, got {len(out)}")
    return out


def gap_offsets(text: str, form: str) -> tuple[int, int] | None:
    """Character span of [form] as a whole token: case-sensitive first, then
    case-insensitive. None if the form does not occur."""
    pattern = r"(?<!\w)" + re.escape(form) + r"(?!\w)"
    m = re.search(pattern, text) or re.search(pattern, text, flags=re.IGNORECASE)
    return (m.start(), m.end()) if m else None


def qa_sentence(first: dict, card: dict, cfg: dict, *, regenerate, lint, blind, judge,
                meaning_check=None, duplicate=None) -> list[dict]:
    """Runs one sentence slot through linter and blind test. Returns all
    attempts; the last one carries the final qa_status, earlier ones are
    'replaced'. Callbacks: regenerate(feedback) → {text, translation_de};
    lint(text, gap) → findings; blind(text, gap, translation_de) → answer;
    judge(answer) → 'passed' | 'failed'."""
    g = cfg["generate"]
    attempts: list[dict] = []
    lint_left, blind_left = g["lint_retries"], g["blind_retries"]
    cur = first
    while True:
        gap = gap_offsets(cur["text"], card["form"])
        findings = lint(cur["text"], gap or (0, 0))
        a = {"text": cur["text"], "translation_de": cur["translation_de"], "gap": gap,
             "lint": [f"{f.level}:{f.rule}: {f.message}" for f in findings],
             "lint_rules": [f.rule for f in findings if f.level == "error"],
             "blind_answer": None, "blind": None, "meaning_check": None,
             "discard_reason": "", "qa_status": None}
        attempts.append(a)
        if a["lint_rules"]:
            a["discard_reason"] = "Linter-Regel: " + ", ".join(a["lint_rules"])
            if lint_left == 0:
                a["qa_status"] = "failed"
                return attempts
            lint_left -= 1
            a["qa_status"] = "replaced"
            cur = regenerate(f"The sentence {cur['text']!r} was rejected by the checker: "
                             + "; ".join(a["lint"]) + ". Write a new one that fixes this.")
            continue
        if duplicate is not None and duplicate(cur["text"], gap):
            a["qa_status"] = "failed"
            a["discard_reason"] = "Duplikat"
            return attempts
        a["blind_answer"] = blind(cur["text"], gap, cur["translation_de"])
        a["blind"] = judge(a["blind_answer"])
        if a["blind"] != "passed" and blind_left > 0:
            blind_left -= 1
            a["qa_status"] = "replaced"
            a["discard_reason"] = "Blindtest"
            cur = regenerate(f"In the sentence {cur['text']!r} a reader who saw a gap instead "
                             f"of the form answered {a['blind_answer']!r}. Change the sentence "
                             f"so that only the target form \"{card['form']}\" fits.")
            continue
        if a["blind"] != "passed":
            a["qa_status"] = "failed"
            a["discard_reason"] = "Blindtest"
            return attempts
        if meaning_check is not None:
            a["meaning_check"] = meaning_check(cur["text"])
            if a["meaning_check"] != card["sense_key"]:
                a["qa_status"] = "failed"
                a["discard_reason"] = "Bedeutung"
                return attempts
        a["qa_status"] = "ok"
        return attempts
