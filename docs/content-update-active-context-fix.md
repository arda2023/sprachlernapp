# Aktive Inhaltsversion und aktuelle Wortdetails · 18.10.2026

## Untersuchung vor dem Fix

Ausgangscommit `e0ef6f8`; Arbeitsbaum nur `?? published-baseline-transfer/`.
Dieser Nutzerordner bleibt unberührt. Keine Geräteinstallation, Cloudabfrage,
Veröffentlichung, Änderung echter Nutzerdaten, Editorentwürfe oder Assets.

Gelesen: Download-Diagnose, Published-Base-Adoption, chitchat-Release,
PRODUCT.md und Update-/Historienvertrag in `docs/content-editor-contract.md`
(Abschnitte 6, 12). Zusätzliche gezielte Quellen: `database_providers.dart`,
`content_pack_installer.dart`, `content_install_journal.dart`,
`learning_providers.dart`, `story_learning_providers.dart`,
`deck_session_controller.dart`, `word_details_sheet.dart`.

Lokaler Publikationsbeleg im Editorstore: `publications/87d44368-a765-4ed8-b02d-20f57230d19b.json`,
Status `published`, Generation 2, Server-Release `510c6685-f0ea-4002-9c7c-a09f0bf8212b`.
Bundle `bundles/87d44368-a765-4ed8-b02d-20f57230d19b`, Version
`chitchat_de_korrektur_v1`, 43.089.920 Bytes, SQLite-SHA256
`30cfd77190e8985dac0c058fa3504c3bf20c792ea8830adec2a48b185dda46be`.
Hash entspricht lokalem Bundlemanifest und gespeichertem Publikationsmanifest.
Keine erneute Cloudbestätigung; keine Dateien neu gebaut oder ersetzt.

Read-only SQLite-Befund für Karte `24aafe512840bcd68eaff7658b01b63b`:
- Historischer Satz `43d1a0bb3a30f1c0d940ae67740a93df`: „Wir plauderten nett miteinander, während wir auf den Bus warteten.“; Link `removed_in=chitchat_de_korrektur_v1`.
- Aktiver Satz `b7b51ca27c4fe3c053ba10e57c73effb`: „Wir unterhielten uns nett, während wir auf den Bus warteten.“; Link `removed_in=NULL`.
- Alte echte Basis: `published-bundles/published-baseline-transfer/content.sqlite`,
  SHA256 `ac87b43105b9305579a7fff38de0343f874cbb19e533e1bebbed8942d975acdd`.

## Datenweg und kleinster Reparaturplan

1. `active.json` speichert Release/Generation; Installer öffnet die dort gebundene
   Datei unter `generations/<release-id>/content.sqlite`. Manifest und SQL-Version
   werden geprüft; ein gültiger installierter Stand geht vor dem Asset.
2. `activeContentKeyProvider`/RepositoryOwner binden den Reader an Sprache und
   Generation; Aktivierung schließt Reader und invalidiert Schlüssel/Repository.
   Die Versionsanzeige liest `contentInfoProvider`, also Repositorymetadaten.
3. `practiceResolverProvider` hängt am Repository; dessen `practiceItems` filtert
   historische Links aus. Lokale Storykontexte werden separat aufgelöst.
4. **Ursache in `wordListProvider`:** Nach korrekt aufgelöstem aktuellem Item wird
   bei kuratierten Karten mit Reviews erneut `historicalSentence` mit der Satz-ID
   des letzten Reviews aufgerufen. Dieser Vorrang überschreibt die aktuelle
   Revision. Neustart ändert daran nichts, weil die Review-ID persistiert ist.
   `word_details_sheet.dart` zeigt genau diese Projektion.
5. Neue Übungen beziehen bereits `item.practiceSentence`; laufende Controller
   halten ihre Items und ihren Pass fest. Historische Reader bleiben erforderlich.

Vor Änderung belegter synthetischer Regressionstest: erwartet „Sie schneiden das
Papier.“, tatsächlich „Synthetischer Testsatz.“, Exit 1. Die reale Reproduktion
und weiteren Ergebnisse werden unten ergänzt.

Plan: ausschließlich den historischen Vorrang in `learning_providers.dart`
entfernen; aktuelle Wortdetails verwenden `item.practiceSentence`. Reviews bleiben
Quelle für Anzahl/Datum, historische Auflösung unverändert. Keine Migration,
keine ID-/SRS-/Reviewänderung, keine chitchat-Sonderbehandlung. Das entspricht dem
Vertrag aktiver Links und unveränderlicher Historie; keine Vertragsänderung nötig.

