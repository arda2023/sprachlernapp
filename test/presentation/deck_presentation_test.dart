import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/deck_visuals.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';

/// Deck names and bolts as the decks screens show them, checked against the
/// installed packs of every language (user decision 29.10.2026).
void main() {
  for (final lang in ['en', 'pt-BR', 'nb', 'it', 'es']) {
    test('$lang: short names without "&", bolts spread over three levels', () {
      final db = sqlite3.open(
        'assets/content/$lang/content.sqlite',
        mode: OpenMode.readOnly,
      );
      addTearDown(db.close);
      final rows = db.select(
        'SELECT slug, title_de, cefr_band FROM decks WHERE removed_in IS NULL',
      );
      expect(rows, isNotEmpty);
      final names = <String>{};
      final levels = <DeckDifficulty>{};
      final icons = <Object>{};
      for (final row in rows) {
        final name = deckDisplayName(
          row['slug'] as String,
          row['title_de'] as String,
        );
        expect(name, isNot(contains('&')), reason: row['slug'] as String);
        expect(names.add(name), isTrue, reason: 'duplicate name $name');
        expect(
          icons.add(deckTopicIcon(row['slug'] as String)),
          isTrue,
          reason: 'duplicate topic icon for ${row['slug']}',
        );
        levels.add(
          deckDifficulty(row['slug'] as String, row['cefr_band'] as String?),
        );
      }
      expect(levels, DeckDifficulty.values.toSet());
    });
  }

  test('unknown decks keep their pack title and band', () {
    expect(deckDisplayName('neu', 'Neuer Stapel'), 'Neuer Stapel');
    expect(deckDifficulty('neu', 'fortgeschritten'), DeckDifficulty.advanced);
    expect(deckDifficulty('neu', null), DeckDifficulty.beginner);
  });
}
