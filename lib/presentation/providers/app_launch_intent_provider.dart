import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_launch_intent.dart';

class PendingAppLaunch {
  const PendingAppLaunch(this.sequence, this.intent);
  final int sequence;
  final AppLaunchIntent intent;
}

/// Keeps cold-start taps until the authenticated/onboarded shell is ready.
/// A newer tap replaces an older pending destination.
final appLaunchIntentProvider =
    NotifierProvider<AppLaunchIntentController, PendingAppLaunch?>(
      AppLaunchIntentController.new,
    );

class AppLaunchIntentController extends Notifier<PendingAppLaunch?> {
  int _sequence = 0;

  @override
  PendingAppLaunch? build() => null;

  void publish(AppLaunchIntent intent) {
    state = PendingAppLaunch(++_sequence, intent);
  }

  bool consume(PendingAppLaunch launch) {
    if (!identical(state, launch)) return false;
    state = null;
    return true;
  }
}
