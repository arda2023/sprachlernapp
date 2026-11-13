import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Real app fonts, scoped to accessibility tests. Existing Ahem goldens keep
/// their original font environment. The fixtures require no system font or
/// network access; provenance and OFL notices live beside the font files.
Future<void> loadAccessibilityFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final fixtures = Directory('test/fixtures/fonts');
  final metadata = jsonDecode(
    File('${fixtures.path}/manifest.json').readAsStringSync(),
  ) as List<dynamic>;
  final fontBytes = <String, ByteData>{};
  for (final entry in metadata.cast<Map<String, dynamic>>()) {
    final name = entry['file']! as String;
    final bytes = File('${fixtures.path}/$name').readAsBytesSync();
    if (bytes.length != entry['bytes']) {
      throw StateError('Font fixture has an unexpected length: $name');
    }
    fontBytes['accessibility-fonts/$name'] = ByteData.sublistView(bytes);
  }

  // Add only this executable's fonts to the manifest seen by google_fonts.
  // Delegate all unrelated asset loads to Flutter's normal asset resolver.
  const codec = StandardMessageCodec();
  final original = await rootBundle.load('AssetManifest.bin');
  final manifest = Map<Object?, Object?>.from(
    codec.decodeMessage(original)! as Map<Object?, Object?>,
  );
  for (final path in fontBytes.keys) {
    manifest[path] = <Object?>[
      <Object?, Object?>{'asset': path},
    ];
  }
  final manifestBytes = codec.encodeMessage(manifest)!;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) {
    final request = message!;
    final key = utf8.decode(
      request.buffer.asUint8List(request.offsetInBytes, request.lengthInBytes),
    );
    if (key == 'AssetManifest.bin') {
      return SynchronousFuture<ByteData?>(manifestBytes);
    }
    if (fontBytes[key] case final bytes?) {
      return SynchronousFuture<ByteData?>(bytes);
    }
    return messenger.delegate.send('flutter/assets', message);
  });
  for (final weight in [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.figtree(fontWeight: weight);
  }
  for (final weight in [FontWeight.w400, FontWeight.w600, FontWeight.w700]) {
    GoogleFonts.sourceSerif4(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
  for (final entry in const {
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    'packages/cupertino_icons/CupertinoIcons':
        'packages/cupertino_icons/assets/CupertinoIcons.ttf',
  }.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}
