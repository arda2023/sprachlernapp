"""Versioned meaning inventory; existing sense keys are immutable."""

from __future__ import annotations

import json
from pathlib import Path

from .config import PIPELINE_DIR


class MeaningInventory:
    def __init__(self, lang: str, path: str | Path | None = None):
        self.lang = lang
        self.path = Path(path or PIPELINE_DIR / "data" / "meanings" / f"{lang}.json")
        if self.path.exists():
            data = json.loads(self.path.read_text(encoding="utf-8"))
            if data.get("lang") != lang or not isinstance(data.get("forms"), dict):
                raise ValueError(f"invalid meaning inventory: {self.path}")
            self.forms = data["forms"]
            for form, entry in list(self.forms.items()):
                if isinstance(entry, list):
                    self.forms[form] = {"display_form": "I" if form == "i" else form,
                                        "meanings": entry}
                else:
                    entry.setdefault("display_form", "I" if form == "i" else form)
                for meaning in self.forms[form]["meanings"]:
                    meaning.setdefault("usage", "haupt")
                    meaning.setdefault("status", "active")
                    if meaning["sense_key"] in CLOZE_AMBIGUOUS:
                        meaning["status"] = "excluded"
                        meaning["exclude_reason"] = "cloze_ambiguous"
        else:
            self.forms = {}

    def get(self, form: str) -> list[dict] | None:
        entry = self.forms.get(form)
        return [dict(m) for m in entry["meanings"]] if entry is not None else None

    def display_form(self, form: str) -> str:
        entry = self.forms.get(form)
        return entry["display_form"] if entry else ("I" if form == "i" else form)

    def classify(self, form: str, usages: dict[str, str]) -> None:
        entry = self.forms[form]
        keys = {m["sense_key"] for m in entry["meanings"]}
        if set(usages) != keys or any(u not in {"haupt", "neben", "selten"} for u in usages.values()):
            raise ValueError(f"invalid usage classification for {form}")
        for meaning in entry["meanings"]:
            meaning["usage"] = usages[meaning["sense_key"]]
            meaning["status"] = "excluded" if meaning["usage"] == "selten" or meaning["sense_key"] in CLOZE_AMBIGUOUS else "active"
            reason = ("cloze_ambiguous" if meaning["sense_key"] in CLOZE_AMBIGUOUS else
                      "selten" if meaning["usage"] == "selten" else None)
            if reason:
                meaning["exclude_reason"] = reason
            else:
                meaning.pop("exclude_reason", None)
        self.save()

    def append(self, form: str, meanings: list[dict], limit: int) -> list[dict]:
        new_form = form not in self.forms
        entry = self.forms.setdefault(form, {"display_form": "I" if form == "i" else form,
                                             "meanings": []})
        current = entry["meanings"]
        known = {m["sense_key"] for m in current}
        changed = new_form
        for meaning in meanings:
            if len(current) >= limit:
                break
            if meaning["sense_key"] not in known:
                added = dict(meaning)
                added.setdefault("usage", "haupt")
                added["status"] = "excluded" if added["usage"] == "selten" or added["sense_key"] in CLOZE_AMBIGUOUS else "active"
                if added["status"] == "excluded":
                    added["exclude_reason"] = "cloze_ambiguous" if added["sense_key"] in CLOZE_AMBIGUOUS else "selten"
                current.append(added)
                known.add(meaning["sense_key"])
                changed = True
        if changed or not self.path.exists():
            self.save()
        return [dict(m) for m in current]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.path.with_suffix(".tmp")
        temporary.write_text(json.dumps({"lang": self.lang, "forms": self.forms},
                                        ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(self.path)


CLOZE_AMBIGUOUS = {"what#ausruf", "there#beruhigung", "like#als_ob", "this#so_graduierend",
                   "not#gar_nicht"}   # emphasis lies in "at all", not in the gap word "not"
