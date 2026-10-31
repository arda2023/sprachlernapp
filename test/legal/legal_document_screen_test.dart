import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/screens/legal/legal_document.dart';
import 'package:sprachapp/screens/legal/legal_document_screen.dart';

void main() {
  for (final document in LegalDocument.values) {
    testWidgets('${document.name} is clearly marked as a draft when gated', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: document,
            legalDocumentsApprovedOverride: false,
          ),
        ),
      );

      expect(find.text(legalDocumentDraftBanner), findsOneWidget);
      expect(find.text('Entwurf und Geltungsbereich'), findsOneWidget);
    });

    testWidgets('${document.name} omits draft notices when approved', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LegalDocumentScreen(
            document: document,
            legalDocumentsApprovedOverride: true,
          ),
        ),
      );

      expect(find.text(legalDocumentDraftBanner), findsNothing);
      expect(find.text('Entwurf und Geltungsbereich'), findsNothing);
      expect(find.text('Weitere Angaben'), findsNothing);
      expect(find.textContaining('Entwurf'), findsNothing);
    });
  }
}
