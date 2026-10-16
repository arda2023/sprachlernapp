import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import 'content_install_journal.dart';
import 'content_release_client.dart';
import 'content_update_validation.dart';
import 'context_revision_validation.dart';

typedef UpdateNotice = void Function(String phase, String message);

/// Session/write leases block activation, including an unfinished review retry.
class ContentTransitionGate {
  int _leases = 0;
  bool _switching = false;
  bool get busy => _switching || _leases > 0;
  void Function() acquire() {
    if (_switching) {
      throw StateError('Inhaltswechsel läuft. Bitte erneut öffnen.');
    }
    _leases++;
    var released = false;
    return () {
      if (!released) {
        released = true;
        _leases--;
      }
    };
  }

  Future<T> transition<T>(Future<T> Function() action) async {
    if (busy) {
      throw StateError(
        'Bitte laufende Übung und offene Inhaltsansichten zuerst schließen.',
      );
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
  });
  final ContentInstallJournal journal;
  final ContentReleaseTransport transport;
  final Future<File?> Function() currentFile;
  final ContentTransitionGate gate;
  final Future<void> Function() closeReaders, openReaders;
  final UpdateNotice? notice;
  ReleaseOffer? available, ready;
  bool _working = false;
  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_working) throw StateError('Inhaltsprüfung läuft bereits.');
    _working = true;
    try {
      return await action();
    } finally {
      _working = false;
    }
  }

  Future<void> check() => _exclusive(() async {
    notice?.call('checking', 'Private Version prüfen …');
    final active = await journal.active();
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
    final pending = await journal.read('pending');
    if (available != null &&
        pending?['manifest_sha256'] == available!.manifestHash) {
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
          ? 'Inhalt ist aktuell.'
          : 'Neue geprüfte Version verfügbar.',
    );
  });
  Future<void> download() => _exclusive(() async {
    final offer = available;
    if (offer == null) throw StateError('Zuerst nach einer Version suchen.');
    final destination = journal.generation(offer.id);
    if (await destination.exists()) {
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
      final urls = await transport.downloads(offer);
      notice?.call('downloading', 'Private Version wird heruntergeladen …');
      for (final name in ['content.sqlite', 'history_inventory.json']) {
        final descriptor = offer.objects[name] as Map;
        final output = await File('${temporary.path}/$name')
            .open(mode: FileMode.write);
        // Reserve candidate bytes while the active and recovery generations
        // remain intact. A disk-full error occurs before any pointer write.
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
      final path = '${temporary.path}/content.sqlite',
          old = (await currentFile())?.path,
          data = offer.toJson();
      await Isolate.run(() => validateDownloadedContent(path, data, old));
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
      await verifyGeneration(journal, next, previous: await currentFile());
      notice?.call('quiescing', 'Inhaltsverbindungen werden geschlossen …');
      await closeReaders(); // A failed close leaves the old pointer untouched.
      Map<String, dynamic>? prepared;
      try {
        await journal.prepare(next);
        prepared = (await journal.read('install-journal'))!;
        notice?.call('activating', 'Geprüfte Version wird aktiviert …');
        await journal.write('active', next.toJson());
        await openReaders();
        await journal.commit(next);
      } catch (_) {
        if (prepared != null) await journal.restorePrepared(prepared);
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
  final path = '${directory.path}/content.sqlite',
      data = offer.toJson(),
      old = previous?.path;
  await Isolate.run(() => validateDownloadedContent(path, data, old));
}

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
