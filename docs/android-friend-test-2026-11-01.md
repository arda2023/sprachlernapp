# Privater Android-Test und befristetes Premium · 01.11.2026

## Erste Auslieferung (durch Update unten ersetzt)

Universelle APK außerhalb des Repositorys: `/Users/ardasayar/Desktop/Linglossa-Android-Test/Linglossa.apk`.
325.608.185 Bytes (325,6 MB), SHA-256 `98041aa02157ad91a10362c7fe00c95ba138a22cfab22dcbcdae6b5f90e0d547`.
Daneben liegen `ANLEITUNG.txt` mit der privaten Kontoanleitung und `SHA256SUMS.txt`. Keine E-Mail-Adresse oder Zugangsdaten im Repository oder APK fest eingebaut.

Release-Build, Android 7/API 24 oder neuer, target API 36, ARM64/ARMv7/x86_64. Die vorhandene Paketkennung `com.example.sprachapp` und die vorhandene Android-Debug-Signatur bleiben für diese private Testauslieferung erhalten. Signatur v2 geprüft, `debuggable=false`, INTERNET-Berechtigung vorhanden. Kein Store-Release. Spätere Testupdates mit gleicher Kennung und Signatur überinstallieren, nicht vorher deinstallieren.

Vorhandene öffentliche App-Konfiguration über eine temporäre Datei eingebunden, anschließend gelöscht. Keine Service-Role-, Anthropic- oder Adapty-Serverschlüssel in der App. Sandbox-Testkonfiguration und nicht freigegebene Rechtsdokumente erlauben in diesem Release-Build keine echten Storekäufe; serverbestätigtes Production-Premium funktioniert davon unabhängig. Android verwendet hier E-Mail-Code-Login; native Apple-/Google-Anmeldung wurde nicht neu eingerichtet.

## Kostenloses Premium

Das vom Nutzer benannte Konto wurde administrativ angelegt, jedoch nicht stellvertretend als E-Mail-verifiziert markiert. Der Empfänger bestätigt den Besitz seiner Adresse selbst per E-Mail-Code. Custom SMTP ist serverseitig aktiviert; eine tatsächliche Zustellung ins Empfängerpostfach wurde nicht vorweggenommen.

Adapty-Freischaltung für genau 30 Tage: 01.11.2026 15:33:50 bis 01.12.2026 15:33:50, Europe/Berlin. Keine Zahlung, kein Storeabo, keine automatische Verlängerung. Personenbezogener Auslieferungsbeleg ausschließlich lokal unter `~/.codex/private/linglossa/friend-premium-2026-11-01.json` (0600).

Der Server akzeptiert ausschließlich manuelle Grants aus einem frisch serverseitig abgerufenen, identitätsgeprüften Adapty-Profil: `store=adapty`, `store_product_id=adapty_server_side_product`, Access Level premium. Interne Kennung `com.ardasayar.linglossa.premium.complimentary`, Production-only, endliche gültige Daten, keine Verlängerung. SDK-Hinweise allein schalten nichts frei. Abgelaufene/zukünftige Grants bleiben inaktiv. Quoten und KI-Einwilligungen gelten weiter. Einstellungen zeigen die kostenlose Freischaltung mit Enddatum, ohne unzutreffenden Store-Verwalten-Knopf.

Migration `20261101000004_complimentary_premium.sql` remote angewendet. `billing-sync`, `adapty-webhook` und `adapty-webhook-sandbox` anschließend veröffentlicht. Der echte Empfänger-Grant wurde vom Server erneut bei Adapty gelesen und als aktiv, Production, nicht verlängernd und mit passendem Enddatum gespeichert.

## Nachweise

