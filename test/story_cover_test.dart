import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/story_category.dart';
import 'package:sprachapp/presentation/story_cover_art.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/widgets/story_cover.dart';

const _asset = 'assets/story_covers/video_04.png';

class _ArtBundle extends CachingAssetBundle {
  _ArtBundle(this.bytes, {this.available = true});
  final Uint8List bytes;
  final bool available;
  final requested = <String>[];
  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        if (available)
          _asset: [
            {'asset': _asset},
          ],
      })!;
    }
    if (key == _asset && available) return ByteData.sublistView(bytes);
    throw StateError('Unexpected asset request: $key');
  }
}

Story _story({
  String id = 'library:en:video_04',
  String topic = 'Wissenschaft',
  ImageProvider? cover,
}) => Story(
  id: id,
  title: 'The rocket launch',
  topic: topic,
  level: 'B1',
  readingMinutes: 4,
  cover: cover,
);

Widget _host(
  Widget child, {
  AssetBundle? bundle,
  Brightness brightness = Brightness.dark,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Scaffold(
    body: Center(
      child: bundle == null
          ? child
          : DefaultAssetBundle(bundle: bundle, child: child),
    ),
  ),
);

Future<Uint8List> _testPng(
  WidgetTester tester, {
  int width = 40,
  int height = 40,
}) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 40, 40),
    Paint()..color = Colors.indigo,
  );
  // A central subject with generous square margins, like the supplied art.
  canvas.drawRect(
    const Rect.fromLTWH(16, 5, 8, 25),
    Paint()..color = Colors.orange,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}))!;

const _libraryLanguages = ['en', 'es', 'it', 'nb', 'pt-BR'];

List<Map<String, dynamic>> _libraryStories() => [
  for (final language in _libraryLanguages)
    for (final story in jsonDecode(
      File('assets/content/$language/stories.json').readAsStringSync(),
    ) as List)
      Map<String, dynamic>.from(story as Map),
];

