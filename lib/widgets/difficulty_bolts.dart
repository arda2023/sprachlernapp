import 'package:flutter/cupertino.dart';

import '../models/home_models.dart';
import '../theme/app_theme.dart';

/// Difficulty Bolt Rule: three bolts, lit in textPrimary, unlit in iconOff.
/// Always paired with the level name; here as a semantics label.
class DifficultyBolts extends StatelessWidget {
  const DifficultyBolts({
    super.key,
    required this.difficulty,
    this.color,
    this.offColor,
    this.size = 14,
  });

  final DeckDifficulty difficulty;

  /// Overrides for coloured backgrounds (lit / unlit bolts).
  final Color? color;
  final Color? offColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Schwierigkeit ${difficulty.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 3; i++)
            Icon(
              CupertinoIcons.bolt_fill,
              size: size,
              color: i <= difficulty.bolts
                  ? color ?? context.appColors.textPrimary
                  : offColor ?? context.appColors.iconOff,
            ),
        ],
      ),
    );
  }
}
