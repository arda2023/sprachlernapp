import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

enum AppTab {
  home('Home', CupertinoIcons.house, CupertinoIcons.house_fill),
  stories('Stories', CupertinoIcons.book, CupertinoIcons.book_fill),
  words(
    'Wortliste',
    CupertinoIcons.square_list,
    CupertinoIcons.square_list_fill,
  ),
  profile('Profil', CupertinoIcons.person, CupertinoIcons.person_fill);

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.onTabSelected,
    required this.onStartPractice,
  });

  final AppTab current;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onStartPractice;

  @override
  Widget build(BuildContext context) {
    Widget tab(AppTab t) => Expanded(
      child: _TabItem(
        tab: t,
        selected: t == current,
        onTap: () => onTabSelected(t),
      ),
    );

    // Tab labels follow iOS: they don't grow with Dynamic Type beyond a small margin.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.raisedInk,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                tab(AppTab.home),
                tab(AppTab.stories),
                _PracticeButton(onPressed: onStartPractice),
                tab(AppTab.words),
                tab(AppTab.profile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 56),
        child: Semantics(
          selected: selected,
          label: tab.label,
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? tab.activeIcon : tab.icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                style: AppType.chrome(
                  size: 11,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeButton extends StatelessWidget {
  const _PracticeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: MergeSemantics(
        child: CupertinoButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          minimumSize: const Size(56, 56),
          child: Semantics(
            label: 'Tägliche Übung starten',
            excludeSemantics: true,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.mastered,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
