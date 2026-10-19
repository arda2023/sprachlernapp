// Regressions for content loading: owner lifecycle, single pack opening per
// language switch, change-free session start and identity-bound Home data.
// Synthetic packs and temporary user data only.
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/screens/home/home_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/language_selection.dart';
import 'fixtures/portuguese_installation.dart';

class CountingInstaller extends ContentPackInstaller {
  CountingInstaller(ContentPackInstaller base)
    : super(
        loadAsset: base.loadAsset,
        supportDirectory: base.supportDirectory,
        lang: base.lang,
      );
  int opens = 0;
  @override
  Future<DriftContentRepository> open({String? expectedFingerprint, ReadCancellation? cancellation, bool Function()? isCurrent}) {
    opens++;
    return super.open(expectedFingerprint: expectedFingerprint, cancellation: cancellation, isCurrent: isCurrent);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('RepositoryOwner', () {
    test(
      'a reader released while paused is not reopened after resume',
      () async {
        var opens = 0, closes = 0;
        final owner = RepositoryOwner<int>(
          () async => ++opens,
          (_) async => closes++,
        );
        final provider = FutureProvider<int>(
          owner.acquire,
          retry: (_, _) => null,
        );
        final old = ProviderContainer();
        expect(await old.read(provider.future), 1);
        owner.pause();
        old.dispose();
        // An outdated scope acquires again while the switch waits for close.
        final stale = ProviderContainer();
        final pending = stale.read(provider.future);
        await owner.closed();
        expect(closes, 1);
        stale.dispose();
        owner.resume();
        await expectLater(pending, throwsStateError);
        await Future<void>.delayed(Duration.zero);
        expect(opens, 1, reason: 'no pack opened only to be closed again');
        final next = ProviderContainer();
        expect(await next.read(provider.future), 2);
        next.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(closes, 2);
      },
    );

    test(
      'an explicit lease shares the connection and closes after its last user',
      () async {
        var opens = 0, closes = 0;
        final opening = Completer<int>();
        final owner = RepositoryOwner<int>(() {
          opens++;
          return opening.future;
        }, (_) async => closes++);
        final provider = FutureProvider<int>(
          owner.acquire,
          retry: (_, _) => null,
        );
        final lease = owner.lease();
        final c = ProviderContainer();
        final shared = c.read(provider.future);
        await Future<void>.delayed(Duration.zero);
        opening.complete(7);
        expect(await lease.future, 7);
        expect(await shared, 7);
        lease.release();
        lease.release(); // idempotent
        await Future<void>.delayed(Duration.zero);
        expect((opens, closes), (1, 0), reason: 'provider still uses it');
        c.dispose();
        await owner.closed();
        expect(closes, 1);
      },
    );
  });

  group('language switch with installed packs', () {
    late Directory tmp;
    late LanguageHarness h;
    late CountingInstaller en, pt;
    late ProviderContainer c;
    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('content-loading-');
      h = LanguageHarness(Directory('${tmp.path}/app')..createSync());
      en = CountingInstaller(h.english);
      pt = CountingInstaller(
        ContentPackInstaller(
          loadAsset: (_) async => null,
          supportDirectory: tmp,
          lang: 'pt-BR',
        ),
      );
      h.english = en;
      h.portuguese = pt;
      c = h.scope();
      final journal = ContentInstallJournal(tmp, 'pt-BR');
      final service = ContentUpdateService(
        journal,
        PortugueseTransport(tmp),
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        closeReaders: () async {},
        openReaders: () async {},
      );
      await service.check();
      await service.download();
      await service.activate();
      await c.read(contentRepositoryProvider.future);
    });
    tearDown(() async {
      c.dispose();
      await h.close();
      tmp.deleteSync(recursive: true);
    });

    Future<void> settings() async {
      // The settings screen keeps both installation rows subscribed.
      c.listen(languageInstallationProvider('en'), (_, _) {});
      c.listen(languageInstallationProvider('pt-BR'), (_, _) {});
      await c.read(languageInstallationProvider('en').future);
      await c.read(languageInstallationProvider('pt-BR').future);
    }

    test(
      'each switch opens only its target pack once; statuses never open readers',
      () async {
        c.listen(decksProvider, (_, _) {});
        await c.read(decksProvider.future);
        await settings();
        expect(
          (en.opens, pt.opens),
          (1, 0),
          reason: 'status opens neither language',
        );
        expect(
          await c
              .read(languageSelectionProvider.notifier)
              .selectLanguage('pt-BR'),
          true,
        );
        expect(
          await c.read(languageInstallationProvider('pt-BR').future),
          startsWith('Installiert'),
        );
        expect(
          (en.opens, pt.opens),
          (1, 1),
          reason: 'no candidate reopen, no old-pack reopen',
        );
        final ptDecks = {
          for (final d in await (await c.read(
            contentRepositoryProvider.future,
          )).decks())
            d.id,
        };
        expect(
          (await c.read(decksProvider.future)).map((d) => d.id).toSet(),
          ptDecks,
        );
        expect(ptDecks.contains('deck-allg'), false);
        expect(
          await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
          true,
        );
        expect(
          await c.read(languageInstallationProvider('en').future),
          startsWith('Installiert'),
        );
        expect((en.opens, pt.opens), (2, 1));
        expect(
          (await c.read(decksProvider.future)).map((d) => d.id),
          contains('deck-allg'),
        );
      },
    );

    test(
      'a rapid second switch is refused; no late result of the other language',
      () async {
        final first = c
            .read(languageSelectionProvider.notifier)
            .selectLanguage('pt-BR');
        expect(
          await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
          false,
        );
        expect(await first, true);
        expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
        expect(
          (await c.read(contentRepositoryProvider.future)).info.lang,
          'pt-BR',
        );
        expect(
          await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
          true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          (await c.read(contentRepositoryProvider.future)).info.lang,
          'en',
        );
        expect(
          ((await c.read(
            userRepositoryProvider.future,
          )) as DriftUserRepository).lang,
          'en',
        );
        expect(pt.opens, 1);
      },
    );

    test('a failed target leaves the previous language usable', () async {
      final file = (await pt.install()).file;
      final bytes = file.readAsBytesSync();
      file.writeAsBytesSync([0, ...bytes.skip(1)]);
      expect(
        await c
            .read(languageSelectionProvider.notifier)
            .selectLanguage('pt-BR'),
        false,
      );
      expect(await c.read(selectedContentLanguageProvider.future), 'en');
      expect((await c.read(contentRepositoryProvider.future)).info.lang, 'en');
      file.writeAsBytesSync(bytes);
      expect(
        await c
            .read(languageSelectionProvider.notifier)
            .selectLanguage('pt-BR'),
        true,
      );
      expect(
        (await c.read(contentRepositoryProvider.future)).info.lang,
        'pt-BR',
      );
    });

    test('session start emits no change event for an existing card', () async {
      var changes = 0;
      c.listen(userChangesProvider, (_, _) => changes++);
      await c
          .read(userChangesProvider.future)
          .timeout(const Duration(milliseconds: 50), onTimeout: () => 0);
      Future<String> start() async {
        const args = (
          deckId: 'deck-allg',
          kind: DeckSessionKind.learn,
          size: 1,
        );
        final shown = Completer<String>();
        final sub = c.listen(deckSessionControllerProvider(args), (_, s) {
          if (shown.isCompleted) return;
          if (s.pass != null) shown.complete(s.pass!.item.card.id);
          if (s.error != null) shown.completeError(s.error!);
        }, fireImmediately: true);
        final id = await shown.future;
        sub.close();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return id;
      }

      final before = changes;
      final id = await start();
      final created = (await (await c.read(userRepositoryProvider.future))
          .cardStates([id]))[id]!;
      expect(created.box, 0);
      expect(
        changes - before,
        1,
        reason: 'a new learning row is a real change',
      );
      final again = await start();
      expect(again, id);
      expect(
        changes - before,
        1,
        reason: 'unchanged rows must not re-project Home',
      );
      final kept = (await (await c.read(userRepositoryProvider.future))
          .cardStates([id]))[id]!;
      expect(
        (kept.box, kept.createdAt, kept.dueAt),
        (created.box, created.createdAt, created.dueAt),
      );
    });
  });

  test(
    'ensureCards inserts only missing rows and keeps existing state',
    () async {
      final db = UserDatabase(NativeDatabase.memory());
      final user = DriftUserRepository(db, lang: 'en');
      var events = 0;
      final sub = user.changes().listen((_) => events++);
      final t0 = DateTime.utc(2026, 10, 1);
      await user.ensureCards(['a'], now: t0, origin: CardOrigin.deck);
      await Future<void>.delayed(Duration.zero);
      expect(events, 1);
      await user.ensureCards(
        ['a'],
        now: t0.add(const Duration(days: 1)),
        origin: CardOrigin.story,
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, 1);
      await user.ensureCards(
        ['a', 'b'],
        now: t0.add(const Duration(days: 2)),
        origin: CardOrigin.deck,
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, 2);
      final states = await user.cardStates(['a', 'b']);
      expect(states['a']!.createdAt!.toUtc(), t0);
      expect(states['a']!.origin, CardOrigin.deck);
      expect(states['b']!.createdAt!.toUtc(), t0.add(const Duration(days: 2)));
      await sub.cancel();
      await user.close();
    },
  );

  testWidgets(
    'Home keeps shown data on a same-language refresh, never across languages',
    (t) async {
      var lang = 'en', revision = 0;
      var gate = Completer<void>()..complete();
      Deck deck(String name) => Deck(
        id: name,
        name: name,
        description: '',
        icon: CupertinoIcons.square_stack,
        difficulty: DeckDifficulty.beginner,
        totalWords: 1,
        seenWords: 0,
        masteredWords: 0,
        isActive: true,
      );
      final revisionProvider = NotifierProvider<_Revision, int>(_Revision.new);
      final container = ProviderContainer(
        overrides: [
          selectedContentLanguageProvider.overrideWith((ref) async => lang),
          activeContentKeyProvider.overrideWith(
            (ref) async => (
              lang: await ref.watch(selectedContentLanguageProvider.future),
              generation: 0,
              fingerprint: 'synthetic',
            ),
          ),
          decksProvider.overrideWith((ref) async {
            final key = await ref.watch(activeContentKeyProvider.future);
            ref.watch(revisionProvider);
            await gate.future;
            return [deck('${key.lang} deck $revision')];
          }),
          vocabBreakdownProvider.overrideWith(
            (ref) async => const VocabBreakdown(
              due: 0,
              building: 0,
              mastered: 0,
              unseen: 0,
            ),
          ),
          lexicalBreakdownProvider.overrideWith(
            (ref) => Completer<LexicalBreakdown>().future,
          ),
          storySummariesProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: HomeScreen(
                goal: const DailyGoal(done: 0, target: 5),
                week: const WeekProgress([
                  DayMark.today,
                  DayMark.upcoming,
                  DayMark.upcoming,
                  DayMark.upcoming,
                  DayMark.upcoming,
                  DayMark.upcoming,
                  DayMark.upcoming,
                ]),
                onOpenStory: (_) {},
                onBrowseStories: () {},
                onOpenDeck: (_) {},
                onBrowseDecks: () {},
                onEditGoal: () {},
                onProfile: () {},
                onSettings: () {},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('en deck 0'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);

      // Review: same language/version recomputes; the shown list stays visible.
      gate = Completer<void>();
      revision = 1;
      container.read(revisionProvider.notifier).bump();
      await t.pump();
      expect(find.text('en deck 0'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('en deck 1'), findsOneWidget);

      // Language switch: English data is never shown as Portuguese.
      gate = Completer<void>();
      lang = 'pt-BR';
      container.invalidate(selectedContentLanguageProvider);
      await t.pump();
      await t.pump();
      expect(find.textContaining('en deck'), findsNothing);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('pt-BR deck 1'), findsOneWidget);

      // Back to English: the Portuguese value is not taken for English.
      gate = Completer<void>();
      lang = 'en';
      container.invalidate(selectedContentLanguageProvider);
      await t.pump();
      await t.pump();
      expect(find.textContaining('pt-BR deck'), findsNothing);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('en deck 1'), findsOneWidget);
    },
  );
}

class _Revision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}
