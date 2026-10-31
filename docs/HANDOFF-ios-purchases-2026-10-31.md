# Linglossa: Übergabe der iOS-Kaufdiagnose an Claude

Stand: 31.10.2026, Europe/Berlin. Dieser Bericht wurde auf ausdrücklichen Wunsch des Betreibers erstellt. Ziel: fehlende Storepreise auf dem echten iPhone beheben und danach den vollständigen Sandbox-Kauf einschließlich serverseitiger Freischaltung und Wiederherstellung prüfen.

## 1. Kurzbefund

**Der Kauf funktioniert noch nicht nachweislich. Die Paywall lädt keine Produkte/Preise aus dem Apple Store. Es gab bisher kein erfolgreiches Kaufblatt und keinen bestätigten Sandbox-Kauf.**

Das aktuelle Geräteprotokoll enthält wiederholt:

```text
v4.1.3, Adapty/Adapty+Shared.swift#72
flutter: Billing catalog: store products failed (Adapty 1000).
```

Der Fehler ist auf den Aufruf `Adapty().getPaywallProducts(flow: flow)` eingegrenzt. Der vorausgehende `Adapty().getFlow(placementId: placementId)` läuft durch. Adapty-Code 1000 steht laut Adapty-Dokumentation für nicht verfügbare/ungültige Produktidentifikatoren beim Storeabruf. Das beweist nicht, dass die Zeichenfolgen falsch sind: Auch Apple-Konfiguration, Verfügbarkeit, Verträge und Bereitstellungsverzögerungen kommen infrage.

Zwei tatsächliche Apple-Konfigurationsprobleme wurden gefunden:

1. Der Vertrag für gebührenpflichtige Apps war noch nicht aktiv. Der Nutzer hat Vertrag, Bank- und Steuerangaben abgeschlossen. Sein Screenshot vom 31.10. um 09:40 zeigt alle als **Aktiv**.
2. Das Jahresabo hatte bei „1 Jahr im Voraus“ **0 verfügbare Länder**. Dies wurde direkt im Apple-Dashboard gelesen. Der Nutzer hat anschließend gemeldet, die Verfügbarkeit korrigiert zu haben. **Die gespeicherte Auswahl wurde danach von uns noch nicht erneut gelesen.**

Nach der gemeldeten Korrektur und einem erneuten Appstart meldet der Nutzer weiterhin fehlende Preise. Auch das zuletzt gelesene Geräteprotokoll enthält weiterhin Fehler 1000. Die genaue Zeit zwischen Speichern der Verfügbarkeitsänderung und letztem Versuch ist nicht belegt. Deshalb ist „Apple braucht nur Zeit“ bisher eine Hypothese, keine Diagnose.

## 2. Arbeitsumgebung und Schutz bestehender Arbeit

