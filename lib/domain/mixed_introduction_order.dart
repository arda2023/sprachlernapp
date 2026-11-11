import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'content.dart';

/// Stable across restarts, independent of alphabetical/editorial input order.
/// Existing learning-group/lemma exclusions still run in selectNewTargets.
List<String> mixedIntroductionOrder(
  List<String> ids,
  Map<String, ContentCard> cards,
  String source,
) {
  final ranks = {
    for (final id in ids)
      id: sha256.convert(utf8.encode('introduction-v1/$source/$id')).toString(),
  };
  final remaining = ids.toSet().toList()
    ..sort((a, b) => ranks[a]!.compareTo(ranks[b]!));
  final result = <String>[];
  String? previous;
  while (remaining.isNotEmpty) {
    String initial(String id) {
      final form = cards[id]?.formNorm ?? id;
      return form.isEmpty ? '' : String.fromCharCode(form.runes.first);
    }

    bool related(String a, String b) {
      final left = cards[a]?.learning, right = cards[b]?.learning;
      return left != null &&
          right != null &&
          ((left.topic.isNotEmpty && left.topic == right.topic) ||
              left.related.any(right.related.contains));
    }

    var next = -1;
    for (var gap = 3; gap >= 0 && next < 0; gap--) {
      bool spaced(String id) =>
          !result.reversed.take(gap).any((old) => related(id, old));
      next = remaining.indexWhere(
        (id) => initial(id) != previous && spaced(id),
      );
      if (next < 0) next = remaining.indexWhere(spaced);
    }
    if (next < 0) next = 0;
    final id = remaining.removeAt(next);
    result.add(id);
    previous = initial(id);
  }
  return result;
}
