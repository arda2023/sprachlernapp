import 'package:flutter/foundation.dart';

import '../../models/playback_clock.dart';
import 'device_speech_playback.dart';

/// Real speech with text-derived progress. Time labels are estimates, not a timer.
class SpeechNarration extends PlaybackClock {
  SpeechNarration({
    required this.text,
    required String language,
    required ValueChanged<String> onError,
  }) : super(
         duration: Duration(
           milliseconds: (text.split(RegExp(r'\s+')).length * 400).clamp(
             1000,
             86400000,
           ),
         ),
       ) {
    _speech = DeviceSpeechPlayback(
      language: () => language,
      onError: onError,
      onProgress: (start, end) {
        _offset = (_start + start).clamp(0, text.length);
        notifyListeners();
      },
      onComplete: () {
        _offset = _end;
        if (_offset < text.length) {
          play();
        } else {
          notifyListeners();
        }
      },
    )..addListener(notifyListeners);
  }
  final String text;
  late final DeviceSpeechPlayback _speech;
  int _offset = 0, _start = 0, _end = 0;
  @override
  bool get playing => _speech.playing != null;
  @override
  double get progress => text.isEmpty ? 0 : _offset / text.length;
  @override
  Duration get position => duration * progress;
  @override
  void play() {
    if (playing || text.trim().isEmpty) return;
    if (_offset >= text.length) _offset = 0;
    _start = _offset;
    _end = (_start + 1200).clamp(0, text.length);
    if (_end < text.length) {
      final boundary = text.lastIndexOf(RegExp(r'\s'), _end);
      if (boundary > _start) _end = boundary;
    }
    _speech.play('$_start', text.substring(_start, _end));
  }

  @override
  void pause() => _speech.stop();
  @override
  void stop() {
    _speech.stop();
    _offset = 0;
    notifyListeners();
  }

  @override
  void seek(Duration to) {
    final resume = playing;
    _speech.stop();
    _offset = (text.length * to.inMilliseconds / duration.inMilliseconds)
        .round()
        .clamp(0, text.length);
    while (_offset > 0 &&
        _offset < text.length &&
        !RegExp(r'\s').hasMatch(text[_offset - 1])) {
      _offset--;
    }
    notifyListeners();
    if (resume && _offset < text.length) play();
  }

  @override
  void dispose() {
    _speech.removeListener(notifyListeners);
    _speech.dispose();
    super.dispose();
  }
}
