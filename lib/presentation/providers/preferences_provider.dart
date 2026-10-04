import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/preferences.dart';
import 'database_providers.dart';

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, PracticePreferences>(
      PreferencesController.new,
    );

class PreferencesController extends AsyncNotifier<PracticePreferences> {
  @override
  Future<PracticePreferences> build() async =>
      (await ref.watch(userRepositoryProvider.future)).preferences();
  Future<void> save(PracticePreferences value) async {
    final repository = await ref.read(userRepositoryProvider.future);
    await repository.savePreferences(value);
    if (ref.mounted) state = AsyncData(value);
  }
}
