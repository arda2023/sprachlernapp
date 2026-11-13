import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/billing/adapty_billing_gateway.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/billing_provider.dart';

class _Gateway implements BillingGateway {
  final activation = Completer<void>();
  final updates = StreamController<BillingProfileSnapshot>.broadcast(
    sync: true,
  );
  final profileReplies = <Completer<BillingProfileSnapshot>>[
    Completer<BillingProfileSnapshot>(),
  ];
  final identityBindings = <String?>[];
  final identityFailures = <String>{};
  var profileReads = 0;

  @override
  Future<void> activate() => activation.future;

  @override
  Future<void> bindCustomerUserId(String? customerUserId) async {
    identityBindings.add(customerUserId);
    if (customerUserId != null && identityFailures.contains(customerUserId)) {
      throw StateError('identity switch failed');
    }
  }

  @override
  Future<BillingProfileSnapshot> readProfile() {
    final index = profileReads++;
    while (profileReplies.length <= index) {
      profileReplies.add(Completer<BillingProfileSnapshot>());
    }
    return profileReplies[index].future;
  }

  @override
  Stream<BillingProfileSnapshot> get profileUpdates => updates.stream;
}

Future<void> _flush() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

ProviderContainer _container(
  _Gateway gateway, {
  Stream<AccountSession?>? sessions,
}) {
  final container = ProviderContainer(
    overrides: [
      billingGatewayProvider.overrideWithValue(gateway),
      accountSessionProvider.overrideWith(
        (ref) => sessions ?? Stream<AccountSession?>.value(null),
      ),
    ],
  );
  container.listen(billingProvider, (previous, next) {});
  return container;
}

