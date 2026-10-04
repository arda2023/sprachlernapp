import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:flutter/foundation.dart';

import 'package:sprachapp/domain/leitner.dart';
import 'package:sprachapp/models/word_list_models.dart';

/// In-memory presentation fixture; never imported by the app.
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

  /// Applies one practice answer: the Leitner rule moves the box, the word
  /// counts as seen [now]. Returns the new box.
  // TODO: append to the review log instead once the Drift layer exists.
  int recordReview(
    String id, {
    required bool correct,
    required DateTime now,
    bool early = false,
  }) => _update(
    id,
    (w) => w.copyWith(
      box: nextLeitnerBox(w.box, correct: correct, early: early),
      lastSeenAt: now,
      reviewCount: w.reviewCount + 1,
    ),
  ).box;

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

class FixtureWordActions extends WordActions {
  FixtureWordActions(super.ref, this.store);
  final WordListStore store;
  @override
  Future<void> save(
    String id, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  }) async {
    if (favorite != null && store.byId(id).isFavorite != favorite) {
      store.toggleFavorite(id);
    }
    if (disabled != null && store.byId(id).isDisabled != disabled) {
      store.toggleDisabled(id);
    }
    if (inPlaylist != null && store.byId(id).inPlaylist != inPlaylist) {
      store.togglePlaylist(id);
    }
    if (note != null) store.setNote(id, note);
  }
}
