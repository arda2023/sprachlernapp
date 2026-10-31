# Linglossa: Rückmeldung zur iOS-Kaufdiagnose (Claude)

Stand: 31.10.2026, ca. 10:45 Europe/Berlin. Antwort auf `docs/HANDOFF-ios-purchases-2026-10-31.md`. Branch `ui-polish-launch-screen`, HEAD weiterhin `d2c276d`. **Nichts committet.**

## 1. Ergebnis

**Storepreise laden, der Sandbox-Kauf läuft bis zum serverbestätigten Status.** Auf dem iPhone von Claus zeigt die Paywall Monat (9,99 €) und Jahr (49,99 €) aus StoreKit. Kaufblatt mit Sandbox-Hinweis und Konto `ardasa716+linglossa-sandbox1@gmail.com`; Jahresabo gekauft. Die App zeigt „Premium-Testabo aktiv (Sandbox) bis 31. Oktober 2026“. Dieser Text erscheint nur nach `billing-sync` mit aktivem, nicht abgelaufenem Sandbox-Entitlement (`sandboxTestAccessAllowed`).

## 2. Ursache von Adapty 1000

Ausgeschlossen (geprüft):

- Signiertes Binary: Bundle-ID `com.ardasayar.linglossa`, explizite App-ID `W27Z6DNPT3.com.ardasayar.linglossa`, Profil gültig bis 31.10.2027.
- Keine StoreKit-Konfigurationsdatei im Projekt/Schema.
- App-ID im Developer-Portal: In-App Purchase aktiv.
- Adapty: Paywall enthält beide Produkte, Produkt-IDs korrekt.
- Jahresabo: Deutschland gespeichert (1 von 175), Preis Deutschland 49,99 €.
- Monatsabo: Deutschland, 9,99 €.

**Gefundene Lücke:** Die App selbst hatte unter Vertrieb → Preise und Verfügbarkeit **keinen Preis und kein Land** („Preise hinzufügen“, „Verfügbarkeit konfigurieren“). Mit Zustimmung des Betreibers um ca. 10:12 gesetzt:

- Preis: kostenlos (0,00, Basisland USA, 175 Regionen).
- Verfügbarkeit: **nur Deutschland**, Status „Verfügbar bei App-Veröffentlichung“.

Etwa 2 Minuten danach (10:14, neuer Build) kamen die Preise. Das Jahresabo kam sofort, das Monatsabo erst einige Minuten später (Apple-Verzögerung; die App filterte nichts, siehe Debug-Log unten). Ein Kausalbeweis ist das nicht; zeitlich ist es der einzige Unterschied. Der vorher aktivierte Vertrag (09:40) kann zusätzlich beigetragen haben.

## 3. Serverseitig bestätigt

- Supabase-Logs `adapty-webhook-sandbox`: 2× POST 200 um 10:16:07 (Kaufzeitpunkt).
- `adapty-webhook` (Production): keine Aufrufe. Umgebungen getrennt.
- Nach Löschen und Neuinstallation: Premium-Sandbox-Status wieder vorhanden, ohne neue Anmeldung (Supabase-Sitzung liegt im iOS-Schlüsselbund und überlebt das Löschen).

## 4. Code-Änderungen (nicht committet)

