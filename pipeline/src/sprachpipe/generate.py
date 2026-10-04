"""Generation steps A (meanings per form) and B (sentences per card).

Candidates are wordfreq forms with their rank, never spaCy lemmas; part of
speech and meaning come from the model. Gap offsets are computed here,
never by the model.
"""

from __future__ import annotations

import re
import hashlib
from copy import deepcopy
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
        from .lemmas import spacy_analyzer

        count = int(spec)
        analyze = spacy_analyzer(cfg["lemmas"]["spacy_model"])
        forms = []
        for word in ranked:
            if not word.isalpha():
                continue
            result = analyze(word)
            if result is None or result[1] in ("PROPN", "NUM") or result[2]:
                continue
            forms.append(word)
            if len(forms) == count:
                break
        if len(forms) != count:
            raise ValueError(f"only {len(forms)} eligible forms among top {len(ranked)}")
    else:
        forms = [f.strip() for f in spec.split(",") if f.strip()]
    return [(f, rank.get(f)) for f in forms]


MEANINGS_SCHEMA = {
    "type": "object",
    "properties": {"meanings": {"type": "array", "maxItems": 4, "items": {
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
            "usage": {"type": "string", "enum": ["haupt", "neben", "selten"]},
        },
        "required": ["pos", "lemma", "sense_key", "gloss_de", "form_kind", "form_label_de",
                     "cefr_band", "translation_de", "usage"],
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


def meanings(llm, cfg: dict, form: str, rank: int | None, inventory,
             *, refresh: bool = False) -> list[dict]:
    """Step A: reuse inventory, or generate and append up to the rank limit."""
    existing = inventory.get(form)
    if existing is not None and not refresh:
        return existing
    g, c = cfg["generate"], cfg["llm"]
    limit = 4 if rank is not None and rank <= 1000 else 3
    schema = deepcopy(MEANINGS_SCHEMA)
    schema["properties"]["meanings"]["maxItems"] = limit
    _, tpl = load_prompt("meanings")
    prompt = tpl.format(form=inventory.display_form(form), rank=rank if rank is not None else "unknown",
                        max_meanings=limit, lang=g["lang"], lang_name=LANG_NAMES[g["lang"]])
    result = llm.generate_json(prompt, schema, model=c["generate_model"],
                               thinking=c["generate_thinking"], step="meanings",
                               max_output_tokens=c["max_output_tokens"]["meanings"])
    seen, out = set(), []
    for m in result["meanings"][:limit]:
        if m["sense_key"] not in seen:
            seen.add(m["sense_key"])
            out.append(m)
    return inventory.append(form, out, limit)


def slot_context(cfg: dict, card: dict, slot: int) -> tuple[str, str]:
    """Stable, distinct situations for up to eleven candidate slots."""
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
              *, contexts: list[tuple[str, str]] | None = None,
              avoid_words: list[str] | None = None) -> list[dict]:
    """Step B: [count] sentences {text, translation_de} for one card."""
    g, c = cfg["generate"], cfg["llm"]
    _, tpl = load_prompt("sentences")
    contexts = contexts or [("everyday life", "") for _ in range(count)]
    if len(contexts) != count:
        raise ValueError("one situation and name required per sentence slot")
    instructions = "\n".join(f"{i}. situation: {situation}; permitted first name: {name or 'none'}"
                             for i, (situation, name) in enumerate(contexts, start=1))
    prompt = tpl.format(count=count, lang_name=LANG_NAMES[g["lang"]], feedback=feedback,
                        slot_instructions=instructions,
                        avoid_words=", ".join(avoid_words or []) or "none",
                        **{k: (card.get("display_form", card["form"]) if k == "form" else card[k])
                           for k in ("form", "pos", "lemma", "gloss_de",
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
    """Character span of [form] as a whole token, ignoring case."""
    pattern = r"(?<!\w)" + re.escape(form) + r"(?!\w)"
    m = re.search(pattern, text, flags=re.IGNORECASE)
    return (m.start(), m.end()) if m else None


def qa_sentence(first: dict, card: dict, cfg: dict, *, regenerate, lint, blind, judge,
                meaning_check=None, duplicate=None, alternative_check=None) -> list[dict]:
    """Runs one sentence slot through linter, blind test, meaning check and
    alternative check. Returns all attempts; the last one carries the final
    qa_status, earlier ones are 'replaced'. Callbacks: regenerate(feedback) →
    {text, translation_de}; lint(text, gap) → findings; blind(text, gap,
    translation_de) → result; judge(result) → 'passed' (target form) | 'other'
    | 'failed'; alternative_check(text, gap, translation_de, candidates) →
    results of alternative_check.check. Final attempt["blind"]: 'passed',
    'confirmed_alternative', 'unconfirmed', 'other' (not checked) or 'failed'."""
    from .blindtest import alternatives_for, candidates_for, clean
    from .ids import form_norm

    g = cfg["generate"]
    attempts: list[dict] = []
    lint_left, blind_left = g["lint_retries"], g["blind_retries"]
    cur = first

    def retry_blind(a: dict, detail: str = "") -> dict | None:
        """The one shared blind-test retry: regenerated sentence or None (failed)."""
        nonlocal blind_left
        a["discard_reason"] = "Blindtest"
        a["discard_reasons"] = [a["discard_reason"]]
        if blind_left == 0:
            a["qa_status"] = "failed"
            return None
        blind_left -= 1
        a["qa_status"] = "replaced"
        return regenerate(f"In the sentence {a['text']!r} a reader who saw a gap instead "
                          f"of the form answered {a['blind_answer']!r}. Change the sentence "
                          f"so that only the target form \"{card.get('display_form', card['form'])}\" fits."
                          f"{detail} Keep the sentence natural and preserve its intended meaning.")
    while True:
        gap = gap_offsets(cur["text"], card["form"])
        findings = lint(cur["text"], gap or (0, 0))
        a = {"text": cur["text"], "translation_de": cur["translation_de"], "gap": gap,
             "lint": [f"{f.level}:{f.rule}: {f.message}" for f in findings],
             "lint_rules": [f.rule for f in findings if f.level == "error"],
             "blind_answer": None, "blind": None, "meaning_check": None,
             "discard_reason": "", "discard_reasons": [], "qa_status": None}
        attempts.append(a)
        if a["lint_rules"]:
            a["discard_reason"] = "Linter-Regel: " + ", ".join(a["lint_rules"])
            a["discard_reasons"] = [a["discard_reason"]]
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
            a["discard_reasons"] = [a["discard_reason"]]
            return attempts
        response = blind(cur["text"], gap, cur["translation_de"])
        a["blind_answer"] = response.get("answer", "") if isinstance(response, dict) else response
        a["blind_alternatives"] = alternatives_for(response, card["form"]) if isinstance(response, dict) else []
        a["alternative_candidates"] = candidates_for(response, card["form"])
        a["alternative_check"] = []
        a["valid_alternatives"] = []
        a["blind"] = judge(response)
        if a["blind"] not in ("passed", "other"):
            cur = retry_blind(a)
            if cur is None:
                return attempts
            continue
        if meaning_check is not None:
            result = meaning_check(cur["text"], cur["translation_de"])
            if (type(result) is not dict or set(result) !=
                    {"sense_key", "observed_pos", "translation_ok", "reason"}
                    or (result.get("sense_key") is not None
                        and not isinstance(result.get("sense_key"), str))
                    or (result.get("observed_pos") is not None
                        and not isinstance(result.get("observed_pos"), str))
                    or type(result.get("translation_ok")) is not bool
                    or not isinstance(result.get("reason"), str)
                    or not result.get("reason", "").strip()):
                result = {"sense_key": None, "observed_pos": None,
                          "translation_ok": False,
                          "reason": "Ungültige Prüfantwort: ungültige Ergebnisstruktur"}
            a["meaning_check"] = result["sense_key"]
            a["meaning_check_result"] = result
            reasons = []
            if result["reason"].startswith("Ungültige Prüfantwort:"):
                reasons.append("Ungültige Prüfantwort")
            else:
                if result["sense_key"] != card["sense_key"]:
                    reasons.append("Bedeutung")
                if result["observed_pos"] != card["pos"]:
                    reasons.append("Wortart")
                if result["translation_ok"] is not True:
                    reasons.append("Übersetzung")
            if reasons:
                a["qa_status"] = "failed"
                a["discard_reason"] = reasons[0]
                a["discard_reasons"] = reasons
                return attempts
        # Alternatives only after the original sentence passed every check.
        candidates = a["alternative_candidates"]
        if alternative_check is not None and candidates:
            results = alternative_check(cur["text"], gap, cur["translation_de"], candidates)
            a["alternative_check"] = results
            if (len(results) != len(candidates)
                    or any(r.get("status") not in ("confirmed", "rejected") for r in results)):
                a["qa_status"] = "failed"
                a["discard_reason"] = "Ungültige Prüfantwort: Alternativprüfung"
                a["discard_reasons"] = [a["discard_reason"]]
                return attempts
        confirmed = [r["norm"] for r in a["alternative_check"] if r["status"] == "confirmed"]
        if a["blind"] == "other":
            main = form_norm(clean(a["blind_answer"]))
            if main not in confirmed:
                a["blind"] = "unconfirmed"
                reason = next((r["reason"] for r in a["alternative_check"] if r["norm"] == main), "")
                cur = retry_blind(a, f" Checker: {reason}" if reason else "")
                if cur is None:
                    return attempts
                continue
            a["blind"] = "confirmed_alternative"
        a["valid_alternatives"] = confirmed
        a["qa_status"] = "ok"
        return attempts