- Repository: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`
- Branch bei Berichterstellung: `ui-polish-launch-screen`
- Zuletzt in dieser Arbeit dokumentierter HEAD: `d2c276d8e2e5f9f32494c66330019dd3f1bebb12` (bei Übernahme erneut prüfen).
- Viele nicht committete Änderungen und neue Dateien, einschließlich Auth/Billing sowie unabhängiger Story-/UI-Arbeit. **Nicht zurücksetzen oder pauschal überschreiben.**
- Für diese Zahlungsarbeit wurde kein Commit erstellt.
- Maßgeblich: `AGENTS.md`, `CLAUDE.md`, `PRODUCT.md`, `DESIGN.md`, `ARCHITECTURE.md`.
- GitNexus: vor Änderungen an vorhandenen Funktionen/Klassen/Methoden Impact prüfen; vor Commit `detect_changes`. UNKNOWN ist keine Freigabe. Repository explizit per absolutem Pfad angeben, weil mehrere ähnlich benannte Indizes registriert sind.
- Keine Server-Secrets in App, Dart-Defines, Bericht oder Git übernehmen. Keine direkten KI-Aufrufe vom Client.
- iOS zuerst; Android ist ausdrücklich zurückgestellt.

Ergänzende Projektunterlagen:

- `ADAPTY_SETUP.md`: Implementierung, Serverregeln, bereits ausgeführte Tests.
- `docs/legal-documents-review.md`: Rechtstextentwürfe und offene Freigaben.
- `docs/release-security-audit.md`: weitere Releaseprüfungen.

## 3. Reproduktion und beobachtete Oberfläche

1. App auf dem verbundenen iPhone über Flutter starten.
2. Mit dem bestätigten Linglossa-Testkonto anmelden.
3. „Premium entdecken“ öffnen.
4. „Erneut versuchen“ antippen.

Beobachtung:

- Keine Monats-/Jahrespreise und keine auswählbaren Storeangebote.
- „Premium abonnieren“ deaktiviert.
- Meldung: „Der Store konnte die Anfrage nicht abschließen. Bitte erneut versuchen.“
- Platzhalter: „Der Preis und die Laufzeit werden vom Store geladen.“
- Fehlertext erscheint an zwei Stellen.
- Oben steht im Screenshot fälschlich **„Lingvist Premium“** statt Linglossa Premium. Separater UI-Fehler, keine nachgewiesene Ursache des Storeproblems.
- Links für Nutzungsbedingungen, Datenschutz und Impressum vorhanden.

Screenshots des Nutzers:

- `/Users/ardasayar/Downloads/IMG_C4FBFEA42C2B-1.jpeg`: erstes Preisfehlerbild, 09:21.
- `/Users/ardasayar/Downloads/IMG_89A0B0740927-1.jpeg`: gleicher Fehler, 09:43.
- `/Users/ardasayar/Downloads/IMG_E5C38BBDEB7F-1.jpeg`: Flutter-Debug-Startbeschränkung.
- `/Users/ardasayar/Downloads/appstoreconnect.apple.com_2026-10-31_09-40.png`: aktive Verträge, Bank und Steuerformulare; EU-Händlerstatus noch offen.

Weitere ältere Bildschirmfotos liegen teilweise unter macOS `TemporaryItems`; diese Pfade können inzwischen verschwunden sein.

## 4. Gerät, Build und Start

| Einstellung | Bekannter Stand |
|---|---|
| Gerät | „iPhone von Claus“, vom Nutzer als sein Testgerät bestätigt |
| Geräte-ID | `00008110-001651611E01401E` |
| Modell / OS | iPhone 14 Plus, iOS 18.7.2, zuvor ermittelt |
| Entwicklermodus | aktiviert, zuvor bestätigt |
| Flutter / Dart | 3.47.2 / 3.13.2, zuvor ermittelt |
| Xcode | 27.2, zuvor ermittelt |
| Minimum iOS | 15.0 |
| Flutter Adapty | `adapty_flutter` 4.1.1 |
| Native Adapty | 4.1.3; auch im aktuellen Log sichtbar |
| Installation | signierter Debug-Build, Swift Package Manager |
| Bundle ID | `com.ardasayar.linglossa` |
| Apple Team | `W27Z6DNPT3` |
| Lokales App-Binary | `build/ios/iphoneos/Runner.app` |
| Xcode-Workspace | `ios/Runner.xcworkspace` |

Der letzte Neustart wurde erfolgreich ausgeführt: „Installing and launching... 20,5s“, „Syncing files ... 153ms“, Dart-VM-Service erreichbar. Danach wiederholte Fehler 1000.

Letzter Startbefehl (macOS/Terminal, im Repository):

```sh
flutter run --debug -d 00008110-001651611E01401E \
  --use-application-binary=build/ios/iphoneos/Runner.app \
  --dart-define-from-file=config/adapty.local.json \
  > /tmp/linglossa-iphone-relaunch-2.log 2>&1
