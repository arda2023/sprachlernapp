import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../platform/sqlite_platform.dart';

import 'package:unorm_dart/unorm_dart.dart' as unicode;

/// Display candidates only. Never contains a learning card ID or pack sense ID.
class DictionaryCandidate {
  const DictionaryCandidate(
    this.lemma,
    this.pos,
    this.gloss,
    this.tags,
    this.source,
    this.formSource,
  );
  final String lemma, pos, gloss, tags, source, formSource;
}

class OfflineDictionary {
  OfflineDictionary({required this.directory, required this.asset});
  final Future<Directory> Function() directory;
  final Future<Uint8List> Function(String name) asset;
  Future<String>? _opening;
  Future<Database>? _browserOpening;

  Future<Database> _openBrowser() async {
    final manifest = jsonDecode(
      utf8.decode(await asset('manifest.json')),
    ) as Map<String, dynamic>;
    final packed = await asset('dictionary.sqlite.gz');
    if (manifest['contract'] != 1 ||
        packed.length != manifest['compressed_bytes'] ||
        sha256.convert(packed).toString() != manifest['compressed_sha256']) {
      throw const FormatException('dictionary archive integrity');
    }
    final bytes = GZipDecoder().decodeBytes(packed);
    if (bytes.length != manifest['bytes'] ||
        sha256.convert(bytes).toString() != manifest['sha256']) {
      throw const FormatException('dictionary integrity');
    }
    final db = await openBundledDatabase(
      Uint8List.fromList(bytes),
      'dictionary_${manifest['sha256']}',
    );
    if (db.select('PRAGMA user_version').single.values.single != 1 ||
        db.select('PRAGMA quick_check').single.values.single != 'ok') {
      db.close();
      throw const FormatException('dictionary schema');
    }
    return db;
  }

  Future<String> _path() => _opening ??= _install().catchError((Object error) {
    _opening = null;
    throw error;
  });

  Future<String> _install() async {
    final manifest = jsonDecode(
      utf8.decode(await asset('manifest.json')),
    ) as Map<String, dynamic>;
    if (manifest['contract'] != 1 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(manifest['sha256'] as String)) {
      throw const FormatException('dictionary manifest');
    }
    final dir = await directory();
    final filename = '${dir.path}/${manifest['sha256']}.sqlite';
    final valid = await Isolate.run(() {
      final f = File(filename);
      return f.existsSync() &&
          f.lengthSync() == manifest['bytes'] &&
          sha256.convert(f.readAsBytesSync()).toString() == manifest['sha256'];
    });
    if (valid) return filename;
    final bytes = await asset('dictionary.sqlite.gz');
    await Isolate.run(() => installDictionary(filename, bytes, manifest));
    return filename;
  }

  Future<List<DictionaryCandidate>> lookup(String lang, String form) async {
    if (!{'en', 'pt-BR'}.contains(lang) ||
        form.trim().isEmpty ||
        form.length > 160) {
      return const [];
    }
    final key = unicode.nfc(form).toLowerCase();
    if (kIsWeb) {
      final db = await (_browserOpening ??= _openBrowser().catchError((
        Object e,
      ) {
        _browserOpening = null;
        throw e;
      }));
      return _lookupRows(db, lang, key);
    }
    final file = await _path();
    return _lookupInBackground(file, lang, key);
  }
}

/// Also exercised with real assets and injected filesystem/integrity failures.
void installDictionary(
  String filename,
  Uint8List packed,
  Map<String, dynamic> manifest,
) {
  if (packed.length != manifest['compressed_bytes'] ||
      sha256.convert(packed).toString() != manifest['compressed_sha256']) {
    throw const FormatException('dictionary archive integrity');
  }
  final bytes = gzip.decode(packed);
  if (bytes.length != manifest['bytes'] ||
      sha256.convert(bytes).toString() != manifest['sha256']) {
    throw const FormatException('dictionary integrity');
  }
  final target = File(filename);
  target.parent.createSync(recursive: true);
  final temporary = File(
    '$filename.${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
  try {
    temporary.writeAsBytesSync(bytes, flush: true);
    final db = sqlite3.open(temporary.path, mode: OpenMode.readOnly);
    try {
      if (db.select('PRAGMA user_version').single.values.single != 1 ||
          db.select('PRAGMA quick_check').single.values.single != 'ok') {
        throw const FormatException('dictionary schema');
      }
    } finally {
      db.close();
    }
    temporary.renameSync(filename);
  } finally {
    if (temporary.existsSync()) temporary.deleteSync();
  }
}

List<DictionaryCandidate> lookupDictionary(
  String filename,
  String lang,
  String key,
) {
  final db = sqlite3.open(filename, mode: OpenMode.readOnly);
  try {
    return _lookupRows(db, lang, key);
  } finally {
    db.close();
  }
}

List<DictionaryCandidate> _lookupRows(Database db, String lang, String key) {
  // Exact indexed lookup, capped for malformed/very ambiguous external entries.
  final rows = db.select(
    '''SELECT DISTINCT e.lemma,e.pos,e.gloss,e.tags,e.source,l.via
      FROM lookup l JOIN entries e ON e.id=l.entry
      WHERE l.lang=? AND l.form=? ORDER BY l.via,e.id LIMIT 80''',
    [lang, key],
  );
  return [
    for (final r in rows)
      DictionaryCandidate(
        r['lemma'] as String,
        r['pos'] as String,
        r['gloss'] as String,
        r['tags'] as String,
        r['source'] as String,
        r['via'] as String,
      ),
  ];
}

// A top-level closure avoids capturing the browser connection/futures from the
// OfflineDictionary instance when sending work to a native isolate.
Future<List<DictionaryCandidate>> _lookupInBackground(
  String file,
  String lang,
  String key,
) => Isolate.run(() => lookupDictionary(file, lang, key));
