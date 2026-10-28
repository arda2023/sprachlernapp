import 'dart:async';
import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'runtime_translation_client.dart';

/// Independent from content.sqlite and the learner database. The owner column
/// is mandatory on every read/write. Hashes alone never authorize access.
class TranslationCache {
  TranslationCache(Future<Database> Function() open) : _open = open;
  final Future<Database> Function() _open;
  Future<Database>? _opening;
  Future<Database> _db() => _opening ??= (() async {
    final db = await _open();
    db.execute('PRAGMA secure_delete=ON');
    db.execute(
      'CREATE TABLE IF NOT EXISTS translations (owner TEXT NOT NULL, key TEXT NOT NULL, response TEXT NOT NULL, expires INTEGER NOT NULL, PRIMARY KEY(owner,key))',
    );
    db.execute('CREATE TABLE IF NOT EXISTS deletion (owner TEXT PRIMARY KEY)');
    db.execute(
      'CREATE TABLE IF NOT EXISTS word_cloud_consent (owner TEXT PRIMARY KEY, version INTEGER NOT NULL, enabled INTEGER NOT NULL, decided_at INTEGER NOT NULL)',
    );
    db.execute('DELETE FROM translations WHERE expires <= ?', [
      DateTime.now().millisecondsSinceEpoch,
    ]);
    return db;
  })();
  Future<Map<String, dynamic>?> read(String owner, String key) async {
    final db = await _db();
    if (db.select('SELECT 1 FROM deletion WHERE owner=?', [owner]).isNotEmpty) {
      return null;
    }
    final rows = db.select(
      'SELECT response FROM translations WHERE owner=? AND key=? AND expires>?',
      [owner, key, DateTime.now().millisecondsSinceEpoch],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['response'] as String) as Map<String, dynamic>;
  }

  Future<void> write(
    String owner,
    String key,
    Map<String, dynamic> response,
  ) async {
    final db = await _db();
    if (db.select('SELECT 1 FROM deletion WHERE owner=?', [owner]).isNotEmpty) {
      return;
    }
    final expires = DateTime.parse(response['created_at'] as String)
        .add(const Duration(days: 30));
    if (expires.isBefore(DateTime.now())) return;
    db.execute('INSERT OR REPLACE INTO translations VALUES(?,?,?,?)', [
      owner,
      key,
      jsonEncode(response),
      expires.millisecondsSinceEpoch,
    ]);
  }

