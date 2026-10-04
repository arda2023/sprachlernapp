"""Stable content IDs (docs/content-schema.md, "Kanonisierung").

id = hex of the first 16 bytes of SHA-256 over the canonical string:

    <table> \\u001f <key field 1> \\u001f <key field 2> ...

- The table name comes first, so equal keys in different tables (decks and
  stories both use lang + slug) never share an ID.
- Key fields follow the fixed order in KEY_FIELDS below, never the order of
  the keyword arguments.
- Every value is converted to text (integers as decimal digits) and
  normalized to Unicode NFC. Nothing else changes: no lowercasing, no
  trimming. None is rejected.
- Only immutable fields are keys. Glosses, translations and labels are
  ordinary columns, so correcting them never changes an ID.
"""

from __future__ import annotations

import hashlib
import unicodedata

SEPARATOR = "\u001f"

# Fixed field order per table. Changing an entry changes every ID of that
# table, so this map is frozen (see docs/content-schema.md).
KEY_FIELDS: dict[str, tuple[str, ...]] = {
    "lemmas": ("lang", "lemma", "pos"),
    "senses": ("lemma_id", "sense_key"),
    "cards": ("lang", "form", "sense_id"),
    "dictionary_forms": ("lang", "form_norm", "sense_id"),
    "decks": ("lang", "slug"),
    "deck_cards": ("deck_id", "card_id"),
    "deck_words": ("lang", "form_norm"),
    "word_aliases": ("lang", "form_norm"),
    "sentences": ("lang", "text"),
    "sentence_tokens": ("sentence_id", "idx"),
    "card_sentences": ("card_id", "sentence_id"),
    "stories": ("lang", "slug"),
    "story_sentences": ("story_id", "idx"),
    "exercises": ("lang", "kind", "slug"),
    "grammar_rules": ("lang", "slug"),
    "audio_assets": ("owner_kind", "owner_id", "voice", "model"),
    "content_releases": ("lang", "version"),
}


def _canonical_value(table: str, field: str, value: object) -> str:
    if value is None or isinstance(value, bool):
        raise ValueError(f"{table}.{field}: key value must be text or int, got {value!r}")
    if isinstance(value, int):
        return str(value)
    if not isinstance(value, str):
        raise ValueError(f"{table}.{field}: key value must be text or int, got {type(value).__name__}")
    return unicodedata.normalize("NFC", value)


def canonical_string(table: str, **key_fields: object) -> str:
    """Canonical string for [table] from exactly its key fields."""
    try:
        order = KEY_FIELDS[table]
    except KeyError:
        raise ValueError(f"unknown table {table!r}") from None
    if set(key_fields) != set(order):
        raise ValueError(f"{table}: key fields must be exactly {order}, got {tuple(sorted(key_fields))}")
    parts = [table] + [_canonical_value(table, f, key_fields[f]) for f in order]
    return SEPARATOR.join(parts)


def stable_id(table: str, **key_fields: object) -> str:
    """Stable ID for a content row (32 hex characters)."""
    digest = hashlib.sha256(canonical_string(table, **key_fields).encode("utf-8")).digest()
    return digest[:16].hex()


def form_norm(form: str) -> str:
    """Normalized form for dictionary lookup: NFC, lowercase, ’ → '."""
    return unicodedata.normalize("NFC", form).lower().replace("’", "'")
