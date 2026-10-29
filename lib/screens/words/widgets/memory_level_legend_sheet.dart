import 'package:flutter/cupertino.dart';

import '../../../domain/leitner.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';
import 'memory_level_indicator.dart';

/// Explains the five memory levels, as the orange popover pointing at the
/// tapped dashes. The [current] level (the tapped word's) sits on a soft
/// white band; screen readers hear it as "aktuelle Stufe".
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
          '${isCurrent ? '. Aktuelle Stufe' : ''}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: popoverInk.withValues(alpha: 0.25)),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The band reaches into the popover's padding, so the dashes
            // stay aligned with the heading.
            if (isCurrent)
              Positioned(
                left: -10,
                right: -10,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x29FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(detail, style: PopoverText.caption()),
                      ],
                    ),
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
