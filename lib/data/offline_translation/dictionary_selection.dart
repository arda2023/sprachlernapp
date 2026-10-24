import 'package:unorm_dart/unorm_dart.dart' as unicode;

import 'offline_dictionary.dart';

/// A general dictionary meaning, never a checked context/sense binding.
/// Conservative structural eligibility; no ranking or morphology guessing.
String? singleDictionaryTranslation(
  String form,
  List<DictionaryCandidate> candidates,
) {
  if (candidates.isEmpty || candidates.length >= 80) return null;
  final key = unicode.nfc(form).toLowerCase();
  final meanings = <String>{};
  for (final candidate in candidates) {
    if (candidate.formSource.isNotEmpty ||
        unicode.nfc(candidate.lemma).toLowerCase() != key ||
        candidate.pos != 'Substantiv') {
      return null;
    }
    final tags = candidate.tags.split(',').map((t) => t.trim());
    if (tags.any((t) => !{'', 'masculine', 'feminine', 'neuter'}.contains(t))) {
      return null;
    }
    final gloss = unicode.nfc(candidate.gloss.trim());
    // A phrase, alternatives, usage commentary or embedded senses are not a
    // single lexical gloss. Do not cut at punctuation to fabricate one.
    if (!RegExp(r'^[A-ZÄÖÜ][a-zäöüß]+(?:-[A-ZÄÖÜa-zäöüß][a-zäöüß]+)*$')
        .hasMatch(gloss)) {
      return null;
    }
    meanings.add(gloss);
  }
  return meanings.length == 1 ? meanings.single : null;
}
