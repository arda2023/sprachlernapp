import 'dart:async';
import 'dart:io';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Small compatibility adapter for the application's bounded JSON requests.
/// Keeping the native interface preserves injected transports in existing tests.
/// BrowserClient uses Fetch, enforces CORS and rejects disabled redirects.
HttpClient createPlatformHttpClient() => _BrowserHttpClient();

class _BrowserHttpClient implements HttpClient {
  final _client = BrowserClient();
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _Request(_client, 'POST', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async =>
      _Request(_client, 'DELETE', url);
  @override
  void close({bool force = false}) => _client.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.client, this.method, this.uri);
  final BrowserClient client;
  @override
  final String method;
  @override
  final Uri uri;
  final _body = StringBuffer();
  @override
  final _Headers headers = _Headers();
  @override
  bool followRedirects = true;
  @override
  void write(Object? object) => _body.write(object);
  @override
  Future<HttpClientResponse> close() async {
    final request = http.Request(method, uri)
      ..followRedirects = followRedirects
      ..headers.addAll(headers.values)
      ..body = _body.toString();
    return _Response(await client.send(request));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  final values = <String, String>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value.toString();
  }

  @override
  ContentType? get contentType => values['content-type'] == null
      ? null
      : ContentType.parse(values['content-type']!);
  @override
  set contentType(ContentType? value) {
    if (value == null) {
      values.remove('content-type');
    } else {
      values['content-type'] = value.toString();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.response);
  final http.StreamedResponse response;
  @override
  int get statusCode => response.statusCode;
  @override
  int get contentLength => response.contentLength ?? -1;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => response.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
