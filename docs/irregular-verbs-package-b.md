# Verben-Paket B: integrierte Formübungen

Stand 10.10.2026. Paket B ist technisch umgesetzt und mit synthetischen Daten abgenommen. Die Inhaltsauswahl für die drei Verbansichten steht weiterhin aus. Der Produktionsstand bleibt `natur_umwelt_batch_3_v1`, Schema 3, acht Stapel und 2121 primäre Lernziele. Technische Abnahme ist keine öffentliche Inhaltsfreigabe.

## Gemeinsamer Lernablauf

`PracticeItemResolver` verwendet `ContentRepository.deckPracticeTargets`. Gewöhnliche Ziele behalten die Lerngruppenprojektion; Formziele bleiben die konkrete Formkarte beziehungsweise ihre exakte lokale Bindung. Nach der Auflösung werden Formkarten nicht erneut auf den gewöhnlichen Gruppenkopf abgebildet. Dieselbe Karten-ID wird über Ansichten hinweg dedupliziert; bestehende lokale und kuratierte Doppelstände bleiben getrennt erhalten.

Stapel, Gemischt, Revue, Fortschritt, Wortliste und Story-Markierungen verwenden diese Auflösung. Formkarten mit identischer Schreibweise behalten eigene Boxen, Termine, Favoriten, Deaktivierung, Playlistauswahl und Notizen. Grundform, Präteritum und Partizip Perfekt sind als solche beschriftet. Die Wortdetails zeigen den Termin der konkreten Form; die Wertezeile bleibt auch bei großer Schrift umbrechbar.

Neue Sitzungssegmente wählen höchstens eine Form je normalisiertem Lemma und Oberfläche. Bekannte Lemmas werden nachrangig angeboten und nicht dauerhaft gesperrt. Fällige gelernte Formen bleiben alle erreichbar. `form_only` kommt über Formansichten oder explizites Story-Hinzufügen hinzu, nicht versehentlich über den Besitzerstapel. Sessionfreeze, feste Sätze und In-Session-Wiederholung bleiben erhalten. `ReviewPass`, `ensureCards` und `recordReview` bleiben der vorhandene Lern- und Buchungsweg; doppelte Ansichten oder Doppeltippen erzeugen keinen zusätzlichen Review pro Pass.

Die Antwortprüfung und Leitnerintervalle wurden nicht geändert. `review_pass.dart` verwendet lediglich das Formlabel für den vorhandenen Hinweis. Geprüfte Alternativen gelten weiterhin ausschließlich im konkreten Satz und bleiben lernstandsneutral; Gruppen, Besitzer und lexikalische Zugehörigkeit erlauben keine zusätzlichen Antworten. Gleiche Schreibweise wird im sichtbaren Satzkontext geprüft.

## Lokale Migration und Story-Hinzufügen

user.db v5 ergänzt nullable `form_function` und `lexical_target_id` in `user_cards` sowie `form_identity_bindings` mit eindeutigem Sprache/Oberfläche/Sense/Funktion-Schlüssel. Die zusätzliche lokale Lexikalspalte ist eine notwendige Ergänzung zum Plan: Sie erhält den belegten Wortanker einer lokalen Form beim Rückfall auf ältere oder fehlende Inhalte. Sie speichert keine Zähler. Alte IDs und `learning_identity_bindings` bleiben unverändert; alte Funktionen bleiben NULL.

Die neuen Namespaces sind `form-learning-identity-v1` und `local-form-card-v1`; alte Hash-Namespaces bleiben unverändert. Ein belegter StoryToken wird exakt aufgelöst. Vorhandene Form und Kontext werden wiederverwendet. Eine andere Funktion erhält einen unabhängigen Zustand, aber keinen zusätzlichen lexikalischen Begriff. Eine neue lokale Form braucht freigegebene vollständige Tokenannotation, deutsche Übersetzung, eindeutige Funktion und Lexikalzuordnung.

Wörterbuch-card_id alleine entscheidet nicht zwischen gleichen Oberflächen. Ohne Funktionsbeleg bleibt die Übersetzung verfügbar und Add nennt den Konflikt. Unklassifizierte alte lokale Bindungen werden nicht geraten. Deaktivierte Ziele bleiben gesperrt; lokale/kuratierte Doppelstände führen zu einem Konflikt ohne dritte Kopie. Ein alter kuratierter Grundformstand wird nicht allein wegen seiner nullable Nutzermetadaten als unklassifizierte lokale Form behandelt. Typisierte lokale Grundformen werden auch über die gewöhnliche Besitzeransicht wiederverwendet.

