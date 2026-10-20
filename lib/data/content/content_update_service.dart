import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import 'content_install_journal.dart';
import 'content_database.dart';
import 'content_update_diagnosis.dart';
import 'content_release_client.dart';
import 'content_update_validation.dart';
import 'context_revision_validation.dart';

typedef UpdateNotice = void Function(String phase, String message);

/// Session/write leases block activation, including an unfinished review retry.
class ContentTransitionGate {
  final _leases = <String>[];
  bool _switching = false;
  bool get busy => _switching || _leases.isNotEmpty;
  String get blockingMessage => _switching
      ? 'Ein Inhalts- oder Sprachwechsel läuft. Bitte erneut versuchen.'
      : _leases.contains('update')
      ? 'Bitte die laufende Inhaltsupdateaktion zuerst abschließen.'
      : _leases.contains('practice')
      ? 'Bitte die laufende Übung zuerst verlassen.'
      : 'Bitte offene Wortdetails, Reader oder Inhaltsansichten zuerst schließen.';
  void Function() acquire({String reason = 'content'}) {
    if (_switching) {
      throw StateError('Inhaltswechsel läuft. Bitte erneut öffnen.');
    }
    _leases.add(reason);
    var released = false;
    return () {
      if (!released) {
        released = true;
        _leases.remove(reason);
      }
    };
  }

  Future<T> transition<T>(Future<T> Function() action) async {
    if (busy) {
      throw StateError(blockingMessage);
    }
    _switching = true;
    try {
      return await action();
    } finally {
      _switching = false;
    }
  }
}

class ContentUpdateService {
  ContentUpdateService(
    this.journal,
    this.transport, {
    required this.currentFile,
    required this.gate,
    required this.closeReaders,
    required this.openReaders,
    this.notice,
    this.invalidateReadProofs,
  });
  final ContentInstallJournal journal;
  final ContentReleaseTransport transport;
  final Future<File?> Function() currentFile;
  final ContentTransitionGate gate;
  final Future<void> Function() closeReaders, openReaders;
  final UpdateNotice? notice;
  final void Function()? invalidateReadProofs;
  ReleaseOffer? available, ready;
  bool _working = false;

