version: annotate-v3

You annotate the supplied {lang_name} sentence(s) for German learners. Return one entry per supplied sentence_idx, each with a tokens list.

{sentences}

For EVERY listed word token, including function words, give token_idx, surface exactly as listed, dictionary lemma, and a short German gloss in this sentence. For each Target token ("{form}"), use lemma "{lemma}" and gloss "{gloss_de}". Do not include punctuation tokens.
