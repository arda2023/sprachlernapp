"""Explicit locally installed linguistic capabilities. Unknown never means English."""
from __future__ import annotations

from dataclasses import dataclass
import re
import unicodedata

from .ids import form_norm
from .word_registry import digest


class UnsupportedLanguage(ValueError):
    code = 'PROFILE_UNSUPPORTED'


def canonical_language(value):
    if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*', value):
        raise ValueError('Sprachcode als BCP-47-Tag eingeben, zum Beispiel en.')
    parts = value.split('-')
    return '-'.join([parts[0].lower(), *[p.title() if len(p)==4 and p.isalpha()
        else p.upper() if len(p)==2 and p.isalpha() else p.lower() for p in parts[1:]]])


def canonical_text(value):
    if not isinstance(value, str) or any(0xD800 <= ord(c) <= 0xDFFF for c in value):
        raise ValueError('Text enthält ungültige Unicodezeichen.')
    return unicodedata.normalize('NFC', value.replace('\r\n','\n'))


def utf16_to_codepoint(text, offset):
    if type(offset) is not int or offset < 0:
        raise ValueError('Ungültige Textauswahl.')
    used = 0
    for i,ch in enumerate(text):
        if used == offset: return i
        used += 2 if ord(ch)>0xFFFF else 1
        if used > offset: raise ValueError('Auswahl trennt ein Unicodezeichen.')
    if used == offset: return len(text)
    raise ValueError('Textauswahl liegt außerhalb des Satzes.')


@dataclass(frozen=True)
class LanguageProfile:
    lang: str = 'en'
    id: str = 'en-legacy-v1'
    model: str = 'en_core_web_sm'
    model_version: str = '3.8.0'
    translation_lang: str = 'de'

    @property
    def manifest(self):
        return {'id':self.id,'lang':self.lang,'translation_lang':self.translation_lang,
                'model':self.model,'model_version':self.model_version,
                'normalization':'NFC-lower-apostrophe-v1',
                'answer_policy':'legacy-target-alternative-form-typo-wrong-v1',
                'allowed_functions':['base','past','past_participle']}

    @property
    def sha256(self): return digest(self.manifest)

    def tokenize(self, text, gap=None):
        from .annotate import tokenize
        from .linter import _nlp
        nlp = _nlp(self.model)
        if nlp.meta['version'] != self.model_version:
            raise UnsupportedLanguage('Das installierte Sprachmodell passt nicht zum geprüften Profil.')
        return tokenize(text, nlp, lexical_spans=[gap] if gap else None)

    def validate_sentence(self, text, form, start, end, cefr_band='anfaenger'):
        from .linter import lint_sentence, _nlp
        from .config import load_config
        cfg = load_config(); lc = cfg['linter']
        result = list(lint_sentence(text,form,start,end,lc['min_zipf'][cefr_band],
            lang=self.lang,names=cfg['generate']['names'],max_words=lc['max_words'],
            max_subclauses=lc['max_subclauses'],nlp=_nlp(self.model)))
        if len(list(_nlp(self.model)(text).sents)) != 1:
            from .linter import Finding
            result.append(Finding('error','sentence_count','Genau ein Übungssatz ist erforderlich.'))
        return result

    def gap(self, text, start, end, form):
        if any(type(n) is not int for n in (start,end)) or not 0<=start<end<=len(text):
            raise ValueError('Lücke liegt außerhalb des Satzes.')
        if form_norm(text[start:end]) != form_norm(form):
            raise ValueError('Die Lücke passt nicht zum Lernziel.')
        from .linter import _whole_token_count
        if _whole_token_count(text,form) != 1:
            raise ValueError('Das Lernziel muss genau einmal vorkommen; alle Fundstellen prüfen.')
        self.tokenize(text,(start,end))
        return {'start_pos':start,'end_pos':end,'surface':text[start:end],
                'sentence_text_sha256':digest(text)}


PROFILES = {'en': LanguageProfile()}


def get_profile(lang, profile_id=None):
    profile = PROFILES.get(canonical_language(lang))
    if profile is None or (profile_id is not None and profile.id != profile_id):
        raise UnsupportedLanguage('Sprachfunktionen noch nicht unterstützt. Entwurf speichern ist möglich.')
    return profile
