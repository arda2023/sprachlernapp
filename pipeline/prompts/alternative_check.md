version: alternative-check-v2

A learner app shows an English sentence with one gap. Other answers were proposed for the gap. The code has already inserted each candidate literally in place of the original gap text; the rest of the sentence is unchanged. Judge every finished candidate sentence.

Original sentence: {text}
German translation: {translation_de}
Candidate sentences ({n}):
{candidates}

For each candidate set valid to true only if both hold:
1. The finished sentence, exactly as written, is grammatically correct and natural English.
2. It states the same thing as the original sentence, so that the given German translation still translates it exactly. Same topic, a related meaning or a situation where the candidate could also be true is not enough.
Preserve in particular: quantities and limits (an approximate amount, German "ungefähr", is not "fast", "mindestens" or "höchstens"); direction (a movement "hinauf" is not merely "entlang"); negation, time reference, modality, and who does what. Do not read extra information into the original or the translation.
A different word length or a slightly more formal or informal register alone is no reason to reject.
Set valid to false for: an extra or duplicated word or article (for example "up the the stairs"), wrong grammar, an unnatural phrase, a shifted, weaker, stronger or opposite meaning, or a merely related meaning. If in doubt, set valid to false.
Do not rewrite the sentence and do not correct a candidate; judge it as written.

Return results with exactly one object per candidate_index from 1 to {n}: candidate_index (integer), valid (boolean), reason (short string). Never add other indices. Return only the JSON object.
