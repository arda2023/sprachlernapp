import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/onboarding/widgets/onboarding_motion.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/widgets/launch_splash.dart';
import 'package:sprachapp/widgets/word_rain.dart';

import '../fixtures/accessibility_fonts.dart';
import '../fixtures/deck_repositories.dart';
import 'accessibility_test_app.dart';

List<String> _spokenLabels(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && !node.isInvisible) {
      final label = node.getSemanticsData().label;
      if (label.isNotEmpty) labels.add(label);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return labels;
}

void main() {
  setUpAll(loadAccessibilityFonts);

  for (final reduceMotion in [false, true]) {
    testWidgets('press feedback respects reduced motion: $reduceMotion', (
      tester,
    ) async {
      usePhoneViewport(tester);
      var taps = 0;
      await tester.pumpWidget(
        accessibilityTestApp(
          reduceMotion: reduceMotion,
          home: Scaffold(
            body: Center(
              child: Pressable(
                label: 'Weiter',
                onTap: () => taps++,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Weiter'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.press(find.text('Weiter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(Pressable),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(
        transform.transform.storage[0],
        closeTo(reduceMotion ? 1 : 0.97, 0.001),
      );
      expect(
        transform.transform.storage[5],
        closeTo(reduceMotion ? 1 : 0.97, 0.001),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cover texture and animated greeting are decorative', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    final wasEnabled = LaunchSplash.enabled;
    LaunchSplash.enabled = true;
    try {
      await tester.pumpWidget(
        accessibilityTestApp(
          textScale: 2,
          home: const Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 120,
                  child: TypeCover(topic: 'DecorativeTopic', tone: 0),
                ),
                WordCycle(words: ['DecorativeGreeting', 'Hello'], height: 100),
                SizedBox(height: 300, child: WordWall(lang: 'en')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labels = _spokenLabels(tester).join(' ');
      expect(labels, contains('Lernsprache wird gewechselt'));
      expect(labels, isNot(contains('DecorativeTopic')));
      expect(labels, isNot(contains('DecorativeGreeting')));
      expect(labels, isNot(contains('Hello')));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      LaunchSplash.enabled = wasEnabled;
      semantics.dispose();
    }
  });

  testWidgets('launch status is spoken once and caption remains accessible', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    final wasEnabled = LaunchSplash.enabled;
    LaunchSplash.enabled = true;
    try {
      await tester.pumpWidget(
        accessibilityTestApp(
          textScale: 2,
          home: const LaunchSplash(caption: 'Inhalte werden vorbereitet'),
        ),
      );
      await tester.pumpAndSettle();
      final labels = _spokenLabels(tester).join(' ');
      expect('Linglossa'.allMatches(labels), hasLength(1));
      expect(labels, contains('Inhalte werden vorbereitet'));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      LaunchSplash.enabled = wasEnabled;
      semantics.dispose();
    }
  });

  testWidgets(
    'paywall restore action scales and reduced route does not slide',
    (tester) async {
      usePhoneViewport(tester);
      final user = TestUser(library: true);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          testScope(
            accessibilityTestApp(
              textScale: 2,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context).push(
                      PaywallScreen.route(
                        plan: (interest: 'Reisen', dailyGoal: 10),
                        onContinue: () {},
                      ),
                    ),
                    child: const Text('Öffnen'),
                  ),
                ),
              ),
            ),
            user: user,
            library: true,
            overrides: accessibilityOverrides(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Öffnen'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(PaywallScreen),
            matching: find.byType(SlideTransition),
          ),
          findsNothing,
        );
        final restore = find.text('Wiederherstellen');
        final style = tester.widget<Text>(restore).style!;
        expect(
          MediaQuery.textScalerOf(tester.element(restore))
              .scale(style.fontSize!),
          closeTo(style.fontSize! * 2, 0.01),
        );
        await tester.pumpAndSettle();
        await expectAccessible(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
        await user.close();
      }
    },
  );

  testWidgets(
    'reader translation hint reaches its final height without motion',
    (tester) async {
      usePhoneViewport(tester);
      final user = TestUser(library: true);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          testScope(
            accessibilityTestApp(
              home: StoryReaderScreen(
                story: sampleStories.first,
                text: sampleStoryText(sampleStories.first.id),
              ),
            ),
            user: user,
            library: true,
          ),
        );
        await tester.pumpAndSettle();
        final heading = find.text(sampleStories.first.title);
        expect(
          tester
              .getSemantics(heading)
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        await tester.tap(find.bySemanticsLabel('Übersetzen'));
        await tester.pump();
        final hint = find.text('Übersetzungsmodus: Tippe auf einen Satz.');
        expect(hint, findsOneWidget);
        final immediate = tester.getRect(hint);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(hint), immediate);
        // Cupertino tap opacity can finish its release after this frame.
        await tester.pumpAndSettle();
        await expectAccessible(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
        await user.close();
      }
    },
  );
}
