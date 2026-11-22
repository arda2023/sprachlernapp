import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tutor/tutor_client.dart';
import '../../data/tutor/tutor_codec.dart';
import '../../data/tutor/tutor_store.dart';
import '../../domain/srs_state.dart' show randomUuidV4;
import '../../domain/tutor.dart';
import '../../domain/tutor_skills.dart';
import 'auth_providers.dart';
import 'database_providers.dart';
import 'personal_learning_provider.dart';
import 'premium_access_provider.dart';

enum TutorAvailability {
  available,
  accountRequired,
  consentRequired,
  unsupportedLanguage,
}

enum TutorSessionStatus {
  idle,
  loading,
  answering,
  grading,
  feedback,
  completed,
  offline,
  limitReached,
  unavailable,
  error,
}

final tutorClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final tutorIdProvider = Provider<String Function()>((ref) => randomUuidV4);
final tutorClientProvider = Provider<TutorClient>(
  (ref) => TutorClient(access: ref.watch(personalLearningClientProvider)),
);
final tutorStoreProvider = FutureProvider<TutorStore>(
  (ref) async => TutorStore(
    await ref.watch(userDatabaseProvider.future),
    lang: await ref.watch(selectedContentLanguageProvider.future),
  ),
  retry: (_, _) => null,
);

final _tutorAccessChangesProvider = StreamProvider<int>((ref) async* {
  final access = ref.watch(personalLearningClientProvider);
  yield access.consentRevision;
  yield* access.changes.map((_) => access.consentRevision);
});

final tutorAvailabilityProvider = FutureProvider<TutorAvailability>((
  ref,
) async {
  ref.watch(_tutorAccessChangesProvider);
  final session = ref.watch(accountSessionProvider).asData?.value;
  final lang = await ref.watch(selectedContentLanguageProvider.future);
  if (!tutorSkills.containsKey(lang)) {
    return TutorAvailability.unsupportedLanguage;
  }
  final access = ref.watch(personalLearningClientProvider);
  if (session == null || await access.owner() == null) {
    return TutorAvailability.accountRequired;
  }
  return await access.consent()
      ? TutorAvailability.available
      : TutorAvailability.consentRequired;
}, retry: (_, _) => null);

/// Emits on database changes; the timer also refreshes after Berlin midnight.
final tutorRemainingFreeTodayProvider = StreamProvider<int>((ref) async* {
  final store = await ref.watch(tutorStoreProvider.future);
  final clock = ref.watch(tutorClockProvider);
  final events = StreamController<void>();
  final sub = store.db
      .select(store.db.tutorAttempts)
      .watch()
      .listen((_) => events.add(null));
  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => events.add(null),
  );
  ref.onDispose(() {
    timer.cancel();
    unawaited(sub.cancel());
    unawaited(events.close());
  });
  yield await store.remainingFreeToday(clock());
  await for (final _ in events.stream) {
    yield await store.remainingFreeToday(clock());
  }
});

class TutorDependencies {
  const TutorDependencies({
    required this.store,
    required this.client,
    required this.verify,
    required this.premium,
    required this.now,
    required this.newId,
  });
  final TutorStore store;
  final TutorClient client;
  final Future<void> Function() verify;
  final bool Function() premium;
  final DateTime Function() now;
  final String Function() newId;
}

final tutorDependenciesProvider = FutureProvider<TutorDependencies>((
  ref,
) async {
  ref.watch(accountSessionProvider);
  ref.watch(_tutorAccessChangesProvider);
  final store = await ref.watch(tutorStoreProvider.future);
  final client = ref.watch(tutorClientProvider);
  final access = ref.watch(personalLearningClientProvider);
  final revision = access.revision(), consent = access.consentRevision;
  var active = true;
  ref.onDispose(() => active = false);
  return TutorDependencies(
    store: store,
    client: client,
    now: ref.watch(tutorClockProvider),
    newId: ref.watch(tutorIdProvider),
    premium: () => ref.read(premiumContentAccessProvider),
    verify: () async {
      if (!active ||
          revision != access.revision() ||
          consent != access.consentRevision) {
        throw const TutorFailure(
          'ACCESS_CHANGED',
          'Konto, Sprache oder Freigabe geändert.',
        );
      }
      if (await access.owner() == null) {
        throw const TutorFailure('AUTH_REQUIRED', 'Bitte zuerst anmelden.');
      }
      if (!await access.consent()) {
        throw const TutorFailure(
          'CONSENT_REQUIRED',
          'Bitte zuerst die KI-Verarbeitung freigeben.',
        );
      }
      if (!active ||
          revision != access.revision() ||
          consent != access.consentRevision) {
        throw const TutorFailure(
          'ACCESS_CHANGED',
          'Konto, Sprache oder Freigabe geändert.',
        );
      }
    },
  );
}, retry: (_, _) => null);