- Flutter: 25 Billing-/Purchase-/Subscription-Tests bestanden.
- Node: 21 Billing-/Webhook-/Grant-Tests bestanden.
- PGlite: drei SQL-Suiten bestanden (Übersetzungsquoten, generierte Vokabeln, kostenlose Premiumfreigabe).
- Veröffentlichter Server: 16 isolierte Live-Prüfungen mit fiktivem, anschließend vollständig gelöschtem Konto bestanden. Grant aktiv → erneuter Serverabgleich aktiv → Providerwiderruf → Serverabgleich inaktiv; RLS und aufgeräumte Konten/Profile geprüft. Keine KI-Aufrufe.
- Finales APK im Android-Emulator installiert: Success; Kaltstart Status ok, 1081 ms, Onboarding sichtbar. Vorab zusätzlich E-Mail-Code-Formular erreicht, ohne Mail auszulösen. Keine Behauptung eines Tests auf dem noch unbekannten physischen Freundesgerät.
- Finale APK enthält die neue Complimentary-Kennung; öffentliche Defines vorhanden, keine lokale JSON-/temporäre Definesdatei enthalten. Desktopkopie stimmt per SHA-256 überein.
- Analyse der geänderten Dart-Dateien: No issues found. CRLF-aware Diffcheck bestanden.
- GitNexus neu indexiert, Änderungsanalyse der getrackten Dateien: 6 Symbole, 5 Dateien, 216 Abläufe, critical, keine Partial-/Truncated-Markierung. Neue Migration und Tests zusätzlich direkt gelesen und ausgeführt; kein Commit erstellt.
- Android-Renderer meldete bekannte Impeller-Opacity-Diagnosen ohne Appcrash.

