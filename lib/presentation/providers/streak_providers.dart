import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/review_activity.dart';
import '../../models/story_models.dart';
import '../../domain/streak.dart';
import '../../models/word_list_models.dart';
import 'database_providers.dart';
import 'deck_providers.dart';
import 'learning_providers.dart';
import 'story_learning_providers.dart';

/// Streak and week stars from the review log's local calendar days.
final streakProvider = FutureProvider<StreakSummary>((ref) async {
  ref.watch(userChangesProvider);
  final now = ref.watch(learningNowProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  final activity = await user.activityBetween(
    DateTime(1970),
    DateTime(now.year, now.month, now.day + 1),
  );
  final days = {
    for (final review in activity) calendarDay(review.at.toLocal()),
  };
  return summarizeStreak(days, now);
}, retry: (_, _) => null);

/// One of the learner's own best-known words, chosen when a week star is
/// earned and shown for that week. Stable for the star's date; `null` while
/// no star from the last seven days exists or no word has been reviewed.
final wordOfWeekProvider = FutureProvider<VocabWord?>((ref) async {
  final streak = await ref.watch(streakProvider.future);
  final star = streak.latestStar;
  final now = ref.watch(learningNowProvider);
  if (star == null || calendarDay(now).difference(star).inDays > 6) {
    return null;
  }
  final user = await ref.watch(userRepositoryProvider.future);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final states = await user.allCardStates();
  final reviewed = await user.lastReviewTimes();
  final eligible = [
    for (final card in resolver.cards.values)
      if (states[card.id] case final state?)
        if (!state.disabled && !state.retired && reviewed.containsKey(card.id))
          card,
  ];
  if (eligible.isEmpty) return null;
  final best = eligible
      .map((c) => states[c.id]!.box)
      .reduce((a, b) => a > b ? a : b);
  final pool = eligible.where((c) => states[c.id]!.box == best).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final seed =
      DateTime.utc(star.year, star.month, star.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final card = pool[seed % pool.length];
  final state = states[card.id]!;
  return VocabWord(
    id: card.id,
    entry: WordEntry(
      headword: card.form,
      partOfSpeech: card.exerciseLabel,
      translation: card.translationDe ?? '',
    ),
    sentence: '',
    sentenceTranslation: '',
    box: state.box,
    lastSeenAt: reviewed[card.id]!,
    reviewCount: (await user.reviewsFor(card.id)).length,
  );
}, retry: (_, _) => null);

/// Remembers which star day already played its celebration, so it runs once
/// the first time Home is seen after the star was earned. UI state only.
abstract class CelebrationMarks {
  Future<bool> celebrated(DateTime starDay);
  Future<void> markCelebrated(DateTime starDay);
}

/// Default (tests, previews): remembered for the app's lifetime only.
class MemoryCelebrationMarks implements CelebrationMarks {
  final _days = <String>{};
  @override
  Future<bool> celebrated(DateTime starDay) async =>
      _days.contains(_key(starDay));
  @override
  Future<void> markCelebrated(DateTime starDay) async =>
      _days.add(_key(starDay));
}

/// Language-scoped device storage for presentation state.
/// Any I/O failure falls back to memory: worst case the star plays again.
class FileCelebrationMarks extends MemoryCelebrationMarks {
  FileCelebrationMarks([this.language = 'en']);
  final String language;
  Future<File>? _file;
  Future<void>? _loading;
  Future<void> _writes = Future.value();

  Future<File> _open() => _file ??= getApplicationSupportDirectory().then(
    (dir) => File(p.join(dir.path, 'ui', language, 'ui_marks.json')),
  );

  Future<void> _load() => _loading ??= _readMarks();

  Future<void> _readMarks() async {
    try {
      final file = await _open();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      for (final day in (json['celebratedStars'] as List? ?? const [])) {
        _days.add(day as String);
      }
    } catch (_) {}
  }

  @override
  Future<bool> celebrated(DateTime starDay) async {
    await _load();
    return super.celebrated(starDay);
  }

  @override
  Future<void> markCelebrated(DateTime starDay) async {
    await _load();
    await super.markCelebrated(starDay);
    _writes = _writes.then((_) async {
      try {
        final file = await _open();
        await file.parent.create(recursive: true);
        final recent = (_days.toList()..sort()).reversed.take(20).toList();
        final temp = File('${file.path}.tmp');
        await temp.writeAsString(
          jsonEncode({'celebratedStars': recent}),
          flush: true,
        );
        await temp.rename(file.path);
      } catch (_) {}
    });
    await _writes;
  }
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final celebrationMarksProvider = Provider<CelebrationMarks>(
  (ref) => MemoryCelebrationMarks(),
);
