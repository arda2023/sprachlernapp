"""Convert pinned Kaikki/dewiktionary text only. No inferred forms or AI calls.
macOS/PowerShell: python tool/offline_dictionary/build.py <source-dir> <output-dir>
"""
import collections
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import unicodedata
from urllib.parse import quote


def norm(text):
    return unicodedata.normalize('NFC', text).lower()


def build(source, output):
    output.mkdir(parents=True, exist_ok=True)
    target = output / 'dictionary.sqlite'
    target.unlink(missing_ok=True)
    db = sqlite3.connect(target)
    db.executescript('''PRAGMA user_version=1;
    CREATE TABLE entries(id INTEGER PRIMARY KEY, lang TEXT NOT NULL, lemma TEXT NOT NULL,
      pos TEXT NOT NULL, gloss TEXT NOT NULL, tags TEXT NOT NULL, source TEXT NOT NULL);
    CREATE TABLE lookup(lang TEXT NOT NULL, form TEXT NOT NULL, entry INTEGER NOT NULL,
      via TEXT NOT NULL, PRIMARY KEY(lang,form,entry,via)) WITHOUT ROWID;
    ''')
    sources = []
    for short, lang, edition in [('en', 'en', 'Englisch'), ('pt', 'pt-BR', 'Portugiesisch')]:
        raw = source / f'{short}.jsonl'
        entries = collections.defaultdict(list)
        links = []
        rows = 0
        for line in raw.open(encoding='utf8'):
            data = json.loads(line)
            if data.get('lang_code') != short:
                raise ValueError('unexpected source language')
            rows += 1
            word, pos = data['word'], data.get('pos_title', data.get('pos', ''))
            url = 'https://de.wiktionary.org/wiki/' + quote(word, safe='')
            for sense in data.get('senses', []):
                refs = sense.get('form_of', [])
                if refs:
                    for ref in refs:
                        if ref.get('word'):
                            links.append((word, ref['word'], data.get('pos'), url))
                    continue
                gloss = '; '.join(sense.get('glosses', []))
                if not gloss or 'no-gloss' in sense.get('tags', []):
                    continue
                tags = ', '.join(dict.fromkeys(data.get('tags', []) + sense.get('tags', []) + sense.get('raw_tags', [])))
                idx = db.execute('INSERT INTO entries(lang,lemma,pos,gloss,tags,source) VALUES(?,?,?,?,?,?)',
                    (lang, word, pos, gloss, tags, url)).lastrowid
                entries[(norm(word), data.get('pos'))].append(idx)
                db.execute('INSERT OR IGNORE INTO lookup VALUES(?,?,?,?)', (lang, norm(word), idx, ''))
        unresolved = 0
        for form, lemma, pos, url in links:
            ids = entries.get((norm(lemma), pos), [])
            if not ids:
                unresolved += 1
            for idx in ids:
                db.execute('INSERT OR IGNORE INTO lookup VALUES(?,?,?,?)', (lang, norm(form), idx, url))
        sources.append(dict(lang=lang, url=f'https://kaikki.org/dewiktionary/{edition}/kaikki.org-dictionary-{edition}.jsonl',
            sha256=hashlib.sha256(raw.read_bytes()).hexdigest(), bytes=raw.stat().st_size,
            source_rows=rows, explicit_form_links=len(links), unresolved_form_links=unresolved))
    db.execute('CREATE INDEX entry_language ON entries(lang)')
    db.commit()
    counts = {lang: dict(senses=db.execute('SELECT count(*) FROM entries WHERE lang=?',(lang,)).fetchone()[0],
        lookup_forms=db.execute('SELECT count(DISTINCT form) FROM lookup WHERE lang=?',(lang,)).fetchone()[0],
        form_links=db.execute("SELECT count(*) FROM lookup WHERE lang=? AND via<>''",(lang,)).fetchone()[0]) for lang in ['en','pt-BR']}
    db.execute('VACUUM')
    db.close()
    blob = target.read_bytes()
    packed = gzip.compress(blob, mtime=0)
    (output / 'dictionary.sqlite.gz').write_bytes(packed)
    manifest = dict(contract=1, version='dewiktionary-2026-10-24-v1', license='CC-BY-SA-4.0',
        sha256=hashlib.sha256(blob).hexdigest(), bytes=len(blob), compressed_bytes=len(packed),
        compressed_sha256=hashlib.sha256(packed).hexdigest(), sources=sources, counts=counts)
    (output / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n',encoding='utf8')
    print(json.dumps(manifest, ensure_ascii=False, indent=2))
    target.unlink()


if __name__ == '__main__':
    build(Path(sys.argv[1]), Path(sys.argv[2]))
