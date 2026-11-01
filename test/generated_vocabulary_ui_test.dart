import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/generated_vocabulary_client.dart';
import 'package:sprachapp/data/learning/generated_vocabulary_service.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/data/user/generated_vocabulary_store.dart';
import 'package:sprachapp/domain/generated_vocabulary.dart';
import 'package:sprachapp/presentation/providers/generated_vocabulary_provider.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/widgets/premium_content_gate.dart';
import 'package:sprachapp/screens/content/generated_vocabulary_selection_screen.dart';
import 'package:sprachapp/screens/content/topic_vocabulary_composer.dart';
import 'package:sprachapp/widgets/action_buttons.dart';
import 'package:sprachapp/widgets/speak_button.dart';

/// All service operations are controlled by the test. No network or database is
/// needed to verify that preview and selection never save implicitly.
class _GrantedAccess implements PersonalLearningClient {
  @override
  Future<bool> consent() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStore implements GeneratedVocabularyStore {
  @override
  String get lang => 'en';
  int saveCalls = 0;
  @override
  Future<GeneratedVocabularySaveResult> save(
    GeneratedVocabularyResponse response, {
    required Set<int> selected,
    required DateTime now,
    required void Function() verify,
  }) async {
    saveCalls++;
    throw StateError('Persistence forbidden for stale access');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GeneratedUiService extends GeneratedVocabularyService {
  _GeneratedUiService({this.deckExists = false})
    : super(
        client: GeneratedVocabularyClient(
          access: _GrantedAccess(),
          createClient: () => throw StateError('HTTP forbidden in UI tests'),
        ),
        store: _UnusedStore(),
        verify: () {},
      );

  final bool deckExists;
  var pending = Completer<GeneratedVocabularyDraft>();
  final statusChecks = <bool>[];
  final requests = <GeneratedVocabularyRequest>[];
  final saves = <Set<int>>[];

  @override
  Future<GeneratedVocabularyDraft> generate(
    GeneratedVocabularyRequest request, {
    bool statusOnly = false,
  }) {
    requests.add(request);
    statusChecks.add(statusOnly);
    return pending.future;
  }

  @override
  Future<bool> hasDeck() async => deckExists;

  @override
  Future<GeneratedVocabularySaveResult> save(
    GeneratedVocabularyDraft draft,
    Set<int> selected,
  ) async {
    saves.add(Set.of(selected));
    return GeneratedVocabularySaveResult(
      [for (final index in selected) 'saved-$index'],
      const [],
      const [],
    );
  }
}

class _MutableAccess extends _GrantedAccess {
  int epoch = 0;
  bool allowed = true;
  int _consentRevision = 0;
  @override
  int get consentRevision => _consentRevision;
  @override
  set consentRevision(int value) => _consentRevision = value;
  @override
  int Function() get revision =>
      () => epoch;
  @override
  Future<bool> consent() async => allowed;
}

/// Only transport is replaced: account/consent verification and save guards run
/// through the production service. Unexpected store access fails the test.
class _PendingClient extends GeneratedVocabularyClient {
  _PendingClient(_MutableAccess access)
    : super(
        access: access,
        createClient: () => throw StateError('HTTP forbidden in UI tests'),
      );
  final response = Completer<GeneratedVocabularyResponse>();
  var calls = 0;
  @override
  Future<GeneratedVocabularyResponse> generate(
    GeneratedVocabularyRequest request, {
    bool statusOnly = false,
  }) {
    calls++;
    return response.future;
  }
}

GeneratedVocabularyDraft _draft({Set<String> existing = const {}}) {
  final request = GeneratedVocabularyRequest(
    requestId: '12345678-1234-4234-8234-123456789abc',
    lang: 'en',
    prompt: 'Reise',
    count: 25,
  );
  return GeneratedVocabularyDraft(
    GeneratedVocabularyResponse.fromJson({
      'contract': 1,
      'request_id': request.requestId,
      'lang': 'en',
      'items': [
        {
          'form': 'ticket',
          'lemma': 'ticket',
          'pos': 'NOUN',
          'gloss_de': 'Fahrkarte',
          'definition_de': 'Ein Nachweis für eine bezahlte Fahrt.',
          'form_detail': 'Singular',
          'sentence': 'Buy a ticket today.',
          'translation_de': 'Kaufe heute eine Fahrkarte.',
          'start': 6,
        },
        {
          'form': 'journey',
          'lemma': 'journey',
          'pos': 'NOUN',
          'gloss_de': 'Reise',
          'definition_de': 'Ein Weg von einem Ort zum anderen.',
          'form_detail': 'Singular',
          'sentence': 'Enjoy the journey today.',
          'translation_de': 'Genieße heute die Reise.',
          'start': 10,
        },
      ],
    }, request: request),
    existing,
    () {},
  );
}

Widget _host(
  GeneratedVocabularyService service, {
  Widget? screen,
  double textScale = 1,
  bool premium = true,
}) => ProviderScope(
  overrides: [
    premiumContentAccessProvider.overrideWithValue(premium),
    generatedVocabularyServiceProvider.overrideWith((ref) async => service),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home:
        screen ??
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: TopicVocabularyComposer(lang: 'en'),
          ),
        ),
  ),
);

/// Words whose chip is selected (not greyed out).
Set<String> _selectedWords(WidgetTester tester) => {
  for (final chip in tester.widgetList<GeneratedWordChip>(
    find.byType(GeneratedWordChip),
  ))
    if (chip.selected) chip.word,
};

Future<void> _begin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('generation-topic')),
    'Reise',
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Generieren'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('free topic field opens paywall without keyboard or generation', (
    tester,
  ) async {
    final service = _GeneratedUiService();
    await tester.pumpWidget(_host(service, premium: false));
    final field = find.byKey(const ValueKey('generation-topic'));
    expect(find.byType(PremiumLockBadge), findsOneWidget);
    expect(find.text('Generieren'), findsNothing);
    expect(find.text('Mit Premium erstellen'), findsNothing);
    final badge = tester.getRect(find.byType(PremiumLockBadge));
    final box = tester.getRect(
      find.ancestor(of: field, matching: find.byType(DecoratedBox)).first,
    );
    expect(badge.right, lessThan(box.right));
    expect(badge.left, greaterThan(box.center.dx));
    expect(badge.top, greaterThan(box.top));
    await tester.tap(field);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.testTextInput.isVisible, isFalse);
    expect(service.requests, isEmpty);
    expect(service.saves, isEmpty);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(nav.canPop(), isTrue);
    nav.pop();
    await tester.pump(const Duration(milliseconds: 500));
    expect(field, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'composer reveals generation only after typing and offers counts',
    (tester) async {
      final service = _GeneratedUiService();
      await tester.pumpWidget(_host(service));
      expect(find.text('Generieren'), findsNothing);
      expect(find.text(TopicVocabularyComposer.headline), findsOneWidget);
      // Self-explanatory counts, no label and no notice below them.
      expect(find.textContaining('Bis zu'), findsNothing);
      expect(find.textContaining('Anthropic'), findsNothing);
      int count() => tester
          .widget<CupertinoSlidingSegmentedControl<int>>(
            find.byType(CupertinoSlidingSegmentedControl<int>),
          )
          .groupValue!;
      expect(count(), 25);
      for (final n in [10, 50, 25]) {
        await tester.tap(find.text('$n'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(count(), n);
      }
      final field = tester.getRect(
        find.byKey(const ValueKey('generation-topic')),
      );
      await tester.enterText(find.byType(CupertinoTextField), 'Reise');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Generieren'), findsOneWidget);
      // The action appears inside the field: nothing moves.
      expect(
        tester.getRect(find.byKey(const ValueKey('generation-topic'))),
        field,
      );
      await tester.enterText(find.byType(CupertinoTextField), '   ');
      await tester.pumpAndSettle();
      expect(find.text('Generieren'), findsNothing);
      expect(service.requests, isEmpty);
      expect(service.saves, isEmpty);
    },
  );

  testWidgets('pending generation completes orange state before navigating', (
    tester,
  ) async {
    final service = _GeneratedUiService();
    expect(await service.client.access.consent(), isTrue);
    await tester.pumpWidget(_host(service));
    await _begin(tester);
    expect(service.requests.single.prompt, 'Reise');
    expect(service.requests.single.count, 25);
    expect(find.bySemanticsLabel('Wird generiert'), findsOneWidget);
    // No progress button: the bar sits in the field, the action fades out.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Generieren'), findsNothing);
    expect(find.text('Wird generiert'), findsNothing);
    expect(find.byType(GeneratedVocabularySelectionScreen), findsNothing);
    service.pending.complete(_draft());
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('Bereit'), findsOneWidget);
    expect(find.byType(GeneratedVocabularySelectionScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 249));
    expect(find.byType(GeneratedVocabularySelectionScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Wähle deine Wörter'), findsOneWidget);
    expect(service.saves, isEmpty);
    await tester.tap(find.byIcon(CupertinoIcons.chevron_left));
    await tester.pump(const Duration(milliseconds: 400));
    expect(service.saves, isEmpty);
  });

  testWidgets('failed generation displays error and never opens selection', (
    tester,
  ) async {
    final service = _GeneratedUiService();
    await tester.pumpWidget(_host(service));
    await _begin(tester);
    service.pending.completeError(
      const GeneratedVocabularyFailure(
        'TOPIC_UNSUITABLE',
        'Kein passendes Thema.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kein passendes Thema.'), findsOneWidget);
    expect(find.byType(GeneratedVocabularySelectionScreen), findsNothing);
    expect(find.bySemanticsLabel('Wird generiert'), findsNothing);
    expect(service.saves, isEmpty);
  });

  testWidgets('REQUEST_MISSING status retries generation with identical UUID', (
    tester,
  ) async {
    final service = _GeneratedUiService();
    await tester.pumpWidget(_host(service));
    await _begin(tester);
    final original = service.requests.single;
    service.pending.completeError(
      const GeneratedVocabularyFailure(
        'TIMEOUT',
        'Status prüfen.',
        uncertain: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Ergebnis prüfen'), findsOneWidget);
    service.pending = Completer<GeneratedVocabularyDraft>();
    await tester.tap(find.text('Ergebnis prüfen'));
    await tester.pump();
    await tester.pump();
    expect(service.requests.last.requestId, original.requestId);
    service.pending.completeError(
      const GeneratedVocabularyFailure(
        'REQUEST_MISSING',
        'Keine Anfrage gespeichert.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Generieren'), findsOneWidget);
    expect(
      find.textContaining('Es wurde noch keine Generierung gestartet.'),
      findsOneWidget,
    );
    service.pending = Completer<GeneratedVocabularyDraft>();
    await tester.tap(find.text('Generieren'));
    await tester.pump();
    await tester.pump();
    expect(service.requests, hasLength(3));
    expect(service.statusChecks, [false, true, false]);
    expect(service.requests.map((r) => r.requestId).toSet(), {
      original.requestId,
    });
    expect(service.requests.last.toJson(), original.toJson());
    expect(service.saves, isEmpty);
  });

  for (final change in ['account', 'consent']) {
    testWidgets('$change change while response pending prevents selection', (
      tester,
    ) async {
      final access = _MutableAccess();
      final client = _PendingClient(access);
      final service = GeneratedVocabularyService(
        client: client,
        store: _UnusedStore(),
        verify: () {},
      );
      await tester.pumpWidget(_host(service));
      await _begin(tester);
      expect(client.calls, 1);
      if (change == 'account') {
        access.epoch++;
      } else {
        access.allowed = false;
        access.consentRevision++;
      }
      client.response.complete(_draft().response);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GeneratedVocabularySelectionScreen), findsNothing);
      expect(
        find.text('Konto oder KI-Freigabe geändert. Bitte erneut öffnen.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Bereit'), findsNothing);
      expect((service.store as _UnusedStore).saveCalls, 0);
    });

    testWidgets(
      '$change change invalidates an already visible preview before save',
      (tester) async {
        final access = _MutableAccess();
        final epoch = access.epoch;
        final consentEpoch = access.consentRevision;
        final fixture = _draft();
        final guardedDraft = GeneratedVocabularyDraft(fixture.response, {}, () {
          if (access.epoch != epoch || access.consentRevision != consentEpoch) {
            throw const GeneratedVocabularyFailure(
              'ACCESS_CHANGED',
              'Freigabe oder Konto geändert.',
            );
          }
        });
        final service = GeneratedVocabularyService(
          client: _PendingClient(access),
          store: _UnusedStore(),
          verify: () {},
        );
        await tester.pumpWidget(
          _host(
            service,
            screen: GeneratedVocabularySelectionScreen(
              draft: guardedDraft,
              service: service,
              hasDeck: false,
            ),
          ),
        );
        if (change == 'account') {
          access.epoch++;
        } else {
          access.allowed = false;
          access.consentRevision++;
        }
        await tester.tap(find.text('Stapel erstellen'));
        await tester.pump();
        expect(find.text('Freigabe oder Konto geändert.'), findsOneWidget);
        expect(find.text('Stapel erstellen'), findsOneWidget);
        expect(find.byType(GeneratedVocabularySelectionScreen), findsOneWidget);
        // _UnusedStore has no save implementation: reaching persistence would
        // throw and show the generic error instead of the precise access error.
        expect(
          find.text('Speichern nicht bestätigt. Bitte erneut versuchen.'),
          findsNothing,
        );
      },
    );
  }

  for (final hasDeck in [false, true]) {
    testWidgets(
      'selection saves only explicit choices, existing deck=$hasDeck',
      (tester) async {
        final service = _GeneratedUiService(deckExists: hasDeck);
        await tester.pumpWidget(
          _host(
            service,
            screen: GeneratedVocabularySelectionScreen(
              draft: _draft(),
              service: service,
              hasDeck: hasDeck,
            ),
          ),
        );
        final label = hasDeck ? 'Zum Stapel hinzufügen' : 'Stapel erstellen';
        expect(find.text(label), findsOneWidget);
        // Chips without a counting subline, sentence or speaker.
        expect(find.textContaining('ausgewählt'), findsNothing);
        expect(find.byType(SpeakButton), findsNothing);
        expect(_selectedWords(tester), {'ticket', 'journey'});
        expect(service.saves, isEmpty);
        await tester.tap(find.text('ticket'));
        await tester.pump();
        expect(_selectedWords(tester), {'journey'});
        expect(service.saves, isEmpty);
        await tester.tap(find.text(label));
        await tester.pump();
        expect(service.saves, [
          {1},
        ]);
      },
    );
  }

  testWidgets(
    'existing words are unselected and empty selection disables save',
    (tester) async {
      final service = _GeneratedUiService();
      await tester.pumpWidget(
        _host(
          service,
          screen: GeneratedVocabularySelectionScreen(
            draft: _draft(existing: {'ticket'}),
            service: service,
            hasDeck: true,
          ),
        ),
      );
      expect(find.text('Bereits im Stapel'), findsOneWidget);
      expect(_selectedWords(tester), {'journey'});
      await tester.tap(find.text('ticket'));
      await tester.pump();
      expect(_selectedWords(tester), {'journey'});
      await tester.ensureVisible(find.text('journey'));
      await tester.tap(find.text('journey'));
      await tester.pump();
      expect(_selectedWords(tester), isEmpty);
      expect(
        tester
            .widget<PrimaryActionButton>(find.byType(PrimaryActionButton))
            .onPressed,
        isNull,
      );
      expect(service.saves, isEmpty);
    },
  );

  for (final width in [320.0, 820.0]) {
    testWidgets('real composer and selection fit width $width at 2x text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = _GeneratedUiService();
      await tester.pumpWidget(_host(service, textScale: 2));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(CupertinoTextField), 'Reise');
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _host(
          service,
          textScale: 2,
          screen: GeneratedVocabularySelectionScreen(
            draft: _draft(),
            service: service,
            hasDeck: false,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Stapel erstellen'), findsOneWidget);
      expect(service.saves, isEmpty);
    });
  }
}
