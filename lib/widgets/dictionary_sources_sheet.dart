import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sources and licence of the offline dictionary (CC BY-SA 4.0). Reached
/// from Settings › Inhalte und Hilfe; the word bubble stays free of it.
Future<void> showDictionarySources(BuildContext context) async {
  final String notice, license;
  try {
    notice = await rootBundle.loadString(
      'assets/offline_dictionary/ATTRIBUTION.txt',
    );
    license = await rootBundle.loadString(
      'assets/offline_dictionary/CC-BY-SA-4.0.txt',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quelleninformationen derzeit nicht lesbar.'),
        ),
      );
    }
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => SizedBox(
      height: MediaQuery.sizeOf(sheet).height * 0.7,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText('$notice\n\n$license'),
      ),
    ),
  );
}
