import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

import '../../models/practice_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/chevron_row.dart';
import 'choice_exercise_screen.dart';

/// A practice library ("Mehr anzeigen" on the Inhalte tab): title, then
/// every exercise in content order. Solved ones carry a green check.
class PracticeLibraryScreen extends StatelessWidget {
  const PracticeLibraryScreen({
    super.key,
    required this.kind,
    required this.exercises,
    required this.progress,
  });

  final PracticeKind kind;
  final List<ChoiceExercise> exercises;
  final PracticeProgress progress;

  static Future<void> open(
    BuildContext context, {
    required PracticeKind kind,
    required List<ChoiceExercise> exercises,
    required PracticeProgress progress,
  }) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => switch (kind) {
        PracticeKind.listening => ListeningLibraryScreen(
          exercises: exercises,
          progress: progress,
        ),
        PracticeKind.grammar => GrammarLibraryScreen(
          exercises: exercises,
          progress: progress,
        ),
      },
    ),
  );

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: progress,
          builder: (context, _) {
            return ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                BackBar(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 8),
                Padding(
                  padding: _gutter,
                  child: Semantics(
                    header: true,
                    child: Text(
                      kind.title,
                      style: AppType.editorial(
                        color: context.appColors.textPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final exercise in exercises)
                  Padding(
                    padding: _gutter,
                    child: ChevronRow(
                      title: exercise.title,
                      summary: exercise.summary,
                      meta: exercise.meta,
                      done: progress.isDone(exercise.id),
                      onTap: () => ChoiceExerciseScreen.open(
                        context,
                        exercise: exercise,
                        queue: exercises,
                        progress: progress,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The "Hören" library.
class ListeningLibraryScreen extends PracticeLibraryScreen {
  const ListeningLibraryScreen({
    super.key,
    required super.exercises,
    required super.progress,
  }) : super(kind: PracticeKind.listening);
}

/// The "Grammatik" library.
class GrammarLibraryScreen extends PracticeLibraryScreen {
  const GrammarLibraryScreen({
    super.key,
    required super.exercises,
    required super.progress,
  }) : super(kind: PracticeKind.grammar);
}
