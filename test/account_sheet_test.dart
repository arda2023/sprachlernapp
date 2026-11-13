import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold, TextButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:sprachapp/presentation/providers/auth_providers.dart';
import 'package:sprachapp/presentation/providers/account_provider.dart';
import 'package:sprachapp/screens/onboarding/widgets/account_sheet.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/account_tile.dart';

class _Actions implements AccountActions {
  Completer<void>? pending;
  Object? failure;
  int logins = 0;
  final sent = <String>[];
  final verified = <(String, String)>[];
  @override
  Future<void> signIn(AccountIdentityProvider provider) async {
    logins++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> sendCode(String email) async {
    sent.add(email);
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    verified.add((email, code));
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> open(
    WidgetTester tester,
    _Actions actions,
    void Function(AccountProvider?) result,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountActionsProvider.overrideWithValue(actions)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result(
                    await AccountSheet.show(context, AccountReason.signIn),
                  );
                },
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a provider tap waits for confirmation and prevents double login',
    (tester) async {
      final actions = _Actions()..pending = Completer<void>();
      AccountProvider? result;
      await open(tester, actions, (value) => result = value);
      await tester.tap(find.bySemanticsLabel('Mit Apple fortfahren'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Mit Google fortfahren'));
      await tester.pump();
      expect(result, isNull);
      expect(actions.logins, 1);
      expect(find.byType(AccountSheet), findsOneWidget);
      actions.pending!.complete();
      await tester.pumpAndSettle();
      expect(result, AccountProvider.apple);
      expect(find.byType(AccountSheet), findsNothing);
    },
  );

  testWidgets('the sheet cannot be dismissed while sign-in is pending', (
    tester,
  ) async {
    final actions = _Actions()..pending = Completer<void>();
    AccountProvider? result;
    await open(tester, actions, (value) => result = value);
    await tester.tap(find.bySemanticsLabel('Mit Apple fortfahren'));
    await tester.pump();

    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AccountSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AccountSheet), findsOneWidget);
    expect(result, isNull);

    actions.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AccountSheet), findsNothing);
    expect(result, AccountProvider.apple);
  });

  testWidgets('native cancellation keeps the sheet open without an error', (
    tester,
  ) async {
    final actions = _Actions()..failure = const AccountLoginCancelled();
    AccountProvider? result;
    await open(tester, actions, (value) => result = value);
    await tester.tap(find.bySemanticsLabel('Mit Apple fortfahren'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(AccountSheet), findsOneWidget);
    expect(find.textContaining('nicht geklappt'), findsNothing);
  });

  testWidgets('provider failure does not report success or leak raw errors', (
    tester,
  ) async {
    final actions = _Actions()..failure = Exception('sensitive-native-error');
    AccountProvider? result;
    await open(tester, actions, (value) => result = value);
    await tester.tap(find.bySemanticsLabel('Mit Google fortfahren'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.textContaining('Prüfe deine Verbindung'), findsOneWidget);
    expect(find.textContaining('sensitive-native-error'), findsNothing);
  });

  testWidgets('account tile distinguishes loading, signed-out, and signed-in', (
    tester,
  ) async {
    final sessions = StreamController<AccountSession?>();
    addTearDown(sessions.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountSessionProvider.overrideWith((ref) => sessions.stream),
          accountActionsProvider.overrideWithValue(_Actions()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: AccountTile()),
        ),
      ),
    );
    expect(find.text('Kontostatus wird geladen …'), findsOneWidget);
    expect(find.text('Ohne Konto'), findsNothing);

    sessions.add(null);
    await tester.pump();
    expect(find.text('Ohne Konto'), findsOneWidget);

    sessions.add((id: 'account-1', email: 'person@example.test'));
    await tester.pump();
    expect(find.text('Angemeldet'), findsOneWidget);
    expect(find.text('person@example.test'), findsOneWidget);
  });

  testWidgets(
    'email is validated, wrong codes stay open, confirmed codes succeed',
    (tester) async {
      final actions = _Actions();
      AccountProvider? result;
      await open(tester, actions, (value) => result = value);
      await tester.tap(find.bySemanticsLabel('Mit E-Mail fortfahren'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Code senden'));
      await tester.pumpAndSettle();
      expect(actions.sent, isEmpty);
      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'person@example.test',
      );
      await tester.tap(find.bySemanticsLabel('Code senden'));
      await tester.pumpAndSettle();
      expect(actions.sent, ['person@example.test']);
      expect(result, isNull);
      await tester.enterText(find.byType(CupertinoTextField).last, '123456');
      actions.failure = const AuthException('invalid', code: 'otp_expired');
      await tester.tap(find.bySemanticsLabel('Code bestätigen'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.textContaining('ungültig oder abgelaufen'), findsOneWidget);
      actions.failure = null;
      await tester.tap(find.bySemanticsLabel('Code bestätigen'));
      await tester.pumpAndSettle();
      expect(result, AccountProvider.email);
      expect(actions.verified.last, ('person@example.test', '123456'));
    },
  );
}
