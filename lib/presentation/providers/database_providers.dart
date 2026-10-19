import 'dart:async';
import '../../domain/language_profile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/content/content_pack_installer.dart';
import '../../data/content/content_database.dart';
import '../../data/content/content_update_service.dart';
import '../../data/user/drift_user_repository.dart';
import '../../data/user/user_database.dart';
import '../../domain/repositories.dart';
import '../../domain/content.dart';

/// Leases share one connection. Reopening waits for its asynchronous close,
/// including when a scope is disposed while opening. Thus an installer never
/// replaces a pack still owned by another provider scope.
class RepositoryOwner<T> {
  RepositoryOwner(this.open, this.close, {this.onEmpty, this.onIdle, this.revive});
  final void Function()? onEmpty, onIdle;
  final RepositoryOwner<T> Function()? revive;
  bool _retired = false;
  T? _value;
  T? get peek => _value;
  bool get hasInterest => _leases > 0;
  final Future<T> Function() open;
  final Future<void> Function(T) close;
  Future<T>? _current;
  Future<void> _closing = Future.value();
  int _leases = 0;
  bool _closeFailed = false;
  Completer<void>? _paused;
  Future<T>? _pausedCurrent;
  void pause() { _pausedCurrent=_current;_paused ??= Completer<void>(); }
  void resume() { final paused=_paused;_paused=null;paused?.complete(); }
  Future<void> closed() async {
    if (_pausedCurrent != null && identical(_current,_pausedCurrent)) throw StateError('Inhaltsansichten sind noch geöffnet.');
    await _closing;
    if (_closeFailed) throw StateError('Inhaltsverbindung konnte nicht geschlossen werden.');
  }

  Future<T> acquire(Ref ref) {
    final lease = this.lease();
    ref.onDispose(lease.release);
    return lease.future;
  }

  /// A lease outside a provider scope, e.g. validating a language switch
  /// target that the next provider scope then shares instead of reopening.
  ({Future<T> future, void Function() release}) lease() {
    if (_retired) return revive!().lease();
    _leases++;
    late final Future<T> opening;
    final future = _current ??= opening = _closing.then((_) async {
      await _paused?.future;
      if (_closeFailed) {
        throw StateError(
          'Die Datenverbindung wurde nicht geschlossen. Bitte die App neu starten.',
        );
      }
      // All leases ended while waiting for close/resume: a reader of an
      // outdated scope must not reopen the pack only to close it again.
      if (!identical(_current, opening)) {
        throw StateError('Inhaltsansicht wurde vor dem Öffnen geschlossen.');
      }
      final value = await open();
      if (identical(_current, opening) && _leases > 0) _value = value;
      return value;
    });
    var released = false;
    void release() {
      if (released) return;
      released = true;
      if (--_leases != 0) return;
      _current = null;
      _value = null;
      onEmpty?.call();
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
        _closing.then<void>((_) {
          if (_current == null && _leases == 0 && !_closeFailed && onIdle != null) {
            _retired = true;
            onIdle!();
          }
        }, onError: (Object _, StackTrace _) {}),
      );
    }
    return (future: future, release: release);
  }
}

final contentInstallerProvider = FutureProvider.family<ContentPackInstaller, String>(
  (ref, lang) => ContentPackInstaller.forApp(lang: lang), retry: (_, _) => null);

final contentTransitionGate = ContentTransitionGate();
typedef ContentRepositoryKey = ({String lang, int generation, String fingerprint});
final _contentOwners = <ContentRepositoryKey,RepositoryOwner<ContentRepository>>{};
RepositoryOwner<ContentRepository> contentOwnerFor(ContentRepositoryKey key) =>
  _contentOwners.putIfAbsent(key, () => createContentOwner(
    key, () => ContentPackInstaller.forApp(lang: key.lang),
    onIdle: () => _contentOwners.remove(key), revive: () => contentOwnerFor(key),
  ));

/// Shared by the app registry and synthetic integration harnesses.
RepositoryOwner<ContentRepository> createContentOwner(
  ContentRepositoryKey key, Future<ContentPackInstaller> Function() installer, {
  void Function()? onIdle, RepositoryOwner<ContentRepository> Function()? revive,
}) {
  ReadCancellation? cancellation;
  late final RepositoryOwner<ContentRepository> owner;
  owner = RepositoryOwner(() async {
    final token = cancellation = ReadCancellation();
    final pack = await installer();
    return pack.open(expectedFingerprint: key.fingerprint, cancellation: token,
      isCurrent: () => owner.hasInterest && identical(cancellation, token));
  }, (repository) => repository.close(), onEmpty: () => cancellation?.cancel(),
    onIdle: onIdle, revive: revive);
  return owner;
}

