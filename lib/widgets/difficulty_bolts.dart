import 'package:flutter/cupertino.dart';

import '../models/home_models.dart';
import '../theme/app_theme.dart';

/// Difficulty Bolt Rule: three bolts, lit in textPrimary, unlit in iconOff.
/// Always paired with the level name; here as a semantics label.
class DifficultyBolts extends StatelessWidget {
  const DifficultyBolts({super.key, required this.difficulty});

  final DeckDifficulty difficulty;

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
              size: 14,
              color: i <= difficulty.bolts
                  ? AppColors.textPrimary
                  : AppColors.iconOff,
            ),
        ],
      ),
    );
  }
}
