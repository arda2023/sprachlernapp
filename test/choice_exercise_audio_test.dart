import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/practice_models.dart';
import 'package:sprachapp/presentation/audio/device_speech_playback.dart';
import 'package:sprachapp/screens/practice/choice_exercise_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/playback_controls.dart';
import 'package:sprachapp/widgets/speak_button.dart';
import 'package:sprachapp/widgets/success_feedback_card.dart';

void main() {
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  const locales = {
    'en': 'en-US',
    'pt-BR': 'pt-BR',
    'nb': 'nb-NO',
    'it': 'it-IT',
    'es': 'es-ES',
  };

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() async {
    await DeviceSpeechPlayback.resetForTest();
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              for (final locale in locales.values)
                {'identifier': 'test.$locale', 'locale': locale},
            ];
          }
          return 1;
        });
  });
  tearDown(() async {
    await DeviceSpeechPlayback.resetForTest();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  ChoiceExercise exercise(PracticeKind kind, {String language = 'en'}) =>
      ChoiceExercise(
        id: '$kind-$language',
        kind: kind,
        title: 'Eine Übung',
        summary: '',
        topic: 'Alltag',
        level: 1,
        prompt: kind == PracticeKind.grammar ? 'I ___ here.' : 'Was hörst du?',
        options: const ['live', 'lives'],
        answer: 'live',
        explanation: 'Die passende Form.',
        audioText: kind == PracticeKind.listening ? 'I live here.' : null,
        targetLanguage: language,
      );

  Future<void> showExercise(
    WidgetTester tester,
    ChoiceExercise exercise,
    PracticeProgress progress,
  ) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        home: ChoiceExerciseScreen(exercise: exercise, progress: progress),
      ),
    ),
  );

  testWidgets(
    'listening has centered standalone playback without track or times',
    (tester) async {
      await DeviceSpeechPlayback.resetForTest();
      final progress = PracticeProgress();
      addTearDown(progress.dispose);
      await showExercise(tester, exercise(PracticeKind.listening), progress);

      final play = find.byType(PlayPauseButton);
      expect(play, findsOneWidget);
      expect(find.byType(PlaybackTrack), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.textContaining(RegExp(r'\d+:\d\d')), findsNothing);
      expect(find.byType(SpeakButton), findsNothing);
      expect(
        tester.getCenter(play).dx,
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      );
      expect(tester.getSize(play), const Size(72, 72));
      expect(
        find.ancestor(
          of: play,
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.decoration != null,
          ),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Abspielen'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Abspielen'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
      expect(
        calls.where((call) => call.method == 'speak').single.arguments,
        'I live here.',
      );

      await tester.tap(find.bySemanticsLabel('Pause'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Abspielen'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Abspielen'));
      await tester.pump();
      await tester.pumpAndSettle();
      final stopsBeforeCorrect = calls
          .where((call) => call.method == 'stop')
          .length;
      await tester.tap(find.text('live'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Abspielen'), findsOneWidget);
      expect(find.byType(SuccessFeedbackCard), findsOneWidget);
      expect(
        calls.where((call) => call.method == 'stop').length,
        greaterThan(stopsBeforeCorrect),
      );
      expect(progress.isDone(exercise(PracticeKind.listening).id), isTrue);
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final language in locales.keys) {
    testWidgets(
      'grammar $language exposes completed sentence audio only on success',
      (tester) async {
        await DeviceSpeechPlayback.resetForTest();
        final progress = PracticeProgress();
        addTearDown(progress.dispose);
        final item = exercise(PracticeKind.grammar, language: language);
        await showExercise(tester, item, progress);
        expect(find.byType(SpeakButton), findsNothing);
        expect(find.byType(PlayPauseButton), findsNothing);
        expect(calls.where((call) => call.method == 'speak'), isEmpty);

        await tester.tap(find.text('lives'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(SpeakButton), findsNothing);
        expect(progress.isDone(item.id), isFalse);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));
        expect(find.byType(SpeakButton), findsNothing);

        await tester.tap(find.text('live'));
        await tester.pumpAndSettle();
        final speak = find.byType(SpeakButton);
        expect(speak, findsOneWidget);
        final button = tester.widget<SpeakButton>(speak);
        expect(button.text, 'I live here.');
        expect(button.text, isNot(contains(ChoiceExercise.gap)));
        expect(button.language, language);
        expect(progress.isDone(item.id), isTrue);
        final sentence = find.bySemanticsLabel('I live here.');
        expect(tester.getTopLeft(speak).dy, tester.getTopLeft(sentence).dy);
        expect(
          tester.getTopLeft(speak).dx,
          greaterThanOrEqualTo(tester.getTopRight(sentence).dx),
        );
        expect(tester.getSize(speak).shortestSide, greaterThanOrEqualTo(44));

        await tester.ensureVisible(speak);
        await tester.tap(speak);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(
          calls.where((call) => call.method == 'speak').single.arguments,
          'I live here.',
        );
        expect(
          calls.where((call) => call.method == 'setVoice').single.arguments,
          containsPair('identifier', 'test.${locales[language]}'),
        );
        debugDefaultTargetPlatformOverride = null;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
