"""Columns of the Supabase schema `content`, mirrored from
supabase/migrations/20261003000002_content_tables.sql (the source of truth).
tests/test_schema.py fails if the two drift apart.
"""

from __future__ import annotations

# Table → [(column, Postgres type)], in migration order. TABLE_ORDER doubles
# as the foreign-key-safe write order.
COLUMNS: dict[str, list[tuple[str, str]]] = {
    "languages": [
        ("code", "text"), ("name_native", "text"), ("name_de", "text"), ("gloss_lang", "text"),
    ],
    "lemmas": [
        ("id", "text"), ("lang", "text"), ("lemma", "text"), ("pos", "text"),
        ("family_key", "text"), ("freq_rank", "integer"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "senses": [
        ("id", "text"), ("lang", "text"), ("lemma_id", "text"), ("sense_key", "text"),
        ("gloss_de", "text"), ("definition_de", "text"), ("notes_de", "text"),
        ("sense_index", "integer"), ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "cards": [
        ("id", "text"), ("lang", "text"), ("form", "text"), ("sense_id", "text"),
        ("form_norm", "text"), ("lemma_id", "text"), ("pos", "text"), ("form_kind", "text"),
        ("form_label_de", "text"), ("translation_de", "text"), ("cefr_band", "text"),
        ("freq_rank", "integer"), ("is_multiword", "boolean"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "dictionary_forms": [
        ("id", "text"), ("lang", "text"), ("form_norm", "text"), ("sense_id", "text"),
        ("card_id", "text"), ("gloss_de", "text"), ("rank", "integer"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "decks": [
        ("id", "text"), ("lang", "text"), ("slug", "text"), ("title_de", "text"),
        ("description_de", "text"), ("cefr_band", "text"), ("icon", "text"), ("sort", "integer"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "deck_cards": [
        ("id", "text"), ("deck_id", "text"), ("card_id", "text"), ("position", "integer"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "sentences": [
        ("id", "text"), ("lang", "text"), ("text", "text"), ("origins", "text[]"),
        ("translation_de", "text"), ("model", "text"), ("qa_status", "text"),
        ("qa_report", "jsonb"), ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "sentence_tokens": [
        ("id", "text"), ("sentence_id", "text"), ("idx", "integer"),
        ("start_pos", "integer"), ("end_pos", "integer"), ("surface", "text"),
        ("lemma_id", "text"), ("sense_id", "text"), ("card_id", "text"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "card_sentences": [
        ("id", "text"), ("card_id", "text"), ("sentence_id", "text"), ("position", "smallint"),
        ("gap_start", "integer"), ("gap_end", "integer"), ("accepted", "text[]"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "stories": [
        ("id", "text"), ("lang", "text"), ("slug", "text"), ("title", "text"), ("kind", "text"),
        ("cefr_band", "text"), ("topic", "text"), ("minutes", "integer"), ("cover", "text"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "story_sentences": [
        ("id", "text"), ("story_id", "text"), ("idx", "integer"), ("sentence_id", "text"),
        ("paragraph_idx", "integer"), ("heading", "text"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "exercises": [
        ("id", "text"), ("lang", "text"), ("kind", "text"), ("slug", "text"), ("title", "text"),
        ("cefr_band", "text"), ("payload", "jsonb"), ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "grammar_rules": [
        ("id", "text"), ("lang", "text"), ("slug", "text"), ("title_de", "text"),
        ("summary_de", "text"), ("cefr_band", "text"), ("sections", "jsonb"),
        ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "audio_assets": [
        ("id", "text"), ("lang", "text"), ("owner_kind", "text"), ("owner_id", "text"),
        ("voice", "text"), ("model", "text"), ("path", "text"), ("sha256", "text"),
        ("duration_ms", "integer"), ("removed_in", "text"), ("replaced_by", "text"),
    ],
    "content_releases": [
        ("id", "text"), ("lang", "text"), ("version", "text"), ("schema_version", "integer"),
        ("created_at", "timestamptz"), ("sha256", "text"), ("size_bytes", "bigint"), ("notes", "text"),
    ],
}

TABLE_ORDER: list[str] = list(COLUMNS)


def primary_key(table: str) -> str:
    return "code" if table == "languages" else "id"
