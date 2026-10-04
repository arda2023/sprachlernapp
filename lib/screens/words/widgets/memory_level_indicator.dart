import 'package:flutter/widgets.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../theme/app_theme.dart';

/// Names for the five memory levels (Leitner boxes 1–5).
const memoryLevelTitles = [
  'Neues Wort',
  'Wird vertraut',
  'Gut verankert',
  'Sicher im Gedächtnis',
  'Maximales Erinnerungsvermögen',
];

String memoryLevelTitle(int level) => memoryLevelTitles[level - 1];

/// "Wiederholung nach 14 Tagen"-style line, derived from the box interval.
String memoryLevelDetail(int level) {
  final interval = intervalLabel(leitnerInterval(level));
  final next = 'Nächste Wiederholung nach $interval';
  return level == leitnerBoxCount ? 'Gemeistert · $next' : next;
}

/// Memory Level Exception (DESIGN.md): five rounded dashes, the first
/// [level] lit in that level's color, the rest Hairline. Purely visual; the
/// caller supplies semantics.
class MemoryLevelIndicator extends StatelessWidget {
  const MemoryLevelIndicator({
    super.key,
    required this.level,
    this.dashWidth = 14,
  }) : assert(level >= 1 && level <= leitnerBoxCount);

  static const dashHeight = 4.0;
  static const gap = 3.0;

  final int level;
  final double dashWidth;

  static double widthFor(double dashWidth) =>
      leitnerBoxCount * dashWidth + (leitnerBoxCount - 1) * gap;

  @override
  Widget build(BuildContext context) {
    final lit = context.appColors.memoryLevel(level);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= leitnerBoxCount; i++)
            Container(
              width: dashWidth,
              height: dashHeight,
              margin: EdgeInsets.only(right: i < leitnerBoxCount ? gap : 0),
              decoration: BoxDecoration(
                color: i <= level ? lit : context.appColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }
}
