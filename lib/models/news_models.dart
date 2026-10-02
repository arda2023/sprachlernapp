import 'package:flutter/widgets.dart' show ImageProvider;

import 'home_models.dart';
import 'story_models.dart';

/// The five news desks, one card each in the "Nachrichten" carousel.
enum NewsCategory {
  politics('Politik'),
  economy('Wirtschaft'),
  technology('Technologie'),
  medicine('Medizin'),
  entertainment('Unterhaltung');

  const NewsCategory(this.label);

  final String label;

  /// The kicker on the card, e.g. "WIRTSCHAFT".
  String get kicker => label.toUpperCase();
}

/// One part of a news article: a subheading and a short paragraph.
class NewsSection {
  const NewsSection({required this.heading, required this.paragraph});

  final String heading;
  final String paragraph;
}

/// A weekly news summary. Unlike a story it alternates subheadings and short
/// paragraphs. It reads in the story reader, so word lookup, sentence
/// translation and narration work the same. Language tags are explicit from
/// day one (PRODUCT.md).
class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.level,
    required this.readingMinutes,
    required this.sections,
    this.cover,
    this.sourceLanguage = 'en',
    this.targetLanguage = 'de',
  }) : assert(readingMinutes > 0);

  /// Stable slug, so content-pack imports stay idempotent.
  final String id;
  final NewsCategory category;
  final String title;

  /// CEFR level, as on stories.
  final String level;
  final int readingMinutes;
  final List<NewsSection> sections;
  final ImageProvider? cover;
  final String sourceLanguage;
  final String targetLanguage;

  /// The reader's header data: the category stands in for the topic.
  Story get asStory => Story(
    id: id,
    title: title,
    topic: category.label,
    level: level,
    readingMinutes: readingMinutes,
    cover: cover,
  );

  /// The body for the reader: one paragraph per section, each led by its
  /// subheading.
  StoryText get text => StoryText(
    storyId: id,
    paragraphs: [for (final s in sections) s.paragraph],
    headings: [for (final s in sections) s.heading],
  );
}
