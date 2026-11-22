import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/tutor/tutor_client.dart';
import 'package:sprachapp/domain/premium_offer.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/presentation/providers/tutor_providers.dart';
import 'package:sprachapp/screens/home/widgets/tutor_entry_card.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/onboarding/widgets/account_sheet.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/screens/tutor/tutor_screen.dart';
import 'package:sprachapp/screens/tutor/widgets/tutor_feedback.dart';
import 'package:sprachapp/screens/tutor/widgets/tutor_chrome.dart';
import 'package:sprachapp/screens/tutor/widgets/tutor_info_chip.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/anchored_popover.dart';

import 'fixtures/accessibility_fonts.dart';
import 'fixtures/tutor_ui.dart';

Future<void> snapshotTutor(
  WidgetTester tester,
  String name, {
  Rect? crop,
}) async {
  if (!const bool.fromEnvironment('REVIEW_SCREENSHOTS')) return;
  RenderObject boundary = tester
      .element(find.byType(MaterialApp))
      .renderObject!;
  while (!boundary.isRepaintBoundary) {
    boundary = boundary.parent!;
  }
  await tester.runAsync(() async {
    final image = await (boundary.debugLayer! as OffsetLayer).toImage(
      crop ?? boundary.paintBounds,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await Directory('C:/tmp/linglossa-review/tutor')
        .create(recursive: true);
    await File('${dir.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadAccessibilityFonts);

  for (final brightness in Brightness.values) {
    testWidgets(
      'Home contains exactly one compact tutor entry ${brightness.name}',
      (tester) async {
        tutorViewport(tester);
        final harness = TutorUiHarness();
        await tester.pumpWidget(
          harness.app(home: tutorHome(), brightness: brightness),
        );
        await tester.pumpAndSettle();
        await snapshotTutor(
          tester,
          'home-${brightness.name}',
          crop: tester.getRect(find.byKey(const Key('tutor-entry'))),
        );
        await tester.ensureVisible(find.byType(TutorEntryCard));
        await tester.pumpAndSettle();
        expect(find.byType(TutorEntryCard), findsOneWidget);
        expect(find.text('AI-Tutor'), findsOneWidget);
        expect(find.text('Sätze frei übersetzen'), findsOneWidget);
        expect(find.text('Heute noch 2 Sätze frei'), findsOneWidget);
        expect(find.byType(CupertinoTextField), findsNothing);
        expect(find.byType(TutorFeedback), findsNothing);
        await tester.tap(find.byKey(const Key('tutor-entry')));
        await tester.pumpAndSettle();
        expect(find.byType(TutorScreen), findsOneWidget);
        expect(harness.controller.starts, 1);
      },
    );
  }

  testWidgets(
    'Premium entry omits free allowance; unavailable remains one entry',
    (tester) async {
      tutorViewport(tester);
      final harness = TutorUiHarness()
        ..premium = true
        ..availability = TutorAvailability.unsupportedLanguage;
      await tester.pumpWidget(
        harness.app(home: const Scaffold(body: TutorEntryCard())),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sätze frei'), findsOneWidget); // title only
      expect(find.textContaining('Heute noch'), findsNothing);
      await tester.tap(find.byKey(const Key('tutor-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Noch nicht verfügbar'), findsOneWidget);
      expect(harness.controller.starts, 0);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.byType(TutorScreen), findsNothing);
    },
  );

  for (final (lang, into, inLanguage) in [
    ('en', 'ins Englische', 'auf Englisch'),
    ('pt-BR', 'ins Portugiesische', 'auf Portugiesisch'),
    ('es', 'ins Spanische', 'auf Spanisch'),
    ('it', 'ins Italienische', 'auf Italienisch'),
    ('nb', 'ins Norwegische', 'auf Norwegisch'),
  ]) {
    for (final kind in TutorKind.values) {
      testWidgets('$kind info uses $lang phrase and correct bubble color', (
        tester,
      ) async {
        tutorViewport(tester);
        final harness = TutorUiHarness(
          controller: FakeTutorSessionController(
            item: tutorUiItem(kind: kind, lang: lang),
          ),
        );
        await tester.pumpWidget(harness.app());
        await tester.pumpAndSettle();
        expect(find.textContaining('Übersetze:'), findsNothing);
        await tester.tap(find.byType(TutorInfoChip));
        await tester.pumpAndSettle();
        expect(
          find.text(
            kind == TutorKind.translate
                ? 'Übersetze den Satz unten $into.'
                : 'Wie würdest du in dieser Situation $inLanguage antworten?',
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<PopoverBubble>(find.byType(PopoverBubble)).color,
          kind == TutorKind.translate
              ? AppColors.active
              : AppColors.memoryLevel2,
        );
        if (lang == 'en' && kind == TutorKind.situation) {
          await snapshotTutor(tester, 'situation-blue-popover');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'waits for dependencies before starting and empty input cannot submit',
    (tester) async {
      tutorViewport(tester);
      final harness = TutorUiHarness()..dependencies = Completer<void>();
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 0);
      harness.dependencies!.complete();
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 1);
      final button = tester.widget<TutorActionButton>(
        find.byType(TutorActionButton),
      );
      expect(button.onPressed, isNull);
      await tester.enterText(find.byType(CupertinoTextField), '   ');
      await tester.pump();
      expect(
        tester
            .widget<TutorActionButton>(find.byType(TutorActionButton))
            .onPressed,
        isNull,
      );
      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.textInputAction, TextInputAction.done);
    },
  );

  testWidgets(
    'check closes keyboard, collapses answer, shows all verdicts and ends round',
    (tester) async {
      tutorViewport(tester, keyboard: true);
      final controller = FakeTutorSessionController(total: 1)
        ..grading = Completer<void>();
      final harness = TutorUiHarness(controller: controller);
      await tester.pumpWidget(
        harness.app(
          home: Builder(
            builder: (context) => Scaffold(
              body: CupertinoButton(
                onPressed: () => TutorScreen.open(context),
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.ellipsis_vertical), findsNothing);
      await tester.enterText(
        find.byType(CupertinoTextField),
        'Yesterday I meet my old teacher.',
      );
      await tester.pump();
      final fieldHeight = tester
          .getSize(find.byKey(const Key('tutor-answer-surface')))
          .height;
      final buttonHeight = tester
          .getSize(find.byType(TutorActionButton))
          .height;
      expect(tutorScroll(tester).position.maxScrollExtent, 0);
      final prompt = tester.getRect(find.byKey(const Key('tutor-prompt')));
      final button = tester.getRect(find.byType(TutorActionButton));
      debugPrint(
        'TUTOR LAYOUT keyboard 390×844: inset=336, prompt=$prompt, fieldHeight=$fieldHeight, button=$button, scroll=${tutorScroll(tester).position.maxScrollExtent}',
      );
      expect(button.bottom, lessThanOrEqualTo(508));
      await snapshotTutor(tester, 'answering-keyboard-390');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.byType(TutorThinkingDots), findsOneWidget);
      expect(
        tester.getSize(find.byType(TutorActionButton)).height,
        buttonHeight,
      );
      tutorKeyboard(tester, false);
      await tester.pumpAndSettle();
      await snapshotTutor(tester, 'grading-loading');
      controller.grading!.complete();
      await tester.pumpAndSettle();
      expect(controller.answers, ['Yesterday I meet my old teacher.']);
      expect(find.byType(CupertinoTextField), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('tutor-answer-surface'))).height,
        lessThan(fieldHeight),
      );
      expect(find.byType(TutorPopoverButton), findsNWidgets(4));
      expect(tutorScroll(tester).position.maxScrollExtent, 0);
      final ideal = tester.getRect(find.byKey(const Key('tutor-ideal-answer')));
      debugPrint(
        'TUTOR LAYOUT feedback 390×844: answerHeight=${tester.getSize(find.byKey(const Key('tutor-answer-surface'))).height}, ideal=$ideal, button=${tester.getRect(find.byType(TutorActionButton))}, scroll=${tutorScroll(tester).position.maxScrollExtent}',
      );
      expect(
        ideal.bottom,
        lessThan(tester.getTopLeft(find.byType(TutorActionButton)).dy),
      );
      await snapshotTutor(tester, 'feedback-mixed-verdicts');
      for (final dimension in TutorDimension.values) {
        await tester.tap(find.byKey(ValueKey('tutor-score-${dimension.name}')));
        await tester.pumpAndSettle();
        final score = [2, 1, 0][dimension.index];
        expect(find.text(dimension.explanation(score)), findsOneWidget);
        expect('.'.allMatches(dimension.explanation(score)).length, 1);
        if (dimension == TutorDimension.grammar) {
          await snapshotTutor(tester, 'grammar-verdict-popover');
        }
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Runde geschafft'), findsOneWidget);
      expect(find.text('1 Satz geübt'), findsOneWidget);
      await snapshotTutor(tester, 'round-completed');
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(controller.endings, 2); // initial reset and route exit
    },
  );

  for (final outcome in TutorOutcome.values) {
    testWidgets('feedback tint ${outcome.name}', (tester) async {
      tutorViewport(tester);
      final controller = FakeTutorSessionController()
        ..initialStatus = TutorSessionStatus.feedback
        ..scores = switch (outcome) {
          TutorOutcome.correct => const TutorScores(2, 2, 2),
          TutorOutcome.acceptable => const TutorScores(2, 1, 1),
          TutorOutcome.incorrect => const TutorScores(0, 0, 0),
        };
      await tester.pumpWidget(TutorUiHarness(controller: controller).app());
      await tester.pumpAndSettle();
      final surface = tester.widget<AnimatedContainer>(
        find.byKey(const Key('tutor-answer-surface')),
      );
      expect(
        (surface.decoration! as BoxDecoration).color,
        tutorOutcomeTint(const AppPalette(Brightness.dark), outcome),
      );
      await snapshotTutor(tester, 'feedback-${outcome.name}');
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(
        tester
            .widget<CupertinoTextField>(find.byType(CupertinoTextField))
            .controller!
            .text,
        isEmpty,
      );
    });
  }

  testWidgets('offline retry keeps the submitted answer and one action', (
    tester,
  ) async {
    tutorViewport(tester);
    final controller = FakeTutorSessionController()
      ..failure = const TutorFailure(
        'NETWORK_UNAVAILABLE',
        'Offline',
        uncertain: true,
      );
    await tester.pumpWidget(TutorUiHarness(controller: controller).app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextField),
      'My unchanged answer',
    );
    await tester.pump();
    await tester.tap(find.text('Prüfen'));
    await tester.pumpAndSettle();
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField))
          .readOnly,
      isTrue,
    );
    controller.failure = null;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(controller.retries, 1);
    expect(controller.answers, ['My unchanged answer', 'My unchanged answer']);
    expect(find.byType(TutorFeedback), findsOneWidget);
  });

  for (final fromHome in [true, false]) {
    testWidgets(
      'limit opens contextual tutor paywall from ${fromHome ? 'Home' : 'round'}',
      (tester) async {
        tutorViewport(tester);
        final controller = FakeTutorSessionController()
          ..initialStatus = fromHome
              ? TutorSessionStatus.answering
              : TutorSessionStatus.limitReached
          ..failure = const TutorFailure(
            'TUTOR_DAILY_LIMIT',
            'Limit',
            premiumRequired: true,
          );
        final harness = TutorUiHarness(controller: controller)..remaining = 0;
        await tester.pumpWidget(
          harness.app(
            home: fromHome
                ? const Scaffold(body: TutorEntryCard())
                : const TutorScreen(),
          ),
        );
        await tester.pumpAndSettle();
        if (fromHome) {
          await tester.tap(find.byKey(const Key('tutor-entry')));
          await tester.pumpAndSettle();
        }
        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(find.text(PremiumOfferReason.tutor.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final access in [
    TutorAvailability.accountRequired,
    TutorAvailability.consentRequired,
  ]) {
    testWidgets('missing $access uses existing flow without starting', (
      tester,
    ) async {
      tutorViewport(tester);
      final harness = TutorUiHarness()..availability = access;
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      expect(
        find.byType(
          access == TutorAvailability.accountRequired
              ? AccountSheet
              : SettingsScreen,
        ),
        findsOneWidget,
      );
      expect(harness.controller.starts, 0);
      expect(harness.client.generationRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'layout ${brightness.name} $width scale $scale, keyboard and feedback',
          (tester) async {
            tutorViewport(tester, width: width, keyboard: true);
            final harness = TutorUiHarness();
            await tester.pumpWidget(
              harness.app(brightness: brightness, scale: scale),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final button = tester.getRect(find.byType(TutorActionButton));
            expect(button.bottom, lessThanOrEqualTo(508));
            if (scale == 1) {
              expect(tutorScroll(tester).position.maxScrollExtent, 0);
            }
            await tester.enterText(
              find.byType(CupertinoTextField),
              'Yesterday I meet my old teacher.',
            );
            await tester.pump();
            await tester.tap(find.text('Prüfen'));
            tutorKeyboard(tester, false);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(TutorFeedback), findsOneWidget);
            if (scale == 1) {
              expect(tutorScroll(tester).position.maxScrollExtent, 0);
              expect(
                tester
                    .getBottomLeft(find.byKey(const Key('tutor-ideal-answer')))
                    .dy,
                lessThan(tester.getTopLeft(find.byType(TutorActionButton)).dy),
              );
            } else {
              expect(tutorScroll(tester).position.pixels, greaterThan(0));
            }
            if (brightness == Brightness.dark && (scale == 2 || width == 320)) {
              await snapshotTutor(
                tester,
                'feedback-${width.toInt()}-scale-$scale',
              );
            }
          },
        );
      }
    }
  }

  testWidgets(
    'reduced motion is static while loading and reveals verdicts immediately',
    (tester) async {
      tutorViewport(tester);
      final controller = FakeTutorSessionController()
        ..grading = Completer<void>();
      await tester.pumpWidget(TutorUiHarness(controller: controller).app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), 'My answer');
      await tester.pump();
      await tester.tap(find.text('Prüfen'));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.grading!.complete();
      await tester.pumpAndSettle();
      for (final paint in tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      )) {
        if (paint.painter case final TutorVerdictPainter painter) {
          expect(painter.progress, 1);
        }
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('motion staggers drawn symbols and fades feedback', (
    tester,
  ) async {
    tutorViewport(tester);
    final controller = FakeTutorSessionController()
      ..grading = Completer<void>();
    await tester.pumpWidget(
      TutorUiHarness(controller: controller).app(reduced: false),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'My answer');
    await tester.pump();
    await tester.tap(find.text('Prüfen'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.binding.hasScheduledFrame, isTrue);
    controller.grading!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final paints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<TutorVerdictPainter>()
        .toList();
    expect(paints, hasLength(3));
    expect(paints[0].progress, greaterThan(paints[1].progress));
    expect(paints[1].progress, greaterThan(paints[2].progress));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'restored uncertain answer is read-only and resubmitted unchanged',
    (tester) async {
      tutorViewport(tester);
      final controller = FakeTutorSessionController()
        ..restoredAnswer = 'My saved answer';
      await tester.pumpWidget(TutorUiHarness(controller: controller).app());
      await tester.pumpAndSettle();
      final field = tester.widget<CupertinoTextField>(
        find.byType(CupertinoTextField),
      );
      expect(field.readOnly, isTrue);
      expect(field.controller!.text, 'My saved answer');
      await tester.tap(find.text('Prüfen'));
      await tester.pumpAndSettle();
      expect(controller.answers, ['My saved answer']);
    },
  );

  testWidgets('error retries explicitly and never submits on its own', (
    tester,
  ) async {
    tutorViewport(tester);
    final controller = FakeTutorSessionController()
      ..initialStatus = TutorSessionStatus.error
      ..failure = const TutorFailure(
        'MODEL_INVALID',
        'Die Antwort konnte nicht geprüft werden.',
      );
    await tester.pumpWidget(TutorUiHarness(controller: controller).app());
    await tester.pumpAndSettle();
    expect(
      find.text('Die Antwort konnte nicht geprüft werden.'),
      findsOneWidget,
    );
    expect(controller.retries, 0);
    expect(controller.answers, isEmpty);
    controller.failure = null;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(controller.retries, 1);
    expect(find.text('Prüfen'), findsOneWidget);
  });

  testWidgets(
    'dependency failure can be retried after initialization recovers',
    (tester) async {
      tutorViewport(tester);
      final harness = TutorUiHarness()..dependencies = Completer<void>();
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      harness.dependencies!.completeError(
        StateError('Local storage unavailable'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(harness.controller.starts, 0);
      harness.dependencies = null;
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 1);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    },
  );

  testWidgets(
    'session invalidation hides the old answer and allows access recheck',
    (tester) async {
      tutorViewport(tester);
      final harness = TutorUiHarness();
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextField),
        'Old account answer',
      );
      harness.controller.emit(TutorSessionState());
      await tester.pumpAndSettle();
      expect(find.text('Zugang prüfen'), findsOneWidget);
      expect(find.text('Old account answer'), findsNothing);
      await tester.tap(find.text('Zugang prüfen'));
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 2);
      expect(
        tester
            .widget<CupertinoTextField>(find.byType(CupertinoTextField))
            .controller!
            .text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'unavailable controller state rechecks access and starts a fresh round',
    (tester) async {
      tutorViewport(tester);
      final controller = FakeTutorSessionController()
        ..initialStatus = TutorSessionStatus.unavailable;
      await tester.pumpWidget(TutorUiHarness(controller: controller).app());
      await tester.pumpAndSettle();
      expect(find.text('Zugang prüfen'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNothing);
      controller.initialStatus = TutorSessionStatus.answering;
      await tester.tap(find.text('Zugang prüfen'));
      await tester.pumpAndSettle();
      expect(controller.starts, 2);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    },
  );

  testWidgets(
    'returning from existing consent settings resumes only with consent',
    (tester) async {
      tutorViewport(tester);
      final harness = TutorUiHarness()
        ..availability = TutorAvailability.consentRequired;
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 0);
      expect(find.text('Freigabe öffnen'), findsOneWidget);
      await tester.tap(find.text('Freigabe öffnen'));
      await tester.pumpAndSettle();
      harness.availability = TutorAvailability.available;
      Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pumpAndSettle();
      expect(harness.controller.starts, 1);
    },
  );

  testWidgets('leaving during startup never starts a round afterward', (
    tester,
  ) async {
    tutorViewport(tester);
    final harness = TutorUiHarness()..dependencies = Completer<void>();
    await tester.pumpWidget(
      harness.app(home: const Scaffold(body: TutorEntryCard())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tutor-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pump();
    harness.dependencies!.complete();
    await tester.pumpAndSettle();
    expect(harness.controller.starts, 0);
    expect(find.byType(TutorScreen), findsNothing);
  });

  testWidgets('premium fair-use limit finishes without opening an offer', (
    tester,
  ) async {
    tutorViewport(tester);
    final controller = FakeTutorSessionController()
      ..initialStatus = TutorSessionStatus.limitReached
      ..failure = const TutorFailure('TUTOR_DAILY_LIMIT', 'Limit');
    final harness = TutorUiHarness(controller: controller)..premium = true;
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('Fertig'), findsOneWidget);
  });
}
