version: annotate-v1

You annotate a {lang_name} sentence for German learners.

Sentence: {text}
German translation: {translation_de}

Tokens (index: surface):
{tokens}

For EVERY token listed above, including function words (articles, prepositions, pronouns, auxiliaries), give:
- token_idx: the index from the list
- surface: the token exactly as listed
- lemma: dictionary form
- gloss_de: short German gloss of this token in this sentence (the meaning here, not all meanings)

Token {card_idx} ("{form}") has the meaning: lemma "{lemma}", gloss "{gloss_de}". Use exactly this lemma and gloss for it.
