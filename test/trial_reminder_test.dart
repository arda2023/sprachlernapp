import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/trial_reminder.dart';

const product = 'com.ardasayar.linglossa.premium.yearly';
final now = DateTime.utc(2026, 11, 13, 10);
final end = DateTime.utc(2026, 11, 20, 10);

TrialSubscription subscription({
  String? offer = 'free_trial',
  DateTime? expiry,
  bool missingExpiry = false,
  bool renew = true,
  bool? sandbox = false,
  bool consistent = true,
  bool refunded = false,
  bool lifetime = false,
  bool grace = false,
}) => (
  productId: product,
  introductoryOfferType: offer,
  expiresAt: missingExpiry ? null : expiry ?? end,
  willRenew: renew,
  isSandbox: sandbox,
  dataConsistent: consistent,
  isRefunded: refunded,
  isLifetime: lifetime,
  isInGracePeriod: grace,
);

TrialReminderDecision decide(
  TrialSubscription? value, {
  bool active = true,
  String? serverProduct = product,
  DateTime? serverEnd,
  bool? serverRenew = true,
  String? environment = 'Production',
}) => trialReminderDecision(
  now: now,
  subscription: value,
  purchaseActive: active,
  purchaseProductId: serverProduct,
  purchaseExpiresAt: serverEnd ?? value?.expiresAt,
  purchaseWillRenew: serverRenew,
  purchaseEnvironment: environment,
);

void main() {
  test(
    'confirmed current free trial reminds exactly 24 hours before expiry',
    () {
      final result = decide(subscription());
      expect(result.status, TrialReminderStatus.ready);
      expect(result.plan!.remindAt, DateTime.utc(2026, 11, 19, 10));
      expect(result.plan!.expiresAt, end);
    },
  );

  test(
    'product eligibility alone and paid introductory offers do not qualify',
    () {
      expect(decide(null).status, TrialReminderStatus.inactive);
      for (final offer in [null, 'pay_as_you_go', 'pay_up_front']) {
        expect(
          decide(subscription(offer: offer)).status,
          TrialReminderStatus.inactive,
        );
      }
    },
  );

  test(
    'cancellation, conversion, refund, lifetime, grace and expiry cancel',
    () {
      for (final value in [
        subscription(renew: false),
        subscription(offer: null),
        subscription(refunded: true),
        subscription(lifetime: true),
        subscription(grace: true),
        subscription(expiry: now),
      ]) {
        expect(decide(value).status, TrialReminderStatus.inactive);
      }
      expect(
        decide(subscription(), serverRenew: false).status,
        TrialReminderStatus.inactive,
      );
    },
  );

  test(
    'missing or conflicting trial facts remain unavailable without guessing',
    () {
      for (final value in [
        subscription(missingExpiry: true),
        subscription(sandbox: null),
        subscription(consistent: false),
      ]) {
        expect(decide(value).status, TrialReminderStatus.unavailable);
      }
      for (final result in [
        decide(subscription(), active: false),
        decide(subscription(), serverProduct: 'another-product'),
        decide(subscription(), serverEnd: end.add(const Duration(seconds: 1))),
        decide(subscription(), serverRenew: null),
        decide(subscription(), environment: 'Sandbox'),
      ]) {
        expect(result.status, TrialReminderStatus.unavailable);
        expect(result.plan, isNull);
      }
    },
  );

  test(
    'sandbox uses actual compressed expiry and only a future 30-second lead',
    () {
      final result = decide(
        subscription(
          sandbox: true,
          expiry: now.add(const Duration(minutes: 3)),
        ),
        environment: 'Sandbox',
      );
      expect(
        result.plan!.remindAt,
        now.add(const Duration(minutes: 2, seconds: 30)),
      );
      expect(result.plan!.isSandbox, true);
      final tooLate = decide(
        subscription(
          sandbox: true,
          expiry: now.add(const Duration(seconds: 30)),
        ),
        environment: 'Sandbox',
      );
      expect(tooLate.status, TrialReminderStatus.tooLate);
      expect(tooLate.plan, isNull);
    },
  );

  test(
    'a missed production lead time never becomes an immediate notification',
    () {
      final result = decide(
        subscription(expiry: now.add(const Duration(hours: 23))),
      );
      expect(result.status, TrialReminderStatus.tooLate);
      expect(result.plan, isNull);
    },
  );
}
