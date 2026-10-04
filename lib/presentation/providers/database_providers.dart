import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/content/content_pack_installer.dart';
import '../../data/user/drift_user_repository.dart';
import '../../data/user/user_database.dart';
import '../../domain/repositories.dart';
import '../../domain/content.dart';

/// Leases share one connection. Reopening waits for its asynchronous close,
/// including when a scope is disposed while opening. Thus an installer never
/// replaces a pack still owned by another provider scope.
class RepositoryOwner<T> {
  RepositoryOwner(this.open, this.close);
  final Future<T> Function() open;
  final Future<void> Function(T) close;
  Future<T>? _current;
  Future<void> _closing = Future.value();
  int _leases = 0;
  bool _closeFailed = false;

  Future<T> acquire(Ref ref) {
    _leases++;
    final future = _current ??= _closing.then((_) {
      if (_closeFailed) {
        throw StateError(
          'Die Datenverbindung wurde nicht geschlossen. Bitte die App neu starten.',
        );
      }
      return open();
    });
    ref.onDispose(() {
      if (--_leases != 0) return;
      _current = null;
      if (_closeFailed) return;
      _closing = future.then((repository) async {
        try {
          await close(repository);
        } catch (_) {
          _closeFailed = true;
          rethrow;
        }
      }, onError: (Object _, StackTrace _) {});
      // Retain close failures in the barrier: replacing an unclosed pack is
      // unsafe. Attach an error handler to avoid an unhandled async error.
      unawaited(
        _closing.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    });
    return future;
  }
}

final _contentOwner = RepositoryOwner<ContentRepository>(
  () async => (await ContentPackInstaller.forApp()).open(),
  (repository) => repository.close(),
);
final _userOwner = RepositoryOwner<UserRepository>(() async {
  final db = await UserDatabase.openForApp();
  final repository = DriftUserRepository(db, lang: 'en');
  try {
    await repository.deviceId();
    return repository;
  } catch (_) {
    await repository.close();
    rethrow;
  }
}, (repository) => repository.close());

final contentRepositoryProvider = FutureProvider<ContentRepository>(
  _contentOwner.acquire,
  retry: (_, _) => null,
);
final userRepositoryProvider = FutureProvider<UserRepository>(
  _userOwner.acquire,
  retry: (_, _) => null,
);
final contentInfoProvider = FutureProvider<ContentInfo>(
  (ref) async => (await ref.watch(contentRepositoryProvider.future)).info,
  retry: (_, _) => null,
);
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final appInfoProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}, retry: (_, _) => null);

/// Retry only failed connections; healthy repositories may still own sessions.
void retryDatabases(WidgetRef ref) {
  if (ref.read(contentRepositoryProvider).hasError) {
    ref.invalidate(contentRepositoryProvider);
  }
  if (ref.read(userRepositoryProvider).hasError) {
    ref.invalidate(userRepositoryProvider);
  }
  if (ref.read(appInfoProvider).hasError) ref.invalidate(appInfoProvider);
}
