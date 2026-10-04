import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/story_learning.dart';
import '../../models/home_models.dart';
import '../../data/learning/practice_item_resolver.dart';
import 'database_providers.dart';
import 'deck_providers.dart';

final practiceResolverProvider = FutureProvider<PracticeItemResolver>((
  ref,
) async {
  ref.watch(userChangesProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  try {
    final content = await ref.watch(contentRepositoryProvider.future);
    return await PracticeItemResolver.load(user, content);
  } catch (error) {
    return PracticeItemResolver.load(user, null, contentError: error);
  }
}, retry: (_, _) => null);
final storySummariesProvider = FutureProvider<List<StorySummary>>((ref) async {
  final content = await ref.watch(contentRepositoryProvider.future);
  if (content is! StoryContentRepository) return [];
  return (content as StoryContentRepository).storySummaries();
}, retry: (_, _) => null);
final storyDocumentProvider = FutureProvider.family<StoryDocument, String>((
  ref,
  id,
) async {
  final content = await ref.watch(contentRepositoryProvider.future);
  if (content is! StoryContentRepository) {
    throw StateError('Keine annotierten Storydaten vorhanden.');
  }
  return (content as StoryContentRepository).storyDocument(id);
}, retry: (_, _) => null);
final storyLearningServiceProvider = Provider<StoryLearningService>(
  StoryLearningService.new,
);

class StoryLearningService {
  StoryLearningService(this.ref);
  final Ref ref;
  Future<StoryLearningCandidate> candidate(
    String story,
    String sentence,
    int token,
  ) async {
    final content = await ref.read(contentRepositoryProvider.future);
    if (content is! StoryContentRepository) {
      throw StateError('Story-Inhalt nicht verfügbar.');
    }
    return (content as StoryContentRepository).resolveStoryWord(
      story,
      sentence,
      token,
    );
  }

  Future<StoryAddResult> status(StoryLearningCandidate c) async {
    final user = await ref.read(userRepositoryProvider.future);
    if (user is! StoryLearningRepository) {
      return const StoryAddResult(StoryAddState.unavailable);
    }
    return (user as StoryLearningRepository).storyLearningStatus(c);
  }

  Future<StoryAddResult> add(StoryLearningCandidate old) async {
    final current = await candidate(
      old.storyId,
      old.sentence.id,
      old.token.index,
    );
    if (current.sourceFingerprint != old.sourceFingerprint) {
      throw StateError(
        'Der Story-Inhalt hat sich geändert. Bitte das Wort erneut öffnen.',
      );
    }
    final user = await ref.read(userRepositoryProvider.future);
    if (user is! StoryLearningRepository) {
      throw StateError('Lerndaten nicht verfügbar');
    }
    final result = await (user as StoryLearningRepository).addStoryWord(
      current,
      now: ref.read(clockProvider)(),
    );
    ref.invalidate(practiceResolverProvider);
    return result;
  }

  Future<StoryAddResult> reactivate(StoryLearningCandidate c) async {
    final current = await status(c);
    if (current.state != StoryAddState.disabled) return current;
    final user = await ref.read(userRepositoryProvider.future);
    await user.setCardFlags(current.cardId!, disabled: false);
    return add(c);
  }
}

final libraryStoriesProvider = Provider<AsyncValue<List<Story>>>(
  (ref) => ref
      .watch(storySummariesProvider)
      .whenData(
        (values) => [
          for (final s in values)
            Story(
              id: s.id,
              title: s.title,
              topic: 'Alltag',
              level: s.level == 'anfaenger' ? 'A2' : s.level,
              readingMinutes: s.minutes,
            ),
        ],
      ),
);
