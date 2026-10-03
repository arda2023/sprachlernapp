version: meanings-v2

You are a lexicographer preparing vocabulary cards for adult German speakers learning {lang_name}.

Word form: "{form}"
Frequency rank (wordfreq, {lang}): {rank}

List the meanings of exactly this form that are genuinely relevant for learners who meet this form. At most 3, most important first. Treat function words (prepositions, particles, adverbs such as "about", "up", "so", "just", "the") like any other word: give their relevant meanings.

For each meaning:
- pos: Universal POS tag of the form in this meaning (NOUN, VERB, ADJ, ADV, ADP, PRON, DET, AUX, CCONJ, SCONJ, PART, INTJ).
- lemma: dictionary form (e.g. "go" for "went").
- sense_key: stable slug "<lemma>#<short German keyword>", lowercase, ASCII only (ae/oe/ue/ss for umlauts), e.g. "leave#verlassen", "left#links".
- gloss_de: short German gloss with a brief distinction from other meanings of this form. For example, for "left": "verlassen (einen Ort verlassen)" versus "zurücklassen (etwas liegen lassen)". Do not merge senses that differ this way.
- form_kind: one of base, past, past_participle, present_participle, third_person, plural, comparative, superlative, other.
- form_label_de: German label, e.g. "Verb, Vergangenheit", "Adjektiv, Grundform", "Präposition".
- cefr_band: anfaenger (A1-A2), mittel (B1-B2) or fortgeschritten (C1-C2) for this meaning.
- translation_de: German translation of exactly this form in this meaning (e.g. "ging" for "went").

If the form is an abbreviation or fragment (e.g. "'s", "n't"), a proper name or a number, return an empty list.
