import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../../data/content/content_install_journal.dart';
import '../../domain/language_profile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/content/content_pack_installer.dart';
import '../../data/content/content_update_service.dart';
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
      return open();
    });
    var released = false;
    void release() {
      if (released) return;
      released = true;
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
    }
    return (future: future, release: release);
  }
}

final contentInstallerProvider = FutureProvider.family<ContentPackInstaller, String>(
  (ref, lang) => ContentPackInstaller.forApp(lang: lang), retry: (_, _) => null);

final contentTransitionGate = ContentTransitionGate();
typedef ContentRepositoryKey = ({String lang, int generation});
final _contentOwners = <ContentRepositoryKey,RepositoryOwner<ContentRepository>>{};
RepositoryOwner<ContentRepository> contentOwnerFor(ContentRepositoryKey key) => _contentOwners.putIfAbsent(key,()=>RepositoryOwner(
  () async => (await ContentPackInstaller.forApp(lang:key.lang)).open(), (repository)=>repository.close()));
final contentOwnerProvider = Provider.family<RepositoryOwner<ContentRepository>, ContentRepositoryKey>((ref, key) => contentOwnerFor(key));
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
  final journal=ContentInstallJournal(await getApplicationSupportDirectory(),lang);
  return (lang:lang,generation:(await journal.active())?.generation??0);
},retry:(_,_)=>null);
/// Owner key of [installer]'s active generation, read like [activeContentKeyProvider].
Future<ContentRepositoryKey> contentKeyFor(ContentPackInstaller installer) async => (
  lang: installer.lang,
  generation: (await ContentInstallJournal(installer.supportDirectory, installer.lang).active())?.generation ?? 0,
);
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
  final key=await ref.watch(activeContentKeyProvider.future);
  if(!ref.mounted)throw StateError('Inhaltsansicht bereits geschlossen.');
  return ref.watch(contentOwnerProvider(key)).acquire(ref);
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
