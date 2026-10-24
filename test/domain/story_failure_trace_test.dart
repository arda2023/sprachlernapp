import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/story_failure_trace.dart';
import 'package:sprachapp/domain/story_learning_diagnostics.dart';

void main() {
  test('diagnostics expose only class and package source locations', () {
    final trace = storyFailureTrace(
      StoryLearningStep.status,
      StateError('private text token=SECRET'),
      StackTrace.fromString(
        '#0 privateAccount (package:sprachapp/data/user/drift_user_repository.dart:41:7)\n'
        'SQL SELECT secret; https://private.invalid/?key=SECRET\n'
        '#1 other (/Users/private/file.dart:20:4)',
      ),
    );
    expect(
      trace,
      'STORY_STATUS_01 type=StateError source=package:sprachapp/data/user/drift_user_repository.dart:41:7',
    );
    expect(
      const StoryLearningFailure(StoryLearningStep.status).message,
      contains('(STORY_STATUS_01)'),
    );
  });
}
