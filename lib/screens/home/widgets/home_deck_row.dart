import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import 'deck_tile.dart';

/// An active deck on Home: the deck card with its progress gauge and
/// difficulty bolts, kept neutral because every deck on Home is active.
class HomeDeckRow extends StatelessWidget {
  const HomeDeckRow({super.key, required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      DeckTile(deck: deck, onTap: onTap, highlightActive: false);
}
