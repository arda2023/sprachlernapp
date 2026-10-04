"""Check unconfirmed alternative answers in one call per sentence.

The code inserts every candidate literally into the gap span; the model only
judges the finished sentences. Only results with status 'confirmed' may become
card_sentences.valid_alternatives.
"""

from __future__ import annotations

from .generate import load_prompt
from .ids import form_norm


def filled(text: str, gap: tuple[int, int], candidate: str) -> str:
    return text[:gap[0]] + candidate + text[gap[1]:]


def _schema(n: int) -> dict:
    return {"type": "object", "properties": {"results": {
        "type": "array", "minItems": n, "maxItems": n, "items": {
            "type": "object", "properties": {
                "candidate_index": {"type": "integer", "minimum": 1, "maximum": n},
                "valid": {"type": "boolean"},
                "reason": {"type": "string"}},
            "required": ["candidate_index", "valid", "reason"],
            "additionalProperties": False}}},
        "required": ["results"], "additionalProperties": False}


def _verdicts(result, n: int) -> dict[int, tuple[bool, str]] | str:
    """{index: (valid, reason)} or the reason why the response is invalid."""
    if type(result) is not dict or set(result) != {"results"} or type(result["results"]) is not list:
        return "ungültige Ergebnisstruktur"
    out = {}
    for item in result["results"]:
        if type(item) is not dict or set(item) != {"candidate_index", "valid", "reason"}:
            return "ungültiger Eintrag"
        index, valid, reason = item["candidate_index"], item["valid"], item["reason"]
        if type(index) is not int or not 1 <= index <= n:
            return "unbekannter candidate_index"
        if index in out:
            return "doppelter candidate_index"
        if type(valid) is not bool or not isinstance(reason, str) or not reason.strip():
            return "valid oder reason fehlt bzw. ist ungültig"
        out[index] = (valid, reason.strip())
    if len(out) != n:
        return "candidate_index fehlt"
    return out


def check(llm, cfg: dict, text: str, gap: tuple[int, int], translation_de: str,
          candidates: list[str]) -> list[dict]:
    """One result per candidate: {candidate_index, candidate, norm, sentence,
    status ('confirmed' | 'rejected' | 'invalid'), reason}. No call without
    candidates. Auth, budget and transport errors propagate unchanged."""
    if not candidates:
        return []
    sentences = [filled(text, gap, c) for c in candidates]
    _, tpl = load_prompt("alternative_check")
    prompt = tpl.format(text=text, translation_de=translation_de, n=len(candidates),
                        candidates="\n".join(
                            f"{i}. inserted: \"{c}\" -> {s}"
                            for i, (c, s) in enumerate(zip(candidates, sentences), start=1)))
    c = cfg["llm"]
    result = llm.generate_json(prompt, _schema(len(candidates)), model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="alternative_check",
                               max_output_tokens=c["max_output_tokens"]["alternative_check"])
    verdicts = _verdicts(result, len(candidates))
    out = []
    for i, (candidate, sentence) in enumerate(zip(candidates, sentences), start=1):
        if isinstance(verdicts, str):
            status, reason = "invalid", f"Ungültige Prüfantwort: {verdicts}"
        else:
            valid, reason = verdicts[i]
            status = "confirmed" if valid else "rejected"
        out.append({"candidate_index": i, "candidate": candidate, "norm": form_norm(candidate),
                    "sentence": sentence, "status": status, "reason": reason})
    return out
