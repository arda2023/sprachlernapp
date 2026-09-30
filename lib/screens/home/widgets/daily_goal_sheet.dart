import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../../../theme/app_theme.dart';

/// Lets the learner pick a daily goal. The goal is a recommendation, never a
/// lockout (PRODUCT.md), and the copy says so.
class DailyGoalSheet extends StatelessWidget {
  const DailyGoalSheet({super.key, required this.current});

  static const options = [5, 10, 15, 20, 30];

  final int current;

  /// Returns the chosen target, or null when dismissed.
  static Future<int?> show(BuildContext context, {required int current}) =>
      showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DailyGoalSheet(current: current),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Tagesziel', style: AppType.editorial(size: 24)),
            ),
            const SizedBox(height: 6),
            Text(
              'Eine Empfehlung – du kannst jederzeit weiterlernen.',
              style: AppType.chrome(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (final target in options)
              _GoalOption(
                target: target,
                selected: target == current,
                onTap: () => Navigator.of(context).pop(target),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final int target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 52),
        child: Semantics(
          label: '$target Wörter pro Tag',
          selected: selected,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$target Wörter pro Tag',
                    style: AppType.chrome(
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      tabular: true,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    CupertinoIcons.checkmark,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
