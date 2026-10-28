import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'celebration_sounds.dart';

/// Quiet sound effects for the onboarding and the paywall
/// (`assets/sounds/`, Epidemic Sound). Used sparingly: picking an option,
/// a plan row ticking off, the paywall rising. Taps on words, back and
/// close stay silent (haptics only).
abstract class OnboardingSounds {
  void select();
  void tick();
  void paywall();
}

/// Default (tests, previews): no audio.
class SilentOnboardingSounds implements OnboardingSounds {
  const SilentOnboardingSounds();
  @override
  void select() {}
  @override
  void tick() {}
  @override
  void paywall() {}
}

class AudioOnboardingSounds implements OnboardingSounds {
  AudioOnboardingSounds() {
    useAmbientAudio();
  }

  final _select = AudioPlayer();
  final _tick = AudioPlayer();
  final _paywall = AudioPlayer();

  void _play(AudioPlayer player, String asset, double volume) {
    unawaited(
      () async {
        await player.stop();
        await player.setVolume(volume);
        await player.play(AssetSource('sounds/$asset'));
      }().catchError((Object _) {}),
    );
  }

  @override
  void select() => _play(_select, 'onboarding_select.mp3', 0.35);

  @override
  void tick() => _play(_tick, 'streak_check.mp3', 0.5);

  @override
  void paywall() => _play(_paywall, 'onboarding_paywall.mp3', 0.45);
}

final onboardingSoundsProvider = Provider<OnboardingSounds>(
  (ref) => const SilentOnboardingSounds(),
);
