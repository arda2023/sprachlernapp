import 'package:unorm_dart/unorm_dart.dart' as unicode;

import 'offline_dictionary.dart';

/// A general dictionary meaning, never a checked context/sense binding.
///
/// User decision 01.11.2026: a word tap asks the offline dictionary first
/// and only goes to the AI when it has nothing usable. The first sense of
/// the word (Wiktionary order; closed word classes such as articles before
/// homonyms) decides: if its gloss starts with a short translation ("Bank",
/// "ankommen, eintreffen", "die Mauer, die Wand"), up to two such terms are
/// shown, also for verbs and inflected forms ("arrived" → arrive). A gloss
/// that is a definition ("Stelle in einer Masse, …"), names, phrases and
/// restricted senses (slang, specialist fields) leave the word to the AI.
String? singleDictionaryTranslation(
  String form,
  List<DictionaryCandidate> candidates,
) {
  // The lookup cap was reached: malformed or hopelessly ambiguous.
  if (candidates.isEmpty || candidates.length >= 80) return null;
  final usable = [
    for (final c in candidates)
      if (!_excludedPos.contains(c.pos) && _plainTags(c.tags)) c,
  ];
  if (usable.isEmpty) return null;
  // Stable: Wiktionary order within each rank.
  final ranked = [
    ...usable.where((c) => _closedClass.contains(c.pos)),
    ...usable.where((c) => !_closedClass.contains(c.pos)),
  ];
  final terms = _leadingTerms(ranked.first.gloss);
  return terms.isEmpty ? null : terms.take(2).join(', ');
}

/// The short translations a gloss starts with, before any explanation.
List<String> _leadingTerms(String gloss) {
  final plain = unicode
      .nfc(gloss)
      .replaceAll(RegExp(r'\([^)]*\)'), '')
      .split(RegExp(r'[:;]'))
      .first;
  final terms = <String>[];
  for (final raw in plain.split(',')) {
    final term = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final words = term.split(' ');
    // Several words only as a translation ("die Mauer", "sich freuen"),
    // never as a description ("tropische Pflanze").
    if (!_term.hasMatch(term) ||
        term.length > 32 ||
        words.length > 3 ||
        words.length > 1 && !_leadWords.contains(words.first)) {
      break;
    }
    terms.add(term);
  }
  return terms;
}

/// Letters (with accents), hyphens and apostrophes, words separated by
/// single spaces: no digits, quotes, ellipses or leftover brackets.
final _term = RegExp(
  r"^[A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’-]+(?: [A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’-]+)*$",
);

const _leadWords = {
  'der',
  'die',
  'das',
  'ein',
  'eine',
  'sich',
  'etwas',
  'jemanden',
  'jemandem',
  'zu',
};

/// Names, abbreviations and multi-word entries are not a word's meaning.
const _excludedPos = {
  'Nachname',
  'Vorname',
  'Toponym',
  'Abkürzung',
  'Redewendung',
  'Wortverbindung',
  'Sprichwort',
  'Eigenname',
};

/// A tapped "the" is the article, not the "the … the" adverb.
const _closedClass = {
  'Artikel',
  'Pronomen',
  'Personalpronomen',
  'Possessivpronomen',
  'Demonstrativpronomen',
  'Relativpronomen',
  'Interrogativpronomen',
  'Reflexivpronomen',
  'Indefinitpronomen',
  'Präposition',
  'Konjunktion',
  'Subjunktion',
  'Hilfsverb',
};

/// Grammar-only tags; anything else (slang, a specialist field, a region's
/// usage) marks a sense the learner should not get as the plain meaning.
bool _plainTags(String tags) {
  for (final tag in tags.split(',')) {
    final t = tag.trim();
    if (t.isNotEmpty && !_grammarTags.contains(t)) return false;
  }
  return true;
}

const _grammarTags = {
  'masculine',
  'feminine',
  'neuter',
  'noun',
  'transitive',
  'intransitive',
  'trans',
  'intrans',
  'irregular',
  'auxiliary',
  'als Vollverb',
  'attributiv',
  'nur Singular',
  'nur Plural',
  'plural-only',
  'plural-normally',
  'form-of',
  'indicative',
  'present',
  'past',
  'participle',
  'singular',
  'plural',
  'British',
  'US',
};
