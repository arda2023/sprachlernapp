import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/billing/billing_sync_gateway.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/subscription_tile.dart';

class _FixedPurchaseController extends PurchaseController {
  _FixedPurchaseController(this.fixed);

  final PurchaseState fixed;

  @override
  PurchaseState build() => fixed;

  @override
  Future<void> load() async {}
}

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

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const storeError = 'Premium-Käufe sind auf diesem Gerät nicht verfügbar.';

  Widget tile(PurchaseState state) => ProviderScope(
    overrides: [
      purchaseProvider.overrideWith(() => _FixedPurchaseController(state)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(brightness: Brightness.light),
      home: const Scaffold(body: SubscriptionTile()),
    ),
  );

  testWidgets('an active gift hides the missing-store error', (tester) async {
    await tester.pumpWidget(
      tile(
        PurchaseState(
          phase: PurchasePhase.failed,
          hasVerifiedAccount: true,
          premiumActive: true,
          activeProductId: ServerBillingSnapshot.complimentaryProductId,
          startsAt: DateTime.utc(2026, 11),
          expiresAt: DateTime.utc(2026, 12, 1, 14),
          willRenew: false,
          errorMessage: storeError,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Kostenlos freigeschaltet bis'), findsOneWidget);
    expect(find.text(storeError), findsNothing);
  });

  testWidgets('a failed account check is shown instead of the store error', (
    tester,
  ) async {
    const error = 'Dein Premium-Zugang konnte gerade nicht geprüft werden.';
    await tester.pumpWidget(
      tile(
        const PurchaseState(
          phase: PurchasePhase.failed,
          hasVerifiedAccount: true,
          errorMessage: storeError,
          accountSyncError: error,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Premium-Status nicht geprüft'), findsOneWidget);
    expect(find.text(error), findsOneWidget);
    expect(find.text(storeError), findsNothing);
  });
}
