import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

import '../../models/practice_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/chevron_row.dart';
import '../../widgets/segmented_tabs.dart';
import 'choice_exercise_screen.dart';

enum _Shelf {
  open('Meine Übungen'),
  done('Fertig');

  const _Shelf(this.label);

  final String label;
}

/// A practice library: title, "Meine Übungen" / "Fertig", then one row per
/// exercise. Solving an exercise moves it to "Fertig".
class PracticeLibraryScreen extends StatefulWidget {
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

  @override
  State<PracticeLibraryScreen> createState() => _PracticeLibraryScreenState();
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

class _PracticeLibraryScreenState extends State<PracticeLibraryScreen> {
  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  _Shelf _shelf = _Shelf.open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.progress,
          builder: (context, _) {
            final done = [
              for (final e in widget.exercises)
                if (widget.progress.isDone(e.id)) e,
            ];
            final shown = _shelf == _Shelf.done
                ? done
                : [
                    for (final e in widget.exercises)
                      if (!widget.progress.isDone(e.id)) e,
                  ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackBar(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 8),
                Padding(
                  padding: _gutter,
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.kind.title,
                      style: AppType.editorial(
                        color: context.appColors.textPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: _gutter,
                  child: Text(
                    '${widget.exercises.length} Übungen · '
                    '${done.length} fertig',
                    style: AppType.meta(color: context.appColors.textMuted),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: _gutter,
                  child: SegmentedTabs(
                    values: _Shelf.values,
                    labelOf: (shelf) => shelf.label,
                    selected: _shelf,
                    onChanged: (shelf) => setState(() => _shelf = shelf),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: shown.isEmpty
                      ? Padding(
                          padding: _gutter.copyWith(top: 16),
                          child: Text(
                            _shelf == _Shelf.done
                                ? 'Noch keine Übung abgeschlossen.'
                                : 'Alles erledigt. Unter „Fertig“ kannst du '
                                      'jede Übung wiederholen.',
                            style: AppType.chrome(
                              color: context.appColors.textMuted,
                            ),
                          ),
                        )
                      : ListView(
                          key: ValueKey(_shelf),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          children: [
                            for (final exercise in shown)
                              ChevronRow(
                                title: exercise.title,
                                summary: exercise.summary,
                                meta: exercise.meta,
                                onTap: () => ChoiceExerciseScreen.open(
                                  context,
                                  exercise: exercise,
                                  queue: widget.exercises,
                                  progress: widget.progress,
                                ),
                              ),
                          ],
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
