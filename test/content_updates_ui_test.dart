import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:sprachapp/presentation/providers/content_update_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/screens/settings/content_updates_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  passwordUiTests();
  testWidgets(
    'update login and offline state remain usable at 320 pixels and double text size',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            contentInfoProvider.overrideWith(
              (ref) async => const ContentInfo(
                lang: 'en',
                version: 'synthetic-v1',
                schemaVersion: 5,
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const ContentUpdatesScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Englisch · synthetic-v1'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Nach Updates suchen'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Nach Updates suchen'),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Nach Updates suchen'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Privater Inhaltsserver noch nicht eingerichtet.'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expect(
        find.text('Privater Inhaltsserver noch nicht eingerichtet.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
}

class PasswordTestAuth extends ContentAuthRepository {
  PasswordTestAuth({this.errorCode}) : super('', '');
  final String? errorCode;
  bool authenticated = false;
  int logins = 0, codeRequests = 0;
  @override
  bool get signedIn => authenticated;
  @override
  Future<void> signInWithPassword(String email, String password) async {
    logins++;
    if (errorCode != null) {
      throw AuthException('synthetic-private-remote-message', code: errorCode);
    }
    authenticated = true;
  }

  @override
  Future<void> requestCode(String email) async {
    codeRequests++;
  }

  @override
  Future<void> signOut() async {
    authenticated = false;
  }
}

void passwordUiTests() {
  Future<void> show(WidgetTester t, PasswordTestAuth auth) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          contentAuthProvider.overrideWithValue(auth),
          contentInfoProvider.overrideWith(
            (ref) async => const ContentInfo(
              lang: 'en',
              version: 'synthetic',
              schemaVersion: 5,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ContentUpdatesScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'password is masked, cleared after success and absent after logout; OTP is explicit',
    (t) async {
      final auth = PasswordTestAuth();
      await show(t, auth);
      final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields.last.obscureText, isTrue);
      expect(fields.last.autofillHints, contains(AutofillHints.password));
      expect(find.text('Anmeldecode senden'), findsNothing);
      final passwordController = fields.last.controller!;
      await t.enterText(find.byType(TextField).first, 'existing@example.test');
      await t.enterText(find.byType(TextField).last, 'synthetic-password');
      await t.ensureVisible(find.text('Mit Passwort anmelden'));
      await t.tap(find.text('Mit Passwort anmelden'));
      await t.pumpAndSettle();
      expect(auth.logins, 1);
      expect(auth.codeRequests, 0);
      expect(passwordController.text, isEmpty);
      expect(find.text('Abmelden'), findsOneWidget);
      await t.tap(find.text('Abmelden'));
      await t.pumpAndSettle();
      expect(
        t.widgetList<TextField>(find.byType(TextField)).last.controller!.text,
        isEmpty,
      );
      await t.ensureVisible(find.text('Alternativ mit E-Mail-Code'));
      await t.tap(find.text('Alternativ mit E-Mail-Code'));
      await t.pumpAndSettle();
      expect(find.text('Anmeldecode senden'), findsOneWidget);
      expect(auth.codeRequests, 0);
    },
  );
  for (final entry in {
    'invalid_credentials': 'E-Mail-Adresse oder Passwort ist falsch.',
    'email_not_confirmed': 'E-Mail-Adresse noch nicht bestätigt. Kontostatus administrativ prüfen.',
    'user_banned':
        'Dieses Konto ist gesperrt. Kontostatus administrativ prüfen.',
  }.entries) {
    testWidgets('password login safely reports ${entry.key}', (t) async {
      final auth = PasswordTestAuth(errorCode: entry.key);
      await show(t, auth);
      await t.enterText(find.byType(TextField).last, 'synthetic-password');
      await t.ensureVisible(find.text('Mit Passwort anmelden'));
      await t.tap(find.text('Mit Passwort anmelden'));
      await t.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(
        find.textContaining('synthetic-private-remote-message'),
        findsNothing,
      );
      expect(find.text('Abmelden'), findsNothing);
      expect(auth.codeRequests, 0);
    });
  }
}
