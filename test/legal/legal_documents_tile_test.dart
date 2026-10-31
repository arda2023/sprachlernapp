import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/screens/legal/legal_document.dart';
import 'package:sprachapp/screens/legal/legal_documents_tile.dart';

void main() {
  testWidgets(
    'privacy link opens offline legal screen at 2x text in narrow layout',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(280, 1100),
                textScaler: TextScaler.linear(2),
              ),
              child: const Scaffold(
                body: SingleChildScrollView(child: LegalDocumentsTile()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nutzungs- und Abonnementbedingungen'), findsOneWidget);
      expect(find.text('Impressum'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Datenschutzhinweise'));
      await tester.tap(find.text('Datenschutzhinweise').first);
      await tester.pumpAndSettle();

      expect(find.text('Datenschutzhinweise'), findsOneWidget);
      expect(find.text(legalDocumentDraftBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
