// Stages a technically finalized content pack as the app's development asset
// (docs/app-content-integration-plan.md, Abschnitt 5).
//
// Windows (PowerShell) and macOS (Terminal), from the repository root:
//   dart run tool/stage_content_pack.dart --from pipeline/out/curated_test_v1
//   dart run tool/stage_content_pack.dart --verify
//
// Checks before copying: finalization_report.json says status "ok", the
// pack opens read-only and passes the app's schema check, and every table
// count equals the report. Then copies content.sqlite into
// assets/content/<lang>/ (temporary file + rename), verifies the copy and
// writes content.manifest.json (SHA-256, version, origin). Both files are
// gitignored internal test material; the app never reads pipeline/out/.
// Exit codes: 0 ok, 1 check failed, 64 usage error.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/domain/content.dart';

class StageError implements Exception {
  StageError(this.message);

  final String message;

  @override
  String toString() => message;
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

/// Validates the pack in [from] against its finalization report, copies it
/// to [to] and writes the manifest. [sourceLabel] is recorded as origin.
ContentManifest stageContentPack({
  required Directory from,
  required Directory to,
  required String lang,
  required String sourceLabel,
}) {
  final reportFile = File(p.join(from.path, 'finalization_report.json'));
  final source = File(p.join(from.path, 'content.sqlite'));
  if (!reportFile.existsSync()) {
    throw StageError('${reportFile.path} fehlt');
  }
  if (!source.existsSync()) throw StageError('${source.path} fehlt');
  final Object? report;
  try {
    report = jsonDecode(reportFile.readAsStringSync());
  } on FormatException catch (e) {
    throw StageError('finalization_report.json ist kein JSON: ${e.message}');
  }
  if (report is! Map<String, Object?>) {
    throw StageError('finalization_report.json hat kein Objekt');
  }
  if (report['status'] != 'ok') {
    throw StageError(
      'Finalisierungsstatus ist "${report['status']}", '
      'erwartet "ok"',
    );
  }
  final counts = report['sqlite_counts'];
  if (counts is! Map<String, Object?> || counts.isEmpty) {
    throw StageError('finalization_report.json nennt keine sqlite_counts');
  }

  final shaBefore = _sha256(source);
  final ContentInfo info;
  final db = sqlite3.open(source.path, mode: OpenMode.readOnly);
  try {
    db.execute('PRAGMA query_only = ON');
    try {
      info = validateContentSchema(db, lang: lang);
    } on ContentUnavailable catch (e) {
      throw StageError('Schemaprüfung: ${e.message}');
    }
    final tables = {
      for (final r in db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      ))
        r['name'] as String,
    };
    if (!tables.containsAll(counts.keys) ||
        !counts.keys.toSet().containsAll(tables)) {
      throw StageError(
        'Tabellen im Pack ${tables.toList()..sort()} passen nicht '
        'zum Bericht ${counts.keys.toList()..sort()}',
      );
    }
    for (final MapEntry(key: table, value: expected) in counts.entries) {
      final actual = db.select('SELECT count(*) AS n FROM "$table"').first['n'];
      if (actual != expected) {
        throw StageError(
          'Tabelle $table: $actual Zeilen, Bericht nennt $expected',
        );
      }
    }
  } finally {
    db.close();
  }
  if (_sha256(source) != shaBefore) {
    throw StageError('Quelle hat sich während der Prüfung geändert');
  }

  to.createSync(recursive: true);
  final target = File(p.join(to.path, 'content.sqlite'));
  final tmp = File('${target.path}.tmp');
  source.copySync(tmp.path);
  if (_sha256(tmp) != shaBefore) {
    tmp.deleteSync();
    throw StageError('Kopie weicht von der Quelle ab');
  }
  tmp.renameSync(target.path);

  final manifest = ContentManifest(
    lang: lang,
    version: info.version,
    schemaVersion: info.schemaVersion,
    sha256: shaBefore,
    sizeBytes: target.lengthSync(),
    internalTestPack:
        report['internal_test_pack'] == true || info.isInternalTestPack,
    notes: info.notes,
    source: {
      'path': sourceLabel,
      'finalization_status': report['status'],
      'table_counts': {
        for (final k in counts.keys.toList()..sort()) k: counts[k],
      },
    },
  );
  File(p.join(to.path, 'content.manifest.json'))
      .writeAsStringSync(manifest.toJson());
  return verifyStagedPack(to, lang: lang);
}

/// Checks a staged asset folder: manifest parses, the file matches its size
/// and checksum and passes the schema check with the manifest version.
ContentManifest verifyStagedPack(Directory dir, {required String lang}) {
  final manifestFile = File(p.join(dir.path, 'content.manifest.json'));
  final file = File(p.join(dir.path, 'content.sqlite'));
  if (!manifestFile.existsSync() || !file.existsSync()) {
    throw StageError('kein gestagtes Pack in ${dir.path}');
  }
  final ContentManifest manifest;
  try {
    manifest = ContentManifest.parse(
      manifestFile.readAsStringSync(),
      lang: lang,
    );
  } on ContentUnavailable catch (e) {
    throw StageError('Manifest: ${e.message}');
  }
  if (file.lengthSync() != manifest.sizeBytes ||
      _sha256(file) != manifest.sha256) {
    throw StageError('content.sqlite passt nicht zum Manifest');
  }
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final info = validateContentSchema(db, lang: lang);
    if (info.version != manifest.version) {
      throw StageError(
        'Version ${info.version} im Pack, ${manifest.version} '
        'im Manifest',
      );
    }
  } on ContentUnavailable catch (e) {
    throw StageError('Schemaprüfung: ${e.message}');
  } finally {
    db.close();
  }
  return manifest;
}

const _usage = '''
Usage: dart run tool/stage_content_pack.dart --from <finalized pack folder> [--lang en]
       dart run tool/stage_content_pack.dart --verify [--lang en]
''';

void main(List<String> args) {
  String? from;
  var lang = 'en';
  var verifyOnly = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--from' when i + 1 < args.length:
        from = args[++i];
      case '--lang' when i + 1 < args.length:
        lang = args[++i];
      case '--verify':
        verifyOnly = true;
      case '-h' || '--help':
        stdout.write(_usage);
        return;
      default:
        stderr.write('Unknown argument: ${args[i]}\n$_usage');
        exitCode = 64;
        return;
    }
  }
  if (!verifyOnly && from == null) {
    stderr.write(_usage);
    exitCode = 64;
    return;
  }
  final to = Directory(p.join('assets', 'content', lang));
  try {
    final manifest = verifyOnly
        ? verifyStagedPack(to, lang: lang)
        : stageContentPack(
            from: Directory(from!),
            to: to,
            lang: lang,
            sourceLabel: p.posix.joinAll(
              p.split(p.normalize(p.join(from, 'content.sqlite'))),
            ),
          );
    final tables = (manifest.source['table_counts'] as Map?)?.length;
    stdout.writeln(
      '${verifyOnly ? 'verified' : 'staged'} ${p.join(to.path, 'content.sqlite')}',
    );
    stdout.writeln(
      '  version ${manifest.version}, schema ${manifest.schemaVersion}, '
      '${manifest.sizeBytes} bytes',
    );
    stdout.writeln('  sha256 ${manifest.sha256}');
    if (tables != null) {
      stdout.writeln('  $tables table counts match finalization_report.json');
    }
    if (manifest.internalTestPack) {
      stdout.writeln(
        '  INTERNES TEST-PACK: own devices and selected testers only, '
        'no public content release',
      );
    }
  } on StageError catch (e) {
    stderr.writeln('error: ${e.message}');
    exitCode = 1;
  }
}
