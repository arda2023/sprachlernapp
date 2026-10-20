# Privater Inhaltsdownload – Diagnose und Fix · 18.10.2026

Ausgangslage (Nutzerbericht, „iPhone von Claus“, aktiver Inhalt `story_single_sentence_v1`,
Projekt `yevntxclpchapacqdizm`): Anmeldung und Updateanzeige funktionieren; nach
**Version herunterladen und prüfen** erscheint nur „Inhaltsaktion nicht abgeschlossen …“.
`content-release`-Logs zeigen nur Boot/Shutdown. Keine Cloudänderung, kein Deployment,
keine Geräteinstallation durch diesen Auftrag.

## Tatsächlicher Ablauf

| Schritt | Code | Netz |
|---|---|---|
| Button „Version herunterladen und prüfen“ | `content_updates_screen.dart` → `ContentUpdateController.download` → `_run` | – |
| Token | `ContentAuthRepository.accessToken` (Refresh nur < 60 s Restlaufzeit) | Auth nur bei Refresh |
| Downloadlink | `ContentReleaseClient.downloads` | `POST /functions/v1/content-release/<id>/download` |
| Übertragung | `ContentReleaseClient.bytes`, Größe/SHA256 in `ContentUpdateService.download` | signierte Storage-URL (kein Function-Aufruf) |
| Prüfung | `Isolate.run(validateDownloadedContent)` | – |
| Installation | `release.json`, Rename `.part`→Generation, `pending.json` | – |
| Aktivierung (separater Button) | Re-Autorisierung `latest`, `verifyGeneration`, Journal | `GET content-release` |

**„Erneut prüfen“** ruft `controller.check` auf, also nur `GET content-release?…` (Releaseabfrage).
Es wiederholt **keinen** Download. Nur wenn ein geprüfter Kandidat (`pending.json`) existiert,
wird dieser lokal erneut verifiziert. Nach dem fehlgeschlagenen Download existiert keiner.

## Wo Details verloren gingen (vor dem Patch)

1. `ContentUpdateController._run`: `catch (_)` ersetzt jeden Fehler durch den Sammeltext.
2. `ContentReleaseClient._json`: Status → zwei Sammeltexte, Server-`code` verworfen.
3. `ContentReleaseClient.bytes`: Storage-Status verworfen.
4. `ContentUpdateService.download`: `catch (_) … rethrow` ohne Schritt.

## Belegte Ursache

`download()` startete die Inhaltsprüfung mit einer Closure **innerhalb der Instanzmethode**:
`Isolate.run(() => validateDownloadedContent(path, data, old))`. Die Dart-VM sendet den
Closure-Kontext mit; er reicht bis zu `this` (Service → echter `HttpClient` mit offenen
Verbindungen/Futures, Provider-Callbacks mit `ref`). Ergebnis nach vollständigem Download:
`ArgumentError: Illegal argument in isolate message: object is unsendable`. Der Kandidat wird
gelöscht, der Fehler im Provider verschluckt. Die bisherigen Tests nutzten einen Fake-Transport
ohne nicht sendbare Objekte und konnten das nicht zeigen. Die Servertrennung passt dazu:
Downloadlink 200, Bytes laufen über Storage, der Fehler ist lokal.

Reproduktion (lokal, synthetisch):
- Probe mit echtem `ContentReleaseClient` gegen lokalen `HttpServer`, HEAD-Code:
  `PROBE ArgumentError: … Illegal argument in isolate message: object is unsendable - Library:'dart:async' Class: _Future`.
- Gegenprobe mit fertigem Regressionstest und zurückgesetzter Inline-Closure:
  `Illegal argument in isolate message: object is unsendable … _HttpServer` → Test FAIL; mit Fix PASS.

Nicht belegt: dass genau dies auf dem iPhone auftritt. Der Gerätepfad nutzt denselben echten
Client, die Wahrscheinlichkeit ist hoch, aber erst der Geräteversuch beweist es (siehe unten).
`test/data/baseline_adoption_pack_test.dart` validiert das echte Adoptionspack direkt
(ohne Isolate); der Paketinhalt ist dort nicht die Ursache.

## Änderungen

- **Fix** `content_update_service.dart`: Prüfung über Top-Level-`_validateInIsolate(path, data, old)`;
  auch `verifyGeneration` nutzt sie. Prüfumfang unverändert.