  /// Step of the last failed action and the exact error object it belongs to.
  /// The thrown error itself is rethrown unchanged.
  ContentUpdateDiagnosis? lastDiagnosis;
  Object? lastError;
  String _step = 'start';
  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_working) throw StateError('Inhaltsprüfung läuft bereits.');
    _working = true;
    _step = 'start';
    try {
      return await action();
    } catch (e) {
      lastError = e;
      lastDiagnosis = ContentUpdateDiagnosis.from(_step, e);
      rethrow;
    } finally {
      _working = false;
    }
  }

  Future<void> check() => _exclusive(() async {
    notice?.call('checking', 'Private Version prüfen …');
    _step = 'local_state';
    final active = await journal.active();
    _step = 'release_check';
    final offer = await transport.latest(journal.lang, active?.generation ?? 0);
    if (offer != null) {
      if (offer.generation < (active?.generation ?? 0) ||
          offer.generation == active?.generation &&
              offer.manifestHash != active?.manifestHash) {
        throw const FormatException(
          'Veraltetes oder widersprüchliches Versionsangebot.',
        );
      }
      available = offer.generation == (active?.generation ?? 0) ? null : offer;
    } else {
      available = null;
    }
    _step = 'local_state';
    final pending = await journal.read('pending');
    if (available != null &&
        pending?['manifest_sha256'] == available!.manifestHash) {
      _step = 'verify_pending';
      await verifyGeneration(
        journal,
        available!,
        previous: await currentFile(),
      );
      ready = available;
      notice?.call('ready_waiting', 'Geprüfte Version wartet auf Aktivierung.');
      return;
    }
    notice?.call(
      available == null ? 'active' : 'available',
      available == null
          ? (await currentFile() == null
                ? 'Für diese Lernsprache ist noch keine veröffentlichte Version verfügbar.'
                : 'Inhalt ist aktuell.')
          : 'Neue geprüfte Version verfügbar.',
    );
  });
  Future<void> download() => _exclusive(() async {
    final offer = available;
    if (offer == null) throw StateError('Zuerst nach einer Version suchen.');
    _step = 'local_state';
    final destination = journal.generation(offer.id);
    if (await destination.exists()) {
      _step = 'verify_existing';
      final stored = jsonDecode(
        await File('${destination.path}/release.json').readAsString(),
      );
      if (stored['manifest_sha256'] != offer.manifestHash) {
        throw const FormatException('Generation bereits anders belegt.');
      }
      await verifyGeneration(journal, offer, previous: await currentFile());
      ready = offer;
      notice?.call('ready_waiting', 'Geprüft. Nach Ende der Übung aktivieren.');
      return;
    }
    final temporary = Directory('${destination.path}.part');
    if (await temporary.exists()) await temporary.delete(recursive: true);
    await temporary.create(recursive: true);
    try {
      _step = 'download_link';
      final urls = await transport.downloads(offer);
      notice?.call('downloading', 'Private Version wird heruntergeladen …');
      for (final name in ['content.sqlite', 'history_inventory.json']) {
        final descriptor = offer.objects[name] as Map;
        final output = await File('${temporary.path}/$name')
            .open(mode: FileMode.write);
        // Reserve candidate bytes while the active and recovery generations
        // remain intact. A disk-full error occurs before any pointer write.
        _step = 'download_reserve';
        try {
          var remaining = descriptor['size_bytes'] as int;
          final reservation = List<int>.filled(1024 * 1024, 0);
          while (remaining > 0) {
            final n = remaining.clamp(0, reservation.length);
            await output.writeFrom(reservation, 0, n);
            remaining -= n;
          }
          await output.flush();
          await output.setPosition(0);
        } catch (_) {
          await output.close();
          rethrow;
        }
        _step = 'download_transfer';
        final digestSink = _DigestSink();
        final hash = sha256.startChunkedConversion(digestSink);
        var size = 0;
        try {
          await for (final chunk in transport.bytes(urls[name]!)) {
            size += chunk.length;
            if (size > descriptor['size_bytes'] ||
                size > maxContentDownloadBytes) {
              throw const FormatException(
                'Download überschreitet die vereinbarte Größe.',
              );
            }
            hash.add(chunk);
            await output.writeFrom(chunk);
          }
          hash.close();
          await output.flush();
        } finally {
          await output.close();
        }
        if (size != descriptor['size_bytes'] ||
            digestSink.value?.toString() != descriptor['sha256']) {
          throw const FormatException(
            'Download unvollständig oder Prüfsumme falsch.',
          );
        }
      }
      notice?.call(
        'verifying',
        'Inhalte und vollständige Historie werden geprüft …',
      );
      _step = 'verify';
      final data = offer.toJson();
      await _validateInIsolate(
        '${temporary.path}/content.sqlite',
        data,
        (await currentFile())?.path,
      );
      _step = 'install';
      await File('${temporary.path}/release.json')
          .writeAsString(jsonEncode(data), flush: true);
      await temporary.rename(destination.path);
      ready = offer;
      await journal.write('pending', offer.toJson());
      notice?.call('ready_waiting', 'Geprüft. Nach Ende der Übung aktivieren.');
    } catch (_) {
      if (await temporary.exists()) await temporary.delete(recursive: true);
      rethrow;
    }
  });
  Future<void> activate() => _exclusive(
    () => gate.transition(() async {
      _step = 'local_state';
      var offer = ready;
      final pending = await journal.read('pending');
      offer ??= pending == null
          ? null
          : ReleaseOffer.parse(pending, journal.lang);
      if (offer == null) {
        throw StateError('Keine geprüfte Version zur Aktivierung.');
      }
      // Reauthorize immediately before activation; expired authorization is never
      // silently treated as permission. Already installed content remains offline.
      final active = await journal.active();
      _step = 'reauthorize';
      final authorized = await transport.latest(
        journal.lang,
        active?.generation ?? 0,
      );
      if (authorized == null ||
          authorized.id != offer.id ||
          authorized.manifestHash != offer.manifestHash) {
        throw StateError('Versionsfreigabe geändert. Bitte neu prüfen.');
      }
      final next = offer;
      _step = 'verify';
      await verifyGeneration(journal, next, previous: await currentFile());
      notice?.call('quiescing', 'Inhaltsverbindungen werden geschlossen …');
      _step = 'close_readers';
      await closeReaders(); // A failed close leaves the old pointer untouched.
      Map<String, dynamic>? prepared;
      _step = 'activate';
      try {
        invalidateReadProofs?.call();
        await journal.prepare(next);
        prepared = (await journal.read('install-journal'))!;
        notice?.call('activating', 'Geprüfte Version wird aktiviert …');
        await journal.write('active', next.toJson());
        await openReaders();
        // Recovery may have made the previous generation usable again. That
        // is not a successful activation of next and must never commit it.
        if (contextCanonicalHash(await journal.read('active')) !=
            contextCanonicalHash(next.toJson())) {
          throw StateError('Aktivierung wurde auf den Vorgänger zurückgesetzt.');
        }
        await journal.commit(next);
      } catch (_) {
        if (prepared != null) {
          invalidateReadProofs?.call();
          await journal.restorePrepared(prepared);
        }
        await openReaders();
        rethrow;
      }
      ready = null;
      available = null;
      if (await journal.named('pending').exists()) {
        await journal.named('pending').delete();
      }
      notice?.call('active', 'Neue Version aktiv. Lernstand bleibt erhalten.');
    }),
  );
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

