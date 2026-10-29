import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/speech_playback.dart';

void showSpeechError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// One native synthesizer across every surface. Controllers own only their turn.
class DeviceSpeechPlayback extends SpeechPlayback with WidgetsBindingObserver {
  DeviceSpeechPlayback({
    required this.language,
    required this.onError,
    this.onComplete,
    this.onProgress,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  final String? Function() language;
  final ValueChanged<String> onError;
  final VoidCallback? onComplete;
  final void Function(int start, int end)? onProgress;
  static FlutterTts? _engine;
  static Future<void> _commands = Future.value();
  static DeviceSpeechPlayback? _owner, _pending;
  static int _revision = 0;
  static String? _configuredLanguage;
  String? _key;
  bool _disposed = false;
  @override
  String? get playing => _key;
  @override
  bool isPlaying(String key) => _key == key;

  static String localeFor(String lang) => switch (lang) {
    'en' => 'en-US',
    'nb' => 'nb-NO',
    'it' => 'it-IT',
    'es' => 'es-ES',
    'de' => 'de-DE',
    _ => lang,
  };
  static Map<String, String>? selectVoice(
    List<dynamic> voices,
    String lang, {
    required bool android,
  }) {
    final locale = localeFor(lang);
    String normalize(Object? value) => value.toString().replaceAll('_', '-');
    bool matches(Map v) {
      final actual = normalize(v['locale']);
      // Never silently replace Brazilian Portuguese with European Portuguese.
      if (lang == 'pt-BR') return actual == 'pt-BR';
      if (lang == 'nb') return actual == 'nb-NO' || actual == 'no-NO';
      return actual.split('-').first == locale.split('-').first;
    }

    final candidates = voices
        .whereType<Map>()
        .where(
          (v) =>
              matches(v) &&
              (!android ||
                  const [
                    '0',
                    'false',
                  ].contains(v['network_required'].toString())) &&
              (!android ||
                  !(v['features']?.toString().contains('notInstalled') ??
                      false)) &&
              (android ? v['name'] != null : v['identifier'] != null),
        )
        .toList();
    int rank(Map v) =>
        (normalize(v['locale']) == locale ? 100 : 0) +
        (v['gender'] == 'female' ? 20 : 0) +
        switch (v['quality']) {
          'premium' => 3,
          'enhanced' => 2,
          'very high' => 5,
          'high' => 4,
          'normal' => 3,
          'low' => 2,
          _ => 1,
        };
    candidates.sort((a, b) {
      final score = rank(b).compareTo(rank(a));
      return score != 0
          ? score
          : '${a['identifier'] ?? a['name']}'.compareTo(
              '${b['identifier'] ?? b['name']}',
            );
    });
    if (candidates.isEmpty) return null;
    final v = candidates.first;
    return android
        ? {'name': '${v['name']}', 'locale': normalize(v['locale'])}
        : {'identifier': '${v['identifier']}'};
  }

  static FlutterTts _getEngine() {
    if (_engine case final engine?) return engine;
    final engine = FlutterTts();
    engine.setCompletionHandler(() {
      final owner = _owner;
      _owner = null;
      owner?._clear();
      if (owner != null && !owner._disposed) owner.onComplete?.call();
    });
    engine.setProgressHandler((text, start, end, word) {
      _owner?.onProgress?.call(start, end);
    });
    engine.setErrorHandler((_) {
      final owner = _owner;
      _owner = null;
      owner?._clear();
      if (owner != null && !owner._disposed) {
        owner.onError('Sprachausgabe fehlgeschlagen. Bitte erneut versuchen.');
      }
    });
    return _engine = engine;
  }

  void _clear() {
    if (_disposed || _key == null) return;
    _key = null;
    notifyListeners();
  }

  @override
  void play(String key, String text) {
    if (_disposed) return;
    if (_key == key) {
      stop();
      return;
    }
    final lang = language();
    if (lang == null || text.trim().isEmpty) return;
    if (kIsWeb ||
        ![
          TargetPlatform.iOS,
          TargetPlatform.android,
        ].contains(defaultTargetPlatform)) {
      onError('Sprachausgabe ist auf iOS und Android verfügbar.');
      return;
    }
    final revision = ++_revision;
    _owner?._clear();
    _pending?._clear();
    _owner = null;
    _pending = this;
    _key = key;
    notifyListeners();
    _commands = _commands.then((_) async {
      try {
        final engine = _getEngine();
        await engine.stop();
        if (_disposed || revision != _revision) return;
        if (_configuredLanguage != lang) {
          final android = defaultTargetPlatform == TargetPlatform.android;
          final voice = selectVoice(
            await engine.getVoices as List,
            lang,
            android: android,
          );
          if (voice == null) throw StateError('missing voice');
          if (android) await engine.setLanguage(voice['locale']!);
          await engine.setVoice(voice);
          await engine.setSpeechRate(0.45);
          await engine.setVolume(1);
          if (!android) {
            await engine.setIosAudioCategory(
              IosTextToSpeechAudioCategory.playback,
              [IosTextToSpeechAudioCategoryOptions.duckOthers],
              IosTextToSpeechAudioMode.spokenAudio,
            );
          }
          _configuredLanguage = lang;
        }
        if (_disposed || revision != _revision || language() != lang) {
          if (revision == _revision) {
            _pending = null;
            _clear();
          }
          return;
        }
        _pending = null;
        _owner = this;
        if (await engine.speak(text, focus: true) != 1) {
          throw StateError('speech rejected');
        }
      } catch (_) {
        _configuredLanguage = null;
        if (!_disposed && revision == _revision) {
          _owner = null;
          _pending = null;
          _clear();
          onError(
            'Keine lokale Stimme für ${localeFor(lang)} verfügbar. Bitte installiere die Sprache in den Sprachausgabe-Einstellungen deines Geräts.',
          );
        }
      }
    });
  }

  @override
  void stop() {
    // A disposed popover must not stop a different screen's newer playback.
    if (_key == null && _owner != this && _pending != this) return;
    ++_revision;
    if (_owner == this) _owner = null;
    if (_pending == this) _pending = null;
    _clear();
    _commands = _commands.then((_) async {
      try {
        await _engine?.stop();
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  static void stopAll() {
    _pending?.stop();
    _owner?.stop();
  }

  @visibleForTesting
  static Future<void> resetForTest() async {
    stopAll();
    ++_revision;
    _commands = Future.value();
    _pending = null;
    _owner = null;
    _engine = null;
    _configuredLanguage = null;
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Route changes stop the current utterance without stopping a later request.
class SpeechNavigationObserver extends NavigatorObserver {
  void _stopCurrent() {
    final owner = DeviceSpeechPlayback._owner ?? DeviceSpeechPlayback._pending;
    final revision = DeviceSpeechPlayback._revision;
    scheduleMicrotask(() {
      if (revision == DeviceSpeechPlayback._revision) owner?.stop();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopCurrent();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stopCurrent();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _stopCurrent();
}
