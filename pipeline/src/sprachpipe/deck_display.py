"""Pure, fail-closed display reordering after an editorial Create, before export.

No file/database writes. Registry positions remain authoritative.
Source/create/registry hashes must be computed by the caller from actual inputs.
"""
from __future__ import annotations
import copy
import hashlib
import json
import re


def canonical_sha256(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(",", ":")).encode("utf-8")).hexdigest()


def apply_deck_display_patch(pack, patch, *, source_sha256, create_sha256, registry_sha256):
    """Return a new pack; only the named deck's two position columns may change."""
    required = {"format", "format_version", "operation_id", "deck", "source_sha256",
                "create_sha256", "registry_sha256", "expected_before_sha256", "rows"}
    if not isinstance(patch, dict) or set(patch) != required:
        raise ValueError("display patch: unexpected or missing top-level fields")
    if patch["format"] != "sprachapp.deck-display-patch" or type(patch["format_version"]) is not int or patch["format_version"] != 1:
        raise ValueError("display patch: unsupported format/version")
    for field, actual in (("source_sha256", source_sha256), ("create_sha256", create_sha256),
                          ("registry_sha256", registry_sha256)):
        if not isinstance(actual, str) or not re.fullmatch(r"[0-9a-f]{64}", actual) or patch[field] != actual:
            raise ValueError(f"display patch: {field} mismatch")
    for field in ("operation_id", "deck"):
        if not isinstance(patch[field], str) or not patch[field].strip():
            raise ValueError(f"display patch: invalid {field}")
    deck = patch["deck"]
    if sum(x.get("ref") == deck for x in pack.get("decks", [])) != 1:
        raise ValueError("display patch: deck is not unique and present")
    before = {table: [row for row in pack.get(table, []) if row.get("deck") == deck]
              for table in ("deck_cards", "deck_words")}
    hashes = patch["expected_before_sha256"]
    if not isinstance(hashes, dict) or set(hashes) != set(before):
        raise ValueError("display patch: invalid before-hash fields")
    if any(hashes[table] != canonical_sha256(rows) for table, rows in before.items()):
        raise ValueError("display patch: prior deck rows differ")
    rows = patch["rows"]
    if not isinstance(rows, list) or not rows:
        raise ValueError("display patch: empty or invalid mapping")
    keys = {"card_ref", "form_norm", "original_position", "expected_position", "position"}
    for row in rows:
        if not isinstance(row, dict) or set(row) != keys:
            raise ValueError("display patch: unexpected or missing row fields")
        if any(type(row[k]) is not int or row[k] < 1 for k in
               ("original_position", "expected_position", "position")):
            raise ValueError("display patch: positions must be positive integers")
        if any(not isinstance(row[k], str) or not row[k].strip() for k in ("card_ref", "form_norm")):
            raise ValueError("display patch: invalid row reference")
    n = len(rows)
    if len({r["card_ref"] for r in rows}) != n or len({r["form_norm"] for r in rows}) != n:
        raise ValueError("display patch: duplicate card/word")
    if len({r["original_position"] for r in rows}) != n:
        raise ValueError("display patch: duplicate original position")
    if sorted(r["position"] for r in rows) != list(range(1, n + 1)):
        raise ValueError("display patch: final positions must be 1..n")
    if sorted(r["expected_position"] for r in rows) != list(range(1, n + 1)):
        raise ValueError("display patch: expected positions must be 1..n")
    if [r["position"] for r in sorted(rows, key=lambda x: x["original_position"])] != list(range(1, n + 1)):
        raise ValueError("display patch: final order differs from original selection order")
    # Bind claimed selection positions to the actual, hash-verified snapshot.
    from .word_registry import index_registry
    snapshot = pack.get("word_registry", {}).get("snapshot")
    if not isinstance(snapshot, dict) or canonical_sha256(snapshot) != registry_sha256:
        raise ValueError("display patch: registry snapshot mismatch")
    registry = index_registry(snapshot)
    for row in rows:
        word = registry.get((pack.get("lang"), row["form_norm"]), (None, {}))[1]
        if (word.get("form_norm") != row["form_norm"]
                or word.get("owner_deck_ref") != deck
                or word.get("primary_card_ref") != row["card_ref"]
                or type(word.get("position")) is not int
                or word["position"] != row["original_position"]):
            raise ValueError("display patch: original registry identity/position mismatch")
    by_card = {r["card_ref"]: r for r in rows}
    if len(before["deck_cards"]) != n or len(before["deck_words"]) != n:
        raise ValueError("display patch: mapping does not cover the whole deck")
    if {r.get("card") for r in before["deck_cards"]} != set(by_card):
        raise ValueError("display patch: card set mismatch")
    if {r.get("primary_card") for r in before["deck_words"]} != set(by_card):
        raise ValueError("display patch: primary card set mismatch")
    for row in before["deck_cards"]:
        if row.get("position") != by_card[row["card"]]["expected_position"]:
            raise ValueError("display patch: unexpected card position")
    for row in before["deck_words"]:
        expected = by_card[row["primary_card"]]
        if row.get("form_norm") != expected["form_norm"] or row.get("position") != expected["expected_position"]:
            raise ValueError("display patch: unexpected word/position")
    result = copy.deepcopy(pack)
    for table, key in (("deck_cards", "card"), ("deck_words", "primary_card")):
        for row in result[table]:
            if row["deck"] == deck:
                row["position"] = by_card[row[key]]["position"]
    return result
