part of 'content_database.dart';

/// Package 1 API is exported by content_database.dart. Sharing its library
/// keeps proof and reader construction private, including across isolates.
const validationContractVersion = 1;

enum InstalledReadMode { normalInstalled, recoveryFull }

enum ValidationStage {
  copyChunk,
  copyComplete,
  hashChunk,
  contentHash,
  inventoryHash,
  fullValidation,
  integrity,
  beforeHandshake,
  handshake,
  beforeCleanup,
}

/// The complete validated offer (including descriptors) and validator contract.
/// Store canonical JSON rather than shallowly immutable, caller-owned maps.
final class GenerationIdentity {
  GenerationIdentity._(this._offerJson, this.lang, this.contractVersion)
    : _key =
          '$contractVersion:$lang:${sha256.convert(utf8.encode(_offerJson))}';

  factory GenerationIdentity.fromOffer(ReleaseOffer offer) {
    final parsed = ReleaseOffer.parse(
      jsonDecode(jsonEncode(offer.toJson())) as Map<String, dynamic>,
      offer.lang,
    );
    return GenerationIdentity._(
      jsonEncode(_sortedJson(parsed.toJson())),
      parsed.lang,
      validationContractVersion,
    );
  }

  final String _offerJson;
  final String _key;
  final String lang;
  final int contractVersion;
  String get fingerprint => _key;
  ReleaseOffer get offer =>
      ReleaseOffer.parse(jsonDecode(_offerJson) as Map<String, dynamic>, lang);
  @override
  bool operator ==(Object other) =>
      other is GenerationIdentity && _key == other._key;
  @override
  int get hashCode => _key.hashCode;
}

Object? _sortedJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _sortedJson(value[key])};
  }
  if (value is List) return value.map(_sortedJson).toList();
  return value;
}

/// The owner cancels only after its last interested lease has ended.
final class ReadCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void _check() {
    if (_cancelled) throw StateError('Inhaltsöffnung abgebrochen.');
  }
}

final class InstalledReadRequest {
  InstalledReadRequest({
    required this.identity,
    required this.contentFile,
    required this.inventoryFile,
    required this.confirmCurrent,
    this.mode = InstalledReadMode.normalInstalled,
    ReadCancellation? cancellation,
  }) : cancellation = cancellation ?? ReadCancellation();

  final GenerationIdentity identity;
  final File contentFile;
  final File inventoryFile;
  final InstalledReadMode mode;
  final ReadCancellation cancellation;

  /// Package 2 must compare journal, active identity and owner epoch here.
  /// This callback confirms routing only; it cannot create a validation proof.
  final Future<bool> Function(GenerationIdentity identity) confirmCurrent;
}

final class _InstalledReadProof {
  _InstalledReadProof(this.info);
  final ContentInfo info;
}

/// Cannot be constructed or implemented outside this library. Consume once in
/// ContentDatabase.fromBoundReader; thereafter RepositoryOwner owns its close.
final class BoundReader {
  BoundReader._(this.identity, this._database);
  final GenerationIdentity identity;
  final ContentDatabase _database;
  bool _taken = false;
  Future<void>? _closing;
  ContentDatabase _take() {
    if (_taken) throw StateError('Reader bereits übernommen.');
    _taken = true;
    return _database;
  }

  Future<void> close() {
    if (_closing != null) return _closing!;
    if (_taken) throw StateError('Reader gehört bereits dem RepositoryOwner.');
    _taken = true;
    return _closing = _database.close();
  }
}

/// Resource accounting only: no owner map, lease management or open queue.
/// The existing RepositoryOwner must share one open future per identity.
final class ProcessValidationRegistry {
  ProcessValidationRegistry(this.temporaryRoot, {this.onStage});
  final Directory temporaryRoot;
  RandomAccessFile? _processLock;
  static Future<ProcessValidationRegistry>? _appRegistry;
  static String? _appSupport;
  static final _liveDirectories = <String>{};

  /// One process lifetime service, independent of Riverpod scopes/languages.
  static Future<ProcessValidationRegistry> forAppSupport(Directory support) {
    if (_appSupport != null && _appSupport != support.absolute.path) {
      throw StateError('App-Inhaltsverzeichnis wurde verändert.');
    }
    _appSupport = support.absolute.path;
    return _appRegistry ??= createProcess(
      Directory('${support.path}/content-readers'),
    );
  }

