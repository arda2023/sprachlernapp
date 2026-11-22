import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/tutor/tutor_client.dart';
import 'package:sprachapp/data/tutor/tutor_store.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';
import 'package:sprachapp/presentation/providers/tutor_providers.dart';
import 'package:sprachapp/screens/home/home_screen.dart';
import 'package:sprachapp/screens/tutor/tutor_screen.dart';

import '../accessibility/accessibility_test_app.dart';
import 'deck_repositories.dart';
import 'tutor.dart';

TutorItem tutorUiItem({
  int id = 1,
  TutorKind kind = TutorKind.translate,
  String lang = 'en',
  String? prompt,
}) => TutorItem(
  id: tutorTestId(id),
  lang: lang,
  kind: kind,
  promptDe:
      prompt ??
      (kind == TutorKind.translate
          ? 'Übersetze: Gestern habe ich meinen alten Lehrer getroffen.'
          : 'Wie würdest du jemanden nach der Uhrzeit fragen?'),
  referenceAnswer: 'I ran into my old teacher yesterday.',
  skills: ['present_simple'],
  topic: 'alltag',
  origin: TutorOrigin.practice,
  expiresAt: tutorTestNow.add(const Duration(days: 30)),
);

TutorAttempt tutorUiAttempt(
  TutorItem item, {
  TutorScores scores = const TutorScores(2, 1, 0),
  String? answer,
  String? feedback,
  String? ideal,
}) => TutorAttempt(
  attemptId: 'attempt-${item.id}',
  itemId: item.id,
  answer:
      answer ??
      switch ((scores.meaning, scores.grammar, scores.naturalness)) {
        (2, 2, 2) => 'I met my old teacher yesterday.',
        (2, 1, 1) => 'Yesterday I met with my old teacher.',
        (0, 0, 0) => 'Tomorrow I will call my teacher.',
        _ => 'Yesterday I meet my old teacher.',
      },
  scores: scores,
  outcome: tutorOutcome(scores, [], item.skills),
  errors: [],
  feedbackDe:
      feedback ??
      switch ((scores.meaning, scores.grammar, scores.naturalness)) {
        (2, 2, 2) =>
          'Die Bedeutung und die Zeitform stimmen. Dein Satz klingt natürlich.',
        (2, 1, 1) => 'Die Aussage ist klar. Für eine zufällige Begegnung passt „ran into“ besser.',
        (0, 0, 0) => 'Dein Satz beschreibt ein Telefonat morgen. Gefragt ist eine Begegnung gestern.',
        _ =>
          'Die Bedeutung stimmt. Für gestern brauchst du „met“ statt „meet“.',
      },
  idealAnswer:
      ideal ??
      (scores.grammar == 1 && scores.naturalness == 1
          ? 'I ran into my old teacher yesterday.'
          : 'I met my old teacher yesterday.'),
  fresh: true,
  createdAt: tutorTestNow,
);

/// Presentation double: deliberately no inherited controller method or AI
/// transport is invoked. The real controller has its own persistence tests.
class FakeTutorSessionController extends TutorSessionController {
  FakeTutorSessionController({TutorItem? item, this.total = 3})
    : item = item ?? tutorUiItem();
  final TutorItem item;
  final int total;
  TutorScores scores = const TutorScores(2, 1, 0);
  TutorSessionStatus initialStatus = TutorSessionStatus.answering;
  TutorFailure? failure;
  Completer<void>? grading;
  int starts = 0, retries = 0, endings = 0;
  final answers = <String>[];
  final attempts = <TutorAttempt>[];
  bool dependenciesReady = false;
  String? restoredAnswer;

  @override
  TutorSessionState build() => TutorSessionState();

  void emit(TutorSessionState value) => state = value;

  TutorSessionState session({
    TutorSessionStatus? status,
    int index = 0,
    TutorAttempt? attempt,
    String? pending,
  }) => TutorSessionState(
    status: status ?? initialStatus,
    lang: item.lang,
    currentItem: index == 0
        ? item
        : tutorUiItem(id: index + 1, lang: item.lang),
    round: [
      for (var i = 0; i < total; i++)
        TutorRoundSlot(request: TutorItemRequest(skills: item.skills)),
    ],
    index: index,
    lastAttempt: attempt,
    attempts: attempts,
    failure: failure,
    pendingAnswer: pending,
    summary: status == TutorSessionStatus.completed
        ? TutorRoundSummary(attempts, const TutorCounts(1, 0, 4))
        : null,
  );

