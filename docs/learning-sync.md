# Kontogebundener Lernstand zwischen App und Web

Stand 07.11.2026: implementiert, lokal getestet und im bestehenden Supabase-Projekt veröffentlicht. Die aktualisierte iPhone-App wurde installiert und gestartet; der Browser meldete erfolgreichen Abgleich. Der Server enthielt anschließend 225 Karten und 281 Reviews für ein Konto. Ältere App-Versionen ohne Syncdienst laden ihren ausschließlich lokalen Lernstand weiterhin nicht selbst hoch. Abnahme und verbleibende Prüflücke: [Deploymentbericht](web-deployment-verification-2026-11-07.md).

## Betrieb

`learningSyncProvider` startet nach Wiederherstellung eines bestätigten Kontos und Öffnen seiner Datenbank. Der Abgleich läuft beim Start, bei Rückkehr zur App, beim Wechsel in den Hintergrund nach Änderungen der Lerndatenbank mit zwei Sekunden Bündelung sowie alle 20 Sekunden, solange die App ausgeführt wird. Eine manuelle Wiederholung ist über `synchronize()` möglich. Ein geschlossener Browser und ein vom Betriebssystem angehaltener Handyprozess synchronisieren nicht weiter. Bei fehlender Verbindung bleiben Änderungen lokal und werden beim nächsten erfolgreichen Durchlauf übertragen.

Die Supabase-Migration `20261107000001_learning_sync.sql` muss in demselben Projekt wie der bestehende Login angewendet werden. Sie stellt die authentifizierten RPCs `push_learning_rows` und `pull_learning_rows` bereit. Keine zusätzliche Edge Function, kein KI-Aufruf und kein neuer Client-Schlüssel. Es werden ausschließlich bestehende öffentliche Projektkonfiguration und das jeweilige Zugriffstoken verwendet. Browser und Handy müssen dieselbe Supabase-Projektkonfiguration verwenden.

## Daten und Konflikte

Synchronisiert werden Kartenstände einschließlich Box, Fälligkeit, Flags und Notiz, Reviewhistorie, private Karten und Kontexte, Stapelaktivierung, Quellenmitgliedschaften, Identitätsbindungen und sprachbezogene Lernpräferenzen. `SyncJsonStore` ergänzt Lesepositionen und importierte Texte in derselben kontogebundenen Datenbank. Die vier Vokabelzähler bleiben aus diesen Daten berechnet. Geräte-ID, gewählte Sprache, Motiv, Zugangstoken, KI-Einwilligungen, Übersetzungscaches, Onboarding und lokales Feedback werden nicht übertragen.

Für veränderliche Zeilen gewinnt der neuere Änderungszeitpunkt; bei exakt gleichen Zeitpunkten entscheidet ein deterministischer SHA-256-Hash. Bereits gespeicherte Zeitpunkte werden übernommen; Änderungen an bisher zeitstempellosen Lernpräferenzen erhalten einen Zeitpunkt, wenn der Sync sie erstmals beobachtet. Zwei unabhängige Offline-Reviews derselben Karte werden beide als unveränderliche Historie erhalten; der zuletzt geänderte Kartenstand bestimmt die Box und Fälligkeit. Die Geräteuhren müssen stimmen; der Server lehnt Zeitpunkte mehr als einen Tag in der Zukunft ab.

Reviews, Kontexte, Bindungen und Quelleneinträge sind unveränderlich. Gleiche IDs mit widersprüchlichem Inhalt führen zu einem Fehler und werden nicht still überschrieben. Lesefortschritt erhält die neuere Position; einmal beendete Storys bleiben beendet. Gelöschte importierte Texte behalten einen Löschmarker, damit ein älteres Gerät sie nicht wiederherstellt. Ein veralteter UI-Speicherstand darf keine noch ungesehenen Importtexte eines anderen Geräts löschen.

Der Client überträgt nur lokal geänderte Zeilen. Der Download liest in dieser ersten Version den gesamten Kontobestand in Seiten zu höchstens 500 Zeilen; es gibt noch keinen inkrementellen Servercursor. Ein Upload enthält höchstens 100 Zeilen und 4 MB; eine Serverzeile höchstens 200 KB. Sehr große Konten benötigen vor einer breiten Veröffentlichung eine Lastmessung und gegebenenfalls inkrementelle Downloads.

## Kontentrennung

Die Datenbankauswahl erfolgt außerhalb des Syncdienstes pro Konto. Zusätzlich bindet der Sync jede Datenbank vor dem ersten Upload dauerhaft an die Kombination aus Supabase-Host und Konto-ID. Ein abweichendes Konto erhält `accountMismatch` und darf nichts hochladen. Jeder asynchrone Netzwerk-/Anwendungsabschnitt kontrolliert die aktuelle Identität; ein verspäteter Download nach Kontowechsel wird verworfen.

RLS begrenzt direkte Lesezugriffe auf das eigene Konto. Direkte Schreibrechte für `authenticated` fehlen; die RPCs erzwingen die bestätigte, nicht anonyme Identität und verwenden ausschließlich `auth.uid()`, niemals eine übergebene Konto-ID. Die Fremdschlüsselbindung an `auth.users` entfernt Syncdaten bei der Kontolöschung. Bestehende lokale Lesedateien dürfen nur beim einmaligen Übernehmen der ursprünglichen Gerätedatenbank migriert werden, niemals in jedes später angemeldete Konto.

## Nachweise

Windows PowerShell und macOS Terminal:

```text
flutter test --no-pub test/data/learning_sync_test.dart
flutter analyze --no-pub lib/data/sync lib/presentation/providers/learning_sync_provider.dart test/data/learning_sync_test.dart
node tool/test_learning_sync_sql.mjs <Pfad-zu-externem-pglite/dist/index.js>
```

Die Darttests verwenden getrennte SQLite-Datenbanken für Handy und Browser sowie einen kontrollierten Transport. Die SQL-Prüfung führt die tatsächliche Migration in PGlite aus und prüft Authentifizierung, Kontentrennung, Konfliktregeln, unveränderliche Reviews, Grants, Seitengrenzen und Kontolöschung. Zusätzlich wurden die tatsächliche veröffentlichte Migration, RLS/Grants und die RPCs live mit vollständig zurückgerollten synthetischen Konten geprüft. Nach dem iPhone-Update wurden vorhandene echte Lernstände auf dem Server nachgewiesen und der angemeldete Browser meldete erfolgreichen Abgleich. Eine neu erzeugte echte Wiederholung in beide Richtungen und ein späterer Aufruf unter der endgültigen Cloudflare-URL sind damit noch nicht nachgewiesen.
