import 'package:flutter/foundation.dart';

import 'home_models.dart';

/// In-memory deck state until Riverpod and Drift arrive. Home, the deck
/// library and deck details all listen to the same store, so toggling
/// "Stapel lernen" updates every screen.
class DeckStore extends ChangeNotifier {
  DeckStore(List<Deck> decks) : _decks = List.of(decks);

  final List<Deck> _decks;

  List<Deck> get decks => List.unmodifiable(_decks);

  List<Deck> get active => _decks.where((d) => d.isActive).toList();

  List<Deck> get inactive => _decks.where((d) => !d.isActive).toList();

  /// Home shows only active decks, at most [limit]. Inactive decks, even
  /// started ones, live in the deck library ("Mehr ansehen").
  List<Deck> homeDecks({int limit = 3}) => active.take(limit).toList();

  Deck byId(String id) => _decks.firstWhere((d) => d.id == id);

  void setActive(String id, bool isActive) {
    final i = _decks.indexWhere((d) => d.id == id);
    if (i < 0 || _decks[i].isActive == isActive) return;
    _decks[i] = _decks[i].copyWith(isActive: isActive);
    notifyListeners();
  }
}