| Datei | Änderung |
|---|---|
| `lib/screens/onboarding/paywall_screen.dart` | „Lingvist Premium“ → „Linglossa Premium“; Fehlertext ohne Produkte nur noch einmal (Statuszeile unterdrückt ihn, wenn die Fehlerkarte sichtbar ist); deutsches Ablaufdatum; **Schließen-Fehler behoben** (siehe 5) |
| `lib/widgets/subscription_tile.dart` | deutsches Ablaufdatum |
| `lib/widgets/date_format.dart` (neu) | `formatDateDe`: „12. März 2027“ (App nutzt kein `flutter_localizations`; `formatMediumDate` lieferte „Sat, Oct 31“) |
| `lib/data/billing/purchase_gateway.dart` | nur `kDebugMode`: loggt gelieferte Produkt-IDs und Skip-Grund je Produkt. Keine Konto-/Schlüsseldaten |
| `lib/screens/onboarding/onboarding_screen.dart`, `lib/widgets/launch_splash.dart`, `onboarding_art.dart` | Marke „Lingvist“ → „Linglossa“; Klasse `LingvistMark` → `LinglossaMark` (GitNexus-`rename`, 4 Stellen) |
| `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml` | Anzeigename „Linglossa“ (auf ausdrückliche Anweisung, trotz Plattform-Ordner-Regel; nur diese Zeilen) |
| `docs/redesign/design-system.md` | drei Stellen Lingvist → Linglossa (Arbeitsname-Vermerk entfernt) |
| `test/onboarding_test.dart` | neue Tests: Fehler nur einmal; exaktes deutsches Datum; Paywall schließt bei Premium (schon aktiv / während Einblendung / nach Öffnen / unter offenem Blatt) |
| `test/data/context_quality_applied_test.dart` | veralteter Test angepasst: Wort und Satzzeichen werden seit 842a26f getrennt gerendert („clean“ statt „clean.“) |

Unverändert gelassen: `lib/domain/srs_state.dart:128` (verweist auf Lingvists Kategorienmodell aus `PRODUCT.md`). `MaterialApp(title: 'Sprachapp')` in `lib/main.dart` ist noch nicht umbenannt.

## 5. Paywall ließ sich nicht schließen

Symptom: X und „Kostenlos weiterlernen“ ohne Wirkung, nachdem „Premium-Testabo aktiv (Sandbox).“ erschienen war. Diagnose per Debug-Log auf dem Gerät: `_leaving=true`, Paywall war beim Tippen oberste Route. Ursache: Der `ref.listen`-Autoschluss rief `_finish` auf, während eine andere Route über der Paywall lag; `maybePop()` schloss nur diese, `_leaving` blieb gesetzt. Fix: `_finish` schließt per `popUntil(route)` + `pop()` die eigene Route samt allem darüber. Regressionstest schlägt mit altem `maybePop()` fehl, mit Fix nicht. Auf dem Gerät bestätigt. Diagnosezeilen wieder entfernt.

## 6. Prüfungen

- `flutter test`: **742 bestanden, 9 übersprungen, 0 fehlgeschlagen.**
- `flutter analyze`: nur bekannter `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43`.
- GitNexus-Impact vor jeder Änderung: LOW, außer `LingvistMark` (MEDIUM, per `rename`) und `AdaptyPurchaseGateway.loadCatalog` (UNKNOWN wegen Interface; Textsuche: einziger Aufrufer `PurchaseController.load`).
- `detect_changes --scope all`: HIGH, überwiegend durch die ältere uncommittete Auth-/Billing-/Übersetzungsarbeit. Index ist veraltet (kennt `LinglossaMark` und die untracked Billing-Dateien nicht): **vor Commit neu indexieren und erneut prüfen.**

## 7. Noch offen

Technisch:

1. **Verlängerungs-Webhook:** Sandbox-Jahr ≈ 1 Stunde, Verlängerung ca. 11:16 erwartet. Prüfung um 11:20 geplant (Supabase-Logs `adapty-webhook-sandbox`); Ergebnis zum Zeitpunkt dieses Berichts offen.
2. **Knopf „Käufe wiederherstellen“** selbst ungetestet (Konto blieb angemeldet). Ablauf/Kündigung und Kontowechsel ebenfalls ungetestet.
3. **Produktentscheidung:** Soll man nach Löschen und Neuinstallation angemeldet bleiben (Schlüsselbund)? Üblich ist, beim ersten Start nach Neuinstallation die Sitzung zu verwerfen.
4. `MaterialApp.title` noch „Sprachapp“.
5. Debug-Warnung `ImpellerValidationBreak … SetInheritedOpacity` häufig im Log; ohne Bezug zum Kauf, nicht untersucht.
6. Debug-Launch: `flutter run` im Hintergrund + Hot Reload/Restart hängt, solange die App nicht im Vordergrund ist; ein abgebrochener Restart hinterließ „Invalid kernel binary“ → dann neu bauen.

Betreiber (nicht technisch lösbar):

