import '../user/user_database.dart';

/// Local presentation history in the account's database. Never an entitlement.
class PremiumOfferHistory {
  PremiumOfferHistory(this.database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UserDatabase database;
  final DateTime Function() _clock;

  Future<void> _prepare() => database.customStatement('''
    CREATE TABLE IF NOT EXISTS premium_offer_history (
      opportunity TEXT PRIMARY KEY,
      occurred_at INTEGER NOT NULL,
      dismissed INTEGER NOT NULL DEFAULT 0
    )
  ''');

  Future<bool> claim(String opportunity) async {
    await _prepare();
    return database.transaction(() async {
      final now = _clock();
      final previous = await database
          .customSelect(
            'SELECT opportunity, occurred_at, dismissed FROM premium_offer_history',
          )
          .get();
      for (final row in previous) {
        if (row.read<String>('opportunity') == opportunity) return false;
        final at = DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('occurred_at'),
        );
        final quiet = Duration(days: row.read<int>('dismissed') == 1 ? 30 : 7);
        if (now.difference(at) < quiet) return false;
      }
      await database.customStatement(
        'INSERT INTO premium_offer_history(opportunity, occurred_at) VALUES(?, ?)',
        [opportunity, now.millisecondsSinceEpoch],
      );
      return true;
    });
  }

  Future<void> dismiss() async {
    await _prepare();
    await database.customStatement(
      'INSERT INTO premium_offer_history(opportunity, occurred_at, dismissed) '
      'VALUES(?, ?, 1) ON CONFLICT(opportunity) DO UPDATE SET '
      'occurred_at=excluded.occurred_at, dismissed=1',
      ['dismissed', _clock().millisecondsSinceEpoch],
    );
  }
}
