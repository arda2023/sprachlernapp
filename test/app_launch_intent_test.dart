import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/app_launch_intent.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/app_launch_intent_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/app_shell.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final scenario in ['valid', 'other language', 'missing', 'locked']) {
    testWidgets('story widget launch: $scenario', (tester) async {
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          premium: scenario != 'locked',
          overrides: [
            selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
            purchaseProvider.overrideWith(_ReadyPurchases.new),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(
            AppLaunchIntent.story(
              scenario == 'missing' ? 'missing-story' : sampleStories.first.id,
              scenario == 'other language' ? 'it' : 'en',
            ),
          );
      await tester.pumpAndSettle();
      expect(
        find.byType(StoryReaderScreen),
        scenario == 'valid' ? findsOneWidget : findsNothing,
      );
      expect(find.byType(PaywallScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNull);
      expect(tester.takeException(), isNull);
    });
  }

  for (final saved in ['progress', 'empty', 'failure']) {
    testWidgets('story widget waits for persisted reading: $saved', (
      tester,
    ) async {
      final store = _DeferredReadingStore();
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
            purchaseProvider.overrideWith(_ReadyPurchases.new),
            readingStoreProvider.overrideWithValue(store),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(AppLaunchIntent.story(sampleStories.first.id, 'en'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryReaderScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNotNull);

      if (saved == 'failure') {
        store.result.completeError(StateError('Read failed'));
      } else {
        store.result.complete(saved == 'progress' ? _readingJson(0.42) : null);
      }
      await tester.pumpAndSettle();
      expect(container.read(appLaunchIntentProvider), isNull);
      expect(
        find.byType(StoryReaderScreen),
        saved == 'failure' ? findsNothing : findsOneWidget,
      );
      if (saved != 'failure') {
        expect(
          tester
              .widget<StoryReaderScreen>(find.byType(StoryReaderScreen))
              .initialProgress,
          saved == 'progress' ? 0.42 : isNull,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['account', 'language', 'sync', 'empty sync']) {
    testWidgets('story widget rechecks reading after $change changes', (
      tester,
    ) async {
      final oldStore = _DeferredReadingStore();
      final newStore = _DeferredReadingStore();
      var currentStore = oldStore;
      var language = 'en';
      if (change != 'language') {
        oldStore.result.complete(
          change == 'empty sync' ? null : _readingJson(0.42),
        );
      }
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith(
              (ref) async => language,
            ),
            purchaseProvider.overrideWith(_ReadyPurchases.new),
            readingStoreProvider.overrideWith((ref) => currentStore),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      final syncReload = change.endsWith('sync');
      if (syncReload) {
        oldStore.result = Completer<Object?>();
        container.invalidate(readingProgressProvider);
      } else {
        currentStore = newStore;
        container.invalidate(readingStoreProvider);
      }
      if (change == 'language') {
        language = 'it';
        container.invalidate(selectedContentLanguageProvider);
      }
      await tester.pumpAndSettle();
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(AppLaunchIntent.story(sampleStories.first.id, language));
      await tester.pumpAndSettle();
      if (change == 'language') {
        oldStore.result.complete(_readingJson(0.42));
        await tester.pumpAndSettle();
      }
      expect(find.byType(StoryReaderScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNotNull);

      (syncReload ? oldStore : newStore).result.complete(_readingJson(0.73));
      await tester.pumpAndSettle();
      expect(container.read(appLaunchIntentProvider), isNull);
      expect(find.byType(StoryReaderScreen), findsOneWidget);
      expect(
        tester
            .widget<StoryReaderScreen>(find.byType(StoryReaderScreen))
            .initialProgress,
        0.73,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a newer home tap replaces a story waiting for reading', (
    tester,
  ) async {
    final store = _DeferredReadingStore();
    await tester.pumpWidget(
      testScope(
        MaterialApp(theme: buildAppTheme(), home: const AppShell()),
        library: true,
        overrides: [
          selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
          purchaseProvider.overrideWith(_ReadyPurchases.new),
          readingStoreProvider.overrideWithValue(store),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    final controller = container.read(appLaunchIntentProvider.notifier);
    controller.publish(AppLaunchIntent.story(sampleStories.first.id, 'en'));
    await tester.pump();
    expect(container.read(appLaunchIntentProvider), isNotNull);
    controller.publish(const AppLaunchIntent.home());
    await tester.pumpAndSettle();
    expect(container.read(appLaunchIntentProvider), isNull);
    store.result.complete(_readingJson(0.42));
    await tester.pumpAndSettle();
    expect(find.byType(StoryReaderScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('stale consumers cannot discard a newer tap', () {
    final container = ProviderContainer.test();
    final controller = container.read(appLaunchIntentProvider.notifier);
    controller.publish(const AppLaunchIntent.practice());
    final old = container.read(appLaunchIntentProvider)!;
    controller.publish(const AppLaunchIntent.home());
    final current = container.read(appLaunchIntentProvider)!;
    expect(controller.consume(old), isFalse);
    expect(container.read(appLaunchIntentProvider), same(current));
    expect(controller.consume(current), isTrue);
    expect(container.read(appLaunchIntentProvider), isNull);
    expect(controller.consume(current), isFalse);
  });

  testWidgets(
    'a launch waits for language readiness and opens mixed practice once',
    (tester) async {
      final language = Completer<String>();
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith(
              (ref) => language.future,
            ),
          ],
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(const AppLaunchIntent.practice());
      await tester.pump();
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNotNull);

      language.complete('en');
      await tester.pumpAndSettle();
      expect(find.byType(DeckPracticeScreen), findsOneWidget);
      expect(
        tester.widget<DeckPracticeScreen>(find.byType(DeckPracticeScreen)).mode,
        DeckPracticeMode.mixed,
      );
      expect(container.read(appLaunchIntentProvider), isNull);
      Navigator.of(tester.element(find.byType(DeckPracticeScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home fallback dismisses a foreground route without starting practice',
    (tester) async {
      await tester.pumpWidget(
        testScope(
          MaterialApp(theme: buildAppTheme(), home: const AppShell()),
          library: true,
          overrides: [
            selectedContentLanguageProvider.overrideWith((ref) async => 'en'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AppShell));
      final container = ProviderScope.containerOf(context);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      container
          .read(appLaunchIntentProvider.notifier)
          .publish(const AppLaunchIntent.home());
      await tester.pumpAndSettle();
      expect(find.text('Other route'), findsNothing);
      expect(find.byType(DeckPracticeScreen), findsNothing);
      expect(container.read(appLaunchIntentProvider), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReadyPurchases extends PurchaseController {
  @override
  PurchaseState build() => const PurchaseState(phase: PurchasePhase.ready);
}

Map<String, Object?> _readingJson(double fraction) => {
  sampleStories.first.id: ReadingEntry(
    fraction: fraction,
    updatedAt: DateTime(2026, 11, 13),
  ).toJson(),
};

class _DeferredReadingStore implements JsonStore {
  var result = Completer<Object?>();
  @override
  Future<Object?> read() => result.future;
  @override
  Future<void> write(Object? json) async {}
}
