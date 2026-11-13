import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/learning/practice_item_resolver.dart';
import '../../domain/repositories.dart';
import 'database_providers.dart';
import 'user_changes_provider.dart';

final practiceCatalogProvider = FutureProvider<PracticeCatalog>((ref) async {
  return PracticeCatalog.load(
    await ref.watch(contentRepositoryProvider.future),
  );
}, retry: (_, _) => null);

final practiceResolverProvider = FutureProvider<PracticeItemResolver>((
  ref,
) async {
  ref.watch(userChangesProvider);
  final user = await ref.watch(userRepositoryProvider.future);
  ContentRepository? content;
  PracticeCatalog? catalog;
  Object? contentError;
  try {
    content = await ref.watch(contentRepositoryProvider.future);
    catalog = await ref.watch(practiceCatalogProvider.future);
  } catch (error) {
    content = null;
    contentError = error;
  }
  // A broken user read/correction is not a missing pack. Do not retry it via
  // the offline fallback and accidentally hide a technical failure.
  return PracticeItemResolver.load(
    user,
    content,
    catalog: catalog,
    contentError: contentError,
  );
}, retry: (_, _) => null);
