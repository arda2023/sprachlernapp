import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_activity.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/deck_details_screen.dart';
import 'package:sprachapp/screens/decks/widgets/practice_chrome.dart';
import 'package:sprachapp/screens/decks/widgets/translation_bubble.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

class GoalContent extends TestContent {
  GoalContent() : super(library: true);
  @override
  PracticeItem item(String id) {
    final base = super.item(id);
    return PracticeItem(
      card: ContentCard(
        id: id,
        lang: 'en',
        form: 'word-$id',
        formNorm: 'word-$id',
        lemmaId: 'unique-$id',
        lemma: 'unique-$id',
        pos: 'NOUN',
        translationDe: base.card.translationDe,
      ),
      sentences: base.sentences,
      otherFormsOfLemma: base.otherFormsOfLemma,
    );
  }
}

class DelayedToggleUser extends TestUser {
  final gate = Completer<void>();
  final writes = <bool>[];
  bool fail = false;
  @override
  Future<void> setDeckActive(
    String id,
    bool value, {
    required DateTime now,
  }) async {
    await gate.future;
    writes.add(value);
    if (fail) throw StateError('disk full');
    await super.setDeckActive(id, value, now: now);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (const bool.fromEnvironment('UI_SCREENSHOTS')) {
      final families = <String, String>{};
      for (final weight in FontWeight.values) {
        families[AppType.chrome(weight: weight).fontFamily!] =
            '/System/Library/Fonts/Supplemental/Arial.ttf';
        families[AppType.editorial(weight: weight).fontFamily!] =
            '/System/Library/Fonts/Supplemental/Georgia.ttf';
      }
      families['packages/cupertino_icons/CupertinoIcons'] = 'build/unit_test_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf';
      families['MaterialIcons'] =
          'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
      for (final entry in families.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            File(entry.value)
                .readAsBytes()
                .then((b) => ByteData.sublistView(b)),
          );
        await loader.load();
      }
    }
  });

  test('global remaining goal survives restart, duplicate saves, modes and local day', () async {
    final dir = Directory.systemTemp.createTempSync('goal-isolated-');
    final file = File('${dir.path}/user.db');
    var user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    var now = DateTime(2026, 10, 25, 12);
    final content = GoalContent();
    Future<void> record(
      String id,
      String pass, {
      ReviewMode mode = ReviewMode.deck,
    }) async {
      await user.ensureCards([id], now: now, origin: CardOrigin.deck);
      final before = (await user.cardStates([id]))[id]!;
      final r = ReviewRecord(
        id: pass,
        cardId: id,
        createdAt: now,
        mode: mode,
        sentenceId: '$id/s1',
        firstAttemptCorrect: true,
        errorCount: 0,
        revealed: false,
        hintUsed: false,
        boxBefore: before.box,
        boxAfter: 3,
        dueAtAfter: now.add(const Duration(days: 7)),
        responseMs: 20,
        appVersion: 'test',
        deviceId: 'isolated',
      );
      expect(await user.recordReview(r), isTrue);
      expect(await user.recordReview(r), isFalse);
    }

    await user.savePreferences(const PracticePreferences(dailyGoal: 20));
    final ids = (await content.allCardIds()).toList();
    for (var i = 0; i < 12; i++) {
      await record(ids[i], 'pass-$i');
    }
    await record(ids[0], 'same-target');
    await record(ids[12], 'revue', mode: ReviewMode.revue);
    ProviderContainer scope() => ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => content),
        userRepositoryProvider.overrideWith((_) => user),
        clockProvider.overrideWithValue(() => now),
        appInfoProvider.overrideWith((_) async => 'test'),
      ],
    );
    var c = scope();
    Future<DeckSessionState> start({
      String deck = '',
      DeckSessionKind kind = DeckSessionKind.mixed,
    }) async {
      final p = deckSessionControllerProvider((
        deckId: deck,
        kind: kind,
        size: 0,
      ));
      final sub = c.listen(p, (_, _) {});
      for (var i = 0; i < 100 && c.read(p).loading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final s = c.read(p);
      expect(s.error, isNull);
      sub.close();
      return s;
    }

    // 12 passes plus one Revue target; the repeated same target counts once.
    expect((await c.read(learningProgressProvider.future)).goal.done, 13);
    expect((await start()).total, 7);
    await user.ensureCards(
      ['deck-5/2', 'deck-5/3'],
      now: now,
      origin: CardOrigin.deck,
    );
    await user.setCardFlags('deck-5/2', disabled: true);
    await user.setCardFlags('deck-5/3', disabled: true);
    c.dispose();
    c = scope();
    expect((await start(deck: 'deck-5', kind: DeckSessionKind.learn)).total, 3);
    c.dispose();
    await user.close();
    user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    c = scope();
    expect((await start()).total, 7);
    await user.savePreferences(const PracticePreferences(dailyGoal: 12));
    c.dispose();
    c = scope();
    // Goal reached: Play opens the voluntary continuation directly (no empty
    // session) and never offers today's completed targets as normal tasks.
    final reached = await start();
    expect(reached.goalReached, isTrue);
    expect(reached.total, 12);
    expect(ids.take(13), isNot(contains(reached.pass!.item.card.id)));
    now = DateTime(2026, 10, 26, 0, 1);
    c.dispose();
    c = scope();
    expect((await c.read(learningProgressProvider.future)).goal.done, 0);
    expect((await start()).total, 12);
    c.dispose();
    await user.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'local date grouping counts every mode once, Revue included, and deduplicates exact exercise IDs',
    () {
      final day = DateTime(2026, 3, 29);
      final days = completedTargetsByDay([
        ReviewActivity('form-a', day, ReviewMode.deck),
        ReviewActivity(
          'form-a',
          day.add(const Duration(hours: 2)),
          ReviewMode.mixed,
        ),
        ReviewActivity('form-b', day, ReviewMode.deck),
        ReviewActivity('revue', day, ReviewMode.revue),
        ReviewActivity('next', DateTime(2026, 3, 30), ReviewMode.deck),
      ]);
      expect(days[day], {'form-a', 'form-b', 'revue'});
      expect(days[DateTime(2026, 3, 30)], {'next'});
    },
  );

  test('repeated start, preference change and midnight retain current unsaved pass', () async {
    final user = TestUser();
    var now = testNow;
    final c = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWith((_) => TestContent()),
        userRepositoryProvider.overrideWith((_) => user),
        clockProvider.overrideWithValue(() => now),
        appInfoProvider.overrideWith((_) async => 'test'),
      ],
    );
    final p = deckSessionControllerProvider((
      deckId: 'deck-0',
      kind: DeckSessionKind.learn,
      size: 0,
    ));
    final sub = c.listen(p, (_, _) {});
    for (var i = 0; i < 100 && c.read(p).loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final pass = c.read(p).pass!;
    final controller = c.read(p.notifier);
    await controller.start();
    expect(identical(c.read(p).pass, pass), isTrue);
    await user.savePreferences(const PracticePreferences(dailyGoal: 1));
    now = DateTime(now.year, now.month, now.day + 1);
    c.invalidate(learningNowProvider);
    await c.pump();
    expect(identical(c.read(p).pass, pass), isTrue);
    sub.close();
    await c.pump();
    expect(user.records, isEmpty);
    c.dispose();
    await user.close();
  });

  testWidgets(
    'toggle stays visible, orders rapid writes and rolls back failures',
    (tester) async {
      final user = DelayedToggleUser();
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
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(DeckDetailsScreen)),
      );
      final controller = scope.read(deckActiveControllerProvider.notifier);
      final first = controller.setActive('deck-0', false);
      await tester.pump();
      expect(
        tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isFalse,
      );
      expect(find.text('In die tägliche Übung'), findsOneWidget);
      final second = controller.setActive('deck-0', true);
      final third = controller.setActive('deck-0', false);
      user.gate.complete();
      await Future.wait([first, second, third]);
      await tester.pumpAndSettle();
      expect(user.writes, [false, true, false]);
      expect(user.active['deck-0'], isFalse);
      user.fail = true;
      await controller.setActive('deck-0', true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isFalse,
      );
      expect(
        find.text('Aktivierung nicht gespeichert. Wiederholen'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await user.close();
    },
  );

  testWidgets(
    'reveal type erase whitespace reveal preserves one assisted review',
    (tester) async {
      final user = TestUser();
      final boundary = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testScope(
          MaterialApp(
            theme: buildAppTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 1),
            ),
          ),
          user: user,
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Wort erfahren'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'wa');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), i == 2 ? '  ' : '');
        await tester.pumpAndSettle();
        expect(find.text('Wort erfahren'), findsOneWidget);
        expect(user.records, isEmpty);
      }
      await tester.tap(find.text('Wort erfahren'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'walks');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eingeben'));
      await tester.pumpAndSettle();
      expect(user.records.length, 1);
      expect(user.records.values.single.revealed, isTrue);
      expect(user.records.values.single.firstAttemptCorrect, isFalse);
      final field = tester.widget<TextField>(find.byType(TextField));
      final colors = tester.element(find.byType(TextField)).appColors;
      expect(field.style!.color, colors.success);
      expect(field.decoration!.fillColor, colors.successTint);
      expect(find.byKey(const ValueKey('practice-success')), findsOneWidget);
      final action = find.bySemanticsLabel('Weiter');
      expect(tester.getSize(action).height, 40); // User-adjusted action slot.
      await screenshot(tester, boundary, 'success-compact');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(544));
      expect(tester.takeException(), isNull);
      await screenshot(tester, boundary, 'success-large-keyboard');
      await tester.pumpWidget(const SizedBox());
      await user.close();
    },
  );

  testWidgets(
    'loading is not completion; bubble is content sized and bounded at large text with keyboard',
    (tester) async {
      final boundary = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.view.resetPhysicalSize());
      Future<void> show(String text, double scale, double keyboard) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(390, 844),
                padding: const EdgeInsets.only(top: 44, bottom: 34),
                viewInsets: EdgeInsets.only(bottom: keyboard),
                textScaler: TextScaler.linear(scale),
              ),
              child: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Stack(
                    children: [
                      Positioned(
                        top: 44,
                        left: 0,
                        right: 0,
                        child: PracticeSessionBar(
                          done: 0,
                          total: 0,
                          loading: true,
                          onHome: () {},
                          onMenu: null,
                        ),
                      ),
                      TranslationBubble(
                        anchor: const Rect.fromLTWH(350, 480, 30, 30),
                        text: text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show('nach', 1, 0);
      expect(find.text('Alle Übungen geübt'), findsNothing);
      final bubble = find.byKey(const ValueKey('translation-bubble'));
      // Content sized: the word, the speaker button and the bubble's insets.
      expect(tester.getSize(bubble).width, lessThan(160));
      expect(tester.getSize(find.text('nach')).height, lessThan(30));
      await screenshot(tester, boundary, 'bubble-short');
      await show(
        'Eine längere Übersetzung mit mehreren Wörtern und Umbruch',
        2,
        300,
      );
      final rect = tester.getRect(bubble);
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(374));
      expect(rect.top, greaterThanOrEqualTo(52));
      expect(rect.bottom, lessThanOrEqualTo(536));
      expect(tester.takeException(), isNull);
      await screenshot(tester, boundary, 'bubble-large-keyboard');
    },
  );
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('UI_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('docs/evidence/learning-ui-device-fixes')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