- **Diagnose** neu `content_update_diagnosis.dart`:
  - `ContentHttpException extends StateError`: alter Text, echter HTTP-Status, Servercode nur aus
    Allowlist (`AUTH_REQUIRED`, `READER_REQUIRED`, `NOT_FOUND`, `BACKEND_UNAVAILABLE`, `WORKER_LIMIT`,
    `InvalidJWT` …), sonst `SERVER_UNKNOWN`. Fehlerkörper höchstens 4 KiB gelesen, nur `code`/`error`.
  - `ContentAuthSessionException`: Token fehlt/Refresh scheitert → Schritt `auth`, `AUTH_SESSION`.
  - Lokale Codes: `ISOLATE_TRANSFER`, `ISOLATE_ERROR`, `FORMAT_INVALID`, `FILE_SYSTEM` (+ OS-Fehlernummer),
    `NETWORK`, `TLS`, `TIMEOUT`, `HTTP_PROTOCOL`, `STATE`, `ARGUMENT`, `UNEXPECTED`.
- Service merkt sich Schritt und Fehlerobjekt (`lastDiagnosis`/`lastError`), wirft den Fehler unverändert
  weiter. Schritte: `local_state`, `release_check`, `verify_pending`, `verify_existing`, `download_link`,
  `download_reserve`, `download_transfer`, `verify`, `install`, `reauthorize`, `close_readers`, `activate`;
  außerhalb des Service `setup`.
- Provider: `debugPrint('Inhaltsupdate fehlgeschlagen: …')` und `ContentUpdateState.diagnosis`.
  Seite zeigt im Fehlerzustand z. B. `Diagnose · Schritt: download_link · HTTP 403 · Server: READER_REQUIRED`
  oder `Diagnose · Schritt: verify · Lokal: ISOLATE_TRANSFER`. Kein HTTP-Wert bei lokalen Fehlern.
- Nie ausgegeben: Passwort, Token, Header, signierte URL, Antwortkörper, Pfade, E-Mail, Exception-Texte.
- Keine automatische Wiederholung; Auth, Freigabe, Hash-/Schema-/Inventarprüfung unverändert.

## Tests (synthetische Temp-Daten)

`test/data/content_update_diagnosis_test.dart` (echter `ContentReleaseClient`, lokaler HTTP-Server):
Erfolg Download→Prüfung im Isolate→„Erneut prüfen“ ohne erneuten POST→Aktivierung; 403/`READER_REQUIRED`;
500 mit E-Mail/Token im Körper → `SERVER_UNKNOWN`, nichts Geheimes im Text; 546 ohne JSON; Link 404;
Storage 400/`InvalidJWT` (kein Auth-Header an Storage); Tokenfehler `auth`; Hashfehler lokal ohne HTTP;
gescheiterte Generation 2 lässt aktive Generation 1, Dateibytes und synthetische user.db unverändert.
`test/content_update_diagnosis_ui_test.dart`: Diagnosezeile im Fehlerzustand.

| Befehl | Ergebnis | Exit |
|---|---|---|
| `flutter test --no-pub test/data/content_update_diagnosis_test.dart test/content_update_diagnosis_ui_test.dart test/data/content_update_test.dart test/data/content_auth_test.dart test/content_updates_ui_test.dart test/data/content_owner_barrier_test.dart test/data/baseline_adoption_pack_test.dart` | `00:10 +29 ~1: All tests passed!` (~1 = vorhandener Skip ohne lokale Realdatei) | 0 |
| `flutter test --no-pub` | `00:56 +360 ~1: All tests passed!` | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:12 +1: All tests passed!` (30-s-Limit unverändert) | 0 |
| `flutter analyze --no-pub` | `1 issue found`: vorbestehendes `avoid_print` in unveränderter, committeter `test/data/baseline_adoption_pack_test.dart:43` (5ec01f8); eigene Dateien ohne Befund | 1 |
| `git diff --check` | ohne Befund | 0 |

Ein erster Testlauf scheiterte, weil `testWidgets` in derselben Datei `HttpClient` durch einen 400-Mock
ersetzt; der Widget-Test liegt deshalb getrennt. Der Testserver verlangte anfangs fälschlich den Bearer
auch für Storage; korrigiert (und prüft jetzt, dass keiner gesendet wird). Kein Produktcode geschwächt.

## Nächster Geräteversuch (genau einer)

macOS (Terminal), Repository-Root, bestehende Signierung, App **nicht** löschen:

```sh
export SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Öffentlicher anon/publishable key des Projekts: '; read -r SUPABASE_ANON_KEY; export SUPABASE_ANON_KEY
flutter run -d 00008110-001651611E01401E --dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
```

Windows (PowerShell): nicht möglich, iOS-Installation nur auf macOS.

Bedienung: **Einstellungen → Inhaltsupdates → Nach Updates suchen → Version herunterladen und prüfen**
(ggf. vorher mit Passwort anmelden). Zu liefern: entweder „Geprüft. Nach Ende der Übung aktivieren.“
(Fix wirksam, erst danach separat aktivieren) **oder** die Zeile `Diagnose · …` von der Seite bzw.
`Inhaltsupdate fehlgeschlagen: …` aus dem Terminal. Kein Geräte-PASS ohne diesen Nachweis.