```

Wichtig: `--use-application-binary` verwendet das vorhandene Binary. Nach Code-/Dart-Define-Änderungen muss ohne diese Option neu gebaut werden, sonst wird die Änderung nicht einkompiliert. iOS-Builds brauchen macOS/Xcode; Windows/PowerShell kann diesen iOS-Start nicht ausführen.

Debug-Apps lassen sich auf diesem iPhone nach Beenden nicht zuverlässig vom Homescreen starten. Die gezeigte Flutter-Meldung verlangt den Start über Flutter/Xcode oder einen Profile-/Release-Build. Neustart über Flutter hat das Startproblem behoben, **nicht das Preisproblem**. Ein Wechsel auf Profile/Release ist kein neutraler Workaround: Die aktuelle Sandbox-Freigabe ist an `kDebugMode` gebunden.

Logpfade (lokal, möglicherweise flüchtig):

- **Aktuell:** `/tmp/linglossa-iphone-relaunch-2.log` (Flutter-Prozess zuletzt Tool-Session 71329).
- `/tmp/linglossa-iphone-relaunch.log` (voriger Prozess endete mit „Lost connection to device“).
- `/tmp/linglossa-store-diagnostic-run.log`
- `/tmp/linglossa-iphone-reinstall.log`
- `/tmp/linglossa-payments-iphone-run.log`

Die VM-Adresse wechselt mit jedem Start; aus dem aktuellen Log lesen. Nicht pauschal alle Flutter-Prozesse beenden, da andere Entwicklungsprozesse vorhanden waren.

Zusätzliche Logwarnung: `sqlite3.framework ... empty dSYM file detected`. Keine belegte Verbindung zum Storefehler.

## 5. Apple Developer / App Store Connect

| Feld | Wert / Beleg |
|---|---|
| App | Linglossa |
| App Store Connect App-ID | `6829010347` |
| Bundle ID | `com.ardasayar.linglossa` |
| Developer Team | `W27Z6DNPT3` |
| Abo-Gruppe | Linglossa Premium |
| Gruppen-ID | `22530015` |
| Gruppenlokalisierung | Deutsch, Anzeigename Linglossa Premium, App-Name Linglossa |
| Abo-Stufen | monatlich und jährlich beide Stufe 1 |
| Letzter gelesener Status | beide „In Vorbereitung zur Übermittlung“ |

Direkte Seiten:

- Gruppe: https://appstoreconnect.apple.com/apps/6829010347/distribution/subscription-groups/22530015
- Monat: https://appstoreconnect.apple.com/apps/6829010347/distribution/subscriptions/6829021098
- Jahr: https://appstoreconnect.apple.com/apps/6829010347/distribution/subscriptions/6829022099
- App-Informationen: https://appstoreconnect.apple.com/apps/6829010347/distribution/info

### Monatsabo (direkt geprüft)

- Apple-ID: `6829021098`
- Produkt-ID: `com.ardasayar.linglossa.premium.monthly`
- Verweisname: Linglossa Premium Monatlich
- Laufzeit: 1 Monat
- Deutschland ausgewählt, insgesamt 1 von 175 Ländern/Regionen.
- Aktueller Preis Deutschland: **9,99 €**, direkt in aufgeklappter Preistabelle gelesen.
- Deutsche Lokalisierung vorhanden.
- Beschreibung: „Alle Lerninhalte, eigene Texte und 500 KI-Übersetzungen“.
- Familienfreigabe zeigte „Aktivieren“, war also nicht aktiviert.
- Review-Screenshot war leer, Prüfanmerkungen leer.

### Jahresabo (Fehler gefunden, Korrektur vom Nutzer gemeldet)

- Apple-ID: `6829022099`
- Produkt-ID: `com.ardasayar.linglossa.premium.yearly`
- Verweisname: Linglossa Premium Jährlich
- Laufzeit: 1 Jahr
- Sollpreis laut Produktentscheidung: **49,99 €/Jahr**. Der aktuelle deutsche Apple-Preis wurde in dieser letzten Prüfung nicht aufgeklappt; bitte verifizieren.
- Deutsche Lokalisierung und gleiche Beschreibung wie Monatsabo vorhanden.
- Unter „1 Jahr im Voraus“ stand „Verfügbarkeit konfigurieren“.
- Geöffneter Dialog: **„Verfügbarkeit der Vorauszahlungsabrechnung (0)“**, Deutschland nicht ausgewählt.
- Nutzer hat danach die Korrektur bestätigt; anschließend weiterhin Fehler. Aktuell gespeicherte Länder neu prüfen.
- Apple zeigt zusätzlich „Monatlich mit Vertrag über 12 Monate“. Das ist ein anderer Abrechnungsmodus, nicht das beabsichtigte normale jährlich im Voraus bezahlte Abo. Diese zusätzliche Option wurde nicht eingerichtet.
- Review-Screenshot und Prüfanmerkungen waren leer.

### Verträge / Bank / Steuern

Nutzerscreenshot 09:40 zeigt:

- Vertrag für kostenlose Apps: Aktiv.
- Vertrag für gebührenpflichtige Apps: **Aktiv**, Gültigkeit 31.10.2026–30.10.2027.
- Bankkonto: **Aktiv**, Bankwährung EUR. Kontonummer wird hier nicht benötigt und nicht übernommen.
- U.S. Certificate of Foreign Status of Beneficial Owner: Aktiv.
- U.S. Form W-8BEN: Aktiv.
- Roter Hinweis: EU-Händlerstatus nach DSA noch anzugeben/zu prüfen. Das bleibt ein Releasepunkt; ein kausaler Zusammenhang zum Sandbox-Produktfehler ist nicht nachgewiesen.

Frühere Steuerformularbilder enthielten ein auffälliges Geburtsjahr 2026. Der Nutzer wurde auf Korrektur hingewiesen; der endgültige Feldinhalt wurde nicht überprüft. Für die technische Diagnose gilt nur: Apple zeigt die Formulare als aktiv. Keine steuerliche Richtigkeit aus dem Status ableiten.

### App-ID / Signing: noch gezielt zu verifizieren

Die App ist signiert installierbar. Das allein beweist nicht sämtliche IAP-Voraussetzungen. Eine frische, vollständige Prüfung von **In-App-Purchase-Capability der registrierten expliziten App-ID**, aktuellem Provisioning-Profil und aktiver StoreKit-Konfiguration ist in diesem Bericht **nicht als erledigt dokumentiert**. Bundle-ID im tatsächlich installierten Binary und im Apple-Appdatensatz vergleichen. Keine Wildcard-App-ID verwenden.

### Apple → Adapty Server Notifications

Im Nutzerscreenshot waren Produktions- und Sandbox-Server-URL identisch eingetragen:

```text
https://api.adapty.io/api/v1/sdk/apple/webhook/07a24210805340e7a93a0c485b4eaf1e/
```

Version 2 wurde empfohlen. **Die tatsächlich gespeicherte Versionsauswahl ist nicht separat belegt.** Die URLs waren bereits vor der Preisdiagnose vorhanden.

## 6. Adapty-Konfiguration

Adapty-CLI lokal vorhanden und authentifiziert, zuvor Version 0.15.0. Produkte und Placement wurden **bei Erstellung dieses Berichts erneut erfolgreich gelesen**.

| Feld | Wert |
|---|---|
| App-Name | Sprachapp |
| App UUID | `9895e182-5f19-4122-a617-5cc83f212bef` |
| Access Level Identifier | `premium` |
| Access Level UUID | `64e86c56-40b6-4051-baec-c21ba5c0265d` |
| Custom Paywall | Linglossa Premium |
| Paywall UUID | `fbd4251e-e2ae-4ee9-b8a4-45ce55f526de` |
| Placement Developer ID | `premium` |
| Placement UUID | `3123692d-7a77-4711-bd24-13fc73551e21` |
| Placement Zustand | `is_active: true`, `type: paywall` |
| Zielgruppe | Standard/alle Nutzer, `segment_ids: []`, Priorität 0 |
| Zugeordnete Paywall | obige Custom-Paywall-UUID |

Aktueller Produktabruf:

| Feld | Monat | Jahr |
|---|---|---|
| Adapty Produkt UUID | `d93cfe2b-7924-4fed-855b-b6862b28968d` | `ff0e5f17-80cf-4788-9581-b4416beddb06` |
| Zeitraum | `monthly` | `annual` |
| App Store SKU | `com.ardasayar.linglossa.premium.monthly` | `com.ardasayar.linglossa.premium.yearly` |
| Vendor-Verbindung UUID | `fdc0c6a1-a9b3-4958-ad2e-309eb4ebc50b` | `fda7ecac-b89b-4770-82ac-7f787c83a715` |
| `price_usd` im Adapty-Katalog | 9.99 | 49.99 |
| `store_status` | `null` | `null` |
| `offers_count` | 0 | 0 |

Beide Produkte sind demselben Access Level zugeordnet. Der USD-Katalogwert ist nicht der Beweis für den deutschen Kaufpreis. In der App soll ausschließlich der von Apple gelieferte lokalisierte Preis angezeigt werden. Die Bedeutung von `store_status: null` wurde nicht abschließend geklärt; nicht mit einer Apple-Ablehnung gleichsetzen.

App-Store-Verbindung laut vorherigen Nutzerscreenshots:

- Bundle ID: `com.ardasayar.linglossa`
- In-App Purchase API Issuer ID: `e39994d9-a09d-471a-82a9-068da3eba6c6`
- Key ID: `BGZ8UAU5KS`
- `.p8`-Datei vom Nutzer hochgeladen; Upload bestätigt.
- Ob ein App-Specific Shared Secret anschließend eingetragen wurde, ist nicht abschließend belegt. Im frühen Screenshot war das Feld leer. Nicht ohne aktuelle Prüfung behaupten, es sei vorhanden oder zwingend die Ursache.
- Small Business Program war im frühen Screenshot „Off“; keine spätere Änderung belegt.
- Keine Google-Play-Verbindung für diesen Release.
- Dashboard zeigte zeitweise „SDK is not installed“, obwohl die App inzwischen Adapty-Aufrufe ausführt. Aktueller Bannerstatus nicht erneut geprüft; kein alleiniger Beweis gegen eine SDK-Integration.

Read-only CLI, auf macOS/Terminal und Windows/PowerShell syntaktisch identisch, sofern CLI installiert und authentifiziert:

```text
adapty products list --app 9895e182-5f19-4122-a617-5cc83f212bef --json
adapty placements get --app 9895e182-5f19-4122-a617-5cc83f212bef 3123692d-7a77-4711-bd24-13fc73551e21 --json
```

## 7. Testkonten und lokale Konfiguration

**Zwei verschiedene Konten nicht verwechseln:**

- Linglossa/Supabase-Testkonto: `ardasa716@gmail.com`
- Supabase User UUID: `2af98709-72e6-4f38-b36c-997473e9eb48`
- Nur diese UUID wurde serverseitig für Sandbox-Testrechte freigegeben.
- Apple Sandbox-Tester laut Nutzer: `ardasa716+linglossa-sandbox1@gmail.com`, Land Deutschland. Der Nutzer meldete Erstellung und Anmeldung unter iPhone-Einstellungen → Entwickler → Sandbox. Aktuell tatsächlich angemeldeter Tester und dessen Storefront müssen bei Bedarf am Gerät überprüft werden.
- Frühere Einladungs-Testadresse `ardasa716+linglossa-test@gmail.com` ist ein anderes Supabase-Konto und nicht automatisch freigegeben.

Konfigurationsdateien:

- `config/adapty.local.json`: ignorierte lokale SDK-/öffentliche Supabase-/Google-Konfiguration. Nicht committen, Werte nicht in Logs kopieren.
- `config/adapty.example.json`: nicht geheime Vorlage.
- `/Users/ardasayar/.codex/private/linglossa/billing-server.env`: private Serverkonfiguration außerhalb des Repos, restriktive Dateirechte.
- `/Users/ardasayar/.codex/private/linglossa/webhook-values.txt`: private Webhook-Werte. **Nicht ausgeben oder an Dritte übertragen.**

Bekannte Schalter:

```text
ENABLE_SANDBOX_PURCHASES=true
LEGAL_DOCUMENTS_APPROVED=false
```

Sandbox-Freigabe benötigt Debugmodus plus lokale Option plus gezielte serverseitige Testerfreigabe. Release-Builds dürfen diese Ausnahme nicht übernehmen. Rechtstexte sind bislang nur Entwürfe, keine öffentlich freigegebene Website. Diese Freigabesperre darf nicht zur Fehlerumgehung entfernt werden. Der aktuell protokollierte Fehler entsteht bereits beim Storeproduktabruf.

## 8. Implementierung und Diagnoseänderung

Relevante Dateien:

- `lib/data/billing/purchase_gateway.dart`: Adapty-SDK, Produktabruf, Kauf/Restore.
- `lib/data/billing/adapty_billing_gateway.dart`
- `lib/data/billing/billing_sync_gateway.dart`
- `lib/presentation/providers/purchase_provider.dart`
- `lib/presentation/providers/billing_provider.dart`
- `lib/presentation/providers/account_provider.dart`
- `lib/screens/onboarding/paywall_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/main.dart`
- `test/adapty_purchase_gateway_test.dart`, `test/purchase_provider_test.dart`, `test/billing_provider_test.dart`, `test/billing_sync_gateway_test.dart`.

Letzte Diagnoseänderung in `AdaptyPurchaseGateway.loadCatalog`:

```dart
var stage = 'placement';
late final List<AdaptyPaywallProduct> products;
try {
  final flow = await Adapty().getFlow(placementId: placementId);
  stage = 'store products';
  products = await Adapty().getPaywallProducts(flow: flow);
} on AdaptyError catch (error) {
  if (kDebugMode) {
    debugPrint('Billing catalog: $stage failed (Adapty ${error.code}).');
  }
  rethrow;
}
```

Zusätzlich `package:flutter/foundation.dart` importiert. Nur Phase und numerischer Fehlercode werden geloggt, keine Kontodaten/Schlüssel. Das Log unterscheidet jetzt fehlgeschlagenes Placement von fehlgeschlagenen Storeprodukten. Rohfehler samt underlying StoreKit-Details wurden bisher **nicht vollständig erhoben**. Eine gezielte, redigierte native Diagnose wäre ein sinnvoller nächster Schritt.

Vor diesem Eingriff: GitNexus-Impact für `AdaptyPurchaseGateway.loadCatalog` ergab UNKNOWN wegen nicht aufgelöster Interface-/dynamischer Aufrufe; Aufrufer zusätzlich im Text geprüft (`PurchaseController.load`). Drei Gatewaytests nach Änderung bestanden.

Weitere bestehende Regeln: SDK-Aktivierung einmalig; Bindung an bestätigte Supabase-UUID; serialisierte Identitäts-/Kaufoperationen; erlaubte SKUs und Access Level; alte Antworten bei Kontowechsel verwerfen; Kauf/Restore erst nach Serverprüfung freischalten; Sandbox separat kennzeichnen. Diese Schutzmechanismen erhalten.

## 9. Backend und Webhooks

Supabase-Projekt: `yevntxclpchapacqdizm`, URL `https://yevntxclpchapacqdizm.supabase.co`.

