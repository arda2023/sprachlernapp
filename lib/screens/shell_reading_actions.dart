import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_access_policy.dart';
import '../models/home_models.dart';
import '../models/story_models.dart';
import '../presentation/providers/content_access_provider.dart';
import '../presentation/providers/database_providers.dart';
import '../presentation/providers/premium_access_provider.dart';
import '../presentation/providers/reading_providers.dart';
import '../widgets/premium_content_gate.dart';
import 'stories/story_reader_screen.dart';

void openStoryFromShell(
  BuildContext context,
  WidgetRef ref,
  Story story, {
  required bool Function() isMounted,
  void Function(String storyId)? onOpened,
}) {
  if (!ref.read(premiumContentAccessProvider)) {
    showPremiumContentPaywall(context, interest: 'Stories');
    return;
  }
  onOpened?.call(story.id);
  final progress = ref.read(readingProgressProvider.notifier);
  final language = ref.read(selectedContentLanguageProvider).asData?.value;
  final start = ref.read(readingProgressProvider)[story.id]?.fraction;
  void report(double f) {
    if (isMounted() &&
        ref.read(selectedContentLanguageProvider).asData?.value == language) {
      progress.report(story.id, f);
    }
  }

  StoryReaderScreen.open(
    context,
    story,
    initialProgress: start,
    onProgress: report,
  );
}

void openImportedFromShell(
  BuildContext context,
  WidgetRef ref,
  ImportedText text, {
  required bool Function() isMounted,
}) {
  if (!ref.read(premiumContentAccessProvider)) {
    showPremiumContentPaywall(context, interest: 'Eigene Texte');
    return;
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
