import 'dart:convert';
import 'dart:io';

import 'content_release_client.dart';
import 'content_database.dart';

/// Only metadata is atomically replaced. A generation's SQLite is never replaced.
class ContentInstallJournal {
  ContentInstallJournal(Directory support, this.lang)
    : root = Directory('${support.path}/content/$lang') {
    if (!RegExp(r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$').hasMatch(lang)) {
      throw ArgumentError('Ungültige Inhaltssprache');
    }
  }
  final Directory root;
  final String lang;
  File named(String name) => File('${root.path}/$name.json');
  Directory generation(String id) {
    if (!RegExp(r'^[0-9a-f-]{36}$').hasMatch(id)) {
      throw const FormatException('Ungültige Generation');
    }
    return Directory('${root.path}/generations/$id');
  }

  Future<Map<String, dynamic>?> read(String name) async {
    final file = named(name);
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> write(String name, Map<String, dynamic> value) async {
    await root.create(recursive: true);
    final temporary = File('${named(name).path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    await temporary.rename(named(name).path);
  }

  Future<ReleaseOffer?> active() async {
    final value = await read('active');
    return value == null || value['bootstrap'] == true
        ? null
        : ReleaseOffer.parse(value, lang);
  }

  File bootstrapFile(ContentManifest manifest) => File(
    '${root.path}/generations/bootstrap-${manifest.sha256}/content.sqlite',
  );
  Future<File?> currentFile() async {
    final pointer = await read('active');
    if (pointer == null) {
      final legacy = File('${root.path}/content.sqlite');
      return await legacy.exists() ? legacy : null;
    }
    if (pointer['bootstrap'] == true) {
      return bootstrapFile(
        ContentManifest.parse(jsonEncode(pointer['manifest']), lang: lang),
      );
    }
    final offer = ReleaseOffer.parse(pointer, lang);
    return File('${generation(offer.id).path}/content.sqlite');
  }

  Future<void> prepare(ReleaseOffer offer) async {
    final old = await read('active');
    if (old != null) await write('previous', old);
    await write('install-journal', {
      'state': 'prepared',
      'previous': old,
      'next': offer.toJson(),
    });
  }

  Future<void> commit(ReleaseOffer offer) async {
    await write('install-journal', {
      'state': 'committed',
      'next': offer.toJson(),
    });
  }

  Future<void> restorePrepared(Map<String, dynamic> journal) async {
    final previous = journal['previous'];
    if (previous == null) {
      if (await named('active').exists()) await named('active').delete();
    } else {
      await write('active', Map<String, dynamic>.from(previous));
    }
    await write('install-journal', {
      'state': 'recovered',
      'failed': journal['next']['manifest_sha256'],
    });
  }
}