GitNexus vor Edit: Index per `node .gitnexus/run.cjs analyze --index-only`
aktualisiert (Exit 0, 7.739 Knoten/17.976 Kanten/416 Flows). MCP meldete danach
noch veraltete Metadaten; CLI-impact ebenfalls ausgeführt. `wordListProvider`
riskiert `UNKNOWN`, keine aufgelösten Aufrufer/Prozesse; ausdrücklich kein Low-PASS.
Ergänzende `rg`-Referenzprüfung belegt Wortlistenseite, Wortdetailblatt und
Integrations-/Story-/Formtests. Index meldet begrenzte Flow-Erfassung.

## Kurze Sperrmeldung

`ContentUpdateController.activate` prüft `contentTransitionGate.busy` und kehrt
vor Aktivierung zurück. Nicht nur Übungen, auch Wortdetailblatt, Reader und
Wort-Lookup halten solche Leases. Deshalb beweist der Meldungstext keine laufende
Übung. Welcher Lease auf dem iPhone kurz aktiv war, ist nicht belegt. Kein
Zusammenhang mit dem historischen Vorrang nach erfolgreicher Aktivierung belegt;
keine Änderung an Gate, Meldung oder Session-Lebenszyklus.

Vor Produktänderung auch mit echten Bundles reproduziert: `real-red.log`,
`01:22 +2 -2`, Exit 1. Blockierung/Autorisierungsfehler und Openfehler/Rollback
bestehen. Nach erfolgreicher Aktivierung sind Pointer, Datei-SHA und Repositoryversion
korrekt; Wortdetails liefern dennoch die alte chitchat-Übersetzung. Identischer
Assertionfehler nach vollständigem Neubau von Userrepository, Contentrepository und
ProviderContainer, mit verbotenem Asset-Fallback. Damit sind falscher Pack,
veralteter Reader und lokale Satzbindung für diese Reproduktion ausgeschlossen.

## Testumfang und Grenzen

Neue Datei `test/data/content_active_context_test.dart`:
- Immer ausführbare Regression mit vorhandenen Schema-5-vorher/nachher-Fixtures:
  schon gelernte Karte, echte SQLite-Userdaten, aktueller Wortlistenprovider,
  neuer ReviewPass aus dem aktuellen Resolver, alter laufender Pass und
  historische Satzauflösung; kompletter Repository-/Providerneustart.
- Opt-in-Ablauf mit den **unveränderten echten** alten/neuen SQLite-Dateien,
  neuem Inventar und gespeichertem veröffentlichtem Endmanifest. Netzwerktransport
  ist lokal; Download, Validierung, Aktivierung, Rollback und Installer sind echt.
  Die alte Basis wird mit einem nur im Speicher in Format 1 verpackten
  Bootstrapmanifest installiert; SHA/Größe/SQLitebytes bleiben unverändert.
  Dies simuliert nicht den vorangegangenen Serverdownload der Generation 1.
- Aktivierung bei gehaltenem Lease und bei Autorisierungsfehler scheitert;
  fehlgeschlagenes Öffnen rollt zurück. Neustart nach Fehler und Erfolg geprüft.
  Erfolgreicher Neustart verbietet Assetzugriff ausdrücklich.
- Vollständige Zeilen aus `user_cards` und `review_log` werden mit den vor dem
  Update gespeicherten Zeilen verglichen: IDs, Fälligkeiten, Boxen, Flags,
  Notizen, Kontextzeiger und Reviews unverändert. Historischer Satz und laufender
  ReviewPass behalten ihre alte Revision, neue Pässe erhalten die aktive Revision.
- Wortdetails werden an ihrer echten Datenquelle geprüft; kein gerenderter
  Geräte-/Widgetnachweis und kein Zugriff auf echte user.db. Die Servicecallbacks
  öffnen echte Reader und invalidieren den Provider; produktive globale
  RepositoryOwner werden ergänzend durch vorhandene Barrieretests geprüft.

