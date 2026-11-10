// Standalone browser QA harness. Never imported by production.
// flutter run -d chrome -t tool/qa/browser_storage_smoke.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/user/user_database.dart';

void check(bool result, String label) {
  if (!result) throw StateError('Failed: $label');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.ensureSemantics();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Text('Browser storage verification running')),
    ),
  );
  try {
    final languageResults = <String>[];
    for (final lang in ['en', 'pt-BR', 'es', 'it', 'nb']) {
      final content = await (await ContentPackInstaller.forApp(lang: lang))
          .open();
      try {
        check(content.info.lang == lang, '$lang identity');
        final decks = await content.decks();
        check(decks.isNotEmpty, '$lang decks');
        var verifiedPractice = false;
        for (final deck in decks) {
          final ids = await content.deckCardIds(deck.id);
          if (ids.isEmpty) continue;
          final practice = await content.practiceItems(ids.take(1).toList());
          if (practice.isNotEmpty) {
            verifiedPractice = true;
            break;
          }
        }
        check(verifiedPractice, '$lang real practice item');
        final stories = await content.storySummaries();
        final bundled = jsonDecode(
          await rootBundle.loadString('assets/content/$lang/stories.json'),
        ) as List;
        check(stories.isNotEmpty || bundled.isNotEmpty, '$lang reader content');
        final result =
            '$lang: ${decks.length} decks, practice item read, ${stories.length} pack stories + ${bundled.length} bundled stories';
        languageResults.add(result);
        debugPrint('PASS: $result');
      } finally {
        await content.close();
      }
    }
    // Reopen after other languages to exercise WASM file/handle lifetime.
    final reopenedContent = await (await ContentPackInstaller.forApp(
      lang: 'en',
    )).open();
    check(
      (await reopenedContent.decks()).isNotEmpty,
      'English reopen after five languages',
    );
    await reopenedContent.close();
    final owner =
        'browser-storage-test-${DateTime.now().microsecondsSinceEpoch}';
    debugPrint('Opening user database');
    var database = await UserDatabase.openForApp(accountId: owner);
    await database.customStatement(
      'CREATE TABLE browser_probe(value TEXT NOT NULL)',
    );
    await database.customStatement(
      "INSERT INTO browser_probe VALUES('persisted')",
    );
    await database.close();
    database = await UserDatabase.openForApp(accountId: owner);
    check(
      (await database
                  .customSelect('SELECT value FROM browser_probe')
                  .getSingle())
              .read<String>('value') ==
          'persisted',
      'reopen persistence',
    );
    final other = await UserDatabase.openForApp(accountId: '$owner-other');
    check(
      (await other
              .customSelect(
                "SELECT name FROM sqlite_master WHERE name='browser_probe'",
              )
              .get())
          .isEmpty,
      'account isolation',
    );
    await database.customStatement('DROP TABLE browser_probe');
    await database.close();
    await other.close();
    debugPrint('PASS: Browser persistence and account isolation verified');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: SelectableText(
            'PASS: ALL 5 LANGUAGES\n${languageResults.join('\n')}\nEnglish reopened after all languages.\nPASS: persisted user database reopening and separate account storage.',
          ),
        ),
      ),
    );
  } catch (error, stack) {
    debugPrint('$error\n$stack');
    runApp(
      MaterialApp(home: Scaffold(body: SelectableText('FAIL: $error\n$stack'))),
    );
  }
  // Keep semantics active for browser automation to read the verification result.
}
