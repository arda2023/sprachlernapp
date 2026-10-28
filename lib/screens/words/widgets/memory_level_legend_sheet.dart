import 'package:flutter/cupertino.dart';

import '../../../domain/leitner.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import 'memory_level_indicator.dart';

/// Explains the five memory levels, as the orange popover pointing at the
/// tapped dashes. The [current] level (the tapped word's) is marked in
/// text, not color.
class MemoryLevelLegendSheet extends StatelessWidget {
  const MemoryLevelLegendSheet({super.key, this.current});

  final int? current;

  /// [context] is the tapped level; the arrow points there.
  static Future<void> show(BuildContext context, {int? current}) =>
      showAnchoredPopover<void>(
        anchorContext: context,
        color: context.appColors.popover,
        builder: (_) => MemoryLevelLegendSheet(current: current),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PopoverTitle('Erinnerungsstufen'),
        const SizedBox(height: 6),
        Text(
          'Jede richtige Wiederholung hebt ein Wort eine Stufe höher. '
          'Ein Fehler setzt es auf Stufe 1 zurück.',
          style: AppType.chrome(
            color: popoverInk.withValues(alpha: 0.9),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        for (var level = 1; level <= leitnerBoxCount; level++)
          _LegendRow(level: level, isCurrent: level == current),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.level, required this.isCurrent});

  final int level;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final title = memoryLevelTitle(level);
    final detail = memoryLevelDetail(level);
    return Semantics(
      label:
          'Stufe $level von $leitnerBoxCount: $title. $detail'
          '${isCurrent ? '. Dieses Wort' : ''}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: popoverInk.withValues(alpha: 0.25)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: MemoryLevelIndicator.widthFor(14),
              child: MemoryLevelIndicator(
                level: level,
                litColor: popoverInk,
                offColor: popoverInk.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.chrome(
                      color: popoverInk,
                      weight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppType.meta(
                      color: popoverInk.withValues(alpha: 0.85),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: popoverInk,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Dieses Wort',
                        style: AppType.meta(color: context.appColors.popover),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
