import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/personal_sentence.dart';

void main() {
  test('bounded en/pt-BR replacement segmentation shared corpus', () {
    for (final pair in jsonDecode(
      File('test/fixtures/personal_sentence_cases.json').readAsStringSync(),
    ) as List) {
      expect(onePersonalSentence(pair[0]), pair[1], reason: pair[0]);
    }
  });
}
