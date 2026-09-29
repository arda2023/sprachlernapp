import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.levelLabel,
    required this.streakDays,
  });

  final String levelLabel;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LevelChip(label: levelLabel),
        const Spacer(),
        _StreakBadge(days: streakDays),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppType.chrome(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$days Tage Lernserie',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: AppColors.raisedInk,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.flame_fill,
              size: 18,
              color: AppColors.active,
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$days',
                    style: AppType.chrome(size: 16, weight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' Tage',
                    style: AppType.chrome(size: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
