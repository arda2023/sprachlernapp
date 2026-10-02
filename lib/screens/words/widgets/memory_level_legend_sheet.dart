import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../../../domain/leitner.dart';
import '../../../theme/app_theme.dart';
import 'memory_level_indicator.dart';

/// Explains the five memory levels. The [current] level (the tapped word's)
/// is marked in text, not color.
class MemoryLevelLegendSheet extends StatelessWidget {
  const MemoryLevelLegendSheet({super.key, this.current});

  final int? current;

  static Future<void> show(BuildContext context, {int? current}) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => MemoryLevelLegendSheet(current: current),
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
              child: Text(
                'Erinnerungsstufen',
                style: AppType.editorial(size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jede richtige Wiederholung hebt ein Wort eine Stufe höher. '
              'Ein Fehler setzt es auf Stufe 1 zurück.',
              style: AppType.chrome(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (var level = 1; level <= leitnerBoxCount; level++)
              _LegendRow(level: level, isCurrent: level == current),
          ],
        ),
      ),
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
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: MemoryLevelIndicator.widthFor(14),
              child: MemoryLevelIndicator(level: level),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.chrome(
                      weight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: AppType.meta()),
                  if (isCurrent) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Dieses Wort',
                      style: AppType.meta(color: AppColors.textPrimary),
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
