import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';

final userChangesProvider = StreamProvider<int>((ref) async* {
  final user = await ref.watch(userRepositoryProvider.future);
  var revision = 0;
  // Every event needs a distinct value: repeated AsyncData<void>(null) can
  // otherwise be coalesced and leave derived progress stale.
  await for (final _ in user.changes()) {
    yield ++revision;
  }
});
