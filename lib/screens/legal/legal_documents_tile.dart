import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ListTile;

import 'legal_document.dart';
import 'legal_document_screen.dart';

/// Direct offline links to the app's privacy notice, terms and imprint.
class LegalDocumentsTile extends StatelessWidget {
  const LegalDocumentsTile({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _LegalLink(title: 'Datenschutzhinweise', document: LegalDocument.privacy),
      _LegalLink(
        title: 'Nutzungs- und Abonnementbedingungen',
        document: LegalDocument.terms,
      ),
      _LegalLink(title: 'Impressum', document: LegalDocument.imprint),
    ],
  );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.title, required this.document});

  final String title;
  final LegalDocument document;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    trailing: const Icon(CupertinoIcons.chevron_right, size: 17),
    onTap: () {
      Navigator.of(context).push(LegalDocumentScreen.route(document: document));
    },
  );
}
