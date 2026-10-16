import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/content/content_auth_repository.dart';
import '../../data/content/content_install_journal.dart';
import '../../data/content/content_release_client.dart';
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

class ContentUpdateState {
  const ContentUpdateState(this.phase, this.message, {this.signedIn = false});
  final String phase, message;
  final bool signedIn;
}

final contentUpdateProvider =
    NotifierProvider<ContentUpdateController, ContentUpdateState>(
      ContentUpdateController.new,
    );

class ContentUpdateController extends Notifier<ContentUpdateState> {
  ContentUpdateService? _service;
  ContentReleaseClient? _client;
  DateTime? _lastCheck;
  @override
  ContentUpdateState build() {
    final observer = _ResumeObserver(() => unawaited(check(automatic: true)));
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(observer);
      _client?.close();
    });
    Future.microtask(() => check(automatic: true));
    return const ContentUpdateState('idle', 'Offline-Inhalt bleibt verfügbar.');
  }

  void _notice(String phase, String message) {
    if (ref.mounted) {
      state = ContentUpdateState(
        phase,
        message,
        signedIn: ref.read(contentAuthProvider).signedIn,
      );
    }
  }

  Future<ContentUpdateService> _getService() async {
    if (_service != null) return _service!;
    final auth = ref.read(contentAuthProvider);
    await auth.initialize();
    if (!auth.configured) {
      throw StateError('Private Inhaltsupdates sind noch nicht eingerichtet.');
    }
    final support = await getApplicationSupportDirectory();
    final key = await ref.read(activeContentKeyProvider.future);
    var owner = contentOwnerFor(key);
    final journal = ContentInstallJournal(support, key.lang);
    _client = ContentReleaseClient(
      Uri.parse(auth.url),
      auth.publicKey,
      auth.accessToken,
    );
    return _service = ContentUpdateService(
      journal,
      _client!,
      gate: contentTransitionGate,
      notice: _notice,
      currentFile: () async {
        final file = await journal.currentFile();
        return file != null && await file.exists() ? file : null;
      },
      closeReaders: () async {
        owner = contentOwnerFor(
          await ref.read(activeContentKeyProvider.future),
        );
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
        ref.invalidate(activeContentKeyProvider);
        ref.invalidate(contentRepositoryProvider);
        await ref.read(contentRepositoryProvider.future);
      },
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _notice(
        'error',
        'Inhaltsaktion nicht abgeschlossen. Anmeldung, Freigabe und Verbindung prüfen. Bisheriger Inhalt bleibt erhalten.',
      );
    }
  }

  Future<void> check({bool automatic = false}) async {
    if (automatic &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(hours: 1)) {
      return;
    }
    _lastCheck = DateTime.now();
    final auth = ref.read(contentAuthProvider);
    if (!auth.configured) {
      if (!automatic) {
        _notice(
          'unconfigured',
          'Privater Inhaltsserver noch nicht eingerichtet.',
        );
      }
      return;
    }
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
        'Bitte die laufende Übung oder Inhaltsansicht zuerst verlassen.',
      );
      return;
    }
    await (await _getService()).activate();
  });
  Future<void> requestCode(String email) => _run(() async {
    await ref.read(contentAuthProvider).requestCode(email);
    _notice('code_sent', 'Code angefordert. Bitte E-Mail prüfen.');
  });
  Future<void> verifyCode(String email, String code) => _run(() async {
    await ref.read(contentAuthProvider).verifyCode(email, code);
    await check();
  });
  Future<bool> signInWithPassword(String email, String password) async {
    _notice('signing_in', 'Anmeldung wird geprüft …');
    try {
      await ref.read(contentAuthProvider).signInWithPassword(email, password);
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
