import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/home_models.dart';
import '../../models/story_models.dart';
import 'database_providers.dart';

/// Editorial text assets use the real unannotated reader/lookup path.
/// They never claim that dictionary senses or translations were reviewed.
class BundledStory {
  BundledStory(this.story, this.text, this.language);
  final Story story;
  final StoryText text;
  final String language;

  static List<BundledStory> decode(String json, String language) => [
    for (final row in jsonDecode(json) as List)
      BundledStory(
        Story(
          id: row['id'] as String,
          title: row['title'] as String,
          topic: row['topic'] as String,
          level: '',
          readingMinutes: row['minutes'] as int,
        ),
        StoryText(
          storyId: row['id'] as String,
          paragraphs: (row['body'] as String).split(RegExp(r'\n\s*\n')),
        ),
        language,
      ),
  ];
}

final bundledStoriesProvider = FutureProvider<List<BundledStory>>((ref) async {
  final language = await ref.watch(selectedContentLanguageProvider.future);
  final json = await rootBundle.loadString(
    'assets/content/$language/stories.json',
  );
  return BundledStory.decode(json, language);
}, retry: (_, _) => null);
