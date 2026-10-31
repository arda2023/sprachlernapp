/// Reviewable legal text for Linglossa.
///
/// These documents are deliberately marked as drafts until the operator has
/// reviewed them and explicitly enables `LEGAL_DOCUMENTS_APPROVED` for a
/// public release.
enum LegalDocument { privacy, terms, imprint }

class LegalSection {
  const LegalSection(this.heading, this.body, {this.draftOnly = false});

  final String heading;
  final String body;
  final bool draftOnly;
}

class LegalDocumentContent {
  const LegalDocumentContent({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;
}

const legalDocumentDraftBanner =
    'ENTWURF – noch nicht rechtlich freigegeben. Diese Fassung muss vor einer öffentlichen Veröffentlichung geprüft und bestätigt werden.';

const legalDocuments = <LegalDocument, LegalDocumentContent>{
  LegalDocument.privacy: LegalDocumentContent(
    title: 'Datenschutzhinweise',
    sections: [
      LegalSection(
        'Entwurf und Geltungsbereich',
        'Stand: 31. Oktober 2026. Diese Hinweise beschreiben die derzeit im Code erkennbare Verarbeitung in Linglossa. Sie sind ein Entwurf und noch nicht für eine öffentliche Veröffentlichung freigegeben.',
        draftOnly: true,
      ),
      LegalSection(
        'Verantwortlicher und Kontakt',
        'Verantwortlicher im Sinne der Datenschutz-Grundverordnung ist Arda Mehmet Sayar, Hellgrund 4, 22880 Wedel, Deutschland. Kontakt für Datenschutzfragen und Betroffenenanfragen: kontakt@linglossa.de. Ein Datenschutzbeauftragter ist in diesen Hinweisen nicht benannt.',
      ),
      LegalSection(
        'Daten auf deinem Gerät',
        'Linglossa speichert Lernkarten, Wiederholungen, Lernfortschritt, Einstellungen, Leselisten, lokal angelegte Inhalte und heruntergeladene Lerninhalte in einer SQLite-Datenbank auf deinem Gerät. Diese Lernstände werden nicht mit einem Linglossa-Konto synchronisiert. Sie bleiben grundsätzlich auf dem Gerät, bis du App-Daten löschst oder die App entfernst; eine Sicherung durch Betriebssystem oder Gerätehersteller kann davon unabhängig sein. Zugangstoken für die Anmeldung werden im sicheren Speicher des Betriebssystems abgelegt.',
      ),
      LegalSection(
        'Konto und Anmeldung',
        'Wenn du ein Konto anlegst oder dich anmeldest, verarbeiten wir deine E-Mail-Adresse und eine Konto-ID, um die Anmeldung und den Zugang zu geschützten Serverfunktionen zu ermöglichen. Bei einer Anmeldung mit Apple oder Google erhalten wir über Supabase Auth die für die Anmeldung erforderlichen Identitätsdaten beziehungsweise Bestätigungen. Welche zusätzlichen Angaben Apple oder Google übermitteln, hängt von deiner Auswahl und den Einstellungen des jeweiligen Anbieters ab. Die Anmeldung bei Apple oder Google läuft über deren native Anmeldefunktionen; der Client sendet keine Zugangsdaten an einen KI-Anbieter.',
      ),
      LegalSection(
        'Serverfunktionen und Lerninhalte',
        'Supabase wird für Authentifizierung, geschützte Edge Functions, Inhaltsbereitstellung und abonnementsbezogene Kontingente eingesetzt. Bei Anfragen an diese Funktionen werden die zur Authentifizierung notwendigen Konto- und Verbindungsdaten verarbeitet. Öffentliche Lerninhalte können vom Server auf das Gerät geladen werden. Persönliche Lernkarten und Wiederholungsstände werden dadurch nicht hochgeladen oder synchronisiert.',
      ),
      LegalSection(
        'Übersetzungen mit Anthropic',
        'Bereits vorhandene Übersetzungen aus Lernpaketen und passende lokal gespeicherte Übersetzungen werden zuerst verwendet. Für eine fehlende Wortübersetzung kann Linglossa das Wort nur nach der ausdrücklichen, widerrufbaren Freigabe in der Einführung beziehungsweise in den Einstellungen und nur mit angemeldetem Konto anfragen. Eine Satzübersetzung wird erst gestartet, wenn du die dafür vorgesehene Übersetzungsaktion ausdrücklich bestätigst. Dabei können der eingegebene oder ausgewählte Wort- oder Satztext, die Sprache und erforderlicher Kontext über eine authentifizierte Supabase Edge Function an Anthropic übermittelt werden. Der Client ruft Anthropic nicht direkt auf. Die Übersetzungsfunktion nutzt Anthropic Claude Haiku 5.5; eine Verarbeitung ausschließlich in der EU wird nicht zugesichert. Bitte sende keine besonderen Kategorien personenbezogener Daten oder vertraulichen Texte zur Übersetzung.',
      ),
      LegalSection(
        'Private Lernkarten',
        'Zusätzlich gibt es eine gesonderte Funktion zum Erstellen einer privaten Übungskarte. Sie wird nur gestartet, wenn du „Hinzufügen“ ausdrücklich auswählst und dieser Funktion separat zustimmst. Zur Zuordnung einer passenden vorhandenen Karte oder zur Erstellung einer Übung können das ausgewählte Wort, sein Satz und seine Position, Vergleichskontexte vorhandener privater Karten, passende gespeicherte Übersetzungshinweise sowie technische Referenzen des Lernpakets über eine authentifizierte Supabase Edge Function an Anthropic übermittelt werden. Anthropic kann daraus eine private Deutsch-gestützte Übung erstellen. Das Ergebnis wird bis zu 30 Tage serverseitig zur Wiederverwendung gespeichert; eine hinzugefügte Karte wird lokal auf deinem Gerät gespeichert. Diese Funktion verändert keine redaktionellen Lerninhalte und nutzt KI weder für Wiederholungsplanung noch für Bewertung deiner Antworten. Die separate Einwilligung ist in den Einstellungen widerrufbar; bereits übermittelte Anfragen lassen sich nicht zurückholen.',
      ),
      LegalSection(
        'Übersetzungsspeicher und Löschung',
        'Übersetzungsantworten können konto- und anfragebezogen zwischengespeichert werden. Die lokale App hält passende Antworten höchstens 30 Tage vor; die serverseitige Übersetzungsantwort wird ebenfalls mit einer Höchstfrist von 30 Tagen gespeichert und danach bei der nächsten passenden Bereinigung entfernt. Du kannst den gespeicherten Übersetzungscache über die dafür vorgesehene Funktion in der App löschen. Eine Cache-Löschung löscht keine lokalen Lernkarten, Wiederholungen oder Leselisten. Technische Sperr- und Wiederholungsmarker können zur Vermeidung doppelter Anfragen länger erforderlich sein; sie enthalten keine fertige Übersetzungsantwort.',
      ),
      LegalSection(
        'Abonnement und Abrechnung',
        'Käufe werden über den Apple App Store abgewickelt. Apple verarbeitet Zahlungsdaten und Store-Transaktionen nach den eigenen Hinweisen. Zur Zuordnung des Abonnements verarbeitet Adapty die von Linglossa verwendete Konto-UUID sowie Store- und Abonnementereignisse; Supabase speichert den serverseitig geprüften Abonnementstatus und das Übersetzungskontingent. Linglossa erhält keine vollständigen Zahlungsdaten wie Kreditkartennummern. In der App ist die Erfassung von Werbe-ID, IP-Adresse und Adapty-Attribution deaktiviert. Angaben, die Store oder Anbieter technisch für Betrieb, Sicherheit und Abrechnung verarbeiten, richten sich zusätzlich nach deren aktuellen Informationen.',
      ),
      LegalSection(
        'Schriftarten und Sprachausgabe',
        'Die App verwendet Google Fonts über das Paket google_fonts. Wenn die verwendete Schriftdatei nicht bereits lokal verfügbar ist, kann das Paket sie beim Anbieter abrufen. Bei einem solchen Abruf können technische Verbindungsdaten wie die IP-Adresse an den Anbieter übertragen werden. Die App kann außerdem die Sprachausgabe des Betriebssystems verwenden; deren Verarbeitung und etwaige Netzwerkverbindung hängen von Gerät, Betriebssystem, gewählter Stimme und Systemeinstellungen ab.',
      ),
      LegalSection(
        'Zwecke und Rechtsgrundlagen',
        'Wir verarbeiten Kontodaten, um den von dir angeforderten Konto- und Abonnementdienst bereitzustellen (Art. 6 Abs. 1 lit. b DSGVO). Die optionale Übermittlung fehlender Wortübersetzungen beruht auf deiner Einwilligung (Art. 6 Abs. 1 lit. a DSGVO); du kannst sie jederzeit für die Zukunft in den Einstellungen widerrufen. Eine einzelne Satzübersetzung beruht auf deiner ausdrücklichen Anforderung als Teil der von dir gewählten Funktion. Notwendige technische Verarbeitung und Sicherheitsmaßnahmen können auf unserem berechtigten Interesse am sicheren Betrieb und der Fehlerbehebung beruhen (Art. 6 Abs. 1 lit. f DSGVO). Gesetzlich erforderliche Aufbewahrung erfolgt auf Grundlage von Art. 6 Abs. 1 lit. c DSGVO.',
      ),
      LegalSection(
        'Empfänger, Drittlandverarbeitung und Aufbewahrung',
        'Je nach Funktion erhalten Supabase, Anthropic, Adapty, Apple, Google oder Google Fonts Daten, die für Anmeldung, Übersetzung, Abrechnung, Schriftabruf oder den Betrieb ihrer jeweiligen Funktion erforderlich sind. Konkreter Speicherort, Unterauftragnehmer, Vertragsstatus und Aufbewahrungsdauer richten sich nach der eingesetzten Konfiguration und den aktuellen Bedingungen der Anbieter. Für Supabase ist die im Projekt eingestellte Region maßgeblich; sie ist aus der App nicht ablesbar. Anthropic kann Übersetzungsanfragen außerhalb des Europäischen Wirtschaftsraums verarbeiten. Vor einer öffentlichen Freigabe müssen die tatsächlichen Anbietervereinbarungen, Drittlandgarantien und Einstellungen geprüft werden. Wir behaupten hier nicht, dass ein bestimmter Auftragsverarbeitungsvertrag oder Standardvertragsklauseln unterzeichnet wurden.',
      ),
      LegalSection(
        'Löschung und Speicherdauer',
        'Du kannst dein Linglossa-Konto in der App unter Einstellungen → Inhalte und Hilfe → Konto dauerhaft löschen starten. Aus Sicherheitsgründen muss deine Anmeldung aktuell sein; wenn sie abgelaufen ist, melde dich erneut an und starte das Löschen innerhalb von fünf Minuten. Dabei werden dein Konto und die zugehörigen serverseitigen Daten gelöscht. Dein lokaler Lernstand auf diesem Gerät bleibt erhalten. Geräte-Backups können davon unabhängig bestehen. Bei Konten mit Veröffentlichungsrechten muss vor der Löschung zuerst die Übertragung der Veröffentlichungsrechte geklärt werden; die App zeigt dir dazu die Kontaktmöglichkeit an. Wenn du dich mit Apple angemeldet hast, musst du nach der Löschung zusätzlich den Zugriff auf Linglossa unter account.apple.com im Bereich „Mit Apple anmelden“ manuell widerrufen; die App zeigt dir diese Schritte nach der Löschung an. Apple beschreibt dieses Vorgehen in der Technischen Notiz TN3194. Das Löschen des Linglossa-Kontos oder der App beendet ein Abonnement nicht. Kündige es zusätzlich im Store, in dem du es abgeschlossen hast, zum Beispiel in den Apple-Account-Einstellungen unter „Abonnements“ oder im Google Play Store unter „Zahlungen und Abos“.',
      ),
      LegalSection(
        'Deine Rechte',
        'Du kannst nach Maßgabe der DSGVO Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung und Datenübertragbarkeit verlangen sowie einer Verarbeitung auf Grundlage berechtigter Interessen widersprechen. Eine Einwilligung kannst du jederzeit mit Wirkung für die Zukunft widerrufen. Außerdem kannst du dich bei einer Datenschutzaufsichtsbehörde beschweren. Für eine nichtöffentliche Stelle mit Sitz in Schleswig-Holstein ist grundsätzlich die Landesbeauftragte für Datenschutz Schleswig-Holstein (ULD) zuständig: Holstenstraße 98, 24103 Kiel, mail@datenschutzzentrum.de; Beschwerdeinformationen: datenschutzzentrum.de/meldungen/.',
      ),
      LegalSection(
        'Änderungen',
        'Wenn sich die App oder ihre Datenverarbeitung wesentlich ändert, werden diese Hinweise angepasst. Die hier angezeigte Fassung ist Bestandteil der App und kann offline gelesen werden.',
      ),
    ],
  ),
  LegalDocument.terms: LegalDocumentContent(
    title: 'Nutzungs- und Abonnementbedingungen',
    sections: [
      LegalSection(
        'Entwurf und Geltungsbereich',
        'Stand: 31. Oktober 2026. Diese Bedingungen sind ein prüfbarer Entwurf und noch nicht für eine öffentliche Veröffentlichung freigegeben. Sie beschreiben die Nutzung der Sprachlern-App Linglossa durch Verbraucherinnen und Verbraucher.',
        draftOnly: true,
      ),
      LegalSection(
        'Anbieter und Vertragsschluss',
        'Anbieter ist Arda Mehmet Sayar, Hellgrund 4, 22880 Wedel, Deutschland, kontakt@linglossa.de. Für ein kostenpflichtiges Abonnement gelten zusätzlich die Angaben im Kaufdialog und die Bedingungen des Apple App Store. Mit der Bestätigung des Kaufs im Store gibst du eine verbindliche Bestellung zu dem dort angezeigten Produkt und Preis ab. Der Kauf kommt nach Bestätigung durch den Store zustande. Der Store wickelt Zahlung und Beleg ab.',
      ),
      LegalSection(
        'Leistungsumfang',
        'Linglossa bietet Sprachlernmaterial, Offline-Wörterbuchfunktionen, Übungen und lokal gespeicherten Lernfortschritt. Verfügbare Inhalte hängen von den in der App bereitgestellten Lernpaketen ab. Ein bestimmter Umfang künftiger Inhalte oder eine bestimmte Veröffentlichungsfolge wird nicht zugesagt. Der Lernfortschritt wird lokal gespeichert und derzeit nicht zwischen Geräten synchronisiert. Für ausgewählte fehlende Wort- oder Satzübersetzungen kann die App eine gesonderte, optionale Online-Übersetzung anbieten.',
      ),
      LegalSection(
        'Kostenlose Nutzung und Übersetzungskontingente',
        'Ohne aktives Abonnement stehen fünf Online-Übersetzungen als kostenloses Kontingent zur Verfügung. Ein aktives Premium-Abonnement umfasst bis zu 500 Online-Übersetzungen je monatlichem Kontingentzeitraum; das gilt auch bei jährlicher Abrechnung. Der Zeitraum richtet sich nach dem vom Server bestätigten Beginn des Abonnements. Das Kontingent umfasst nur erfolgreich zugelassene Übersetzungsanfragen und kann nicht auf andere Konten übertragen oder in Geld ausgezahlt werden. Offline-Wörterbuchfunktionen und vorhandene Lernpaketübersetzungen sind davon nicht betroffen.',
      ),
      LegalSection(
        'Abonnement, Preis und automatische Verlängerung',
        'Derzeit werden im deutschen Store ein monatliches Abonnement für 9,99 € pro Monat und ein jährliches Abonnement für 49,99 € pro Jahr angeboten. Der verbindliche Preis und die Abrechnungsperiode werden dir vor dem Kauf im Store angezeigt; bei einem anderen Land oder einer anderen Store-Währung kann der angezeigte Betrag abweichen. Es gibt derzeit keine kostenlose Testphase. Abonnements verlängern sich automatisch um die gewählte Laufzeit, sofern du vor der nächsten Verlängerung nicht kündigst. Die Kündigung und Verwaltung erfolgen in den Einstellungen deines Apple-Accounts unter „Abonnements“. Die Kündigung eines Linglossa-Kontos oder das Löschen der App kündigt ein Store-Abonnement nicht. Nach einer Kündigung bleibt der Premium-Zugang bis zum Ende des bezahlten Zeitraums bestehen, soweit der Store nichts anderes anzeigt.',
      ),
      LegalSection(
        'Kündigung und Widerruf',
        'Du kannst ein laufendes Abonnement jederzeit über die Abonnementverwaltung deines Apple-Accounts kündigen. Für gesetzliche Widerrufsrechte gelten die gesetzlichen Voraussetzungen und Fristen. Einen Widerruf gegenüber dem Anbieter kannst du eindeutig per E-Mail an kontakt@linglossa.de erklären. Die Store-Verwaltung ist für das Stoppen der automatischen Verlängerung erforderlich und ersetzt eine gesonderte Erklärung gesetzlicher Rechte gegenüber dem Anbieter nicht. Die konkrete Widerrufsbelehrung und gegebenenfalls das Muster-Widerrufsformular müssen vor dem öffentlichen Angebot entsprechend dem finalen Bestellweg ergänzt und geprüft werden.',
      ),
      LegalSection(
        'Nutzung und Online-Übersetzungen',
        'Du darfst Linglossa im Rahmen des geltenden Rechts und dieser Bedingungen für persönliche Lernzwecke nutzen. Eine fehlende Wortübersetzung wird nur bei aktivierter Einwilligung und angemeldetem Konto online angefragt. Eine Satzübersetzung startet erst nach deiner ausdrücklichen Bestätigung. Die Anfrage wird über einen authentifizierten Server an Anthropic Claude Haiku 5.5 übermittelt; eine ausschließlich europäische Verarbeitung wird nicht zugesichert. Sende keine vertraulichen oder sensiblen personenbezogenen Inhalte.',
      ),
      LegalSection(
        'Private Übungskarten',
        'Wenn du in der App „Hinzufügen“ auswählst, kannst du nach gesonderter Einwilligung eine private Übungskarte erstellen lassen. Dafür können das gewählte Wort, sein Satz, Vergleichskontexte aus vorhandenen privaten Karten, gespeicherte Übersetzungshinweise und Referenzen des Lernpakets an Anthropic über den authentifizierten Linglossa-Server übermittelt werden. Die Antwort kann bis zu 30 Tage serverseitig zur Wiederverwendung gespeichert werden; hinzugefügte Karten liegen auf deinem Gerät. KI-Ergebnisse sind private Lernhilfen und keine redaktionell geprüften Inhalte. Die Funktion ändert weder den Wiederholungsplan noch die Bewertung deiner Antworten.',
      ),
      LegalSection(
        'Verfügbarkeit, Änderungen und gesetzliche Rechte',
        'Wir bemühen uns um einen funktionierenden Dienst, schulden aber keine jederzeit unterbrechungsfreie Verfügbarkeit. Wartung, Sicherheitsupdates, technische Störungen oder Vorgaben von Plattformen können die Nutzung zeitweise beeinträchtigen. Gesetzliche Ansprüche wegen Mängeln digitaler Produkte und sonstige zwingende Verbraucherrechte bleiben unberührt. Nichts in diesen Bedingungen schließt eine Haftung aus, soweit ein Ausschluss gesetzlich unzulässig wäre.',
      ),
      LegalSection(
        'Konto und Datenschutz',
        'Für geschützte Serverfunktionen und Abonnements ist eine bestätigte Anmeldung erforderlich. Die Datenschutzhinweise erklären, welche Daten dabei verarbeitet werden. Du kannst die Löschung in der App unter Einstellungen → Inhalte und Hilfe → Konto dauerhaft löschen starten. Wenn deine Anmeldung abgelaufen ist, melde dich erneut an und starte das Löschen innerhalb von fünf Minuten. Dein lokaler Lernstand bleibt auf dem Gerät; ein abgeschlossenes Store-Abonnement musst du separat kündigen. Bei Anmeldung mit Apple widerrufst du den Apple-Zugriff nach der Kontolöschung zusätzlich manuell, wie in Apples Hinweis TN3194 beschrieben. Für Konten mit Veröffentlichungsrechten muss vorher die Übertragung der Rechte geklärt werden.',
      ),
      LegalSection(
        'Anwendbares Recht',
        'Es gilt deutsches Recht unter Wahrung der zwingenden Verbraucherschutzvorschriften des Staates, in dem du deinen gewöhnlichen Aufenthalt hast. Ein Gerichtsstand wird gegenüber Verbraucherinnen und Verbrauchern nicht abweichend von den gesetzlichen Regeln vereinbart.',
      ),
      LegalSection(
        'Kontakt',
        'Fragen zu Linglossa, Käufen oder diesen Bedingungen: Arda Mehmet Sayar, Hellgrund 4, 22880 Wedel, Deutschland; kontakt@linglossa.de.',
      ),
    ],
  ),
  LegalDocument.imprint: LegalDocumentContent(
    title: 'Impressum',
    sections: [
      LegalSection(
        'Entwurf und Geltungsbereich',
        'Stand: 31. Oktober 2026. Dieses Impressum ist ein Entwurf und noch nicht für eine öffentliche Veröffentlichung freigegeben.',
        draftOnly: true,
      ),
      LegalSection(
        'Anbieter',
        'Arda Mehmet Sayar\nHellgrund 4\n22880 Wedel\nDeutschland',
      ),
      LegalSection('Kontakt', 'E-Mail: kontakt@linglossa.de'),
      LegalSection(
        'Weitere Angaben',
        'Es wird keine Gesellschafts- oder Registereintragung angegeben. Eine Umsatzsteuer-Identifikationsnummer oder Wirtschafts-Identifikationsnummer wird in diesem Entwurf nicht angegeben. Falls eine solche Nummer besteht oder weitere gesetzliche Angaben aufgrund der konkreten geschäftlichen Tätigkeit erforderlich sind, muss das Impressum vor der Veröffentlichung ergänzt werden.',
        draftOnly: true,
      ),
    ],
  ),
};
