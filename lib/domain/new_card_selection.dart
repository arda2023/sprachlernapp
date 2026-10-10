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
  Set<String> priorityIds = const {},
  void Function(ContentCard card, int minimumGap)? onSelected,
}) {
  if (limit <= 0) return [];
  final pool = [
    ...candidates.where((c) => priorityIds.contains(c.id)),
    ...candidates.where(
      (c) =>
          !priorityIds.contains(c.id) &&
          !knownLemmas.contains(selectionLemma(c)),
    ),
    ...candidates.where(
      (c) =>
          !priorityIds.contains(c.id) &&
          knownLemmas.contains(selectionLemma(c)),
    ),
  ];
  final lemmas = <String>{}, surfaces = <String>{}, groups = <String>{};
  final recent = <ContentCard>[];
  final picked = <String>[];
  var contentCount = 0, functionCount = 0;
  bool related(ContentCard a, ContentCard b) =>
      a.learning != null &&
      b.learning != null &&
      (a.learning!.topic == b.learning!.topic ||
          a.learning!.related.any(b.learning!.related.contains));
  ContentCard? next(bool? content, int gap, {bool priorityOnly = false}) {
    for (final c in pool) {
      if ((content == null || isContentWord(c) == content) &&
          (!priorityOnly || priorityIds.contains(c.id)) &&
          !lemmas.contains(selectionLemma(c)) &&
          !surfaces.contains(c.formNorm) &&
          !groups.contains(c.learningGroup) &&
          !recent.reversed.take(gap).any((r) => related(c, r))) {
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
    ContentCard? c;
    var selectedGap = 3;
    // Bounded relaxation: 3 intervening new targets, then 2, 1, 0 only
    // when the available content/function quota offers no such candidate.
    for (var gap = 3; gap >= 0 && c == null; gap--) {
      selectedGap = gap;
      c =
          next(null, gap, priorityOnly: true) ??
          (preferFunction ? next(false, gap) : null) ??
          next(true, gap) ??
          (functionAllowed ? next(false, gap) : null);
    }
    if (c == null) break;
    onSelected?.call(c, selectedGap);
    picked.add(c.id);
    recent.add(c);
    groups.add(c.learningGroup);
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
