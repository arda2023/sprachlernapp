import 'package:flutter/foundation.dart';

import 'word_list_models.dart';

/// In-memory Wortliste state until Riverpod and Drift arrive. The list and
/// the details sheet listen to the same store.
class WordListStore extends ChangeNotifier {
  WordListStore(List<VocabWord> words) : _words = List.of(words);

  final List<VocabWord> _words;

  /// Most recently seen first.
  List<VocabWord> get words =>
      List.of(_words)..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));

  List<VocabWord> get playlist => words.where((w) => w.inPlaylist).toList();

  VocabWord byId(String id) => _words.firstWhere((w) => w.id == id);

  /// Matches headword or German translation, case-insensitive.
  List<VocabWord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return words;
    return words
        .where(
          (w) =>
              w.entry.headword.toLowerCase().contains(q) ||
              w.entry.translation.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Each toggle returns the new value, so callers can confirm it.
  bool toggleDisabled(String id) =>
      _update(id, (w) => w.copyWith(isDisabled: !w.isDisabled)).isDisabled;

  bool toggleFavorite(String id) =>
      _update(id, (w) => w.copyWith(isFavorite: !w.isFavorite)).isFavorite;

  bool togglePlaylist(String id) =>
      _update(id, (w) => w.copyWith(inPlaylist: !w.inPlaylist)).inPlaylist;

  void setNote(String id, String note) {
    if (byId(id).note == note) return;
    _update(id, (w) => w.copyWith(note: note));
  }

  VocabWord _update(String id, VocabWord Function(VocabWord) change) {
    final i = _words.indexWhere((w) => w.id == id);
    final updated = change(_words[i]);
    _words[i] = updated;
    notifyListeners();
    return updated;
  }
}
