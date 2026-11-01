import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sprachapp/presentation/audio/device_dictation.dart';

class FakeSpeech extends SpeechToText {
  FakeSpeech() : super.withMethodChannel();
  bool allowed = true;
  int initialized = 0;
  int listens = 0;
  int cancels = 0;
  int stops = 0;
  bool reportsListening = true;
  Completer<bool>? permission;
  Completer<void>? listening;
  final List<String> commands = [];
  List<LocaleName> available = [LocaleName('en_US', 'English')];
  SpeechResultListener? result;
  SpeechStatusListener? status;
  SpeechErrorListener? error;
  SpeechListenOptions? options;
  List<SpeechConfigOption>? config;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    initialized++;
    status = onStatus;
    error = onError;
    config = options;
    return permission == null ? allowed : await permission!.future;
  }

  @override
  Future<List<LocaleName>> locales() async => available;

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
    commands.add('listen');
    result = onResult;
    options = listenOptions;
    await listening?.future;
    if (reportsListening) status?.call(SpeechToText.listeningStatus);
  }

  @override
  Future<void> cancel() async {
    cancels++;
    commands.add('cancel');
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  void emit(String text, {bool finalResult = false}) {
    result?.call(
      SpeechRecognitionResult([
        SpeechRecognitionWords(text, null, 1),
      ], finalResult ? 2 : 0),
    );
  }
}

