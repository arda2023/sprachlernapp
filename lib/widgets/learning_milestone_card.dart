import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/learning_milestone.dart';
import '../presentation/celebration_sounds.dart';
import '../theme/app_theme.dart';

class LearningMilestoneCard extends ConsumerStatefulWidget {
  const LearningMilestoneCard({
    super.key,
    required this.milestone,
    this.playSound = true,
  });

  final LearningMilestone milestone;

  /// The recap already plays the existing streak cues.
  final bool playSound;

  @override
  ConsumerState<LearningMilestoneCard> createState() =>
      _LearningMilestoneCardState();
}

class _LearningMilestoneCardState extends ConsumerState<LearningMilestoneCard> {
  @override
  void initState() {
    super.initState();
    if (!widget.playSound) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          TickerMode.valuesOf(context).enabled &&
          !MediaQuery.disableAnimationsOf(context) &&
          ModalRoute.of(context)?.isCurrent != false &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed)) {
        HapticFeedback.mediumImpact();
        ref.read(celebrationSoundsProvider).check();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (title, detail, icon) = switch (widget.milestone) {
      LearningMilestone.firstStory => (
        'Deine erste Story!',
        'Du hast sie bis zum Ende gelesen.',
        CupertinoIcons.book_fill,
      ),
      LearningMilestone.firstTopicPractice => (
        'Dein Thema, dein Wortschatz',
        'Du hast ein Wort aus deinem eigenen Thema geübt.',
        CupertinoIcons.text_badge_checkmark,
      ),
      LearningMilestone.firstMasteredWord => (
        'Dein erstes gemeistertes Wort',
        'Ein Wort hat die höchste Erinnerungsstufe erreicht.',
        CupertinoIcons.checkmark_seal_fill,
      ),
    };
    final colors = context.appColors;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.successTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: const Cubic(0.23, 1, 0.32, 1),
                builder: (context, value, child) => Transform.scale(
                  scale: reducedMotion ? 1 : 0.9 + 0.1 * value,
                  child: Opacity(
                    opacity: reducedMotion ? 1 : value,
                    child: child,
                  ),
                ),
                child: Icon(icon, size: 26, color: colors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppType.editorial(
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppType.chrome(size: 15, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
