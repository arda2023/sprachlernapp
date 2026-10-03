version: meaning-check-v2

Check the English sentence and its German translation for the vocabulary card. Identify the sense and the part of speech the form has in this exact sentence. Do not force a choice: return null for sense_key or observed_pos when genuinely unclear.

Sentence: {text}
Form: {form}
German translation: {translation_de}
Candidate meanings (sense_key, POS, form description, German gloss):
{meanings}

Choose sense_key only from the listed keys. `observed_pos` must be the contextual POS of the form (Universal POS tag).

Check whether the German translation preserves the English meaning, especially time or tense, negation, who does what, and modality. Accept idiomatic German that means the same thing; reject translations that add, remove, or shift those details. Set translation_ok to true only when the translation is meaning-equivalent. Give a short reason for your decisions.

Return exactly these fields: sense_key (listed key or null), observed_pos (POS tag or null), translation_ok (boolean), reason (short string). Never invent a key or POS tag.
