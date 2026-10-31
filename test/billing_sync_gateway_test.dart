import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/billing_sync_gateway.dart';

Map<String, Object?> _response({
  String environment = 'Production',
  bool active = true,
  String? productId = 'com.ardasayar.linglossa.premium.yearly',
  String? expiresAt = '2099-01-01T00:00:00Z',
}) => {
  'entitlement': 'premium',
  'is_active': active,
  'product_id': productId,
  'starts_at': '2026-10-01T00:00:00Z',
  'expires_at': expiresAt,
  'will_renew': true,
  'environment': environment,
  'synced_at': '2026-10-31T12:00:00Z',
  'purchase_allowed': true,
  'purchase_environment': environment,
};

void main() {
  test('parses production entitlement and server purchase policy', () {
    final snapshot = ServerBillingSnapshot.fromJson(
      _response(),
      now: DateTime.parse('2026-10-31T12:00:00Z'),
    );
    expect(snapshot.premiumActive, isTrue);
    expect(snapshot.environment, 'Production');
    expect(snapshot.productId, 'com.ardasayar.linglossa.premium.yearly');
    expect(snapshot.expiresAt, DateTime.parse('2099-01-01T00:00:00Z'));
    expect(snapshot.purchaseAllowed, isTrue);
  });

  test('expired and sandbox entitlements never become production premium', () {
    expect(
      ServerBillingSnapshot.fromJson(
        _response(expiresAt: '2000-01-01T00:00:00Z'),
        now: DateTime.parse('2026-10-31T12:00:00Z'),
      ).premiumActive,
      isFalse,
    );
    final sandbox = ServerBillingSnapshot.fromJson(
      _response(environment: 'Sandbox'),
      now: DateTime.parse('2026-10-31T12:00:00Z'),
    );
    expect(sandbox.premiumActive, isFalse);
    expect(sandbox.sandboxActive, isTrue);
  });

  test(
    'rejects unknown environments, products, and active products missing an ID',
    () {
      for (final response in [
        _response(environment: 'Development'),
        _response(productId: 'unconfigured.product'),
        _response(productId: null),
      ]) {
        expect(
          () => ServerBillingSnapshot.fromJson(response),
          throwsFormatException,
        );
      }
    },
  );
}