Bereitgestellt:

- `billing-sync`
- `adapty-webhook`
- `adapty-webhook-sandbox`
- `delete-account`
- aktualisierte `lookup-word` / `translate-sentence`
- Migrationen `20261031000001_adapty_entitlements.sql`, `20261031000002_translation_subscription_budget.sql`, `20261031000003_account_deletion.sql`.

Adapty → Supabase:

```text
Production: https://yevntxclpchapacqdizm.supabase.co/functions/v1/adapty-webhook
Sandbox:    https://yevntxclpchapacqdizm.supabase.co/functions/v1/adapty-webhook-sandbox
```

Getrennte Auth-Secrets wurden gespeichert und nach Neuladen per Hashvergleich verifiziert. Falsches Secret ergab 401, authentifizierte Verifikation 200. **Die Zustellung eines echten Store-Kaufereignisses wurde mangels Kauf noch nicht getestet.**

Server liest aktuelle Adapty-Profildaten erneut, statt Payloads blind zu vertrauen. `app.verified_entitlements` ist servergeschrieben, RLS nur eigener lesender Zugriff. Production/Sandbox getrennt. Nur Production-Premium autorisiert bezahlte KI-Kontingente. Sandbox-Testabo soll in der App als „Premium-Testabo aktiv (Sandbox)“ sichtbar sein; es verleiht keine 500 bezahlten Serverübersetzungen.