  Future<void> markDeletion(String owner) async {
    final db = await _db();
    db.execute('BEGIN IMMEDIATE');
    try {
      db.execute('INSERT OR IGNORE INTO deletion VALUES(?)', [owner]);
      db.execute('DELETE FROM translations WHERE owner=?', [owner]);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<bool> deletionPending(String owner) async => (await _db()).select(
    'SELECT 1 FROM deletion WHERE owner=?',
    [owner],
  ).isNotEmpty;
  Future<void> deletionDone(String owner) async =>
      (await _db()).execute('DELETE FROM deletion WHERE owner=?', [owner]);
  Future<WordCloudConsent> readWordConsent(String owner) async {
    final rows = (await _db()).select(
      'SELECT version,enabled FROM word_cloud_consent WHERE owner=?',
      [owner],
    );
    if (rows.isEmpty || rows.single['version'] != 1) {
      return WordCloudConsent.unknown;
    }
    return rows.single['enabled'] == 1
        ? WordCloudConsent.enabled
        : WordCloudConsent.disabled;
  }

  Future<void> writeWordConsent(String owner, bool enabled) async {
    (await _db()).execute(
      'INSERT OR REPLACE INTO word_cloud_consent VALUES(?,?,?,?)',
      [owner, 1, enabled ? 1 : 0, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    final Database db;
    try {
      db = await opening;
    } catch (_) {
      return;
    }
    db.close();
  }
}

class CachedRuntimeTranslationClient extends RuntimeTranslationClient {
  CachedRuntimeTranslationClient({
    required this.remote,
    required this.store,
    required this.owner,
    required this.revision,
    Stream<void> identityChanges = const Stream.empty(),
  }) : super(remote.url, remote.publicKey, remote.token) {
    _identitySubscription = identityChanges.listen((_) {
      _epoch++;
      _changes.add(null);
    });
  }
  final RuntimeTranslationClient remote;
  final TranslationCache store;
  final Future<String?> Function() owner;
  final int Function() revision;
  final _inflight = <String, Future<RuntimeTranslation>>{};
  final _changes = StreamController<void>.broadcast(sync: true);
  late final StreamSubscription<void> _identitySubscription;
  int _epoch = 0;
  int _consentEpoch = 0;
  bool _consentWritePending = false;
  bool _consentBlocked = false;

  @override
  Future<WordCloudConsent> wordCloudConsent() async {
    final account = await owner();
    if (account == null) return WordCloudConsent.unknown;
    final epoch = _epoch, authRevision = revision();
    if (_consentWritePending || _consentBlocked) {
      return WordCloudConsent.disabled;
    }
    try {
      final value = await store.readWordConsent(account);
      await _check(account, epoch, authRevision);
      return _consentWritePending ? WordCloudConsent.disabled : value;
    } on TranslationFailure {
      rethrow;
    } catch (_) {
      throw const TranslationFailure(
        'Cloud-Einstellung konnte nicht gelesen werden. Keine Anfrage gestartet.',
      );
    }
  }

  @override
  Future<void> setWordCloudConsent(bool enabled) async {
    if (_consentWritePending) {
      throw const TranslationFailure('Einstellung wird noch gespeichert.');
    }
    _consentEpoch++;
    _consentBlocked = true;
    _consentWritePending = true;
    try {
      final account = await _owner();
      final epoch = _epoch, authRevision = revision();
      await store.writeWordConsent(account, enabled);
      await _check(account, epoch, authRevision);
      _consentBlocked = false;
    } on TranslationFailure {
      rethrow;
    } catch (_) {
      throw const TranslationFailure(
        'Cloud-Einstellung konnte nicht gespeichert werden.',
      );
    } finally {
      _consentWritePending = false;
    }
  }

  @override
  Future<RuntimeTranslation> translateWordOnTap({
    required String lang,
    required String text,
    required String form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async {
    final consentEpoch = _consentEpoch;
    final account = await _owner();
    final epoch = _epoch, authRevision = revision();
    Future<void> authorize() async {
      await _check(account, epoch, authRevision);
      if (consentEpoch != _consentEpoch ||
          _consentWritePending ||
          await wordCloudConsent() != WordCloudConsent.enabled ||
          consentEpoch != _consentEpoch) {
        throw const TranslationFailure(
          'Automatische Cloudübersetzung ist ausgeschaltet.',
        );
      }
    }

    await authorize();
    final value = await translate(
      lang: lang,
      text: text,
      form: form,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
      authorize: authorize,
    );
    await authorize();
    return value;
  }

  final _cloudDeletions = <String, Future<void>>{};
  Future<void> _flushDeletion(
    String account,
    int epoch,
    int authRevision,
  ) async {
    final key = '$account:$epoch:$authRevision';
    final future = _cloudDeletions.putIfAbsent(key, () async {
      if (!await store.deletionPending(account)) return;
      await _check(account, epoch, authRevision);
      await remote.clearSaved();
      await _check(account, epoch, authRevision);
      await store.deletionDone(account);
    });
    try {
      await future;
    } finally {
      if (identical(_cloudDeletions[key], future)) {
        _cloudDeletions.remove(key);
      }
    }
  }

  @override
  Stream<void> get changes => _changes.stream;
  Future<String> _owner() async {
    final value = await owner();
    if (value == null) {
      throw const TranslationFailure(
        'Bitte zuerst in den Einstellungen anmelden.',
      );
    }
    return value;
  }

  Future<void> _check(String account, int epoch, int authRevision) async {
    if (await owner() != account ||
        epoch != _epoch ||
        authRevision != revision()) {
      throw const TranslationFailure(
        'Konto oder Übersetzungsspeicher wurde geändert. Bitte erneut öffnen.',
      );
    }
  }

  @override
  Future<RuntimeTranslation?> cached({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async {
    final account = await owner();
    if (account == null) return null;
    final epoch = _epoch, authRevision = revision();
    final request = TranslationRequest(
      lang: lang,
      text: text,
      form: form,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
    );
    try {
      final payload = await store.read(account, request.key);
      await _check(account, epoch, authRevision);
      return payload == null
          ? null
          : RuntimeTranslation.parse(payload, request);
    } on TranslationFailure {
      rethrow;
    } catch (_) {
      throw const TranslationFailure(
        'Gespeicherte Übersetzung konnte nicht gelesen werden. Keine neue Anfrage gestartet.',
      );
    }
  }

  @override
  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
    Future<void> Function()? authorize,
  }) async {
    await authorize?.call();
    final account = await _owner();
    final epoch = _epoch, authRevision = revision();
    final request = TranslationRequest(
      lang: lang,
      text: text,
      form: form,
      start: start,
      senseRef: senseRef,
      formRef: formRef,
    );
    final key = '$account:$authRevision:$epoch:${request.key}';
    final existing = _inflight[key];
    if (existing != null) return existing;
    final future = (() async {
      final hit = await cached(
        lang: lang,
        text: text,
        form: form,
        start: start,
        senseRef: senseRef,
        formRef: formRef,
      );
      await _check(account, epoch, authRevision);
      if (hit != null) return hit;
      try {
        await _flushDeletion(account, epoch, authRevision);
      } catch (_) {
        throw const TranslationFailure(
          'Ausstehende Cloudlöschung zuerst abschließen. Bitte verbinden und erneut versuchen.',
        );
      }
      await _check(account, epoch, authRevision);
      await authorize?.call();
      final value = await remote.translate(
        lang: lang,
        text: text,
        form: form,
        start: start,
        senseRef: senseRef,
        formRef: formRef,
        authorize: authorize,
      );
      await authorize?.call();
      await _check(account, epoch, authRevision);
      final payload = value.payload;
      if (payload == null) {
        throw const TranslationFailure('Ungültige Übersetzungsantwort.');
      }
      RuntimeTranslation.parse(payload, request);
      try {
        await store.write(account, request.key, payload);
      } catch (_) {
        await _check(account, epoch, authRevision);
        return value.withStorageWarning();
      }
      await _check(account, epoch, authRevision);
      return value;
    })();
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_inflight[key], future)) _inflight.remove(key);
    }
  }

  @override
  Future<void> clearSaved() async {
    final account = await _owner();
    final epoch = ++_epoch, authRevision = revision();
    _changes.add(null);
    try {
      await store.markDeletion(account);
    } catch (_) {
      throw const TranslationFailure(
        'Übersetzungen konnten auf diesem Gerät nicht gelöscht werden.',
      );
    }
    try {
      await _flushDeletion(account, epoch, authRevision);
    } catch (_) {
      throw const TranslationFailure(
        'Auf diesem Gerät gelöscht. Cloudlöschung steht aus; bitte mit diesem Konto online erneut löschen.',
      );
    }
  }

  Future<void> close() async {
    await _identitySubscription.cancel();
    await _changes.close();
    await store.close();
  }
}
