import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
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

final uiStorageErrorProvider = StateProvider<String?>((ref) => null);

final readingStoreProvider = Provider<JsonStore>((ref) => MemoryJsonStore());
final importStoreProvider = Provider<JsonStore>((ref) => MemoryJsonStore());

// ---------------------------------------------------------------- progress

/// Where the learner stopped in a story (scroll position 0–1).
class ReadingEntry {
  const ReadingEntry({
    required this.fraction,
    required this.updatedAt,
    this.finished = false,
  });

  final double fraction;
  final DateTime updatedAt;

  /// Reached the end once; stays true when scrolling back up.
  final bool finished;

  /// Started but not finished: belongs in "Weiterlesen".
  bool get inProgress => !finished && fraction >= 0.02;

  Map<String, Object> toJson() => {
    'fraction': fraction,
    'updatedAt': updatedAt.toIso8601String(),
    'finished': finished,
  };

  static ReadingEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final fraction = json['fraction'];
    final at = DateTime.tryParse('${json['updatedAt']}');
    if (fraction is! num || at == null) return null;
    return ReadingEntry(
      fraction: fraction.toDouble().clamp(0.0, 1.0),
      updatedAt: at,
      finished: json['finished'] == true,
    );
  }
}

class ReadingProgressNotifier extends Notifier<Map<String, ReadingEntry>> {
  int _generation = 0;
  late Future<void> _loaded;
  late JsonStore _store;

  @override
  Map<String, ReadingEntry> build() {
    _store = ref.watch(readingStoreProvider);
    final generation = ++_generation;
    _loaded = _load(_store, generation);
    return const {};
  }

  Future<void> _load(JsonStore store, int generation) async {
    final json = await store.read();
    if (!ref.mounted || generation != _generation || json is! Map) return;
    final loaded = <String, ReadingEntry>{
      for (final MapEntry(:key, :value) in json.entries)
        '$key': ?ReadingEntry.fromJson(value),
    };
    state = {
      ...loaded,
      for (final MapEntry(:key, :value) in state.entries)
        key: ReadingEntry(
          fraction: value.fraction,
          updatedAt: value.updatedAt,
          finished: value.finished || (loaded[key]?.finished ?? false),
        ),
    };
  }

  Future<void> _save(int generation) async {
    await _loaded;
    if (!ref.mounted || generation != _generation) return;
    await _store.write({
      for (final MapEntry(:key, :value) in state.entries) key: value.toJson(),
    });
  }

  /// Records the reading position of [storyId].
  void report(String storyId, double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    final before = state[storyId];
    final finished = (before?.finished ?? false) || f >= 0.98;
    if (before != null &&
        (before.fraction - f).abs() < 0.005 &&
        before.finished == finished) {
      return;
    }
    state = {
      ...state,
      storyId: ReadingEntry(
        fraction: f,
        updatedAt: DateTime.now(),
        finished: finished,
      ),
    };
    _save(_generation).catchError((Object error) {
      if (ref.mounted) {
        ref.read(uiStorageErrorProvider.notifier).state = error.toString();
      }
    });
  }
}

final readingProgressProvider =
    NotifierProvider<ReadingProgressNotifier, Map<String, ReadingEntry>>(
      ReadingProgressNotifier.new,
    );

// ----------------------------------------------------------------- imports

enum ImportSource { pasted, file, youtube, web }

/// A text the learner brought in. Read-only in the reader; word lookups have
/// no curated dictionary; on-demand translations use the existing runtime flow.
class ImportedText {
  const ImportedText({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final ImportSource source;
  final DateTime createdAt;

  int get wordCount => RegExp(r"[A-Za-zÀ-ÿ]+").allMatches(body).length;

  /// About 180 words per minute for a learner.
  int get readingMinutes => (wordCount / 180).ceil().clamp(1, 999);

  List<String> get paragraphs => [
    for (final part in body.split(RegExp(r'\n\s*\n')))
      if (part.trim().isNotEmpty)
        part.trim().replaceAll(RegExp(r'\s*\n\s*'), ' '),
  ];

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
  };

  static ImportedText? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['createdAt']}');
    if (json['id'] is! String || json['body'] is! String || at == null) {
      return null;
    }
    return ImportedText(
      id: json['id'] as String,
      title: '${json['title'] ?? 'Eigener Text'}',
      body: json['body'] as String,
      source:
          ImportSource.values.asNameMap()[json['source']] ??
          ImportSource.pasted,
      createdAt: at,
    );
  }
}

class ImportedTextsNotifier extends Notifier<List<ImportedText>> {
  /// PRODUCT.md: imported texts are limited to 5,000 words.
  static const maxWords = 5000;

  int _generation = 0;
  late Future<void> _loaded;
  late JsonStore _store;
  final _removed = <String>{};

  @override
  List<ImportedText> build() {
    _store = ref.watch(importStoreProvider);
    _removed.clear();
    final generation = ++_generation;
    _loaded = _load(_store, generation);
    return const [];
  }

  Future<void> _load(JsonStore store, int generation) async {
    final json = await store.read();
    if (!ref.mounted || generation != _generation || json is! List) return;
    final loaded = [for (final item in json) ?ImportedText.fromJson(item)];
    final known = {for (final t in state) t.id};
    state = [
      ...state,
      ...loaded.where((t) => !known.contains(t.id) && !_removed.contains(t.id)),
    ];
  }

  /// Adds [body] and returns it, or throws [FormatException] with a message
  /// for the learner.
  ImportedText add(String body, {ImportSource source = ImportSource.pasted}) {
    final text = body.trim();
    if (text.isEmpty) {
      throw const FormatException('Der Text ist leer.');
    }
    final now = DateTime.now();
    final imported = ImportedText(
      id: 'import-${now.microsecondsSinceEpoch}',
      title: _titleFor(text),
      body: text,
      source: source,
      createdAt: now,
    );
    if (imported.wordCount > maxWords) {
      throw const FormatException(
        'Der Text ist zu lang – höchstens 5.000 Wörter.',
      );
    }
    state = [imported, ...state];
    _save();
    return imported;
  }

  void remove(String id) {
    _removed.add(id);
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    _save();
  }

  void _save() {
    final generation = _generation;
    _loaded
        .then((_) async {
          if (!ref.mounted || generation != _generation) return;
          await _store.write([for (final t in state) t.toJson()]);
        })
        .catchError((Object error) {
          if (ref.mounted) {
            ref.read(uiStorageErrorProvider.notifier).state = error.toString();
          }
        });
  }

  static String _titleFor(String text) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length <= 60 && firstLine.split(' ').length <= 10) {
      return firstLine;
    }
    final words = firstLine.split(RegExp(r'\s+')).take(7).join(' ');
    return '$words …';
  }
}

final importedTextsProvider =
    NotifierProvider<ImportedTextsNotifier, List<ImportedText>>(
      ImportedTextsNotifier.new,
    );
