# Zahlungsabschluss Linglossa — 31. Oktober 2026

## Urteil

Der Kaufweg wurde in der Apple-Sandbox tatsächlich benutzt. Monats- und Jahresabo, automatische Verlängerung, Kündigung mit bezahlter Restlaufzeit, Ablauf, Wiederherstellung und Neuinstallation wurden beobachtet. Das ist keine öffentliche App-Store-Freigabe. Es gibt noch ausdrücklich benannte Voraussetzungen für den Verkauf; dieser Bericht zählt sie nicht als erledigt.

## Heute nachgebessert

- Eine fehlgeschlagene Wiederherstellung meldet ihren Fehler in Einstellungen und Paywall auch dann, wenn ein zuvor bestätigtes Premium weiter aktiv ist. Dieser bestehende Zugang wird durch den Fehler nicht gelöscht.
- Ein aktiver Production-Kontowechsel A → B → A wird mit verzögerter B-Antwort automatisch geprüft. B erbt keinen lokalen A-Status; die alte Antwort darf A nicht überschreiben.
- Release/TestFlight nutzt eine gemeinsame Kauf-Gate-Logik in Paywall und Provider. Production braucht die ausdrückliche Rechtstextfreigabe. Sandbox benötigt zusätzlich das explizite Build-Flag, serverseitige Testerfreigabe, passende Umgebung und einen gültigen, nicht abgelaufenen Testzugang. Sandbox wird dadurch kein Production-Entitlement und erhält kein bezahltes KI-Kontingent. Ein Release-Build mit Testunterstützung kann weiterhin Production bedienen.
- Neue eigene Texte benötigen jetzt einen bestätigten Premiumzugang. Der Zugriff wird vor dem Speichern geprüft. Ein unklarer Serverstatus bietet eine erneute Prüfung ohne Kauf an; ein abgemeldetes oder bestätigt kostenloses Konto kann bewusst „Premium ansehen“ öffnen. Ein vorgemerkter Text bleibt nach dem Paywall-Aufruf erhalten. Bereits gespeicherte Texte bleiben außerhalb dieser Schreibsperre lesbar und löschbar. Lernkarten, Wiederholungen und SRS wurden nicht umgeschrieben.
- Die offline erreichbaren Rechtstextseiten kennzeichnen Entwürfe abhängig vom tatsächlichen Freigabezustand. Das Entfernen der Kennzeichnung ersetzt keine inhaltliche Freigabe. Die Texte enthalten weiterhin fachliche Prüfpunkte und bleiben gesperrt.
- Adaptys zusätzliche dashboardseitige IP-Erfassung wurde abgeschaltet und zurückgelesen. Das SDK hatte die Erfassung bereits deaktiviert. Die Abschaltung löscht keine historischen Daten. [Bildnachweis](release-security-evidence/adapty-ip-collection-disabled-2026-10-31.png).
- `tool/payment_build.py` prüft die lokale Konfiguration, lehnt Server-/Service-Schlüssel ab, baut aus den aktuellen Quellen und protokolliert nur Konfigurationshash, Zeitpunkt und Ergebnis. Flutter-Fehler bleiben sichtbar; Konfigurationswerte werden aus der Ausgabe entfernt. Kein automatischer Upload und keine automatische Rechtstextfreigabe.
- Debug und Profile sind ausdrücklich Sandbox-only. Die Profile-Version verwendet AOT und wurde nach Beenden der Flutter-Sitzung über iOS erneut gestartet; damit braucht der Appstart keine Debug-Anbindung. Release/TestFlight bleibt an die zusätzliche Rechtsfreigabe gebunden.

## Tatsächlich gespeicherte Einstellungen

