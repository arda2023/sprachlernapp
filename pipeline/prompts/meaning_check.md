version: meaning-check-v6

Check the English sentence and its German translation for the vocabulary card. Identify the sense and the part of speech the form has in this exact sentence. Do not force a choice: return null for sense_key or observed_pos when genuinely unclear.

Sentence: {text}
Form: {form}
German translation: {translation_de}
Candidate meanings (sense_key, POS, form description, German gloss):
{meanings}

Choose sense_key only from the listed keys. `observed_pos` must be the contextual POS of the form (Universal POS tag). English UD convention: copular "be" (state, property, identity, location) is AUX; "be" meaning "exist" is VERB. Learner terms such as "Vollverb" in the form description are not POS tags.

Check whether the German translation preserves the English meaning, especially time or tense, negation, who does what, and modality. Accept idiomatic German that means the same thing; reject translations that add, remove, or shift those details. Set translation_ok to true only when the translation is meaning-equivalent. Give a short reason for your decisions.

Judge the English sentence exactly as written, with the form in its original position. Set language_ok to true only if a careful native speaker would accept it as natural, common English: grammatically correct, the form used idiomatically in this context, correct spelling and word boundaries (words normally written as one word or hyphenated are not split), and no word split or altered just to contain the form. Accept legitimate variants (British or American spelling, usual compounds and fixed expressions). language_ok covers the whole sentence, not only the form: every word combination must be natural and every property must make sense for what it describes; a correct use of the form alone is not enough. An unusual but plausible situation is acceptable. A correct German translation does not make an unnatural English sentence acceptable. If in doubt, set language_ok to false.

Return exactly these fields: sense_key (listed key or null), observed_pos (POS tag or null), translation_ok (boolean), language_ok (boolean), reason (always a short, non-empty string, also when every check passes; it must cover every false field). Never invent a key or POS tag.
