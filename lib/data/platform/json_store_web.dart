import 'dart:convert';

import 'package:web/web.dart' as web;

import 'json_store_base.dart';

JsonStore createJsonStore(String name) => _BrowserJsonStore(name);

class _BrowserJsonStore implements JsonStore {
  _BrowserJsonStore(String name) : key = 'linglossa.ui.$name';
  final String key;
  @override
  Future<Object?> read() async {
    final value = web.window.localStorage.getItem(key);
    return value == null ? null : jsonDecode(value);
  }

  @override
  Future<void> write(Object? json) async =>
      web.window.localStorage.setItem(key, jsonEncode(json));
}