| Bereich | Live-Feststellung |
| --- | --- |
| Adapty-App | `9895e182-5f19-4122-a617-5cc83f212bef`, nur iOS, Bundle `com.ardasayar.linglossa` |
| Produkte | Monat `com.ardasayar.linglossa.premium.monthly`; Jahr `com.ardasayar.linglossa.premium.yearly`; beide Access Level `premium`, keine Offers |
| Placement | `premium`, aktiv, alle Nutzer, Custom Paywall „Linglossa Premium“, beide Produkte |
| Kontoteilung in Adapty | Production und Sandbox jeweils „Enabled (default)“. Das ist die bewusst dokumentierte aktuelle Store-Restore-Policy; keine Zusage einer exklusiven Bindung eines Storekaufs an genau ein App-Konto. Die serverseitige Profilbindung jedes App-Kontos bleibt unveränderlich. |
| Adapty iOS-Verbindung | SDK „Installed and working“, Bundle und IAP-Key-ID passend, private IAP-Datei vorhanden, Apple-Benachrichtigungen „Active“. Schlüsselwerte werden hier nicht dokumentiert. |
| Apple-Abos | Beide in Gruppe `22530015`, Stufe 1; Status „In Vorbereitung zur Übermittlung“; Monatsabo Deutschland 9,99 € live abgelesen; Jahrespreis 49,99 € zuvor im Sandbox-Kauf bestätigt |
| Apple-Prüfinformationen | Monatsabo hat weiterhin keinen Review-Screenshot und keine Prüfanmerkungen. Erster Abo-/Gruppenreview muss mit einer neuen App-Version erfolgen. |
| Apple-Vertrag/Bank/Steuer | Vertrag für gebührenpflichtige Apps, hinterlegtes Bankkonto und beide Steuerformulare jeweils „Aktiv“ |
| EU-Händlerprüfung | Vom Betreiber einschließlich Dokument und abschließender Bestätigung übermittelt. Am 31.10.2026 live in Safari geprüft: „Gesetz über digitale Dienste“ → „In Prüfung“. Noch keine Annahme oder Freigabe behauptet. Persönliche Kontaktwerte und Nachweisdokument bleiben aus diesem Repository-Bericht heraus. |
| Supabase | Projekt `yevntxclpchapacqdizm`, Region `eu-central-1`, Status `ACTIVE_HEALTHY`; die EU-Datenbankregion ist keine Zusage ausschließlich europäischer Verarbeitung sämtlicher Anbieter. |
| Letzter Kontoabgleich | Sandbox-Monatsabo abgelaufen, `is_active=false`, `will_renew=false`, Ablauf 31.10.2026 11:37:25 UTC; Production-Zeile inaktiv. Kein echtes Production-Abo behauptet. |
| Rechtstexte/Web | `LEGAL_DOCUMENTS_APPROVED=false`; lokale HTML- und App-Entwürfe vorhanden; keine freigegebene öffentliche Rechtswebsite. `linglossa.de` schlug im HTTPS-Test fehl, `www` war nicht auflösbar. |

## Prüfungen dieses Abschlussdurchlaufs

