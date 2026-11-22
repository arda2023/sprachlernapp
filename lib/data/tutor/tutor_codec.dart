import '../../domain/tutor.dart';
import '../../domain/tutor_skills.dart';

final tutorUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

class TutorGenerationRequest {
  TutorGenerationRequest({
    required this.requestId,
    required this.lang,
    required List<TutorItemRequest> items,
    List<String> avoidTopics = const [],
  }) : items = List.unmodifiable(items),
       avoidTopics = List.unmodifiable(avoidTopics);
  final String requestId, lang;
  final List<TutorItemRequest> items;
  final List<String> avoidTopics;
  void validate() {
    final ids = tutorSkills[lang]?.map((s) => s.id).toSet();
    if (!tutorUuid.hasMatch(requestId) ||
        ids == null ||
        items.isEmpty ||
        items.length > 5 ||
        avoidTopics.length > 8 ||
        !avoidTopics.every(tutorTopics.contains) ||
        items.any(
          (i) =>
              i.skills.isEmpty ||
              i.skills.length > 2 ||
              i.skills.toSet().length != i.skills.length ||
              !i.skills.every(ids.contains) ||
              (i.parentItemId != null && !tutorUuid.hasMatch(i.parentItemId!)),
        )) {
      throw const FormatException('Invalid tutor request');
    }
  }

  Map<String, Object> toJson() => {
    'consent': 1,
    'request_id': requestId,
    'lang': lang,
    'items': items.map((i) => i.toJson()).toList(),
    'avoid_topics': avoidTopics,
  };
  Map<String, Object> toStorageJson() => {
    ...toJson(),
    'origins': items.map((i) => i.origin.name).toList(),
  };
  factory TutorGenerationRequest.fromStorageJson(Map<String, dynamic> json) =>
      TutorGenerationRequest(
        requestId: json['request_id'] as String,
        lang: json['lang'] as String,
        avoidTopics: List<String>.from(json['avoid_topics'] as List),
        items: [
          for (var n = 0; n < (json['items'] as List).length; n++)
            TutorItemRequest(
              skills: List<String>.from(json['items'][n]['skills'] as List),
              kind: TutorKind.values.byName(json['items'][n]['kind'] as String),
              origin: TutorOrigin.values.byName(json['origins'][n] as String),
              parentItemId: json['items'][n]['parent_item_id'] as String?,
            ),
        ],
      );
}

class TutorGrade {
  TutorGrade({
    required this.scores,
    required this.outcome,
    required List<TutorError> errors,
    required this.feedbackDe,
    required this.idealAnswer,
    required this.used,
    required this.limit,
    required this.quotaDay,
  }) : errors = List.unmodifiable(errors);
  final TutorScores scores;
  final TutorOutcome outcome;
  final List<TutorError> errors;
  final String feedbackDe, idealAnswer;
  final int used, limit;
  final String quotaDay;
  Map<String, Object> toJson() => {
    'scores': scores.toJson(),
    'outcome': outcome.name,
    'errors': errors.map((e) => e.toJson()).toList(),
    'feedback_de': feedbackDe,
    'ideal_answer': idealAnswer,
    'quota': {'used': used, 'limit': limit, 'quota_day': quotaDay},
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

String _text(Object? value, int min, int max) {
  if (value is! String || value.trim().length < min || value.length > max) {
    throw const FormatException('Invalid text');
  }
  return value;
}

int _integer(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid integer');
  }
  return value;
}

List<TutorItem> decodeTutorItems(
  Object? value,
  TutorGenerationRequest request,
) {
  final rows = _map(value)['items'];
  if (rows is! List || rows.length != request.items.length) {
    throw const FormatException('Item count');
  }
  final ids = <String>{};
  return List.unmodifiable([
    for (var n = 0; n < rows.length; n++)
      (() {
        final row = _map(rows[n]);
        final spec = request.items[n];
        final id = _text(row['id'], 36, 36);
        final kind = _text(row['kind'], 1, 20);
        final skills = row['skills'];
        final topic = _text(row['topic'], 1, 40);
        final prompt = stripTutorInstruction(_text(row['prompt_de'], 8, 240));
        final reference = _text(row['reference_answer'], 2, 200);
        final expiresAt = DateTime.tryParse(_text(row['expires_at'], 20, 40));
        if (expiresAt == null || !expiresAt.isUtc) {
          throw const FormatException('Invalid item expiry');
        }
        if (!tutorUuid.hasMatch(id) ||
            !ids.add(id) ||
            kind != spec.kind.name ||
            skills is! List ||
            skills.isEmpty ||
            skills.length > 2 ||
            skills.toSet().length != skills.length ||
            skills.first != spec.skills.first ||
            !skills.every(spec.skills.contains) ||
            (spec.parentItemId != null &&
                skills.length != spec.skills.length) ||
            !tutorTopics.contains(topic) ||
            request.avoidTopics.contains(topic) ||
            prompt.length < 8 ||
            prompt.length > 160 ||
            prompt == reference ||
            !RegExp(r'[.!?]$').hasMatch(prompt) ||
            (kind == 'situation' && !prompt.endsWith('?'))) {
          throw const FormatException('Invalid tutor item');
        }
        return TutorItem(
          id: id,
          lang: request.lang,
          kind: spec.kind,
          promptDe: prompt,
          referenceAnswer: reference,
          skills: List<String>.from(skills),
          topic: topic,
          origin: spec.origin,
          expiresAt: expiresAt,
          parentItemId: spec.parentItemId,
        );
      })(),
  ]);
}

TutorGrade decodeTutorGrade(Object? value, TutorItem item) {
  final json = _map(value), scores = _map(_map(value)['scores']);
  final s = TutorScores(
    _integer(scores['meaning'], 0, 2),
    _integer(scores['grammar'], 0, 2),
    _integer(scores['naturalness'], 0, 2),
  );
  final rows = json['errors'];
  if (rows is! List || rows.length > 4) throw const FormatException('Errors');
  final valid = {'other', ...tutorSkills[item.lang]!.map((s) => s.id)};
  final errors = <TutorError>[];
  for (final raw in rows) {
    final e = _map(raw);
    if (!valid.contains(e['skill']) ||
        !['minor', 'major'].contains(e['severity'])) {
      throw const FormatException('Error skill/severity');
    }
    errors.add(
      TutorError(
        skill: e['skill'] as String,
        severity: TutorSeverity.values.byName(e['severity'] as String),
        quote: _text(e['quote'], 0, 60),
        fix: _text(e['fix'], 0, 60),
      ),
    );
  }
  final outcome = tutorOutcome(s, errors, item.skills);
  if (json['outcome'] != outcome.name) {
    throw const FormatException('Rubric mismatch');
  }
  final quota = _map(json['quota']);
  final limit = _integer(quota['limit'], 1, 150);
  final quotaDay = _text(quota['quota_day'], 10, 10);
  final parsedDay = DateTime.tryParse(quotaDay);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(quotaDay) ||
      parsedDay == null ||
      parsedDay.toIso8601String().substring(0, 10) != quotaDay) {
    throw const FormatException('Invalid quota day');
  }
  return TutorGrade(
    scores: s,
    outcome: outcome,
    errors: errors,
    feedbackDe: _text(json['feedback_de'], 1, 220),
    idealAnswer: _text(json['ideal_answer'], 1, 200),
    used: _integer(quota['used'], 0, limit),
    limit: limit,
    quotaDay: quotaDay,
  );
}
