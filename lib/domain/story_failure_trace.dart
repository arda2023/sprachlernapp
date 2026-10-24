import 'story_learning_diagnostics.dart';

/// No error message, SQL, arguments, user IDs or arbitrary stack lines escape.
String storyFailureTrace(
  StoryLearningStep step,
  Object error,
  StackTrace stack,
) {
  final type = error.runtimeType.toString();
  final safeType = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(type)
      ? type
      : 'UnknownError';
  final frames = RegExp(r'package:sprachapp/[a-zA-Z0-9_/]+\.dart:[0-9]+:[0-9]+')
      .allMatches(stack.toString())
      .take(3)
      .map((m) => m.group(0)!)
      .join(' <- ');
  return '${step.code} type=$safeType source=${frames.isEmpty ? 'unavailable' : frames}';
}
