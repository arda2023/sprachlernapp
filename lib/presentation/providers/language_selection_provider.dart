import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/user_database.dart';
import '../../domain/content.dart';
import '../../domain/language_profile.dart';
import 'database_providers.dart';

final languageInstallationProvider = FutureProvider.family<String, String>((
  ref,
  lang,
) async {
  try {
    // The active language reports its shared reader; another language opens
    // through its owner, never as a second unowned connection.
    final selected = await ref
        .read(selectedContentLanguageProvider.future)
        .then<String?>((value) => value, onError: (Object _) => null);
    if (selected == lang) {
      return 'Installiert · ${(await ref.read(contentInfoProvider.future)).version}';
    }
    final installer = await ref.watch(contentInstallerProvider(lang).future);
    final lease = ref
        .read(contentOwnerProvider(await contentKeyFor(installer)))
        .lease();
    try {
      return 'Installiert · ${(await lease.future).info.version}';
    } finally {
      lease.release();
    }
  } on ContentUnavailable catch (e) {
    return switch (e.reason) {
      ContentUnavailableReason.missing => 'Noch nicht installiert',
      ContentUnavailableReason.corrupt => 'Installation beschädigt',
      ContentUnavailableReason.incompatible => 'Installation nicht kompatibel',
    };
  } catch (_) {
    return 'Installation nicht lesbar';
  }
}, retry: (_, _) => null);

class LanguageSelectionState {
  const LanguageSelectionState({this.switching = false, this.message});
  final bool switching;
  final String? message;
}

final languageSelectionProvider =
    NotifierProvider<LanguageSelectionController, LanguageSelectionState>(
      LanguageSelectionController.new,
    );

class LanguageSelectionController extends Notifier<LanguageSelectionState> {
  @override
  LanguageSelectionState build() => const LanguageSelectionState();

  Future<bool> selectLanguage(String lang) async {
    if (ContentLanguageProfile.forLanguage(lang) == null) {
      state = const LanguageSelectionState(
        message: 'Diese Lernsprache wird noch nicht unterstützt.',
      );
      return false;
    }
    if (contentTransitionGate.busy) {
      state = LanguageSelectionState(
        message: contentTransitionGate.blockingMessage,
      );
      return false;
    }
    try {
      return await contentTransitionGate.transition(() async {
        state = const LanguageSelectionState(switching: true);
        final previous = await ref.read(selectedContentLanguageProvider.future);
        if (previous == lang) {
          state = const LanguageSelectionState();
          return true;
        }
        // Validate the target before changing any settings or closing the old
        // reader. A never-installed language is a valid explicit empty state.
        // The lease keeps the validated reader open for the new scope.
        var installed = true;
        final target = ref
            .read(
              contentOwnerProvider(
                await contentKeyFor(
                  await ref.read(contentInstallerProvider(lang).future),
                ),
              ),
            )
            .lease();
        try {
          await target.future;
        } on ContentUnavailable catch (e) {
          target.release();
          if (e.reason != ContentUnavailableReason.missing) rethrow;
          installed = false;
        } catch (_) {
          target.release();
          rethrow;
        }
        try {
          final key = await ref.read(activeContentKeyProvider.future);
          final owner = ref.read(contentOwnerProvider(key));
          final db = await ref.read(userDatabaseProvider.future);
          await (await ref.read(userRepositoryProvider.future)).deviceId();
          var persisted = false;
          owner.pause();
          ref.invalidate(contentRepositoryProvider);
          try {
            await Future<void>.delayed(Duration.zero);
            await owner.closed();
            await (db.update(db.settings)..where((t) => t.id.equals(1))).write(
              SettingsCompanion(targetLang: Value(lang)),
            );
            persisted = true;
            ref.invalidate(selectedContentLanguageProvider);
            ref.invalidate(activeContentKeyProvider);
            // Rebuild the reader scope on the new key before resuming, so a
            // pending reader of the previous key is released, not reopened.
            ref.read(contentRepositoryProvider);
            owner.resume();
            await ref.read(selectedContentLanguageProvider.future);
            await ref.read(userRepositoryProvider.future);
            if (installed) await ref.read(contentRepositoryProvider.future);
            ref.invalidate(languageInstallationProvider(lang));
            state = const LanguageSelectionState();
            return true;
          } catch (_) {
            if (persisted) {
              await (db.update(db.settings)..where((t) => t.id.equals(1)))
                  .write(SettingsCompanion(targetLang: Value(previous)));
              ref.invalidate(selectedContentLanguageProvider);
              ref.invalidate(activeContentKeyProvider);
            }
            owner.resume();
            ref.invalidate(contentRepositoryProvider);
            rethrow;
          } finally {
            owner.resume();
          }
        } finally {
          target.release();
        }
      });
    } catch (_) {
      state = const LanguageSelectionState(
        message: 'Sprachwechsel nicht abgeschlossen. Die bisherige Auswahl bleibt erhalten. Installation und offene Inhaltsansichten prüfen.',
      );
      return false;
    }
  }
}
