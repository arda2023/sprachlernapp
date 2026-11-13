import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/widgets/home_widget_gateway.dart';
import '../../data/widgets/widget_gateway.dart';
import '../../domain/widget_launch_intent.dart';
import '../../domain/srs_state.dart';
import '../../domain/widget_snapshot.dart';
import '../story_cover_art.dart';
import '../widgets/widget_snapshot_service.dart';
import 'app_launch_intent_provider.dart';
import 'auth_providers.dart';
import 'database_providers.dart';
import 'language_selection_provider.dart';
import 'learning_providers.dart';
import 'practice_resolver_providers.dart';
import 'reading_providers.dart';
import 'story_learning_providers.dart';
import 'streak_providers.dart';

final widgetGatewayProvider = Provider<WidgetGateway>(
  (ref) => HomeWidgetGateway(),
);

final learningWidgetSnapshotProvider = FutureProvider<LearningWidgetSnapshot>((
  ref,
) async {
  final account = ref.watch(accountSessionProvider);
  final language = ref.watch(selectedContentLanguageProvider);
  final switching = ref.watch(languageSelectionProvider).switching;
  ref.watch(learningNowProvider);
  final now = ref.watch(clockProvider)();
  if (account.isLoading ||
      account.hasError ||
      account.value == null ||
      language.isLoading ||
      language.hasError ||
      switching) {
    return const LearningWidgetSnapshot.empty();
  }
  final progress = await ref.watch(learningProgressProvider.future);
  final streak = await ref.watch(streakProvider.future);
  final resolver = await ref.watch(practiceResolverProvider.future);
  final reading = ref.watch(readingProgressProvider);
  final library = ref.watch(libraryStoriesProvider).asData?.value ?? const [];
  final eligible = eligiblePracticeIds(
    targetsResolved: true,
    activeDeckCardIds: (await resolver.activePrimaryIds()).toSet(),
    states: resolver.states,
    contentCards: resolver.cards,
    knownCardIds: resolver.knownIds,
    explicitStoryIds: resolver.additions.keys.toSet(),
    hiddenIds: await resolver.deactivatedDeckIds(),
  );
  return buildLearningWidgetSnapshot(
    now: now,
    language: language.requireValue,
    goalDone: progress.goal.done,
    goalTarget: progress.goal.target,
    streak: streak,
    eligibleCardIds: eligible,
    cards: resolver.states,
    library: [
      for (final story in library)
        WidgetStory(
          id: story.id,
          title: story.title,
          coverAsset: storyCoverAssetKey(story.id, story.topic),
        ),
    ],
    reading: {
      for (final entry in reading.entries)
        entry.key: WidgetReading(
          fraction: entry.value.fraction,
          updatedAt: entry.value.updatedAt,
          finished: entry.value.finished,
        ),
    },
  );
}, retry: (_, _) => null);

/// Lives above the navigator; neither background routes nor logout pause it.
final widgetSyncProvider = Provider<void>((ref) {
  final gateway = ref.watch(widgetGatewayProvider);
  if (!gateway.supported) return;
  final service = WidgetSnapshotService(gateway);
  void clear() =>
      unawaited(service.publish(const LearningWidgetSnapshot.empty()));
  void publish() {
    final data = ref.read(learningWidgetSnapshotProvider);
    if (data.isLoading) return;
    unawaited(
      service.publish(
        data.asData?.value ?? const LearningWidgetSnapshot.empty(),
      ),
    );
  }

  ref.listen(accountSessionProvider, (previous, next) {
    if (previous?.value?.id != next.value?.id ||
        next.isLoading ||
        next.hasError) {
      clear();
    }
  });
  ref.listen(selectedContentLanguageProvider, (previous, next) {
    if (previous?.asData?.value != next.asData?.value ||
        next.isLoading ||
        next.hasError) {
      clear();
    }
  });
  ref.listen(languageSelectionProvider, (_, next) {
    if (next.switching) clear();
  });
  ref.listen(learningWidgetSnapshotProvider, (_, _) => publish());
  String? lastUri;
  DateTime? lastLaunch;
  void launch(Uri? uri) {
    if (!ref.mounted || uri == null) return;
    final intent = appLaunchIntentFromWidget(uri);
    if (intent == null) return;
    final now = DateTime.now();
    if (lastUri == uri.toString() &&
        lastLaunch != null &&
        now.difference(lastLaunch!) < const Duration(milliseconds: 750)) {
      return;
    }
    lastUri = uri.toString();
    lastLaunch = now;
    ref.read(appLaunchIntentProvider.notifier).publish(intent);
  }

  final taps = gateway.launches.listen(launch, onError: (Object _) {});
  unawaited(gateway.initialLaunch().then(launch).catchError((Object _) {}));
  final observer = _WidgetLifecycleObserver((state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(learningNowProvider);
      ref.invalidate(learningWidgetSnapshotProvider);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      publish();
    }
  });
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    service.dispose();
    unawaited(taps.cancel());
    WidgetsBinding.instance.removeObserver(observer);
  });
  // Clear a previous install/account before the first authenticated projection.
  clear();
  publish();
});

class _WidgetLifecycleObserver extends WidgetsBindingObserver {
  _WidgetLifecycleObserver(this.changed);
  final void Function(AppLifecycleState) changed;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => changed(state);
}
