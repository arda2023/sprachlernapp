import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../data/personal_learning_client.dart';
import '../../data/learning/personal_learning_service.dart';
import 'content_update_provider.dart';
import 'database_providers.dart';

final personalLearningClientProvider = Provider<PersonalLearningClient>((ref) {
  final auth = ref.read(contentAuthProvider);
  final store = PersonalConsentStore(() async {
    final dir = await getApplicationSupportDirectory();
    return sqlite3.open('${dir.path}/private_learning_consent.sqlite');
  });
  ref.onDispose(() => unawaited(store.close()));
  return PersonalLearningClient(
    url: auth.url,
    publicKey: auth.publicKey,
    token: auth.accessToken,
    owner: auth.cacheOwner,
    revision: () => auth.identityRevision,
    store: store,
  );
});
final personalLearningServiceProvider = FutureProvider<PersonalLearningService>(
  (ref) async {
    var active = true;
    ref.onDispose(() => active = false);
    final content = await ref.watch(contentRepositoryProvider.future);
    final user = await ref.watch(userRepositoryProvider.future);
    return PersonalLearningService(
      content: content,
      user: user,
      client: ref.watch(personalLearningClientProvider),
      verify: () {
        if (!active) {
          throw const PersonalLearningFailure(
            'Inhalt oder Sprache geändert. Bitte erneut öffnen.',
          );
        }
      },
    );
  },
  retry: (_, _) => null,
);
