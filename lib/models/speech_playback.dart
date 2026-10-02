import 'dart:async';

import 'package:flutter/foundation.dart';

/// Stand-in for platform text-to-speech (PRODUCT.md): marks one item as
/// "playing" for about as long as reading it aloud would take. Starting a new
/// item stops the current one. Swap the timer for a TTS engine later; the
/// listeners stay the same.
class SpeechPlayback extends ChangeNotifier {
  String? _playing;
  Timer? _timer;

  /// Key of the item being read aloud, or null.
  String? get playing => _playing;

  bool isPlaying(String key) => _playing == key;

  /// Roughly 60 ms per character, between 0.8 and 4 seconds.
  static Duration durationFor(String text) =>
      Duration(milliseconds: (500 + text.length * 60).clamp(800, 4000));

  void play(String key, String text) {
    _timer?.cancel();
    _playing = key;
    _timer = Timer(durationFor(text), stop);
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_playing == null) return;
    _playing = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
