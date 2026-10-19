import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/runtime_translation_client.dart';
import 'content_update_provider.dart';

final runtimeTranslationProvider = Provider<RuntimeTranslationClient>((ref) {
  final auth = ref.read(contentAuthProvider);
  return RuntimeTranslationClient(auth.url, auth.publicKey, auth.accessToken);
});
