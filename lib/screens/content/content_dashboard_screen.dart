import 'package:flutter/cupertino.dart';

import '../../models/deck_store.dart';
import '../../models/home_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_heading.dart';
import '../home/widgets/deck_tile.dart';

/// One practice category on the dashboard. [onOpen] null means the category
/// isn't built yet ("Bald verfügbar").
class ContentCategory {
  const ContentCategory({
    required this.title,
    required this.icon,
    this.detail,
    this.onOpen,
  });

  final String title;
  final IconData icon;
  final String? detail;
  final VoidCallback? onOpen;
}

/// The "Inhalte" tab: decks on top, then a grid of practice categories.
class ContentDashboardScreen extends StatelessWidget {
  const ContentDashboardScreen({
    super.key,
    required this.decks,
    required this.categories,
    required this.onOpenDeck,
    required this.onBrowseDecks,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final DeckStore decks;
  final List<ContentCategory> categories;
  final ValueChanged<Deck> onOpenDeck;
  final VoidCallback onBrowseDecks;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: decks,
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            Padding(
              padding: _gutter,
              child: Semantics(
                header: true,
                child: Text('Inhalte', style: AppType.editorial(size: 32)),
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: _gutter,
              child: SectionHeading(title: 'Stapel'),
            ),
            const SizedBox(height: 14),
            for (final deck in decks.active.take(2))
              Padding(
                padding: _gutter.copyWith(bottom: 12),
                child: DeckTile(deck: deck, onTap: () => onOpenDeck(deck)),
              ),
            Padding(
              padding: _gutter,
              child: _AllDecksRow(
                count: decks.decks.length,
                active: decks.active.length,
                onTap: onBrowseDecks,
              ),
            ),
            const SizedBox(height: 44),
            const Padding(
              padding: _gutter,
              child: SectionHeading(title: 'Üben'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: _gutter,
              child: _CategoryGrid(categories: categories),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDecksRow extends StatelessWidget {
  const _AllDecksRow({
    required this.count,
    required this.active,
    required this.onTap,
  });

  final int count;
  final int active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 52),
        child: Semantics(
          label: 'Alle Stapel, $count Stapel, $active aktiv',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.raisedInk,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Alle Stapel',
                    style: AppType.chrome(weight: FontWeight.w600),
                  ),
                ),
                Text('$count', style: AppType.meta()),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two columns; rows size to their tallest card, so large Dynamic Type grows
/// the cards instead of clipping them.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<ContentCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < categories.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _CategoryCard(category: categories[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < categories.length
                        ? _CategoryCard(category: categories[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ContentCategory category;

  @override
  Widget build(BuildContext context) {
    final available = category.onOpen != null;
    final detail = available ? category.detail ?? '' : 'Bald verfügbar';
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: category.onOpen,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: '${category.title}, $detail',
          enabled: available,
          excludeSemantics: true,
          child: Container(
            // Fill the grid column; the button would otherwise shrink-wrap.
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.raisedInk,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  category.icon,
                  size: 28,
                  color: available ? AppColors.textPrimary : AppColors.iconOff,
                ),
                const Spacer(),
                const SizedBox(height: 16),
                Text(
                  category.title,
                  style: AppType.chrome(
                    size: 17,
                    weight: FontWeight.w600,
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: AppType.meta()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