Quellen: [Adapty Grant API](https://adapty.io/docs/api-adapty/operations/grantAccessLevel.md), [manuelle Freischaltung](https://adapty.io/docs/grant-access-level.md). Tatsächliche Grant-Form zusätzlich mit einem gelöschten Testprofil geprüft.


## Korrektur nach Rückmeldung vom Android-Gerät

Der Screenshot des Empfängers zeigte die Kauf-Fehlerseite vor der Anmeldung. Die erste APK enthielt zwar die neue serverseitige Freigabe, prüfte sie unter Android jedoch nicht korrekt: `PurchaseController.load()` brach bei fehlendem Store-Gateway zu früh ab. Zusätzlich setzte die Prüfung laufender Serverantworten einen bereiten Store voraus. Die Aussage oben, dass serverbestätigtes Premium im ausgelieferten Android-Build unabhängig vom Store funktioniert, war deshalb für diese erste APK nicht zutreffend. Die bisherigen Server- und Widgettests hatten diesen Gerätepfad nicht abgedeckt.

Die Korrektur trennt den angemeldeten Kontozugang von der Storebereitschaft. Der erste Kontoabgleich läuft automatisch, auch ohne Öffnen der Paywall; ein fehlender oder fehlerhafter Storekatalog verhindert diesen Abgleich nicht mehr. Storekäufe bleiben an ihre bisherigen Konten-, Konfigurations- und Storebedingungen gebunden. Veraltete Antworten nach Kontowechsel werden verworfen; der Zugriff endet weiterhin zum serverbestätigten Ablaufdatum.

Ohne Store und ohne Anmeldung zeigt die Paywall jetzt „Mit Konto freischalten“ sowie eine Erklärung zum vorhandenen Kontozugang. Der Knopf öffnet die Anmeldung per E-Mail-Code. Eine aktive kostenlose Freigabe zeigt das Enddatum und „Weiterlernen“, keinen Abo-Verwalten-Knopf. Das tatsächliche Empfängerkonto und sein ursprüngliches 30-Tage-Enddatum bleiben unverändert; eine Anmeldung durch den Empfänger ist weiterhin notwendig.

Die neue Android-Prüfung verwendet ein eigenes fiktives Testkonto. Der Empfänger wird weder stellvertretend angemeldet noch mit einem fest eingebauten Passwort versehen.

### Prüfungen der Korrektur

- 26 Controller-Tests bestanden, darunter neun neue Regressionen für Android ohne Store, automatischen Kontozugang, parallele Abgleiche, fehlerhaften Katalog, Kontowechsel und Ablauf. Eine bereits unterwegs abgelaufene Serverantwort führt nicht zu einer endlosen Wiederholung.
- Breiter Lauf mit sieben Billing-/Content-/Subscription-/Onboarding-Testdateien: 76 Tests bestanden. Nach dem abschließenden Ablauf-Guard erneut alle 26 Controller-Tests bestanden.
- Die Paywall-Tests enthalten zusätzlich den Android-Fall ohne Store: Anmeldeknopf sichtbar und nutzbar, E-Mail-Anmeldung öffnet sich, irreführender Kauf-Fehlertext wird vor der Anmeldung nicht angezeigt. Separater Onboarding-Lauf: 17 Tests bestanden.
- Analyse der geänderten Controller-/Paywall-Dateien und Tests: `No issues found!`. CRLF-aware Diff-Prüfung ohne Fehler.
- GitNexus neu indexiert: 13.950 Knoten, 47.329 Kanten, 216 Abläufe. Änderungsanalyse: neun getrackte Dateien, zwei zugeordnete Symbole, 215 betroffene Abläufe, Risiko `critical`, ohne `partial`/`truncated`. Die Ausgabe enthält ein namenloses Dart-Methodensymbol und sehr breite Abläufe; deshalb kein vollständiger Abdeckungsnachweis. Quelltextprüfung, konkrete Regressionen und Android-Gerätetest dienen als zusätzliche Nachweise. Kein Commit erstellt.

- Echter Android-Emulatortest mit temporärer Test-App und unveränderten echten Providern (keine Gateway-Overrides): Auth/SecureStorage, Anmeldung des fiktiven Kontos, `SupabaseBillingSyncGateway`, native Store-/Purchase-Gateways `null`; `purchaseProvider.load()` bestätigt Production-Complimentary-Premium, UI-Zugriff, zukünftiges Enddatum, keine Verlängerung, keine Storeprodukte und keine Kaufberechtigung. Anschließendes echtes Abmelden entfernt Konto und Premium. Ergebnis: `ANDROID_SERVER_GIFT_TEST: PREMIUM_PASS`, `LOGOUT_PASS`, `PASS`.
- Der erste Testaufbau wartete ohne aktiven Provider-Listener; mit einem aktiven Listener wie in der App lief der Test erfolgreich. Dafür wurde ausschließlich der temporäre Harness angepasst, kein zusätzlicher Appcode.

- Temporäres Android-Testkonto vollständig entfernt: Adapty DELETE 204, Auth DELETE 200, erneute GETs jeweils 404. Lokale Fixture-/Define-Dateien und temporärer Dart-Einstieg gelöscht; sieben generierte Testdateien mit Zugangsdatenliteralen entfernt. Die finale App wird danach aus `lib/main.dart` ausschließlich mit öffentlicher App-Konfiguration neu gebaut.


### Ersatz-APK (Build 2, durch Build 3 unten ersetzt)

Damalige Weitergabedatei (jetzt archiviert unter `/Users/ardasayar/Desktop/Linglossa-Android-Archiv/Build-2`): `/Users/ardasayar/Desktop/Linglossa-Android-Test/Linglossa-Update.apk`, Version 1.0.0+2, 325.608.189 Bytes.
SHA-256: `d13a69776f32a8ebb75f25b1f1f66828ae65b85286a1a42f3422428ecffa7a3b`.

Die Desktopkopie ist hashidentisch mit dem geprüften Build. Gleiche Paketkennung und gleicher Signierer wie Build 1; Zertifikat SHA-256 `fa211a61f6d7212427ac86359a6fe8acad0c0d9cb130bf9d09bc35da4b80508e`. Installation als Update (`-r`) erfolgreich; Kaltstart `Status: ok`, 933 ms. Im finalen Release-APK bis zur Paywall navigiert: „Anmelden“ und „Mit Konto freischalten“ sichtbar; Antippen öffnet das echte AccountSheet mit „Mit E-Mail fortfahren“. Screenshot lokal: `/tmp/linglossa-update-paywall-cta.png`.

Gesamtscan des finalen APK auf temporäre Testzugangsdaten und Probe-Marker bestanden. Der Weitergabeordner enthält nur die neue APK, `ANLEITUNG.txt` und `SHA256SUMS.txt`; die drei alten Dateien liegen separat in `/Users/ardasayar/Desktop/Linglossa-Android-Archiv/Build-1`. Der Emulator wurde beendet. Auf dem physischen Gerät des Empfängers muss das Update noch installiert und die E-Mail-Anmeldung abgeschlossen werden; das wurde nicht stellvertretend behauptet.


## Zweite Rückmeldung: weiterhin Paywall (Build 3)

### Befund auf dem Server (ohne Zugriff auf das Gerät des Empfängers)

- Empfängerkonto: genau ein Auth-Konto mit dieser Adresse, identisch mit dem Konto des Grants. E-Mail per Code selbst bestätigt am 01.11.2026 um 18:43:09 (Europe/Berlin), eine Sitzung, nur Identität `email`. Adapty-Bindung zeigt auf das Profil des Grants; Entitlement `premium`, Production, aktiv, Produkt `com.ardasayar.linglossa.premium.complimentary`, Ende 01.12.2026 15:33:50, keine Verlängerung.
- `observed_at` des Entitlements blieb auf dem Einrichtungszeitpunkt (15:34). Ein erfolgreicher billing-sync hätte den Wert erneuert.
- Edge- und Function-Logs: Vom Gerät kamen `POST /auth/v1/otp` (18:42:52), `POST /auth/v1/verify` (18:43:09) und 44 s später `GET /functions/v1/content-release` (403 `READER_REQUIRED`, für Premium ohne Bedeutung). Danach kam kein einziger Aufruf von `billing-sync`.

### Ursache

Im Android-Emulator (API 28) wurden die ausgelieferten APKs mit einem eigenen, temporären Testkonto mit derselben Grant-Art nachgespielt. Die Anmeldung lief jeweils über den echten E-Mail-Code-Ablauf, der Code wurde serverseitig erzeugt.

| Build | Weg | billing-sync | Ergebnis |
|---|---|---|---|
| 1 (versionCode 1) | Einstellungen → Anmelden → E-Mail-Code | nie | Kachel bleibt bei „Abostatus wird geprüft“ und „Premium-Käufe sind auf diesem Gerät nicht verfügbar.“; die Paywall zeigt exakt den Screenshot des Empfängers |
| 2 (versionCode 2) | Inhaltsupdates → E-Mail-Code, Einstellungen → Anmelden, Kaltstart | nach ≤ 1 s bzw. sobald ein Premium-Element sichtbar ist | „Kostenlos freigeschaltet bis 1. Dezember 2026“, Premium-Stapel offen |

Das Servermuster des Empfängers (verify, keine billing-sync-Anfrage, `content-release` nur beim App-Start) entspricht Build 1. Mit Build 2 entsteht auf jedem getesteten Anmeldeweg innerhalb einer Sekunde ein billing-sync-Aufruf. Die Anmeldung um 18:43 lief also in einer App ohne die Korrektur. Ob das Update nicht installiert oder später versehentlich die erste APK erneut geöffnet wurde, lässt sich vom Server aus nicht unterscheiden. Die Einstellungen zeigen unten „Version 1.0.0+N“.

Zusätzlich gefundene Schwächen von Build 2, die eine Diagnose erschwerten:

1. Der Kontoabgleich startete nur, solange ein Premium-Element sichtbar war (Paywall, Einstellungen, Premium-Kacheln). Auf der Startseite oben passierte nach einem Kaltstart zunächst nichts.
2. Ein fehlgeschlagener Serverabgleich wurde neben der fehlenden Storeunterstützung nicht angezeigt. Sichtbar blieb nur „Premium-Käufe sind auf diesem Gerät nicht verfügbar.“
3. Der rote Store-Hinweis blieb in den Einstellungen auch bei aktiver Freigabe stehen.
4. „Wiederherstellen“ ohne nativen Store meldete nur den fehlenden Store und prüfte das Konto nicht.

### Änderung

- `lib/main.dart`: `SprachApp` hält `purchaseProvider` ab dem Start aktiv. Damit läuft der Kontoabgleich beim App-Start und nach jeder Anmeldung, unabhängig vom sichtbaren Bildschirm.
- `purchase_provider.dart`:
  - Neues Feld `PurchaseState.accountSyncError` für einen fehlgeschlagenen Serverabgleich. Es wird beim nächsten Abgleich gelöscht.
  - `restore()` prüft ohne nativen Store den serverbestätigten Kontozugang; ohne Konto bleibt es bei der Anmeldeaufforderung.
- `subscription_tile.dart`: Bei aktiver Freigabe kein Store-Fehler. Ein Serverfehler wird als „Premium-Status nicht geprüft“ mit Erklärung angezeigt.
- `paywall_screen.dart`:
  - Zeigt einen Serverfehler an.
  - Ohne Store meldet ein angemeldetes Konto ohne Premium ausdrücklich, dass für diese Adresse nichts freigeschaltet ist. Damit fällt eine Anmeldung mit einer anderen Adresse auf.

Keine globale Freischaltung, keine E-Mail-Ausnahme im Client und keine Änderung an Server, Autorisierung oder Grant.

GitNexus-Impact vor den Änderungen: `PurchaseState` **CRITICAL** (6 direkte Nutzer, 110 betroffene Symbole), `PurchaseController` MEDIUM, `_PaywallScreenState` MEDIUM, `SubscriptionTile` LOW, `SprachApp` UNKNOWN (per Textsuche bestätigt: `main.dart` und vier Testdateien). Deshalb wurde `PurchaseState` nur additiv erweitert.

### Nachweise

- Flutter:
  - 29 Controller-Tests bestanden. Neu darunter: Wiederherstellen ohne Store prüft das Konto, Wiederherstellen ohne Konto verlangt eine Anmeldung, und ein Serverfehler bleibt neben dem fehlenden Store sichtbar und verschwindet nach dem nächsten erfolgreichen Abgleich.
  - In `test/subscription_tile_test.dart` 2 neue Widget-Tests; alle 6 Tests der Datei bestanden.
  - In `test/onboarding_test.dart` 2 neue Paywall-Tests.
  - Billing-, Onboarding-, Practice-, Deck- und App-Tests: 157 bestanden. Einziger Fehler ist das bereits vorher rote „Gap markup“.
  - Alle 147 Testdateien einzeln: Nur die 8 bereits vorher roten Dateien schlagen fehl (widget_test „Gap markup“, form_learning, learning_groups, review_flow, language_selection, language_selection_ui, device_speech, personal_import_status). `personal_import_status` hängt; die Datei nutzt weder `SprachApp` noch `purchaseProvider`.
- `flutter analyze`: nur die zwei bekannten `avoid_print`-Hinweise in Tests.
- Release-APK Build 3 im Emulator, über eine angemeldete Build-1-Installation als Update (`-r`) eingespielt, gleiche Lage wie beim Empfänger:
  - Kaltstart `Status: ok`.
  - Ohne jede Eingabe billing-sync 1 s nach Start (HTTP 200, `bind_adapty_profile` und `sync_adapty_entitlement` 200).
  - Einstellungen: „Kostenlos freigeschaltet bis 1. Dezember 2026 · endet automatisch“, kein Store-Fehler, Version 1.0.0+3.
  - Abmelden entfernt Premium sofort.
- Testkonto anschließend entfernt: Adapty DELETE 204, Auth DELETE 200, erneute GETs 404, keine Entitlement- oder Bindungszeilen übrig. Die Code-Mails dieses Tests gingen an eine `+`-Adresse des Entwicklers.

### Auslieferung Build 3

`/Users/ardasayar/Desktop/Linglossa-Android-Test/Linglossa-Update-Build3.apk`

| Eigenschaft | Wert |
|---|---|
| Version | 1.0.0+3 (versionCode 3) |
| Paket | `com.example.sprachapp` |
| Größe | 325.624.689 Bytes |
| SHA-256 | `113dda6da3cb2a6d54e40a6fc146135dffd7c48bf5d489af59bbf6395dc9250e` |
| Signaturzertifikat | gleich wie bei Build 1 und 2: `fa211a61f6d7212427ac86359a6fe8acad0c0d9cb130bf9d09bc35da4b80508e` (v2 verifiziert) |
| Manifest | ohne `debuggable` |
| Konfiguration | dieselbe öffentliche wie zuvor, über eine temporäre Datei eingebunden und danach gelöscht |

In `libapp.so` stehen nur die Prüf-Literale `sb_secret_` und `service_role`, keine Schlüsselwerte. Build 2 liegt jetzt in `/Users/ardasayar/Desktop/Linglossa-Android-Archiv/Build-2`. Die neue `ANLEITUNG.txt` verlangt, alte APKs zu löschen und in den Einstellungen „Version 1.0.0+3“ zu prüfen.

### Grenzen

- Nicht auf dem physischen Gerät des Empfängers geprüft. Unbekannt sind dort die tatsächlich installierte Version, das Android-Modell, Batterie- und Netzwerkbeschränkungen und die Speicherung in Secure Storage.
- Der Token-Refresh einer seit mehr als einer Stunde bestehenden Sitzung wurde im Emulator nicht abgewartet. Die Sitzung des Empfängers stammt von 18:43 und wird beim nächsten Abgleich per Refresh-Token erneuert.
- Dass der Empfänger Build 1 nutzte, ist aus dem Servermuster und der Emulator-Nachstellung abgeleitet, nicht auf seinem Gerät beobachtet.
- Nach der Installation von Build 3 zeigt der Server einen neuen billing-sync-Aufruf für das Empfängerkonto (`observed_at` des Entitlements). Daran lässt sich der Erfolg ohne Zugriff auf das Gerät erkennen.
