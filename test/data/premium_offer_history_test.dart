import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/premium_offer_history.dart';
import 'package:sprachapp/data/user/user_database.dart';

void main() {
  final firstDay = DateTime.utc(2026, 11, 15, 8);
  group('Premium offer timing', () {
    late DateTime now;
    late UserDatabase database;
    late PremiumOfferHistory history;

    setUp(() {
      now = firstDay;
      database = UserDatabase(NativeDatabase.memory());
      history = PremiumOfferHistory(database, clock: () => now);
    });
    tearDown(() => database.close());

    test(
      'a new opportunity becomes eligible after exactly seven days',
      () async {
        expect(await history.claim('first_session'), isTrue);

        now = firstDay.add(const Duration(days: 7, milliseconds: -1));
        expect(await history.claim('first_story:linglossa'), isFalse);
        now = firstDay.add(const Duration(days: 7));
        expect(await history.claim('first_story:linglossa'), isTrue);
        now = firstDay.add(const Duration(days: 90));
        expect(await history.claim('first_session'), isFalse);
        expect(await history.claim('first_story:linglossa'), isFalse);
      },
    );

    test(
      'dismissal starts a thirty-day quiet period at the dismissal time',
      () async {
        expect(await history.claim('first_session'), isTrue);
        final dismissedAt = now = firstDay.add(const Duration(days: 2));
        await history.dismiss();
        now = dismissedAt.add(const Duration(days: 30, milliseconds: -1));
        expect(await history.claim('first_story:linglossa'), isFalse);
        now = dismissedAt.add(const Duration(days: 30));
        expect(await history.claim('first_story:linglossa'), isTrue);
      },
    );

    test(
      'simultaneous claims across instances yield only one invitation',
      () async {
        final other = PremiumOfferHistory(database, clock: () => now);
        final claims = await Future.wait([
          history.claim('first_session'),
          other.claim('first_session'),
          other.claim('first_story:linglossa'),
        ]);
        expect(claims.where((claim) => claim), hasLength(1));
      },
    );

    test(
      'clock rollback keeps the quiet period measured from the last offer',
      () async {
        final offeredAt = now = firstDay.add(const Duration(days: 40));
        expect(await history.claim('first_session'), isTrue);
        now = firstDay;
        expect(await history.claim('first_story:linglossa'), isFalse);
        now = offeredAt.add(const Duration(days: 7));
        expect(await history.claim('first_story:linglossa'), isTrue);
      },
    );
  });

  test(
    'history survives reopening and another account has a fresh history',
    () async {
      var now = firstDay;
      final directory = await Directory.systemTemp.createTemp(
        'premium-offer-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstAccount = File('${directory.path}/first.sqlite');
      final secondAccount = File('${directory.path}/second.sqlite');

      Future<bool> claimOn(File file) async {
        final db = UserDatabase(NativeDatabase(file));
        try {
          return await PremiumOfferHistory(
            db,
            clock: () => now,
          ).claim('first_story:linglossa');
        } finally {
          await db.close();
        }
      }

      expect(await claimOn(firstAccount), isTrue);
      now = firstDay.add(const Duration(days: 7));
      expect(await claimOn(firstAccount), isFalse);
      expect(await claimOn(secondAccount), isTrue);
    },
  );
}
