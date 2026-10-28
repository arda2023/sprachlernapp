import 'package:flutter/foundation.dart';
import '../../domain/story_failure_trace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/story_learning.dart';
import '../../domain/repositories.dart';
import '../../domain/story_learning_diagnostics.dart';
import '../../models/home_models.dart';
import '../../data/learning/practice_item_resolver.dart';
import 'database_providers.dart';
import 'deck_providers.dart';

final practiceCatalogProvider = FutureProvider<PracticeCatalog>((ref) async {
  return PracticeCatalog.load(await ref.watch(contentRepositoryProvider.future));
}, retry: (_, _) => null);

final practiceResolverProvider = FutureProvider<PracticeItemResolver>((
  ref,
) async {
  ref.watch(userChangesProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  ContentRepository? content;
  PracticeCatalog? catalog;
  Object? contentError;
  try {
    content = await ref.watch(contentRepositoryProvider.future);
    catalog = await ref.watch(practiceCatalogProvider.future);
  } catch (error) {
    content = null;
    contentError = error;
  }
  // A broken user read/correction is not a missing pack. Do not retry it via
  // the offline fallback and accidentally hide a technical failure.
  return PracticeItemResolver.load(user, content,
    catalog: catalog, contentError: contentError);
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
  Future<T> _at<T>(StoryLearningStep step, Future<T> Function() action) async {
    try {
      return await action();
    } on StoryLearningFailure {
      rethrow;
    } catch (error, stack) {
      // Profile diagnostics retain only the exception class and source locations.
      if (!kReleaseMode) debugPrint(storyFailureTrace(step, error, stack));
      // Deliberately discard raw errors: they can contain private text/URLs.
      throw StoryLearningFailure(step);
    }
  }

  Future<StoryLearningCandidate> candidate(String story, String sentence, int token) =>
      _at(StoryLearningStep.context, () async {
        final content = await ref.read(contentRepositoryProvider.future);
        if (content is! StoryContentRepository) {
          throw const StoryLearningFailure(StoryLearningStep.context);
        }
        return (content as StoryContentRepository).resolveStoryWord(story, sentence, token);
      });

  Future<StoryAddResult> status(StoryLearningCandidate c) =>
      _at(StoryLearningStep.status, () async {
        final user = await ref.read(userRepositoryProvider.future);
        if (user is! StoryLearningRepository) {
          throw const StoryLearningFailure(StoryLearningStep.status);
        }
        final result = await (user as StoryLearningRepository).storyLearningStatus(c);
        if (!result.canAdd || result.message != null) return result;
        final availability = storyAvailability(c);
        return StoryAddResult(result.state, cardId: result.cardId, message:
          availability == StoryLearningAvailability.existingCard
              ? 'Die vorhandene Lernkarte wird mit deiner Sammlung verknüpft.'
              : availability == StoryLearningAvailability.approvedContext
              ? 'Ein geprüfter Übungssatz ist vorhanden.' : null);

      });

  Future<StoryAddResult> add(StoryLearningCandidate old) async {
    final current = await candidate(old.storyId, old.sentence.id, old.token.index);
    if (current.retired) return status(current);
    if (current.sourceFingerprint != old.sourceFingerprint) {
      return const StoryAddResult(StoryAddState.unavailable,
        message: 'Der Story-Inhalt hat sich geändert. Bitte das Wort erneut öffnen.');
    }
    return _at(StoryLearningStep.save, () async {
      final user = await ref.read(userRepositoryProvider.future);
      if (user is! StoryLearningRepository) {
        throw const StoryLearningFailure(StoryLearningStep.save);
      }
      // This committed result is authoritative; no fallible post-save status read.
      return (user as StoryLearningRepository).addStoryWord(current, now: ref.read(clockProvider)());
    });
  }

  Future<StoryAddResult> reactivate(StoryLearningCandidate c) async {
    final fresh = await candidate(c.storyId, c.sentence.id, c.token.index);
    if (fresh.retired) return status(fresh);
    if (fresh.sourceFingerprint != c.sourceFingerprint) {
      return const StoryAddResult(StoryAddState.unavailable,
        message: 'Der Story-Inhalt hat sich geändert. Bitte das Wort erneut öffnen.');
    }
    final current = await status(fresh);
    if (current.state != StoryAddState.disabled) return current;
    await _at(StoryLearningStep.reactivate, () async {
      final user = await ref.read(userRepositoryProvider.future);
      await user.setCardFlags(current.cardId!, disabled: false);
    });
    return add(fresh);
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