Future<void> verifyGeneration(
  ContentInstallJournal journal,
  ReleaseOffer offer, {
  File? previous,
}) async {
  final directory = journal.generation(offer.id);
  for (final name in ['content.sqlite', 'history_inventory.json']) {
    final file = File('${directory.path}/$name');
    final d = offer.objects[name] as Map;
    if (!await file.exists() ||
        await file.length() != d['size_bytes'] ||
        (await sha256.bind(file.openRead()).first).toString() != d['sha256']) {
      throw const FormatException(
        'Installierte Generation beschädigt. Reparatur erforderlich.',
      );
    }
  }
  await _validateInIsolate(
    '${directory.path}/content.sqlite',
    offer.toJson(),
    previous?.path,
  );
}

/// Top-level on purpose: a closure created inside an instance method can carry
/// that method's context (`this`, HTTP client, provider callbacks) into the
/// isolate message, which the VM rejects as unsendable.
Future<void> _validateInIsolate(
  String path,
  Map<String, dynamic> data,
  String? old,
) => Isolate.run(() => validateDownloadedContent(path, data, old));

/// Called before returning any repository to app code. Committed generations
/// never fall back to the asset: newer learner references may already exist.
Future<ReleaseOffer?> recoverContentInstallation(
  ContentInstallJournal journal,
) async {
  final log = await journal.read('install-journal');
  final pointer = await journal.read('active');
  final active = await journal.active();
  if (log?['state'] == 'committed' &&
      (active == null ||
          active.manifestHash != log?['next']?['manifest_sha256'])) {
    throw const FormatException(
      'Aktiver Zeiger widerspricht der zuletzt aktivierten Generation. Reparatur erforderlich.',
    );
  }
  if (log?['state'] == 'prepared' &&
      contextCanonicalHash(pointer) != contextCanonicalHash(log?['previous']) &&
      contextCanonicalHash(pointer) != contextCanonicalHash(log?['next'])) {
    throw const FormatException(
      'Installationsjournal und Versionszeiger widersprechen sich.',
    );
  }
  if (log?['state'] == 'prepared' &&
      active?.manifestHash == log?['next']?['manifest_sha256']) {
    try {
      await verifyGeneration(journal, active!);
      await journal.commit(active);
    } catch (_) {
      await journal.restorePrepared(log!);
      final previous = await journal.active();
      if (previous != null) await verifyGeneration(journal, previous);
      return previous;
    }
  } else if (active != null) {
    await verifyGeneration(journal, active);
  }
  return active;
}

