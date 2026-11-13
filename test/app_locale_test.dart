import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/main.dart';
import 'package:sprachapp/widgets/date_format.dart';

import 'fixtures/deck_repositories.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('German system UI even on an English device', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'US',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(testScope(const SprachApp(), library: true));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('de'));
    final material = MaterialLocalizations.of(context);
    final cupertino = CupertinoLocalizations.of(context);
    expect(material.copyButtonLabel, 'Kopieren');
    expect(material.pasteButtonLabel, 'Einsetzen');
    expect(cupertino.copyButtonLabel, 'Kopieren');
    expect(cupertino.pasteButtonLabel, 'Einsetzen');
    expect(material.backButtonTooltip, 'Zurück');
    expect(material.formatDecimal(1234), '1.234');
    expect(material.formatShortDate(DateTime(2027, 3, 12)), '12. März 2027');
    // Billing dates keep their existing, explicit German formatting.
    expect(formatDateDe(DateTime(2027, 3, 12)), '12. März 2027');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
