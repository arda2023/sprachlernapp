import 'package:flutter/material.dart';

/// Visual metadata for real story topics; contains no sample content.
class StoryCategory {
  const StoryCategory(this.name, this.color, this.icon);

  final String name;

  /// Cover base colour; dark enough for white text.
  final Color color;

  /// Placeholder illustration until real artwork exists.
  final IconData icon;

  static const science = StoryCategory(
    'Wissenschaft',
    Color(0xFF2D5AB8),
    Icons.science_outlined,
  );
  static const restaurant = StoryCategory(
    'Restaurant',
    Color(0xFFB0472C),
    Icons.restaurant,
  );
  static const work = StoryCategory(
    'Englisch im Beruf',
    Color(0xFF256B5A),
    Icons.work_outline,
  );
  static const travel = StoryCategory(
    'Reisen',
    Color(0xFF8A5A1E),
    Icons.flight_takeoff,
  );
  static const everyday = StoryCategory(
    'Alltag',
    Color(0xFF3E4A8F),
    Icons.home_outlined,
  );
  static const health = StoryCategory(
    'Gesundheit',
    Color(0xFF9E3560),
    Icons.favorite_border,
  );
  static const culture = StoryCategory(
    'Kultur',
    Color(0xFF5C478F),
    Icons.museum_outlined,
  );
  static const tech = StoryCategory('Technik', Color(0xFF1F6C8C), Icons.memory);

  /// Display order on the Stories tab.
  static const all = [
    science,
    restaurant,
    work,
    travel,
    everyday,
    health,
    culture,
    tech,
  ];

  static const _aliases = {'Küche': restaurant, 'Medizin': health};

  static StoryCategory of(String topic) =>
      _aliases[topic] ??
      all.where((c) => c.name == topic).firstOrNull ??
      StoryCategory(topic, const Color(0xFF3B4150), Icons.menu_book_outlined);
}