Add ist transaktional und idempotent, erzeugt keinen Review und aktiviert keinen Besitzerstapel. Append-only-Kontexte und Reviews sowie Pass-ID-Schutz bleiben erhalten. Unterstützte Migrationen v1/v2/v3/v4 → v5 sind geprüft; v2/v3/v4 vergleichen vorhandene Spaltenwerte und Reviewzeilen, v4 zusätzlich bestehende lokale Kontexte, Quellen und Bindungen. Ein echter Prozessneustart und synthetischer Schema-3-Rückfall mit anschließender Schema-4-Rückkehr erhalten dieselben Zustände und IDs. Keine echte user.db wurde geöffnet.

## Wörter und Übungen

`eligiblePracticeIds` liefert das gemeinsame berechtigte Inventar für vier SRS-Kategorien und lexikalische Zahlen. Die Oberfläche bezeichnet Karten als Übungen: Wiederholungen, Übungen im Aufbau, gemeisterte Übungen und noch nicht geübte Übungen. Daneben stehen Wörter und davon bereits geübte Wörter. Explizite Lexikalanker gelten innerhalb belegter Sense-/Gruppenkomponenten; ohne Anker bleibt der alte Gruppenfallback. Derselbe Begriff wird nicht zugleich explizit und per Fallback gezählt. Bereits geübt bedeutet mindestens eine beantwortete Form, keine Beherrschung aller Formen.

Stapel zählen ihre tatsächlichen Übungen, globale Werte werden nicht aus Stapelsummen gebildet. Das Tagesziel zählt weiterhin unterschiedliche reviewte Karten am lokalen Tag. Kein Counter wird gespeichert. Die Diagnosewerkzeuge geben Übungen, Formmitgliedschaften und lexikalische Wörter getrennt aus; `report_learning_groups.dart PACK` schreibt nur stdout und überschreibt keine historischen Berichte.

## Tests und technische Installation

Die Paket-A-Fixture enthält go/went/gone, cut/cut/cut und run/ran/run: neun Formübungen, drei lexikalische Ziele, zwölf Ansichtsmitgliedschaften. Tests decken getrennte Lernstände, alle fälligen Homographen, eine neue Form pro Lemma/Oberfläche, ordinary/form_only, neutralen Rückfall, idempotentes paralleles Add, fehlende Annotation, mehrdeutige Funktion, deaktivierte lokale Bindung, lokale/kuratierte Doppelstände, feste Kontexte, Provider-Neuberechnung und Sessionfreeze ab. Ein eigener Domainfall hält eine Form ausdrücklich von ihrem abweichenden gewöhnlichen Gruppenkopf getrennt. Widgettests prüfen neue Labels, VoiceOver und große Schrift.

Die Schema-4-Sperren wurden erst nach bestandenem Integrationslauf entfernt (`integration-final.log`: 11 Tests, Exit 0). Synthetisches Staging und Installation erfolgen in separaten temporären Verzeichnissen. Alle 22 Tabellen bleiben Bestandteil der Validierung. Falscher Hash, unbekannte Version und defekte Forminhalte ersetzen keine gültige Installation. Schema 1/2/3 bleiben kompatibel; die Pipeline-Regression prüft weiterhin den vollständigen Python-Export/Import-Abgleich aller 22 Tabellen. Der reale Schema-3-Pack wurde read-only mit allen 18 Tabellen gegen `pack.json`, Asset und Manifest verglichen.

Die folgenden Befehle liefen auf macOS; Flutter/Dart-Befehle sind unter Windows PowerShell identisch. Für Python nutzt Windows nach Aktivierung der vorhandenen Umgebung `python` statt `pipeline/.venv-macos/bin/python`. Logs liegen lokal unter `/tmp/irregular-verbs-package-b/`.