/// Metadata only. A consistent journal is not proof that its files are usable.
class InstalledContentState {
  InstalledContentState(this.pointer, this.log, this.offer)
    : stamp = contextCanonicalHash({'active': pointer, 'journal': log});
  final Map<String, dynamic>? pointer, log;
  final ReleaseOffer? offer;
  final String stamp;
  bool get prepared => log?['state'] == 'prepared';
  bool get preparedNext =>
      prepared &&
      offer != null &&
      contextCanonicalHash(pointer) == contextCanonicalHash(log?['next']);
  String? get fingerprint => offer != null
      ? GenerationIdentity.fromOffer(offer!).fingerprint
      : pointer == null
      ? null
      : contextCanonicalHash(pointer!['manifest']);
}

class RecoveredGenerationChanged implements Exception {
  const RecoveredGenerationChanged();
}

Future<InstalledContentState> resolveInstalledState(
  ContentInstallJournal journal,
) async {
  final log = await journal.read('install-journal');
  final pointer = await journal.read('active');
  final offer = pointer == null || pointer['bootstrap'] == true
      ? null
      : ReleaseOffer.parse(pointer, journal.lang);
  if (log?['state'] == 'committed' &&
      (offer == null ||
          contextCanonicalHash(pointer) !=
              contextCanonicalHash(log?['next']))) {
    throw const FormatException(
      'Aktiver Zeiger widerspricht der aktivierten Generation.',
    );
  }
  if (log?['state'] == 'prepared' &&
      contextCanonicalHash(pointer) != contextCanonicalHash(log?['previous']) &&
      contextCanonicalHash(pointer) != contextCanonicalHash(log?['next'])) {
    throw const FormatException(
      'Installationsjournal und Versionszeiger widersprechen sich.',
    );
  }
  return InstalledContentState(pointer, log, offer);
}

/// Normal installed reads use the process proof. Recovery always validates in
/// full, then commits the exact reader; no second path-only reopen follows.
Future<BoundReader?> openRecoveredContent(
  ContentInstallJournal journal,
  ProcessValidationRegistry registry, {
  required String? expectedFingerprint,
  required ReadCancellation cancellation,
  required bool Function() isCurrent,
}) async {
  final initial = await resolveInstalledState(journal);
  final offer = initial.offer;
  if (offer == null) return null;
  final identity = GenerationIdentity.fromOffer(offer);
  if (expectedFingerprint != null &&
      identity.fingerprint != expectedFingerprint) {
    throw const RecoveredGenerationChanged();
  }
  if (initial.prepared) registry.invalidateLanguage(journal.lang);
  bool valid() => !cancellation.isCancelled && isCurrent();
  try {
    return await registry.openBoundReader(
      InstalledReadRequest(
        identity: identity,
        contentFile: File(
          '${journal.generation(offer.id).path}/content.sqlite',
        ),
        inventoryFile: File(
          '${journal.generation(offer.id).path}/history_inventory.json',
        ),
        mode: initial.prepared
            ? InstalledReadMode.recoveryFull
            : InstalledReadMode.normalInstalled,
        cancellation: cancellation,
        confirmCurrent: (_) async {
          if (!valid() ||
              (await resolveInstalledState(journal)).stamp != initial.stamp) {
            return false;
          }
          if (!valid()) return false;
          if (initial.preparedNext) {
            await journal.commit(offer);
            final committed = await resolveInstalledState(journal);
            return valid() &&
                committed.fingerprint == identity.fingerprint &&
                committed.log?['state'] == 'committed';
          }
          return valid();
        },
      ),
    );
  } catch (_) {
    // A cancelled/stale owner must never roll back another transition.
    if (initial.preparedNext &&
        valid() &&
        (await resolveInstalledState(journal)).stamp == initial.stamp) {
      registry.invalidateLanguage(journal.lang);
      await journal.restorePrepared(initial.log!);
      // Caller re-resolves once under the restored key; invalidation forces
      // its full validation before it can return a repository.
      throw const RecoveredGenerationChanged();
    }
    rethrow;
  }
}