Set<String> _expectedArtwork() => {
  for (final story in _libraryStories())
    'assets/story_covers/${(story['id'] as String).split(':').last}.png',
  'assets/story_covers/pack_en_open_pocket.png',
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('only inventoried stable IDs map to language-shared art', () {
    for (final language in ['en', 'es', 'it', 'nb', 'pt-BR']) {
      expect(
        storyCoverAssetKey('library:$language:video_04', 'Wissenschaft'),
        _asset,
      );
      expect(
        storyCoverAssetKey('library:$language:video_04', 'Alltag'),
        _asset,
      );
      expect(
        storyCoverAssetKey('library:$language:video_04', 'Wirtschaft'),
        _asset,
      );
    }
    for (final id in [
      'unknown',
      'library:de:video_04',
      'library:en:video_99',
      'library:en:everyday_99',
      '1fe9baf1b1a199b5bfb116e320a679b0',
      'news:video_04',
    ]) {
      expect(storyCoverAssetKey(id, 'Wissenschaft'), isNull);
    }
  });

  test(
    'all 285 library variants and the annotated pack story map to 58 images',
    () {
      final stories = _libraryStories();
      final artwork = <String>{};
      for (final story in stories) {
        final id = story['id'] as String;
        final topic = story['topic'] as String;
        final mapped = storyCoverAssetKey(id, topic);
        final expected = 'assets/story_covers/${id.split(':').last}.png';
        expect(mapped, expected, reason: id);
        expect(_libraryLanguages, contains(id.split(':')[1]), reason: id);
        artwork.add(mapped!);
      }
      expect(stories, hasLength(285));
      expect(artwork, hasLength(57));
      final pack = storyCoverAssetKey(
        '1fe9baf1b1a199b5bfb116e320a679b9',
        'Alltag',
      );
      expect(pack, 'assets/story_covers/pack_en_open_pocket.png');
      artwork.add(pack!);
      expect(artwork, hasLength(58));
    },
  );

  testWidgets(
    'all 58 shipping PNGs are registered and decode from the real asset bundle',
    (tester) async {
      final expected = _expectedArtwork();
      expect(expected, hasLength(58));
      final manifest = (await tester.runAsync(
        () => AssetManifest.loadFromAssetBundle(rootBundle),
      ))!;
      final registered = manifest
          .listAssets()
          .where(
            (key) =>
                key.startsWith('assets/story_covers/') && key.endsWith('.png'),
          )
          .toSet();
      expect(registered, expected);
      for (final key in expected) {
        final bytes = (await tester.runAsync(() => rootBundle.load(key)))!;
        final codec = (await tester.runAsync(
          () => ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          ),
        ))!;
        final frame = (await tester.runAsync(codec.getNextFrame))!;
        expect(frame.image.width, greaterThan(0), reason: key);
        expect(frame.image.height, greaterThan(0), reason: key);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  testWidgets(
    'absent assets preserve the existing cover without failed image loads',
    (tester) async {
      final bundle = _ArtBundle(await _testPng(tester), available: false);
      await tester.pumpWidget(
        _host(
          StoryCover(story: _story(), width: 160, height: 220),
          bundle: bundle,
        ),
      );
      await tester.pump();
      expect(find.byIcon(StoryCategory.science.icon), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(bundle.requested, isNot(contains(_asset)));
      expect(tester.getSize(find.byType(StoryCover)), const Size(160, 220));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('registered asset loads automatically through the shared hook', (
    tester,
  ) async {
    final bundle = _ArtBundle(await _testPng(tester));
    await tester.pumpWidget(
      _host(
        StoryCover(story: _story(), width: 320, height: 196),
        bundle: bundle,
      ),
    );
    await tester.pump();
    final context = tester.element(find.byType(StoryCover));
    await tester.runAsync(
      () => precacheImage(AssetImage(_asset, bundle: bundle), context),
    );
    await tester.pump();
    expect(bundle.requested, contains(_asset));
    expect(
      tester.widgetList<Image>(find.byType(Image)).map((i) => i.fit),
      contains(BoxFit.contain),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'portrait, wide and tablet covers contain the complete square art',
    (tester) async {
      final provider = MemoryImage(await _testPng(tester));
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in [
        const Size(160, 220),
        const Size(340, 128),
        const Size(1024, 196),
      ]) {
        await tester.pumpWidget(
          _host(
            StoryCover(
              story: _story(cover: provider),
              width: size.width,
              height: size.height,
            ),
          ),
        );
        await tester.runAsync(
          () =>
              precacheImage(provider, tester.element(find.byType(StoryCover))),
        );
        await tester.pump();
        final foreground = tester
            .widgetList<Image>(find.byType(Image))
            .singleWhere((i) => i.fit == BoxFit.contain);
        expect(foreground.alignment, Alignment.center);
        expect(tester.getSize(find.byType(StoryCover)), size);
        expect(tester.getSize(find.byWidget(foreground)), size);
        final side = size.shortestSide;
        final imageBounds = tester.getRect(
          find.byKey(const ValueKey('story-cover-contained-art')),
        );
        expect(imageBounds.size, Size(side, side));
        expect(
          imageBounds.center,
          tester.getRect(find.byType(StoryCover)).center,
        );
        final masks = tester.widgetList<ShaderMask>(find.byType(ShaderMask));
        expect(masks, hasLength(2));
        for (final mask in masks) {
          expect(mask.blendMode, BlendMode.dstIn);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'edge blend follows a non-square caller supplied image without cropping',
    (tester) async {
      final provider = MemoryImage(
        await _testPng(tester, width: 80, height: 40),
      );
      await tester.pumpWidget(
        _host(
          StoryCover(story: _story(cover: provider), width: 320, height: 220),
        ),
      );
      await tester.runAsync(
        () => precacheImage(provider, tester.element(find.byType(StoryCover))),
      );
      await tester.pump();
      final imageBounds = tester.getRect(
        find.byKey(const ValueKey('story-cover-contained-art')),
      );
      expect(imageBounds.size, const Size(320, 160));
      expect(
        imageBounds.center,
        tester.getRect(find.byType(StoryCover)).center,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed image decoding returns to the existing category artwork',
    (tester) async {
      final invalid = MemoryImage(Uint8List.fromList([0, 1, 2]));
      await tester.pumpWidget(
        _host(
          StoryCover(story: _story(cover: invalid), width: 160, height: 220),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          invalid,
          tester.element(find.byType(StoryCover)),
          onError: (_, _) {},
        ),
      );
      await tester.pump();
      expect(find.byIcon(StoryCategory.science.icon), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'white card titles and stronger lower scrim survive both themes',
    (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(
            StoryCard(
              story: _story(id: 'unknown'),
              onTap: () {},
              progress: 0.42,
            ),
            brightness: brightness,
          ),
        );
        final title = tester.widget<Text>(find.text('The rocket launch'));
        expect(title.style!.color, Colors.white);
        expect(find.text('42 %'), findsOneWidget);
        final scrim = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('story-cover-title-scrim')),
        );
        final gradient =
            (scrim.decoration as BoxDecoration).gradient! as LinearGradient;
        expect(gradient.colors.last, const Color(0xEB000000));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'continue-reading miniature uses the same story art without changing title',
    (tester) async {
      final story = _story(cover: MemoryImage(await _testPng(tester)));
      // Decode the image before mounting the text-bearing widget. runAsync
      // after mounting also advances google_fonts' platform work, which these
      // layout tests intentionally leave on Flutter's normal test font.
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.runAsync(
        () =>
            precacheImage(story.cover!, tester.element(find.byType(Scaffold))),
      );
      await tester.pumpWidget(
        _host(
          ContinueReadingTile(
            story: story,
            title: story.title,
            meta: story.topic,
            category: StoryCategory.science,
            fraction: 0.42,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(StoryCover), findsOneWidget);
      expect(tester.getSize(find.byType(StoryCover)), const Size(56, 72));
      expect(find.text(story.title), findsOneWidget);
      expect(find.text('42 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
