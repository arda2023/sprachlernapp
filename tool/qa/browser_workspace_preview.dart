// QA ONLY: isolated account and entitlement overrides for local visual review.
// This entry is never imported by lib/main.dart and must not be deployed.
// flutter run -d web-server --web-port 8348 -t tool/qa/browser_workspace_preview.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/sync/sync_json_store.dart';
import 'package:sprachapp/domain/content_access_policy.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/presentation/providers/account_provider.dart';
import 'package:sprachapp/presentation/providers/content_access_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_sync_provider.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';

class _PreviewSync extends LearningSyncController {
  @override
  LearningSyncPhase build() => LearningSyncPhase.offline;
  @override
  Future<void> synchronize() async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.ensureSemantics();
  const owner = 'local-visual-qa-only';
  final database = await UserDatabase.openForApp(accountId: owner);
  runApp(
    ProviderScope(
      overrides: [
        accountSessionProvider.overrideWith(
          (ref) => Stream.value((id: owner, email: 'qa@example.invalid')),
        ),
        userDatabaseProvider.overrideWith((ref) async => database),
        premiumContentAccessProvider.overrideWithValue(true),
        contentAccessProvider.overrideWithValue(ContentAccessDecision.allowed),
        learningSyncProvider.overrideWith(_PreviewSync.new),
        readingStoreProvider.overrideWith(
          (ref) => SyncJsonStore(
            Future.value(database),
            'reading_progress_en',
            isCurrent: () => true,
          ),
        ),
        importStoreProvider.overrideWith(
          (ref) => SyncJsonStore(
            Future.value(database),
            'imported_texts_en',
            list: true,
            isCurrent: () => true,
          ),
        ),
      ],
      child: const SprachApp(),
    ),
  );
}
