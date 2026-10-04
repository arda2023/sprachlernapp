import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/home_models.dart';
import '../../models/word_list_models.dart';
import '../../models/story_models.dart';
import '../../domain/srs_state.dart';
import 'database_providers.dart';
import 'story_learning_providers.dart';
import 'deck_providers.dart';

/// Invalidate derived views at local midnight and after a background period.
final learningNowProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  final timer = Timer(
    DateTime(now.year, now.month, now.day + 1).difference(now),
    ref.invalidateSelf,
  );
  final observer = _ClockObserver(ref.invalidateSelf);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(observer);
  });
  return now;
});

class _ClockObserver extends WidgetsBindingObserver {
  _ClockObserver(this.refresh);
  final void Function() refresh;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}

final learningProgressProvider =
    FutureProvider<({DailyGoal goal, WeekProgress week})>((ref) async {
      ref.watch(userChangesProvider);
      final now = ref.watch(learningNowProvider);
      final user = await ref.watch(userRepositoryProvider.future);
      final prefs = await user.preferences();
      final days = <DateTime, Set<String>>{};
      for (final id in (await user.allCardStates()).keys) {
        for (final review in await user.reviewsFor(id)) {
          final at = review.createdAt.toLocal();
          (days[DateTime(at.year, at.month, at.day)] ??= {}).add(id);
        }
      }
      final today = DateTime(now.year, now.month, now.day);
      final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
      return (
        goal: DailyGoal(
          done: days[today]?.length ?? 0,
          target: prefs.dailyGoal,
        ),
        week: WeekProgress([
          for (var i = 0; i < 7; i++)
            if (DateTime(
              monday.year,
              monday.month,
              monday.day + i,
            ).isAfter(today))
              DayMark.upcoming
            else if ((days[DateTime(monday.year, monday.month, monday.day + i)]
                        ?.length ??
                    0) >=
                prefs.dailyGoal)
              DayMark.met
            else if (i == now.weekday - 1)
              DayMark.today
            else
              DayMark.missed,
        ]),
      );
    }, retry: (_, _) => null);

final learningNoticesProvider = FutureProvider<List<String>>(
  (ref) async => (await ref.watch(practiceResolverProvider.future)).notices,
);

final wordListProvider = FutureProvider<List<VocabWord>>((ref) async {
  ref.watch(userChangesProvider);
  ref.watch(learningNowProvider);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final user = await ref.watch(userRepositoryProvider.future);
  final known = resolver.knownIds;
  final states = await user.allCardStates();
  // Box zero has not been answered; unknown old IDs remain untouched in user.db.
  final ids = [
    for (final s in states.values)
      if ((s.box >= 1 ||
              resolver.additions.containsKey(s.cardId) ||
              s.origin == CardOrigin.story) &&
          !s.retired &&
          known.contains(s.cardId))
        s.cardId,
  ];
  final items = await resolver.practiceItems(ids);
  final words = <VocabWord>[];
  for (final item in items) {
    final state = states[item.card.id]!;
    final reviews = await user.reviewsFor(item.card.id);
    final sentence =
        (reviews.isEmpty
            ? null
            : await resolver.historicalSentence(
                item.card.id,
                reviews.last.sentenceId,
              )) ??
        item.practiceSentence;
    final seen = reviews.isEmpty
        ? state.createdAt
        : reviews.last.createdAt.toLocal();
    if (seen == null) continue;
    words.add(
      VocabWord(
        id: item.card.id,
        entry: WordEntry(
          headword: item.card.form,
          partOfSpeech: item.card.formLabelDe ?? item.card.pos,
          translation: item.card.translationDe ?? '',
        ),
        sentence: sentence.text,
        sentenceTranslation: sentence.translationDe ?? '',
        box: state.box,
        lastSeenAt: seen,
        reviewCount: reviews.length,
        isDisabled: state.disabled,
        isFavorite: state.favorite,
        inPlaylist: state.inPlaylist,
        note: state.note,
      ),
    );
  }
  words.sort((a, b) {
    final d = b.lastSeenAt.compareTo(a.lastSeenAt);
    return d != 0 ? d : a.id.compareTo(b.id);
  });
  return words;
}, retry: (_, _) => null);

final wordActionsProvider = Provider<WordActions>((ref) => WordActions(ref));

class WordActions {
  WordActions(this.ref);
  final Ref ref;
  Future<void> save(
    String id, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  }) async {
    final user = await ref.read(userRepositoryProvider.future);
    await user.setCardFlags(
      id,
      favorite: favorite,
      disabled: disabled,
      inPlaylist: inPlaylist,
      note: note,
    );
    ref.invalidate(wordListProvider);
    ref.invalidate(vocabBreakdownProvider);
    ref.invalidate(decksProvider);
  }
}
