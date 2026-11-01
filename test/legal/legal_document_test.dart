import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/screens/legal/legal_document.dart';
import 'package:sprachapp/screens/legal/legal_release_gate.dart';

String textFor(LegalDocument document) => legalDocuments[document]!.sections
    .map((section) => '${section.heading}\n${section.body}')
    .join('\n');

void main() {
  test('all in-app legal texts are substantial and visibly draft-only', () {
    expect(legalDocuments.keys, containsAll(LegalDocument.values));
    for (final document in LegalDocument.values) {
      final content = legalDocuments[document]!;
      expect(content.sections, isNotEmpty);
      expect(
        content.sections.every((section) => section.body.isNotEmpty),
        isTrue,
      );
      expect(textFor(document), contains('Entwurf'));
    }
    expect(
      legalDocumentDraftBanner,
      contains('noch nicht rechtlich freigegeben'),
    );
  });

  test(
    'privacy notice describes actual processing without unsupported promises',
    () {
      final privacy = textFor(LegalDocument.privacy);
      expect(privacy, contains('ohne Ablaufdatum'));
      expect(
        privacy,
        contains('nicht mit einem Linglossa-Konto synchronisiert'),
      );
      expect(privacy, contains('authentifizierte Supabase Edge Function'));
      expect(
        privacy,
        contains(
          'gesonderte Funktion zum Erstellen einer privaten Übungskarte',
        ),
      );
      expect(
        privacy,
        contains('Vergleichskontexte vorhandener privater Karten'),
      );
      expect(
        privacy,
        contains('weder für Wiederholungsplanung noch für Bewertung'),
      );
      expect(privacy, contains('nicht zugesichert'));
      expect(
        privacy,
        contains('Einstellungen → Inhalte und Hilfe → Konto dauerhaft löschen'),
      );
      expect(privacy, contains('innerhalb von fünf Minuten'));
      expect(
        privacy,
        contains('lokaler Lernstand auf diesem Gerät bleibt erhalten'),
      );
      expect(privacy, contains('account.apple.com'));
      expect(privacy, contains('Technischen Notiz TN3194'));
      expect(privacy, contains('Store, in dem du es abgeschlossen hast'));
      expect(privacy, isNot(contains('Ein Antrag auf Löschung deines Kontos')));
      expect(
        privacy,
        contains(
          'Wir behaupten hier nicht, dass ein bestimmter Auftragsverarbeitungsvertrag',
        ),
      );
      expect(privacy, contains('kontakt@linglossa.de'));
      expect(privacy, contains('Apple-Account-Einstellungen unter'));
    },
  );

  test('terms use configured prices and do not promise future content', () {
    final terms = textFor(LegalDocument.terms);
    expect(terms, contains('9,99 € pro Monat'));
    expect(terms, contains('49,99 € pro Jahr'));
    expect(
      terms,
      contains('500 Online-Übersetzungen je monatlichem Kontingentzeitraum'),
    );
    expect(terms, contains('fünf Online-Übersetzungen'));
    expect(terms, contains('keine kostenlose Testphase'));
    expect(terms, contains('Ein bestimmter Umfang künftiger Inhalte'));
    expect(terms, contains('innerhalb von fünf Minuten'));
    expect(terms, contains('Dein lokaler Lernstand bleibt auf dem Gerät'));
    expect(terms, contains('Apples Hinweis TN3194'));
    expect(terms, contains('kündigt ein Store-Abonnement nicht'));
  });

  test(
    'public legal approval defaults off and HTML is reusable draft copy',
    () {
      expect(legalDocumentsApproved, isFalse);
      for (final file in [
        'assets/legal/datenschutz.html',
        'assets/legal/nutzungsbedingungen.html',
        'assets/legal/impressum.html',
      ]) {
        final html = File(file).readAsStringSync();
        expect(html, contains('<!doctype html>'));
        expect(html, contains('ENTWURF – noch nicht rechtlich freigegeben'));
        expect(html, contains('kontakt@linglossa.de'));
      }
    },
  );
}
