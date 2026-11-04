import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/generated_vocabulary_client.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/domain/generated_vocabulary.dart';

const requestId = '12345678-1234-4234-8234-123456789abc';
GeneratedVocabularyRequest request() => GeneratedVocabularyRequest(
  requestId: requestId,
  lang: 'en',
  prompt: 'Travel',
  count: 5,
);
Map<String, Object?> reply() => {
  'contract': 1,
  'request_id': requestId,
  'lang': 'en',
  'items': [
    {
      'form': 'ticket',
      'lemma': 'ticket',
      'pos': 'NOUN',
      'gloss_de': 'Fahrkarte',
      'definition_de': 'Nachweis einer bezahlten Fahrt.',
      'form_detail': 'Singular',
      'sentence': 'Buy a ticket today.',
      'translation_de': 'Kaufe heute eine Fahrkarte.',
      'start': 6,
    },
  ],
};

class MemoryConsent extends PersonalConsentStore {
  MemoryConsent() : super(() async => throw StateError('No database needed'));
  bool enabled = true, closed = false;
  @override
  Future<bool> read(String owner) async => enabled;
  @override
  Future<void> close() async {
    closed = true;
  }
}

class FakeHeaders implements HttpHeaders {
  final values = <String, Object>{};
  @override
  ContentType? contentType;
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeResponse(
    this.body, {
    this.statusCode = 200,
    this.contentLength = -1,
    this.beforeChunk,
  });
  final List<List<int>> body;
  final void Function()? beforeChunk;
  @override
  final int statusCode, contentLength;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return (() async* {
      for (final chunk in body) {
        beforeChunk?.call();
        yield chunk;
      }
    })().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRequest implements HttpClientRequest {
  FakeRequest(this.respond);
  final Future<HttpClientResponse> Function() respond;
  final body = StringBuffer();
  @override
  final FakeHeaders headers = FakeHeaders();
  @override
  bool followRedirects = true;
  @override
  void write(Object? value) => body.write(value);
  @override
  Future<HttpClientResponse> close() => respond();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClient implements HttpClient {
  FakeClient(this.respond);
  final Future<HttpClientResponse> Function() respond;
  final requests = <FakeRequest>[];
  final urls = <Uri>[];
  bool closed = false;
  void Function()? opened;
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    urls.add(url);
    final value = FakeRequest(respond);
    requests.add(value);
    opened?.call();
    return value;
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Harness {
  Harness({this.url = 'https://synthetic.invalid'}) {
    access = PersonalLearningClient(
      url: url,
      publicKey: 'public',
      token: () async {
        tokenCalls++;
        return await token();
      },
      owner: () async => owner,
      revision: () => epoch,
      store: consent,
    );
    http = FakeClient(() async => await respond());
    client = GeneratedVocabularyClient(
      access: access,
      createClient: () {
        clientCalls++;
        return http;
      },
    );
  }
  final String url;
  final consent = MemoryConsent();
  String? owner = 'owner';
  int epoch = 0, tokenCalls = 0, clientCalls = 0;
  Future<String> Function() token = () async => 'fixture-token';
  Future<HttpClientResponse> Function() respond = () async =>
      FakeResponse([utf8.encode(jsonEncode(reply()))]);
  late final PersonalLearningClient access;
  late final FakeClient http;
  late final GeneratedVocabularyClient client;
}

TypeMatcher<GeneratedVocabularyFailure> failure(String code) =>
    isA<GeneratedVocabularyFailure>().having(
      (error) => error.code,
      'code',
      code,
    );

void main() {
  test(
    'HTTPS request sends consent-bearing body, no redirects, strict response',
    () async {
      final h = Harness();
      addTearDown(h.access.close);
      final result = await h.client.generate(request());
      expect(result.items.single.form, 'ticket');
      expect(
        h.http.urls.single.toString(),
        'https://synthetic.invalid/functions/v1/generate-vocabulary',
      );
      final outgoing = h.http.requests.single;
      expect(outgoing.followRedirects, isFalse);
      expect(outgoing.headers.values['apikey'], 'public');
      expect(outgoing.headers.values['Authorization'], 'Bearer fixture-token');
      expect(jsonDecode(outgoing.body.toString()), request().toJson());
      expect(h.http.closed, isTrue);
      expect(h.consent.closed, isFalse);
      expect(h.tokenCalls, 1);
    },
  );

  test('status recovery uses same request UUID and status-only URL', () async {
    final h = Harness();
    addTearDown(h.access.close);
    await h.client.generate(request(), statusOnly: true);
    expect(h.http.urls.single.queryParameters, {'status': '1'});
    expect(
      jsonDecode(h.http.requests.single.body.toString())['request_id'],
      requestId,
    );
  });

  test('auth, consent, token and HTTPS are required before network', () async {
    for (final code in [
      'AUTH_REQUIRED',
      'CONSENT_REQUIRED',
      'NOT_CONFIGURED',
      'EMPTY_TOKEN',
    ]) {
      final h = Harness(
        url: code == 'NOT_CONFIGURED'
            ? 'http://synthetic.invalid'
            : 'https://synthetic.invalid',
      );
      addTearDown(h.access.close);
      if (code == 'AUTH_REQUIRED') h.owner = null;
      if (code == 'CONSENT_REQUIRED') h.consent.enabled = false;
      if (code == 'EMPTY_TOKEN') h.token = () async => '';
      await expectLater(
        h.client.generate(request()),
        throwsA(failure(code == 'EMPTY_TOKEN' ? 'AUTH_REQUIRED' : code)),
      );
      expect(h.clientCalls, 0);
    }
  });

  test(
    'account or consent change while token is loading prevents send',
    () async {
      for (final consentChanged in [false, true]) {
        final h = Harness();
        addTearDown(h.access.close);
        h.token = () async {
          if (consentChanged) {
            h.access.consentRevision++;
          } else {
            h.owner = 'another';
            h.epoch++;
          }
          return 'old-token';
        };
        await expectLater(
          h.client.generate(request()),
          throwsA(failure('ACCESS_CHANGED')),
        );
        expect(h.clientCalls, 0);
      }
    },
  );

  test('stale account or consent cannot return a completed response', () async {
    for (final stage in ['open', 'close', 'chunk']) {
      final h = Harness();
      addTearDown(h.access.close);
      void change() {
        h.owner = 'another';
        h.epoch++;
      }

      if (stage == 'open') h.http.opened = change;
      h.respond = () async {
        if (stage == 'close') change();
        return FakeResponse(
          [utf8.encode(jsonEncode(reply()))],
          beforeChunk: stage == 'chunk'
              ? () {
                  h.access.consentRevision++;
                }
              : null,
        );
      };
      await expectLater(
        h.client.generate(request()),
        throwsA(failure('ACCESS_CHANGED')),
      );
      expect(h.http.closed, isTrue);
      expect(h.http.requests, hasLength(1));
      if (stage == 'open') {
        expect(h.http.requests.single.body.toString(), isEmpty);
      }
    }
  });

  test(
    'bounded streamed body and strict malformed responses fail safely',
    () async {
      for (final response in [
        FakeResponse([List.filled(300001, 97)]),
        FakeResponse([List.filled(150000, 97), List.filled(150001, 97)]),
        FakeResponse([], contentLength: 300001),
        FakeResponse([utf8.encode('not JSON secret-error')]),
        FakeResponse([
          utf8.encode(jsonEncode({...reply(), 'secret': true})),
        ]),
        FakeResponse([
          [0xff],
        ]),
      ]) {
        final h = Harness();
        addTearDown(h.access.close);
        h.respond = () async => response;
        await expectLater(
          h.client.generate(request()),
          throwsA(failure('RESPONSE_INVALID')),
        );
        expect(h.http.closed, isTrue);
        expect(h.http.requests, hasLength(1));
      }
    },
  );

  test(
    'server codes are allowlisted, raw messages never escape, no retry',
    () async {
      for (final known in [true, false]) {
        final h = Harness();
        addTearDown(h.access.close);
        h.respond = () async => FakeResponse([
          utf8.encode(
            jsonEncode({
              'error': known ? 'REQUEST_UNCERTAIN' : 'secret provider error',
              'message': 'secret provider details',
            }),
          ),
        ], statusCode: 409);
        await expectLater(
          h.client.generate(request()),
          throwsA(
            failure(known ? 'REQUEST_UNCERTAIN' : 'SERVICE_UNAVAILABLE')
                .having((e) => e.status, 'status', 409)
                .having((e) => e.uncertain, 'uncertain', true)
                .having(
                  (e) => e.message.contains('secret'),
                  'raw details',
                  false,
                ),
          ),
        );
        expect(h.http.requests, hasLength(1));
      }
    },
  );
  test('monthly limit and off-topic denial have actionable messages without a retry', () async {
    for (final code in ['AI_MONTHLY_LIMIT', 'TOPIC_NOT_ALLOWED']) {
      final h = Harness();
      addTearDown(h.access.close);
      h.respond = () async => FakeResponse([
        utf8.encode(
          jsonEncode({'error': code, 'message': 'secret provider details'}),
        ),
      ], statusCode: code == 'AI_MONTHLY_LIMIT' ? 429 : 422);
      await expectLater(
        h.client.generate(request()),
        throwsA(
          failure(code)
              .having((e) => e.uncertain, 'uncertain', false)
              .having(
                (e) => e.message.contains(
                  code == 'AI_MONTHLY_LIMIT' ? 'Monat' : 'Vokabelthema',
                ),
                'actionable',
                true,
              )
              .having((e) => e.message.contains('secret'), 'safe', false),
        ),
      );
      expect(h.http.requests, hasLength(1));
    }
  });
}
