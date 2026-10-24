import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../domain/personal_learning.dart';

class PersonalLearningFailure implements Exception {
  const PersonalLearningFailure(this.message);
  final String message;
}

/// Consent only. No card response, source text, provider secret or translation.
class PersonalConsentStore {
  PersonalConsentStore(this.open);
  final Future<Database> Function() open;
  Future<Database>? _pending;
  Future<Database> db() => _pending ??= (() async {
    final db = await open();
    db.execute(
      'CREATE TABLE IF NOT EXISTS consent(owner TEXT PRIMARY KEY, version INTEGER NOT NULL, enabled INTEGER NOT NULL)',
    );
    return db;
  })();
  Future<bool> read(String owner) async {
    final rows = (await db()).select(
      'SELECT enabled FROM consent WHERE owner=? AND version=1',
      [owner],
    );
    return rows.isNotEmpty && rows.single['enabled'] == 1;
  }

  Future<void> write(String owner, bool enabled) async => (await db()).execute(
    'INSERT OR REPLACE INTO consent VALUES(?,1,?)',
    [owner, enabled ? 1 : 0],
  );
  Future<void> close() async {
    if (_pending != null) (await _pending!).close();
  }
}

class PersonalLearningClient {
  PersonalLearningClient({
    required this.url,
    required this.publicKey,
    required this.token,
    required this.owner,
    required this.revision,
    required this.store,
    HttpClient Function()? createClient,
  }) : createClient = createClient ?? HttpClient.new;
  final String url, publicKey;
  final Future<String> Function() token;
  final Future<String?> Function() owner;
  final int Function() revision;
  final PersonalConsentStore store;
  final HttpClient Function() createClient;
  int consentRevision = 0;
  bool _blocked = false;
  final _inflight = <String, Future<Map<String, dynamic>>>{};
  Future<bool> consent() async {
    final who = await owner();
    return who != null && !_blocked && await store.read(who);
  }

  Future<void> setConsent(bool enabled) async {
    consentRevision++;
    _blocked = true;
    final epoch = revision(), who = await owner();
    if (who == null || epoch != revision()) {
      throw const PersonalLearningFailure('Bitte zuerst anmelden.');
    }
    await store.write(who, enabled);
    if (epoch != revision()) {
      throw const PersonalLearningFailure(
        'Konto geändert. Bitte erneut öffnen.',
      );
    }
    _blocked = false;
  }

  Future<Map<String, dynamic>> create(
    PersonalTarget t,
    List<String> ids, {
    List<Map<String, dynamic>> localCandidates = const [],
  }) async {
    t.validate();
    final who = await owner(),
        epoch = revision(),
        consentEpoch = consentRevision;
    if (who == null) {
      throw const PersonalLearningFailure('Bitte zuerst anmelden.');
    }
    Future<void> authorize() async {
      if (epoch != revision() ||
          consentEpoch != consentRevision ||
          _blocked ||
          await owner() != who ||
          !await store.read(who)) {
        throw const PersonalLearningFailure(
          'Freigabe oder Konto geändert. Bitte erneut öffnen.',
        );
      }
    }

    await authorize();
    final key = '$who:${t.key}:${ids.join(',')}:${jsonEncode(localCandidates)}';
    if (_inflight[key] case final pending?) return pending;
    final pending = _send({
      ...t.body,
      'candidates': ids,
      'local_candidates': localCandidates,
      'consent': 1,
    }, authorize);
    _inflight[key] = pending;
    try {
      return await pending;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<Map<String, dynamic>> _send(
    Map<String, dynamic> body,
    Future<void> Function() authorize,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || publicKey.isEmpty) {
      throw const PersonalLearningFailure(
        'Kartenerstellung ist noch nicht eingerichtet.',
      );
    }
    await authorize();
    final access = await token().timeout(const Duration(seconds: 30));
    await authorize();
    final client = createClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final r = await client.postUrl(
          uri.resolve('/functions/v1/create-learning-card'),
        );
        r.followRedirects = false;
        r.headers.set('apikey', publicKey);
        r.headers.set('Authorization', 'Bearer $access');
        r.headers.contentType = ContentType.json;
        await authorize();
        r.write(jsonEncode(body));
        final response = await r.close();
        if (response.statusCode != 200) {
          throw PersonalLearningFailure(switch (response.statusCode) {
            401 || 403 => 'Anmeldung oder Sprachfreigabe erforderlich.',
            429 => 'Tages- oder Minutenlimit erreicht. Bitte später versuchen.',
            409 => 'Erstellung läuft bereits oder ihr Ausgang ist unklar. Keine automatische Wiederholung.',
            422 =>
              'Wortstelle oder Packreferenz passt nicht. Bitte Inhalte prüfen.',
            504 => 'Erstellung hat zu lange gedauert. Keine automatische Wiederholung.',
            _ =>
              'Lernkarte derzeit nicht verfügbar. Es wurde nichts gespeichert.',
          });
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 16384) throw const FormatException();
        }
        await authorize();
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 30));
    } on PersonalLearningFailure {
      rethrow;
    } on SocketException {
      throw const PersonalLearningFailure(
        'Offline: Neue Karten benötigen eine Verbindung. Gespeicherte Karten bleiben lernbar.',
      );
    } on TimeoutException {
      throw const PersonalLearningFailure(
        'Erstellung hat zu lange gedauert. Keine automatische Wiederholung.',
      );
    } catch (_) {
      throw const PersonalLearningFailure(
        'Ungültige Antwort oder Verbindungsfehler. Nichts gespeichert.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