- Prüf-Screenshot für beide Abos hochladen (Paywall mit beiden Preisen).
- EU-Händlerstatus nach DSA in App Store Connect.
- Rechtstexte freigeben/veröffentlichen (`LEGAL_DOCUMENTS_APPROVED=false` bleibt).
- Später: weitere Länder für App und Abos, falls gewünscht (derzeit nur Deutschland).

## 8. Geräte-/Logpfade dieser Sitzung

Logs liegen im Claude-Scratchpad (`…/scratchpad/iphone-run-3.log`), flüchtig. Laufender Start (macOS):

```sh
flutter run --debug -d 00008110-001651611E01401E --dart-define-from-file=config/adapty.local.json
```

## 9. Nachtrag: Startzeit und Sprachwechsel (31.10.2026, nachmittags)

Messung im **Profile-Build** (Geschwindigkeit wie App Store) auf dem iPhone, vorher:

- Erster Start nach Neuinstallation: **27,1 s** bis zum Onboarding. Ursache: `main` aktivierte vor `runApp` alle vier gebündelten Sprachpakete (pt-BR, nb, it, es; je 6,3–7,0 s: Asset laden, schreiben, SHA-256, volle Historienprüfung, Aktivierung), auch wenn Englisch gelernt wird.
- Zweiter Start: Paketprüfung 0,08 s, Startseite nach 2,5 s. Die vom Betreiber gezählten 7 s waren der Debug-Modus.

Umgesetzt:

- `ContentPackInstaller.forApp` aktiviert das gebündelte Release einer Sprache einmal pro Prozess beim ersten Öffnen dieser Sprache (vor jedem Reader dieser Sprache). `main` installiert nichts mehr vorab; `ContentStartupGate` wird von `main` nicht mehr verwendet (Klasse bleibt).
- Bootstrap-SHA-256 im Installer läuft per `Isolate.run`, nicht mehr auf dem UI-Isolate.
- `_Start` (`lib/main.dart`) lädt die Startseitendaten während des Onboardings vor (`ref.listen` auf Decks, Fortschritt, Streak, Wortzähler).
- `LaunchCurtain` kann zurückkehren: Bei Sprachwechsel blendet das Logo über der App ein (App bleibt per `GlobalKey` gemountet) und hebt sich, sobald `languageSelectionProvider.switching` aus ist, `activeContentKeyProvider` nicht lädt und alle vier Startseitendaten für den aktuellen Schlüssel stabil sind (`watchContentStable`). Sicherheitsgrenze 30 s.
- Nativer Startbildschirm: Farbe `LaunchBackground` (hell `#F6F5F2`, dunkel `#0D0F14`) statt Weiß.
- Neuer Test `test/launch_curtain_test.dart`.

Nachher (Profile-Build, gemessen):

- Erster Start: Onboarding nach **0,09 s** bereit (sichtbar nach der 1,1-s-Logoanimation). Nach dem Onboarding keine Ladekreise (Betreiber bestätigt).
- Erster Wechsel in eine nicht installierte Sprache (Spanisch): ca. 7 s Logo. Wechsel in installierte Sprache: Spanisch 3,7–3,9 s, Englisch 2,3 s.
- Doppeltes Logo beim Wechsel behoben (Ursache: `switching` endete, bevor `activeContentKeyProvider` neu berechnet war; die Ansichten galten kurz mit alten Werten als fertig).

Prüfungen: `flutter test` 743 bestanden; `flutter analyze` nur bekannter `avoid_print`. Impact: `forApp`/`install` von GitNexus als HIGH gemeldet (Namenskollision mit Supabase-Modul im Ergebnis, aber tatsächlich zentraler Inhaltspfad), daher auf dem Gerät mit Neuinstallation und beiden Wechselrichtungen geprüft. Temporäre Zeit-/Diagnosezeilen wieder entfernt.

Offen: Die volle Inhaltsprüfung (Kopie + SHA-256 + Historienprüfung) läuft weiterhin bei jedem Kaltstart (~2,5 s bis Startseite). Ein über Starts gespeicherter Prüfnachweis würde das verkürzen, schwächt aber die bewusste „Nachweis pro Prozess“-Regel; Betreiberentscheidung. Den dunklen nativen Startbildschirm hat der Betreiber nicht gesondert bestätigt.
