import 'package:flutter/cupertino.dart';

import '../../../models/exercise_models.dart';
import '../../../models/story_category.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_content_gate.dart';
import '../../../widgets/press_scale.dart';

/// Compact numbered text exercises. Category colours replace cover imagery;
/// the three-row columns grow with the learner's text size.
class TextExerciseShelf extends StatelessWidget {
  const TextExerciseShelf({
    super.key,
    required this.texts,
    required this.onOpen,
    this.premiumLocked = false,
    this.onUpgrade,
  });

  final List<ExerciseText> texts;
  final void Function(ExerciseText text, BuildContext anchor) onOpen;
  final bool premiumLocked;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final width = texts.length <= 3 ? screen - 40 : (screen - 40) * 0.9;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < texts.length; i += 3) ...[
              if (i > 0) const SizedBox(width: 14),
              SizedBox(
                width: width,
                child: Column(
                  children: [
                    for (final (offset, text) in texts.skip(i).take(3).indexed)
                      Padding(
                        padding: EdgeInsets.only(top: offset == 0 ? 0 : 10),
                        child: TextExerciseRow(
                          text: text,
                          rank: i + offset + 1,
                          premiumLocked: premiumLocked,
                          onUpgrade: onUpgrade,
                          onOpen: onOpen,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TextExerciseRow extends StatelessWidget {
  const TextExerciseRow({
    super.key,
    required this.text,
    required this.rank,
    required this.onOpen,
    this.premiumLocked = false,
    this.onUpgrade,
  });

  final ExerciseText text;
  final int rank;
  final void Function(ExerciseText text, BuildContext anchor) onOpen;
  final bool premiumLocked;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final category = StoryCategory.of(text.info.topic);
    return MergeSemantics(
      child: PressScale(
        child: CupertinoButton(
          onPressed: premiumLocked ? onUpgrade : () => onOpen(text, context),
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label:
                '${text.info.title}. ${text.info.topic}, Niveau ${text.info.level}'
                '${premiumLocked ? ', mit Premium freischalten' : ', Text üben'}',
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color.lerp(category.color, colors.raisedInk, 0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '$rank',
                      style: AppType.editorial(
                        size: 20,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.info.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.editorial(
                            size: 17,
                            height: 1.2,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text.info.topic,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.meta(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (premiumLocked) ...[
                    const SizedBox(width: 8),
                    const PremiumLockBadge(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