| Tatsächlicher Befehl | Tatsächlicher Output (Ausschnitt) | Exit |
|---|---|---:|
| `dart run build_runner build --delete-conflicting-outputs` | `Built with build_runner/aot in 40s; wrote 245 outputs.` | 0 |
| `flutter test` | `00:36 +275: All tests passed!` | 0 |
| `flutter analyze` | `No issues found! (ran in 3.7s)` | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | `431 passed, 19 subtests passed in 43.08s` | 0 |
| `pipeline/.venv-macos/bin/python /tmp/irregular-verbs-package-a/verify_pack.py` | `PASS build_rows + check_sqlite: 18 tables, complete row comparison, read-only`; `primary_goals=2121 cards=2236 owners=2132 sentences=2770 links_total=2764 active_links=2236`; Asset/Manifest PASS | 0 |
| `dart run tool/report_learning_groups.dart /tmp/irregular-verbs-package-b/diagnostic.sqlite` | JSON mit 9 Übungen und 3 Wörtern in `mixed`, getrennten Formmitgliedschaften und Funktionslabels | 0 |
| `dart run tool/inspect_new_card_selection.dart /tmp/irregular-verbs-package-b/diagnostic.sqlite` | `3 exercises / 3 words; 3 form memberships`; drei eindeutige neue Formen je Formansicht | 0 |

Codegen aktualisierte nur die benötigte generierte `user_database.g.dart`; der Generator meldete den inzwischen wirkungslosen `--delete-conflicting-outputs`-Schalter. Keine Paketinstallation. Frühe gezielte Tests fanden korrigierte Fixtureannahmen, Compile-/Importbefunde und veraltete UI-Texterwartungen. Die vollständige UI-Prüfung fand einen behobenen Überlauf bei großer Schrift. Ein negativer Storytest entfernte zunächst einen vorgeschriebenen Übungstokenbeleg und scheiterte deshalb korrekt schon am Packvalidator; er verwendet jetzt eine separate Storysatzkopie. Abschließende Prüfungen sind oben ausgewiesen.

## Isolierter Simulatornachweis

Neu angelegt: iPhone 17 Pro, iOS 26.5, UUID `4053D601-9241-40FF-9393-8BE2EBC4C3DD`; keine bestehende Simulatorinstallation verwendet. Der temporäre Einstieg enthielt ausschließlich die synthetische SQL-Fixture und verwendete den echten `DeckSessionController`, Repository-/Providerpfad sowie eine eigene SQLite im neuen Appcontainer. Es war ein automatischer Funktionslauf mit Ergebnisanzeige, kein manueller Rundgang durch sämtliche Produktionsscreens. Die Produktionsoberfläche ist zusätzlich durch Widgettests geprüft.

Ausgeführte macOS-Befehle: `xcrun simctl create 'Sprachapp Paket B Isolated' com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-5`, anschließend `boot UUID`, `flutter run --no-pub -d UUID -t lib/package_b_device_probe.dart`, Prozessende über `simctl terminate UUID com.example.sprachapp`, erneutes `flutter run`, Screenshot, `shutdown UUID`, `delete UUID`. simctl ist ausschließlich ein macOS-Werkzeug; unter Windows stehen die plattformneutralen Integrations-/Widgettests zur Verfügung.

Nach Korrektur des temporären Imports lief der Build. Die erste unmittelbare Wortlistenabfrage erfolgte vor dem asynchronen Providerereignis; der Probe wurde eine Wartephase gegeben. Direkter Debugstart per simctl lieferte keinen Nachweis; der tatsächliche Neustart erfolgte deshalb erneut über Flutter. Gemessene Ausgabe:

```text
flutter: DEVICE form=base card=61ee58a531ddc9d1a0a7ff82ead3deaf box=0->3
flutter: DEVICE form=past card=8e0c9de036c8be97761550af31d871e4 box=0->3
flutter: DEVICE Story Add u:800c643a259c6fc285db6dd224b6275368c8e74dc5b581e2a6e58ef3b53b9da2, no review=true
flutter: DEVICE RESTART PASS binding=u:800c643a259c6fc285db6dd224b6275368c8e74dc5b581e2a6e58ef3b53b9da2 flags/context retained
flutter: DEVICE PASS 9 exercises / 3 words / 2 reviews / 3 wordlist rows
```

Erfolgreicher Flutter-Lauf nach Beenden des Tests: Exit 0. Create, Boot, Terminate, Screenshot, Shutdown und Delete: Exit 0. Erster Build mit ungültigem temporärem Testimport: Exit 1. Ergebnisbild: `/tmp/irregular-verbs-package-b/device-pass.png`. Testeinstieg aus `lib/` entfernt, ausschließlich zur Nachvollziehbarkeit unter `/tmp/irregular-verbs-package-b/device-probe.dart` gesichert. Testsimulator samt synthetischer Daten gelöscht; keine temporäre Startkonfiguration verbleibt.

## Umfang und Übergabe

