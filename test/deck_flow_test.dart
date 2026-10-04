import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/deck_library_screen.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/widgets/form_info_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

const args = (deckId: 'deck-0', kind: DeckSessionKind.learn, size: 5);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late TestUser user;
  setUp(() => user = TestUser());
  tearDown(() => user.close());

  Future<void> practice(
    WidgetTester tester, {
    int size = 5,
    DeckPracticeMode mode = DeckPracticeMode.learn,
  }) async {
    await tester.pumpWidget(
      testScope(
        MaterialApp(
          theme: buildAppTheme(),
          home: DeckPracticeScreen(
            deckId: 'deck-0',
            sessionSize: size,
            mode: mode,
          ),
        ),
        user: user,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> answer(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
  }

  InputDecoration gap(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).decoration!;

  testWidgets('Library → details → repository sentence → summary → progress', (
    tester,
  ) async {
    await tester.pumpWidget(testScope(const SprachApp(), user: user));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mehr ansehen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mehr ansehen'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckLibraryScreen), findsOneWidget);
    expect(find.text('1 aktiv · 1 Stapel'), findsOneWidget);
    await tester.tap(find.text('Allgemeine Sprache'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckDetailsScreen), findsOneWidget);
    expect(
      find.bySemanticsLabel('0 von 5 neuen Wörtern gesehen, 0 Wörter gelernt'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lerne mit diesem Stapel'));
    await tester.pumpAndSettle();
    expect(find.text('Mia geht nach Hause.'), findsOneWidget);
    expect(find.text('Verb, 3. Person Singular'), findsOneWidget);
    expect(find.text('Neues Wort'), findsOneWidget);
    for (final form in ['walks', 'about', 'went', 'a']) {
      await answer(tester, form);
      await next(tester);
    }
    expect(find.text('4 Wörter geübt'), findsOneWidget);
    expect(
      find.text('4 auf Anhieb richtig · 0 zurück auf Stufe 1'),
      findsOneWidget,
    );
    expect(user.records, hasLength(4));
    expect(user.states.values.map((s) => s.box), everyElement(3));
    await tester.tap(find.text('Zurück zum Stapel'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('4 von 5 neuen Wörtern gesehen, 0 Wörter gelernt'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Wrong feedback persists; wrong form and typo keep text; exact saves once',
    (tester) async {
      await practice(tester);
      await tester.tap(find.text('Verb, 3. Person Singular'));
      await tester.pumpAndSettle();
      expect(find.byType(FormInfoSheet), findsOneWidget);
      expect(find.text('Wort-Details ansehen'), findsNothing);
      Navigator.of(tester.element(find.byType(FormInfoSheet))).pop();
      await tester.pumpAndSettle();
      await answer(tester, 'banana');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'banana',
      );
      expect(find.text('Falsch'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await answer(tester, 'walk');
      expect(
        find.text('Andere Form von „walk“ – gesucht: Verb, 3. Person Singular'),
        findsOneWidget,
      );
      expect(gap(tester).hintText, isNull);
      expect(
        gap(tester).fillColor,
        AppColors.memoryLevel2.withValues(alpha: .12),
      );
      expect(gap(tester).filled, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'walk',
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(gap(tester).hintText, isNull);
      await answer(tester, 'wlaks');
      expect(
        find.text('Fast richtig – prüf die Schreibweise.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'wlaks',
      );
      await answer(tester, ' WALKS ');
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(user.records.values.single.errorCount, 2);
      expect(user.records.values.single.boxAfter, 1);
      expect(user.records.values.single.firstAttemptCorrect, isFalse);
      await next(tester);
      expect(find.text('ungefähr'), findsOneWidget);
    },
  );

  testWidgets('Typo → exact is box 3 with first_attempt_correct false', (
    tester,
  ) async {
    await practice(tester, size: 1);
    await answer(tester, 'wlaks');
    await answer(tester, 'walks');
    final record = user.records.values.single;
    expect(record.boxAfter, 3);
    expect(record.errorCount, 0);
    expect(record.firstAttemptCorrect, isFalse);
    await next(tester);
    expect(
      find.text(
        '0 auf Anhieb richtig · 0 zurück auf Stufe 1 · 1 nach Schreibkorrektur',
      ),
      findsOneWidget,
    );
  });

  for (final reveal in [false, true]) {
    testWidgets(
      'Synonym → ${reveal ? 'reveal → ' : ''}exact → repeat, one log',
      (tester) async {
        await practice(tester, size: 1);
        await answer(tester, 'strolls');
        const message =
            'Strolls passt hier auch. Gesucht ist ein anderes Wort: w…';
        expect(find.text(message), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(message)).style!.color,
          AppColors.textMuted,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'strolls',
        );
        expect(gap(tester).filled, isTrue);
        expect(find.text('Weiter'), findsNothing);
        expect(user.records, isEmpty);
        if (reveal) {
          await tester.enterText(find.byType(TextField), '');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Wort erfahren'));
          await tester.pump();
          expect(gap(tester).hintText, 'walks');
          expect(
            gap(tester).hintStyle!.color,
            AppColors.memoryLevel2.withValues(alpha: 0.5),
          );
        }
        await answer(tester, 'walks');
        final record = user.records.values.single;
        expect(record.hintUsed, isTrue);
        expect(record.revealed, reveal);
        expect(record.errorCount, 0);
        expect(record.boxAfter, 1);
        expect(record.dueAtAfter, DateTime(2026, 10, 5));
        await next(tester);
        expect(find.byType(TextField), findsOneWidget);
        await answer(tester, 'walks');
        await next(tester);
        expect(user.records, hasLength(1));
        expect(user.states.values.single.box, 1);
        expect(find.text('1 Wort geübt'), findsOneWidget);
        expect(
          find.text('0 auf Anhieb richtig · 1 zurück auf Stufe 1'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('One-letter target hint has no initial and remains editable', (
    tester,
  ) async {
    await practice(tester);
    await answer(tester, 'walks');
    await next(tester);
    await answer(tester, 'about');
    await next(tester);
    await answer(tester, 'went');
    await next(tester);
    await answer(tester, 'one');
    expect(
      find.text('One passt hier auch. Gesucht ist ein anderes Wort.'),
      findsOneWidget,
    );
    expect(find.text('Weiter'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'one',
    );
  });

  for (final ambiguous in [false, true]) {
    testWidgets(
      'Write failure (${ambiguous ? 'after commit' : 'before commit'}) retries same ID',
      (tester) async {
        user.failures = ambiguous ? 0 : 1;
        user.failAfterWrite = ambiguous;
        await practice(tester, size: 1);
        await answer(tester, 'walks');
        await tester.pumpAndSettle();
        expect(find.text('Speichern wiederholen'), findsOneWidget);
        expect(find.text('Weiter'), findsNothing);
        final scope = ProviderScope.containerOf(
          tester.element(find.byType(DeckPracticeScreen)),
        );
        const one = (deckId: 'deck-0', kind: DeckSessionKind.learn, size: 1);
        expect(
          scope.read(deckSessionControllerProvider(one)).canLeave,
          isFalse,
        );
        await tester.tap(find.text('Speichern wiederholen'));
        await tester.pumpAndSettle();
        expect(user.attempts, hasLength(2));
        expect(user.attempts.toSet(), hasLength(1));
        expect(user.records, hasLength(1));
        await next(tester);
        expect(find.text('1 Wort geübt'), findsOneWidget);
      },
    );
  }

  testWidgets('Double submit / next blocked during write, one review', (
    tester,
  ) async {
    user.writeGate = Completer<void>();
    await practice(tester, size: 1);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DeckPracticeScreen)),
    );
    const one = (deckId: 'deck-0', kind: DeckSessionKind.learn, size: 1);
    final controller = container.read(
      deckSessionControllerProvider(one).notifier,
    );
    await answer(tester, 'walks');
    controller.submit('walks');
    await controller.commit();
    await controller.next();
    expect(user.attempts, hasLength(1));
    expect(
      container.read(deckSessionControllerProvider(one)).canLeave,
      isFalse,
    );
    expect(find.text('Wird gespeichert …'), findsWidgets);
    user.writeGate!.complete();
    await tester.pumpAndSettle();
    await controller.next();
    await controller.next();
    await tester.pumpAndSettle();
    expect(user.records, hasLength(1));
    expect(find.text('1 Wort geübt'), findsOneWidget);
  });

  testWidgets('Revue retains box / due date and rotates sentence', (
    tester,
  ) async {
    user.states['deck-0/0'] = UserCardState(
      cardId: 'deck-0/0',
      box: 4,
      dueAt: testNow.add(const Duration(days: 30)),
    );
    await practice(tester, size: 1, mode: DeckPracticeMode.review);
    await answer(tester, 'walks');
    expect(user.records.values.single.boxAfter, 4);
    expect(
      user.records.values.single.dueAtAfter,
      testNow.add(const Duration(days: 30)),
    );
    await next(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await practice(tester, size: 1, mode: DeckPracticeMode.review);
    await answer(tester, 'walks');
    expect(user.records.values.last.sentenceId, 'deck-0/0/s2');
  });

  testWidgets(
    'Translation stays folded; toolbar follows keyboard and large type fits',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await practice(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlign,
        TextAlign.start,
      );
      expect(
        tester.getTopRight(find.bySemanticsLabel('Wort erfahren')).dx,
        closeTo(378, 1),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Übersetzung:')));
      await tester.pumpAndSettle();
      expect(find.text('Mia geht nach Hause.'), findsNothing);
      await answer(tester, 'walks');
      await next(tester);
      expect(find.text('Es dauert ungefähr eine Stunde.'), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(
        tester.getBottomLeft(find.bySemanticsLabel('Wort erfahren')).dy,
        lessThanOrEqualTo(544),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await answer(tester, 'approximately');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Text>(
              find.text(
                'Approximately passt hier auch. Gesucht ist ein anderes Wort: a…',
              ),
            )
            .maxLines,
        isNull,
      );
    },
  );

  testWidgets(
    'Aborting keeps completed passes only; reentry builds fresh queue',
    (tester) async {
      await tester.pumpWidget(
        testScope(
          MaterialApp(
            theme: buildAppTheme(),
            home: const DeckDetailsScreen(deckId: 'deck-0'),
          ),
          user: user,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lerne mit diesem Stapel'));
      await tester.pumpAndSettle();
      await answer(tester, 'walks');
      await next(tester);
      await answer(tester, 'about');
      await next(tester);
      await answer(tester, 'one');
      await tester.tap(find.bySemanticsLabel('Session beenden'));
      await tester.pumpAndSettle();
      expect(find.byType(DeckDetailsScreen), findsOneWidget);
      expect(user.records, hasLength(2));
      expect(user.states['deck-0/3']!.box, 0);
      await tester.tap(find.text('Lerne mit diesem Stapel'));
      await tester.pumpAndSettle();
      expect(find.text('Verb, Vergangenheit'), findsOneWidget);
      expect(find.textContaining('passt hier auch'), findsNothing);
    },
  );

  for (final reason in ContentUnavailableReason.values) {
    testWidgets('Unavailable pack: ${reason.name}, retry without samples', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWith((ref) async {
              if (attempts++ == 0) throw ContentUnavailable(reason, 'fixture');
              return TestContent();
            }),
            userRepositoryProvider.overrideWith((ref) => user),
          ],
          child: const SprachApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inhalte nicht verfügbar'), findsWidgets);
      expect(find.text('Allgemeine Sprache'), findsNothing);
      expect(find.text('Reisen & Unterwegs'), findsNothing);
      await tester.tap(find.text('Erneut versuchen').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Allgemeine Sprache'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Allgemeine Sprache'), findsOneWidget);
    });
  }

  test(
    'Controller + real user.db survive close / new provider container',
    () async {
      final dir = Directory.systemTemp.createTempSync('deck_flow_');
      final file = File('${dir.path}/user.db');
      Future<void> run({required bool reopened}) async {
        final repo = DriftUserRepository(UserDatabase.file(file), lang: 'en');
        final container = ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWith((ref) => TestContent()),
            userRepositoryProvider.overrideWith((ref) => repo),
            clockProvider.overrideWithValue(() => testNow),
            appInfoProvider.overrideWith((ref) async => 'test+1'),
          ],
        );
        try {
          if (reopened) {
            expect(await repo.activeDeckIds(['deck-0']), isEmpty);
            expect((await repo.cardStates(['deck-0/0']))['deck-0/0']!.box, 3);
            expect(await repo.reviewsFor('deck-0/0'), hasLength(1));
            final decks = await container.read(decksProvider.future);
            expect(decks.single.seenWords, 1);
            expect(decks.single.isActive, isFalse);
          } else {
            final subscription = container.listen(
              deckSessionControllerProvider(args),
              (_, _) {},
            );
            final ready = Completer<void>();
            final listener = container.listen(
              deckSessionControllerProvider(args),
              (_, next) {
                if (!next.loading && next.pass != null && !ready.isCompleted) {
                  ready.complete();
                }
              },
            );
            await ready.future.timeout(const Duration(seconds: 5));
            final controller = container.read(
              deckSessionControllerProvider(args).notifier,
            );
            controller.submit('walks');
            final saved = Completer<void>();
            final saving = container.listen(
              deckSessionControllerProvider(args),
              (_, next) {
                if (next.saved && !saved.isCompleted) saved.complete();
              },
            );
            await saved.future.timeout(const Duration(seconds: 5));
            await container
                .read(deckActiveControllerProvider.notifier)
                .setActive('deck-0', false);
            subscription.close();
            listener.close();
            saving.close();
          }
        } finally {
          container.dispose();
          await repo.close();
        }
      }

      try {
        await run(reopened: false);
        await run(reopened: true);
      } finally {
        dir.deleteSync(recursive: true);
      }
    },
  );
  test('Repository ownership shares connections and waits for close before reopening', () async {
    var opened = 0;
    var closed = 0;
    final closing = Completer<void>();
    final owner = RepositoryOwner<int>(() async => ++opened, (value) async {
      closed++;
      if (value == 1) await closing.future;
    });
    final provider = FutureProvider<int>(owner.acquire, retry: (_, _) => null);
    final first = ProviderContainer();
    final second = ProviderContainer();
    expect(await first.read(provider.future), 1);
    expect(await second.read(provider.future), 1);
    first.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(closed, 0);
    second.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(closed, 1);
    final third = ProviderContainer();
    final reopening = third.read(provider.future);
    await Future<void>.delayed(Duration.zero);
    expect(opened, 1);
    closing.complete();
    expect(await reopening, 2);
    third.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(closed, 2);
  });

  test(
    'Disposal during open closes eventual connection; failed open can retry',
    () async {
      final opening = Completer<int>();
      final closed = Completer<int>();
      final owner = RepositoryOwner<int>(() => opening.future, (value) async {
        closed.complete(value);
      });
      final provider = FutureProvider<int>(
        owner.acquire,
        retry: (_, _) => null,
      );
      final container = ProviderContainer();
      container.read(provider);
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      opening.complete(7);
      expect(await closed.future, 7);
      var attempts = 0;
      final failingOwner = RepositoryOwner<int>(() async {
        if (attempts++ == 0) throw StateError('missing pack');
        return 8;
      }, (_) async {});
      final failingProvider = FutureProvider<int>(
        failingOwner.acquire,
        retry: (_, _) => null,
      );
      final retry = ProviderContainer();
      await expectLater(retry.read(failingProvider.future), throwsStateError);
      retry.invalidate(failingProvider);
      expect(await retry.read(failingProvider.future), 8);
      retry.dispose();
    },
  );

  test('Every repository change refreshes derived counts', () async {
    final container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((ref) => TestContent()),
        userRepositoryProvider.overrideWith((ref) => user),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    final subscription = container.listen(vocabBreakdownProvider, (_, _) {});
    try {
      expect((await container.read(vocabBreakdownProvider.future)).unseen, 5);
      await user.setDeckActive('deck-0', false, now: testNow);
      await Future<void>.delayed(Duration.zero);
      expect((await container.read(vocabBreakdownProvider.future)).unseen, 0);
      await user.setDeckActive('deck-0', true, now: testNow);
      await Future<void>.delayed(Duration.zero);
      expect((await container.read(vocabBreakdownProvider.future)).unseen, 5);
    } finally {
      subscription.close();
      container.dispose();
    }
  });
  test(
    'A failed close never permits pack replacement, even after retries',
    () async {
      var opens = 0;
      final owner = RepositoryOwner<int>(() async => ++opens, (_) async {
        throw StateError('close failed');
      });
      final provider = FutureProvider<int>(
        owner.acquire,
        retry: (_, _) => null,
      );
      final original = ProviderContainer();
      await original.read(provider.future);
      original.dispose();
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 3; i++) {
        final retry = ProviderContainer();
        await expectLater(retry.read(provider.future), throwsStateError);
        retry.dispose();
      }
      expect(opens, 1);
    },
  );
}
