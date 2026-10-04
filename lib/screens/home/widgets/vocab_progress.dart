import 'package:flutter/widgets.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';

String formatCountDe(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// The four derived vocabulary categories. Counts are marked with an ink
/// underline rather than colored text: mastered violet on the dark ground is
/// too low-contrast (~2.7:1) to carry text. Due and unseen stay neutral.
class VocabProgress extends StatelessWidget {
  const VocabProgress({super.key, required this.breakdown});

  final VocabBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final due = formatCountDe(b.due);
    return Semantics(
      container: true,
      label:
          '$due ${b.due == 1 ? 'Wiederholung' : 'Wiederholungen'} verfügbar. '
          '${formatCountDe(b.building)} Wörter im Aufbau, '
          '${formatCountDe(b.mastered)} gemeistert, '
          '${formatCountDe(b.unseen)} noch nicht angezeigt',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Due reviews lead: the actionable number, deliberately neutral.
          Text.rich(
            TextSpan(
              style: AppType.chrome(
                color: context.appColors.textPrimary,
                size: 22,
                weight: FontWeight.w600,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: due,
                  style: AppType.chrome(
                    color: context.appColors.textPrimary,
                    size: 22,
                    weight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: b.due == 1
                      ? ' Wiederholung verfügbar'
                      : ' Wiederholungen verfügbar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SegmentedTrack(breakdown: b),
          const SizedBox(height: 12),
          _LedgerRow(
            label: 'Wörter im Aufbau',
            count: b.building,
            ink: context.appColors.active,
          ),
          _LedgerRow(
            label: 'Wörter gemeistert',
            count: b.mastered,
            ink: context.appColors.mastered,
          ),
          _LedgerRow(label: 'Noch nicht angezeigt', count: b.unseen),
        ],
      ),
    );
  }
}

/// Label left, count right; only mastered/active counts carry an ink underline.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.label, required this.count, this.ink});

  final String label;
  final int count;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppType.chrome(color: context.appColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCountDe(count),
            style: AppType.chrome(
              color: context.appColors.textPrimary,
              weight: FontWeight.w700,
              tabular: true,
              decoration: ink == null ? null : TextDecoration.underline,
              decorationColor: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({required this.breakdown});

  final VocabBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    // Due and unseen get no ink: they stay in the unfilled hairline groove.
    final neutral = b.due + b.unseen;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: context.appColors.hairline,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (b.mastered > 0)
                Expanded(
                  flex: b.mastered,
                  child: ColoredBox(color: context.appColors.mastered),
                ),
              if (b.building > 0)
                Expanded(
                  flex: b.building,
                  child: ColoredBox(color: context.appColors.active),
                ),
              if (neutral > 0) Expanded(flex: neutral, child: const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