- Gemeinsamer Flutter-Lauf nach der Profile-Erweiterung: **78 bestanden**, Kauf-/Billing-Provider, SDK-Adapter, Serverparser, Wiederherstellung, Legal-Widgets, Importzugang, Story-Oberfläche und Onboarding. Anschließend vollständiger Flutter-Testlauf: **763 bestanden, 9 übersprungen** (nach dem zusätzlichen Paywall-Restore-Regressionsfall erneut vollständig ausgeführt). Keine dieser Prüfungen wurde als tatsächlicher Production-Kauf ausgegeben.
- Deno mit Typprüfung: **22 bestanden** für Billing, geteilte Webhooks und Kontolöschung. Die gezielten Regressionsfälle für anonym geteilte Profile und früh eintreffende Verlängerung bleiben enthalten.
- Python-Buildhelfer: **17 bestanden** inklusive Ablehnung von Service-Schlüsseln, Debug/Profile/Release-Gates und Redaction bei einem Buildfehlertext.
- Fokussierte Flutter-Analyse: **No issues found**. Whitespaceprüfung mit korrekter CRLF-Behandlung sauber.
- Frischer signierter Debug-Build auf dem verbundenen iPhone 14 Plus: Xcode-Build **27,2 s**, Installation/Start über WLAN **45,4 s**, Dart-VM-Service erreichbar. Keine Wiederverwendung einer unpassenden AOT-Datei.
- Anschließend frischer signierter **Profile-Build**, nach dem letzten Paywall-Fix erneut erstellt: Xcode **37,6 s**, Installation/Start **5,8 s**. Flutter-Anbindung beendet; unabhängiger iOS-Start erfolgreich, App-Prozess anschließend vorhanden. Im Startlog stehen Impeller-Rendererdiagnosen (`SetInheritedOpacity`); das ist kein bestandener visueller Gesamttest und wurde nicht als Billingfehler umgedeutet.
- GitNexus meldet für den gesamten gemischten Arbeitsbaum **CRITICAL** (36 geänderte Dateien, 83 Symbole, 208 Prozesse). Die vollständige MCP-Antwort war nicht partiell oder abgeschnitten. Der Dart-Graph enthält falsch zugeordnete Referenzen und erfasst unversionierte Dateien nicht vollständig; Quellprüfung und gezielte Tests bleiben zusätzlich erforderlich. Das ist kein sauberer Gesamtfreigabevermerk und kein Anlass, andere Arbeitsänderungen zurückzusetzen.

Frühere SQL-, Quota-Concurrency-, Live-RLS- und Lösch-Smoke-Nachweise stehen in [ADAPTY_SETUP.md](../ADAPTY_SETUP.md). Der manuelle Abbruch des Apple-Kaufblatts wurde auf ausdrücklichen Nutzerwunsch ausgelassen; der automatische Ergebniszweig ist getestet. Ein realer Apple-Refund und eine reale Zahlung mit Production-Abrechnung sind nicht nachgewiesen.

## Noch notwendig, um öffentlich zu verkaufen

### Live ergänzter Stand der Store-Seite am 31.10.2026

Die Version 1.0 steht weiterhin auf „In Vorbereitung zur Übermittlung“. In der angemeldeten Oberfläche wurden zusätzlich folgende Lücken bestätigt: Beschreibung, Schlüsselwörter, Support-URL und Copyright leer; kein Build ausgewählt; Review-Benutzername, Passwort, Kontaktangaben und Prüfanmerkungen leer. Der ausgewählte iPhone-Screenshotbereich zeigt 0 von 10 Bildschirmfotos; damit ist nicht behauptet, dass jede weitere Mediengröße geprüft wurde. Kategorie, Inhaltsrechte und Altersfragebogen sind noch nicht eingerichtet. Die Datenschutzseite fordert die Ersteinrichtung der Datenerfassungsangaben; eine öffentliche Datenschutz-URL fehlt. Als Lizenzvertrag ist Apples Standardlizenzvertrag ausgewählt. Der Build unterstützt iPhone und iPad; die endgültigen Medien und der Gerätetest müssen zu diesem Versandumfang passen.

Dieser Abgleich ändert keine Store-Angaben und ersetzt keinen vollständigen erneuten Quellcodeaudit. Die bereits korrigierten Kauf-/Auth-Platzhalter aus dem Bericht vom 30.10. werden nicht erneut als aktuelle Fehler gezählt.

Für eine Anfrage an Apple zu einem individuellen Nachweis kann folgender Entwurf verwendet werden (noch nicht versendet):

> I am enrolled in the Apple Developer Program as an individual under my legal name. During DSA trader verification, App Store Connect requests proof of name using business or legal records. I do not have a business registration or company documents. Which documents do you accept for an individual in this situation? Can a current personal bank statement showing my full legal name and residential address be accepted, and which unrelated financial information may be redacted? App Apple ID: 6829010347.