class TutorRoundSummary {
  TutorRoundSummary(Iterable<TutorAttempt> attempts, this.skills)
    : correct = attempts.where((a) => a.outcome == TutorOutcome.correct).length,
      acceptable = attempts
          .where((a) => a.outcome == TutorOutcome.acceptable)
          .length,
      incorrect = attempts
          .where((a) => a.outcome == TutorOutcome.incorrect)
          .length;
  final int correct, acceptable, incorrect;
  final TutorCounts skills;
  int get total => correct + acceptable + incorrect;
}

class TutorSessionState {
  TutorSessionState({
    this.status = TutorSessionStatus.idle,
    this.lang,
    this.roundId,
    List<TutorRoundSlot> round = const [],
    this.index = 0,
    this.currentItem,
    this.lastAttempt,
    List<TutorAttempt> attempts = const [],
    this.failure,
    this.summary,
    this.remainingFreeToday = 3,
    this.pendingAnswer,
    this.prefetchFailure,
  }) : round = List.unmodifiable(round),
       attempts = List.unmodifiable(attempts);
  final TutorSessionStatus status;
  final String? lang, roundId;
  final List<TutorRoundSlot> round;
  final int index, remainingFreeToday;
  final TutorItem? currentItem;
  final TutorAttempt? lastAttempt;
  final List<TutorAttempt> attempts;
  final TutorFailure? failure, prefetchFailure;
  final TutorRoundSummary? summary;

  /// A network-uncertain answer must be submitted unchanged with its stored ID.
  final String? pendingAnswer;
  int get total => round.length;
  int get completed => attempts.length;
  bool get isLastItem => index >= total - 1;
  bool get premiumRequired => failure?.premiumRequired ?? false;
  TutorSessionState copyWith({
    TutorSessionStatus? status,
    int? index,
    TutorItem? currentItem,
    TutorAttempt? lastAttempt,
    List<TutorAttempt>? attempts,
    TutorFailure? failure,
    TutorRoundSummary? summary,
    int? remainingFreeToday,
    String? pendingAnswer,
    TutorFailure? prefetchFailure,
    bool clearPrefetchFailure = false,
  }) => TutorSessionState(
    status: status ?? this.status,
    lang: lang,
    roundId: roundId,
    round: round,
    index: index ?? this.index,
    currentItem: currentItem ?? this.currentItem,
    lastAttempt: lastAttempt,
    attempts: attempts ?? this.attempts,
    failure: failure,
    summary: summary ?? this.summary,
    remainingFreeToday: remainingFreeToday ?? this.remainingFreeToday,
    pendingAnswer: pendingAnswer,
    prefetchFailure: clearPrefetchFailure
        ? null
        : prefetchFailure ?? this.prefetchFailure,
  );
}

final tutorSessionControllerProvider =
    NotifierProvider<TutorSessionController, TutorSessionState>(
      TutorSessionController.new,
    );

class TutorSessionController extends Notifier<TutorSessionState> {
  TutorDependencies? _dependencies;
  final Map<int, TutorItem> _resolved = {};
  int _epoch = 0;
  Future<void>? _prefetch;
  String? _attemptId;
  bool _busy = false;

  @override
  TutorSessionState build() {
    final dependencies = ref.watch(tutorDependenciesProvider);
    _dependencies = dependencies.asData?.value;
    _epoch++;
    _resolved.clear();
    _prefetch = null;
    _attemptId = null;
    _busy = false;
    ref.onDispose(() => _epoch++);
    return TutorSessionState(
      status: dependencies.hasError
          ? TutorSessionStatus.error
          : _dependencies == null
          ? TutorSessionStatus.loading
          : TutorSessionStatus.idle,
      lang: _dependencies?.store.lang,
    );
  }

  void _verify(int epoch) {
    if (!ref.mounted || epoch != _epoch) {
      throw const TutorFailure('ACCESS_CHANGED', 'Sitzung geändert.');
    }
  }

