# Adapty-Anbindung – Linglossa

Stand: 31.10.2026. **Sandbox-Käufe sind nachgewiesen; ein öffentlicher Verkaufsstart ist noch nicht freigegeben.** Aktueller Abschlussstand, neue Korrekturen und konkrete Releasehindernisse: [Zahlungsabschluss](docs/payment-completion-2026-10-31.md). Die weiter unten datierten Protokolle beschreiben ihren jeweiligen damaligen Prüfstand.

## Konfiguration

- Bestehende Adapty-App „Sprachapp“, iOS zuerst; Android bleibt deaktiviert.
- Bundle-ID: `com.ardasayar.linglossa`, Apple-Team `W27Z6DNPT3`.
- Custom Paywall „Linglossa Premium“, Placement und Access Level `premium`.
- Monat: `com.ardasayar.linglossa.premium.monthly`.
- Jahr: `com.ardasayar.linglossa.premium.yearly`.
- Monat und Jahr liegen in derselben Apple-Abo-Stufe. Jahr ist vorausgewählt.
- StoreKit liefert die lokalisierten Preise; kein allgemeiner Trial oder Einführungsrabatt. Die Produktentscheidung bleibt 9,99 €/Monat oder 49,99 €/Jahr.
- Apple→Adapty-Server-URLs wurden zuvor in beiden Apple-Umgebungen bestätigt. Adapty→Supabase-Webhooks sind gespeichert; nach Neuladen wurden beide URLs und beide passenden Schlüssel per Hashvergleich bestätigt.

## App

`adapty_flutter` 4.1.1 startet unabhängig von lokalen Inhalten. Apple, Google und E-Mail-Code verwenden Supabase Auth; Sitzungen liegen im sicheren Gerätespeicher. Öffentliche Registrierung vergibt keine internen Inhalts-/Publisher-Rollen.

Adapty wird an die bestätigte Supabase-Konto-ID gebunden. Konto- und Storeoperationen sind serialisiert; ein vor Beginn eines Kaufs gewechseltes Konto verwirft die alte Operation. Alte Profilantworten dürfen keine Rechte auf das neue Konto übertragen.

Die Paywall lädt die beiden erlaubten Storeprodukte, behandelt Kaufabbruch, ausstehende Zahlung, Wiederherstellung, Serverfehler und Retry. Später bestätigte Zahlungen lösen erneut einen Serverabgleich aus. Eine bekannte Ablaufzeit beendet den sichtbaren aktiven Status und löst eine neue Prüfung aus. Wiederherstellung wird erst nach Serverbestätigung als erfolgreich angezeigt. Einstellungen enthalten Aboverwaltung, Wiederherstellung und die offline erreichbaren Rechtstexte.

Werbe-IDs, IP-Erfassung und Attribution sind im SDK deaktiviert. Keine Namen/E-Mails werden als Adapty-Profilattribute übermittelt. Die Serverzuordnung verwendet ausschließlich die Konto-UUID.

## Verifizierte Serverberechtigung

Bereitgestellt im Supabase-Projekt `yevntxclpchapacqdizm`:

- `billing-sync`: authentifizierter POST `{}`; die Konto-ID stammt aus Supabase Auth, niemals aus dem Clientkörper. Bestätigtes, nicht anonymes Konto erforderlich.
- `adapty-webhook` und `adapty-webhook-sandbox`: getrennte Shared Secrets und Umgebungen; unbekannte oder ungebundene Profile erhalten keine Rechte.
- `delete-account`: aktuelle, bestätigte Sitzung mit frischer signierter Authentifizierung; zusätzliche explizite Löschbestätigung und Bindung an das angezeigte Konto.
- `lookup-word` / `translate-sentence`: aktualisierter serverseitiger Kontingentpfad.
- Migrationen `20261031000001`, `20261031000002`, `20261031000003` sind angewendet.

`app.verified_entitlements` ist servergeschrieben, mit lesendem RLS nur für das eigene Konto. Nur erlaubte Produkte aus **Production** autorisieren bezahlte Serverkontingente. Webhook-Payloads vergeben keine Rechte direkt: der Server liest das aktuelle Adapty-Profil erneut. Ereignisse sind idempotent und ältere Beobachtungen dürfen neuere Zustände nicht überschreiben. Natürlicher Ablauf wird bei jeder Kontingentprüfung berücksichtigt; Erstattungs-/Verlängerungsereignisse werden über die gespeicherte Webhook-Verbindung empfangen; die tatsächliche Store-Ereigniszustellung bleibt Teil der Geräteabnahme.

