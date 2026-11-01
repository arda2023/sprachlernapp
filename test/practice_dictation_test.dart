import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/audio/device_dictation.dart';
import 'package:sprachapp/presentation/audio/device_speech_playback.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/screens/decks/deck_practice_screen.dart';
import 'package:sprachapp/screens/decks/widgets/practice_chrome.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

const _microphoneKey = ValueKey('practice-dictation');
const _sessionArgs = (deckId: 'deck-0', kind: DeckSessionKind.learn, size: 2);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'mount is permission-free; 44px microphone sits beside sentence audio',
    (tester) async {
      final engine = _SpeechEngine();
      final service = DeviceDictation(engine: engine);
      await _mount(tester, service);

      expect(engine.initializations, 0);
      expect(engine.listens, 0);
      final microphone = find.byKey(_microphoneKey);
      final speaker = find.ancestor(
        of: find.bySemanticsLabel('Satz vorlesen'),
        matching: find.byType(CupertinoButton),
      );
      expect(find.bySemanticsLabel('Antwort sprechen'), findsOneWidget);
      final microphoneRect = tester.getRect(microphone);
      final speakerRect = tester.getRect(speaker);
      expect(microphoneRect.size.width, greaterThanOrEqualTo(44));
      expect(microphoneRect.size.height, greaterThanOrEqualTo(44));
      expect(microphoneRect.center.dy, speakerRect.center.dy);
      expect(microphoneRect.left, speakerRect.right);

      await tester.tap(microphone);
      await tester.pumpAndSettle();
      expect(engine.initializations, 1);
      expect(engine.listens, 1);
      expect(engine.options!.localeId, 'en_US');
      expect(find.bySemanticsLabel('Spracheingabe beenden'), findsOneWidget);
    },
  );

  testWidgets(
    'transcripts replace the answer without submitting or saving; stop permits a final result',
    (tester) async {
      final dictation = _Dictation();
      final user = await _mount(tester, dictation);
      final pass = _state(tester).pass!;
      final target = pass.item.card.form;
      await tester.enterText(find.byType(TextField), 'old answer');
      await tester.pump();
      await tester.tap(find.byKey(_microphoneKey));
      await tester.pumpAndSettle();

      expect(dictation.turns.single.language, pass.item.card.lang);
      expect(_field(tester).focusNode!.hasFocus, isFalse);
      dictation.turns.single.onText('first partial result');
      await tester.pump();
      expect(_answer(tester), 'first partial result');
      dictation.turns.single.onText(target);
      await tester.pump(const Duration(seconds: 2));
      expect(_answer(tester), target);
      expect(_state(tester).pass!.solved, isFalse);
      expect(_state(tester).saved, isFalse);
      expect(user.records, isEmpty);

      await tester.tap(find.byKey(_microphoneKey));
      await tester.pump();
      expect(dictation.finishes, 1);
      dictation.turns.single.onText(target);
      await tester.pump();
      expect(_answer(tester), target);
      expect(user.records, isEmpty);

      await tester.tap(find.text('Eingeben'));
      await tester.pumpAndSettle();
      expect(dictation.cancels, 1);
      expect(_state(tester).pass!.solved, isTrue);
      expect(user.records, hasLength(1));
      expect(find.byKey(_microphoneKey), findsNothing);
    },
  );

  testWidgets(
    'dictation preserves a shared first letter after wrong-answer feedback',
    (tester) async {
      final dictation = _Dictation();
      final user = await _mount(tester, dictation);
      final target = _state(tester).pass!.item.card.form;
      await tester.enterText(
        find.byType(TextField),
        '${target.substring(0, 1)}zzzzz',
      );
      await tester.pump();
      await tester.tap(find.text('Eingeben'));
      await tester.pump();
      expect(_toolbar(tester).error, isTrue);
      expect(_state(tester).pass!.errorCount, 1);

      await tester.tap(find.byKey(_microphoneKey));
      await tester.pumpAndSettle();
      dictation.turns.single.onText(target);
      await tester.pump();
      expect(_answer(tester), target);
      expect(
        _field(tester).controller!.selection,
        TextSelection.collapsed(offset: target.length),
      );
      expect(_toolbar(tester).error, isFalse);
      expect(
        _field(tester).decoration!.fillColor,
        isNot(tester.element(find.byType(TextField)).appColors.errorTint),
      );
      expect(_state(tester).pass!.solved, isFalse);
      expect(user.records, isEmpty);
    },
  );

  testWidgets('manual correction cancels and rejects an obsolete transcript', (
    tester,
  ) async {
    final dictation = _Dictation();
    final user = await _mount(tester, dictation);
    await tester.tap(find.byKey(_microphoneKey));
    await tester.pumpAndSettle();
    final oldTurn = dictation.turns.single;
    oldTurn.onText('walk');
    await tester.pump();
    expect(dictation.cancels, 0);

    await tester.enterText(find.byType(TextField), 'manual correction');
    await tester.pump();
    expect(dictation.cancels, 1);
    expect(dictation.active, isFalse);
    oldTurn.onText('late recognition');
    oldTurn.onError('obsolete error');
    await tester.pump();
    expect(_answer(tester), 'manual correction');
    expect(find.text('obsolete error'), findsNothing);
    expect(user.records, isEmpty);

    await tester.tap(find.byKey(_microphoneKey));
    await tester.pumpAndSettle();
    oldTurn.onText('old session');
    dictation.turns.last.onText('current session');
    await tester.pump();
    expect(_answer(tester), 'current session');
    expect(dictation.active, isTrue);
  });

  testWidgets('submit cancels and old callbacks cannot change the next card', (
    tester,
  ) async {
    final dictation = _Dictation();
    final user = await _mount(tester, dictation);
    final firstPass = _state(tester).pass!.id;
    final target = _state(tester).pass!.item.card.form;
    await tester.tap(find.byKey(_microphoneKey));
    await tester.pumpAndSettle();
    final oldTurn = dictation.turns.single;
    oldTurn.onText(target);
    await tester.pump();
    await tester.tap(find.text('Eingeben'));
    await tester.pumpAndSettle();
    expect(dictation.cancels, 1);
    expect(find.byKey(_microphoneKey), findsNothing);
    oldTurn.onText('late result after submit');
    await tester.pump();
    expect(_answer(tester), target);
    expect(user.records, hasLength(1));

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(_state(tester).pass!.id, isNot(firstPass));
    oldTurn.onText('late result for the previous card');
    await tester.pump();
    expect(_answer(tester), isEmpty);
    expect(_state(tester).pass!.solved, isFalse);
    expect(find.byKey(_microphoneKey), findsOneWidget);
    expect(user.records, hasLength(1));
  });

  testWidgets('reveal cancels and rejects a late transcript', (tester) async {
    final dictation = _Dictation();
    final user = await _mount(tester, dictation);
    await tester.tap(find.byKey(_microphoneKey));
    await tester.pumpAndSettle();
    final oldTurn = dictation.turns.single;
    await tester.tap(find.text('Wort erfahren'));
    await tester.pumpAndSettle();
    expect(dictation.cancels, 1);
    expect(_state(tester).pass!.revealed, isTrue);
    oldTurn.onText('walks');
    await tester.pump();
    expect(_answer(tester), isEmpty);
    expect(_state(tester).pass!.solved, isFalse);
    expect(user.records, isEmpty);
  });

  testWidgets('history cancels an active turn and retains the current answer', (
    tester,
  ) async {
    final dictation = _Dictation();
    await _mount(tester, dictation);
    await tester.enterText(
      find.byType(TextField),
      _state(tester).pass!.item.card.form,
    );
    await tester.pump();
    await tester.tap(find.text('Eingeben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    final currentPass = _state(tester).pass!.id;
    await tester.tap(find.byKey(_microphoneKey));
    await tester.pumpAndSettle();
    final oldTurn = dictation.turns.single;
    oldTurn.onText('draft');
    await tester.pump();
    await tester.fling(find.text('Neues Wort'), const Offset(250, 0), 1000);
    await tester.pumpAndSettle();
    expect(dictation.cancels, 1);
    expect(find.textContaining('Rückblick'), findsOneWidget);
    expect(find.byKey(_microphoneKey), findsNothing);
    oldTurn.onText('obsolete history result');
    await tester.pump();
    expect(_state(tester).pass!.id, currentPass);
    await tester.fling(
      find.textContaining('Rückblick'),
      const Offset(-250, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(_answer(tester), 'draft');
    expect(find.byKey(_microphoneKey), findsOneWidget);
  });

  testWidgets(
    'background and disposal cancel without accepting late callbacks',
    (tester) async {
      final dictation = _Dictation();
      final user = await _mount(tester, dictation);
      await tester.tap(find.byKey(_microphoneKey));
      await tester.pumpAndSettle();
      final backgroundTurn = dictation.turns.single;
      backgroundTurn.onText('draft');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(dictation.cancels, 1);
      backgroundTurn.onText('late background result');
      await tester.pump();
      expect(_answer(tester), 'draft');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.tap(find.byKey(_microphoneKey));
      await tester.pumpAndSettle();
      final disposedTurn = dictation.turns.last;
      await tester.pumpWidget(const SizedBox());
      expect(dictation.cancels, 2);
      expect(dictation.disposals, 1);
      disposedTurn.onText('late disposed result');
      disposedTurn.onError('late disposed error');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(user.records, isEmpty);
    },
  );

  testWidgets('320px toolbar fits microphone and actions at twice text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final hasInput in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              bottomNavigationBar: PracticeAnswerToolbar(
                speakerEnabled: true,
                playing: false,
                onSpeak: () {},
                onDictate: () {},
                dictating: true,
                message:
                    'Sprich das Wort … System-Spracherkennung, ggf. online.',
                solved: false,
                saved: false,
                hasInput: hasInput,
                revealed: false,
                onReveal: () {},
                onSubmit: () {},
                onNext: null,
                nextLabel: 'Weiter',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_microphoneKey)), const Size(44, 44));
      final action = find.bySemanticsLabel(
        hasInput ? 'Eingeben' : 'Wort erfahren',
      );
      expect(action, findsOneWidget);
      expect(tester.getRect(action).right, lessThanOrEqualTo(320));
      expect(
        tester.getRect(action).left,
        greaterThanOrEqualTo(tester.getRect(find.byKey(_microphoneKey)).right),
      );
    }
  });
}

