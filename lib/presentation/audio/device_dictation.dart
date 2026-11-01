import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final deviceDictationProvider = Provider<DeviceDictation>((ref) {
  final service = DeviceDictation();
  ref.onDispose(service.dispose);
  return service;
});

/// Short, explicit dictation through the operating system's speech service.
/// Audio is not stored by the app. The system service may require a network.
class DeviceDictation extends ChangeNotifier {
  DeviceDictation({
    SpeechToText? engine,
    this.startTimeout = const Duration(seconds: 5),
    this.finalResultTimeout = const Duration(seconds: 3),
  }) : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;
  final Duration startTimeout;
  final Duration finalResultTimeout;
  Future<void> _commands = Future<void>.value();
  bool _initialized = false;
  bool _active = false;
  bool _disposed = false;
  bool _acceptEvents = false;
  int _revision = 0;
  String? _message;
  ValueChanged<String>? _onText;
  ValueChanged<String>? _onError;
  Timer? _startTimer;
  Timer? _finalTimer;

  bool get active => _active;
  String? get message => _message;

  Future<void> _enqueue(Future<void> Function() command) {
    final next = _commands.then((_) => command());
    _commands = next.catchError((Object _) {});
    return next;
  }

  bool _current(int revision) => !_disposed && _active && revision == _revision;

  Future<void> start({
    required String language,
    required ValueChanged<String> onText,
    required ValueChanged<String> onError,
  }) async {
    if (_disposed || _active) return;
    final revision = ++_revision;
    _active = true;
    _message = null;
    _onText = onText;
    _onError = onError;
    notifyListeners();
    await _enqueue(() async {
      if (!_current(revision)) return;
      try {
        if (!_initialized) {
          _initialized = await _engine.initialize(
            onStatus: _status,
            onError: (error) {
              if (_acceptEvents && _active && !_disposed) {
                _fail(
                  'Die Spracheingabe ist gerade nicht verfügbar. Prüfe Mikrofonfreigabe und Verbindung.',
                );
              }
            },
            options: [
              SpeechToText.androidNoBluetooth,
              SpeechToText.iosNoBluetooth,
            ],
          );
        }
        if (!_current(revision)) return;
        if (!_initialized) {
          _fail(
            'Spracheingabe nicht verfügbar. Erlaube Mikrofon und Spracherkennung in den Geräteeinstellungen.',
          );
          return;
        }
        final locales = await _engine.locales();
        if (!_current(revision)) return;
        final locale = _locale(language, locales);
        if (locale == null) {
          _fail(
            'Für diese Lernsprache ist auf deinem Gerät keine passende Spracherkennung verfügbar.',
          );
          return;
        }
        _acceptEvents = true;
        // speech_to_text 7.5 discards the native listen() boolean. A refused
        // start can therefore complete without a result, status or exception.
        _startTimer = Timer(startTimeout, () {
          if (_current(revision)) {
            _fail(
              'Die Spracheingabe konnte nicht gestartet werden. Versuche es erneut.',
            );
          }
        });
        await _engine.listen(
          onResult: (result) => _result(revision, result),
          listenOptions: SpeechListenOptions(
            localeId: locale,
            listenMode: ListenMode.dictation,
            partialResults: true,
            cancelOnError: true,
            autoPunctuation: false,
            listenFor: const Duration(seconds: 45),
          ),
        );
      } catch (_) {
        if (_current(revision)) {
          _fail(
            'Die Spracheingabe konnte nicht gestartet werden. Versuche es erneut.',
          );
        }
      }
    });
  }

  static String? _locale(String language, List<LocaleName> locales) {
    String normalized(String value) => value.replaceAll('_', '-').toLowerCase();
    final code = normalized(language);
    final base = code.split('-').first;
    final preferred = switch (base) {
      'en' => ['en-us'],
      'es' => ['es-es'],
      'it' => ['it-it'],
      'nb' || 'no' => ['nb-no', 'no-no'],
      'pt' => ['pt-br'],
      _ => <String>[],
    };
    for (final id in preferred) {
      for (final locale in locales) {
        if (normalized(locale.localeId) == id) return locale.localeId;
      }
    }
    if (base == 'en' || base == 'es') {
      for (final locale in locales) {
        if (normalized(locale.localeId).split('-').first == base) {
          return locale.localeId;
        }
      }
    }
    return null;
  }

  void _result(int revision, SpeechRecognitionResult result) {
    if (!_current(revision)) return;
    _startTimer?.cancel();
    _startTimer = null;
    final text = result.recognizedWords
        .trim()
        .replaceFirst(RegExp(r'[.!?…。！？]+$'), '')
        .trimRight();
    if (text.isNotEmpty) _onText?.call(text);
    if (_current(revision) && result.finalResult) {
      unawaited(
        _enqueue(() async {
          await _engine.cancel();
        }).catchError((Object _) {}),
      );
      _end();
    }
  }

  void _status(String status) {
    if (!_active || _disposed || !_acceptEvents) return;
    if (status == SpeechToText.listeningStatus ||
        status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _startTimer?.cancel();
      _startTimer = null;
    }
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _waitForFinal();
    }
  }

  void _waitForFinal() {
    final revision = _revision;
    _finalTimer ??= Timer(finalResultTimeout, () {
      if (!_current(revision)) return;
      unawaited(
        _enqueue(() async {
          await _engine.cancel();
        }).catchError((Object _) {}),
      );
      _end();
    });
  }

  Future<void> finish() async {
    if (!_active || _disposed) return;
    if (!_acceptEvents) return cancel();
    final revision = _revision;
    _waitForFinal();
    await _enqueue(() async {
      if (!_current(revision)) return;
      try {
        await _engine.stop();
      } catch (_) {
        if (_current(revision)) _fail('Die Spracheingabe wurde beendet.');
      }
    });
  }

  Future<void> cancel() async {
    if (_disposed) return;
    ++_revision;
    final cancelling = _enqueue(() async {
      try {
        await _engine.cancel();
      } catch (_) {
        /* Already unavailable. */
      }
    });
    _end();
    await cancelling;
  }

  void _fail(String message) {
    final onError = _onError;
    _message = message;
    unawaited(
      _enqueue(() async {
        await _engine.cancel();
      }).catchError((Object _) {}),
    );
    _end();
    onError?.call(message);
  }

  void _end() {
    _startTimer?.cancel();
    _startTimer = null;
    _finalTimer?.cancel();
    _finalTimer = null;
    _active = false;
    _acceptEvents = false;
    _onText = null;
    _onError = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_revision;
    _end();
    unawaited(
      _enqueue(() async {
        await _engine.cancel();
      }).catchError((Object _) {}),
    );
    super.dispose();
  }
}