## 10. Bisherige Versuche und deren Aussagekraft

| Versuch | Ergebnis |
|---|---|
| Produkt-IDs und Adapty-Placement geprüft | IDs passen, Placement aktiv, Paywall zugeordnet |
| App mehrfach neu gestartet / neu installiert | startet; Preise fehlen weiterhin |
| `getFlow` vs. `getPaywallProducts` diagnostiziert | Fehler in `getPaywallProducts`, Adapty 1000 |
| Paid Apps Agreement / Bank / Tax vervollständigt | Nutzer-Screenshot zeigt Aktiv |
| Jahresabo-Länder geprüft | tatsächlicher Fehler: 0 Länder; Nutzer meldet Korrektur |
| Retry nach Korrektur und Neustart | weiterhin 1000; genaue Wartezeit unbekannt |
| Flutter VM evaluate | Fehler 113, „No compilation service available; cannot evaluate from source“ |
| VM getVM / getIsolate | erreichbar, beweist laufende App |
| Weitere VM-Introspektion / Websocketdiagnose | keine brauchbare Produktdiagnose; nicht als Erfolg werten |
| Wechsel auf Profile/Release | nicht vorgenommen, würde derzeit Debug-Sandbox-Gate verändern |
| Abos gelöscht / neu angelegt | nicht vorgenommen; nicht als ersten Reparaturschritt durchführen |
| App/Abos bei Apple zur Prüfung eingereicht | nicht als durchgeführt dokumentiert; Sandbox braucht keine vorherige Revieweinreichung |

