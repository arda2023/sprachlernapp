import 'language_profile.dart';
import 'srs_state.dart';
import 'streak.dart';

/// Only editorial library metadata may enter the shared widget container.
class WidgetStory {
  const WidgetStory({required this.id, required this.title, this.coverAsset});
  final String id;
  final String title;
  final String? coverAsset;
}

class WidgetReading {
  const WidgetReading({
    required this.fraction,
    required this.updatedAt,
    required this.finished,
  });
  final double fraction;
  final DateTime updatedAt;
  final bool finished;
}

class LearningWidgetSnapshot {
  const LearningWidgetSnapshot(this.json, {this.coverAsset});
  const LearningWidgetSnapshot.empty()
    : json = const {'schemaVersion': 1, 'available': false},
      coverAsset = null;
  final Map<String, Object?> json;
  final String? coverAsset;
}

String widgetDayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Pure projection: no account identifiers, imported text or stored counters.
/// Eligibility is the same inventory used by deriveVocabBreakdown.
LearningWidgetSnapshot buildLearningWidgetSnapshot({
  required DateTime now,
  required String language,
  required int goalDone,
  required int goalTarget,
  required StreakSummary streak,
  required Iterable<String> eligibleCardIds,
  required Map<String, UserCardState> cards,
  required Iterable<WidgetStory> library,
  required Map<String, WidgetReading> reading,
}) {
  if (ContentLanguageProfile.forLanguage(language) == null) {
    return const LearningWidgetSnapshot.empty();
  }
  final today = DateTime(now.year, now.month, now.day);
  final recentCutoff = DateTime(now.year, now.month, now.day - 13);
  final active =
      streak.activeDays.where((date) => !date.isAfter(today)).toList()..sort();
  final due = <DateTime>[
    for (final id in eligibleCardIds.toSet())
      if (cards[id] case final card?)
        if (card.isActive && card.box > 0) (card.dueAt ?? now).toUtc(),
  ]..sort();
  final candidates =
      library.where((story) {
        final entry = reading[story.id];
        return !story.id.startsWith('import-') &&
            story.id.isNotEmpty &&
            story.id.length <= 256 &&
            story.title.trim().isNotEmpty &&
            story.title.length <= 300 &&
            entry != null &&
            !entry.finished &&
            entry.fraction.isFinite &&
            entry.fraction >= 0.02 &&
            entry.fraction < 0.98;
      }).toList()..sort((a, b) {
        final order = reading[b.id]!.updatedAt.compareTo(
          reading[a.id]!.updatedAt,
        );
        return order != 0 ? order : a.id.compareTo(b.id);
      });
  final story = candidates.firstOrNull;
  final cover = story?.coverAsset;
  final safeCover =
      cover != null &&
          RegExp(r'^assets/story_covers/[A-Za-z0-9_-]+\.png$').hasMatch(cover)
      ? cover
      : null;
  return LearningWidgetSnapshot({
    'schemaVersion': 1,
    'available': true,
    'generatedAt': now.toUtc().toIso8601String(),
    'day': widgetDayKey(now),
    'language': language,
    'streak': streak.current,
    'lastActiveDay': active.isEmpty ? null : widgetDayKey(active.last),
    'activeDays': [
      for (final date in active)
        if (!date.isBefore(recentCutoff)) widgetDayKey(date),
    ],
    'goalDone': goalDone.clamp(0, 1000000),
    'goalTarget': goalTarget.clamp(1, 1000000),
    'dueDates': [for (final date in due) date.toIso8601String()],
    'story': story == null
        ? null
        : {
            'id': story.id,
            'title': story.title,
            'coverFileName': null,
            'progress': reading[story.id]!.fraction.clamp(0.0, 1.0),
          },
  }, coverAsset: safeCover);
}