Die Opt-in-Gruppe ist ein geordneter mehrphasiger Integrationstest, gemeinsam
mit SetUp/Teardown ausführen (keine zufällige Testreihenfolge oder einzelne
Phasenauswahl). Ohne die drei Umgebungsvariablen werden vier Phasen übersprungen;
die portable Regression läuft immer. Erster Aufbaufehler: Format-2-Manifest
fälschlich direkt als Format-1-Asset angeboten. Danach überschritt der gesamte
mehrphasige Ablauf 30 Sekunden. Aufteilung in vier fachliche Phasen löst das;
**kein Timeout wurde erhöht**, insbesondere `real_pack_test.dart` unverändert.
Danach scheiterten nur noch die erwarteten Altcode-Assertions, anschließend Fix.

### Exakte Befehle

Repository-Root, macOS (Terminal), reale lokale Bundles nur lesen:

```sh
export ACTIVE_CONTEXT_OLD_BUNDLE="$HOME/Library/Application Support/SprachappContentEditor/published-bundles/published-baseline-transfer"
export ACTIVE_CONTEXT_NEW_BUNDLE="$HOME/Library/Application Support/SprachappContentEditor/bundles/87d44368-a765-4ed8-b02d-20f57230d19b"
export ACTIVE_CONTEXT_PUBLICATION="$HOME/Library/Application Support/SprachappContentEditor/publications/87d44368-a765-4ed8-b02d-20f57230d19b.json"
flutter test --no-pub test/data/content_active_context_test.dart
unset ACTIVE_CONTEXT_OLD_BUNDLE ACTIVE_CONTEXT_NEW_BUNDLE ACTIVE_CONTEXT_PUBLICATION
```

Windows (PowerShell): dieselben drei Variablen mit `$env:ACTIVE_CONTEXT_OLD_BUNDLE`,
`$env:ACTIVE_CONTEXT_NEW_BUNDLE`, `$env:ACTIVE_CONTEXT_PUBLICATION` auf die dortigen
Originalordner/-dateien setzen; keine Macpfade übernehmen. Danach derselbe
Flutterbefehl. Entfernen mit `Remove-Item Env:ACTIVE_CONTEXT_OLD_BUNDLE`,
`Remove-Item Env:ACTIVE_CONTEXT_NEW_BUNDLE`, `Remove-Item Env:ACTIVE_CONTEXT_PUBLICATION`.

Folgende Befehle sind auf macOS und Windows identisch:

```text
flutter test --no-pub test/data/content_active_context_test.dart test/data/content_update_test.dart test/data/content_update_diagnosis_test.dart test/data/content_owner_barrier_test.dart test/data/content_context_revisions_test.dart test/data/content_repository_test.dart test/data/story_content_test.dart test/story_single_sentence_test.dart test/learning_integration_test.dart
flutter test --no-pub
flutter test --no-pub test/data/real_pack_test.dart
flutter analyze --no-pub
git -c core.whitespace=cr-at-eol diff --check -- lib/presentation/providers/learning_providers.dart test/data/content_active_context_test.dart docs/content-update-active-context-fix.md NEXTSTEPS.md
node .gitnexus/run.cjs detect-changes --scope all --repo .
```

### Erneuter iPhone-Versuch (offen; in diesem Auftrag nicht ausgeführt)

macOS (Terminal), Repository-Root, vorhandene Signierung/Bundle-ID unverändert.
Bestehende Projektkonfiguration verwenden, keinen Reset, keine Deinstallation,
keinen erneuten Inhaltsupload oder Release. Falls noch nicht in dieser Shell gesetzt:

```sh
export SUPABASE_URL='https://yevntxclpchapacqdizm.supabase.co'
read -r 'SUPABASE_ANON_KEY?Öffentlicher anon/publishable key des Projekts: '
export SUPABASE_ANON_KEY
flutter run -d 00008110-001651611E01401E --dart-define="SUPABASE_URL=$SUPABASE_URL" --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
```

`read` oben ist für macOS/zsh. Windows (PowerShell): iPhone-Build/Installation
nicht möglich; diesen Geräteversuch am Mac durchführen.

1. Bereits aktiviertes `Englisch · chitchat_de_korrektur_v1` unter Inhaltsupdates
   bestätigen. Ist es schon aktiv, **nicht erneut herunterladen/aktivieren**.
2. Bestehendes gelerntes chitchat in der Wortliste öffnen. Erwartet:
   „Wir unterhielten uns nett, während wir auf den Bus warteten.“
   Box, Fälligkeit, Reviewanzahl, Favorit/Notiz mit vorherigem Stand vergleichen.
