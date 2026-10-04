import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/domain/preferences.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/repositories.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';

final testNow = DateTime(2026, 10, 4, 12);

/// Small explicit content independent of production assets and sample_content.
class TestContent implements ContentRepository {
  TestContent({this.library = false});
  final bool library;
  static const titles = [
    'Reisen & Unterwegs',
    'Alltägliche Konversation',
    'Medizin',
    'Kultur',
    'Arbeit',
    'Natur',
  ];
  static const forms = ['walks', 'about', 'a', 'went', 'goes'];
  @override
  ContentInfo get info => const ContentInfo(
    lang: 'en',
    version: 'fixture',
    schemaVersion: 1,
    notes: 'INTERNES TEST-PACK',
  );
  @override
  Future<List<DeckSummary>> decks() async => [
    for (var i = 0; i < (library ? 6 : 1); i++)
      DeckSummary(
        id: 'deck-$i',
        slug: 'deck-$i',
        titleDe: library ? titles[i] : 'Allgemeine Sprache',
        cardCount: 5,
        cefrBand: i == 2 ? 'fortgeschritten' : 'anfaenger',
        descriptionDe: 'Fünf Formen im Satz.',
      ),
  ];
  @override
  Future<List<String>> deckCardIds(String deckId) async => [
    for (var i = 0; i < 5; i++) '$deckId/$i',
  ];
  @override
  Future<Set<String>> allCardIds() async => {
    for (final d in await decks()) ...await deckCardIds(d.id),
  };
  @override
  Future<List<ContentCard>> selectionCards(Iterable<String> ids) async => [
    for (final id in ids) item(id).card,
  ];
  @override
  Future<List<PracticeItem>> practiceItems(List<String> cardIds) async => [
    for (final id in cardIds) item(id),
  ];
  PracticeItem item(String id) {
    final index = int.parse(id.split('/').last);
    final form = forms[index];
    final sentence = [
      'Mia walks home.',
      'It takes about an hour.',
      'Leo has a dog.',
      'Mia went home.',
      'Ben goes to school.',
    ][index];
    final translations = [
      'Mia geht nach Hause.',
      'Es dauert ungefähr eine Stunde.',
      'Leo hat einen Hund.',
      'Mia ging nach Hause.',
      'Ben geht zur Schule.',
    ];
    final label = [
      'Verb, 3. Person Singular',
      'Adverb',
      'Artikel',
      'Verb, Vergangenheit',
      'Verb, 3. Person Singular',
    ][index];
    return PracticeItem(
      card: ContentCard(
        id: id,
        lang: 'en',
        form: form,
        formNorm: form,
        lemmaId: 'lemma-$index',
        lemma: index == 0
            ? 'walk'
            : index >= 3
            ? 'go'
            : form,
        pos: index == 1
            ? 'ADV'
            : index == 2
            ? 'DET'
            : 'VERB',
        formLabelDe: label,
        translationDe: ['geht', 'ungefähr', 'ein', 'ging', 'geht'][index],
      ),
      sentences: [
        for (var p = 1; p <= 3; p++)
          CardSentence(
            cardId: id,
            sentenceId: '$id/s$p',
            position: p,
            text: p == 1 ? sentence : 'Today: $sentence',
            translationDe: translations[index],
            gapStart: sentence.indexOf(form) + (p == 1 ? 0 : 7),
            gapEnd: sentence.indexOf(form) + form.length + (p == 1 ? 0 : 7),
            validAlternatives: index == 0
                ? ['strolls']
                : index == 1
                ? ['around', 'approximately']
                : index == 2
                ? ['one']
                : [],
          ),
      ],
      otherFormsOfLemma: index == 0
          ? {'walk', 'walked', 'walking'}
          : index >= 3
          ? {'go', 'goes', 'went', 'gone'}
          : {},
    );
  }

  @override
  Future<CardSentence?> historicalSentence(
    String cardId,
    String sentenceId,
  ) async {
    for (final item in await practiceItems([cardId])) {
      for (final sentence in item.sentences) {
        if (sentence.sentenceId == sentenceId) return sentence;
      }
    }
    return null;
  }

  @override
  Future<void> close() async {}
}

class TestUser implements UserRepository {
  PracticePreferences prefs = const PracticePreferences();
  final localEntries = <LocalSubmission>[];
  @override
  Future<PracticePreferences> preferences() async => prefs;
  @override
  Future<void> savePreferences(PracticePreferences value) async {
    prefs = value;
    events.add(null);
  }

  @override
  Future<void> saveSubmission(LocalSubmission s) async {
    localEntries.add(s);
  }

