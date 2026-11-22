import 'tutor_skills.dart';

enum TutorKind { translate, situation }

enum TutorOrigin { diagnostic, practice, regenerated, review }

enum TutorItemStatus { fresh, retry, retired }

enum TutorOutcome { correct, acceptable, incorrect }

enum TutorSeverity { minor, major }

class TutorScores {
  const TutorScores(this.meaning, this.grammar, this.naturalness)
    : assert(meaning >= 0 && meaning <= 2),
      assert(grammar >= 0 && grammar <= 2),
      assert(naturalness >= 0 && naturalness <= 2);
  final int meaning, grammar, naturalness;
  Map<String, Object> toJson() => {
    'meaning': meaning,
    'grammar': grammar,
    'naturalness': naturalness,
  };
}

class TutorError {
  const TutorError({
    required this.skill,
    required this.severity,
    required this.quote,
    required this.fix,
  });
  final String skill, quote, fix;
  final TutorSeverity severity;
  Map<String, Object> toJson() => {
    'skill': skill,
    'severity': severity.name,
    'quote': quote,
    'fix': fix,
  };
}

/// Order matters: the correct branch precedes the targeted-major check.
TutorOutcome tutorOutcome(
  TutorScores scores,
  Iterable<TutorError> errors,
  Iterable<String> targets,
) {
  if (scores.meaning == 2 && scores.grammar == 2 && scores.naturalness >= 1) {
    return TutorOutcome.correct;
  }
  if (scores.meaning >= 1 &&
      scores.grammar >= 1 &&
      scores.naturalness >= 1 &&
      !errors.any(
        (e) => e.severity == TutorSeverity.major && targets.contains(e.skill),
      )) {
    return TutorOutcome.acceptable;
  }
  return TutorOutcome.incorrect;
}

class TutorSkillState {
  const TutorSkillState({
    required this.lang,
    required this.skillId,
    this.tested = false,
    this.box = 0,
    this.dueAt,
    this.freshStreak = 0,
    required this.updatedAt,
    this.lastFreshTopic,
  });
  final String lang, skillId;
  final bool tested;
  final int box, freshStreak;
  final DateTime? dueAt;
  final DateTime updatedAt;

  /// Evidence for the different-topic guard, not a derived counter.
  final String? lastFreshTopic;
  bool get weak => tested && box <= 1;
  bool get secure => box >= 4 && freshStreak >= 2;
  bool due(DateTime now) => dueAt == null || !dueAt!.isAfter(now);
}

String normalizeTutorAnswer(String answer) =>
    answer.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();

class TutorItem {
  TutorItem({
    required this.id,
    required this.lang,
    required this.kind,
    required String promptDe,
    required this.referenceAnswer,
    required List<String> skills,
    required this.topic,
    required this.origin,
    required this.expiresAt,
    this.parentItemId,
    this.failures = 0,
    this.answerShown = false,
    this.status = TutorItemStatus.fresh,
    this.lastShownAt,
    this.lastRoundId,
    this.regenerationNeeded = false,
  }) : skills = List.unmodifiable(skills),
       promptDe = stripTutorInstruction(promptDe);
  final String id, lang, promptDe, referenceAnswer, topic;
  final List<String> skills;
  final TutorKind kind;
  final TutorOrigin origin;
  final String? parentItemId, lastRoundId;
  final int failures;
  final bool answerShown, regenerationNeeded;
  final TutorItemStatus status;
  final DateTime? lastShownAt;
  final DateTime expiresAt;
  bool expired(DateTime now) => !expiresAt.isAfter(now);
  String get primarySkill => skills.first;
  TutorItem copyWith({
    int? failures,
    bool? answerShown,
    TutorItemStatus? status,
    DateTime? lastShownAt,
    String? lastRoundId,
    bool? regenerationNeeded,
  }) => TutorItem(
    id: id,
    lang: lang,
    kind: kind,
    promptDe: promptDe,
    referenceAnswer: referenceAnswer,
    skills: skills,
    topic: topic,
    origin: origin,
    expiresAt: expiresAt,
    parentItemId: parentItemId,
    failures: failures ?? this.failures,
    answerShown: answerShown ?? this.answerShown,
    status: status ?? this.status,
    lastShownAt: lastShownAt ?? this.lastShownAt,
    lastRoundId: lastRoundId ?? this.lastRoundId,
    regenerationNeeded: regenerationNeeded ?? this.regenerationNeeded,
  );
}