  /// Call after tutorDependenciesProvider has resolved. Repeated taps during
  /// loading or an active round do not replace the frozen selection.
  Future<void> startRound() async {
    final d = _dependencies;
    if (d == null ||
        _busy ||
        !{
          TutorSessionStatus.idle,
          TutorSessionStatus.completed,
          TutorSessionStatus.error,
          TutorSessionStatus.offline,
          TutorSessionStatus.limitReached,
        }.contains(state.status) ||
        (state.round.isNotEmpty &&
            state.status != TutorSessionStatus.completed)) {
      return;
    }
    final epoch = ++_epoch;
    _busy = true;
    _resolved.clear();
    state = TutorSessionState(
      status: TutorSessionStatus.loading,
      lang: d.store.lang,
    );
    try {
      await d.verify();
      _verify(epoch);
      // Explicit restart recovers durable generations without spending again.
      for (final request in await d.store.pendingGenerations()) {
        late final List<TutorItem> items;
        try {
          items = await d.client.generate(request);
        } on TutorFailure catch (e) {
          await _discardTerminalGeneration(d, request, e, epoch);
          rethrow;
        }
        await d.verify();
        _verify(epoch);
        await d.store.completeGeneration(
          request,
          items,
          verify: () => _verify(epoch),
        );
      }
      final snapshot = await d.store.snapshot();
      final remaining = await d.store.remainingFreeToday(d.now());
      final pending = await d.store.pendingAttempts();
      _verify(epoch);
      final round = pending.isNotEmpty
          ? [
              for (final p in pending.take(10))
                TutorRoundSlot(
                  item: snapshot.items.firstWhere((i) => i.id == p.itemId),
                  request: TutorItemRequest(
                    skills: snapshot.items
                        .firstWhere((i) => i.id == p.itemId)
                        .skills,
                  ),
                ),
            ]
          : composeTutorRound(
              lang: d.store.lang,
              states: snapshot.skills,
              items: snapshot.items,
              now: d.now(),
              premium: d.premium(),
              remainingDailyQuota: remaining,
              previousRoundId: snapshot.previousRoundId,
              freshItemsSoFar: snapshot.attempts.where((a) => a.fresh).length,
            );
      if (round.isEmpty) {
        state = TutorSessionState(
          lang: d.store.lang,
          status: !d.premium() && remaining == 0
              ? TutorSessionStatus.limitReached
              : TutorSessionStatus.completed,
          remainingFreeToday: remaining,
          failure: !d.premium() && remaining == 0
              ? const TutorFailure(
                  'TUTOR_DAILY_LIMIT',
                  'Das Tageskontingent ist erreicht.',
                  premiumRequired: true,
                )
              : null,
          summary: TutorRoundSummary(
            [],
            tutorCounts(d.store.lang, snapshot.skills),
          ),
        );
        return;
      }
      state = TutorSessionState(
        status: TutorSessionStatus.loading,
        lang: d.store.lang,
        roundId: d.newId(),
        round: round,
        remainingFreeToday: remaining,
      );
      for (var i = 0; i < round.length; i++) {
        if (round[i].item != null) _resolved[i] = round[i].item!;
      }
      await _generateBatch(d, epoch);
      await _show(d, epoch, 0);
      _startPrefetch(d, epoch);
    } catch (e) {
      _fail(e, epoch);
    } finally {
      if (epoch == _epoch) _busy = false;
    }
  }

  Future<void> _generateBatch(TutorDependencies d, int epoch) async {
    _verify(epoch);
    final missing = [
      for (var i = 0; i < state.round.length; i++)
        if (!_resolved.containsKey(i)) i,
    ].take(5).toList();
    if (missing.isEmpty) return;
    final snapshot = await d.store.snapshot();
    final expiredIds = {
      for (final item in snapshot.items)
        if (item.expired(d.now())) item.id,
    };
    TutorItemRequest replacement(int index) {
      final slot = state.round[index];
      final spec = slot.request;
      if (expiredIds.contains(spec.parentItemId) ||
          expiredIds.contains(slot.item?.id)) {
        return TutorItemRequest(
          skills: slot.item?.skills ?? spec.skills,
          kind: spec.kind,
          origin: TutorOrigin.regenerated,
        );
      }
      return spec;
    }

    final recent = snapshot.items.where((i) => i.lastShownAt != null).toList()
      ..sort((a, b) => b.lastShownAt!.compareTo(a.lastShownAt!));
    final avoid = <String>{for (final i in recent) i.topic}.take(8).toList();
    final pending = await d.store.pendingGenerations();
    final request =
        pending.firstOrNull ??
        TutorGenerationRequest(
          requestId: d.newId(),
          lang: d.store.lang,
          items: missing.map(replacement).toList(),
          avoidTopics: avoid,
        );
    await d.verify();
    _verify(epoch);
    await d.store.prepareGeneration(request);
    late final List<TutorItem> items;
    try {
      items = await d.client.generate(request);
    } on TutorFailure catch (e) {
      await _discardTerminalGeneration(d, request, e, epoch);
      rethrow;
    }
    await d.verify();
    _verify(epoch);
    await d.store.completeGeneration(
      request,
      items,
      verify: () => _verify(epoch),
    );
    for (var i = 0; i < items.length; i++) {
      final slot = missing
          .where(
            (index) =>
                !_resolved.containsKey(index) &&
                state.round[index].primarySkill == items[i].primarySkill,
          )
          .firstOrNull;
      if (slot != null) _resolved[slot] = items[i];
    }
  }

