import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import '../fixtures/deck_repositories.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/audio/device_speech_playback.dart';
import 'package:sprachapp/presentation/audio/speech_narration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  final errors = <String>[];
  final controllers = <DeviceSpeechPlayback>[];
  var lang = 'en';
  var voices = <Map<String, Object>>[];
  Completer<void>? voiceGate;
  DeviceSpeechPlayback controller() {
    final c = DeviceSpeechPlayback(language: () => lang, onError: errors.add);
    controllers.add(c);
    return c;
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> event(String method, [Object? args]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter_tts',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, args),
          ),
          (_) {},
        );
    await flush();
  }

  setUp(() async {
    await DeviceSpeechPlayback.resetForTest();
    calls.clear();
    errors.clear();
    lang = 'en';
    voiceGate = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    voices = [
      for (final locale in ['en-US', 'pt-BR', 'nb-NO', 'it-IT', 'es-ES'])
        {
          'identifier': locale,
          'name': locale,
          'locale': locale,
          'gender': 'female',
          'quality': 'enhanced',
          'network_required': '0',
        },
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            await voiceGate?.future;
            return voices;
          }
          return 1;
        });
  });
  tearDown(() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    await DeviceSpeechPlayback.resetForTest();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('all five languages use correct local voice on $platform', () async {
      debugDefaultTargetPlatformOverride = platform;
      final c = controller();
      for (final language in ['en', 'pt-BR', 'nb', 'it', 'es']) {
        lang = language;
        c.play(language, 'Test sentence');
        await flush();
        final selected =
            calls.lastWhere((c) => c.method == 'setVoice').arguments as Map;
        expect(
          selected[platform == TargetPlatform.iOS ? 'identifier' : 'locale'],
          DeviceSpeechPlayback.localeFor(language),
        );
        await event('speak.onComplete');
        expect(c.playing, isNull);
      }
      expect(errors, isEmpty);
      if (platform == TargetPlatform.android) {
        expect(calls.where((c) => c.method == 'setIosAudioCategory'), isEmpty);
      }
    });
  }
  test('Android refuses network-only voices and pt-PT fallback', () {
    expect(
      DeviceSpeechPlayback.selectVoice(
        [
          {'name': 'online', 'locale': 'pt-BR', 'network_required': '1'},
          {'name': 'wrong-region', 'locale': 'pt-PT', 'network_required': '0'},
        ],
        'pt-BR',
        android: true,
      ),
      isNull,
    );
  });
  test('prefers female premium; falls back to available male voice', () {
    final selected = DeviceSpeechPlayback.selectVoice(
      [
        {
          'identifier': 'standard',
          'locale': 'en-US',
          'gender': 'female',
          'quality': 'default',
        },
        {
          'identifier': 'premium',
          'locale': 'en-US',
          'gender': 'female',
          'quality': 'premium',
        },
      ],
      'en',
      android: false,
    );
    expect(selected, {'identifier': 'premium'});
    expect(
      DeviceSpeechPlayback.selectVoice(
        [
          {'identifier': 'male', 'locale': 'it-IT', 'gender': 'male'},
        ],
        'it',
        android: false,
      ),
      {'identifier': 'male'},
    );
  });
  test(
    'rapid changes cancel obsolete pending text across controllers',
    () async {
      voiceGate = Completer<void>();
      final a = controller(), b = controller();
      a.play('a', 'old');
      await flush();
      b.play('b', 'new');
      expect(a.playing, isNull);
      voiceGate!.complete();
      await flush();
      await flush();
      expect(calls.where((c) => c.method == 'speak').map((c) => c.arguments), [
        'new',
      ]);
      a.dispose();
      controllers.remove(a);
      expect(b.playing, 'b');
      b.play('b', 'new');
      await flush();
      expect(b.playing, isNull);
    },
  );
  test(
    'new request on same controller survives older initialization',
    () async {
      voiceGate = Completer<void>();
      final c = controller();
      c.play('old', 'old');
      await flush();
      c.play('new', 'new');
      voiceGate!.complete();
      await flush();
      await flush();
      expect(c.playing, 'new');
      expect(calls.where((c) => c.method == 'speak').map((c) => c.arguments), [
        'new',
      ]);
    },
  );

  testWidgets(
    'deck speaks masked sentence then solved sentence without changing learning state',
    (tester) async {
      await DeviceSpeechPlayback.resetForTest();
      GoogleFonts.config.allowRuntimeFetching = false;
      final user = TestUser();
      await tester.pumpWidget(
        testScope(
          MaterialApp(
            theme: buildAppTheme(),
            home: const DeckPracticeScreen(deckId: 'deck-0'),
          ),
          user: user,
        ),
      );
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.tap(find.bySemanticsLabel('Satz vorlesen'));
      await tester.pumpAndSettle();
      expect(
        calls.where((c) => c.method == 'speak').map((c) => c.arguments).toList(),
        ['Mia  …  home.'],
      );
      await tester.enterText(find.byType(TextField).first, 'walks');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eingeben'));
      await tester.pumpAndSettle();
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter_tts', const StandardMethodCodec().encodeMethodCall(const MethodCall('speak.onComplete')), (_) {});
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Satz vorlesen'));
      await tester.pumpAndSettle();
      expect(
        calls.lastWhere((c) => c.method == 'speak').arguments,
        'Mia walks home.',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(user.close);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test('missing voice shows error without speaking another language', () async {
    voices = [];
    final c = controller();
    c.play('a', 'test');
    await flush();
    expect(errors.single, contains('en-US'));
    expect(c.playing, isNull);
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });
  test('background stops speech', () async {
    final c = controller();
    c.play('a', 'test');
    await flush();
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await flush();
    expect(c.playing, isNull);
    expect(calls.last.method, 'stop');
  });
  test(
    'long narration chunks, pauses and resumes from native progress',
    () async {
      final text = List.filled(700, 'word').join(' ');
      final n = SpeechNarration(
        text: text,
        language: 'en',
        onError: errors.add,
      );
      n.play();
      await flush();
      var spoken = calls.where((c) => c.method == 'speak').toList();
      expect((spoken.last.arguments as String).length, lessThanOrEqualTo(1200));
      await event('speak.onProgress', {
        'text': text.substring(0, 1199),
        'start': '50',
        'end': '54',
        'word': 'word',
      });
      expect(n.progress, greaterThan(0));
      n.pause();
      await flush();
      expect(n.playing, false);
      n.play();
      await flush();
      spoken = calls.where((c) => c.method == 'speak').toList();
      expect(spoken.last.arguments, startsWith(text.substring(50, 60)));
      await event('speak.onComplete');
      expect(n.playing, true);
      n.seek(n.duration);
      await flush();
      expect(n.playing, false);
      n.dispose();
    },
  );
}
