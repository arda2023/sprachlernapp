import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/count_format.dart';
import '../../../widgets/difficulty_bolts.dart';
import '../../../widgets/progress_ring.dart';

/// The deck's icon inside a progress gauge like the Play button's: open at
/// the bottom, filling clockwise from the lower left with the share of the
/// deck's exercises already practised.
class DeckGauge extends StatelessWidget {
  const DeckGauge({
    super.key,
    required this.deck,
    this.size = 52,
    this.onAccent = false,
  });

  final Deck deck;
  final double size;

  /// On an orange card: white arc and icon on a translucent track.
  final bool onAccent;

  static double fractionOf(Deck deck) =>
      deck.totalWords == 0 ? 0 : deck.seenWords / deck.totalWords;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    return ExcludeSemantics(
      child: ProgressRing(
        fraction: fractionOf(deck),
        size: size,
        strokeWidth: size > 60 ? 5 : 4,
        gapDegrees: 110,
        color: onAccent ? white : colors.active,
        trackColor: onAccent ? white.withValues(alpha: 0.3) : null,
        child: Icon(
          deck.icon,
          size: size * 0.42,
          color: onAccent ? white : colors.textPrimary,
        ),
      ),
    );
  }
}

/// Deck card: gauge with icon on the left, name, difficulty bolts and word
/// count. In the deck library active decks are filled orange (with an
/// "Aktiv" label, so colour is never the only cue); on Home, where every
/// deck shown is active, cards stay neutral ([highlightActive] false).
class DeckTile extends StatelessWidget {
  const DeckTile({
    super.key,
    required this.deck,
    required this.onTap,
    this.highlightActive = true,
  });

  final Deck deck;
  final VoidCallback onTap;
  final bool highlightActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    final practised = (DeckGauge.fractionOf(deck) * 100).round();
    final active = deck.isActive;
    final accent = active && highlightActive;
    return MergeSemantics(
      // Cards sink slightly under the finger (press feedback).
      child: PressScale(
        child: CupertinoButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          pressedOpacity: 0.9,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label:
                '${deck.name}, $practised Prozent geübt, '
                'Schwierigkeit ${deck.difficulty.label}, '
                '${formatCountDe(deck.totalWords)} Wörter'
                '${active ? ', aktiv' : ''}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              decoration: BoxDecoration(
                color: accent ? colors.popover : colors.raisedInk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  DeckGauge(deck: deck, onAccent: accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.chrome(
                            color: accent ? white : colors.textPrimary,
                            size: 17,
                            weight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            DifficultyBolts(
                              difficulty: deck.difficulty,
                              size: 13,
                              color: accent ? white : null,
                              offColor: accent
                                  ? white.withValues(alpha: 0.35)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${formatCountDe(deck.totalWords)} Wörter',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.meta(
                                  color: accent
                                      ? white.withValues(alpha: 0.85)
                                      : colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (accent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Aktiv', style: AppType.meta(color: white)),
                    )
                  else
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: colors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
