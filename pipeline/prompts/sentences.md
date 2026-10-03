version: sentences-v2

You write example sentences for a {lang_name} vocabulary card for adult German speakers.

Card:
- form: "{form}" (write it exactly like this, same spelling and same case)
- meaning: {pos}, lemma "{lemma}", German gloss "{gloss_de}" ({form_label_de}, German: "{translation_de}")
- level: {cefr_band}
- situation for this slot: {situation}
- permitted first name if needed: {name} (use no other name)
- avoid these overused content words if possible: {avoid_words}

Write exactly {count} sentence(s). Rules for every sentence:
1. It contains exactly this form "{form}" exactly once, in exactly this meaning. No other form of the word.
2. Do not start the sentence with the form if that would change its case.
3. At most 14 words.
4. At most 1 subordinate clause.
5. Understandable without context: no pronoun without a clear referent, no ellipsis.
6. Vocabulary and grammar fit the level "{cefr_band}" (anfaenger = A1-A2, mittel = B1-B2, fortgeschritten = C1-C2).
7. Everyday situations. No proper names except simple first names.
8. The context makes the form guessable: a learner who sees the sentence with a gap, the German translation and the gloss can name exactly this form (e.g. a time word that fixes the tense).
9. The sentences differ in structure and situation.
10. Ends with . ? or !  No digits.
translation_de: natural German translation, not word for word.
{feedback}