Server-Secrets liegen ausschließlich in Supabase und einer privaten lokalen Datei außerhalb des Repositories. SDK-/öffentliche Auth-Konfiguration kommt aus der ignorierten `config/adapty.local.json`. Keine Server-Schlüssel gehören in Dart-Defines oder die App.

## Übersetzungskontingente

- Bestätigtes Konto: fünf einmalige erfolgreiche neue Wort-/Satzübersetzungen, sprachübergreifend.
- Verifiziertes Production-Premium: 500 je am Kaufdatum verankertem Monat. Ein Jahresabo erhält monatliche Einheiten, nicht 6.000 auf einmal.
- UTC-Monatsgrenzen, Monatsende und Schaltjahre sind berücksichtigt. Ein Tarifwechsel erzeugt kein separates zweites Guthaben desselben Kontingentzeitraums.
- Cachetreffer werden nicht belastet. Reservierungen verhindern parallele Überziehung; erfolgreiche Speicherung belastet einmal, Fehler geben die Einheit frei.
- Schutzgrenzen bleiben fünf Versuche pro Minute/Konto und 1.000 pro Tag global; kein zusätzlicher täglicher Premium-Verbrauchsdeckel.
- Private Übungskartenerstellung behält ihren bestehenden internen Berechtigungs-/Versuchspfad. Diese Änderung öffnet keine redaktionellen oder Publisher-Funktionen.

## Kontolöschung und Rechtstexte

Einstellungen → Inhalte und Hilfe → Konto dauerhaft löschen verlangt `LÖSCHEN`. Bei älterer Authentifizierung erfolgt eine erneute Anmeldung innerhalb der App, ausschließlich für dasselbe Konto. Der Server entfernt das gebundene Adapty-Profil und den Auth-Nutzer; persönliche Tabellen und Leserrechte werden bereinigt. Veröffentlichungshistorie bleibt unverändert, aktive Publisher müssen ihre Berechtigung zuerst übertragen. Lokale Lernstände bleiben erhalten. Ein Apple-Abonnement muss separat gekündigt werden. Fehlt ein verwendbarer Apple-Widerrufstoken, zeigt die App die manuellen Schritte gemäß Apple TN3194; automatischer Apple-Tokenwiderruf ist nicht implementiert.

Datenschutz, Bedingungen und Impressum sind **nicht freigegebene Entwürfe** in `lib/screens/legal/` und `assets/legal/`. Quellen und offene Betreiber-/Anbieterprüfungen stehen in `docs/legal-documents-review.md`. Es wurde keine öffentliche Rechtswebsite veröffentlicht.

## Tests und tatsächliche Grenzen

Nachweise vom 31.10.2026:

- Integrierte Flutter-Suite: **159 Tests bestanden** (Konto, Anmeldung, native Adapter, Kauf/Restore, SDK-Methodenkanal, Serverparser, Sandbox-Gates, Ablauf, Rechtstexte und bestehende App-Widgets).
- Deno: **44 Tests mit Typprüfung bestanden**, einschließlich Authentifizierung, Umgebungen, Webhooks, Cache und Kontolöschung. Die breitere bestehende Shared-Suite bestand zur Laufzeit mit 106 Tests und drei ausgelassenen Tests (`--no-check`); ihre vollständige Typprüfung scheitert an einem bereits vorhandenen untypisierten Parameter in `personal_learning_test.ts:154`.
- PostgreSQL 17 in einem isolierten Testcontainer: Migrations-/Berechtigungs-/Cache-/Kontingent-/Lösch-Assertions bestanden. pgTAP ist dort nicht installiert; Assertions liefen ohne dessen Berichtshülle. Zwei parallele Anfragen bei 499 belasteten Premium-Einheiten ergaben genau einmal `claimed` und einmal `quota`.
- Live-Supabase-/Adapty-Smoke-Test: eigens erstelltes Testkonto ohne E-Mail-Versand, Anmeldung, Profilbindung, inaktiver Status, eigener RLS-Zugriff, abgewiesene Rechtefälschung, Kontingentreservierung/-freigabe und anschließende Konto-/Adapty-Löschung bestanden. Keine bestehenden Nutzer wurden gelöscht; keine echten KI-Anfragen oder Zahlungen ausgelöst.
- Webhook-Endpunkte: falsches Secret → HTTP 401, authentifizierter Verifikationsaufruf → HTTP 200 in beiden Umgebungen.
- Analyse: keine neuen Fehler/Warnungen; vorhandener `avoid_print`-Infohinweis im Baseline-Test.
- iOS-Simulator-Build bestanden; signierter iPhone-Build anschließend in 293,7 Sekunden bestanden. Installation und Appstart auf „iPhone von Claus“ bestätigt; Dart-VM-Service erreichbar. Dies war der Stand vor dem später bestätigten Sandbox-Jahreskauf.

