"""Apply the two exact, reviewable source edits required by compound target spans.
Call on a disposable copy for verification; repository application belongs to Codex.
No validation rule is removed. Existing tokenize(text) behaviour is unchanged.
"""
from pathlib import Path
import argparse
OLD='''    return [{"idx": t.i, "start_pos": t.idx, "end_pos": t.idx + len(t.text),
             "surface": t.text, "pos": t.pos_, "is_word": any(ch.isalpha() for ch in t.text)}
            for t in doc]'''
NEW='''    tokens = [{"idx": t.i, "start_pos": t.idx, "end_pos": t.idx + len(t.text),
               "surface": t.text, "pos": t.pos_, "is_word": any(ch.isalpha() for ch in t.text)}
              for t in doc]
    spans = sorted(set(tuple(span) for span in (lexical_spans or ())))
    previous_end = -1
    for start, end in spans:
        if (type(start) is not int or type(end) is not int or
                not 0 <= start < end <= len(text) or start < previous_end):
            raise ValueError("invalid or overlapping lexical spans")
        selected = [t for t in tokens if start <= t["start_pos"] and t["end_pos"] <= end]
        if (not selected or selected[0]["start_pos"] != start or
                selected[-1]["end_pos"] != end or
                not any(t["is_word"] for t in selected)):
            raise ValueError("lexical span must cover complete word tokens")
        # Merge only an explicitly supplied card gap. Never rewrite all hyphens.
        first = tokens.index(selected[0]); last = tokens.index(selected[-1])
        surface = text[start:end]
        tokens[first:last+1] = [{"idx": first, "start_pos": start, "end_pos": end,
                               "surface": surface, "pos": selected[0]["pos"],
                               "is_word": True}]
        previous_end = end
    for idx, token in enumerate(tokens):
        token["idx"] = idx
    return tokens'''
def apply(root):
    root=Path(root)
    p=root/'pipeline/src/sprachpipe/annotate.py';s=p.read_text()
    signature='def tokenize(text: str, nlp=None) -> list[dict]:'
    new_signature='def tokenize(text: str, nlp=None, *, lexical_spans=None) -> list[dict]:'
    if signature in s:
        if s.count(signature)!=1 or s.count(OLD)!=1:raise ValueError('annotate.py differs from reviewed source')
        s=s.replace(signature,new_signature).replace(OLD,NEW);p.write_text(s)
    elif new_signature not in s or NEW not in s:raise ValueError('unknown tokenize implementation')
    p=root/'pipeline/scripts/import_editorial_patch.py';s=p.read_text()
    old="        expected = tokenize(sn['text'])"
    new="        expected = tokenize(sn['text'], lexical_spans=[(c['gap_start'], c['gap_end']) for c in links])"
    if old in s:
        if s.count(old)!=1:raise ValueError('ambiguous importer call')
        s=s.replace(old,new);p.write_text(s)
    elif new not in s:raise ValueError('importer differs from reviewed source')
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('root',type=Path);apply(a.parse_args().root)