3. Details schließen; eine neue passende Stapel-Revue beginnen und chitchat
   prüfen, sobald es regulär erscheint. Keine Antwort nötig, um nur die
   Übersetzung zu prüfen; keine Testreviews oder Lernstandänderung erzwingen.
4. App vollständig schließen, `flutter run` beenden und mit exakt demselben
   Befehl neu starten. Version und Wortdetails erneut prüfen.
5. Falls noch eine echte Aktivierung erforderlich ist: Durchgang ausdrücklich
   verlassen, Wortdetails/Reader/Lookup schließen, dann einmal aktivieren.
   Falls die Sperrmeldung bleibt, offene Ansicht und Zeitpunkt festhalten;
   nicht durch Reset umgehen.
6. Rückmeldung: aktive Version, Wortdetailübersetzung unmittelbar/nach Neustart,
   Übersetzung im neu begonnenen Durchgang (oder „noch nicht erreicht“),
   unveränderte persönliche Daten und gegebenenfalls sichere Diagnosezeile.
   Historische Reviews dürfen weiterhin den alten Satz referenzieren.

Kein Geräte-PASS ohne diese tatsächliche Prüfung.

## Tatsächliche Ergebnisse

Logs lokal unter `build/active_context_fix/` (nicht committed).

| Prüfung | Output | Exit |
|---|---|---|
| Neue portable Regression, alter Code | erwartet aktuelle Revision, tatsächlich historischer Testsatz | 1 |
| Echte Bundles, alter Code | `01:22 +2 -2: Some tests failed.`; exakt alte chitchat-Übersetzung nach Aktivierung und Neustart | 1 |
| Neue Regression + echte Bundles, Fix | `01:21 +5: All tests passed!` | 0 |
| Gezielte Update-/Reader-/Historien-/Integrationstests (Befehl oben) | `00:14 +51 ~4: All tests passed!`; vier Realphasen ohne Umgebungsvariablen übersprungen, separat bestanden | 0 |
| `flutter test --no-pub` | `00:55 +361 ~5: All tests passed!`; vier Opt-in-Realphasen + vorhandener Baseline-Skip | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:12 +1: All tests passed!`; 30-s-Budget unverändert | 0 |
| `flutter analyze --no-pub` | ein vorbestehendes `avoid_print` in `test/data/baseline_adoption_pack_test.dart:43:7`; eigene Dateien ohne Befund | 1 |
| Diffcheck mit CRLF-Konfiguration, eigene Dateien | ohne Befund | 0 |
| CLI und MCP `detect_changes(scope: all)` nach Staging/Reindex | 4 Dateien, 36 Symbole inkl. Test/Doku, 0 aufgelöste Prozesse, `low`; MCP vollständig, kein partial/truncated | 0 / erfolgreich |

Gezielte Tests zeigen bestehende Drift-Debugwarnungen beim parallelen Öffnen
mehrerer ContentDatabase-Testinstanzen mit getrennten Testdateien; kein Testfehler.
Unkonfiguriertes `git diff --check` meldete CRLF als trailing whitespace (Exit 2).
Bestehende CRLF in den zwei bearbeiteten Bestandsdateien bleiben erhalten;
`git -c core.whitespace=cr-at-eol diff --check -- <eigene Dateien>` ist sauber,
Exit 0. Keine großflächige Zeilenendenänderung.

Der niedrige detect_changes-Wert hebt die dokumentierte `UNKNOWN`-Grenze des
Provider-Impactgraphen nicht auf; Referenzprüfung und reale Regression ergänzen
sie. Abschließender Hashvergleich beider externen SQLite-Dateien: unverändert,
beide weiterhin exakt an ihre Originalmanifeste gebunden (Exit 0).

Geänderte Dateien: `lib/presentation/providers/learning_providers.dart`,
`test/data/content_active_context_test.dart`, dieser Bericht und `NEXTSTEPS.md`
(nur fünf neue Zeilen; sämtliche Altinformationen erhalten). Keine weiteren
Produktdateien verändert. Eigene Änderungen werden isoliert committed, kein Push.
Die Geräteprüfung und die konkrete Ursache des kurz gehaltenen Geräte-Leases
bleiben offen; keine Vertragsänderung erforderlich.
