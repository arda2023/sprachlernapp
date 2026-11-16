import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/adapty_billing_gateway.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';

class _IdentityRunner implements BillingIdentityRunner {
  _IdentityRunner(this.customerUserId);

  final String? customerUserId;

  @override
  Future<T> runForCustomerUserId<T>(
    String? expected,
    Future<T> Function() operation, {
    bool Function()? isCurrent,
  }) async {
    if (customerUserId != expected || (isCurrent != null && !isCurrent())) {
      throw StateError('Identity mismatch.');
    }
    return operation();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.adapty.com/adapty');
  const customerUserId = 'authenticated-account';
  const monthlyId = AdaptyPurchaseGateway.monthlyProductId;
  const yearlyId = AdaptyPurchaseGateway.yearlyProductId;

  Map<String, Object?> profile({
    bool premium = false,
    String profileUserId = customerUserId,
  }) => {
    'profile_id': 'profile',
    'segment_hash': 'segment',
    'customer_user_id': profileUserId,
    'timestamp': 0,
    'is_test_user': false,
    'paid_access_levels': premium
        ? {
            'premium': {
              'id': 'premium',
              'is_active': true,
              'vendor_product_id': yearlyId,
              'store': 'app_store',
              'activated_at': '2026-10-31T12:00:00Z',
              'is_lifetime': false,
              'will_renew': true,
              'is_in_grace_period': false,
              'is_refund': false,
            },
          }
        : <String, Object?>{},
  };

  Map<String, Object?> product(String id) => {
    'vendor_product_id': id,
    'adapty_product_id': 'adapty-$id',
    'access_level_id': 'premium',
    'product_type': 'subscription',
    'localized_description': 'Premium subscription',
    'localized_title': id == yearlyId ? 'Yearly' : 'Monthly',
    'paywall_variation_id': 'variation',
    'paywall_ab_test_name': 'test',
    'paywall_name': 'premium',
    'price': {
      'amount': id == yearlyId ? 49.99 : 9.99,
      'currency_code': 'EUR',
      'currency_symbol': '€',
      'localized_string': id == yearlyId ? '49,99 €' : '9,99 €',
    },
    'paywall_product_index': id == yearlyId ? 1 : 0,
  };

  Map<String, Object?> flow() => {
    'placement': {
      'developer_id': 'premium',
      'audience_name': 'Everyone',
      'revision': 1,
      'ab_test_name': 'test',
      'placement_audience_version_id': 'audience',
    },
    'flow_id': 'flow',
    'flow_name': 'Premium flow',
    'variation_id': 'variation',
    'variations': <Object?>[],
    'response_created_at': 0,
  };

  Future<void> withSdk(
    Future<void> Function(List<MethodCall> calls) run, {
    required List<Map<String, Object?>> products,
    String purchaseResult = '{"type":"user_cancelled"}',
    bool restorePremium = false,
    String restoreCustomerUserId = customerUserId,
  }) async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'get_flow':
          return jsonEncode({'success': flow()});
        case 'get_paywall_products':
          return jsonEncode({'success': products});
        case 'make_purchase':
          return jsonEncode({'success': jsonDecode(purchaseResult)});
        case 'restore_purchases':
          return jsonEncode({
            'success': profile(
              premium: restorePremium,
              profileUserId: restoreCustomerUserId,
            ),
          });
        default:
          throw StateError('Unexpected Adapty method ${call.method}.');
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await run(calls);
  }

  test(
    'fetches the premium flow, filters configured plans and localizes prices',
    () async {
      await withSdk((calls) async {
        final gateway = AdaptyPurchaseGateway(_IdentityRunner(customerUserId));
        final catalog = await gateway.loadCatalog(
          customerUserId: customerUserId,
        );

        expect(catalog.map((item) => item.productId), [monthlyId, yearlyId]);
        expect(catalog.first.localizedPrice, '9,99 €');
        expect(catalog.last.localizedPrice, '49,99 €');
        expect(catalog.last.isRecommended, isTrue);
        expect(calls.map((call) => call.method), [
          'get_flow',
          'get_paywall_products',
        ]);
        expect(
          jsonDecode(calls.first.arguments as String)['placement_id'],
          'premium',
        );
      }, products: [product(yearlyId), product(monthlyId), product('other')]);
    },
  );

