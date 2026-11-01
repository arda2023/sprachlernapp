import 'practice_models.dart';

/// Stable partition: retain editorial order within both groups and never
/// mutate the shared content list. Reevaluate when progress notifies listeners.
List<ChoiceExercise> unfinishedPracticeFirst(
  Iterable<ChoiceExercise> exercises,
  PracticeProgress progress,
) {
  final open = <ChoiceExercise>[];
  final done = <ChoiceExercise>[];
  for (final exercise in exercises) {
    (progress.isDone(exercise.id) ? done : open).add(exercise);
  }
  return [...open, ...done];
}
