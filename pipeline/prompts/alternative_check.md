version: alternative-check-v1

A learner app shows an English sentence with one gap. Other answers were proposed for the gap. The code has already inserted each candidate literally in place of the original gap text; the rest of the sentence is unchanged. Judge every finished candidate sentence.

Original sentence: {text}
German translation: {translation_de}
Candidate sentences ({n}):
{candidates}

For each candidate set valid to true only if the finished sentence, exactly as written, is grammatically correct, natural, and keeps the same relevant meaning as the original sentence, so that the German translation still fits. Ignore only letter case of the inserted text.
Set valid to false for: an extra or duplicated word or article (for example "up the the stairs"), wrong grammar, an unnatural phrase, a shifted or opposite meaning, or a merely related meaning. If in doubt, set valid to false.
Do not rewrite the sentence and do not correct a candidate; judge it as written.

Return results with exactly one object per candidate_index from 1 to {n}: candidate_index (integer), valid (boolean), reason (short string). Never add other indices. Return only the JSON object.
