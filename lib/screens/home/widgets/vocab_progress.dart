import 'package:flutter/widgets.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';

String formatCountDe(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// Word counts are marked with an ink underline rather than colored text:
/// mastered violet on the dark ground is too low-contrast (~2.7:1) to carry text.
class VocabProgress extends StatelessWidget {
  const VocabProgress({super.key, required this.stats});

  final VocabStats stats;

  @override
  Widget build(BuildContext context) {
    final activated = formatCountDe(stats.activated);
    final mastered = formatCountDe(stats.mastered);
    final total = formatCountDe(stats.total);

    return Semantics(
      container: true,
      label:
          '$activated der relevantesten $total Wörter aktiviert, davon $mastered gemeistert',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: AppType.chrome(
                size: 22,
                weight: FontWeight.w600,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: activated,
                  style: AppType.chrome(
                    size: 22,
                    weight: FontWeight.w700,
                    height: 1.3,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.active,
                  ),
                ),
                TextSpan(text: ' der relevantesten $total Wörter aktiviert'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppType.chrome(size: 15, color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: mastered,
                  style: AppType.chrome(
                    size: 15,
                    weight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.mastered,
                  ),
                ),
                const TextSpan(text: ' gemeistert'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SegmentedTrack(stats: stats),
        ],
      ),
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({required this.stats});

  final VocabStats stats;

  @override
  Widget build(BuildContext context) {
    final remaining = stats.total - stats.activated;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: AppColors.hairline,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stats.mastered > 0)
                Expanded(
                  flex: stats.mastered,
                  child: const ColoredBox(color: AppColors.mastered),
                ),
              if (stats.inPractice > 0)
                Expanded(
                  flex: stats.inPractice,
                  child: const ColoredBox(color: AppColors.active),
                ),
              if (remaining > 0)
                Expanded(flex: remaining, child: const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