  @override
  Future<void> startRound() async {
    if (!dependenciesReady) throw StateError('Dependencies must be awaited');
    starts++;
    if (initialStatus == TutorSessionStatus.feedback ||
        initialStatus == TutorSessionStatus.completed) {
      attempts.add(tutorUiAttempt(item, scores: scores));
    }
    state = session(
      status: initialStatus,
      attempt: initialStatus == TutorSessionStatus.feedback
          ? attempts.last
          : null,
      pending: restoredAnswer,
    );
  }

  @override
  Future<void> submitAnswer(String answer) async {
    answers.add(answer);
    final index = state.index;
    final current = state.currentItem!;
    state = session(
      status: TutorSessionStatus.grading,
      index: index,
      pending: answer,
    );
    await grading?.future;
    if (failure != null) {
      state = session(
        status: failure!.code == 'TUTOR_DAILY_LIMIT'
            ? TutorSessionStatus.limitReached
            : failure!.code == 'NETWORK_UNAVAILABLE'
            ? TutorSessionStatus.offline
            : TutorSessionStatus.error,
        index: index,
        pending: answer,
      );
      return;
    }
    final attempt = tutorUiAttempt(current, scores: scores, answer: answer);
    attempts.add(attempt);
    state = session(
      status: TutorSessionStatus.feedback,
      index: index,
      attempt: attempt,
    );
  }

  @override
  Future<void> next() async {
    final next = state.index + 1;
    state = session(
      status: next >= total
          ? TutorSessionStatus.completed
          : TutorSessionStatus.answering,
      index: next,
    );
  }

  @override
  Future<void> retry() async {
    retries++;
    if (state.pendingAnswer case final answer?) {
      await submitAnswer(answer);
    } else {
      state = session(status: TutorSessionStatus.answering, index: state.index);
    }
  }

  @override
  void endRound() {
    endings++;
    state = TutorSessionState();
  }
}

class TutorUiHarness {
  TutorUiHarness({FakeTutorSessionController? controller})
    : controller = controller ?? FakeTutorSessionController() {
    addTearDown(() async {
      await client.access.close();
      await db.close();
    });
  }
  final FakeTutorSessionController controller;
  final db = UserDatabase(NativeDatabase.memory());
  final client = FakeTutorClient();
  TutorAvailability availability = TutorAvailability.available;
  int remaining = 2;
  bool premium = false;
  Completer<void>? dependencies;

  List<Override> get overrides => [
    ...accessibilityOverrides(),
    tutorSessionControllerProvider.overrideWith(() => controller),
    tutorAvailabilityProvider.overrideWith((ref) async => availability),
    tutorRemainingFreeTodayProvider.overrideWith(
      (ref) => Stream.value(remaining),
    ),
    selectedContentLanguageProvider.overrideWith(
      (ref) async => controller.item.lang,
    ),
    accountSessionProvider.overrideWith(
      (ref) => Stream.value((id: 'owner', email: 'fixture@example.invalid')),
    ),
    personalLearningClientProvider.overrideWithValue(client.access),
    tutorDependenciesProvider.overrideWith((ref) async {
      await dependencies?.future;
      controller.dependenciesReady = true;
      return TutorDependencies(
        store: TutorStore(db, lang: controller.item.lang),
        client: client,
        verify: () async {},
        premium: () => premium,
        now: () => tutorTestNow,
        newId: () => tutorTestId(500),
      );
    }),
  ];

  Widget app({
    Widget home = const TutorScreen(),
    Brightness brightness = Brightness.dark,
    double scale = 1,
    bool reduced = true,
  }) => testScope(
    accessibilityTestApp(
      home: home,
      brightness: brightness,
      textScale: scale,
      reduceMotion: reduced,
    ),
    premium: premium,
    overrides: overrides,
  );
}

Widget tutorHome() => Scaffold(
  body: HomeScreen(
    onOpenStory: (_) {},
    onBrowseStories: () {},
    onOpenDeck: (_) {},
    onBrowseDecks: () {},
    onSetGoal: (_) {},
    onSettings: () {},
  ),
);

void tutorViewport(
  WidgetTester tester, {
  double width = 390,
  bool keyboard = false,
}) {
  usePhoneViewport(tester, size: Size(width, 844));
  tutorKeyboard(tester, keyboard);
}

void tutorKeyboard(WidgetTester tester, bool open) {
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.padding = FakeViewPadding(top: 47, bottom: open ? 0 : 34);
  tester.view.viewInsets = FakeViewPadding(bottom: open ? 336 : 0);
}

ScrollableState tutorScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const Key('tutor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