GitNexus findet in der Gesamtänderung hohe Auswirkung auf Anmeldung, Kauf und Übersetzung. Neue SQL-/dynamische Aufrufe waren teilweise nicht im Graph auflösbar und wurden zusätzlich anhand der Quellen und tatsächlicher Serveraufrufe geprüft. Der Graph ist kein Vollständigkeitsbeweis. Keine Commits erstellt.

## Stand der Geräteabnahme und offene Zahlungstests

1. Sandbox-Jahreskauf am 31.10.2026 um 10:16 Uhr Europe/Berlin bestätigt (Claudes Übergabebericht); die Serverdatenbank bestätigt `subscription_started` und `access_level_updated` um 09:16 UTC. Der Benutzer hat „Käufe wiederherstellen“ ausgeführt und „Premium-Testabo aktiv (Sandbox)“ bestätigt. Neuinstallation mit fortbestehender Sitzung wurde von Claude berichtet; der kombinierte Wiederholungs-/Restore-Test bleibt offen.
2. App auf dem richtigen iPhone starten; mit dem vorgesehenen bestätigten Testkonto anmelden. Das bekannte Testkonto ist serverseitig für Sandbox freigegeben; neue Konten brauchen eine eigene gezielte Testfreigabe.
3. Sandbox-Apple-Account einrichten, Kaufblatt mit Sandbox-Hinweis bestätigen, Ereignis und aktiven Access Level in Adapty prüfen.
4. Wiederherstellung nach Neuinstallation sowie spätere Bestätigung, Verlängerung, Kündigung/Ablauf und Kontowechsel auf dem Gerät prüfen. Automatisierte Tests ersetzen diese Abnahme nicht.

Die aktive lokale Debug-Konfiguration fordert `ENABLE_SANDBOX_PURCHASES=true` an. Sandbox-Testzugriff benötigt zusätzlich die serverseitige Testerfreigabe, ein geprüftes aktives Sandbox-Profil und gültige Ablaufzeit. Er wird ausdrücklich als „Premium-Testabo aktiv (Sandbox)“ angezeigt. Er vergibt keine Production-Berechtigung und keine bezahlten KI-Kontingente. Release-Builds ignorieren die Debug-Freigabe.

`LEGAL_DOCUMENTS_APPROVED=false` bleibt aktiv. Vor einem öffentlichen Verkauf fehlen weiterhin die Freigabe/Veröffentlichung der Rechtstexte und die Geräteabnahme. Die übrigen Freemium-Inhaltsfreigaben und Inhalts-Mindestmengen aus dem Produktplan sind ein separater Releasepunkt; ein geprüfter Kaufweg beweist nicht deren Umsetzung.

## Starten

macOS, iPhone-Build/Start:

```text
flutter run --dart-define-from-file=config/adapty.local.json
```

Flutter-Parameter sind auf Windows/PowerShell identisch; iOS-Builds erfordern jedoch macOS/Xcode. Android-Verkäufe sind für diese erste Integration deaktiviert. Leere, nicht geheime Konfigurationsvorlage: `config/adapty.example.json`.

## Korrektur geteilter Adapty-Profile (31.10.2026)

Ein anonymes Profil mit geerbtem Access Level sendete `access_level_updated` mit `customer_user_id: null`. Das zugehörige bekannte App-Konto stand in `profiles_sharing_access_level`. Der ursprüngliche Handler verlangte ausschließlich eine direkte Bindung des Ereignisprofils; der Sandbox-Endpunkt antwortete im Live-Replay mit `503 PROFILE_NOT_BOUND`.

Der Handler verarbeitet jetzt diesen anonymen Sonderfall über bereits vorhandene Bindungen der geteilten Profile. Kunden-ID und gespeicherte Bindung müssen übereinstimmen; anschließend liest `reconcileWebhook` das Zielkonto erneut bei Adapty und prüft die Profil-ID. Der Payload allein vergibt keine Rechte, neue Bindungen werden nicht erzeugt. Identifizierte Ereignisse benötigen weiterhin ihre direkte Bindung. Mehrere bekannte Zielkonten erhalten getrennte, stabile Ereignisschlüssel; unbekannte Profile und Speicherausfälle bleiben bei fehlendem Ziel wiederholbar.

Nachweise: 16 gezielte Deno-Tests mit Typprüfung bestanden; beide Webhook-Einstiege und `billing-sync` mit `deno check` geprüft. Sandbox nach Bereitstellung: Replay der betroffenen Ereignisform → `200 {"ok":true,"duplicate":false}`, Wiederholung → `200 {"ok":true,"duplicate":true}`. Die Server-Ereignistabelle bestätigt die Verarbeitung für das gebundene Konto um 10:13:37 UTC. Das Replay ist ein gezielter Diagnosetest und kein Nachweis einer automatischen Store-Verlängerung oder einer erneuten Adapty-Zustellung.

