version: sentences-v6

You write example sentences for a {lang_name} vocabulary card for adult German speakers.

Card:
- form: "{form}" (use this display spelling; sentence-initial capitalization is allowed)
- meaning: {pos}, lemma "{lemma}", German gloss "{gloss_de}" ({form_label_de}, German: "{translation_de}")
- level: {cefr_band}
- avoid these overused content words if possible: {avoid_words}

For the {count} sentence slots, follow the matching situation and permitted name. Use no other names:
{slot_instructions}

Write exactly {count} sentence(s). Rules for every sentence:
1. It contains this form "{form}" exactly once, in exactly this meaning. Case may follow sentence position. No other form of the word.
2. Capitalize sentence beginnings normally; always write the pronoun I in uppercase.
3. At most 14 words.
4. At most 1 subordinate clause.
5. Understandable without context: no pronoun without a clear referent, no ellipsis.
6. Vocabulary and grammar fit the level "{cefr_band}" (anfaenger = A1-A2, mittel = B1-B2, fortgeschritten = C1-C2).
7. Everyday situations. No proper names except simple first names.
8. The context makes the form guessable: a learner who sees the sentence with a gap, the German translation and the gloss names this form as the most natural answer (e.g. a time word that fixes the tense). A true synonym that also fits is acceptable; do not force unnatural wording to exclude it.
9. Use a different first word for every sentence, ignoring case. Vary sentence patterns: mix statements, questions, requests, and negation where natural. Make the situations distinct.
10. Ends with . ? or !  No digits.
11. Natural, common English that a native speaker would write: idiomatic word choice and collocations, correct spelling and word boundaries. Never split a word or a word normally written as one (e.g. a closed compound) so that the form appears separately; if the form only fits unnaturally, choose a different situation.
translation_de: idiomatic German that preserves the sentence meaning, including time/tense, negation, who does what, and modality. Do not add a time-of-day meaning for "early" when the English means "before expected". Natural phrasing is welcome; changing meaning is not.
{feedback}
