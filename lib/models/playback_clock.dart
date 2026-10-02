import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Stand-in for audio that runs longer than a word: a story read aloud or a
/// listening clip. A clock that runs while [playing] and can be paused,
/// skipped and sought. Swap the ticker for a TTS engine later; the
/// listeners stay the same.
class PlaybackClock extends ChangeNotifier {
  PlaybackClock({
    required this.duration,
    this.tick = const Duration(seconds: 1),
  }) : assert(duration > Duration.zero);

  /// About 150 words a minute, at least ten seconds.
  factory PlaybackClock.forText(Iterable<String> paragraphs) {
    final words = paragraphs
        .expand((p) => p.split(RegExp(r'\s+')))
        .where((w) => w.isNotEmpty)
        .length;
    return PlaybackClock(
      duration: Duration(milliseconds: math.max(10000, words * 400)),
    );
  }

  static const skipStep = Duration(seconds: 15);

  final Duration duration;
  final Duration tick;

  Duration _position = Duration.zero;
  Timer? _timer;

  Duration get position => _position;
  bool get playing => _timer != null;

  /// Share of the story already read, 0–1.
  double get progress => _position.inMilliseconds / duration.inMilliseconds;

  void play() {
    if (playing) return;
    if (_position >= duration) _position = Duration.zero;
    _timer = Timer.periodic(tick, (_) => _advance());
    notifyListeners();
  }

  void pause() {
    if (!playing) return;
    _timer!.cancel();
    _timer = null;
    notifyListeners();
  }

  void toggle() => playing ? pause() : play();

  /// Pauses and rewinds to the start.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _position = Duration.zero;
    notifyListeners();
  }

  void seek(Duration to) {
    _position = to < Duration.zero
        ? Duration.zero
        : (to > duration ? duration : to);
    if (_position >= duration) {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  void skip(Duration by) => seek(_position + by);

  void _advance() => seek(_position + tick);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// `m:ss`, e.g. "0:07" or "5:56".
String clockLabel(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
