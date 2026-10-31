"""Inventory all required texts; a partial delivery never passes this audit."""
import hashlib
import json
from pathlib import Path
import unicodedata


ROOT = Path(__file__).resolve().parent
manifest = json.loads((ROOT / "manifest.json").read_text())
languages = manifest["languages"]
sources = {row["id"]: row for row in manifest["items"]}
originals = [
    f"{category}_{number:02d}"
    for category in ("everyday", "travel", "restaurant", "work")
    for number in range(1, 6)
]
missing = []
problems = []
checked = []

for language in languages:
    for story_id in [*sources, *originals]:
        path = ROOT / language / f"{story_id}.txt"
        if not path.exists():
            missing.append(f"{language}/{story_id}.txt")
            continue
        text = path.read_text()
        title = text.splitlines()[0] if text.strip() else ""
        words = len(text.split())
        errors = []
        forbidden = sorted({
            char for char in text
            if unicodedata.category(char) == "Pd" or char == ";"
        })
        if forbidden:
            errors.append({"forbidden_punctuation": forbidden})
        if not title or len(title) > 32:
            errors.append("title_missing_or_over_32_characters")
        low, high = (1200, 3600) if story_id in sources else (600, 1800)
        if not low <= words <= high:
            errors.append({"word_range": [low, high], "actual": words})
        if story_id in sources:
            source_words = sources[story_id]["source_words"]
            reduction = 1 - words / source_words
            if not 0.2 <= reduction <= 0.5:
                errors.append({"reduction_outside_20_to_50_percent": reduction})
        entry = {
            "path": str(path.relative_to(ROOT)),
            "title": title,
            "words": words,
            "minutes_at_120_words": round(words / 120, 1),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        checked.append(entry)
        if errors:
            problems.append({"path": entry["path"], "errors": errors})

report = {
    "scope": "Mechanical text inventory only, not factual, language or application acceptance",
    "required_texts": len(languages) * (len(sources) + len(originals)),
    "present_texts": len(checked),
    "missing_texts": missing,
    "problems": problems,
    "checked": checked,
    "mechanical_text_requirements_complete": not missing and not problems,
}
(ROOT / "content_audit.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n"
)
print(json.dumps({
    "required": report["required_texts"],
    "present": len(checked),
    "missing": len(missing),
    "invalid_present": len(problems),
    "complete": report["mechanical_text_requirements_complete"],
}))
raise SystemExit(0 if report["mechanical_text_requirements_complete"] else 1)
