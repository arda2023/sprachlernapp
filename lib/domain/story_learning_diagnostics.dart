import 'story_learning.dart';

/// UI routing key only: this is never a content-pack deck.
const storyCollectionId = 'personal:stories';

enum StoryLearningStep {
  context('STORY_LOAD_01', 'Storydaten laden'),
  status('STORY_STATUS_01', 'Lernstatus laden'),
  save('STORY_SAVE_01', 'Wort speichern'),
  reactivate('STORY_REACTIVATE_01', 'Wort reaktivieren'),
  collection('STORY_COLLECTION_01', 'Sammlung laden');

  const StoryLearningStep(this.code, this.label);
  final String code, label;
}

class StoryLearningFailure implements Exception {
  const StoryLearningFailure(this.step);
  final StoryLearningStep step;
  String get message =>
      '${step.label} nicht möglich. Bitte erneut versuchen. (${step.code})';
  @override
  String toString() => '${step.code}: ${step.label}';
}

/// Presentation classification supplements, but never relaxes, validation.
enum StoryLearningAvailability {
  existingCard,
  approvedContext,
  missingAnnotation,
  missingContext,
  deferred,
  invalidReference,
}

StoryLearningAvailability storyAvailability(StoryLearningCandidate c) {
  if (c.retired) return StoryLearningAvailability.deferred;
  if (!c.token.annotated) return StoryLearningAvailability.missingAnnotation;
  if (c.validationProblem(needsContext: false) != null) {
    return StoryLearningAvailability.invalidReference;
  }
  if (c.card != null) return StoryLearningAvailability.existingCard;
  return c.validationProblem() == null
      ? StoryLearningAvailability.approvedContext
      : StoryLearningAvailability.missingContext;
}
