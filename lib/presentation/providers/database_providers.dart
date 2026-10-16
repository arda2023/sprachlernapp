import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../../data/content/content_install_journal.dart';
import '../../domain/language_profile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _leases++;
    final future = _current ??= _closing.then((_) async {
      await _paused?.future;
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

final contentTransitionGate = ContentTransitionGate();
typedef ContentRepositoryKey = ({String lang, int generation});
final _contentOwners = <ContentRepositoryKey,RepositoryOwner<ContentRepository>>{};
RepositoryOwner<ContentRepository> contentOwnerFor(ContentRepositoryKey key) => _contentOwners.putIfAbsent(key,()=>RepositoryOwner(
  () async => (await ContentPackInstaller.forApp(lang:key.lang)).open(), (repository)=>repository.close()));
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
final contentRepositoryProvider = FutureProvider<ContentRepository>((ref) async {
  final key=await ref.watch(activeContentKeyProvider.future);
  if(!ref.mounted)throw StateError('Inhaltsansicht bereits geschlossen.');
  return contentOwnerFor(key).acquire(ref);
},retry:(_,_)=>null);
final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final db=await ref.watch(userDatabaseProvider.future);
  final lang=await ref.watch(selectedContentLanguageProvider.future);
  final repository=DriftUserRepository(db,lang:lang,ownsDatabase:false,contentIds:(kind) async {
    final content=await ref.read(contentRepositoryProvider.future);
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