class TutorAttempt {
  TutorAttempt({
    required this.attemptId,
    required this.itemId,
    required this.answer,
    required this.scores,
    required this.outcome,
    required List<TutorError> errors,
    required this.feedbackDe,
    required this.idealAnswer,
    required this.fresh,
    required this.createdAt,
    this.quotaUsed,
    this.quotaLimit,
  }) : errors = List.unmodifiable(errors);
  final String attemptId, itemId, answer, feedbackDe, idealAnswer;
  final TutorScores scores;
  final TutorOutcome outcome;
  final List<TutorError> errors;
  final bool fresh;
  final DateTime createdAt;
  final int? quotaUsed, quotaLimit;
}

class TutorItemRequest {
  TutorItemRequest({
    required List<String> skills,
    this.kind = TutorKind.translate,
    this.origin = TutorOrigin.practice,
    this.parentItemId,
  }) : skills = List.unmodifiable(skills);
  final List<String> skills;
  final TutorKind kind;
  final TutorOrigin origin;
  final String? parentItemId;
  Map<String, Object> toJson() => {
    'skills': skills,
    'kind': kind.name,
    'parent_item_id': ?parentItemId,
  };
}

class TutorUpdate {
  TutorUpdate(this.item, Map<String, TutorSkillState> states, this.regeneration)
    : states = Map.unmodifiable(states);
  final TutorItem item;
  final Map<String, TutorSkillState> states;
  final TutorItemRequest? regeneration;
}

const tutorIntervals = [0, 0, 1, 3, 7, 21];

TutorUpdate applyTutorAttempt({
  required TutorItem item,
  required TutorAttempt attempt,
  required Map<String, TutorSkillState> states,
  required DateTime now,
}) {
  if (item.id != attempt.itemId ||
      attempt.fresh != !item.answerShown ||
      item.status == TutorItemStatus.retired ||
      attempt.outcome !=
          tutorOutcome(attempt.scores, attempt.errors, item.skills)) {
    throw ArgumentError('Attempt does not match item or rubric');
  }
  final updated = Map<String, TutorSkillState>.of(states);
  final fresh = !item.answerShown;
  var regenerate = false;
  for (final id in item.skills) {
    final old =
        states[id] ??
        TutorSkillState(lang: item.lang, skillId: id, updatedAt: now);
    var box = old.box, streak = old.freshStreak;
    DateTime due = now;
    String? topic = old.lastFreshTopic;
    if (!old.tested && fresh && item.origin == TutorOrigin.diagnostic) {
      box = switch (attempt.outcome) {
        TutorOutcome.correct => 3,
        TutorOutcome.acceptable => 2,
        TutorOutcome.incorrect => 1,
      };
      streak = attempt.outcome == TutorOutcome.correct ? 1 : 0;
      topic = attempt.outcome == TutorOutcome.correct ? item.topic : null;
      due = now.add(Duration(days: tutorIntervals[box]));
    } else {
      switch (attempt.outcome) {
        case TutorOutcome.correct:
          if (fresh) {
            box = (box + 1).clamp(1, 5);
            streak = old.lastFreshTopic == item.topic ? 1 : streak + 1;
            topic = item.topic;
            due = now.add(Duration(days: tutorIntervals[box]));
          } else {
            // Recalling an exposed answer never proves fresh mastery.
            regenerate = regenerate || old.weak;
          }
        case TutorOutcome.acceptable:
          box = box.clamp(1, 5);
          streak = 0;
          topic = null;
          due = now.add(const Duration(days: 1));
        case TutorOutcome.incorrect:
          box = (box - 2).clamp(1, 5);
          streak = 0;
          topic = null;
      }
    }
    updated[id] = TutorSkillState(
      lang: item.lang,
      skillId: id,
      tested: true,
      box: box,
      dueAt: due,
      freshStreak: streak,
      updatedAt: now,
      lastFreshTopic: topic,
    );
  }
  final valid = tutorSkills[item.lang]!.map((s) => s.id).toSet();
  for (final id
      in attempt.errors
          .where(
            (e) =>
                e.severity == TutorSeverity.major &&
                !item.skills.contains(e.skill) &&
                valid.contains(e.skill),
          )
          .map((e) => e.skill)
          .toSet()) {
    final old = states[id];
    updated[id] = TutorSkillState(
      lang: item.lang,
      skillId: id,
      tested: true,
      box: old == null || !old.tested ? 1 : (old.box - 1).clamp(1, 5),
      dueAt: now,
      freshStreak: 0,
      updatedAt: now,
    );
  }
  final failures =
      item.failures + (attempt.outcome == TutorOutcome.incorrect ? 1 : 0);
  regenerate = regenerate || failures >= 3;
  final next = item.copyWith(
    failures: failures.clamp(0, 3),
    answerShown: true,
    lastShownAt: now,
    regenerationNeeded: regenerate,
    status: attempt.outcome == TutorOutcome.incorrect && failures < 3
        ? TutorItemStatus.retry
        : TutorItemStatus.retired,
  );
  return TutorUpdate(
    next,
    updated,
    regenerate
        ? TutorItemRequest(
            skills: item.skills,
            kind: item.kind,
            origin: TutorOrigin.regenerated,
            parentItemId: item.id,
          )
        : null,
  );
}

