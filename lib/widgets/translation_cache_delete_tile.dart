import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/runtime_translation_client.dart';
import '../presentation/providers/runtime_translation_provider.dart';

class TranslationCacheDeleteTile extends ConsumerStatefulWidget {
  const TranslationCacheDeleteTile({super.key});
  @override
  ConsumerState<TranslationCacheDeleteTile> createState() => _DeleteState();
}

class _DeleteState extends ConsumerState<TranslationCacheDeleteTile> {
  bool busy = false;
  String? notice;
  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gespeicherte Übersetzungen löschen?'),
        content: const Text(
          'Die KI-Übersetzungen dieses Kontos werden auf diesem Gerät und in der Cloud gelöscht. Lernkarten, Storytexte und Fortschritt bleiben erhalten. Offline wird die Cloudlöschung vorgemerkt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await ref.read(runtimeTranslationProvider).clearSaved();
      if (mounted) {
        setState(() => notice = 'Gespeicherte Übersetzungen gelöscht.');
      }
    } on TranslationFailure catch (e) {
      if (mounted) setState(() => notice = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => notice = 'Löschen nicht abgeschlossen. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Gespeicherte Übersetzungen löschen'),
    subtitle: Text(notice ?? 'Nur KI-Übersetzungen dieses Kontos'),
    trailing: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(),
          )
        : const Icon(Icons.delete_outline),
    onTap: busy ? null : clear,
  );
}
