import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:sprachapp/presentation/providers/content_update_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';

import 'fixtures/language_selection.dart';
import 'fixtures/portuguese_installation.dart';

class _Auth extends ContentAuthRepository {
  _Auth({this.authenticated = false})
    : super('https://synthetic.invalid', 'public-test-only');
  final bool authenticated;
  @override
  bool get signedIn => authenticated;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('service, transport, pending status and activation stay bound through repeated switches', () async {
    final h = LanguageHarness(
      Directory.systemTemp.createTempSync('language-update-'),
    );
    final en = PortugueseTransport(
      Directory('${h.root.path}/en-transport')..createSync(),
    );
    final pt = PortugueseTransport(
      Directory('${h.root.path}/pt-transport')..createSync(),
    );
    h.auth = _Auth();
    h.transports.addAll({'en': en, 'pt-BR': pt});
    final c = h.scope();
    addTearDown(() async {
      c.dispose();
      await h.close();
    });
    await c.read(selectedContentLanguageProvider.future);
    final sub = c.listen(contentUpdateProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await c.read(contentUpdateProvider.notifier).check();
    expect(en.requests, ['en']);
    expect(pt.requests, isEmpty);
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    await c.read(contentUpdateProvider.notifier).check();
    expect(pt.requests, ['pt-BR']);
    expect(c.read(contentUpdateProvider).phase, 'available');
    await c.read(contentUpdateProvider.notifier).download();
    expect(c.read(contentUpdateProvider).phase, 'ready_waiting');
    expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
      true,
    );
    expect(c.read(contentUpdateProvider).phase, isNot('ready_waiting'));
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    await c.read(contentUpdateProvider.notifier).check();
    expect(c.read(contentUpdateProvider).phase, 'ready_waiting');
    await c.read(contentUpdateProvider.notifier).activate();
    expect(c.read(contentUpdateProvider).phase, 'active');
    expect((await c.read(contentRepositoryProvider.future)).info.lang, 'pt-BR');
    expect(en.requests, ['en']);
    expect(pt.requests.every((l) => l == 'pt-BR'), true);
  });
  test('in-flight request rejects switch; stale notice after forced lifecycle reset cannot change next language', () async {
    final h = LanguageHarness(
      Directory.systemTemp.createTempSync('late-language-update-'),
    );
    final transport = PortugueseTransport(h.root);
    h.auth = _Auth();
    h.transports.addAll({'en': transport, 'pt-BR': transport});
    final c = h.scope();
    addTearDown(() async {
      c.dispose();
      await h.close();
    });
    await (await c.read(userRepositoryProvider.future)).deviceId();
    final sub = c.listen(contentUpdateProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    transport.pending = Completer<void>();
    final checking = c.read(contentUpdateProvider.notifier).check();
    while (transport.requests.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      false,
    );
    expect(
      c.read(languageSelectionProvider).message,
      contains('Inhaltsupdateaktion'),
    );
    // Deliberately bypass the command to exercise a late callback after rebuild.
    await h.db.customUpdate(
      "UPDATE settings SET target_lang='pt-BR' WHERE id=1",
    );
    c.invalidate(selectedContentLanguageProvider);
    expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
    c.read(contentUpdateProvider);
    transport.pending!.complete();
    await checking;
    expect(c.read(contentUpdateProvider).phase, 'idle');
    transport.pending = null;
    await c.read(contentUpdateProvider.notifier).check();
    expect(c.read(contentUpdateProvider).phase, 'available');
    expect(transport.requests, ['en', 'pt-BR']);
  });
  test('automatic check deadline is independent for each language', () async {
    final h = LanguageHarness(
      Directory.systemTemp.createTempSync('language-check-deadline-'),
    );
    final transport = PortugueseTransport(h.root);
    h.auth = _Auth(authenticated: true);
    h.transports.addAll({'en': transport, 'pt-BR': transport});
    final c = h.scope();
    addTearDown(() async {
      c.dispose();
      await h.close();
    });
    await c.read(selectedContentLanguageProvider.future);
    final sub = c.listen(contentUpdateProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 100 && transport.requests.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(transport.requests, ['en']);
    while (contentTransitionGate.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    for (var i = 0; i < 100 && transport.requests.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(transport.requests, ['en', 'pt-BR']);
    while (contentTransitionGate.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
      true,
    );
    await c.read(contentUpdateProvider.notifier).check(automatic: true);
    expect(transport.requests, ['en', 'pt-BR']);
  });
}
