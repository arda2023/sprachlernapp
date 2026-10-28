import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/language_profile.dart';

void main() {
  test('Dart capabilities match exact exported Python profile manifests', () {
    final manifests = jsonDecode(
      File('test/fixtures/multilingual_profiles.json').readAsStringSync(),
    ) as Map;
    expect(
      ContentLanguageProfile.selectable.map((p) => p.lang),
      manifests.keys,
    );
    for (final profile in ContentLanguageProfile.selectable) {
      expect(profile.id, manifests[profile.lang]['id']);
      expect(profile.sha256, contextCanonicalHash(manifests[profile.lang]));
      expect(
        ContentLanguageProfile.resolve(
          profile.lang,
          profile.id,
          profile.sha256,
        ),
        profile,
      );
      expect(
        ContentLanguageProfile.resolve(profile.lang, profile.id, '0' * 64),
        isNull,
      );
      expect(profile.flag, isNotEmpty);
    }
    expect(ContentLanguageProfile.forLanguage('fr'), isNull);
    expect(ContentLanguageProfile.forLanguage('no'), isNull);
  });

  test(
    'language letters remain significant even with English accent toggle off',
    () {
      for (final sample in [
        (ContentLanguageProfile.portugueseBrazil, 'ação', 'acao'),
        (ContentLanguageProfile.norwegian, 'blå', 'bla'),
        (ContentLanguageProfile.norwegian, 'søt', 'sot'),
        (ContentLanguageProfile.norwegian, 'lær', 'lar'),
        (ContentLanguageProfile.italian, 'città', 'citta'),
        (ContentLanguageProfile.spanish, 'año', 'ano'),
      ]) {
        expect(
          evaluateAnswer(
            sample.$3,
            target: sample.$2,
            profile: sample.$1,
            includeDiacritics: false,
          ),
          isNot(AnswerVerdict.target),
        );
        expect(
          evaluateAnswer(
            sample.$2.toUpperCase(),
            target: sample.$2,
            profile: sample.$1,
          ),
          AnswerVerdict.target,
        );
        expect(
          evaluateAnswer(
            'altro',
            target: sample.$2,
            alternatives: ['altro'],
            profile: sample.$1,
          ),
          AnswerVerdict.alternative,
        );
        expect(
          evaluateAnswer(
            'forma',
            target: sample.$2,
            otherFormsOfLemma: {'forma'},
            profile: sample.$1,
          ),
          AnswerVerdict.wrongForm,
        );
      }
      expect(
        evaluateAnswer(
          'citta\u0300',
          target: 'città',
          profile: ContentLanguageProfile.italian,
        ),
        AnswerVerdict.target,
      );
    },
  );

  test('offers accept exact supported revisions and reject crossed language/profile', () {
    final original = jsonDecode(
      File('test/fixtures/portuguese_release/first/content.manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final profile in [
      ...ContentLanguageProfile.selectable,
      ContentLanguageProfile.portugueseBrazilV1,
    ]) {
      final m = {
        ...original,
        'lang': profile.lang,
        'profile_id': profile.id,
        'profile_sha256': profile.sha256,
        'release_id': '11111111-1111-4111-8111-111111111111',
        'channel': 'internal',
        'generation': 1,
      };
      Map<String, dynamic> offer() => {
        'manifest': m,
        'manifest_sha256': contextCanonicalHash(m),
        'objects': {
          for (final name in ['content.sqlite', 'history_inventory.json'])
            name: {'sha256': m['sha256'], 'size_bytes': m['size_bytes']},
        },
      };
      expect(ReleaseOffer.parse(offer(), profile.lang).lang, profile.lang);
      m['profile_sha256'] = '0' * 64;
      expect(
        () => ReleaseOffer.parse(offer(), profile.lang),
        throwsFormatException,
      );
    }
  });
}
