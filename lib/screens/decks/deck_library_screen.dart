import 'package:flutter/cupertino.dart';

import '../../models/deck_store.dart';
import '../../models/home_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_heading.dart';
import '../home/widgets/deck_tile.dart';

/// All decks, active first. Serves as the "Inhalte" tab and the target of
/// "Mehr ansehen" on Home.
class DeckLibraryScreen extends StatelessWidget {
  const DeckLibraryScreen({
    super.key,
    required this.decks,
    required this.onOpenDeck,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final DeckStore decks;
  final ValueChanged<Deck> onOpenDeck;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: decks,
        builder: (context, _) {
          final active = decks.active;
          final others = decks.inactive;
          List<Widget> section(String title, List<Deck> group) => [
            const SizedBox(height: 44),
            Padding(
              padding: _gutter,
              child: SectionHeading(
                title: title,
                trailing: Text('${group.length}', style: AppType.meta()),
              ),
            ),
            const SizedBox(height: 14),
            for (final (i, deck) in group.indexed)
              Padding(
                padding: _gutter.copyWith(top: i == 0 ? 0 : 12),
                child: DeckTile(deck: deck, onTap: () => onOpenDeck(deck)),
              ),
          ];

          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              Padding(
                padding: _gutter,
                child: Semantics(
                  header: true,
                  child: Text('Stapel', style: AppType.editorial(size: 32)),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: _gutter,
                child: Text(
                  '${active.length} aktiv · ${decks.decks.length} Stapel',
                  style: AppType.meta(),
                ),
              ),
              if (active.isNotEmpty) ...section('Aktiv', active),
              if (others.isNotEmpty) ...section('Weitere Stapel', others),
            ],
          );
        },
      ),
    );
  }
}
