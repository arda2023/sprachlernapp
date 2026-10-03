"""Check intended meaning, contextual part of speech, and translation in one call."""

from __future__ import annotations

from .generate import POS_TAGS, load_prompt


def _schema(keys: list[str]) -> dict:
    return {"type": "object", "properties": {
        "sense_key": {"anyOf": [{"type": "string", "enum": keys}, {"type": "null"}]},
        "observed_pos": {"anyOf": [{"type": "string", "enum": POS_TAGS}, {"type": "null"}]},
        "translation_ok": {"type": "boolean"},
        "reason": {"type": "string"},
    }, "required": ["sense_key", "observed_pos", "translation_ok", "reason"],
        "additionalProperties": False}


def _invalid(reason: str) -> dict:
    return {"sense_key": None, "observed_pos": None, "translation_ok": False,
            "reason": f"Ungültige Prüfantwort: {reason}"}


def check(llm, cfg: dict, text: str, form: str, meanings: list[dict],
          translation_de: str) -> dict:
    keys = [m["sense_key"] for m in meanings]
    _, tpl = load_prompt("meaning_check")
    prompt = tpl.format(
        text=text, form=form, translation_de=translation_de,
        meanings="\n".join(
            f"- {m['sense_key']}: POS={m['pos']}; form={m['form_kind']} / "
            f"{m['form_label_de']}; gloss={m['gloss_de']}"
            for m in meanings))
    c = cfg["llm"]
    result = llm.generate_json(prompt, _schema(keys), model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="meaning_check",
                               max_output_tokens=c["max_output_tokens"]["meaning_check"])
    if type(result) is not dict or set(result) != {
            "sense_key", "observed_pos", "translation_ok", "reason"}:
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
    return {"sense_key": sense_key, "observed_pos": observed_pos,
            "translation_ok": translation_ok, "reason": reason.strip()}
