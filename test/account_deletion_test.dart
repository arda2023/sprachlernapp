import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/auth/account_deletion_gateway.dart';
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/account_provider.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/account_tile.dart';

class _Gateway implements AccountDeletionGateway {
  final errors = <Object>[];
  int calls = 0;
  AccountDeletionResult result = const AccountDeletionResult(
    appleManualRevocationRequired: false,
  );

  @override
  Future<AccountDeletionResult> deleteAccount({
    required String expectedUserId,
  }) async {
    if (expectedUserId != 'account-1') {
      throw const AccountDeletionException('ACCOUNT_CHANGED', 'Changed.');
    }
    calls++;
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return result;
  }
}

class _Identity {
  String? id = 'account-1';
}

class _Actions implements AccountActions {
  _Actions(this.identity);
  final _Identity identity;
  String? signInAs;
  bool signOutFails = false;
  int signOutCalls = 0;

  @override
  Future<void> signIn(AccountIdentityProvider provider) async {
    if (signInAs != null) identity.id = signInAs;
  }

  @override
  Future<void> sendCode(String email) async {}

  @override
  Future<void> verifyCode(String email, String code) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutFails) throw StateError('secure storage unavailable');
    identity.id = null;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<
    ({
      StreamController<AccountSession?> sessions,
      _Identity identity,
      _Actions actions,
      _Gateway gateway,
    })
  >
  mount(WidgetTester tester, {String? email = 'person@example.test'}) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = StreamController<AccountSession?>();
    final identity = _Identity();
    final actions = _Actions(identity);
    final gateway = _Gateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountSessionProvider.overrideWith((ref) => sessions.stream),
          accountIdentityReaderProvider.overrideWithValue(
            () async => identity.id,
          ),
          accountActionsProvider.overrideWithValue(actions),
          accountDeletionGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: AccountTile()),
        ),
      ),
    );
    sessions.add((id: 'account-1', email: email));
    await tester.pumpAndSettle();
    return (
      sessions: sessions,
      identity: identity,
      actions: actions,
      gateway: gateway,
    );
  }

  Future<void> beginDeletion(WidgetTester tester) async {
    await tester.tap(find.text('Konto dauerhaft löschen'));
    await tester.pumpAndSettle();
  }

  Future<void> typeConfirmation(WidgetTester tester) async {
    await tester.enterText(find.byType(CupertinoTextField), 'LÖSCHEN');
    await tester.pump();
  }

  testWidgets('cancelled typed confirmation never calls the deletion gateway', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    await beginDeletion(tester);
    await typeConfirmation(tester);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(harness.gateway.calls, 0);
  });

  testWidgets('late identity change after confirmation blocks deletion', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    await beginDeletion(tester);
    await typeConfirmation(tester);
    harness.identity.id = 'account-2';
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();

    expect(harness.gateway.calls, 0);
    expect(find.textContaining('Konto hat sich geändert'), findsOneWidget);
  });

  testWidgets('backend failure is reported and does not sign out', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    harness.gateway.errors.add(
      const AccountDeletionException('BACKEND_UNAVAILABLE', 'Serverfehler.'),
    );
    await beginDeletion(tester);
    await typeConfirmation(tester);
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();

    expect(harness.gateway.calls, 1);
    expect(harness.actions.signOutCalls, 0);
    expect(find.text('Serverfehler.'), findsOneWidget);
  });

  testWidgets('successful non-Apple deletion signs out and confirms success', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    await beginDeletion(tester);
    await typeConfirmation(tester);
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();

    expect(harness.gateway.calls, 1);
    expect(harness.actions.signOutCalls, 1);
    expect(find.text('Konto gelöscht'), findsOneWidget);
    expect(find.textContaining('lokaler Lernstand'), findsOneWidget);
  });

  testWidgets('reauthentication in the same account retries deletion', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    harness.gateway.errors.add(
      const AccountDeletionException('RECENT_AUTH_REQUIRED', 'Recent auth.'),
    );
    await beginDeletion(tester);
    await typeConfirmation(tester);
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Erneut anmelden'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mit Google fortfahren'));
    await tester.pumpAndSettle();
    expect(harness.gateway.calls, 2);
    expect(harness.actions.signOutCalls, 1);
    expect(find.text('Konto gelöscht'), findsOneWidget);
  });

  testWidgets('reauthentication as another account never retries deletion', (
    tester,
  ) async {
    final harness = await mount(tester);
    addTearDown(harness.sessions.close);
    harness.gateway.errors.add(
      const AccountDeletionException('RECENT_AUTH_REQUIRED', 'Recent auth.'),
    );
    harness.actions.signInAs = 'account-2';
    await beginDeletion(tester);
    await typeConfirmation(tester);
    await tester.tap(find.text('Konto löschen'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Mit Google fortfahren'));
    await tester.pumpAndSettle();
    expect(harness.gateway.calls, 1);
    expect(harness.actions.signOutCalls, 1);
    expect(find.textContaining('anderes Konto'), findsOneWidget);
  });

  testWidgets(
    'server deletion followed by signout failure is not misreported',
    (tester) async {
      final harness = await mount(tester);
      addTearDown(harness.sessions.close);
      harness.actions.signOutFails = true;
      await beginDeletion(tester);
      await typeConfirmation(tester);
      await tester.tap(find.text('Konto löschen'));
      await tester.pumpAndSettle();

      expect(harness.gateway.calls, 1);
      expect(find.textContaining('bereits gelöscht'), findsOneWidget);
      expect(find.text('Konto konnte nicht gelöscht werden.'), findsNothing);
    },
  );
}