1. **Ergebnis der Apple-Händlerprüfung abwarten.** Die Angaben und der Nachweis sind übermittelt; der live gelesene Status lautet „In Prüfung“. Apple kann weitere Nachweise anfordern. Eine erneute Eingabe ist derzeit nicht erforderlich. Quelle: [Apples Händleranforderungen](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/).
2. **Rechtstexte inhaltlich abschließen und öffentlich bereitstellen.** Vorhandene Entwürfe enthalten noch die ausdrückliche offene Widerrufsbelehrung und Anbieter-/Vertragsprüfungen. Sie werden nicht allein durch einen Build-Schalter rechtlich vollständig. Anbietervereinbarungen und ein erreichbarer öffentlicher Datenschutzlink müssen zum tatsächlichen Betrieb passen. Technische Nachweise und Prüfgrenzen: [Rechtstextprüfung](legal-documents-review.md).
3. **Verkaufte Inhaltsleistung fertigstellen.** Der feste [Freemium-Plan](plans/2026-10-24-freemium-premium-plan.md) verkauft die volle Bibliothek und eigene Texte. Der Importzugang ist jetzt umgesetzt; Story-/Deck-/Grammatikzugänge besitzen weiterhin keine Premium-/Starterzuordnung. Die gebündelten Packs sind interne Testinhalte: 14 Stapel je Sprache, nur eine englische Story, keine Storys in den übrigen vier Sprachen, keine gepackten Grammatik-/Textübungs-/Audiozeilen. Daraus darf keine fertige öffentliche Premium-Bibliothek abgeleitet werden. Die Umsetzung benötigt explizite Starterkennzeichnung und einen Bestandsschutz für bereits verfügbares Material; neue Karten dürfen gesperrt werden, vorhandene Karten/Reviews niemals. Fehlende öffentliche Inhalte werden nicht durch einen erfolgreichen Kauf ersetzt.
4. **Prüfbuild und Apple-Einreichung.** Für einen genehmigten Release-Build muss die Rechtsfreigabe tatsächlich erteilt sein; TestFlight verwendet Apple-Sandbox. Ein Demo-App-Konto für App Review muss serverseitig für Sandbox zugelassen sein. Review-Screenshots, nachvollziehbare Testschritte und beide ersten Abos an derselben App-Version ergänzen. Erst dann einreichen; kein stiller App-Review-Submit. Quellen: [TestFlight-Käufe](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/), [Ersten In-App-Kauf einreichen](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase).

Eine einzelne allgemeine Zusage „Zahlungen erledigt“ würde diese vier Punkte verdecken. Die Softwarekorrekturen und Tests sind erledigte Einzelpositionen; die offene Betreiberverifikation und öffentliche Vertriebsfreigabe bleiben offen.

## Reproduzierbare Befehle

Vom Projektverzeichnis aus. Windows/PowerShell nutzt `python`, macOS/Terminal `python3`; Flutter-Parameter sind identisch, iOS-Builds erfordern macOS/Xcode.

```text
python3 tool/payment_build.py check --config config/adapty.local.json
python3 tool/payment_build.py ios-debug --config config/adapty.local.json --device <iPhone-ID>
python3 tool/payment_build.py ios-profile --config config/adapty.local.json --device <iPhone-ID>
python3 tool/payment_build.py ios-archive --config config/adapty.local.json --build-number <neue-Nummer> --dry-run
```

Der Archivbefehl muss im aktuellen Zustand mit `LEGAL_DOCUMENTS_APPROVED=false` ablehnen. Erst nach tatsächlicher Freigabe wird dieser Wert bewusst geändert. Für TestFlight/App Review braucht derselbe Release-Build außerdem explizite Sandbox-Unterstützung; Production bleibt trotzdem nutzbar. Die serverseitige Sandbox-Testerfreigabe wird dadurch nicht ersetzt.