  Future<void> _discardTerminalGeneration(
    TutorDependencies d,
    TutorGenerationRequest request,
    TutorFailure failure,
    int epoch,
  ) async {
    if (!failure.terminalForId) return;
    _verify(epoch);
    if (failure.code == 'ITEM_EXPIRED' || failure.code == 'ITEM_NOT_FOUND') {
      for (final spec in request.items) {
        if (spec.parentItemId != null) {
          await d.store.retireExpiredItem(spec.parentItemId!, d.now());
          _verify(epoch);
        }
      }
    }
    await d.store.discardFailedGeneration(request.requestId);
  }

  void _startPrefetch(TutorDependencies d, int epoch) {
    if (_prefetch != null || _resolved.length == state.round.length) return;
    _prefetch = (() async {
      try {
        while (_resolved.length < state.round.length) {
          await _generateBatch(d, epoch);
        }
      } catch (e) {
        if (ref.mounted && epoch == _epoch) {
          state = state.copyWith(
            status: state.status,
            lastAttempt: state.lastAttempt,
            pendingAnswer: state.pendingAnswer,
            prefetchFailure: _failure(e),
          );
        }
      }
    })();
  }

  Future<void> _show(TutorDependencies d, int epoch, int index) async {
    _verify(epoch);
    while (index < state.round.length &&
        skipTutorDiagnostic(state.round[index], d.store.lang, state.attempts, {
          for (final i in _resolved.values) i.id: i,
        })) {
      index++;
    }
    if (index == state.round.length) {
      final snapshot = await d.store.snapshot();
      _verify(epoch);
      state = state.copyWith(
        status: TutorSessionStatus.completed,
        index: index,
        summary: TutorRoundSummary(
          state.attempts,
          tutorCounts(d.store.lang, snapshot.skills),
        ),
      );
      return;
    }
    if (_resolved[index]?.expired(d.now()) == true) {
      await d.store.retireExpiredItem(_resolved[index]!.id, d.now());
      _verify(epoch);
      _resolved.remove(index);
    }
    if (!_resolved.containsKey(index)) {
      await _prefetch;
      _verify(epoch);
      if (state.prefetchFailure != null) throw state.prefetchFailure!;
      if (!_resolved.containsKey(index)) await _generateBatch(d, epoch);
    }
    final item = _resolved[index]!;
    await d.verify();
    _verify(epoch);
    await d.store.markShown(item, state.roundId!, d.now());
    final pending = (await d.store.pendingAttempts())
        .where((p) => p.itemId == item.id)
        .firstOrNull;
    _verify(epoch);
    _attemptId = pending?.attemptId;
    state = state.copyWith(
      status: TutorSessionStatus.answering,
      index: index,
      currentItem: item,
      pendingAnswer: pending?.answer,
    );
  }

