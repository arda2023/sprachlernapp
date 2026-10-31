import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/widgets/subscription_tile.dart';

void main() {
  test(
    'does not announce restore success before the server confirms premium',
    () {
      const state = PurchaseState(
        lastOutcome: PurchaseResult.restored,
        premiumActive: null,
        errorMessage:
            'Der Store- oder Kontostatus konnte nicht geprüft werden.',
      );

      expect(
        subscriptionRestoreNotice(state),
        'Storekauf gefunden, Kontoabgleich noch offen.',
      );
    },
  );

  test('announces restored only for server-verified active premium', () {
    const state = PurchaseState(
      lastOutcome: PurchaseResult.restored,
      premiumActive: true,
    );

    expect(subscriptionRestoreNotice(state), 'Käufe wurden wiederhergestellt.');
  });

  test('restore failure takes precedence over previously active premium', () {
    const state = PurchaseState(
      phase: PurchasePhase.failed,
      lastOutcome: PurchaseResult.restored,
      premiumActive: true,
      errorMessage: 'Der Store konnte die Anfrage nicht abschließen.',
    );

    expect(
      subscriptionRestoreNotice(state),
      'Der Store konnte die Anfrage nicht abschließen.',
    );
  });

  test('labels server-verified sandbox access as test-only', () {
    const state = PurchaseState(
      lastOutcome: PurchaseResult.restored,
      premiumActive: false,
      sandboxTestActive: true,
    );

    expect(
      subscriptionRestoreNotice(state),
      'Premium-Testabo aktiv (Sandbox).',
    );
  });
}