class TutorCounts {
  const TutorCounts(this.weak, this.secure, this.untested);
  final int weak, secure, untested;
}

TutorCounts tutorCounts(String lang, Map<String, TutorSkillState> states) {
  final catalog = tutorSkills[lang] ?? const <TutorSkill>[];
  return TutorCounts(
    catalog.where((s) => states[s.id]?.weak == true).length,
    catalog.where((s) => states[s.id]?.secure == true).length,
    catalog.where((s) => states[s.id]?.tested != true).length,
  );
}

class TutorRoundSlot {
  const TutorRoundSlot({this.item, required this.request});
  final TutorItem? item;
  final TutorItemRequest request;
  String get primarySkill => request.skills.first;
  bool get retry => item?.status == TutorItemStatus.retry;
}

/// Frozen selection; diagnostics can subsequently be skipped, never replaced.
List<TutorRoundSlot> composeTutorRound({
  required String lang,
  required Map<String, TutorSkillState> states,
  required List<TutorItem> items,
  required DateTime now,
  required bool premium,
  required int remainingDailyQuota,
  String? previousRoundId,
  int freshItemsSoFar = 0,
}) {
  final capacity = (premium ? 10 : remainingDailyQuota).clamp(0, 10);
  final catalog = tutorSkills[lang] ?? const <TutorSkill>[];
  if (capacity == 0 || catalog.isEmpty) return const [];
  final available =
      items.where((i) => i.lang == lang && !i.expired(now)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final untested = catalog.where((s) => states[s.id]?.tested != true).toList()
    ..sort((a, b) => a.levelIndex.compareTo(b.levelIndex));
  final selected = <TutorRoundSlot>[];
  final used = <String>{};
  final usedItems = <String>{};
  var freshCount = freshItemsSoFar;
  bool due(String id) => states[id]?.due(now) ?? true;
  void addFresh(String id, TutorOrigin origin) {
    if (selected.length >= capacity || used.contains(id)) return;
    final parents = available.where(
      (i) => i.regenerationNeeded && i.primarySkill == id,
    );
    final parent = parents.firstOrNull;
    final expiredParent = items
        .where(
          (item) =>
              item.lang == lang && item.primarySkill == id && item.expired(now),
        )
        .firstOrNull;
    final cached = available
        .where(
          (i) =>
              i.status == TutorItemStatus.fresh &&
              !i.answerShown &&
              i.primarySkill == id &&
              !usedItems.contains(i.id) &&
              (parent == null || i.parentItemId == parent.id) &&
              (origin != TutorOrigin.diagnostic || i.origin == origin) &&
              (states[id]?.lastFreshTopic == null ||
                  i.topic != states[id]!.lastFreshTopic),
        )
        .firstOrNull;
    freshCount++;
    final request = TutorItemRequest(
      skills: parent?.skills ?? expiredParent?.skills ?? [id],
      kind:
          cached?.kind ??
          (freshCount % 4 == 0 ? TutorKind.situation : TutorKind.translate),
      origin: parent != null ? TutorOrigin.regenerated : origin,
      parentItemId: parent?.id,
    );
    selected.add(TutorRoundSlot(item: cached, request: request));
    used.add(id);
    if (cached != null) usedItems.add(cached.id);
  }

  // Reserve diagnostics before taking retries/weak items (3+4+4 cannot fit 10).
  final reserve = untested.length.clamp(0, capacity.clamp(0, 4));
  for (final item in available.where(
    (i) =>
        i.status == TutorItemStatus.retry &&
        due(i.primarySkill) &&
        (previousRoundId == null || i.lastRoundId != previousRoundId),
  )) {
    if (selected.length >= 3 || selected.length >= capacity - reserve) break;
    if (used.contains(item.primarySkill)) continue;
    selected.add(
      TutorRoundSlot(
        item: item,
        request: TutorItemRequest(
          skills: item.skills,
          kind: item.kind,
          origin: item.origin,
        ),
      ),
    );
    used.add(item.primarySkill);
    usedItems.add(item.id);
  }
  final ranked =
      catalog.where((s) => states[s.id]?.tested == true && due(s.id)).toList()
        ..sort((a, b) {
          final c = states[a.id]!.box.compareTo(states[b.id]!.box);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
  var weak = 0;
  for (final skill in ranked.where((s) => states[s.id]!.weak)) {
    if (weak >= 4 || selected.length >= capacity - reserve) break;
    if (!used.contains(skill.id)) {
      addFresh(skill.id, TutorOrigin.practice);
      weak++;
    }
  }
  for (final skill in untested) {
    addFresh(skill.id, TutorOrigin.diagnostic);
  }
  for (final skill in ranked.where((s) => states[s.id]!.secure)) {
    addFresh(skill.id, TutorOrigin.review);
  }
  for (final skill in ranked) {
    addFresh(skill.id, TutorOrigin.practice);
  }
  // Within each group of four, place the situation on a suitable skill when
  // possible. Cached tasks keep their already-generated kind and content.
  final group = <int>[];
  var cadence = freshItemsSoFar;
  bool suitable(String id) =>
      RegExp('question|modal|imperativ|conditional|ipotetic|hipotetic')
          .hasMatch(id);
  TutorRoundSlot withKind(TutorRoundSlot slot, TutorKind kind) =>
      TutorRoundSlot(
        request: TutorItemRequest(
          skills: slot.request.skills,
          kind: kind,
          origin: slot.request.origin,
          parentItemId: slot.request.parentItemId,
        ),
      );
  for (var i = 0; i < selected.length; i++) {
    if (selected[i].retry) continue;
    cadence++;
    group.add(i);
    if (cadence % 4 != 0) continue;
    final preferred = group
        .where(
          (n) => selected[n].item == null && suitable(selected[n].primarySkill),
        )
        .firstOrNull;
    if (preferred != null &&
        preferred != i &&
        selected[i].item == null &&
        selected[i].request.kind == TutorKind.situation) {
      selected[i] = withKind(selected[i], TutorKind.translate);
      selected[preferred] = withKind(selected[preferred], TutorKind.situation);
    }
    group.clear();
  }
  // Each primary occurs once; interleave retries after fresh tasks.
  final fresh = selected.where((s) => !s.retry).toList();
  final retry = selected.where((s) => s.retry).toList();
  final mixed = <TutorRoundSlot>[];
  while (fresh.isNotEmpty || retry.isNotEmpty) {
    if (fresh.isNotEmpty) mixed.add(fresh.removeAt(0));
    if (retry.isNotEmpty) mixed.add(retry.removeAt(0));
  }
  return List.unmodifiable(mixed);
}

bool skipTutorDiagnostic(
  TutorRoundSlot slot,
  String lang,
  Iterable<TutorAttempt> attempts,
  Map<String, TutorItem> items,
) {
  if (slot.request.origin != TutorOrigin.diagnostic) return false;
  final catalog = {
    for (final s in tutorSkills[lang] ?? <TutorSkill>[]) s.id: s,
  };
  final level = catalog[slot.primarySkill]?.levelIndex;
  if (level == null || level < 2) return false;
  final failed = <String>{};
  for (final a in attempts) {
    final item = items[a.itemId];
    if (a.fresh &&
        a.outcome == TutorOutcome.incorrect &&
        item?.origin == TutorOrigin.diagnostic &&
        catalog[item!.primarySkill]?.levelIndex == level - 2) {
      failed.add(item.primarySkill);
    }
  }
  return failed.length >= 2;
}

String stripTutorInstruction(String text) => text
    .trim()
    .replaceFirst(
      RegExp(
        r'^(?:(?:bitte\s+)?(?:übersetze(?:n\s+Sie)?|translate)(?:\s+[^:]{0,60})?\s*:\s*)',
        caseSensitive: false,
      ),
      '',
    )
    .trim();
String tutorIntoLanguage(String lang) => switch (lang) {
  'en' => 'ins Englische',
  'pt-BR' => 'ins Portugiesische',
  'es' => 'ins Spanische',
  'it' => 'ins Italienische',
  'nb' => 'ins Norwegische',
  _ => throw ArgumentError.value(lang),
};
String tutorInLanguage(String lang) => switch (lang) {
  'en' => 'auf Englisch',
  'pt-BR' => 'auf Portugiesisch',
  'es' => 'auf Spanisch',
  'it' => 'auf Italienisch',
  'nb' => 'auf Norwegisch',
  _ => throw ArgumentError.value(lang),
};