  /// A private process directory, with an OS lock (not a validation receipt).
  /// Symlinks, unknown names and directories of live processes are untouched.
  static Future<ProcessValidationRegistry> createProcess(Directory root) async {
    await root.create(recursive: true);
    final own = await root.createTemp('process-');
    _liveDirectories.add(own.path);
    final lock = await File('${own.path}/owner.lock')
        .open(mode: FileMode.append);
    await lock.lock(FileLock.exclusive);
    final registry = ProcessValidationRegistry(own).._processLock = lock;
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory ||
          _liveDirectories.contains(entity.path) ||
          !entity.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('process-')) {
        continue;
      }
      final marker = File('${entity.path}/owner.lock');
      if (await FileSystemEntity.type(marker.path, followLinks: false) !=
          FileSystemEntityType.file) {
        continue;
      }
      RandomAccessFile? stale;
      try {
        stale = await marker.open(mode: FileMode.append);
        await stale.lock(
          FileLock.exclusive,
        ); // non-blocking: another process owns it
      } on FileSystemException {
        await stale?.close();
        continue;
      }
      await stale.unlock();
      await stale.close();
      // Process directories are never reused; an unlocked old owner is gone.
      await entity.delete(recursive: true);
    }
    return registry;
  }

  /// Test/process teardown only; never called on provider invalidation.
  Future<void> closeProcess() async {
    if (_reservations != 0) throw StateError('Inhaltsreader sind noch belegt.');
    final lock = _processLock;
    if (lock == null) return;
    await lock.unlock();
    await lock.close();
    _processLock = null;
    _liveDirectories.remove(temporaryRoot.path);
    await temporaryRoot.delete(recursive: true);
  }

  /// Observation/fault seam, never a source of proofs. Errors fail closed.
  final Future<void> Function(ValidationStage stage)? onStage;
  // Keep only a fixed-size fingerprint, not the request manifest/JSON.
  final _proofs = <String, _InstalledReadProof>{};
  int _reservations = 0;
  final _epochs = <String, int>{};
  int get proofCount => _proofs.length;
  int get readerReservations => _reservations;

  void invalidateLanguage(String lang) {
    _epochs[lang] = (_epochs[lang] ?? 0) + 1;
    _proofs.removeWhere((_, proof) => proof.info.lang == lang);
  }

  /// For later Bootstrap integration. No validation authority is conferred.
  ReaderReservation reserveExternalReader() => _reserve();

  ReaderReservation _reserve() {
    if (_reservations == 3) throw StateError('Drei Inhaltsreader sind belegt.');
    _reservations++;
    return ReaderReservation._(() => _reservations--);
  }

  Future<BoundReader> openBoundReader(InstalledReadRequest request) async {
    request.cancellation._check();
    final identity = request.identity;
    final epoch = _epochs[identity.lang] ?? 0;
    if (identity.contractVersion != validationContractVersion) {
      throw StateError('Unpassender Validierungsvertrag.');
    }
    final reservation = _reserve();
    final cached = request.mode == InstalledReadMode.normalInstalled
        ? _proofs[identity._key]
        : null;
    Directory? snapshot;
    _BoundWorker? worker;
    DatabaseConnection? connection;
    final messages = ReceivePort();
    ContentInfo? validatedInfo;
    var fullSucceeded = false;
    final subscription = messages.listen((dynamic message) async {
      final data = message as List;
      final reply = data[0] as SendPort;
      try {
        request.cancellation._check();
        if (data[1] == 'info') {
          validatedInfo = data[2] as ContentInfo;
          fullSucceeded = data[3] as bool;
        } else if (data[1] != 'checkpoint') {
          await onStage?.call(ValidationStage.values[data[1] as int]);
        }
        request.cancellation._check();
        reply.send(null);
      } catch (error) {
        reply.send(error.toString());
      }
    });
    try {
      await temporaryRoot.create(recursive: true);
      snapshot = await temporaryRoot.createTemp('reader-');
      worker = await _spawnBoundWorker(
        identity._offerJson,
        identity.lang,
        request.contentFile.path,
        request.inventoryFile.path,
        snapshot.path,
        cached?.info,
        messages.sendPort,
      );
      // Explicit shutdown, so close completion precedes snapshot deletion.
      connection = await worker.drift.connect();
      await connection.executor.ensureOpen(_BoundExecutorUser());
      await connection.executor.runSelect('SELECT 1', const []);
      await onStage?.call(ValidationStage.handshake);
      request.cancellation._check();
      if (!await request.confirmCurrent(identity)) {
        throw StateError('Journal oder Reader-Epoch während Öffnung geändert.');
      }
      request.cancellation._check();
      if ((_epochs[identity.lang] ?? 0) != epoch) {
        throw StateError('Inhaltsnachweise während Öffnung invalidiert.');
      }
      final info = validatedInfo;
      if (info == null || (cached == null && !fullSucceeded)) {
        throw StateError('Vollständiges Prüfergebnis fehlt.');
      }
      final database = ContentDatabase._remote(connection.executor, info);
      final ownedWorker = worker;
      final ownedSnapshot = snapshot;
      database._boundCleanup = () => reservation.closeAfter(() async {
        await ownedWorker.shutdownAll();
        await onStage?.call(ValidationStage.beforeCleanup);
        await ownedSnapshot.delete(recursive: true);
      });
      if (fullSucceeded) {
        _proofs.remove(identity._key);
        _proofs[identity._key] = _InstalledReadProof(info);
      } else if (identical(_proofs[identity._key], cached)) {
        _proofs.remove(identity._key);
        _proofs[identity._key] = cached!;
      }
      while (_proofs.length > 2) {
        _proofs.remove(_proofs.keys.first);
      }
      return BoundReader._(identity, database);
    } catch (_) {
      _proofs.remove(identity._key);
      await reservation.closeAfter(() async {
        // A failure leaves the reservation held until process restart.
        await connection?.executor.close();
        await worker?.shutdownAll();
        if (snapshot != null) await snapshot.delete(recursive: true);
      });
      rethrow;
    } finally {
      await subscription.cancel();
      messages.close();
    }
  }
}

