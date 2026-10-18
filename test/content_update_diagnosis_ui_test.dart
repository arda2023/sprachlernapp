import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_update_diagnosis.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/presentation/providers/content_update_provider.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/screens/settings/content_updates_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('error state shows the safe diagnosis line', (t) async {
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
          contentUpdateProvider.overrideWith(_FailedController.new),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ContentUpdatesScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.text('Diagnose · Schritt: verify · Lokal: ISOLATE_TRANSFER'),
      findsOneWidget,
    );
    expect(find.text('Erneut prüfen'), findsOneWidget);
  });
}

class _FailedController extends ContentUpdateController {
  @override
  ContentUpdateState build() => ContentUpdateState(
    'error',
    'Inhaltsaktion nicht abgeschlossen. Anmeldung, Freigabe und Verbindung prüfen. Bisheriger Inhalt bleibt erhalten.',
    diagnosis: const ContentUpdateDiagnosis(
      'verify',
      'ISOLATE_TRANSFER',
    ).describe(),
  );
}
