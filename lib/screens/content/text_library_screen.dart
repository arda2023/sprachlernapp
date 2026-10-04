import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/exercise_models.dart';
import '../../models/reading_history.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/section_heading.dart';
import '../home/widgets/story_carousel.dart';
import 'text_exercise_screen.dart';
import 'widgets/exercise_choice_sheet.dart';

/// Exercise texts as carousels: first those built from stories the learner
/// has opened, then by level.
class TextLibraryScreen extends StatelessWidget {
  const TextLibraryScreen({
    super.key,
    required this.texts,
    required this.history,
  });

  final List<ExerciseText> texts;
  final ReadingHistory history;

  static Future<void> open(
    BuildContext context, {
    required List<ExerciseText> texts,
    required ReadingHistory history,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => TextLibraryScreen(texts: texts, history: history),
    ),
  );

  Future<void> _choose(BuildContext context, String id) async {
    final text = texts.firstWhere((t) => t.id == id);
    final mode = await ExerciseChoiceSheet.show(context, text);
    if (mode != null && context.mounted) {
      await TextExerciseScreen.open(context, text, mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: ListenableBuilder(
                  listenable: history,
                  builder: (context, _) {
                    final read = history.storyIds;
                    final fromStories = [
                      for (final t in texts)
                        if (read.contains(t.sourceStoryId)) t,
                    ];
                    final sections = <(String, List<ExerciseText>)>[
                      if (fromStories.isNotEmpty)
                        ('Aus deinen Stories', fromStories),
                      (
                        'Einstieg · A1–A2',
                        [
                          for (final t in texts)
                            if (t.info.level.startsWith('A')) t,
                        ],
                      ),
                      (
                        'Weiter · B1–B2',
                        [
                          for (final t in texts)
                            if (t.info.level.startsWith('B')) t,
                        ],
                      ),
                    ];
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(top: 8, bottom: 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Texte',
                              style: AppType.editorial(
                                color: context.appColors.textPrimary,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Lückentexte zum Lesen und Üben',
                            style: AppType.meta(
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ),
                        for (final (title, group) in sections)
                          if (group.isNotEmpty) ...[
                            const SizedBox(height: 44),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: SectionHeading(
                                title: title,
                                trailing: Text(
                                  '${group.length}',
                                  style: AppType.meta(
                                    color: context.appColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            StoryCarousel(
                              stories: [for (final t in group) t.info],
                              onOpen: (s) => _choose(context, s.id),
                            ),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
