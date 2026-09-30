import 'package:flutter/widgets.dart';

/// The four Lingvist categories (PRODUCT.md). Disjoint by construction, so
/// [total] always equals their sum. Derived upstream from card state and due
/// dates; never persisted.
class VocabBreakdown {
  const VocabBreakdown({
    required this.due,
    required this.building,
    required this.mastered,
    required this.unseen,
  }) : assert(due >= 0 && building >= 0 && mastered >= 0 && unseen >= 0);

  /// Verfügbare Wiederholungen: seen words whose due date has passed.
  final int due;

  /// Wörter im Aufbau: box 1–4, not yet due.
  final int building;

  /// Wörter gemeistert: box 5, not yet due.
  final int mastered;

  /// Noch nicht angezeigt: never shown to the learner.
  final int unseen;

  int get total => due + building + mastered + unseen;
}

/// A recommendation, never a lockout (PRODUCT.md).
class DailyGoal {
  const DailyGoal({required this.done, required this.target})
    : assert(done >= 0 && target > 0);

  final int done;
  final int target;
}

class Deck {
  const Deck({required this.name, required this.masteredFraction});

  final String name;
  final double masteredFraction;
}

class Story {
  const Story({
    required this.id,
    required this.title,
    required this.topic,
    required this.level,
    required this.readingMinutes,
    this.cover,
  }) : assert(readingMinutes > 0);

  /// Stable slug, so content-pack imports stay idempotent.
  final String id;
  final String title;
  final String topic;

  /// CEFR level, matching the header chip (e.g. 'A2').
  final String level;
  final int readingMinutes;
  final ImageProvider? cover;
}
