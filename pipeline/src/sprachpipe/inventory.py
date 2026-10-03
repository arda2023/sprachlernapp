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
        else:
            self.forms = {}

    def get(self, form: str) -> list[dict] | None:
        values = self.forms.get(form)
        return [dict(m) for m in values] if values is not None else None

    def append(self, form: str, meanings: list[dict], limit: int) -> list[dict]:
        new_form = form not in self.forms
        current = self.forms.setdefault(form, [])
        known = {m["sense_key"] for m in current}
        changed = new_form
        for meaning in meanings:
            if len(current) >= limit:
                break
            if meaning["sense_key"] not in known:
                current.append(dict(meaning))
                known.add(meaning["sense_key"])
                changed = True
        if changed or not self.path.exists():
            self.path.parent.mkdir(parents=True, exist_ok=True)
            temporary = self.path.with_suffix(".tmp")
            temporary.write_text(json.dumps({"lang": self.lang, "forms": self.forms},
                                            ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            temporary.replace(self.path)
        return [dict(m) for m in current]