Future<TestUser> _mount(WidgetTester tester, DeviceDictation dictation) async {
  await DeviceSpeechPlayback.resetForTest();
  final user = TestUser();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await user.close();
  });
  await tester.pumpWidget(
    testScope(
      MaterialApp(
        theme: buildAppTheme(),
        home: const DeckPracticeScreen(deckId: 'deck-0', sessionSize: 2),
      ),
      user: user,
      overrides: [
        deviceDictationProvider.overrideWith((ref) {
          ref.onDispose(dictation.dispose);
          return dictation;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return user;
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));
String _answer(WidgetTester tester) => _field(tester).controller!.text;
PracticeAnswerToolbar _toolbar(WidgetTester tester) =>
    tester.widget<PracticeAnswerToolbar>(find.byType(PracticeAnswerToolbar));
DeckSessionState _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DeckPracticeScreen)))
        .read(deckSessionControllerProvider(_sessionArgs));

/// Delivers old callbacks deliberately, so these tests verify the screen's
/// ownership guards independently of the native service's own guards.
class _Dictation extends DeviceDictation {
  _Dictation() : super(engine: _SpeechEngine());
  final turns = <_Turn>[];
  bool _active = false;
  int cancels = 0, finishes = 0, disposals = 0;
  @override
  bool get active => _active;
  @override
  Future<void> start({
    required String language,
    required ValueChanged<String> onText,
    required ValueChanged<String> onError,
  }) async {
    turns.add(_Turn(language, onText, onError));
    _active = true;
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    cancels++;
    _active = false;
    notifyListeners();
  }

  @override
  Future<void> finish() async => finishes++;

  @override
  void dispose() {
    disposals++;
    _active = false;
    super.dispose();
  }
}

class _Turn {
  const _Turn(this.language, this.onText, this.onError);
  final String language;
  final ValueChanged<String> onText, onError;
}

class _SpeechEngine extends SpeechToText {
  _SpeechEngine() : super.withMethodChannel();
  int initializations = 0, listens = 0;
  SpeechListenOptions? options;
  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    initializations++;
    return true;
  }

  @override
  Future<List<LocaleName>> locales() async => [LocaleName('en_US', 'English')];

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    listens++;
    options = listenOptions;
  }

  @override
  Future<void> cancel() async {}
}
