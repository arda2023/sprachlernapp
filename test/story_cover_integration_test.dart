import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/streak.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/providers/bundled_stories_provider.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/presentation/story_cover_art.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/presentation/providers/streak_providers.dart';
import 'package:sprachapp/screens/home/home_screen.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/story_cover.dart';

const _surface = ValueKey('story-art-surface');

class _ShippingAssetBundle extends CachingAssetBundle {
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return rootBundle.load(key);
  }
}

// Use the shipping JSON provider and SQLite story summaries. Only unrelated
// Home progress is supplied locally; no Story, cover, bundle or image is mocked.
ProviderContainer _container(String language, DriftContentRepository content) =>
    ProviderContainer(
      overrides: [
        premiumContentAccessProvider.overrideWithValue(true),
        selectedContentLanguageProvider.overrideWith((ref) async => language),
        contentRepositoryProvider.overrideWith((ref) async => content),
        activeContentKeyProvider.overrideWith(
          (ref) async => (
            lang: language,
            generation: 0,
            fingerprint: 'shipping-cover-test',
          ),
        ),
        decksProvider.overrideWith((ref) async => []),
        vocabBreakdownProvider.overrideWith(
          (ref) async =>
              const VocabBreakdown(due: 0, building: 0, mastered: 0, unseen: 0),
        ),
        lexicalBreakdownProvider.overrideWith(
          (ref) => Completer<LexicalBreakdown>().future,
        ),
        learningNowProvider.overrideWith((ref) => DateTime(2026, 11, 1)),
        learningProgressProvider.overrideWith(
          (ref) async => (
            goal: const DailyGoal(done: 0, target: 10),
            week: const WeekProgress([]),
          ),
        ),
        streakProvider.overrideWith((ref) async => StreakSummary.empty),
        wordOfWeekProvider.overrideWith((ref) async => null),
      ],
    );

Widget _host(ProviderContainer container, AssetBundle bundle, Widget screen) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: DefaultAssetBundle(
          bundle: bundle,
          child: RepaintBoundary(
            key: _surface,
            child: Scaffold(body: screen),
          ),
        ),
      ),
    );

Future<void> _expectPaintedArtwork(WidgetTester tester, Finder cover) async {
  final images = find.descendant(of: cover, matching: find.byType(RawImage));
  var ready = false;
  // Let the real bundle and engine codec complete naturally. In particular,
  // precacheImage would hide a broken automatic asset-loading path here.
  for (var i = 0; i < 100; i++) {
    await tester.pump();
    final raw = tester.widgetList<RawImage>(images).toList();
    if (raw.length == 2 && raw.every((image) => image.image != null)) {
      ready = true;
      break;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(ready, isTrue, reason: 'both art layers must decode automatically');

  // A decoded image can still be invisible behind a layer. Inspect the painted
  // middle of the cover, away from text and feathered edges: art has hundreds
  // of colours here, while the category fallback is a smooth gradient.
  final rect = tester.getRect(cover);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_surface),
  );
  final colours = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bytes = data.buffer.asUint8List();
    final unique = <int>{};
    for (
      var y = (rect.top + rect.height * 0.2).ceil();
      y < rect.top + rect.height * 0.45;
      y++
    ) {
      for (
        var x = (rect.left + rect.width * 0.2).ceil();
        x < rect.left + rect.width * 0.8;
        x++
      ) {
        final offset = (y * image.width + x) * 4;
        unique.add(
          (bytes[offset] << 16) | (bytes[offset + 1] << 8) | bytes[offset + 2],
        );
      }
    }
    image.dispose();
    return unique.length;
  }))!;
  expect(colours, greaterThan(250), reason: 'the art must reach the screen');
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final warm in [false, true]) {
    testWidgets(
      '${warm ? 'cached synchronous' : 'cold'} manifest paints shipping art',
      (tester) async {
        final bundled = BundledStory.decode(
          File('assets/content/en/stories.json').readAsStringSync(),
          'en',
        );
        final story = bundled
            .firstWhere((item) => item.story.id == 'library:en:video_04')
            .story;
        final bundle = _ShippingAssetBundle();
        if (warm) {
          await tester.runAsync(
            () => AssetManifest.loadFromAssetBundle(bundle),
          );
          expect(
            AssetManifest.loadFromAssetBundle(bundle),
            isA<SynchronousFuture<AssetManifest>>(),
            reason: 'reproduce the cached bundle path used after font loading',
          );
        }
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: RepaintBoundary(
              key: _surface,
              child: Scaffold(
                body: Center(
                  child: DefaultAssetBundle(
                    bundle: bundle,
                    child: StoryCover(story: story, width: 150, height: 212),
                  ),
                ),
              ),
            ),
          ),
        );
        await _expectPaintedArtwork(tester, find.byType(StoryCover));
        expect(bundle.requested, contains('assets/story_covers/video_04.png'));
        expect(
          bundle.requested.where((key) => key == 'AssetManifest.bin'),
          hasLength(1),
        );
      },
    );
  }

  for (final language in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    testWidgets('$language shipping stories paint on Home and in the library', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final content = DriftContentRepository(
        ContentDatabase.open(
          File('assets/content/$language/content.sqlite'),
          lang: language,
        ),
      );
      final container = _container(language, content);
      // A real platform bundle per test keeps cached futures in this test's
      // FakeAsync zone; the root bundle itself outlives individual tests.
      final bundle = PlatformAssetBundle();
      addTearDown(() async {
        container.dispose();
        await content.close();
      });
      await tester.runAsync(() async {
        await container.read(bundledStoriesProvider.future);
        await container.read(storySummariesProvider.future);
      });
      final stories = container.read(libraryStoriesProvider).requireValue;
      expect(stories.length, language == 'en' ? 58 : 57);
      for (final story in stories) {
        expect(
          storyCoverAssetKey(story.id, story.topic),
          isNotNull,
          reason: story.id,
        );
      }

      await tester.pumpWidget(
        _host(
          container,
          bundle,
          HomeScreen(
            onOpenStory: (_) {},
            onBrowseStories: () {},
            onOpenDeck: (_) {},
            onBrowseDecks: () {},
            onSetGoal: (_) {},
            onSettings: () {},
          ),
        ),
      );
      await tester.pump();
      final homeCover = find.byWidgetPredicate(
        (widget) =>
            widget is StoryCover &&
            widget.story.id == 'library:$language:video_04',
      );
      expect(homeCover, findsOneWidget);
      await _expectPaintedArtwork(tester, homeCover);

      await tester.pumpWidget(
        _host(
          container,
          bundle,
          Consumer(
            builder: (context, ref, _) => StoryLibraryScreen(
              stories: ref.watch(libraryStoriesProvider).requireValue,
              onOpenStory: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      final libraryCover = find.byWidgetPredicate(
        (widget) =>
            widget is StoryCover &&
            widget.story.id == 'library:$language:video_11',
      );
      expect(libraryCover, findsOneWidget);
      await _expectPaintedArtwork(tester, libraryCover);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
