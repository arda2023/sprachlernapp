import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/models/speech_playback.dart';
import 'package:sprachapp/models/word_list_models.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/screens/words/widgets/empty_word_panda.dart';
import 'package:sprachapp/screens/words/word_list_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  final now = DateTime(2026, 10, 2);
  final panda = find.byType(EmptyWordPanda);
  final search = find.byType(CupertinoSearchTextField);

  Widget wordList(
    FutureOr<List<VocabWord>> Function() words, {
    String? target,
  }) => ProviderScope(
    overrides: [wordListProvider.overrideWith((_) => words())],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: WordListScreen(
          targetCardId: target,
          clock: () => now,
          playbackFactory: SpeechPlayback.new,
        ),
      ),
    ),
  );

  testWidgets('Empty vocabulary keeps the header and shows a readable hint', (
    tester,
  ) async {
    await tester.pumpWidget(wordList(() => []));

    expect(panda, findsOneWidget);
    expect(find.text('Wortliste'), findsOneWidget);
    expect(search, findsOneWidget);
    expect(find.textContaining('Übe einen Stapel'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Neu, 0'));
    await tester.pumpAndSettle();
    expect(panda, findsNothing);
    expect(find.text('Keine Wörter unter „Neu“.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Alle, 0'));
    await tester.pumpAndSettle();
    expect(panda, findsOneWidget);

    await tester.enterText(search, 'nichts');
    await tester.pumpAndSettle();
    expect(panda, findsNothing);
    expect(find.text('Keine Wörter für „nichts“'), findsOneWidget);

    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    expect(panda, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filtering a populated list never shows the empty panda', (
    tester,
  ) async {
    await tester.pumpWidget(wordList(() => [sampleVocabulary(now).first]));
    expect(find.text('platform'), findsOneWidget);
    expect(panda, findsNothing);

    await tester.tap(find.bySemanticsLabel('Neu, 0'));
    await tester.pumpAndSettle();
    expect(find.text('Keine Wörter unter „Neu“.'), findsOneWidget);
    expect(panda, findsNothing);
  });

  testWidgets('A missing target shows its own message with an empty list', (
    tester,
  ) async {
    await tester.pumpWidget(wordList(() => [], target: 'missing'));
    expect(find.text('Dieses Wort ist nicht in deiner Wortliste.'), findsOne);
    expect(panda, findsNothing);
  });

  testWidgets('An empty list hides its panda during a failing refresh', (
    tester,
  ) async {
    final refresh = Completer<List<VocabWord>>();
    var refreshing = false;
    await tester.pumpWidget(wordList(() => refreshing ? refresh.future : []));
    expect(panda, findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(panda));
    refreshing = true;
    container.invalidate(wordListProvider);
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(panda, findsNothing);

    refresh.completeError(StateError('Unable to load the vocabulary'));
    await tester.pumpAndSettle();
    expect(find.text('Inhalte nicht verfügbar'), findsOneWidget);
    expect(panda, findsNothing);
  });
}
