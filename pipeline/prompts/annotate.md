version: annotate-v2

You annotate three {lang_name} sentences for German learners. Return one entry per sentence_idx (0, 1, 2), each with a tokens list.

{sentences}

For EVERY listed word token, including function words, give token_idx, surface exactly as listed, dictionary lemma, and a short German gloss in this sentence. For each Target token ("{form}"), use lemma "{lemma}" and gloss "{gloss_de}". Do not include punctuation tokens.
