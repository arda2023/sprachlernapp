import 'answer_check.dart';
import 'content.dart';

/// Sense-specific exceptions to pack POS tags, never a surface blacklist.
const _functionSenses = {
  'have#muessen',
  'get#werden',
  'but#nur',
  'no#nicht',
  'that#so',
  'the#umso',
  'just#nur',
  'more#mehr_steigerung',
  'more#wieder_noch',
  'like#fuellwort',
  'when#in_dem',
  'when#wann',
  'as#so_vergleich',
  'so#ebenfalls',
  'so#so_sehr',
  'about#ungefaehr',
  'about#im_begriff',
  'on#weiter',
};
const _lexicalAuxSenses = {
  'be#sein_vollverb',
  'be#sein_existieren',
  'be#befinden',
};

bool isContentWord(ContentCard card) {
  if (_functionSenses.contains(card.senseKey)) return false;
  if (card.pos == 'AUX') return _lexicalAuxSenses.contains(card.senseKey);
  return const {'NOUN', 'VERB', 'ADJ', 'ADV'}.contains(card.pos);
}

String selectionLemma(ContentCard card) => normalizeAnswer(card.lemma);

/// Ranked candidates, distinct lemma and surface even across POS/lemma IDs.
/// Each group prefers never displayed lemmas, retaining input order per tier.
/// Scarcity shortens the session: no duplicate refill and at most one function
/// word per four content words (one remains available when content runs out).
List<String> selectNewCards({
  required List<ContentCard> candidates,
  required Set<String> knownLemmas,
  required int limit,
}) {
  if (limit <= 0) return [];
  final pool = [
    ...candidates.where((c) => !knownLemmas.contains(selectionLemma(c))),
    ...candidates.where((c) => knownLemmas.contains(selectionLemma(c))),
  ];
  final lemmas = <String>{}, surfaces = <String>{};
  final picked = <String>[];
  var contentCount = 0, functionCount = 0;
  ContentCard? next(bool content) {
    for (final c in pool) {
      if (isContentWord(c) == content &&
          !lemmas.contains(selectionLemma(c)) &&
          !surfaces.contains(c.formNorm)) {
        return c;
      }
    }
    return null;
  }

  while (picked.length < limit) {
    final functionAllowed =
        functionCount < (contentCount ~/ 4 > 0 ? contentCount ~/ 4 : 1);
    final preferFunction =
        contentCount > 0 &&
        contentCount % 4 == 0 &&
        functionCount < contentCount ~/ 4;
    final c =
        (preferFunction ? next(false) : null) ??
        next(true) ??
        (functionAllowed ? next(false) : null);
    if (c == null) break;
    picked.add(c.id);
    lemmas.add(selectionLemma(c));
    surfaces.add(c.formNorm);
    if (isContentWord(c)) {
      contentCount++;
    } else {
      functionCount++;
    }
  }
  return picked;
}
