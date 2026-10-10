"""Classify usage of existing inventory senses without changing their keys."""

from __future__ import annotations

from .generate import load_prompt


def classify_form(llm, cfg: dict, form: str, meanings: list[dict], display_form: str) -> dict[str, str]:
    keys = [m["sense_key"] for m in meanings]
    schema = {"type": "object", "properties": {"usages": {"type": "object",
              "properties": {key: {"type": "string", "enum": ["haupt", "neben", "selten"]}
                             for key in keys}, "required": keys}}, "required": ["usages"]}
    _, tpl = load_prompt("classify_usage")
    lines = [f"- {m['sense_key']}: {m['pos']}, {m['gloss_de']}, {m['translation_de']}"
             for m in meanings]
    prompt = tpl.format(form=display_form, meanings="\n".join(lines))
    c = cfg["llm"]
    result = llm.generate_json(prompt, schema, model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="classify_usage",
                               max_output_tokens=c["max_output_tokens"]["classify_usage"])
    usages = result["usages"]
    if set(usages) != set(keys):
        raise ValueError(f"invalid usage keys for {form}")
    return usages