  @override
  Future<List<LocalSubmission>> submissions() async => List.of(localEntries);
  @override
  Future<void> setCardFlags(
    String id, {
    bool? favorite,
    bool? disabled,
    bool? inPlaylist,
    String? note,
  }) async {
    final s = states[id]!;
    states[id] = UserCardState(
      cardId: id,
      box: s.box,
      dueAt: s.dueAt,
      favorite: favorite ?? s.favorite,
      note: note ?? s.note,
      inPlaylist: inPlaylist ?? s.inPlaylist,
      disabled: disabled ?? s.disabled,
      retired: s.retired,
      localOnly: s.localOnly,
      origin: s.origin,
      createdAt: s.createdAt,
    );
    events.add(null);
  }

  final states = <String, UserCardState>{};
  final records = <String, ReviewRecord>{};
  final active = <String, bool>{};
  final events = StreamController<void>.broadcast(sync: true);
  int failures = 0;
  bool failAfterWrite = false;
  Completer<void>? writeGate;
  final attempts = <String>[];
  TestUser({bool library = false}) {
    if (library) {
      for (var d = 0; d < 6; d++) {
        active['deck-$d'] = d < 2;
        for (var i = 0; i < 3; i++) {
          final id = 'deck-$d/$i';
          final box = i == 0 ? 5 : 2;
          final due = i == 2
              ? testNow.subtract(const Duration(days: 1))
              : testNow.add(const Duration(days: 14));
          states[id] = UserCardState(cardId: id, box: box, dueAt: due);
          records['seed-$id'] = ReviewRecord(
            id: 'seed-$id',
            cardId: id,
            createdAt: testNow.subtract(Duration(days: i + 1)),
            mode: ReviewMode.deck,
            sentenceId: '$id/s1',
            firstAttemptCorrect: true,
            errorCount: 0,
            revealed: false,
            hintUsed: false,
            boxBefore: 0,
            boxAfter: box,
            dueAtAfter: due,
            responseMs: 100,
            appVersion: 'test',
            deviceId: 'test',
          );
        }
      }
    }
  }
  @override
  Future<Map<String, UserCardState>> cardStates(Iterable<String> ids) async => {
    for (final id in ids)
      if (states.containsKey(id)) id: states[id]!,
  };
  @override
  Future<Map<String, UserCardState>> allCardStates() async => Map.of(states);
  @override
  Future<void> ensureCards(
    Iterable<String> ids, {
    required DateTime now,
    required CardOrigin origin,
  }) async {
    for (final id in ids) {
      states.putIfAbsent(
        id,
        () => UserCardState(cardId: id, box: 0, dueAt: null, origin: origin),
      );
    }
    events.add(null);
  }

  @override
  Future<bool> recordReview(ReviewRecord record) async {
    attempts.add(record.id);
    await writeGate?.future;
    if (failures > 0) {
      failures--;
      throw StateError('disk full');
    }
    if (records.containsKey(record.id)) return false;
    records[record.id] = record;
    states[record.cardId] = UserCardState(
      cardId: record.cardId,
      box: record.boxAfter,
      dueAt: record.dueAtAfter,
    );
    events.add(null);
    if (failAfterWrite) {
      failAfterWrite = false;
      throw StateError('lost write response');
    }
    return true;
  }

  @override
  Future<Map<String, int>> reviewCounts(Iterable<String> ids) async => {
    for (final id in ids)
      id: records.values.where((r) => r.cardId == id).length,
  };
  @override
  Future<List<ReviewRecord>> reviewsFor(String id) async =>
      records.values.where((r) => r.cardId == id).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  @override
  Future<Set<String>> activeDeckIds(Iterable<String> ids) async =>
      ids.where((id) => active[id] ?? true).toSet();
  @override
  Future<void> setDeckActive(
    String id,
    bool value, {
    required DateTime now,
  }) async {
    active[id] = value;
    events.add(null);
  }

  @override
  Future<String> deviceId() async => 'fixture-device';
  @override
  Stream<void> changes() => events.stream;
  @override
  Future<void> close() => events.close();
}

Widget testScope(
  Widget child, {
  ContentRepository? content,
  UserRepository? user,
  bool library = false,
}) => ProviderScope(
  overrides: [
    contentRepositoryProvider.overrideWith(
      (ref) => content ?? TestContent(library: library),
    ),
    userRepositoryProvider.overrideWith((ref) {
      if (user != null) return user;
      final owned = TestUser(library: library);
      ref.onDispose(owned.close);
      return owned;
    }),
    clockProvider.overrideWithValue(() => testNow),
    libraryStoriesProvider.overrideWith(
      (ref) => const AsyncData(sampleStories),
    ),
    storyDocumentProvider.overrideWith(
      (ref, id) async => StoryDocument(
        StorySummary(id: id, title: id, titleDe: id, level: 'A2', minutes: 1),
        'fixture',
        [
          for (final (i, text) in sampleStoryText(id).paragraphs.indexed)
            StorySentence(
              id: '$id/$i',
              text: text,
              translation: '',
              paragraph: i,
              tokens: [],
            ),
        ],
      ),
    ),
    appInfoProvider.overrideWith((ref) async => 'test+1'),
  ],
  child: child,
);
