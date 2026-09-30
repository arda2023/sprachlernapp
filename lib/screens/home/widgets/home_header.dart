import 'package:flutter/widgets.dart';

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

  /// Understated Streak Rule: neutral hairline pill, no flame, no ink.
  @override
  Widget build(BuildContext context) {
    final unit = days == 1 ? 'Tag' : 'Tage';
    return Semantics(
      container: true,
      label: '$days $unit Lernserie',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$days',
                style: AppType.chrome(
                  size: 16,
                  weight: FontWeight.w700,
                  tabular: true,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: AppType.chrome(
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