## 11. Bereits vorhandene Tests, keine Geräteabnahme

Frühere Ergebnisse vom 31.10., nicht alle bei Berichterstellung neu ausgeführt:

- 159 Fluttertests bestanden: `/tmp/linglossa-payments-flutter.log`.
- 44 Deno-Tests mit Typprüfung bestanden: `/tmp/linglossa-payments-deno.log`.
- Breitere Deno-Suite: 106 bestanden, 3 ignoriert, mit `--no-check`; volle Typprüfung durch vorhandenen impliziten any in `personal_learning_test.ts:154` blockiert.
- Flutter analyze: nur vorhandener `avoid_print`-Infohinweis in `test/data/baseline_adoption_pack_test.dart:43`.
- Simulatorbuild und signierter Gerätebuild erfolgreich.
- Isolierte PostgreSQL-Assertions für Berechtigungen, Entitlements, Reihenfolge, Kontingente, Monatsgrenzen und Löschung bestanden; keine pgTAP-Installation, deshalb keine vollständige pgTAP-Ausführung behaupten.
- Live-Smoke mit eigens angelegtem und anschließend entferntem Testkonto: Auth, Profilbindung, inaktive Rechte, RLS, abgewiesene Rechtefälschung, Kontingentreservierung/-freigabe und Löschung bestanden. Keine echten KI-Anfragen oder Käufe.
- Drei SDK-Gatewaytests nach Diagnoseänderung bestanden: `/tmp/linglossa-catalog-diagnostic-test.log`.

