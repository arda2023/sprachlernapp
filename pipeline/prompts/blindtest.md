version: blindtest-v2

A {lang_name} sentence has one gap (___). Name the missing word or words.

Sentence: {gapped}
German translation of the full sentence: {translation_de}
Meaning of the missing word (German): {gloss_de}

Return answer (the most likely missing text) and alternatives (at most three objects with answer and a brief reason). Consider other natural solutions, including multiword solutions, that preserve the same meaning and the German translation without changing any other part of the sentence. Merely similar meanings do not qualify. Give a reason for each alternative. Keep reasons brief. Use an empty list when you find none; never invent alternatives to fill the list. Return only the JSON object.
