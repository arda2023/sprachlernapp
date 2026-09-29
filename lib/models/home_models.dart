import 'package:flutter/widgets.dart';

class VocabStats {
  const VocabStats({
    required this.activated,
    required this.mastered,
    required this.total,
  }) : assert(mastered <= activated && activated <= total);

  /// Includes mastered words; mastered is a subset of activated.
  final int activated;
  final int mastered;
  final int total;

  int get inPractice => activated - mastered;
}

class Deck {
  const Deck({required this.name, required this.masteredFraction});

  final String name;
  final double masteredFraction;
}

class Story {
  const Story({
    required this.title,
    required this.topic,
    required this.difficulty,
    this.cover,
  }) : assert(difficulty >= 1 && difficulty <= 3);

  final String title;
  final String topic;
  final int difficulty;
  final ImageProvider? cover;
}
