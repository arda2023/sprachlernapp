import 'dart:convert';

import 'package:crypto/crypto.dart';

const translationContract = 2;
const translationPrompt = 'translation-v2';
const translationModel = 'claude-haiku-5-5';

/// Exact UTF-16 offsets, matching Dart substring and JavaScript slice.
/// No case folding, NFC conversion or whitespace normalization.
class TranslationRequest {
  TranslationRequest({
    required this.lang,
    required this.text,
    this.form,
    int? start,
    this.senseRef,
    this.formRef,
  }) {
    if (!{'en', 'pt-BR'}.contains(lang) ||
        !_valid(text, 600) ||
        text.contains('\n')) {
      throw const FormatException('translation input');
    }
    if (form != null) {
      final at = start ?? text.indexOf(form!);
      if (!_valid(form!, 80) ||
          at < 0 ||
          at + form!.length > text.length ||
          text.substring(at, at + form!.length) != form ||
          (start == null && text.indexOf(form!, at + 1) != -1)) {
        throw const FormatException('translation span');
      }
      wordStart = at;
    } else if (start != null || senseRef != null || formRef != null) {
      throw const FormatException('sentence references');
    }
    for (final reference in [senseRef, formRef]) {
      if (reference != null && !_valid(reference, 200)) {
        throw const FormatException('translation reference');
      }
    }
  }
  final String lang, text;
  final String? form, senseRef, formRef;
  int? wordStart;
  String get kind => form == null ? 'translate-sentence' : 'lookup-word';
  Map<String, dynamic> get body => {
    'contract': translationContract,
    'lang': lang,
    'target_lang': 'de',
    if (form == null) 'text': text,
    if (form != null) ...{
      'sentence': text,
      'form': form,
      'start': wordStart,
      'end': wordStart! + form!.length,
      'sense_ref': senseRef,
      'form_ref': formRef,
    },
  };
  String get key => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            translationContract,
            translationPrompt,
            kind,
            lang,
            'de',
            text,
            form,
            wordStart,
            form == null ? null : wordStart! + form!.length,
            senseRef,
            formRef,
          ]),
        ),
      )
      .toString();
}

bool _valid(String value, int max) =>
    value.trim().isNotEmpty &&
    value.length <= max &&
    !RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(value);

/// Shared validation for HTTP results and persisted results. Invalid data is
/// never turned into a successful translation or cached error message.
class RuntimeTranslation {
  const RuntimeTranslation(
    this.text,
    this.model,
    this.requestId, {
    this.payload,
    this.storageWarning,
  });
  final String text, model, requestId;
  final Map<String, dynamic>? payload;
  final String? storageWarning;
  RuntimeTranslation withStorageWarning() => RuntimeTranslation(
    text,
    model,
    requestId,
    payload: payload,
    storageWarning:
        'Übersetzung angezeigt, aber auf diesem Gerät nicht gespeichert.',
  );
  static RuntimeTranslation parse(
    Map<String, dynamic> v,
    TranslationRequest r,
  ) {
    if (v['provider'] != 'anthropic' ||
        v['model'] != translationModel ||
        v['contract'] != translationContract ||
        v['prompt'] != translationPrompt ||
        v['request_id'] is! String ||
        !_valid(v['request_id'], 80) ||
        v['created_at'] is! String ||
        DateTime.tryParse(v['created_at']) == null ||
        DateTime.parse(v['created_at'])
            .isAfter(DateTime.now().add(const Duration(minutes: 1))) ||
        DateTime.parse(v['created_at'])
            .isBefore(DateTime.now().subtract(const Duration(days: 30))) ||
        v['cached'] is! bool) {
      throw const FormatException('translation response');
    }
    final usage = v['usage'];
    if (usage is! Map ||
        usage['input_tokens'] is! int ||
        usage['input_tokens'] < 0 ||
        usage['output_tokens'] is! int ||
        usage['output_tokens'] < 0 ||
        usage['output_tokens'] > 384) {
      throw const FormatException('translation usage');
    }
    String translated;
    if (r.form == null) {
      if (v['translation_de'] is! String ||
          !_valid(v['translation_de'], 1200)) {
        throw const FormatException('translation sentence');
      }
      translated = v['translation_de'];
    } else {
      final senses = v['senses'];
      if (v['form'] != r.form ||
          senses is! List ||
          senses.length != 1 ||
          senses.single is! Map) {
        throw const FormatException('translation senses');
      }
      final sense = senses.single as Map;
      if (sense.length != 4 ||
          ![
            'pos',
            'form_label',
            'gloss_de',
            'lemma',
          ].every((k) => sense[k] is String && _valid(sense[k], 200))) {
        throw const FormatException('translation sense');
      }
      translated = sense['gloss_de'];
    }
    return RuntimeTranslation(
      translated,
      v['model'],
      v['request_id'],
      payload: v,
    );
  }
}

class TranslationFailure implements Exception {
  const TranslationFailure(this.message);
  final String message;
}