BillingProfileSnapshot _profile(String? id, bool premium) => (
  customerUserId: id,
  premiumActive: premium,
  activeProductId: null,
  expiresAt: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unconfigured installs do not initialize billing', () {
    final container = ProviderContainer(
      overrides: [billingGatewayProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    final state = container.read(billingProvider);
    expect(state.phase, BillingPhase.disabled);
    expect(state.premiumActive, isNull);
  });

  test(
    'waits for activation, then applies the identified profile updates',
    () async {
      final gateway = _Gateway();
      final container = _container(gateway);
      addTearDown(() async {
        container.dispose();
        await gateway.updates.close();
      });
      expect(container.read(billingProvider).phase, BillingPhase.connecting);
      await _flush();
      expect(gateway.profileReads, 0);
      gateway.activation.complete();
      await _flush();
      expect(gateway.identityBindings, [null]);
      expect(gateway.profileReads, 1);
      gateway.profileReplies[0].complete(_profile(null, false));
      await _flush();
      expect(container.read(billingProvider).premiumActive, false);
      gateway.updates.add(_profile(null, true));
      expect(container.read(billingProvider).premiumActive, true);
      gateway.updates.add(_profile(null, false));
      expect(container.read(billingProvider).premiumActive, false);
    },
  );

  test('activation failure means unknown, never a free entitlement', () async {
    final gateway = _Gateway();
    final container = _container(gateway);
    addTearDown(() async {
      container.dispose();
      await gateway.updates.close();
    });
    container.read(billingProvider);
    await _flush();
    gateway.activation.completeError(StateError('offline'));
    await _flush();
    expect(container.read(billingProvider).phase, BillingPhase.unknown);
    expect(container.read(billingProvider).premiumActive, isNull);
    expect(gateway.profileReads, 0);
  });

  for (final fail in [false, true]) {
    test(
      'newer entitlement survives a stale ${fail ? 'failed' : 'free'} read',
      () async {
        final gateway = _Gateway();
        final container = _container(gateway);
        addTearDown(() async {
          container.dispose();
          await gateway.updates.close();
        });
        container.read(billingProvider);
        gateway.activation.complete();
        await _flush();
        gateway.updates.add(_profile(null, true));
        if (fail) {
          gateway.profileReplies[0].completeError(StateError('offline'));
        } else {
          gateway.profileReplies[0].complete(_profile(null, false));
        }
        await _flush();
        expect(container.read(billingProvider).phase, BillingPhase.ready);
        expect(container.read(billingProvider).premiumActive, true);
      },
    );
  }

  test(
    'account A profile and stream events cannot leak into account B',
    () async {
      final sessions = StreamController<AccountSession?>.broadcast(sync: true);
      final gateway = _Gateway();
      final container = _container(gateway, sessions: sessions.stream);
      addTearDown(() async {
        container.dispose();
        await sessions.close();
        await gateway.updates.close();
      });
      container.read(billingProvider);
      await _flush();
      sessions.add((id: 'account-a', email: 'a@example.test'));
      gateway.activation.complete();
      await _flush();
      expect(gateway.identityBindings, ['account-a']);
      expect(gateway.profileReads, 1);

      sessions.add((id: 'account-b', email: 'b@example.test'));
      expect(container.read(billingProvider).premiumActive, isNull);
      await _flush();
      expect(gateway.identityBindings, ['account-a', 'account-b']);
      expect(gateway.profileReads, 2);

      gateway.profileReplies[0].complete(_profile('account-a', true));
      gateway.updates.add(_profile('account-a', true));
      await _flush();
      expect(container.read(billingProvider).premiumActive, isNull);

      gateway.profileReplies[1].complete(_profile('account-b', false));
      await _flush();
      expect(container.read(billingProvider).phase, BillingPhase.ready);
      expect(container.read(billingProvider).premiumActive, false);
      gateway.updates.add(_profile('account-a', true));
      expect(container.read(billingProvider).premiumActive, false);
      gateway.updates.add(_profile('account-b', true));
      expect(container.read(billingProvider).premiumActive, true);
    },
  );

  test(
    'logout clears access until Adapty confirms the anonymous profile',
    () async {
      final sessions = StreamController<AccountSession?>.broadcast(sync: true);
      final gateway = _Gateway();
      final container = _container(gateway, sessions: sessions.stream);
      addTearDown(() async {
        container.dispose();
        await sessions.close();
        await gateway.updates.close();
      });
      container.read(billingProvider);
      await _flush();
      sessions.add((id: 'account-a', email: null));
      gateway.activation.complete();
      await _flush();
      gateway.profileReplies[0].complete(_profile('account-a', true));
      await _flush();
      expect(container.read(billingProvider).premiumActive, true);

      sessions.add(null);
      expect(container.read(billingProvider).premiumActive, isNull);
      await _flush();
      expect(gateway.identityBindings, ['account-a', null]);
      expect(gateway.profileReads, 2);
      gateway.profileReplies[1].complete(_profile(null, false));
      await _flush();
      expect(container.read(billingProvider).premiumActive, false);
    },
  );

  test(
    'failed identity switch stays unknown and a later account can recover',
    () async {
      final sessions = StreamController<AccountSession?>.broadcast(sync: true);
      final gateway = _Gateway()..identityFailures.add('account-a');
      final container = _container(gateway, sessions: sessions.stream);
      addTearDown(() async {
        container.dispose();
        await sessions.close();
        await gateway.updates.close();
      });
      container.read(billingProvider);
      await _flush();
      sessions.add((id: 'account-a', email: null));
      gateway.activation.complete();
      await _flush();
      expect(container.read(billingProvider).phase, BillingPhase.unknown);
      expect(container.read(billingProvider).premiumActive, isNull);
      expect(gateway.profileReads, 0);

      sessions.add((id: 'account-b', email: null));
      await _flush();
      expect(gateway.identityBindings, ['account-a', 'account-b']);
      expect(gateway.profileReads, 1);
      gateway.profileReplies[0].complete(_profile('account-b', true));
      await _flush();
      expect(container.read(billingProvider).premiumActive, true);
    },
  );

  test('disposing during activation prevents later profile calls', () async {
    final gateway = _Gateway();
    final container = _container(gateway);
    container.read(billingProvider);
    await _flush();
    container.dispose();
    gateway.activation.complete();
    await _flush();
    expect(gateway.profileReads, 0);
    expect(gateway.updates.hasListener, false);
    await gateway.updates.close();
  });

  test(
    'failed initial profile can recover through the profile stream',
    () async {
      final gateway = _Gateway();
      final container = _container(gateway);
      addTearDown(() async {
        container.dispose();
        await gateway.updates.close();
      });
      container.read(billingProvider);
      gateway.activation.complete();
      await _flush();
      gateway.profileReplies[0].completeError(StateError('offline'));
      await _flush();
      expect(container.read(billingProvider).phase, BillingPhase.unknown);
      gateway.updates.add(_profile(null, true));
      expect(container.read(billingProvider).premiumActive, true);
    },
  );

  test('Adapty adapter resolves restored identity and serializes failed binds', () async {
    const channel = MethodChannel('flutter.adapty.com/adapty');
    final calls = <String>[];
    var nativeUserId = 'restored-account';
    var failNextIdentify = false;
    final profileReadGate = Completer<void>();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'is_activated':
          return '{"success":false}';
        case 'activate':
          return '{"success":null}';
        case 'get_profile':
          await profileReadGate.future;
          return '{"success":{"profile_id":"profile","segment_hash":"segment","customer_user_id":"$nativeUserId","timestamp":0,"is_test_user":false}}';
        case 'identify':
          final args =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          nativeUserId = args['customer_user_id'] as String;
          if (failNextIdentify) {
            failNextIdentify = false;
            throw PlatformException(code: 'identify_failed');
          }
          return '{"success":null}';
        case 'logout':
          nativeUserId = 'anonymous-after-logout';
          return '{"success":null}';
        default:
          return '{"success":null}';
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final gateway = AdaptyBillingGateway('public_test_key');
    await gateway.activate();

    final bindRestored = gateway.bindCustomerUserId('restored-account');
    final bindNext = gateway.bindCustomerUserId('account-b');
    await Future<void>.delayed(Duration.zero);
    expect(calls.where((method) => method == 'get_profile').length, 1);
    expect(calls.where((method) => method == 'identify'), isEmpty);
    failNextIdentify = true;
    profileReadGate.complete();
    await bindRestored;
    await expectLater(bindNext, throwsA(anything));

    // The failed native call partially switched to account-b. A later request
    // must reread Adapty and actively restore the requested identity.
    await gateway.bindCustomerUserId('restored-account');
    expect(calls.where((method) => method == 'get_profile').length, 2);
    expect(calls.where((method) => method == 'identify').length, 2);
    expect(nativeUserId, 'restored-account');

    final purchaseGate = Completer<void>();
    final purchase = gateway.runForCustomerUserId('restored-account', () async {
      await purchaseGate.future;
      return 'completed';
    });
    final switchAccount = gateway.bindCustomerUserId('account-c');
    await Future<void>.delayed(Duration.zero);
    expect(nativeUserId, 'restored-account');
    purchaseGate.complete();
    expect(await purchase, 'completed');
    await switchAccount;
    expect(nativeUserId, 'account-c');

    final queueBlocker = Completer<void>();
    final blocker = gateway.runForCustomerUserId('account-c', () async {
      await queueBlocker.future;
    });
    var staleQueuedOperationStarted = false;
    final staleQueuedOperation = gateway.runForCustomerUserId(
      'account-c',
      () async {
        staleQueuedOperationStarted = true;
      },
      isCurrent: () => false,
    );
    await Future<void>.delayed(Duration.zero);
    queueBlocker.complete();
    await blocker;
    await expectLater(staleQueuedOperation, throwsA(isA<StateError>()));
    expect(staleQueuedOperationStarted, isFalse);

    var wrongAccountOperationStarted = false;
    await expectLater(
      gateway.runForCustomerUserId('account-b', () async {
        wrongAccountOperationStarted = true;
      }),
      throwsA(isA<StateError>()),
    );
    expect(wrongAccountOperationStarted, isFalse);
    expect(nativeUserId, 'account-c');
  });
}