ContentRepository? peekContentOwner(ContentRepositoryKey key) => _contentOwners[key]?.peek;
final contentOwnerProvider = Provider.autoDispose.family<RepositoryOwner<ContentRepository>, ContentRepositoryKey>((ref, key) => contentOwnerFor(key));

/// Retry a changed recovery key once, always releasing the failed owner first.
Future<({ContentRepositoryKey key, ContentRepository repository, void Function() release})> acquireInstalledContent(
  Ref ref, ContentPackInstaller installer,
) async {
  for (var attempt = 0; attempt < 2; attempt++) {
    if (!ref.mounted) throw StateError('Inhaltsansicht bereits geschlossen.');
    final key = await contentKeyFor(installer);
    if (!ref.mounted) throw StateError('Inhaltsansicht bereits geschlossen.');
    final lease = ref.read(contentOwnerProvider(key)).lease();
    // Safe even for the explicit target lease: release is idempotent.
    final detach = ref.onDispose(lease.release);
    void release() { detach(); lease.release(); }
    try {
      final repository = await lease.future;
      if (!ref.mounted) throw StateError('Inhaltsansicht bereits geschlossen.');
      if (attempt != 0) ref.invalidate(activeContentKeyProvider);
      return (key: key, repository: repository, release: release);
    } on RecoveredGenerationChanged {
      release();
      if (attempt == 1) rethrow;
    } catch (_) {
      release();
      rethrow;
    }
  }
  throw StateError('Inhaltsgeneration wiederholt geändert.');
}
final _userDatabaseOwner = RepositoryOwner<UserDatabase>(UserDatabase.openForApp, (db)=>db.close());
final userDatabaseProvider = FutureProvider<UserDatabase>(_userDatabaseOwner.acquire,retry:(_,_)=>null);
final selectedContentLanguageProvider=FutureProvider<String>((ref) async {
  final db=await ref.watch(userDatabaseProvider.future);
  final settings=await db.select(db.settings).getSingleOrNull();
  final lang=settings?.targetLang??'en';
  if(ContentLanguageProfile.forLanguage(lang)==null)throw const ContentUnavailable(ContentUnavailableReason.incompatible,'Gewähltes Sprachprofil wird von dieser App noch nicht unterstützt.');
  return lang;
},retry:(_,_)=>null);
final activeContentKeyProvider=FutureProvider<ContentRepositoryKey>((ref) async {
  final lang=await ref.watch(selectedContentLanguageProvider.future);
  return contentKeyFor(await ref.watch(contentInstallerProvider(lang).future));
},retry:(_,_)=>null);
Future<ContentRepositoryKey> contentKeyFor(ContentPackInstaller installer) async {
  final identity = await installer.routingIdentity();
  return (lang: installer.lang, generation: identity.generation, fingerprint: identity.fingerprint);
}
final _settledViews = Provider<Map<Object, ({ContentRepositoryKey key, Object? value})>>((ref) => {});

/// Keeps the value a view already showed while the same language and pack
/// generation recomputes (review, resume). Another identity, or a previous
/// value this view never showed, keeps the loading state.
AsyncValue<T> watchContentStable<T>(WidgetRef ref, ProviderListenable<AsyncValue<T>> provider) {
  final key = ref.watch(activeContentKeyProvider);
  final value = ref.watch(provider);
  final current = key is AsyncData<ContentRepositoryKey> ? key.value : null;
  final settled = ref.read(_settledViews);
  if (current != null && value is AsyncData<T>) {
    settled[provider] = (key: current, value: value.value);
  } else if (current != null && value.isLoading && value.hasValue) {
    final last = settled[provider];
    if (last != null && last.key == current && last.value == value.value) {
      return AsyncData<T>(value.requireValue);
    }
  }
  return value;
}
final contentRepositoryProvider = FutureProvider<ContentRepository>((ref) async {
  final lang = await ref.watch(selectedContentLanguageProvider.future);
  final installer = await ref.watch(contentInstallerProvider(lang).future);
  // Deliberately do not depend on activeContentKeyProvider: recovery can update
  // that routing view without disposing its own newly validated reader.
  return (await acquireInstalledContent(ref, installer)).repository;
},retry:(_,_)=>null);
final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final db=await ref.watch(userDatabaseProvider.future);
  final lang=await ref.watch(selectedContentLanguageProvider.future);
  final repository=DriftUserRepository(db,lang:lang,ownsDatabase:false,contentIds:(kind) async {
    if (!ref.mounted) throw StateError('Sprachansicht wurde geschlossen.');
    final content=await ref.read(contentRepositoryProvider.future);
    if (content.info.lang != lang) throw StateError('Sprachansicht hat sich geändert.');
    return kind=='cards'?content.allCardIds():{for(final deck in await content.decks())deck.id};
  });
  await repository.deviceId();return repository;
},retry:(_,_)=>null);
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