  Future<void> submitAnswer(String answer) async {
    answer = normalizeTutorAnswer(answer);
    final d = _dependencies, item = state.currentItem;
    if (d == null ||
        item == null ||
        _busy ||
        !{
          TutorSessionStatus.answering,
          TutorSessionStatus.offline,
          TutorSessionStatus.error,
          TutorSessionStatus.limitReached,
        }.contains(state.status) ||
        state.lastAttempt != null) {
      return;
    }
    if (answer.trim().isEmpty || answer.trim().length > 300) return;
    final epoch = _epoch;
    _busy = true;
    state = state.copyWith(
      status: TutorSessionStatus.grading,
      pendingAnswer: state.pendingAnswer,
    );
    try {
      await d.verify();
      _verify(epoch);
      final pending = await d.store.prepareAttempt(
        attemptId: _attemptId ??= d.newId(),
        item: item,
        answer: answer,
        now: d.now(),
      );
      _verify(epoch);
      _attemptId = pending.attemptId;
      state = state.copyWith(
        status: TutorSessionStatus.grading,
        pendingAnswer: pending.answer,
      );
      late final TutorGrade grade;
      try {
        grade = await d.client.grade(
          attemptId: pending.attemptId,
          item: item,
          answer: pending.answer,
        );
      } on TutorFailure catch (e) {
        if (e.terminalForId) {
          _verify(epoch);
          await d.store.discardFailedAttempt(pending.attemptId);
          _verify(epoch);
          _attemptId = null;
          if (e.code == 'ITEM_EXPIRED' || e.code == 'ITEM_NOT_FOUND') {
            await d.store.retireExpiredItem(item.id, d.now());
            _verify(epoch);
            _resolved.remove(state.index);
            state = state.copyWith(
              status: TutorSessionStatus.error,
              failure: e,
            );
          } else {
            state = state.copyWith(
              status: TutorSessionStatus.answering,
              failure: e,
            );
          }
          return;
        }
        rethrow;
      }
      await d.verify();
      _verify(epoch);
      final attempt = await d.store.completeAttempt(
        pending,
        grade,
        now: d.now(),
        verify: () => _verify(epoch),
      );
      final remaining = await d.store.remainingFreeToday(d.now());
      _verify(epoch);
      state = state.copyWith(
        status: TutorSessionStatus.feedback,
        lastAttempt: attempt,
        attempts: [...state.attempts, attempt],
        remainingFreeToday: remaining,
      );
    } catch (e) {
      _fail(e, epoch);
    } finally {
      if (epoch == _epoch) _busy = false;
    }
  }

  Future<void> next() async {
    final d = _dependencies;
    if (d == null || _busy || state.status != TutorSessionStatus.feedback) {
      return;
    }
    final epoch = _epoch;
    _busy = true;
    state = state.copyWith(
      status: TutorSessionStatus.loading,
      lastAttempt: state.lastAttempt,
    );
    try {
      await _show(d, epoch, state.index + 1);
    } catch (e) {
      _fail(e, epoch);
    } finally {
      if (epoch == _epoch) _busy = false;
    }
  }

  /// Explicit recovery only; MODEL_INVALID never triggers automatic retries.
  Future<void> retry() async {
    if (_busy ||
        !{
          TutorSessionStatus.error,
          TutorSessionStatus.offline,
          TutorSessionStatus.limitReached,
        }.contains(state.status)) {
      return;
    }
    if (state.round.isEmpty) {
      await startRound();
      return;
    }
    if (state.pendingAnswer != null) {
      await submitAnswer(state.pendingAnswer!);
      return;
    }
    final d = _dependencies;
    if (d == null) return;
    final epoch = _epoch;
    _busy = true;
    state = state.copyWith(
      status: state.status,
      lastAttempt: state.lastAttempt,
      pendingAnswer: state.pendingAnswer,
      clearPrefetchFailure: true,
    );
    _prefetch = null;
    try {
      await _show(
        d,
        epoch,
        state.lastAttempt != null ? state.index + 1 : state.index,
      );
      _startPrefetch(d, epoch);
    } catch (e) {
      _fail(e, epoch);
    } finally {
      if (epoch == _epoch) _busy = false;
    }
  }

  void endRound() {
    _epoch++;
    _resolved.clear();
    _prefetch = null;
    _busy = false;
    state = TutorSessionState(lang: _dependencies?.store.lang);
  }

  void _fail(Object error, int epoch) {
    if (!ref.mounted || epoch != _epoch) return;
    final failure = _failure(error);
    state = state.copyWith(
      status: switch (failure.code) {
        'NETWORK_UNAVAILABLE' || 'TIMEOUT' => TutorSessionStatus.offline,
        'TUTOR_DAILY_LIMIT' => TutorSessionStatus.limitReached,
        'AUTH_REQUIRED' ||
        'ACCOUNT_UNVERIFIED' ||
        'CONSENT_REQUIRED' ||
        'ACCESS_CHANGED' => TutorSessionStatus.unavailable,
        _ => TutorSessionStatus.error,
      },
      failure: failure,
      lastAttempt: state.lastAttempt,
      pendingAnswer: state.pendingAnswer,
    );
  }

  TutorFailure _failure(Object e) => e is TutorFailure
      ? e
      : const TutorFailure(
          'SERVICE_UNAVAILABLE',
          'Der AI-Tutor ist derzeit nicht verfügbar.',
        );
}