Geändert sind Domainauflösung/-zählung und Formidentität, gemeinsamer Resolver, lokales Schema/Repository mit Drift-Ausgabe, Sessioncontroller/Provider, betroffene Home-/Stapel-/Wortlisten-/Storytexte und Formdetails, Installer/Staging sowie zwei Diagnosewerkzeuge. Abhängige Anpassungen betreffen `word_list_models.dart` (Termin und Wortanker), Tagesziel-/Navigationslabels und den bestehenden Wrong-form-Hinweis. `repositories.dart` braucht keine weitere Schnittstelle: der in A eingeführte Vertrag reicht aus. Neue Dateien: `test/data/form_learning_test.dart`, `test/fixtures/form_learning.dart`, `test/form_learning_flow_test.dart`, `test/domain/form_projection_test.dart`, `test/form_counts_widget_test.dart` und dieser Bericht. Vorhandene Migration-/Content-/UI-Tests sowie Verträge und NEXTSTEPS wurden angepasst.

Nächste Aktion ist eine **gemeinsame** Verbenauswahl für drei Ansichten mit belegtem Sense-/Funktions-/Lexikalanker, Wiederverwendung passender bestehender Karten und fester Sätze, eindeutigem Besitzer-/Aliasmapping und Prüfung unklassifizierter Konkurrenz. Mengen bleiben Richtwerte nach Dublettenprüfung. Erst danach neue Ziele über die vorhandenen geprüften Authoring-ZIPs im Chat redigieren. Keine drei unabhängigen Reservierungsläufe, keine automatische Modellgenerierung, keine zusätzlichen Kategorien. Technische Abnahme und öffentliche Inhaltsfreigabe bleiben getrennt.

## Bestandserhalt und Whitespace

Audit gegen 2575 vor Beginn erfasste Dateien: **46 geänderte Bestandsdateien, 2529 bytegleich, 6 neue Auftragsdateien**. Alle 73 gesondert erfassten geschützten Produktionsdateien sind hashgleich. Historische Lieferungen, Auswahlen/Registrys, Modellkonfiguration und Authoring-ZIPs wurden nicht bearbeitet. Keine Commits, Pushes, Cloud-/Modellaufrufe oder Remote-Migrationen. Der Repository-Arbeitsbaum enthielt bereits umfangreiche Änderungen einschließlich Paket A; diese sind erhalten.

| Datei | SHA256 vor und nach Paket B |
|---|---|
| `pipeline/out/natur_umwelt_batch_3_v1/pack.json` | `7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e` |
| `pipeline/out/natur_umwelt_batch_3_v1/content.sqlite` | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| `assets/content/en/content.sqlite` | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| `assets/content/en/content.manifest.json` | `e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b` |

`python3 /tmp/irregular-verbs-package-b/audit.py` — Exit **0**. Ausgabe: `crlf: 52 files checked; 0 whitespace/error findings; audit exit 0`, anschließend Bestands-/Hash-PASS. Die tatsächlich geprüfte Dateiliste steht in `changed-files.json`, alle Befehle/Ausgaben in `whitespace-crlf.json` im selben Verzeichnis. Verglichen wurde pro Datei gegen den gesicherten Anfangsstand (`git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --no-index --check BEFORE AFTER`); Exit 0/1 ohne Ausgabe, wobei 1 lediglich Unterschiede bedeutet. Zwei Dokument-Vorherkopien wurden durch exakt rückgängig gemachte eigene Ergänzungen rekonstruiert und gegen ihren vorab gespeicherten SHA256 bestätigt. Unveränderte gemischte Zeilenenden wurden erhalten.

Ohne `cr-at-eol` meldet Git bestehende CRLF als Whitespace: 38 der 52 Vergleiche betroffen, Auditbewertung 1. Das ist getrennt von tatsächlichen neuen Whitespacebefunden. `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check -- <eigene Dateiliste>` liefert **Exit 2** ausschließlich wegen vorbestehender Markdown-Doppelspaces in `DESIGN.md:162–164`. Repositoryweit liefert derselbe Befehl ohne Dateiliste ebenfalls **Exit 2** und zusätzlich die bekannten Altbefunde in `docs/alltag-zuhause-continuation.md:148/153`, `docs/arbeit-bildung-batch-1-import.md:127` und `docs/arbeit-bildung-batch-2-import.md:121`. Keine pauschale Bereinigung und keine Behauptung eines sauberen Gesamtarbeitsbaums.
