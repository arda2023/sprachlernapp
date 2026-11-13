import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/learning_sync.dart';
import '../../data/sync/supabase_learning_sync_gateway.dart';
import 'database_providers.dart';
import 'learning_providers.dart';
import 'reading_providers.dart';
import 'streak_providers.dart';
import 'deck_providers.dart';
import 'preferences_provider.dart';
import 'auth_providers.dart';

/// Visible status can be used by both the web shell and mobile account screen.
enum LearningSyncPhase { signedOut, syncing, current, offline, accountMismatch }

final learningSyncProvider =
    NotifierProvider<LearningSyncController, LearningSyncPhase>(
      LearningSyncController.new,
    );

class LearningSyncController extends Notifier<LearningSyncPhase> {
  LearningSyncService? _service;
  bool _active = false;
  int _generation = 0;

  @override
  LearningSyncPhase build() {
    final accountState = ref.watch(accountSessionProvider);
    final databaseState = ref.watch(userDatabaseProvider);
    final account = !accountState.isLoading && !accountState.hasError
        ? accountState.value
        : null;
    final database = !databaseState.isLoading && !databaseState.hasError
        ? databaseState.value
        : null;
    final auth = ref.watch(contentAuthProvider);
    final generation = ++_generation;
    _service = null;
    if (account == null || database == null || auth.localOwner == null) {
      return LearningSyncPhase.signedOut;
    }
    final owner = auth.localOwner!;
    bool current() =>
        ref.mounted && generation == _generation && auth.localOwner == owner;
    final gateway = SupabaseLearningSyncGateway(auth, owner);
    _service = LearningSyncService(
      database,
      gateway,
      owner: owner,
      isCurrent: current,
    );
    final observer = _SyncLifecycle(() {
      if (current()) unawaited(synchronize());
    });
    WidgetsBinding.instance.addObserver(observer);
    Timer? changedTimer;
    final changes = database.tableUpdates().listen((_) {
      changedTimer?.cancel();
      changedTimer = Timer(const Duration(seconds: 2), () {
        if (current()) unawaited(synchronize());
      });
    });
    final timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (current()) unawaited(synchronize());
    });
    ref.onDispose(() {
      _generation++;
      timer.cancel();
      changedTimer?.cancel();
      unawaited(changes.cancel());
      WidgetsBinding.instance.removeObserver(observer);
      unawaited(gateway.close());
    });
    Future.microtask(() {
      if (current()) unawaited(synchronize());
    });
    return LearningSyncPhase.syncing;
  }

  Future<void> synchronize() async {
    final service = _service;
    if (_active || service == null) return;
    final generation = _generation;
    _active = true;
    state = LearningSyncPhase.syncing;
    try {
      final changed = await service.synchronize();
      if (!ref.mounted || generation != _generation) return;
      state = LearningSyncPhase.current;
      if (changed) {
        ref.invalidate(preferencesProvider);
        ref.invalidate(learningProgressProvider);
        ref.invalidate(wordListProvider);
        ref.invalidate(decksProvider);
        ref.invalidate(streakProvider);
        ref.invalidate(readingProgressProvider);
        ref.invalidate(importedTextsProvider);
      }
    } on LearningSyncAccountMismatch {
      if (ref.mounted && generation == _generation) {
        state = LearningSyncPhase.accountMismatch;
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = LearningSyncPhase.offline;
      }
    } finally {
      _active = false;
    }
  }
}

class _SyncLifecycle extends WidgetsBindingObserver {
  _SyncLifecycle(this.sync);
  final void Function() sync;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      sync();
    }
  }
}
