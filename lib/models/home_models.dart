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

enum DeckDifficulty {
  beginner(1, 'Einsteiger'),
  intermediate(2, 'Mittelstufe'),
  advanced(3, 'Fortgeschritten');

  const DeckDifficulty(this.bolts, this.label);

  /// Number of lit bolts out of three.
  final int bolts;
  final String label;
}

/// A word recently seen in a deck, for the "letzten 5" list.
class SeenWord {
  const SeenWord({required this.word, required this.translation});

  final String word;
  final String translation;
}

/// View model for a deck. The counts are derived upstream from card state
/// (like [VocabBreakdown]); they are never persisted as counters.
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.totalWords,
    required this.seenWords,
    required this.masteredWords,
    required this.isActive,
    this.recentWords = const [],
  }) : assert(0 <= masteredWords && masteredWords <= seenWords),
       assert(seenWords <= totalWords && totalWords > 0);

  /// Stable slug, so content-pack imports stay idempotent.
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final DeckDifficulty difficulty;

  /// All words in the deck.
  final int totalWords;

  /// Words shown at least once ("X von Y neuen Wörtern").
  final int seenWords;

  /// Words in box 5 ("Z Wörter gelernt", "gemeistert").
  final int masteredWords;

  /// Whether the deck feeds the mixed daily practice ("Stapel lernen").
  final bool isActive;

  /// Most recent first.
  final List<SeenWord> recentWords;

  double get masteredFraction => masteredWords / totalWords;

  Deck copyWith({bool? isActive}) => Deck(
    id: id,
    name: name,
    description: description,
    icon: icon,
    difficulty: difficulty,
    totalWords: totalWords,
    seenWords: seenWords,
    masteredWords: masteredWords,
    isActive: isActive ?? this.isActive,
    recentWords: recentWords,
  );
}

enum DayMark { met, missed, today, upcoming }

/// Monday-first week row for the streak. Derived from the review log by local
/// calendar date once that exists.
class WeekProgress {
  const WeekProgress(this.days);

  /// Exactly seven entries, Monday first.
  final List<DayMark> days;
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
