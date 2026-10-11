import 'content.dart';
import 'srs_state.dart';

/// A read-only projection. Learned rows are never collapsed. An existing row
/// also reserves a group while disabled, so a synonym cannot bypass disabling.
class LearningGroups {
  LearningGroups(this.cards, this.states);
  final Map<String, ContentCard> cards;
  final Map<String, UserCardState> states;

  List<String> project(Iterable<String> ids, {bool exactForms = false}) {
    final groups = <String>{};
    final result = <String>[];
    final members = <String, List<String>>{};
    for (final id in states.keys) {
      final c = cards[id];
      if (c != null) (members[c.learningGroup] ??= []).add(id);
    }
    for (final id in ids) {
      final c = cards[id];
      if (c == null) continue;
      if (exactForms && c.formFunction != null) {
        result.add(id);
        continue;
      }
      if (!groups.add(c.learningGroup)) continue;
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
    return result.toSet().toList();
  }
}

/// Local contexts join only by the exact language/form/sense identity.
Map<String, ContentCard> attachLocalLearning(
  Iterable<ContentCard> content,
  Iterable<ContentCard> locals,
) {
  String identity(ContentCard c) => '${c.lang}|${c.formNorm}|${c.senseId}|${c.formFunction}';
  final byIdentity = <String, List<ContentCard>>{};
  for (final c in content) { (byIdentity[identity(c)] ??= []).add(c); }
  ContentCard? counterpart(ContentCard c) {
    final values = byIdentity[identity(c)] ?? [];
    return values.length == 1 ? values.single : null;
  }
  String? lexical(ContentCard c) {
    final ids = content.where((v) => v.lang == c.lang && v.senseId != null && v.senseId == c.senseId)
        .map((v) => v.lexicalTargetId).whereType<String>().toSet();
    return ids.length == 1 ? ids.single : c.lexicalTargetId;
  }
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
        learning: c.senseId == null ? null : counterpart(c)?.learning,
        formTarget: c.formTarget,
        identityFunction: c.identityFunction,
        introductionScope: c.introductionScope,
        lexicalTargetId: lexical(c),
      ),
  };
}

/// Reuse an explicit lexical key throughout its sense/group component. Without
/// an explicit key the old group fallback stays unchanged, including schema 3.
Map<String, String> lexicalCountingKeys(Map<String, ContentCard> cards) {
  final parent = {for (final id in cards.keys) id: id};
  String root(String id) {
    if (parent[id] != id) parent[id] = root(parent[id]!);
    return parent[id]!;
  }
  final groups = <String, String>{}, senses = <String, String>{};
  for (final c in cards.values) {
    final group = groups.putIfAbsent('${c.lang}|${c.learningGroup}', () => c.id);
    parent[root(c.id)] = root(group);
    if (c.senseId != null) {
      final sense = senses.putIfAbsent('${c.lang}|${c.senseId}', () => c.id);
      parent[root(c.id)] = root(sense);
    }
  }
  final explicit = <String, Set<String>>{};
  for (final c in cards.values) {
    if (c.lexicalTargetId != null) (explicit[root(c.id)] ??= {}).add(c.lexicalTargetId!);
  }
  final result = <String,String>{};
  for (final c in cards.values) {
    final keys = explicit[root(c.id)] ?? {};
    if (keys.length > 1) throw StateError('Widersprüchliche Wortzuordnung für ${c.form}; Lernstände bleiben erhalten.');
    result[c.id] = keys.isEmpty ? 'group:${c.lang}:${c.learningGroup}' : 'lexical:${c.lang}:${keys.single}';
  }
  return result;
}
