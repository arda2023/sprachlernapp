"""Model check of the intended sense against all senses returned in step A."""

from __future__ import annotations

from .generate import load_prompt

SCHEMA = {"type": "object", "properties": {"sense_key": {"type": "string"}},
          "required": ["sense_key"]}


def check(llm, cfg: dict, text: str, form: str, meanings: list[dict]) -> str:
    _, tpl = load_prompt("meaning_check")
    prompt = tpl.format(text=text, form=form,
                        meanings="\n".join(f"- {m['sense_key']}: {m['gloss_de']}" for m in meanings))
    c = cfg["llm"]
    result = llm.generate_json(prompt, SCHEMA, model=c["blindtest_model"],
                               thinking=c["blindtest_thinking"], step="meaning_check",
                               max_output_tokens=c["max_output_tokens"]["meaning_check"])
    return result["sense_key"].strip()
