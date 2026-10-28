import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Short sound effects for the practice completion screen
/// (`assets/sounds/`, Epidemic Sound). Fire and forget: a failing player
/// never blocks the animation.
abstract class CelebrationSounds {
  /// The streak bar starts charging.
  void charge();

  /// The bar reached its last day; the charge sound fades out.
  void stopCharge();

  /// One day's check pops.
  void check();

  /// The week star flips over.
  void star();
}

/// Default (tests, previews): no audio.
class SilentCelebrationSounds implements CelebrationSounds {
  const SilentCelebrationSounds();
  @override
  void charge() {}
  @override
  void stopCharge() {}
  @override
  void check() {}
  @override
  void star() {}
}

/// Plays the bundled effects. Ambient on iOS: the Silent switch mutes them
/// and they mix with whatever else is playing.
class AudioCelebrationSounds implements CelebrationSounds {
  AudioCelebrationSounds() {
    useAmbientAudio();
  }

  final _charge = AudioPlayer();
  final _check = AudioPlayer();
  final _star = AudioPlayer();
  Timer? _fade;

  void _play(AudioPlayer player, String asset, {double volume = 1}) {
    unawaited(
      () async {
        await player.stop();
        await player.setVolume(volume);
        await player.play(AssetSource('sounds/$asset'));
      }().catchError((Object _) {}),
    );
  }

  @override
  void charge() {
    _fade?.cancel();
    _play(_charge, 'streak_charge.mp3', volume: 0.6);
  }

  @override
  void stopCharge() {
    _fade?.cancel();
    var volume = 0.6;
    _fade = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      volume -= 0.1;
      if (volume <= 0) {
        timer.cancel();
        unawaited(_charge.stop().catchError((Object _) {}));
      } else {
        unawaited(_charge.setVolume(volume).catchError((Object _) {}));
      }
    });
  }

  @override
  void check() => _play(_check, 'streak_check.mp3', volume: 0.8);

  @override
  void star() => _play(_star, 'streak_star.mp3', volume: 0.9);
}

/// Sound effects are ambient: the iOS Silent switch mutes them, they mix
/// with other audio and never take focus. Set once for the whole app.
void useAmbientAudio() {
  if (_ambient) return;
  _ambient = true;
  unawaited(
    AudioPlayer.global
        .setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        )
        .catchError((Object _) {}),
  );
}

bool _ambient = false;

final celebrationSoundsProvider = Provider<CelebrationSounds>(
  (ref) => const SilentCelebrationSounds(),
);
