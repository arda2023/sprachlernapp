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

/// A web page a daily article is based on; shown under the article.
class NewsSource {
  const NewsSource({required this.title, required this.url});

  final String title;
  final Uri url;

  /// "reuters.com" for "https://www.reuters.com/world/…".
  String get site => url.host.replaceFirst(RegExp(r'^www\.'), '');
}

/// A news article. Unlike a story it alternates subheadings and short
/// paragraphs. It reads in the story reader, so word lookup, sentence
/// translation and narration work the same. Language tags are explicit from
/// day one (PRODUCT.md). Daily articles (user decision 01.11.2026) carry
/// their German sentence translations and their web sources.
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
    this.edition,
    this.sources = const [],
    this.translations = const {},
  }) : assert(readingMinutes > 0);

  /// One daily article from `latest_news`; throws [FormatException] when a
  /// field is missing or malformed.
  factory NewsArticle.fromJson(Map<String, dynamic> json, String lang) {
    T field<T>(String key) => json[key] is T
        ? json[key] as T
        : throw FormatException('Nachricht: $key');
    final category = NewsCategory.values.firstWhere(
      (c) => c.name == field<String>('category'),
      orElse: () => throw const FormatException('Nachricht: category'),
    );
    final sections = <NewsSection>[];
    final translations = <String, String>{};
    for (final section in field<List<dynamic>>('sections')) {
      final sentences = (section as Map<String, dynamic>)['sentences'] as List;
      final texts = <String>[];
      for (final sentence in sentences.cast<Map<String, dynamic>>()) {
        final text = (sentence['text'] as String).trim();
        texts.add(text);
        translations[text] = (sentence['de'] as String).trim();
      }
      sections.add(
        NewsSection(
          heading: section['heading'] as String,
          paragraph: texts.join(' '),
        ),
      );
    }
    final sources = [
      for (final source in field<List<dynamic>>('sources'))
        if (Uri.tryParse((source as Map<String, dynamic>)['url'] as String)
            case final url? when url.scheme == 'https' && url.host.isNotEmpty)
          NewsSource(title: source['title'] as String, url: url),
    ];
    if (sections.isEmpty || sources.isEmpty) {
      throw const FormatException('Nachricht: Inhalt');
    }
    return NewsArticle(
      id: field<String>('id'),
      category: category,
      title: field<String>('title'),
      level: field<String>('level'),
      readingMinutes: (field<num>('reading_minutes')).toInt().clamp(1, 60),
      sections: sections,
      sourceLanguage: lang,
      edition: DateTime.tryParse(field<String>('edition')),
      sources: sources,
      translations: translations,
    );
  }

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

  /// The day a daily article was written; null for the bundled samples.
  final DateTime? edition;
  final List<NewsSource> sources;

  /// German translation per sentence, keyed by the trimmed sentence.
  final Map<String, String> translations;

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
