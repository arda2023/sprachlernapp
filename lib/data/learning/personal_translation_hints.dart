import '../../domain/personal_learning.dart';
import '../runtime_translation_client.dart';

/// Reads exact, account-scoped cached responses only. Never calls translate.
Future<Map<String, dynamic>> personalTranslationHints(
  RuntimeTranslationClient cache,
  PersonalTarget target,
) async {
  final hints = <String, dynamic>{};
  for (final kind in ['word', 'sentence']) {
    final word = kind == 'word';
    final request = TranslationRequest(
      lang: target.lang,
      text: target.text,
      form: word ? target.form : null,
      start: word ? target.start : null,
    );
    final result = await cache.cached(
      lang: target.lang,
      text: target.text,
      form: request.form,
      start: request.wordStart,
    );
    if (result == null) continue;
    final payload = result.payload;
    if (payload == null) {
      throw const FormatException('Cache provenance missing');
    }
    // Repeat contract/TTL validation at the adapter boundary; no invented hints.
    RuntimeTranslation.parse(payload, request);
    hints[kind] = {
      'request_key': request.key,
      'request_id': payload['request_id'],
      'contract': payload['contract'],
      'prompt': payload['prompt'],
      'created_at': payload['created_at'],
      'value': word ? payload['senses'].single : payload['translation_de'],
    };
  }
  return hints;
}
