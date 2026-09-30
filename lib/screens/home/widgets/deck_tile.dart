import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/difficulty_bolts.dart';
import '../../../widgets/progress_ring.dart';

/// Deck card: icon inside a mastery ring, title, "[X]% gemeistert" and the
/// difficulty bolts. Active decks carry Field Orange (Active Deck Rule) plus
/// an "Aktiv" label, so color is never the only cue.
class DeckTile extends StatelessWidget {
  const DeckTile({super.key, required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (deck.masteredFraction * 100).round();
    final active = deck.isActive;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '${deck.name}, $percent Prozent gemeistert, '
              'Schwierigkeit ${deck.difficulty.label}'
              '${active ? ', aktiv' : ''}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: active ? AppColors.activeTint : AppColors.raisedInk,
              border: Border.all(
                color: active ? AppColors.active : AppColors.hairline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ProgressRing(
                  fraction: deck.masteredFraction,
                  size: 52,
                  color: AppColors.mastered,
                  child: Icon(
                    deck.icon,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: AppType.chrome(
                          size: 17,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$percent% gemeistert',
                        style: AppType.chrome(
                          size: 13,
                          color: AppColors.textMuted,
                          tabular: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DifficultyBolts(difficulty: deck.difficulty),
                    ],
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Aktiv',
                    style: AppType.meta(color: AppColors.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
