import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/tutor_skills.dart';

void main() {
  test('Dart catalog exactly mirrors canonical version, languages, skills and topics', () {
    final json = jsonDecode(
      File('supabase/functions/_shared/tutor_skills.json').readAsStringSync(),
    ) as Map;
    expect(tutorCatalogVersion, json['version']);
    final languages = json['languages'] as Map;
    expect(tutorSkills.keys.toList(), languages.keys.toList());
    for (final lang in languages.keys) {
      expect(
        tutorSkills[lang]!
            .map((s) => {'id': s.id, 'level': s.level, 'label': s.label})
            .toList(),
        (languages[lang] as List)
            .map(
              (s) => {'id': s['id'], 'level': s['level'], 'label': s['label']},
            )
            .toList(),
      );
      expect(
        tutorSkills[lang]!.map((s) => s.id).toSet().length,
        tutorSkills[lang]!.length,
      );
    }
    expect(tutorTopics, json['topics']);
  });
}
