# Linglossa im Browser und auf Cloudflare Pages

Stand 07.11.2026. Die Webversion verwendet denselben Flutter-Code, dieselben
Inhaltspakete und dieselbe Lernlogik wie die Handy-App. Hauptbereiche sind
**Lesemodus** und **Stapel**. Inhalte und Wortliste sind nicht in der
Webnavigation enthalten. Desktop: seitliche Navigation, begrenzte Inhalts- und
Lesebreite; schmale Fenster: untere Navigation. Einstellungen bleiben erreichbar.

Die aktuelle Lernsprache steht auf dem Desktop in der Seitenleiste und auf
schmalen Fenstern in der Kopfzeile. Antippen öffnet dieselbe Sprachauswahl wie
auf dem Handy; mit „Auswählen“ wechseln Lesemodus und Stapel gemeinsam. Die
Auswahl bleibt in diesem Browser gespeichert, der Lernstand bleibt je Sprache
getrennt erhalten.

## Anmeldung und gemeinsamer Lernstand

Der Webzugang benötigt ein bestehendes oder neu per E-Mail-Code bestätigtes
Supabase-Konto. Es wird dieselbe E-Mail-Adresse wie auf dem Handy verwendet;
der bestehende Supabase-E-Mail-OTP-Versand muss aktiviert sein. Der Webclient
verwendet weder native Apple-/Google-Login-Plugins noch einen eigenen
Kontobestand. Premiumrechte werden weiterhin vom vorhandenen Backend geprüft.

Voraussetzungen für den Geräteabgleich (am 07.11.2026 ausgeführt):

1. Die Migration `supabase/migrations/20261107000001_learning_sync.sql` im
   **gleichen Supabase-Projekt wie der Handy-Login** über den bestehenden
   Migrationsprozess anwenden. Kein anderes Projekt anlegen. Die Migration
   erstellt die eigene RLS-Tabelle und authentifizierte Push-/Pull-RPCs.
2. Die Handy-App aus diesem Stand installieren und dort mit demselben Konto
   öffnen. Erst diese Version kann den bisherigen lokalen Lernstand hochladen.
3. Webversion öffnen, anmelden und den angezeigten Synchronisierungsstatus
   prüfen. Eine abgeschlossene Wiederholung und eine Leseposition in beide
   Richtungen kontrollieren.

Vor Browseraufrufen müssen außerdem die sechs bestehenden Edge Functions mit
der gemeinsamen CORS-Hülle erneut veröffentlicht werden. Gleiche Befehle in
Windows PowerShell und macOS Terminal, nach Anmeldung und Verknüpfung mit dem
bestehenden Supabase-Projekt:

```text
supabase functions deploy lookup-word
supabase functions deploy translate-sentence
supabase functions deploy create-learning-card
supabase functions deploy generate-vocabulary
supabase functions deploy billing-sync
supabase functions deploy delete-account
```