void main() {
  late FakeSpeech engine;
  late DeviceDictation service;
  late List<String> texts;
  late List<String> errors;
  Future<void> start([String language = 'en']) =>
      service.start(language: language, onText: texts.add, onError: errors.add);
  setUp(() {
    engine = FakeSpeech();
    service = DeviceDictation(
      engine: engine,
      startTimeout: const Duration(milliseconds: 100),
      finalResultTimeout: const Duration(milliseconds: 100),
    );
    texts = [];
    errors = [];
  });
  tearDown(() => service.dispose());

  test(
    'initializes lazily once and disables Bluetooth without billing',
    () async {
      expect(engine.initialized, 0);
      await start();
      expect(
        engine.config,
        containsAll([
          SpeechToText.androidNoBluetooth,
          SpeechToText.iosNoBluetooth,
        ]),
      );
      expect(engine.options!.localeId, 'en_US');
      await service.cancel();
      await start();
      expect(engine.initialized, 1);
    },
  );

  test('permission denial ends state and reports a useful message', () async {
    engine.allowed = false;
    await start();
    expect(service.active, false);
    expect(engine.listens, 0);
    expect(errors.single, contains('Geräteeinstellungen'));
    expect(service.message, errors.single);
  });

  test(
    'native refused start without an event releases the microphone state',
    () async {
      engine.reportsListening = false;
      await start();
      expect(service.active, true);
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(service.active, false);
      expect(errors.single, contains('nicht gestartet'));
      expect(engine.cancels, greaterThan(0));
    },
  );

  test(
    'listening status prevents the start watchdog from ending a session',
    () async {
      await start();
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(service.active, true);
      expect(errors, isEmpty);
    },
  );

  test(
    'a transcript confirms the start even without listening status',
    () async {
      engine.reportsListening = false;
      await start();
      engine.emit('hello');
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(service.active, true);
      expect(texts, ['hello']);
      expect(errors, isEmpty);
    },
  );

  test(
    'native recognition errors release state and allow a fresh tap',
    () async {
      await start();
      engine.error!(SpeechRecognitionError('error_network', true));
      expect(service.active, false);
      expect(errors.single, contains('Verbindung'));
      await start();
      expect(engine.listens, 2);
      expect(service.active, true);
    },
  );

  test('no German fallback and Brazilian Portuguese is strict', () async {
    engine.available = [
      LocaleName('de_DE', 'Deutsch'),
      LocaleName('pt_PT', 'Português'),
    ];
    await start('pt-BR');
    expect(engine.listens, 0);
    expect(errors.single, contains('Lernsprache'));
    engine.available.add(LocaleName('pt_BR', 'Brasil'));
    await start('pt');
    expect(engine.options!.localeId, 'pt_BR');
  });

  test('preferred locales, English fallback, and Norwegian alias', () async {
    engine.available = [
      LocaleName('en_GB', 'English'),
      LocaleName('no_NO', 'Norsk'),
    ];
    await start();
    expect(engine.options!.localeId, 'en_GB');
    await service.cancel();
    await start('nb');
    expect(engine.options!.localeId, 'no_NO');
  });

  test(
    'replaces whole partial transcript, retains accents and inner punctuation',
    () async {
      await start('en');
      engine.emit(' São');
      engine.emit(' São Paulo, café! ', finalResult: true);
      expect(texts, ['São', 'São Paulo, café']);
      expect(service.active, false);
    },
  );

  test('Italian locale stays strict and Spanish prefers Spain', () async {
    engine.available = [
      LocaleName('it_CH', 'Italiano'),
      LocaleName('es_MX', 'Español'),
      LocaleName('es_ES', 'Español'),
    ];
    await start('it');
    expect(engine.listens, 0);
    await start('es');
    expect(engine.options!.localeId, 'es_ES');
  });

  test('finish during permissions prevents a delayed session', () async {
    engine.permission = Completer<bool>();
    final starting = start();
    await Future<void>.delayed(Duration.zero);
    final finishing = service.finish();
    expect(service.active, false);
    engine.permission!.complete(true);
    await starting;
    await finishing;
    expect(engine.listens, 0);
  });

  test('busy start does not replace callbacks or start twice', () async {
    await start();
    await start('es');
    expect(engine.listens, 1);
    engine.emit('hello');
    expect(texts, ['hello']);
  });

  test('cancel during permission request prevents delayed listening', () async {
    engine.permission = Completer<bool>();
    final starting = start();
    await Future<void>.delayed(Duration.zero);
    final cancelling = service.cancel();
    expect(service.active, false);
    engine.permission!.complete(true);
    await starting;
    await cancelling;
    expect(engine.listens, 0);
  });

  test('cancel completes before a queued replacement listen', () async {
    engine.listening = Completer<void>();
    final starting = start();
    await Future<void>.delayed(Duration.zero);
    final cancelling = service.cancel();
    final restarting = start();
    expect(engine.commands, ['listen']);
    engine.listening!.complete();
    await starting;
    await cancelling;
    await restarting;
    expect(engine.commands, ['listen', 'cancel', 'listen']);
    expect(service.active, true);
    expect(errors, isEmpty);
  });

  test(
    'old result cannot overwrite text after cancellation or new session',
    () async {
      await start();
      final oldResult = engine.result;
      await service.cancel();
      await start();
      oldResult!(
        SpeechRecognitionResult([
          const SpeechRecognitionWords('late', null, 1),
        ], 2),
      );
      expect(texts, isEmpty);
      expect(service.active, true);
      engine.emit('current', finalResult: true);
      expect(texts, ['current']);
    },
  );

  test(
    'notListening waits for final result then releases on timeout',
    () async {
      await start();
      engine.status!('notListening');
      expect(service.active, true);
      await Future<void>.delayed(const Duration(milliseconds: 110));
      expect(service.active, false);
      expect(engine.cancels, greaterThan(0));
    },
  );

  test('finish allows final transcript before timeout', () async {
    await start();
    await service.finish();
    expect(engine.stops, 1);
    expect(service.active, true);
    engine.emit('finished.', finalResult: true);
    expect(texts, ['finished']);
    expect(service.active, false);
    await Future<void>.delayed(const Duration(milliseconds: 110));
  });

  test(
    'dispose during permission request prevents callback and listening',
    () async {
      engine.permission = Completer<bool>();
      final starting = start();
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      engine.permission!.complete(true);
      await starting;
      expect(engine.listens, 0);
      expect(texts, isEmpty);
      expect(errors, isEmpty);
    },
  );

  test('provider retains the same idle service for the container lifetime', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = container.read(deviceDictationProvider);
    expect(first.active, false);
    expect(identical(first, container.read(deviceDictationProvider)), true);
  });
}