Quellen: [Webhook-Felder](https://adapty.io/docs/webhook-event-types-and-fields), [Geteilter Zugriff](https://adapty.io/docs/sharing-paid-access-between-user-accounts). Lokale private Sicherung einschließlich ursprünglicher Serverquellen liegt außerhalb des Repositories unter `~/.codex/private/linglossa/backups/20261031-105452/`.

### Automatische Verlängerung und früher Empfang

Die Datenbank bestätigt inzwischen ein echtes `subscription_renewed` mit Ereigniszeit 31.10.2026 10:16:03 UTC. Die neue Ablaufzeit beträgt 11:16:03 UTC (=12:16:03 Europe/Berlin). Dieses Ereignis wurde bereits um 10:15:21 UTC empfangen, also vor Beginn des neuen Zeitraums. Wegen des zukünftigen `purchased_at` hatte die frühere Berechnung vorübergehend `is_active=false` gespeichert.

`deriveEntitlement` verwendet bei fehlendem explizitem `starts_at` jetzt zuerst `originally_purchased_at` aus dem servergelesenen Access Level bzw. der zugehörigen Subscription. Ein expliziter zukünftiger Start bleibt gesperrt; Ablauf und Umgebung werden weiterhin geprüft. Der Regressionstest reproduziert die frühe Jahresverlängerung und prüft diese Sperren. Korrektur in `billing-sync` und beiden Webhooks bereitgestellt. Eine frische Datenbankabfrage bestätigt inzwischen `is_active=true`, ursprünglichen Kaufbeginn 09:16:03 UTC und Ablauf 11:16:03 UTC. Der erneute UI-Restore bleibt offen. Das physische iPhone14Plus wurde nach Abziehen des Kabels als `localNetwork`/`paired`/`connected` erkannt und Linglossa erfolgreich über Flutter auf dem ausdrücklich als „wireless“ erkannten Gerät gestartet.

## Zusammenfassung der Geräteprüfungen (31.10.2026, bis ca. 12:39 Europe/Berlin)

- Jahresabo gekauft; automatische Verlängerung als echtes `subscription_renewed` am Server bestätigt. Nach Kündigung `will_renew=false`; nach Ablauf Oberfläche und Server inaktiv.
- App gelöscht und über WLAN neu installiert: Onboarding erneut angezeigt, bestehende Anmeldung erhalten. Danach Abmeldung/erneute Anmeldung und aktiver Teststatus bestätigt, mit frischem Serverabgleich.
- Für den Monatskauf war die zunächst wiederverwendete App-Datei ungeeignet: lokales Build-Gate sperrte neue Käufe. Frisch aus dem aktuellen Quellstand gebauter Debug-Build mit `ENABLE_SANDBOX_PURCHASES=true`, `LEGAL_DOCUMENTS_APPROVED=false` lief erfolgreich; JIT-Modus und aktivierte Assertions der laufenden VM geprüft.
- Monatsabo als Sandbox-Produkt am Server bestätigt. Nach Kündigung und Ablauf inaktiv, Verlängerung aus.
- Wechsel auf ein zweites bestätigtes App-Konto: Benutzer bestätigt richtige Adresse und inaktiven Premiumstatus; Server bestätigt zwei getrennte Profilbindungen. Das ursprüngliche Abo war dabei schon abgelaufen; das zweite Konto ist nicht Sandbox-freigegeben. Daraus folgt keine Abnahme der Kaufübertragung zwischen zwei freigegebenen Konten bei aktivem Abo.
- Kaufabbruch auf ausdrücklichen Benutzerwunsch nicht manuell geprüft.
- Vor der Neuinstallation wurden Library und Documents privat gesichert: 68 Dateien, 147604561 Bytes, acht SQLite-Integritätsprüfungen erfolgreich. Frühere lokale Einstellungen und fehlende Sprachpakete wurden anschließend selektiv zurückgespielt; eine zwischenzeitlich hinzugekommene Karte und aktuelle SDK-/Auth-Daten blieben erhalten. SHA256-Rückleseprüfung der Gerätedatenbank und SQLite-Integritätsprüfung erfolgreich, fünf Sprachpakete vorhanden.

Diese Ergebnisse betreffen Sandbox und ersetzen keine Production-/App-Review-Freigabe. Rechtstexte bleiben Entwürfe, öffentliche Kauf-Freigabe ist nicht erteilt. Änderungen sind privat gesichert, nicht als Git-Commit zusammengefasst.
