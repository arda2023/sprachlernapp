import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/home_models.dart';
import '../theme/app_theme.dart';
import 'progress_ring.dart';

enum AppTab {
  home('Home', CupertinoIcons.house, CupertinoIcons.house_fill),
  stories('Stories', CupertinoIcons.book, CupertinoIcons.book_fill),
  words(
    'Wortliste',
    CupertinoIcons.square_list,
    CupertinoIcons.square_list_fill,
  ),
  content(
    'Inhalte',
    CupertinoIcons.square_stack_3d_up,
    CupertinoIcons.square_stack_3d_up_fill,
  );

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Notched bar: the [PracticeButton] docks into the notch as the Scaffold's
/// centerDocked floating action button; this bar only carries the tabs and
/// the "Lernen" label beneath the button.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.onTabSelected,
    required this.onStartPractice,
  });

  static const height = 64.0;

  /// Width of the center slot under the practice button.
  static const _centerSlot = 88.0;

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
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: height,
        padding: EdgeInsets.zero,
        color: context.appColors.raisedInk,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        child: Row(
          children: [
            tab(AppTab.home),
            tab(AppTab.stories),
            SizedBox(
              width: _centerSlot,
              // The button above carries the semantics; this label is a
              // visual caption and an extra tap area.
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onStartPractice,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Lernen',
                        maxLines: 1,
                        style: AppType.chrome(
                          size: 11,
                          weight: FontWeight.w600,
                          color: context.appColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            tab(AppTab.words),
            tab(AppTab.content),
          ],
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
    final color = selected
        ? context.appColors.textPrimary
        : context.appColors.textMuted;
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

/// The central "Lernen" button: a neutral floating action button inside a
/// ring that shows the daily goal (Neutral Chrome + Neutral Progress Rules).
class PracticeButton extends StatelessWidget {
  const PracticeButton({
    super.key,
    required this.goal,
    required this.onPressed,
  });

  static const ringSize = 72.0;

  final DailyGoal goal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      color: context.appColors.textMuted,
      fraction: goal.done / goal.target,
      size: ringSize,
      child: MergeSemantics(
        child: Semantics(
          label: 'Lernen, Tagesziel ${goal.done} von ${goal.target} Wörtern',
          child: FloatingActionButton(
            onPressed: onPressed,
            heroTag: null,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            backgroundColor: context.appColors.raisedInk,
            foregroundColor: context.appColors.textPrimary,
            splashColor: Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: context.appColors.hairline),
            ),
            child: const Icon(CupertinoIcons.play_fill, size: 22),
          ),
        ),
      ),
    );
  }
}
