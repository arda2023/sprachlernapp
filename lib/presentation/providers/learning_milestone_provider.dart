import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/learning_milestone_store.dart';
import 'database_providers.dart';

final learningMilestoneStoreProvider = FutureProvider<LearningMilestoneStore>(
  (ref) async =>
      LearningMilestoneStore(await ref.watch(userDatabaseProvider.future)),
  retry: (_, _) => null,
);