Diese Tests belegen nicht, dass Apple die Live-Sandboxprodukte liefert. Kauf, Wiederherstellung nach Neuinstallation, Verlängerung, Kündigung/Ablauf und Store-Webhooks müssen noch am Gerät abgenommen werden.

## 12. Empfohlene nächste Untersuchung für Claude

1. Aktuellen Arbeitsbaum und `ADAPTY_SETUP.md` lesen; bestehende Änderungen schützen.
2. Gespeicherte Jahresabo-Verfügbarkeit und tatsächlichen deutschen Preis neu prüfen. Zeitpunkt der letzten Änderung festhalten. Monatsabo ist bereits mit 9,99 € für Deutschland belegt.
3. Aktuellen Apple-Sandbox-Tester und Storefront am Gerät verifizieren. Keine echte Zahlung auslösen; bei Kaufblatt Umgebung kontrollieren.
4. Signiertes Binary, Apple-Appdatensatz, explizite App-ID/IAP-Capability, Provisioning-Profil und Xcode-StoreKit-Konfiguration vergleichen.
5. Falls nach angemessener Bereitstellungszeit weiterhin 1000: zugrunde liegende StoreKit-/Adapty-Fehler redigiert erfassen. Falls nötig beide IDs einzeln abfragen, um festzustellen, ob ein einzelnes Produkt oder beide fehlen. Keine gefälschten Preise als Reparatur einbauen.
6. Adapty-App-Store-Verbindung und dortigen aktuellen Diagnose-/Validierungsstatus prüfen. `store_status: null` allein erklärt den Fehler nicht.
7. Erst wenn echte Preise geladen werden: Sandbox-Kauf durchführen, Adapty-Event und aktiven Access Level prüfen, Supabase-Sandbox-Entitlement und Appstatus vergleichen. Danach Wiederherstellung/Verlängerung/Ablauf testen.
8. UI-Namensfehler „Lingvist Premium“ und doppelten Fehlertext separat korrigieren, mit vorgeschriebener Impact-Prüfung. Nicht mit erfolgreicher Storebehebung verwechseln.

