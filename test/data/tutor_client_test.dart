import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/data/tutor/tutor_client.dart';
import 'package:sprachapp/data/tutor/tutor_codec.dart';
import 'package:sprachapp/domain/tutor.dart';

import '../fixtures/tutor.dart';
import 'generated_vocabulary_client_test.dart' show FakeClient, FakeResponse;

TutorGenerationRequest request() => TutorGenerationRequest(
  requestId: tutorTestId(99),
  lang: 'en',
  items: [
    TutorItemRequest(skills: ['present_simple']),
  ],
  avoidTopics: ['reisen'],
);
Map<String, Object> generated() => {
  'items': [
    {
      'id': tutorTestId(1),
      'kind': 'translate',
      'prompt_de': 'Übersetze: Ich gehe heute nach Hause.',
      'reference_answer': 'I am going home today.',
      'skills': ['present_simple'],
      'topic': 'alltag',
      'expires_at': tutorTestNow
          .add(const Duration(days: 30))
          .toIso8601String(),
    },
  ],
};
TypeMatcher<TutorFailure> failure(String code) =>
    isA<TutorFailure>().having((e) => e.code, 'code', code);

void main() {
  late PersonalLearningClient access;
  late FakeClient http;
  late TutorClient client;
  late TutorMemoryConsent consent;
  late Future<HttpClientResponse> Function() respond;
  String? owner;
  int revision = 0;
  setUp(() {
    owner = 'owner';
    revision = 0;
    consent = TutorMemoryConsent();
    access = PersonalLearningClient(
      url: 'https://synthetic.invalid',
      publicKey: 'public',
      token: () async => 'fixture-token',
      owner: () async => owner,
      revision: () => revision,
      store: consent,
    );
    respond = () async => FakeResponse([utf8.encode(jsonEncode(generated()))]);
    http = FakeClient(() => respond());
    client = TutorClient(access: access, createClient: () => http);
  });
  tearDown(() => access.close());
  test(
    'terminal body codes survive transport instead of becoming uncertain',
    () async {
      final contract = jsonDecode(
        File('supabase/functions/_shared/tutor_errors.json').readAsStringSync(),
      ) as Map;
      for (final entry in (contract['terminal'] as Map).entries) {
        final code = entry.key as String;
        respond = () async => FakeResponse([
          utf8.encode(jsonEncode({'error': code})),
        ], statusCode: entry.value as int);
        await expectLater(
          client.grade(
            attemptId: tutorTestId(2),
            item: tutorTestItem(),
            answer: 'answer',
          ),
          throwsA(
            failure(code)
                .having((error) => error.uncertain, 'uncertain', false)
                .having(
                  (error) => error.terminalForId,
                  'terminal for ID',
                  true,
                ),
          ),
        );
      }
      for (final code in contract['uncertain'] as List) {
        respond = () async => FakeResponse([
          utf8.encode(jsonEncode({'error': code})),
        ], statusCode: 503);
        await expectLater(
          client.generate(request()),
          throwsA(
            failure(code as String)
                .having((error) => error.uncertain, 'uncertain', true)
                .having(
                  (error) => error.terminalForId,
                  'terminal for ID',
                  false,
                ),
          ),
        );
      }
    },
  );
  test('unclassified or bodyless 5xx keeps same-ID recovery', () async {
    for (final body in ['', 'Bad Gateway', '{}', '{"error":"FUTURE_ERROR"}']) {
      respond = () async => FakeResponse([utf8.encode(body)], statusCode: 502);
      await expectLater(
        client.generate(request()),
        throwsA(
          failure('SERVICE_UNAVAILABLE')
              .having((error) => error.uncertain, 'uncertain', true)
              .having((error) => error.terminalForId, 'terminal for ID', false),
        ),
      );
    }
  });
  test('multiline answer is normalized on the wire', () async {
    respond = () async =>
        FakeResponse([utf8.encode(jsonEncode(tutorTestGrade().toJson()))]);
    await client.grade(
      attemptId: tutorTestId(2),
      item: tutorTestItem(),
      answer: '  I\n\t go   home. ',
    );
    expect(
      jsonDecode(http.requests.single.body.toString())['answer'],
      'I go home.',
    );
  });
  test('expired generated items never enter a round', () async {
    final payload = generated();
    final row = (payload['items'] as List).single as Map;
    row['expires_at'] = tutorTestNow.toIso8601String();
    final items = decodeTutorItems(payload, request());
    final round = composeTutorRound(
      lang: 'en',
      states: {
        'present_simple': TutorSkillState(
          lang: 'en',
          skillId: 'present_simple',
          tested: true,
          box: 1,
          updatedAt: tutorTestNow,
        ),
      },
      items: items,
      now: tutorTestNow,
      premium: true,
      remainingDailyQuota: 3,
    );
    expect(round.where((slot) => slot.item?.id == items.single.id), isEmpty);
    expect(round.every((slot) => slot.request.parentItemId == null), true);
  });
  test(
    'generate contract, HTTPS auth, consent, no redirect, prefix stripped',
    () async {
      final items = await client.generate(request());
      expect(items.single.promptDe, 'Ich gehe heute nach Hause.');
      expect(http.urls.single.path, '/functions/v1/tutor-generate');
      final outgoing = http.requests.single;
      expect(outgoing.followRedirects, false);
      expect(outgoing.headers.values['Authorization'], 'Bearer fixture-token');
      expect(outgoing.headers.values['apikey'], 'public');
      expect(jsonDecode(outgoing.body.toString()), request().toJson());
      expect(request().toJson()['consent'], 1);
      expect(http.closed, true);
    },
  );
  test('grade sends only attempt/item/trimmed answer and consent', () async {
    respond = () async =>
        FakeResponse([utf8.encode(jsonEncode(tutorTestGrade().toJson()))]);
    final grade = await client.grade(
      attemptId: tutorTestId(2),
      item: tutorTestItem(),
      answer: '  Answer  ',
    );
    expect(grade.outcome, TutorOutcome.correct);
    expect(grade.used, 1);
    expect(grade.limit, 3);
    expect(http.urls.single.path, '/functions/v1/tutor-grade');
    expect(jsonDecode(http.requests.single.body.toString()), {
      'consent': 1,
      'attempt_id': tutorTestId(2),
      'item_id': tutorTestId(1),
      'answer': 'Answer',
    });
  });
  test('missing auth or consent fails before transport', () async {
    owner = null;
    await expectLater(
      client.generate(request()),
      throwsA(failure('AUTH_REQUIRED')),
    );
    owner = 'owner';
    consent.enabled = false;
    await expectLater(
      client.generate(request()),
      throwsA(failure('CONSENT_REQUIRED')),
    );
    expect(http.requests, isEmpty);
  });
  test(
    'identity/consent changes during open, response or stream fail closed',
    () async {
      for (final stage in ['open', 'response', 'stream']) {
        http.opened = stage == 'open' ? () => revision++ : null;
        respond = () async {
          if (stage == 'response') revision++;
          return FakeResponse(
            [utf8.encode(jsonEncode(generated()))],
            beforeChunk: stage == 'stream'
                ? () => access.consentRevision++
                : null,
          );
        };
        await expectLater(
          client.generate(request()),
          throwsA(failure('ACCESS_CHANGED')),
        );
      }
    },
  );
  test(
    'known failures mapped safely, daily premium flag only for daily limit',
    () async {
      for (final code in [
        'AUTH_REQUIRED',
        'CONSENT_REQUIRED',
        'TUTOR_DAILY_LIMIT',
        'AI_MONTHLY_LIMIT',
        'MODEL_INVALID',
        'CONFLICT',
        'secret',
      ]) {
        respond = () async => FakeResponse([
          utf8.encode(
            jsonEncode({
              'error': code,
              'premium_required': true,
              'message': 'secret provider diagnostics',
            }),
          ),
        ], statusCode: 429);
        await expectLater(
          client.generate(request()),
          throwsA(
            failure(code == 'secret' ? 'SERVICE_UNAVAILABLE' : code)
                .having(
                  (e) => e.premiumRequired,
                  'paywall',
                  code == 'TUTOR_DAILY_LIMIT',
                )
                .having(
                  (e) => e.message.contains('secret'),
                  'safe message',
                  false,
                ),
          ),
        );
      }
      expect(http.requests, hasLength(7));
    },
  );
  test(
    'network offline and malformed payloads are typed failures, no auto retry',
    () async {
      respond = () async => throw const SocketException('offline');
      await expectLater(
        client.generate(request()),
        throwsA(failure('NETWORK_UNAVAILABLE')),
      );
      for (final body in [
        'not JSON',
        jsonEncode({'items': []}),
        jsonEncode({
          'items': [
            {
              ...(generated()['items'] as List).single as Map,
              'topic': 'reisen',
            },
          ],
        }),
        'a' * 300001,
      ]) {
        respond = () async => FakeResponse([utf8.encode(body)]);
        await expectLater(
          client.generate(request()),
          throwsA(failure('RESPONSE_INVALID')),
        );
      }
      expect(http.requests, hasLength(5));
    },
  );
  test(
    'grade refuses invalid score, wrong outcome, unknown error skill and quota',
    () async {
      for (final bad in [
        {
          ...tutorTestGrade().toJson(),
          'scores': {'meaning': 3, 'grammar': 2, 'naturalness': 2},
        },
        {...tutorTestGrade().toJson(), 'outcome': 'incorrect'},
        {
          ...tutorTestGrade().toJson(),
          'errors': [
            {'skill': 'invented', 'severity': 'major', 'quote': '', 'fix': ''},
          ],
        },
        {
          ...tutorTestGrade().toJson(),
          'quota': {'used': 4, 'limit': 3},
        },
      ]) {
        respond = () async => FakeResponse([utf8.encode(jsonEncode(bad))]);
        await expectLater(
          client.grade(
            attemptId: tutorTestId(2),
            item: tutorTestItem(),
            answer: 'answer',
          ),
          throwsA(failure('RESPONSE_INVALID')),
        );
      }
    },
  );
  test(
    'request count, skill and answer limits rejected before sending',
    () async {
      for (final count in [0, 6]) {
        await expectLater(
          client.generate(
            TutorGenerationRequest(
              requestId: tutorTestId(99),
              lang: 'en',
              items: List.generate(
                count,
                (_) => TutorItemRequest(skills: ['present_simple']),
              ),
            ),
          ),
          throwsA(failure('INPUT_INVALID')),
        );
      }
      for (final answer in ['', 'a' * 301]) {
        await expectLater(
          client.grade(
            attemptId: tutorTestId(2),
            item: tutorTestItem(),
            answer: answer,
          ),
          throwsA(failure('INPUT_INVALID')),
        );
      }
      expect(http.requests, isEmpty);
    },
  );
}
