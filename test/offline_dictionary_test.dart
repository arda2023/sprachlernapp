import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/offline_translation/offline_dictionary.dart';

void main() {
  late Directory dir;
  late OfflineDictionary dictionary;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dictionary-test');
    dictionary = OfflineDictionary(directory: () async => dir,
      asset: (name) => File('assets/offline_dictionary/$name').readAsBytes());
  });
  tearDown(() => dir.delete(recursive: true));
  test('real shipped data: senses, irregular forms, accents, phrases and language separation', () async {
    final bank = await dictionary.lookup('en', 'bank');
    expect(bank.any((c) => c.gloss.contains('Geldinstitut')), isTrue);
    expect(bank.any((c) => c.gloss.contains('Ufer')), isTrue);
    final went = await dictionary.lookup('en', 'went');
    expect(went.any((c) => c.lemma == 'go' && c.formSource.endsWith('/went')), isTrue);
    expect((await dictionary.lookup('pt-BR', 'coração')).any((c) => c.gloss.contains('Herz')), isTrue);
    expect(await dictionary.lookup('pt-BR', 'coracao'), isEmpty);
    expect(await dictionary.lookup('pt-BR', 'corac\u0327a\u0303o'), isNotEmpty);
    expect((await dictionary.lookup('pt-BR', 'fui')).map((c) => c.lemma).toSet(), contains('ser'));
    expect(await dictionary.lookup('pt-BR', 'went'), isEmpty);
    expect(await dictionary.lookup('en', 'coração'), isEmpty);
    expect(await dictionary.lookup('en', 'from scratch'), isNotEmpty);
    expect(await dictionary.lookup('en', 'of course'), isEmpty);
    expect(await dictionary.lookup('pt-BR', 'por favor'), isNotEmpty);
    // Current source does not cover these contractions: no guessed decomposition.
    expect(await dictionary.lookup('pt-BR', 'do'), isEmpty);
    expect(await dictionary.lookup('pt-BR', 'na'), isEmpty);
    expect(await dictionary.lookup('en', 'zzsyntheticmissing'), isEmpty);
  });
  test('restart, indexed lookup timing and actual delivered size', () async {
    final manifest = jsonDecode(await File('assets/offline_dictionary/manifest.json').readAsString());
    expect(manifest['counts']['en']['senses'], greaterThan(20000));
    expect(manifest['counts']['pt-BR']['senses'], greaterThan(1000));
    await dictionary.lookup('en', 'bank');
    final restarted = OfflineDictionary(directory: () async => dir, asset: (name) {
      if (name.endsWith('.gz')) throw StateError('archive not needed after installation');
      return File('assets/offline_dictionary/$name').readAsBytes();
    });
    final watch = Stopwatch()..start();
    for (var i = 0; i < 30; i++) { expect(await restarted.lookup('en', 'bank'), isNotEmpty); }
    watch.stop();
    // Measurement, not a relaxed runtime assertion or a claim about iPhone.
    // ignore: avoid_print
    print('Dictionary: ${manifest['compressed_bytes']} compressed / ${manifest['bytes']} installed bytes; 30 isolate lookups ${watch.elapsedMilliseconds} ms');
  });
  test('corrupt archive and failed disk write never replace a valid dictionary', () async {
    final manifest = jsonDecode(await File('assets/offline_dictionary/manifest.json').readAsString()) as Map<String,dynamic>;
    final bytes = await File('assets/offline_dictionary/dictionary.sqlite.gz').readAsBytes();
    final target = '${dir.path}/dictionary.sqlite';
    installDictionary(target, bytes, manifest);
    final before = await File(target).readAsBytes();
    expect(() => installDictionary(target, Uint8List.fromList([1,2,3]), manifest), throwsFormatException);
    expect(await File(target).readAsBytes(), before);
    final blocker = File('${dir.path}/not-a-directory')..writeAsStringSync('occupied');
    expect(() => installDictionary('${blocker.path}/dictionary.sqlite', bytes, manifest), throwsA(isA<FileSystemException>()));
    expect(dir.listSync().where((f) => f.path.endsWith('.tmp')), isEmpty);
  });
}
