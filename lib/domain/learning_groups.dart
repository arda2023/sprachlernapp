import 'content.dart';
import 'srs_state.dart';

/// A read-only projection. Learned rows are never collapsed. An existing row
/// also reserves a group while disabled, so a synonym cannot bypass disabling.
class LearningGroups {
  LearningGroups(this.cards, this.states);
  final Map<String, ContentCard> cards;
  final Map<String, UserCardState> states;

  List<String> project(Iterable<String> ids) {
    final groups = <String>{};
    final result = <String>[];
    final members = <String, List<String>>{};
    for (final id in states.keys) {
      final c = cards[id];
      if (c != null) (members[c.learningGroup] ??= []).add(id);
    }
    for (final id in ids) {
      final c = cards[id];
      if (c == null || !groups.add(c.learningGroup)) continue;
      final existing = members[c.learningGroup] ?? [];
      final learned = existing.where((id) => states[id]!.box >= 1).toList();
      if (learned.isNotEmpty) {
        result.addAll(learned);
      } else if (existing.isNotEmpty) {
        existing.sort((a, b) {
          final d = (states[a]!.createdAt ?? DateTime(1970)).compareTo(
            states[b]!.createdAt ?? DateTime(1970),
          );
          return d != 0 ? d : a.compareTo(b);
        });
        result.add(existing.first);
      } else if (cards.containsKey(c.learningHead)) {
        result.add(c.learningHead);
      }
    }
    return result;
  }
}

/// Local contexts join only by the exact language/form/sense identity.
Map<String, ContentCard> attachLocalLearning(
  Iterable<ContentCard> content,
  Iterable<ContentCard> locals,
) {
  String identity(ContentCard c) => '${c.lang}|${c.formNorm}|${c.senseId}';
  final byIdentity = {for (final c in content) identity(c): c};
  return {
    for (final c in content) c.id: c,
    for (final c in locals)
      c.id: ContentCard(
        id: c.id,
        lang: c.lang,
        form: c.form,
        formNorm: c.formNorm,
        lemmaId: c.lemmaId,
        lemma: c.lemma,
        pos: c.pos,
        senseId: c.senseId,
        senseKey: c.senseKey,
        formKind: c.formKind,
        formLabelDe: c.formLabelDe,
        translationDe: c.translationDe,
        cefrBand: c.cefrBand,
        learning: c.senseId == null ? null : byIdentity[identity(c)]?.learning,
      ),
  };
}