/// Retains failed close futures as a safety barrier; never force-releases slots.
final class ReaderReservation {
  ReaderReservation._(this._release);
  final void Function() _release;
  Future<void>? _closing;
  Future<void> closeAfter(Future<void> Function() close) =>
      _closing ??= _finish(close);
  Future<void> _finish(Future<void> Function() close) async {
    await close();
    _release();
  }
}

final class _BoundExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => supportedContentSchemaVersion;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

// Top-level seam prevents the spawn closure from capturing the registry,
// callbacks, owner, cancellation object or a SQLite handle.
final class _BoundWorker {
  _BoundWorker(this.drift, this.exited);
  final DriftIsolate drift;
  final Future<void> exited;
  Future<void>? _closing;
  Future<void> shutdownAll() => _closing ??= _shutdown();
  Future<void> _shutdown() async {
    await drift.shutdownAll();
    await exited;
  }
}

Future<_BoundWorker> _spawnBoundWorker(
  String offerJson,
  String lang,
  String source,
  String inventory,
  String directory,
  ContentInfo? proofInfo,
  SendPort events,
) async {
  final ready = ReceivePort();
  final exit = ReceivePort();
  final exited = exit.first.then<void>((_) {
    exit.close();
  });
  try {
    await Isolate.spawn(_startBoundWorker, [
      offerJson,
      lang,
      source,
      inventory,
      directory,
      proofInfo,
      events,
      ready.sendPort,
    ], onExit: exit.sendPort);
    final result = await ready.first as List;
    if (result[0] is DriftIsolate) {
      return _BoundWorker(result[0] as DriftIsolate, exited);
    }
    await exited;
    Error.throwWithStackTrace(result[0] as Object, result[1] as StackTrace);
  } catch (_) {
    exit.close();
    rethrow;
  } finally {
    ready.close();
  }
}

// One worker prepares the bytes and then becomes the Drift server. In contrast
// to a failing LazyDatabase opener, early failures need no Drift close at all.
void _startBoundWorker(List<Object?> args) async {
  final ready = args[7] as SendPort;
  try {
    final executor = await _prepareBoundExecutor(
      args[0] as String,
      args[1] as String,
      args[2] as String,
      args[3] as String,
      args[4] as String,
      args[5] as ContentInfo?,
      args[6] as SendPort,
    );
    final drift = DriftIsolate.inCurrent(
      () => DatabaseConnection(executor),
      killIsolateWhenDone: true,
    );
    ready.send([drift]);
  } catch (error, stack) {
    Isolate.exit(ready, [error, stack]);
  }
}

