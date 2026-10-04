import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';

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

/// The "Inhalte" tab: the practice categories as a two-column grid. Decks
/// live on Home and in the deck library.
class ContentDashboardScreen extends StatelessWidget {
  const ContentDashboardScreen({super.key, required this.categories});

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  final List<ContentCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          Padding(
            padding: _gutter,
            child: Semantics(
              header: true,
              child: Text(
                'Inhalte',
                style: AppType.editorial(
                  color: context.appColors.textPrimary,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: _gutter,
            child: _CategoryGrid(categories: categories),
          ),
        ],
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
              color: context.appColors.raisedInk,
              border: Border.all(color: context.appColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  category.icon,
                  size: 28,
                  color: available
                      ? context.appColors.textPrimary
                      : context.appColors.iconOff,
                ),
                const Spacer(),
                const SizedBox(height: 16),
                Text(
                  category.title,
                  style: AppType.chrome(
                    size: 17,
                    weight: FontWeight.w600,
                    color: available
                        ? context.appColors.textPrimary
                        : context.appColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppType.meta(color: context.appColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