Keine Grundlage für eine definitive Ursache außer den bereits gefundenen Konfigurationslücken. Nicht behaupten, dass Warten garantiert hilft oder dass fehlende Review-Screenshots zwingend den Sandboxabruf blockieren.

## 13. Quellen und lokale Skills

Offizielle Apple-Diagnose (in dieser Arbeit gelesen):

- https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox
- https://developer.apple.com/documentation/storekit/testing-a-product-request
- https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox

Apple TN3186 nennt Produkt-IDs, Preise/Lokalisierungen, Bundle-ID/IAP-Capability, Signing, Mitgliedschaft, aktiven Paid Apps Agreement sowie vollständige Bank-/Steuerdaten. Änderungen an IAP-Informationen können bis zu eine Stunde im Sandboxsystem benötigen. Die Quelle nennt damit keine garantierte Wartezeit speziell für unsere Vertragsaktivierung. Sandboxprüfung benötigt keine vorherige App-Review-Einreichung.

Adapty:

- https://adapty.io/docs/InvalidProductIdentifiers-flutter.md?ref=skill-4b923e74
- https://adapty.io/docs/test-purchases-in-sandbox.md?ref=skill-4b923e74
- https://adapty.io/docs/flutter-llms.txt?ref=skill-4b923e74
- https://github.com/adaptyteam/adapty-skills

Lokal vorhandene Skills:

- `/Users/ardasayar/.codex/skills/purchase-testing/SKILL.md`
- `/Users/ardasayar/.codex/skills/purchase-testing/references/app-store.md`
- `/Users/ardasayar/.codex/skills/adapty-integration/SKILL.md`
- `/Users/ardasayar/.codex/skills/adapty-docs/SKILL.md`
- Repository `.agents/skills/gitnexus-debugging/SKILL.md`

## 14. Abnahmekriterium

Das Problem gilt erst als behoben, wenn auf dem echten iPhone die tatsächlichen lokalisierten Storepreise erscheinen und ein Sandbox-Kauf zuverlässig bis zum serverbestätigten Sandbox-Premiumstatus durchläuft. Eine erfolgreiche Wiederherstellung und tatsächliche Ereigniszustellung bleiben zusätzliche Pflichtprüfungen. Öffentliche Kauf-Freigabe und Rechtstextfreigabe sind weiterhin gesondert offen.
