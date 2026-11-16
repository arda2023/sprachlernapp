import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_access_policy.dart';
import '../domain/editorial_stories.dart';
import '../domain/learning_milestone.dart';
import '../models/home_models.dart';
import '../models/story_models.dart';
import '../presentation/providers/auth_providers.dart';
import '../presentation/providers/content_access_provider.dart';
import '../presentation/providers/database_providers.dart';
import '../presentation/providers/learning_milestone_provider.dart';
import '../presentation/providers/premium_access_provider.dart';
import '../presentation/providers/reading_providers.dart';
import '../widgets/premium_action.dart';
import 'stories/story_reader_screen.dart';

Future<void> openStoryFromShell(
  BuildContext context,
  WidgetRef ref,
  Story story, {
  required bool Function() isMounted,
  void Function(String storyId)? onOpened,
}) async {
  final requestedLanguage = ref
      .read(selectedContentLanguageProvider)
      .asData
      ?.value;
  if (!isFreeStoryId(story.id) && !ref.read(premiumContentAccessProvider)) {
    final unlocked = await unlockPremiumAction(
      context,
      interest: 'Stories',
      allowGuestSignIn: true,
    );
    if (!unlocked ||
        !context.mounted ||
        !isMounted() ||
        ref.read(selectedContentLanguageProvider).asData?.value !=
            requestedLanguage) {
      return;
    }
  }
  onOpened?.call(story.id);
  final progress = ref.read(readingProgressProvider.notifier);
  final language = ref.read(selectedContentLanguageProvider).asData?.value;
  final start = ref.read(readingProgressProvider)[story.id]?.fraction;
  final auth = ref.read(contentAuthProvider);
  final owner = auth.localOwner;
  var finishing = false;
  bool isCurrent() =>
      isMounted() &&
      auth.localOwner == owner &&
      ref.read(selectedContentLanguageProvider).asData?.value == language &&
      identical(progress, ref.read(readingProgressProvider.notifier));
  void report(double f) {
    if (!finishing && isCurrent()) {
      // Only the completion callback may advance to a finished reading entry.
      progress.report(story.id, f < 0.98 ? f : 0.979);
    }
  }

  Future<bool> finish() async {
    if (!isCurrent()) return false;
    finishing = true;
    try {
      final first = await progress.finishStory(story.id);
      if (!first || !isCurrent()) return false;
      final store = await ref.read(learningMilestoneStoreProvider.future);
      if (!isCurrent()) return false;
      return await store.claim(LearningMilestone.firstStory) && isCurrent();
    } catch (_) {
      return false;
    } finally {
      finishing = false;
    }
  }

  StoryReaderScreen.open(
    context,
    story,
    initialProgress: start,
    onProgress: report,
    onFinished: finish,
  );
}

Future<void> openImportedFromShell(
  BuildContext context,
  WidgetRef ref,
  ImportedText text, {
  required bool Function() isMounted,
}) async {
  final requestedDatabase = ref.read(userDatabaseProvider.future);
  final requestedLanguage = ref
      .read(selectedContentLanguageProvider)
      .asData
      ?.value;
  if (!ref.read(premiumContentAccessProvider)) {
    final unlocked = await unlockPremiumAction(
      context,
      interest: 'Eigene Texte',
    );
    if (!unlocked ||
        !context.mounted ||
        !isMounted() ||
        ref.read(userDatabaseProvider.future) != requestedDatabase ||
        ref.read(selectedContentLanguageProvider).asData?.value !=
            requestedLanguage) {
      return;
    }
  }
  final language = ref.read(selectedContentLanguageProvider).asData?.value;
  final progress = ref.read(readingProgressProvider.notifier);
  StoryReaderScreen.openText(
    context,
    story: Story(
      id: text.id,
      title: text.title,
      topic: 'Import',
      level: 'Eigener Text',
      readingMinutes: text.readingMinutes,
    ),
    text: StoryText(storyId: text.id, paragraphs: text.paragraphs),
    lookup: WordEntry.unknown,
    sourceLanguage:
        ref.read(selectedContentLanguageProvider).asData?.value ?? 'en',
    initialProgress: ref.read(readingProgressProvider)[text.id]?.fraction,
    onProgress: (f) {
      if (isMounted() &&
          ref.read(selectedContentLanguageProvider).asData?.value == language) {
        progress.report(text.id, f);
      }
    },
  );
}

String? importTextFromShell(WidgetRef ref, String text) {
  final access = ref.read(contentAccessProvider);
  if (access == ContentAccessDecision.statusUnknown) {
    return 'Dein Premium-Zugang konnte noch nicht geprüft werden. '
        'Bitte prüfe ihn erneut.';
  }
  if (access == ContentAccessDecision.premiumRequired) {
    return 'Neue eigene Texte kannst du mit Premium importieren. '
        'Dein Text bleibt hier vorgemerkt.';
  }
  try {
    ref.read(importedTextsProvider.notifier).add(text);
    return null;
  } on FormatException catch (e) {
    return e.message;
  }
}