`translate-sentence` übernimmt auch das Löschen des Übersetzungscaches per
`DELETE`; es gibt keine separate `clear-translation-cache`-Function. Die CORS-Hülle
beantwortet `OPTIONS` ohne Auth-/KI-/Budgetaufruf. Tatsächliche Anfragen durchlaufen
weiterhin die vorhandenen Bearer-, Konto-, Einwilligungs- und Budgetprüfungen.
`verify_jwt = true` bleibt bestehen; **kein** `--no-verify-jwt` verwenden. Erlaubt
sind Browseraufrufe mit `authorization`, `apikey`, `content-type` und
`x-client-info`, ohne Cookies oder CORS-Credentials. Ein fester Cloudflare-Hostname
ist dafür nicht nötig. Siehe [Supabase CORS](https://supabase.com/docs/guides/functions/cors)
und [JWT-Header](https://supabase.com/docs/guides/functions/auth-headers).

Am 07.11.2026 wurden die Migration und alle sechs Functions im bestehenden
Supabase-Projekt veröffentlicht. Die aktualisierte iPhone-App wurde installiert
und gestartet. Der Browser zeigte nach erneutem Laden „Lernstand abgeglichen“;
der bestehende Premiumzugang wurde korrekt erkannt. Eine unabhängige Liveprüfung
bestätigte 225 Karten und 281 Reviews für genau ein synchronisiertes Konto.
Das belegt die Übertragung des vorhandenen Lernstands; eine neu abgeschlossene
Wiederholung mit anschließendem Gegencheck auf beiden Geräten wurde dabei nicht
zusätzlich ausgelöst. Einzelheiten und Sicherheitsnachweise:
[Web-Deployment-Abnahme](web-deployment-verification-2026-11-07.md). Konfliktregeln, Kontentrennung und Umfang stehen in
[learning-sync.md](learning-sync.md). Die vier Lernzähler bleiben abgeleitet.

Die verwendete Supabase CLI v3 adressiert das verknüpfte Projekt mit
`--remote` (nicht mit dem älteren `--linked`). Der veröffentlichte
Migrationsstand lässt sich auf Windows PowerShell und macOS Terminal prüfen:

```text
npx supabase migration list --remote
```

`20261107000001` ist lokal und remote vorhanden. Für künftige geprüfte
Migrationen verwendet CLI v3 `npx supabase db push --remote`; für diesen Stand
ist keine erneute Anwendung nötig.

## Build

Voraussetzungen: zum Projekt passende Flutter-/Dart-Version, Python 3,
bereitgestellte lokale Inhaltspakete unter `assets/content/{en,pt-BR,nb,it,es}`.
SQLite-Dateien und Inhaltsmanifeste sind absichtlich nicht in Git enthalten;
ein frischer Checkout benötigt dieselben geprüften Pakete wie der Handybuild.
Die derzeit bereitgestellten Pakete sind als internes Testmaterial markiert.
Die Vorbereitung des Uploadordners veröffentlicht sie noch nicht.

Der Buildhelper liest ausschließlich `SUPABASE_URL` und den **öffentlichen**
`SUPABASE_ANON_KEY` aus der angegebenen lokalen JSON-Datei oder den gleichnamigen
Umgebungsvariablen. Andere Einträge werden nicht in den Webbuild übernommen;
Server-/Service-Role-/Anthropic-Schlüssel sind unzulässig. Kein Schlüssel wird
in dieser Anleitung oder in versionierten Konfigurationsdateien hinterlegt.

macOS Terminal:

```sh
python3 tool/build_web.py --config config/adapty.local.json
```

Windows PowerShell:

```powershell
py -3 tool/build_web.py --config config/adapty.local.json
```

Ohne `--config` werden die beiden vorhandenen Umgebungsvariablen verwendet.
Der Helper prüft die Konfiguration, holt bei Bedarf das fest versionierte
SQLite-WASM mit SHA-256-Prüfung, kompiliert den Drift-Worker und baut die
Release-Webversion mit lokal gebündeltem CanvasKit. Danach prüft er benötigte
Dateien und die Cloudflare-Pages-Grenze von 25 MiB je Datei. Das aktuelle
englische Paket liegt knapp unter dieser Grenze; größere Folgestände benötigen
vor dem Upload eine andere Inhaltsauslieferung.

Ergebnis: **`build/web`**. Dieser Ordner enthält bereits `_headers` und
`_redirects`. Es gibt keine Node-/SSR-Serverkomponente.

## Veröffentlichung

In Cloudflare Pages ein Direct-Upload-Projekt anlegen und den Inhalt von
`build/web` hochladen, oder Wrangler verwenden. Gleicher Befehl auf beiden
Systemen nach dem Build:

```text
npx wrangler pages deploy build/web --project-name linglossa
```

Den Projektnamen gegebenenfalls an das eigene Pages-Projekt anpassen. Für einen
späteren Git-Build muss die Buildumgebung Flutter und die nicht versionierten
Inhaltspakete bereitstellen; allein `flutter build web` aus einem frischen
Cloudflare-Checkout reicht deshalb nicht. Keine Zugangsdaten oder internen
Packarchive zu Git hinzufügen, um das zu umgehen.

Die ausgelieferten Header aktivieren die Browserisolierung für SQLite und
deklarieren `.wasm` korrekt. Die Anwendung wird unter der HTTPS-Pages-URL am
Domainroot betrieben. Anmeldung braucht keine Magic-Link-Weiterleitung, da der
Code direkt eingegeben wird. Die Supabase-Mailvorlage muss `{{ .Token }}` anzeigen.

## Prüfung und Grenzen

Windows PowerShell und macOS Terminal:

```text
flutter analyze
node --experimental-transform-types --test supabase/functions/_shared/browser_cors_test.ts
flutter test test/web_workspace_test.dart test/data/learning_sync_test.dart test/data/account_database_isolation_test.dart
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8347 -t tool/qa/browser_storage_smoke.dart
```

Der letzte Befehl startet einen separaten Test der echten Browserdatenbank:
Pakete öffnen, Stapel/Storys und Übungsinhalt lesen, Konto A schließen und erneut
öffnen, Konto B auf Trennung prüfen. Die sichtbare Seite meldet das Ergebnis.
`tool/qa/browser_workspace_preview.dart` ist ausschließlich ein isolierter
Layouttest mit Testkonto und lokal überschriebenem Premiumstatus. Beide
QA-Einstiege sind **keine** Veröffentlichungseinstiege; der Buildhelper verwendet
immer `lib/main.dart` mit echter Anmeldung und echten Zugriffsprüfungen.

Browserdaten liegen kontogetrennt in OPFS/IndexedDB. Inkognitomodi ohne dauerhafte
Speicherung werden abgewiesen. Gelöschter Browser-Websitespeicher lässt sich
nach Anmeldung nur aus bereits erfolgreich synchronisierten Daten wieder
herstellen. Der erste Aufruf lädt das Inhaltspaket; eine vollständige
Offline-PWA-Installation wird nicht zugesagt. Sprachausgabe bleibt wie bisher
auf iOS und Android beschränkt, Texteingabe und Üben funktionieren im Browser.

Technische Grundlagen: [Drift Web](https://drift.simonbinder.eu/platforms/web/),
[Cloudflare-Pages-Limits](https://developers.cloudflare.com/pages/platform/limits/).