Future<QueryExecutor> _prepareBoundExecutor(
  String offerJson,
  String lang,
  String source,
  String inventory,
  String directory,
  ContentInfo? proofInfo,
  SendPort events,
) async {
  final offer = ReleaseOffer.parse(
    jsonDecode(offerJson) as Map<String, dynamic>,
    lang,
  );
  final copy = File('$directory/content.sqlite');
  await _copyBound(File(source), copy, offer.size, events);
  await _sessionEvent(events, ValidationStage.copyComplete.index);
  await _hashBound(copy, offer.objects['content.sqlite'] as Map, events);
  await _sessionEvent(events, ValidationStage.contentHash.index);
  final inventoryBytes = await _hashBound(
    File(inventory),
    offer.objects['history_inventory.json'] as Map,
    events,
    retain: proofInfo == null,
  );
  await _sessionEvent(events, ValidationStage.inventoryHash.index);
  final raw = sqlite3.open(copy.path, mode: OpenMode.readOnly);
  try {
    raw.execute('PRAGMA query_only=ON');
    final ContentInfo info;
    if (proofInfo == null) {
      await _sessionEvent(events, ValidationStage.fullValidation.index);
      info = validateDownloadedDatabase(
        raw,
        offer,
        jsonDecode(utf8.decode(inventoryBytes!)) as Map<String, dynamic>,
      );
    } else {
      info = proofInfo;
    }
    await _sessionEvent(events, ValidationStage.integrity.index);
    final check = raw.select('PRAGMA quick_check');
    final release = raw.select(
      'SELECT lang,version,schema_version FROM content_releases',
    );
    if (check.length != 1 ||
        check.first.values.first != 'ok' ||
        release.length != 1 ||
        release.first['lang'] != lang ||
        release.first['version'] != offer.manifest['version'] ||
        release.first['schema_version'] != offer.manifest['schema_version']) {
      throw StateError('Inhaltsidentität oder Integrität stimmt nicht.');
    }
    await _sessionEvent(events, 'info', [info, proofInfo == null]);
    await _sessionEvent(events, ValidationStage.beforeHandshake.index);
    return NativeDatabase.opened(raw, enableMigrations: false);
  } catch (_) {
    raw.close();
    rethrow;
  }
}

Future<void> _sessionEvent(
  SendPort events,
  Object kind, [
  List<Object?> extra = const [],
]) async {
  final response = ReceivePort();
  try {
    events.send([response.sendPort, kind, ...extra]);
    final error = await response.first;
    if (error != null) throw StateError(error.toString());
  } finally {
    response.close();
  }
}

Future<void> _copyBound(
  File source,
  File target,
  int size,
  SendPort events,
) async {
  final input = await source.open();
  RandomAccessFile? output;
  try {
    output = await target.open(mode: FileMode.writeOnly);
    var total = 0;
    while (true) {
      await _sessionEvent(events, 'checkpoint');
      final bytes = await input.read(64 * 1024);
      if (bytes.isEmpty) break;
      total += bytes.length;
      if (total > size) throw const FormatException('Inhaltsdatei zu groß.');
      await output.writeFrom(bytes);
      await _sessionEvent(events, ValidationStage.copyChunk.index);
    }
    if (total != size) {
      throw const FormatException('Inhaltsdatei unvollständig.');
    }
    await output.flush();
  } finally {
    await input.close();
    await output?.close();
  }
}

final class _DigestResult implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

Future<Uint8List?> _hashBound(
  File file,
  Map descriptor,
  SendPort events, {
  bool retain = false,
}) async {
  final expected = descriptor['size_bytes'] as int;
  final result = _DigestResult();
  final sink = sha256.startChunkedConversion(result);
  final bytes = retain ? BytesBuilder(copy: false) : null;
  final input = await file.open();
  var total = 0;
  try {
    while (true) {
      await _sessionEvent(events, 'checkpoint');
      final chunk = await input.read(64 * 1024);
      if (chunk.isEmpty) break;
      total += chunk.length;
      if (total > expected) throw const FormatException('Datei zu groß.');
      sink.add(chunk);
      await _sessionEvent(events, ValidationStage.hashChunk.index);
      bytes?.add(chunk);
    }
  } finally {
    await input.close();
    sink.close();
  }
  if (total != expected || result.value.toString() != descriptor['sha256']) {
    throw const FormatException('Dateihash oder Größe stimmt nicht.');
  }
  return bytes?.takeBytes();
}
