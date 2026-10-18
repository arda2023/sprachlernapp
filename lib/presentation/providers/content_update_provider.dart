import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/content/content_auth_repository.dart';
import '../../data/content/content_install_journal.dart';
import '../../data/content/content_release_client.dart';
import '../../data/content/content_update_diagnosis.dart';
import '../../data/content/content_update_service.dart';
import 'database_providers.dart';

final contentAuthProvider = Provider<ContentAuthRepository>((ref) {
  final auth = ContentAuthRepository(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  ref.onDispose(() => unawaited(auth.close()));
  return auth;
});

// Each language owns its HTTP client; authentication is shared deliberately.
final contentReleaseTransportProvider = Provider.family<ContentReleaseTransport, String>((ref, lang) {
  final auth = ref.read(contentAuthProvider);
  final client = ContentReleaseClient(Uri.parse(auth.url), auth.publicKey, auth.accessToken);
  ref.onDispose(client.close);
  return client;
});

class ContentUpdateState {
  const ContentUpdateState(
    this.phase,
    this.message, {
    this.signedIn = false,
    this.diagnosis,
  });
  final String phase, message;
  final bool signedIn;

  /// Safe step/status/code line of the last failure; never secrets or bodies.
  final String? diagnosis;
}

final contentUpdateProvider =
    NotifierProvider<ContentUpdateController, ContentUpdateState>(
      ContentUpdateController.new,
    );

class ContentUpdateController extends Notifier<ContentUpdateState> {
  ContentUpdateService? _service;
  final _lastChecks = <String, DateTime>{};
  String? _language;
  int _epoch = 0;
  @override
  ContentUpdateState build() {
    final selection = ref.watch(selectedContentLanguageProvider);
    _language = selection.isLoading ? null : selection.asData?.value;
    final epoch = ++_epoch;
    _service = null;
    final observer = _ResumeObserver(() => unawaited(check(automatic: true)));
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(observer);
    });
    if (_language != null) {
      Future.microtask(() { if (ref.mounted && epoch == _epoch) unawaited(check(automatic: true)); });
    }
    return ContentUpdateState('idle', 'Installierter Inhalt bleibt offline verfügbar.', signedIn: ref.read(contentAuthProvider).signedIn);
  }

  void _notice(String phase, String message, {String? diagnosis}) {
    if (ref.mounted) {
      state = ContentUpdateState(
        phase,
        message,
        signedIn: ref.read(contentAuthProvider).signedIn,
        diagnosis: diagnosis,
      );
    }
  }

  Future<ContentUpdateService> _getService() async {
    if (_service != null) return _service!;
    final epoch = _epoch;
    final String lang = await ref.read(selectedContentLanguageProvider.future);
    final auth = ref.read(contentAuthProvider);
    await auth.initialize();
    if (!auth.configured) {
      throw StateError('Private Inhaltsupdates sind noch nicht eingerichtet.');
    }
    final support = (await ref.read(contentInstallerProvider(lang).future)).supportDirectory;
    final key = await ref.read(activeContentKeyProvider.future);
    if (!ref.mounted || epoch != _epoch || key.lang != lang) throw StateError('Sprachauswahl hat sich geändert.');
    var owner = ref.read(contentOwnerProvider(key));
    final journal = ContentInstallJournal(support, key.lang);
    return _service = ContentUpdateService(
      journal,
      ref.read(contentReleaseTransportProvider(lang)),
      gate: contentTransitionGate,
      notice: (phase, message) {
        if (ref.mounted && epoch == _epoch) _notice(phase, message);
      },
      currentFile: () async {
        final file = await journal.currentFile();
        return file != null && await file.exists() ? file : null;
      },
      closeReaders: () async {
        if (!ref.mounted || epoch != _epoch) throw StateError('Sprachauswahl hat sich geändert.');
        final activeKey = await ref.read(activeContentKeyProvider.future);
        if (activeKey.lang != lang) throw StateError('Sprachauswahl hat sich geändert.');
        owner = ref.read(contentOwnerProvider(activeKey));
        owner.pause();
        ref.invalidate(contentRepositoryProvider);
        await Future<void>.delayed(Duration.zero);
        try {
          await owner.closed();
        } catch (_) {
          owner.resume();
          rethrow;
        }
      },
      openReaders: () async {
        owner.resume();
        if (!ref.mounted || epoch != _epoch) return;
        ref.invalidate(activeContentKeyProvider);
        ref.invalidate(contentRepositoryProvider);
        await ref.read(contentRepositoryProvider.future);
      },
    );
  }

  Future<void> _run(Future<void> Function() action, {bool lease = true}) async {
    final epoch = _epoch;
    void Function()? release;
    try {
      if (lease) release = contentTransitionGate.acquire(reason: 'update');
      await action();
    } catch (e) {
      if (!ref.mounted || epoch != _epoch) return;
      final service = _service;
      final diagnosis =
          service != null && identical(service.lastError, e)
          ? service.lastDiagnosis!
          : ContentUpdateDiagnosis.from('setup', e);
      final line = diagnosis.describe();
      debugPrint('Inhaltsupdate fehlgeschlagen: $line');
      _notice(
        'error',
        switch (diagnosis.code) {
          'READER_REQUIRED' => 'Für diese Lernsprache fehlt die Leserfreigabe. Freigabe für diese Sprache anfordern.',
          'NETWORK' || 'TIMEOUT' || 'TLS' => 'Inhaltsserver nicht erreichbar. Verbindung prüfen und erneut versuchen.',
          'FORMAT_INVALID' => 'Inhaltsprüfung fehlgeschlagen. Installation oder Download beschädigt; erneut prüfen.',
          _ => 'Inhaltsaktion nicht abgeschlossen. Anmeldung, Freigabe und Verbindung prüfen. Bisheriger Inhalt bleibt erhalten.',
        },
        diagnosis: line,
      );
    } finally {
      release?.call();
    }
  }

  Future<void> check({bool automatic = false}) async {
    final auth = ref.read(contentAuthProvider);
    if (!auth.configured) {
      if (!automatic) _notice('unconfigured', 'Privater Inhaltsserver noch nicht eingerichtet.');
      return;
    }
    final lang = _language;
    if (lang == null) return;
    final lastCheck = _lastChecks[lang];
    if (automatic && lastCheck != null && DateTime.now().difference(lastCheck) < const Duration(hours: 1)) return;
    _lastChecks[lang] = DateTime.now();
    await _run(() async {
      await auth.initialize();
      if (automatic && !auth.signedIn) return;
      await (await _getService()).check();
    });
  }

  Future<void> download() => _run(() async => (await _getService()).download());
  Future<void> activate() => _run(() async {
    if (contentTransitionGate.busy) {
      _notice(
        'ready_waiting',
        contentTransitionGate.blockingMessage,
      );
      return;
    }
    // Protect async setup, then hand over synchronously to the service's
    // transition lock. Activation must not hold its own blocking lease.
    final release = contentTransitionGate.acquire(reason: 'update');
    late ContentUpdateService service;
    try { service = await _getService(); } finally { release(); }
    await service.activate();
  }, lease: false);
  Future<void> requestCode(String email) => _run(() async {
    await ref.read(contentAuthProvider).requestCode(email);
    _notice('code_sent', 'Code angefordert. Bitte E-Mail prüfen.');
  });
  Future<void> verifyCode(String email, String code) => _run(() async {
    await ref.read(contentAuthProvider).verifyCode(email, code);
    await check();
  });
  Future<bool> signInWithPassword(String email, String password) async {
    final epoch = _epoch;
    if (contentTransitionGate.busy) return false;
    final release = contentTransitionGate.acquire(reason: 'update');
    _notice('signing_in', 'Anmeldung wird geprüft …');
    try {
      await ref.read(contentAuthProvider).signInWithPassword(email, password);
      if (!ref.mounted || epoch != _epoch) return false;
      _notice(
        'idle',
        'Angemeldet. Nach Updates suchen, um die Lesefreigabe zu prüfen.',
      );
      return true;
    } on AuthException catch (e) {
      final message = switch (e.code) {
        'credentials_required' => 'E-Mail-Adresse und Passwort angeben.',
        'invalid_credentials' => 'E-Mail-Adresse oder Passwort ist falsch.',
        'email_not_confirmed' => 'E-Mail-Adresse noch nicht bestätigt. Kontostatus administrativ prüfen.',
        'user_banned' =>
          'Dieses Konto ist gesperrt. Kontostatus administrativ prüfen.',
        _ => 'Anmeldung fehlgeschlagen. Zugangsdaten und Kontostatus prüfen.',
      };
      _notice('error', message);
    } catch (_) {
      _notice(
        'error',
        'Anmeldung nicht abgeschlossen. Einrichtung und Verbindung prüfen.',
      );
    } finally {
      release();
    }
    return false;
  }

  Future<void> signOut() => _run(() async {
    await ref.read(contentAuthProvider).signOut();
    _notice(
      'idle',
      'Abgemeldet. Installierter Inhalt bleibt offline verfügbar.',
    );
  });
}

class _ResumeObserver extends WidgetsBindingObserver {
  _ResumeObserver(this.resume);
  final void Function() resume;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) resume();
  }
}
