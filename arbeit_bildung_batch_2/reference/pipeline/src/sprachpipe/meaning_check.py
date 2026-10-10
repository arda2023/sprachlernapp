"""Check intended meaning, contextual part of speech, translation and language
quality of the original sentence in one call."""

from __future__ import annotations

from .generate import POS_TAGS, load_prompt

FIELDS = ("sense_key", "observed_pos", "translation_ok", "language_ok", "reason")


def _schema(keys: list[str]) -> dict:
    return {"type": "object", "properties": {
        "sense_key": {"anyOf": [{"type": "string", "enum": keys}, {"type": "null"}]},
        "observed_pos": {"anyOf": [{"type": "string", "enum": POS_TAGS}, {"type": "null"}]},
        "translation_ok": {"type": "boolean"},
        "language_ok": {"type": "boolean"},
        "reason": {"type": "string", "minLength": 1},
    }, "required": list(FIELDS),
        "additionalProperties": False}


def violations(result, keys: list[str]) -> list[dict]:
    """Diagnosis only: every contract violation of a raw response as
    {field, problem, type, value}. Empty exactly when check() accepts it."""
    def v(field, problem, value=None):
        return {"field": field, "problem": problem, "type": type(value).__name__, "value": value}
    if type(result) is not dict:
        return [v(None, "keine JSON-Objektantwort", result)]
    out = [v(f, "fehlt") for f in FIELDS if f not in result]
    out += [v(f, "unbekanntes Feld", result[f]) for f in result if f not in FIELDS]
    for field, allowed in (("sense_key", keys), ("observed_pos", POS_TAGS)):
        value = result.get(field)
        if field in result and value is not None and (not isinstance(value, str) or value not in allowed):
            out.append(v(field, "nicht null und nicht in der Liste", value))
    for field in ("translation_ok", "language_ok"):
        if field in result and type(result[field]) is not bool:
            out.append(v(field, "kein boolean", result[field]))
    if "reason" in result and (not isinstance(result["reason"], str) or not result["reason"].strip()):
        out.append(v("reason", "kein nicht-leerer String", result["reason"]))
    return out


def _invalid(reason: str) -> dict:
    return {"sense_key": None, "observed_pos": None, "translation_ok": False,
            "language_ok": False, "reason": f"Ungültige Prüfantwort: {reason}"}


def check(llm, cfg: dict, text: str, form: str, meanings: list[dict],
          translation_de: str, *, model: str | None = None, thinking: dict | None = None,
          diagnostics: dict | None = None) -> dict:
    """Default: meaning_check model and thinking. [model]/[thinking] override both
    (diagnosis only). [diagnostics], if given, receives the raw response and
    its contract violations; acceptance is unchanged."""
    keys = [m["sense_key"] for m in meanings]
    _, tpl = load_prompt("meaning_check")
    prompt = tpl.format(
        text=text, form=form, translation_de=translation_de,
        meanings="\n".join(
            f"- {m['sense_key']}: POS={m['pos']}; form={m['form_kind']} / "
            f"{m['form_label_de']}; gloss={m['gloss_de']}"
            for m in meanings))
    c = cfg["llm"]
    result = llm.generate_json(prompt, _schema(keys), model=model or c["meaning_check_model"],
                               thinking=c["meaning_check_thinking"] if thinking is None else thinking,
                               step="meaning_check",
                               max_output_tokens=c["max_output_tokens"]["meaning_check"])
    if diagnostics is not None:
        diagnostics["response"] = result
        diagnostics["violations"] = violations(result, keys)
    if type(result) is not dict or set(result) != set(FIELDS):
        return _invalid("Felder fehlen oder sind unbekannt")
    sense_key, observed_pos = result["sense_key"], result["observed_pos"]
    translation_ok, reason = result["translation_ok"], result["reason"]
    if sense_key is not None and (not isinstance(sense_key, str) or sense_key not in keys):
        return _invalid("sense_key ist unbekannt")
    if observed_pos is not None and (not isinstance(observed_pos, str)
                                     or observed_pos not in POS_TAGS):
        return _invalid("observed_pos ist ungültig")
    if type(translation_ok) is not bool or not isinstance(reason, str) or not reason.strip():
        return _invalid("translation_ok oder reason fehlt bzw. ist ungültig")
    if type(result["language_ok"]) is not bool:
        return _invalid("language_ok fehlt bzw. ist ungültig")
    return {"sense_key": sense_key, "observed_pos": observed_pos,
            "translation_ok": translation_ok, "language_ok": result["language_ok"],
            "reason": reason.strip()}