  for (final (offerType, paymentMode, amount) in [
    ('introductory', 'free_trial', 0.0),
    ('promotional', 'pay_up_front', 2.99),
  ]) {
    test(
      'blocks $offerType offers in the catalog and purchase cache',
      () async {
        final monthly = {
          ...product(monthlyId),
          'subscription': {
            'period': {'unit': 'month', 'number_of_units': 1},
            'localized_period': 'Monat',
          },
        };
        final yearly = {
          ...product(yearlyId),
          'subscription': {
            'period': {'unit': 'year', 'number_of_units': 1},
            'localized_period': 'Jahr',
          },
        };
        final products = [monthly, yearly];
        await withSdk((calls) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          final initial = await gateway.loadCatalog(
            customerUserId: customerUserId,
          );
          expect(initial.map((item) => item.productId), [monthlyId, yearlyId]);

          products[0] = {
            ...monthly,
            'subscription': {
              ...monthly['subscription'] as Map<String, Object?>,
              'offer': {
                'offer_identifier': {
                  'type': offerType,
                  if (offerType == 'promotional') 'id': 'summer-offer',
                },
                'phases': [
                  {
                    'price': {'amount': amount, 'currency_code': 'EUR'},
                    'number_of_periods': 1,
                    'payment_mode': paymentMode,
                    'subscription_period': {
                      'unit': 'week',
                      'number_of_units': 1,
                    },
                  },
                ],
              },
            },
          };

          final paidCatalog = await gateway.loadCatalog(
            customerUserId: customerUserId,
          );
          expect(paidCatalog.single.productId, yearlyId);
          expect(paidCatalog.single.localizedPeriod, 'Jahr');
          await expectLater(
            gateway.purchase(
              customerUserId: customerUserId,
              productId: monthlyId,
            ),
            throwsStateError,
          );
          expect(
            calls.where((call) => call.method == 'make_purchase'),
            isEmpty,
          );

          expect(
            await gateway.purchase(
              customerUserId: customerUserId,
              productId: yearlyId,
            ),
            PurchaseOutcome.cancelled,
          );
          final request = calls
              .where((call) => call.method == 'make_purchase')
              .single;
          final args = jsonDecode(request.arguments as String);
          expect(args['product']['vendor_product_id'], yearlyId);
        }, products: products);
      },
    );
  }

  test(
    'uses Adapty make_purchase result types and validates returned identity',
    () async {
      await withSdk(
        (calls) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          await gateway.loadCatalog(customerUserId: customerUserId);
          expect(
            await gateway.purchase(
              customerUserId: customerUserId,
              productId: yearlyId,
            ),
            PurchaseOutcome.cancelled,
          );
          expect(calls.last.method, 'make_purchase');
          final args = jsonDecode(calls.last.arguments as String);
          expect(args['product']['vendor_product_id'], yearlyId);
        },
        products: [product(yearlyId)],
        purchaseResult: '{"type":"user_cancelled"}',
      );

      await withSdk(
        (_) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          await gateway.loadCatalog(customerUserId: customerUserId);
          expect(
            await gateway.purchase(
              customerUserId: customerUserId,
              productId: yearlyId,
            ),
            PurchaseOutcome.pending,
          );
        },
        products: [product(yearlyId)],
        purchaseResult: '{"type":"pending"}',
      );

      await withSdk(
        (_) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          await gateway.loadCatalog(customerUserId: customerUserId);
          expect(
            await gateway.purchase(
              customerUserId: customerUserId,
              productId: yearlyId,
            ),
            PurchaseOutcome.success,
          );
        },
        products: [product(yearlyId)],
        purchaseResult: jsonEncode({
          'type': 'success',
          'profile': profile(premium: true),
        }),
      );

      await withSdk(
        (_) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          await gateway.loadCatalog(customerUserId: customerUserId);
          await expectLater(
            gateway.purchase(
              customerUserId: customerUserId,
              productId: yearlyId,
            ),
            throwsA(isA<StateError>()),
          );
        },
        products: [product(yearlyId)],
        purchaseResult: jsonEncode({
          'type': 'success',
          'profile': profile(premium: true, profileUserId: 'another-account'),
        }),
      );
    },
  );

  test(
    'restores from Adapty profile and validates the profile identity',
    () async {
      await withSdk(
        (calls) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          expect(
            await gateway.restore(customerUserId: customerUserId),
            RestoreOutcome.restored,
          );
          expect(calls.single.method, 'restore_purchases');
        },
        products: const [],
        restorePremium: true,
      );

      await withSdk(
        (_) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          expect(
            await gateway.restore(customerUserId: customerUserId),
            RestoreOutcome.noPurchases,
          );
        },
        products: const [],
        restorePremium: false,
      );

      await withSdk(
        (_) async {
          final gateway = AdaptyPurchaseGateway(
            _IdentityRunner(customerUserId),
          );
          await expectLater(
            gateway.restore(customerUserId: customerUserId),
            throwsA(isA<StateError>()),
          );
        },
        products: const [],
        restoreCustomerUserId: 'another-account',
      );
    },
  );
}
