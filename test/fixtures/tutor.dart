import 'dart:async';

import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/data/tutor/tutor_client.dart';
import 'package:sprachapp/data/tutor/tutor_codec.dart';
import 'package:sprachapp/domain/tutor.dart';
import 'package:sprachapp/domain/tutor_skills.dart';

String tutorTestId(int n) =>
    '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
final tutorTestNow = DateTime.utc(2026, 11, 22, 12);
TutorItem tutorTestItem({
  int id = 1,
  String lang = 'en',
  String? skill,
  TutorOrigin origin = TutorOrigin.diagnostic,
  String topic = 'alltag',
  DateTime? expiresAt,
}) => TutorItem(
  id: tutorTestId(id),
  lang: lang,
  kind: TutorKind.translate,
  promptDe: 'Ich gehe heute nach Hause.',
  referenceAnswer: 'I am going home today.',
  skills: [skill ?? tutorSkills[lang]!.first.id],
  topic: topic,
  origin: origin,
  expiresAt: expiresAt ?? tutorTestNow.add(const Duration(days: 30)),
);
TutorGrade tutorTestGrade({
  TutorOutcome outcome = TutorOutcome.correct,
  int used = 1,
  int limit = 3,
  String quotaDay = '2026-11-22',
}) => TutorGrade(
  scores: switch (outcome) {
    TutorOutcome.correct => const TutorScores(2, 2, 2),
    TutorOutcome.acceptable => const TutorScores(2, 1, 1),
    TutorOutcome.incorrect => const TutorScores(0, 0, 0),
  },
  outcome: outcome,
  errors: [],
  feedbackDe: 'Die Bedeutung stimmt.',
  idealAnswer: 'I am going home today.',
  used: used,
  limit: limit,
  quotaDay: quotaDay,
);

class TutorMemoryConsent extends PersonalConsentStore {
  TutorMemoryConsent() : super(() async => throw StateError('No DB'));
  bool enabled = true;
  @override
  Future<bool> read(String owner) async => enabled;
  @override
  Future<void> write(String owner, bool value) async {
    enabled = value;
  }

  @override
  Future<void> close() async {}
}

PersonalLearningClient tutorTestAccess() => PersonalLearningClient(
  url: 'https://synthetic.invalid',
  publicKey: 'public',
  token: () async => 'fixture-token',
  owner: () async => 'owner',
  revision: () => 0,
  store: TutorMemoryConsent(),
);

class FakeTutorClient extends TutorClient {
  FakeTutorClient() : super(access: tutorTestAccess());
  final generationRequests = <TutorGenerationRequest>[];
  final gradeRequests = <({String id, String itemId, String answer})>[];
  Future<void> Function()? beforeGenerate, beforeGrade;
  TutorFailure? generateFailure, gradeFailure;
  TutorOutcome outcome = TutorOutcome.correct;
  int sequence = 1000;
  int used = 0;
  int limit = 150;
  final _generated = <String, List<TutorItem>>{};
  final _graded = <String, TutorGrade>{};
  @override
  Future<List<TutorItem>> generate(TutorGenerationRequest request) async {
    generationRequests.add(request);
    await beforeGenerate?.call();
    if (generateFailure != null) throw generateFailure!;
    return _generated.putIfAbsent(
      request.requestId,
      () => [
        for (final spec in request.items)
          TutorItem(
            id: tutorTestId(sequence++),
            lang: request.lang,
            kind: spec.kind,
            promptDe: spec.kind == TutorKind.situation
                ? 'Wie fragst du nach der Uhrzeit?'
                : 'Ich gehe heute nach Hause.',
            referenceAnswer: 'I am going home today.',
            skills: spec.skills,
            topic: tutorTopics.firstWhere(
              (t) => !request.avoidTopics.contains(t),
            ),
            origin: spec.origin,
            expiresAt: tutorTestNow.add(const Duration(days: 30)),
            parentItemId: spec.parentItemId,
          ),
      ],
    );
  }

  @override
  Future<TutorGrade> grade({
    required String attemptId,
    required TutorItem item,
    required String answer,
  }) async {
    gradeRequests.add((id: attemptId, itemId: item.id, answer: answer));
    await beforeGrade?.call();
    if (gradeFailure != null) throw gradeFailure!;
    return _graded.putIfAbsent(
      attemptId,
      () => tutorTestGrade(outcome: outcome, used: ++used, limit: limit),
    );
  }
}
