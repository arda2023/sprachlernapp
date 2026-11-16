import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/home_models.dart';
import '../../models/news_models.dart';
import '../../models/story_models.dart';
import 'database_providers.dart';

/// Editorial text assets use the unannotated reader and can include offline
/// glosses and translations indexed by the literal text.
class BundledStory {
  BundledStory(
    this.story,
    this.text,
    this.language, {
    this.translations = const {},
    this.glosses = const {},
    this.sources = const [],
  });
  final Story story;
  final StoryText text;
  final String language;
  final Map<String, String> translations;
  final Map<String, String> glosses;
  final List<NewsSource> sources;

  static List<BundledStory> decode(String json, String language) => [
    for (final row in jsonDecode(json) as List)
      BundledStory(
        Story(
          id: row['id'] as String,
          title: row['title'] as String,
          topic: row['topic'] as String,
          level: row['level'] as String? ?? '',
          readingMinutes: row['minutes'] as int,
        ),
        StoryText(
          storyId: row['id'] as String,
          paragraphs: (row['body'] as String).split(RegExp(r'\n\s*\n')),
        ),
        language,
        translations: Map.unmodifiable(
          (row['translations'] as Map<String, dynamic>? ?? const {})
              .cast<String, String>(),
        ),
        glosses: Map.unmodifiable(
          (row['glosses'] as Map<String, dynamic>? ?? const {})
              .cast<String, String>(),
        ),
        sources: [
          for (final source in row['sources'] as List? ?? const [])
            NewsSource(
              title: source['title'] as String,
              url: Uri.parse(source['url'] as String),
            ),
        ],
      ),
  ];
}

final bundledStoriesProvider = FutureProvider<List<BundledStory>>((ref) async {
  final language = await ref.watch(selectedContentLanguageProvider.future);
  final editions = await Future.wait([
    rootBundle.loadString('assets/content/$language/stories.json'),
    rootBundle.loadString('assets/content/$language/learning-stories.json'),
  ]);
  return [for (final json in editions) ...BundledStory.decode(json, language)];
}, retry: (_, _) => null);
