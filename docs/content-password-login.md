# Passwortanmeldung für private Inhalte

## Änderungsplan und Dateigrenze

Ausgangspunkt: `f34992d`, Windows-Checkout `C:\Users\ardas\Music\sprachapp`.
Vor der Änderung gelesen: Publisher-OTP/Refresh/Logout, lokale Cookie-/CSRF-Sitzung,
Editor-Service, Browsersteuerung, Flutter-Authrepository mit Secure Storage und
Updatecontroller/-maske. Keine neue Autharchitektur, keine Migration.

1. `pipeline/src/sprachpipe/editor/publisher.py`: Passwort-Grant über Supabase Auth;
   vorhandenen Session-/Refresh-/Logoutpfad weiterverwenden, sichere Fehlermeldungen.
2. `pipeline/src/sprachpipe/editor/server.py`: CSRF-geschützte POST-Route;
   Zugangsdaten weder in URL noch in Requestcache oder Fehlerausgabe behalten.
3. `pipeline/src/sprachpipe/editor/web/{app.js,index.html,style.css}`:
   Passwortformular mit klarer Aktion, maskiertem Feld und expliziter OTP-Alternative.
4. `lib/data/content/content_auth_repository.dart`,
   `lib/presentation/providers/content_update_provider.dart`,
   `lib/screens/settings/content_updates_screen.dart`: vorhandener Supabase-Client,
   Sessionpersistenz, sichere Fehlertexte und Löschen des Passwortfelds.
5. Gezielte Python-, HTTP-, JS-, Dart- und Widgettests; isolierte lokale
   Supabase-Integration, wenn der vorhandene Docker-Stack erreichbar ist.
6. Getrennter interaktiver Adminhelfer in `pipeline/scripts/`, diese Anleitung,
   Verweise im Editorvertrag/Paket-3-Bericht und gezielter NEXTSTEPS-Nachtrag.

Bestätigt vorhanden: alle im Auftrag genannten Pfade. `AGENTS.md`, `CLAUDE.md`
und `editor/service.py` bleiben unverändert; ihre bestehende Anbindung genügt.
Fremde Arbeitsbaumänderungen bleiben erhalten und werden nicht mitcommittet.

## Einmalig: Passwort des bestehenden Cloudbenutzers setzen

Ziel ist ausschließlich Projekt **sprachapp**, Ref `yevntxclpchapacqdizm`,
Benutzer `2af98709-72e6-4f38-b36c-997473e9eb48`. Keine Registrierung nötig.
Der folgende Schritt wird **vom Nutzer selbst** ausgeführt; in diesem Auftrag
wird weder ein Cloudpasswort noch Cloudkonfiguration verändert.

Offizielle Dokumentation, geprüft am 16.10.2026:

- [Users im Dashboard ansehen](https://supabase.com/docs/guides/auth/managing-user-data):
  Projekt öffnen → Authentication → Users → die genannte UID öffnen; E-Mail,
  Bestätigungsstatus und Sperrstatus prüfen.
- [Passwortbasierte Anmeldung](https://supabase.com/docs/guides/auth/passwords):
  die Anmeldung eines vorhandenen Kontos benötigt keine OTP-Mail. Registrierung
  und mailbasierte Wiederherstellung sind getrennte Abläufe.
- [Administratives Passwortsetzen](https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid)
  ist offiziell über Auth Admin dokumentiert. Die Dashboarddokumentation belegt
  keinen direkten administrativen Passwortsetzen-Button für bestehende Nutzer.
  Deshalb wird hier kein solcher Button versprochen und kein Reset-Mailweg empfohlen.
- Der getrennte lokale Helfer verwendet den entsprechenden offiziellen
  [Auth-Endpunkt `PUT /admin/users/<user_id>`](https://github.com/supabase/auth#post-put-adminusersuser_id).

Den lokalen Adminhelfer nur in einem eigenen interaktiven Terminal starten,
ohne Terminalaufzeichnung, Debugproxy oder Shell-Transcript. Er hat keine
Kommandozeilenargumente für Secrets und liest weder `.env` noch Editorconfig.
Projektref und erwartete E-Mail werden geprüft; Adminschlüssel und Passwort
werden verdeckt eingelesen. Verwendbar ist der serverseitige Secret-Key oder
Legacy-Service-Role-Key des Zielprojekts aus dessen API-Keys-Einstellungen.
**Diesen Schlüssel niemals in Editor-/App-Variablen eintragen.**

Windows (PowerShell), aus dem Repository:

```powershell
pipeline\.venv\Scripts\python.exe pipeline\scripts\set_content_user_password.py
```

macOS (Terminal), aus dem Repository:

```sh
pipeline/.venv-macos/bin/python pipeline/scripts/set_content_user_password.py
```

Der Helfer liest nur die festgelegte UID und aktualisiert nur deren Passwort.
Er legt keine Identität an, verändert keine Rollen, Sperren oder Bestätigungsregeln
und versendet keine Mail. Bei unbestätigter Adresse oder Sperre bricht er ab:
zuerst den Status dieses konkreten Kontos administrativ klären; nicht global
E-Mail-Bestätigung abschalten. Keine direkten SQL-Änderungen an Passworthashes.
Ein erfolgreicher Passwortwechsel kann bestehende Refresh-Sessions ungültig
machen; bei Bedarf in Editor und App neu anmelden.

## Windows: Editor starten und anmelden

Im Repository, mit vorhandener Pipeline-Umgebung und öffentlichem Projektkey:

```powershell
Set-Location C:\Users\ardas\Music\sprachapp
$env:SPRACHAPP_SUPABASE_URL = 'https://yevntxclpchapacqdizm.supabase.co'
$env:SPRACHAPP_SUPABASE_ANON_KEY = Read-Host 'Öffentlicher anon/publishable key des Projekts'
pipeline\.venv\Scripts\python.exe -X utf8 -m sprachpipe.editor
```

macOS (Terminal):

```sh
export SPRACHAPP_SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Öffentlicher anon/publishable key des Projekts: '
read -r SPRACHAPP_SUPABASE_ANON_KEY
export SPRACHAPP_SUPABASE_ANON_KEY
pipeline/.venv-macos/bin/python -X utf8 -m sprachpipe.editor
```

Der Browser öffnet den lokalen Startlink. Unter **Versionen → Private
Veröffentlichung** E-Mail und Passwort eingeben und **Mit Passwort anmelden**
wählen. Erfolg leert das Passwortfeld; **Abmelden** entfernt die Tokens aus dem
Editorprozess. Dienstneustart verlangt eine neue Anmeldung. Speichern oder
Anmelden veröffentlicht keine Inhalte; die vorhandenen getrennten Schritte
für Upload, Serverprüfung und Veröffentlichung bleiben erforderlich.

**Alternativ mit E-Mail-Code** öffnet OTP ausdrücklich. **Code senden** nur
verwenden, wenn Zustellung und Tokenvorlage tatsächlich eingerichtet und geprüft
sind. Das Passwortverfahren benötigt diesen Zweig nicht. Es gibt keinen
Passwort-Reset-Mailbutton und keine automatische Anmeldungsmail.

## Einmaliges iPhone-Appupdate am Mac

Die bisher installierte App enthält die neue Maske erst nach einem Appupdate.
Auf dem Mac denselben Commit aus dem eigenen lokalen Übergabeweg bereitstellen
(dieser Auftrag pusht nichts), vorhandene Signing-/Geräteeinrichtung verwenden.
Die App auf dem iPhone **nicht löschen**: Lernstand und vorhandene Installation
sollen erhalten bleiben. Nur der Nutzer führt die Geräteaktualisierung aus.

macOS (Terminal), aus dem Repository:

```sh
flutter pub get --enforce-lockfile
export SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
printf 'Öffentlicher anon/publishable key des Projekts: '
read -r SUPABASE_ANON_KEY
export SUPABASE_ANON_KEY
flutter devices
flutter run -d <IPHONE-GERAETE-ID> --dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
```

`<IPHONE-GERAETE-ID>` durch die Ausgabe von `flutter devices` ersetzen. iOS-Build
und Installation erfolgen auf macOS; Windows kann diese Geräteaktualisierung
nicht ausführen. Anschließend **Einstellungen → Inhaltsupdates → Mit Passwort
anmelden**. Danach **Nach Updates suchen**, bei verfügbarem Release **Version
herunterladen und prüfen**, dann **Geprüfte Version aktivieren**. Laufende
Übungen behalten ihre bisherige Version. Bereits installierter Inhalt bleibt
ohne Anmeldung offline nutzbar.

## Nachweise vom 16.10.2026

Die folgenden Ergebnisse betreffen lokale Tests. Der Browsertest verwendet
synthetische Anmeldedaten und einen Fake-Authtransport; der gesonderte
Supabase-Test verwendet echte lokale Auth-/Edge-Endpunkte auf
`http://127.0.0.1:54321`, zwei eigens erzeugte und im `finally` entfernte
Testbenutzer, keine Cloudidentität. Er verändert keine Allowlist und veröffentlicht
keine Inhalte. Cloudlogin der bestehenden UID und echte iPhone-Abnahme bleiben offen.

| Prüfung | Tatsächliches Ergebnis | Exit |
|---|---|---|
| Python Auth/HTTP/Admin und echte lokale Supabase-Integration | `20 passed in 13.13s` | 0 |
| `flutter test --no-pub test/data/content_auth_test.dart test/content_updates_ui_test.dart` | `+11: All tests passed!` | 0 |
| `flutter analyze --no-pub` | `No issues found! (ran in 4.7s)` | 0 |
| `node --check pipeline/src/sprachpipe/editor/web/app.js` | keine Syntaxfehler | 0 |
| `node --test pipeline/tests/editor_ui_test.cjs pipeline/tests/editor_password_ui_test.cjs` | `tests 2`, `pass 2`, `fail 0` | 0 |

Pythonbefehl unter Windows (PowerShell), bei bereits lokal laufendem Supabase:

```powershell
$env:PYTHONUTF8 = '1'
$env:SPRACHAPP_TEST_LOCAL_AUTH = '1'
pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests/test_editor_publisher.py pipeline/tests/test_editor_http.py pipeline/tests/test_editor_password_http.py pipeline/tests/test_content_password_admin.py pipeline/tests/test_editor_password_local.py -q --tb=short -o faulthandler_timeout=25
```

Gleichwertiger Befehl auf macOS (Terminal):

```sh
PYTHONUTF8=1 SPRACHAPP_TEST_LOCAL_AUTH=1 pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_editor_publisher.py pipeline/tests/test_editor_http.py pipeline/tests/test_editor_password_http.py pipeline/tests/test_content_password_admin.py pipeline/tests/test_editor_password_local.py -q --tb=short -o faulthandler_timeout=25
```

Vorher wurde `supabase functions serve` ohne `--no-verify-jwt` in einem eigenen
Terminal gestartet (Windows und macOS gleich); die Auth-Integration liest die
lokalen Schlüssel nur im Speicher aus `supabase status -o json`. **Dessen
ungefilterte Ausgabe nicht in Logs kopieren.** Der Test akzeptiert ausschließlich
die oben festgelegte Loopbackadresse. Ohne `SPRACHAPP_TEST_LOCAL_AUTH=1` ist nur
dieser Integrationstest ausdrücklich übersprungen. Für Nachtests die Variable
unter Windows mit `Remove-Item Env:SPRACHAPP_TEST_LOCAL_AUTH` bzw. unter macOS
mit `unset SPRACHAPP_TEST_LOCAL_AUTH` wieder entfernen.

Abgedeckt: erfolgreiche bestehende Identität aus Authantwort; falsches Passwort;
unbestätigtes/gesperrtes Konto; Publisher- und Reader-Ablehnung ohne Allowlist;
Refresh; Sessionwiederherstellung; lokaler Logout; Secure Storage ohne Passwort;
CSRF/Origin und kein Auth-Requestcache; Formularzustände und 320 Pixel bei
doppelter Schriftgröße. Adminhelfer mit Mock geprüft, niemals gegen Cloud ausgeführt.

Browser: Fehler und anschließender Erfolg, Abmelden, leeres maskiertes Passwortfeld
mit `current-password`, standardmäßig geschlossene OTP-Alternative und deren
Zustellungshinweis geprüft. Mobile Ansicht und 1280-Pixel-Desktopansicht ohne
Formularüberlauf. [Anmeldemaske mobil](evidence/content-password-login/login.jpg),
[Desktop](evidence/content-password-login/login-desktop.jpg),
[synthetisch angemeldet](evidence/content-password-login/signed-in.jpg).

Vorlauffehler transparent: Flutter hatte zunächst fehlende lokale Paketverknüpfungen;
`flutter pub get --enforce-lockfile` stellte sie mit unverändertem Lockfile wieder her.
In der Pipeline fehlte das bereits deklarierte `openpyxl==3.1.5`; lokal nachinstalliert.
Windows-Tests benötigten UTF-8-Modus für vorhandene Unicode-Hashfixtures;
deshalb auch der Start mit `-X utf8`. Fake-HTTP/Testscrolling wurden korrigiert.
Der bestehende Upload-Retrytest lief einmal nach 90 Sekunden in `job did not finish`;
isolierter Kontrolllauf bestand (`1 passed in 3.07s`), anschließend bestand der
obige gemeinsame Lauf. Kein Retrybudget und kein Produktcode dafür gelockert.
Vor lokalem Functionstart war die Rechteprobe HTTP 404 und wurde nicht als bestanden gewertet.

GitNexus: separater Windowsindex unter `%USERPROFILE%\.codex\gitnexus-windows`,
gebunden an diesen Checkout und Ausgangscommit `f34992d`. Der übernommene macOS-Index
blieb erhalten. Vorab-Impact für Publisher, Handler, Authrepository, Updatecontroller,
Screen und `publisherControls`: LOW; `_remember_session` erreicht OTP, Refresh,
Channel und Veröffentlichung. `_http`: UNKNOWN, ergänzend den injizierten
Transportverweis samt Auth-/Uploadaufrufen im Quelltext bestätigt. Die begrenzte
globale Flow-Erfassung des Index ist kein Beleg für unbetroffene Sessions.

Vor Commit: `node .gitnexus/run.cjs detect-changes --scope all --limit 10000 --repo .`
ausgeführt; zusätzlich denselben offiziellen LocalBackend-Aufruf strukturiert für
`all` und `staged` ausgelesen, weil die CLI ihre Anzeige auf 15 Symbole kürzt.
Strukturierte Kontrollläufe: gesamter Arbeitsbaum 39 Dateien/70–76 Symbole,
**CRITICAL**; eigener Commitumfang 23 Dateien/58 Symbole, ebenfalls **CRITICAL**.
Die Prozesszuordnung schwankte zwischen 259 und 313; keine verlässliche Entwarnung.
Die vollständigen Resultate waren ohne `partial`/`truncated`/Fehler. Der neue
UI-Schalter `_useCode` hat im Resultat eine leere Symbol-ID; sämtliche Schritte
fachfremder Prozesse wie `NewTarget → Api` werden ihm zugeordnet. Diesen Befund
nicht als LOW umdeuten: direkte Textprüfung beschränkt seine Verwendungen auf
die Darstellung und Umschaltung der Anmeldealternative; die Session- und
Rechtepfade sind zusätzlich durch die oben genannten Tests belegt.

`git diff --cached --check`: Exit 0. Fremde Änderungen werden bytegleich anhand
des gesicherten Ausgangsdiffs geprüft; bei NEXTSTEPS bleibt der Ausgangstext
erhalten, nur drei neue Fakten werden isoliert gegen HEAD gestagt. Eine leere,
vor Arbeitsbeginn angelegte `index.lock` ohne laufenden Git-Prozess wurde nach
`build/content_password_login/index.lock.before` gesichert, um Staging zu ermöglichen.

Lokale Prüflogs liegen unter `build/content_password_login/` (nicht versioniert).
Keine echte `user.db`, Produktionsinhalte, Cloudkonfiguration, bestehende Cloud-UID,
Passwörter oder Rollen wurden in diesem Auftrag verändert; keine Geräteinstallation,
Veröffentlichung von Inhalten oder Push.
