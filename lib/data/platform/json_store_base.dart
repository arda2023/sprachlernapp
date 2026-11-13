import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Small JSON document for UI state (reading position, imported texts).
/// Never learner data: SRS state stays in user.db.
abstract class JsonStore {
  Future<Object?> read();
  Future<void> write(Object? json);
}

/// Default (tests, previews): kept for the app's lifetime only.
class MemoryJsonStore implements JsonStore {
  Object? _value;
  @override
  Future<Object?> read() async => _value;
  @override
  Future<void> write(Object? json) async => _value = json;
}

/// `<support>/ui/<name>.json`, independent of content packs. Any
/// I/O failure degrades to "nothing stored".
class FileJsonStore implements JsonStore {
  FileJsonStore(this.name);
  final String name;
  Future<void> _writes = Future.value();

  Future<File> get _file async => File(
    p.join((await getApplicationSupportDirectory()).path, 'ui', '$name.json'),
  );

  @override
  Future<Object?> read() async {
    try {
      final file = await _file;
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Object? json) {
    final encoded = jsonEncode(json);
    final write = _writes.then((_) async {
      final file = await _file;
      await file.parent.create(recursive: true);
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(encoded, flush: true);
      await temp.rename(file.path);
    });
    _writes = write.catchError((Object _) {});
    return write;
  }
}
