// Read-only diagnosis using the production selector. Optional user.db is a
// local snapshot; this tool never opens or changes the running app's state.
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/new_card_selection.dart';
import 'package:sprachapp/domain/srs_state.dart';

void main(List<String> args) {
  final pack = sqlite3.open(
    args.isEmpty ? 'assets/content/en/content.sqlite' : args[0],
    mode: OpenMode.readOnly,
  );
  final now = args.length > 2 ? DateTime.parse(args[2]) : DateTime.now();
  final cards = <String, ContentCard>{};
  final sensesByForm = <String, Set<String>>{};
  final formsByLemma = <String, Set<String>>{};
  for (final r in pack.select(
    'SELECT c.*,l.lemma,s.sense_key FROM cards c '
    'JOIN lemmas l ON l.id=c.lemma_id JOIN senses s ON s.id=c.sense_id WHERE c.removed_in IS NULL',
  )) {
    final c = ContentCard(
      id: r['id'],
      lang: r['lang'],
      form: r['form'],
      formNorm: r['form_norm'],
      lemmaId: r['lemma_id'],
      lemma: r['lemma'],
      pos: r['pos'],
      senseKey: r['sense_key'],
    );
    cards[c.id] = c;
    (sensesByForm[c.formNorm] ??= {}).add(r['sense_id']);
    (formsByLemma[selectionLemma(c)] ??= {}).add(c.formNorm);
  }
  final states = <String, UserCardState>{};
  if (args.length > 1) {
    final user = sqlite3.open(args[1], mode: OpenMode.readOnly);
    for (final r in user.select('SELECT * FROM user_cards')) {
      states[r['card_id']] = UserCardState(
        cardId: r['card_id'],
        box: r['box'],
        dueAt: r['due_at'] == null
            ? null
            : r['due_at'] is String
            ? DateTime.parse(r['due_at']).toLocal()
            : DateTime.fromMillisecondsSinceEpoch((r['due_at'] as int) * 1000),
        disabled: r['disabled'] == 1,
        retired: r['retired'] == 1,
      );
    }
    stdout.writeln(
      'User snapshot: ${File(args[1]).absolute.path}; snapshot file time: ${File(args[1]).lastModifiedSync()}; reference time: $now',
    );
    stdout.writeln(
      'Persisted first-pass reviews: ${user.select('SELECT count(*) AS n FROM review_log').first['n']}',
    );
    stdout.writeln(
      'First passes with error/hint/reveal (not a count of completed repeats): ${user.select('SELECT count(*) AS n FROM review_log WHERE error_count>0 OR hint_used=1 OR revealed=1').first['n']}',
    );
    user.close();
  }
  final multipleSenses = sensesByForm.values
      .where((s) => s.length > 1)
      .toList();
  final multipleForms = formsByLemma.values.where((s) => s.length > 1).toList();
  stdout.writeln(
    'Pack: ${cards.length} cards; ${sensesByForm.length} surfaces; ${formsByLemma.length} normalized lemmas',
  );
  stdout.writeln(
    'Different senses of the same surface: ${multipleSenses.length} surfaces; ${multipleSenses.fold(0, (n, s) => n + s.length - 1)} additional senses',
  );
  stdout.writeln(
    'Multiple surfaces of the same lemma: ${multipleForms.length} lemmas; ${multipleForms.fold(0, (n, s) => n + s.length - 1)} additional surfaces (overlaps previous category; do not add)',
  );
  stdout.writeln(
    'Content/function cards: ${cards.values.where(isContentWord).length}/${cards.values.where((c) => !isContentWord(c)).length}',
  );
  final diverse = selectNewCards(
    candidates: cards.values.toList(),
    knownLemmas: {},
    limit: cards.length,
  );
  stdout.writeln(
    'Maximum new cards without duplicate refill in this pack: ${diverse.length} '
    '(${diverse.where((id) => isContentWord(cards[id]!)).length} content, '
    '${diverse.where((id) => !isContentWord(cards[id]!)).length} function); requested ${cards.length}.',
  );
  stdout.writeln(
    'Due active cards in snapshot and pack: ${states.values.where((s) => cards.containsKey(s.cardId) && s.isActive && s.isDue(now)).length}',
  );
  stdout.writeln(
    'Actual in-session repetitions are not persisted and cannot be reconstructed as a count from review_log. Initial queues contain 0 repeat passes.',
  );
  for (final deck in pack.select(
    'SELECT id,title_de FROM decks WHERE removed_in IS NULL ORDER BY sort',
  )) {
    final ids = pack
        .select(
          'SELECT dc.card_id FROM deck_cards dc JOIN cards c ON c.id=dc.card_id '
          'WHERE dc.deck_id=? AND dc.removed_in IS NULL AND c.removed_in IS NULL ORDER BY dc.position,dc.card_id',
          [deck['id']],
        )
        .map((r) => r['card_id'] as String)
        .toList();
    for (final scenario in ['unseen profile, size 20', 'snapshot, size 5']) {
      if (scenario.startsWith('snapshot') && args.length < 2) continue;
      final profile = scenario.startsWith('snapshot')
          ? states
          : <String, UserCardState>{};
      final size = scenario.startsWith('snapshot') ? 5 : 20;
      final eligible = ids
          .where((id) => profile[id]?.isActive ?? true)
          .toList();
      final due =
          eligible.where((id) => profile[id]?.isDue(now) ?? false).toList()
            ..sort((a, b) {
              final x = profile[a]!.dueAt, y = profile[b]!.dueAt;
              final v = x == null
                  ? (y == null ? 0 : -1)
                  : y == null
                  ? 1
                  : x.compareTo(y);
              return v != 0 ? v : ids.indexOf(a).compareTo(ids.indexOf(b));
            });
      final before = [
        ...due,
        ...eligible.where((id) => (profile[id]?.box ?? 0) == 0),
      ].take(size).toList();
      final after = buildDeckQueue(
        deckCardIds: ids,
        cards: cards,
        states: profile,
        kind: DeckSessionKind.learn,
        now: now,
        size: size,
      );
      stdout.writeln(
        '\n${deck['title_de']} | $scenario | before ${before.length}, after ${after.length}',
      );
      final known = {
        for (final id in profile.keys)
          if (cards[id] != null) selectionLemma(cards[id]!),
      };
      for (final part in [
        ('BEFORE', before),
        ('AFTER', after.map((e) => e.cardId).toList()),
      ]) {
        stdout.writeln(part.$1);
        for (final id in part.$2) {
          final c = cards[id]!;
          final reason = (profile[id]?.isDue(now) ?? false)
              ? 'due review, unchanged'
              : part.$1 == 'BEFORE'
              ? 'new, deck position ${ids.indexOf(id) + 1}'
              : 'new ${known.contains(selectionLemma(c)) ? 'known' : 'unseen'} lemma, unique surface/lemma, group rank ${ids.indexOf(id) + 1}';
          stdout.writeln(
            '${c.form} | ${c.lemma} | ${c.senseKey} | ${isContentWord(c) ? 'content' : 'function'} (${c.pos}) | $reason',
          );
        }
      }
      if (after.isNotEmpty) {
        stdout.writeln(
          'Controlled error example: 1 failed first pass -> ${withRepeat(after, 0).where((e) => e.repeat).length} repeat; repeated repeat adds 0 (not live-session telemetry).',
        );
      }
    }
  }
  pack.close();
}
