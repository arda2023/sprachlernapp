# Pack-Lesetest: Messdiagnose und Reparaturplan zur Abnahme

Stand: 14.10.2026. **Zwei belegte Engpässe:** Schema-4-Validierung in Dart und unindexierte Token-/Wörterbuchabfragen. Der instrumentierte Volltest benötigt **61.39s Testkörper /62.86s Gesamtprozess**. Installation und erneute Öffnung kosten **33.55s**, das Satzlesen **26.35s**. Eine zeilengleiche Diagnosekopie mit zwei Indizes reduziert das Satzlesen auf **1.00s**, lässt die Öffnung aber bei **33.46s**. **Kein Produktionsfix umgesetzt; Standard-Timeout bleibt offen.** Kleinstes vorgeschlagenes Reparaturpaket: lokale Nachschlageindizes in `validateFormContent` plus zwei Suchindizes im SQLite-Export. Zur Umsetzung ist eine weitere Planabnahme nötig.

## Basis, Vorgehen und Grenzen der Messung

Finaler Pack `business_email_batch_6_v1`, Schema 4, 14 Stapel, 3768 Karten, 3654 Übungen /3383 Wörter, Business 579/43 E-Mail. SQLite/Asset-SHA256 `843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9`; 22 Tabellen exakt gegen finalization_report.json bestätigt, integrity_check=ok. 22 automatische PK-Indizes, **0 explizite Zusatzindizes**. Nachweis [source-state.json](../build/pack_read_performance_checks/source-state.json). Der bekannte Liefer-Audit-Zählfehler ist unabhängig vom Timeout; maßgeblich bleibt die App-Projektion.

Bestehende Belege: Standard `flutter test --no-pub test/data/real_pack_test.dart`, Exit 1, 30s-Timeout, 41,19s Gesamtprozess. Historischer Langlauf mit `--timeout 3m`, Exit 0, 126,65s Gesamtprozess, **kein bewiesener SQL-/Testkörperwert und kein Standard-PASS**. Diese Läufe wurden nicht identisch wiederholt.

Der Harness [instrumented_pack_test.dart](../build/pack_read_performance_checks/instrumented_pack_test.dart) wird aus dem vollständig gelesenen Original erzeugt ([create_harness.py](../build/pack_read_performance_checks/create_harness.py)). Alle 195 ursprünglichen expect-Aufrufstellen, einschließlich versionsabhängiger Zweige, bleiben erhalten; 3626 Assertions tatsächlich im aktuellen Packlauf ausgeführt. Geändert werden nur Importpfad, Messwrapper, explizite Diagnosedateiauswahl und Ausgabe. `MeasuredInstaller` delegiert `install/open` an dieselben Produktionsfunktionen; `MeasuredRepository` delegiert sämtliche Lese-/Close-Aufrufe. Gruppenbildung und Assertions sind gesondert gestoppt. Kein zweites Repository implementiert, kein Ziel oder Satz übersprungen.

Monotone Stopwatches messen Phasen und Testkörper einschließlich temporärem Teardown. Der Prozesswrapper misst die gesamte Subprozessdauer separat. Differenz Prozess minus Testkörper: **1.47s** bzw. **3.63s**. Das umfasst Build/Start/Isolate/Registrierung/Shutdown; eine reine Compilerzeit ist daraus nicht bestimmbar. Main→Testbeginn ist im jeweiligen PERF_EVENT-Log beobachtbar (etwa 20ms). Keine CPU-Sampling-Messung einzelner innerer Dart-Schleifen. GC-/JSON-/Map-Anteile innerhalb des Validators sind nicht separat gemessen.

Installationsphase enthält Hashprüfung, Schreiben, Kandidatenvalidierung, Close und Rename; diese privaten Teilzeiten sind ohne Quelländerung nicht getrennt erreichbar. Asset-Lesen wurde mitgemessen (ca. 10–11ms für SQLite), vor/nachgelagerte vollständige Hashes zusammen ca. 0.298s. Die anschließende DB-Öffnungsphase wird exakt zwischen Rückkehr von install und Rückkehr von open gemessen, einschließlich Validierung, Versionscheck und Repository-Konstruktion. Teilwerte nicht durch ungemessene Annahmen ergänzt.

Umgebung: macOS-26.6.2-arm64-arm-64bit-Mach-O, Dart SDK 3.13.2, sqlite3-Dart-Paket 3.7.0, drift 2.35.1; Python 3.13.15. EXPLAIN-Ausgaben stammen von Python-SQLite 3.50.4, nicht von einem gemessenen nativen Dart-Planner. Die kausale Laufzeitwirkung wurde zusätzlich über den tatsächlichen Dart-Leseweg geprüft. Jeder Flutter-Lauf benutzt einen neuen Prozess und frisches Installationsverzeichnis. OS-Dateicache nicht geleert; Basis war durch Read-only-Prüfungen bereits gelesen, Kopie frisch geschrieben. Keine universellen Benchmarks aus Einzelläufen ableiten. Unterschied zu den historischen 126,65s bleibt hinsichtlich damaliger Last/JIT/Cachezustand unaufgelöst; beide neuen vollständigen Testkörper liegen weiterhin über 30s.

## Gemessene Laufzeitverteilung

| Phase | Basis, Sekunden | Zwei Indizes, Sekunden |
|---|---:|---:|
| Testkörper inkl. Teardown | 61.389437 | 35.928214 |
| Gesamtprozess | 62.860000 | 39.560000 |
| Installation inkl. Kandidatenvalidierung | 17.103647 | 16.801780 |
| DB öffnen nach Installation inkl. Validierung | 16.447706 | 16.653466 |
| Stapel laden und interne Metadaten-/Formabfragen | 0.307606 | 0.306459 |
| Sätze/Tokens/Metadaten lesen, alle Aufrufe | 26.354185 | 0.995021 |
| Davon letzter Allkarten-Aufruf, 3768 Karten | 13.463904 | 0.488891 |
| Explizite Selection-Metadatenaufrufe | 0.194604 | 0.194692 |
| Gruppenbildung in generischem Testzweig | 0.000714 | 0.000682 |
| Assertions | 0.027409 | 0.026902 |
| Raw-SQL-Erwartungen/Close vor Installation | 0.583815 | 0.554978 |
| Dateihashes vor/nach Test | 0.297739 | 0.314866 |
| Repository schließen | 0.000583 | 0.001148 |
| Temporäres Verzeichnis löschen | 0.000711 | 0.002897 |
| Übrige gemessene Körperzeit, u.a. Kontrollfluss/Logs | 0.011191 | 0.014677 |

Überlappung: Gesamtprozess, Testkörper, Installer-open-Gesamtzeit und der letzte Allkarten-Aufruf sind Summen/Teilmengen und dürfen nicht zusätzlich addiert werden. Asset-Load liegt innerhalb install. Die exklusiven Detailphasen werden im JSON gesondert summiert. 44 gemessene öffentliche Repository-Aufrufe in beiden Läufen; interne SQL-Zahl des Repositorys nicht öffentlich beobachtbar.

Teuerste Satzlesephasen nach Stapel; jeweils eine Produktion-API `practiceItems`, keine Token-Einzellogs:

| Stapel | Eingabekarten | Basis s | Indizes s |
|---|---:|---:|---:|
| allgemeine-sprache | 181 | 0.640515 | 0.030562 |
| reisen | 519 | 1.759531 | 0.073018 |
| alltag-zuhause | 262 | 0.972447 | 0.036498 |
| arbeit-bildung | 252 | 0.924254 | 0.035392 |
| menschen-beziehungen | 251 | 0.987790 | 0.036961 |
| koerper-gesundheit | 264 | 1.017806 | 0.037647 |
| essen-trinken | 250 | 0.931073 | 0.034836 |
| natur-umwelt | 248 | 1.005705 | 0.034434 |
| irregular_verbs_base | 129 | 0.445902 | 0.018588 |
| irregular_verbs_past | 0 | 0.000014 | 0.000014 |
| irregular_verbs_participle | 0 | 0.000013 | 0.000013 |
| alltagssprache-redewendungen | 441 | 1.429529 | 0.057855 |
| verbalphrasen | 181 | 0.619780 | 0.025499 |
| business-email | 579 | 2.155922 | 0.084813 |
| all_cards | 3768 | 13.463904 | 0.488891 |

Datenmengen: 3557 Eigentümerkarten in den Stapelschleifen, danach 3768 Karten insgesamt; 7325 Karten/Satzzuordnungen über diese Aufrufe. `_tokens` wird laut unverändertem Source pro zurückgegebener Satzzeile aufgerufen: daraus 7325 Aufrufe ableitbar, **kein SQL-Trace-Zähler**. Jeder öffentliche practiceItems-Aufruf umfasst auch selectionCards, Alternativen, Formmetadaten und Lemmaformen; genaue innere Aufteilung unbekannt. Hauptbeleg für den SQL-Anteil ist der kontrollierte Indexvergleich mit unverändertem Produktionscode.

## Vergleich 1: dominante Öffnungsphase

Öffentliche Validatoren einmal separat auf derselben vollständigen read-only SQLite aufgerufen. [validation_probe_test.dart](../build/pack_read_performance_checks/validation_probe_test.dart) delegiert Database.select unverändert und zählt tatsächliche Abfragen, Ergebniszeilen und Gesamtzeit; nicht implementierte Database-Operationen würden explizit abbrechen. Vollständige queryweise Werte: [validation-probe.json](../build/pack_read_performance_checks/validation-probe.json).

| Öffentlicher Validator | Gesamt s | SQL s inkl. ResultSet-Erstellung | SQL-Aufrufe | Gelieferte SQL-Zeilen |
|---|---:|---:|---:|---:|
| validateSingleSentenceContent | 0.668527 | 0.461518 | 10888 | 21803 |
| validateLearningGroups | 0.017108 | 0.002762 | 2 | 3786 |
| validateFormContent | 16.027222 | 0.098185 | 21 | 80739 |

**validateFormContent: 16,03s insgesamt, nur 0,098s in 21 select-Aufrufen.** Mehr als 99% dieser Phase entsteht außerhalb Database.select. Konkrete wiederholte Durchläufe in `lib/data/content/form_content_validation.dart`:

- Zeile 349: je aktivem Satzlink erneut alle aktiven sentence_tokens nach Satz/Offset/Karte filtern; `targets.length` traversiert den Filter vollständig.
- Zeile 364/367: je aktivem Satz erneut alle aktiven sentence_tokens filtern und sortieren.
- Zeile 396: je Worttoken aktive dictionary_forms mit `.any` durchsuchen und dabei Formnormalisierung wiederholen.

Die ersten beiden Schleifen erzwingen bei 3768 aktiven Links, 4302 Sätzen und 47082 Tokens bereits **379951740 Tokenprädikat-Prüfungen pro Validierung**, aus Source und Datenmengen abgeleitet. Das ist kein gemessener Instruktionszähler; zusätzliche Form-/Wörterbuchdurchläufe und erneute Iteratoren kommen hinzu. `.any` bricht früh ab, seine tatsächliche Prüfschrittzahl bleibt unbekannt. Kein einzelner innerer Loop wurde zeitlich isoliert. Belegt sind der Validator als Hauptphase, seine fast vollständig außerhalb von SQL liegende Zeit und die wiederholten Vollscans; eine exakte Prozentaufteilung zwischen diesen Schleifen fehlt.

`ContentPackInstaller.install` validiert den Kandidaten über ContentDatabase.open. `ContentPackInstaller.open` öffnet/validiert danach die installierte Datei erneut. Beide Prüfungen bleiben sinnvoll für die bestehende Sicherheits-/Austauschsemantik; der Plan entfernt keine davon.

## Vergleich 2: SQL-Ursache auf zeilengleicher Kopie

Nur `build/pack_read_performance_checks/indexed/` erhält zwei zusätzliche Indizes und ein an Kopie/Größe gebundenes Diagnosemanifest. Alle Zeilen sämtlicher 22 Tabellen, auch content_releases, sind als Multimengen exakt gleich; integrity_check=ok. Original-Asset und Manifest unverändert. Kopie **26095616 Bytes**, Original **23408640 Bytes**, Mehrbedarf **2686976 Bytes**.

```sql
CREATE INDEX perf_sentence_tokens_active
ON sentence_tokens(sentence_id,idx) WHERE removed_in IS NULL;
CREATE INDEX perf_dictionary_lookup_active
ON dictionary_forms(sense_id,form_norm,rank,id) WHERE removed_in IS NULL;
```

Dies ist ausschließlich ein Versuch, kein Stage-/Produktionsfix. `_tokens`-SQL aus dem aktuellen Source exakt extrahiert in [queries.json](../build/pack_read_performance_checks/queries.json). EXPLAIN vor Änderung: `SCAN t`, korrelierte Unterabfrage mit `SCAN df`, zwei temporäre Sortierbäume. Danach: `SEARCH t USING INDEX perf_sentence_tokens_active (sentence_id=?)`, `SEARCH df USING INDEX perf_dictionary_lookup_active (sense_id=? AND form_norm=?)`; keine dortigen temporären Sortierbäume. Ein Beispiel-ResultSet exakt gleich, alle Tabellen unverändert und sämtliche ursprünglichen Testassertions im Vollharness bestanden. Nachweis [index-comparison-preflight.json](../build/pack_read_performance_checks/index-comparison-preflight.json).

Satzlesephase **26,354s → 0,995s**, rund **26,5-fach schneller**. Öffnungsphase **33,552s → 33,456s**, praktisch gleich. Damit sind unindexierte Satz-/Wörterbuchabfragen als zusätzlicher Engpass kausal belegt; sie erklären die dominante Dart-Validierung nicht. Der indexierte Diagnosekörper bleibt mit **35,928s über 30s**. Kein Standard-PASS behauptet. Außer diesen zwei Vergleichen keine weitere Performance-Messreihe oder Originaltestwiederholung.

## Tatsächliche Aufrufkette und Bezug zur App

| Ort / Symbol | Tätigkeit |
|---|---|
| test/data/real_pack_test.dart:22, main/Testcallback | Tempverzeichnis, Assethash, Raw-SQL-Erwartungen, Installer.open |
| lib/data/content/content_pack_installer.dart:64, install | Asset-/Manifestprüfung, bedarfsweise Kandidat schreiben/validieren/ersetzen |
| lib/data/content/content_pack_installer.dart:125, open | install, ContentDatabase.open, Versionsabgleich, DriftContentRepository |
| lib/data/content/content_database.dart:423, ContentDatabase.open | native read-only Verbindung, query_only, validateContentSchema |
| lib/data/content/content_database.dart:68, validateContentSchema | quick_check, Spalten/Release, SingleSentence/Groups/Form-Validatoren |
| lib/data/content/form_content_validation.dart:8, validateFormContent | vollständige Form-/Token-/Wörterbuch-/Satzvalidierung |
| lib/data/content/drift_content_repository.dart:37, decks | Summaries, interne selectionCards/deckPracticeTargets |
| lib/data/content/drift_content_repository.dart:65/117, deckCardIds/selectionCards | Mitgliedschaften/Metadaten, _formTarget pro Karte |
| lib/data/content/drift_content_repository.dart:170, practiceItems | Metadaten, aktive Satzlinks, _tokens je Satz, _lemmaForms, _checked |
| lib/data/content/drift_content_repository.dart:248, _tokens | Token-SELECT mit Wörterbuch-Unterabfrage, UTF-16-Umrechnung |
| test/data/real_pack_test.dart:439, letzter practiceItems | sämtliche aktiven Karten, danach letzte Assertions und repo.close |

App: `lib/presentation/providers/database_providers.dart:56` `_contentOwner` ruft `(await ContentPackInstaller.forApp()).open()` auf; RepositoryOwner.acquire teilt dieselbe Verbindung, solange Provider-Leases bestehen. Bei Erstinstallation/Packwechsel erfolgt Kandidatenvalidierung plus Öffnungsvalidierung. Bei identischer installierter Prüfsumme entfällt Kandidatenersetzung, die anschließende Öffnungsvalidierung bleibt. **Die Hauptursache betrifft App und Test.** Native Geräte-/Release-Laufzeiten wurden nicht gemessen.

`lib/presentation/providers/story_learning_providers.dart` practiceResolverProvider → `lib/data/learning/practice_item_resolver.dart:26` PracticeItemResolver.load lädt alle Kartenmetadaten via selectionCards/allCardIds, nicht alle Übungssätze. `lib/presentation/providers/deck_providers.dart:21` decksProvider lädt Stapel und nur bis zu fünf zuletzt geübte Wörter je Stapel. `lib/presentation/practice/deck_session_controller.dart:114` DeckSessionController.start baut eine Queue und lädt bei Zeile 159 deren practiceItems; eine einzelne Lektion liest nicht doppelt den vollständigen Satzbestand. Der SQL-Engpass ist auch dort erreichbar, aber die Volltestdauer ist **keine belegte Nutzerwartezeit von zwei Minuten**. Kein echter Benutzerbestand für die Diagnose geöffnet.

## Abdeckungsabgleich

Der generische Stapeltest liest Eigentümerkarten: Basis-Verben 129 Eigentümerkarten, Präteritum/Partizip keine. Das ist keine Aussage, dass die anderen Formkarten ungeprüft bleiben: der abschließende allCardIds/practiceItems-Aufruf liest **alle 3768 Karten inklusive form_only** mit ihren festen aktiven Sätzen.

**Konkrete Lücken der Testbehauptung:** versionsspezifische 402-Formmitgliedschafts-/134-Identitäts-/cut/read/run-Assertions (Test Zeilen 296–407) laufen nur für alte Verben-/Alltag-Batches 1/2, nicht für business_email_batch_6_v1. decks() und der Schema-4-Validator erreichen Formmetadaten, doch die vollständige typisierte Stapelzuordnung wird für den Business-Pack nicht dort ausdrücklich gegen 134/134/134 asserted. Außerdem liest der echte Test **3768 aktive Satzzuordnungen**, nicht alle **4296 historischen Verknüpfungszeilen**; **528 archivierte Links** werden nicht über historicalSentence gelesen. Alle 47082 aktiven Tokenzeilen/4302 Sätze werden im Form-Validator geprüft; das ersetzt keinen expliziten historischen Repository-Lesetest. Der Test prüft die Repository-Tokenarrays nicht einzeln gegen jede SQL-Tokenzeile, `_tokens` kann ungültige Offsets überspringen; Installationsvalidierung prüft die Rohannotation. [coverage-audit.json](../build/pack_read_performance_checks/coverage-audit.json).

Diese Grenzen werden dokumentiert, keine Assertions entfernt, keine Testsuite ungefragt erweitert. Die separate Inhaltsabnahme bestätigte alle 22 Tabellen und 402/402 Formen; geplante Inhaltslieferung bleibt abgeschlossen.

## Kleinster Reparaturplan, noch nicht umgesetzt

**Paket 1 — linear nachschlagen im vorhandenen Validator.** Exakte Produktionsdatei `lib/data/content/form_content_validation.dart`, Funktion `validateFormContent(Database db)`, lokale Funktionen active/get und die drei genannten Schleifen. Einmal pro Aufruf aktive Tokenzeilen nach sentence_id gruppieren und Wörterbuchzeilen nach dem Tupel (lang,sense_id,form_norm) indexieren. Satzlink-Zielsuche und Satz-Tokenlisten greifen auf dieselbe vollständige Satzliste zu; Wörterbuchprüfung normalisiert die Tokenform einmal und prüft die passende Zeilenliste. Die existing require/get/live-Prüfungen, Sortierung nach idx, Lücken, Vollabdeckung, Unicode-Codepunktbezug, Alias-/Form-/Lexikalregeln und Reihenfolge bleiben erhalten. Keine neuen öffentlichen Schnittstellen.

Werte als Listen speichern, keine einzelne Zeile überschreiben: doppelte Zieltoken, doppelte Wörterbuchzuordnungen und konkurrierende Identitäten müssen weiterhin abgewiesen werden. Zusammengesetzte Schlüssel als Dart-Tupel/Records statt trennzeichenbasierter Strings; fehlende Schlüssel liefern leere Kandidatenliste und damit dieselben bestehenden Fehler. Keine Tokens/archivierten Satzkontexte herausfiltern, keine frühe Rückkehr aufgrund eines Hash-/Versionscaches.

Lebensdauer: ausschließlich innerhalb eines validateFormContent-Aufrufs. Bei Packwechsel vollständig neu aufgebaut; keine globale Cacheinvalidierung, kein Zustand über Verbindungen/Isolates, keine Gleichzeitigkeitssynchronisierung. Zusätzlicher Speicher O(Token- und Wörterbuchzeilen), bestehende Zeilen referenzieren statt kopieren. Ziel O(Tokens + Wörterbuch + Satzlinks + Sätze + Sortierung je Satz) für die ersetzten Hotloops; andere kleine Checks bleiben unverändert. Wirkung/Laufzeit dieser Änderung ist **noch ungemessen**. Beide Installer-Validierungen werden erhalten.

**Paket 2 — gemessene Suchindizes beim Export.** Exakte Produktionsdatei `pipeline/src/sprachpipe/export.py`, `export_sqlite(pack,path)`: nach vollständigem Zeilenschreiben in derselben temporären SQLite/Transaktion, vor Schließen und atomarem os.replace, die beiden obigen nicht eindeutigen Partialindizes erzeugen. Finale Namen sind Implementierungsdetails; Spalten, Filter und ORDER-BY-Semantik entsprechen dem Versuch. Bestehende `schema.columns_for`/Schema-1–4-Tabellen berücksichtigen; keine neue Content-Spalte, kein Schema-Versionssprung, unveränderte build_rows-Ergebnismenge, kein Laufzeit-Indexbau in read-only Dateien. Historische Packs behalten ihre Bytes. Zwei Indizes zusammen getestet; ihr jeweiliger Einzelanteil wurde nicht isoliert.

Aus der unveränderten finalen Auswahl/Inhaltsbasis in ein **neues Ausgabeverzeichnis** exportieren, 22 Tabellen samt IDs/Wort-/Form-/Lerngruppen/Sätzen/Tokens zeilengleich abgleichen. Vor Assetwechsel erneut Sicherung; vorhandenes `tool/stage_content_pack.dart` stageContentPack/verifyStagedPack aktualisiert SHA/Größe/Manifest. Beim nächsten App-Install ist der SHA anders: `ContentPackInstaller.install` ersetzt erst nach Kandidatenvalidierung; gleiche Inhalts-IDs erhalten Nutzerstände. RepositoryOwner schließt bestehende Verbindungen vor Austausch. Kein direkter Eingriff in installierte Lern-/Contentdateien und keine Schema-Migration für user.db.

**Begrenzter Umfang:** genau diese zwei Produktionsdateien plus passende Regressionstests. Installer, _tokens-Query, Antwort-/SRS-/Queue-/Synonymlogik, Zeitbudget und Original-Volltest bleiben bestehen. SQL-Batch-Umbau oder dauerhafter Cache sind nach den Messungen nicht nötig für dieses erste Paket. Sekundäre N+1-Formabfragen sind vorhanden, aber die explizite Metadatenphase ist ca. 0,195s und deshalb kein eigener Reparaturauftrag.

## Regressionen und Abnahme für den Folgeauftrag

- `test/data/form_content_test.dart`: vorhandene Mutationstests weiter bestehen; ergänzen nur doppelte Zieltokens/Dictionary-Zeilen, fehlende/verschobene Tokenabdeckung, Unicode-Offsets, aktive/inaktive Kandidaten und nullable geerbte Definitionen. Identische erlaubte Daten und Ablehnung defekter Daten, keine durch Indexaufbau verschluckten Duplikate.
- `pipeline/tests/test_pack_db_export.py`: Indizes bei unterstützten Schemas vorhanden, tatsächlicher Queryplan verwendet sie, 22 bzw. schemaabhängige Tabellen/alle Datenwerte erhalten; Fehler lässt vorhandene Exportdatei erhalten. Nicht-eindeutige Indizes dürfen keine Zeilen/Glossen erzwingen.
- Vorhandene gezielte `test/data/single_sentence_content_test.dart`, `test/data/content_repository_test.dart`, `test/data/stage_content_pack_test.dart`: feste/archivierte Sätze, Glossen/Tokenreihenfolge, Schema-1–4-Kompatibilität, korrupter Kandidat ersetzt gültigen Pack nicht. Gleiche Metadaten, IDs, gültige Alternativen und Unicode-Ergebnisse.
- Fresh- und Warm-Installation/Packwechsel auf temporären Contentverzeichnissen; keine echten user.db. Inhaltssummen 14 Stapel, 3768 Karten, 3654/3383, 579/43, Formen 134/134/134 und alle 22 Tabellen beibehalten. Historische Links erhalten. Die hier dokumentierte spezielle Form-/Historienassertionslücke gesondert zur Entscheidung vorlegen; sie wird durch den Performancefix weder verdeckt noch reduziert.
- **Erfolgsgate:** `flutter test --no-pub test/data/real_pack_test.dart` mit vorhandenem 30s-Budget, unverändertem Umfang und frischem Installationsverzeichnis PASS. Erst das ist der reguläre Nachweis. Vorher-/Nachher-Phasen mit dem gleichen Harness für Attribution protokollieren. Aktuelle indexierte Kopie mit 35,93s genügt ausdrücklich nicht. Zusätzlich gezielte Analyzer/Regressionen, Staging --verify und vollständiger Row-/Hashabgleich. Keine Garantie aus der unimplementierten Mapoptimierung.

macOS (Folgeauftrag, noch nicht ausgeführt):
```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_pack_db_export.py -q
```
Windows PowerShell:
```text
.\pipeline\.venv\Scripts\python.exe -m pytest pipeline\tests\test_pack_db_export.py -q
```
Beide Systeme:
```text
flutter test --no-pub test/data/form_content_test.dart test/data/single_sentence_content_test.dart test/data/content_repository_test.dart test/data/stage_content_pack_test.dart
flutter test --no-pub test/data/real_pack_test.dart
```

## Tatsächliche Diagnosebefehle und kurze Outputs

Ab Repository-Root. Dart/Flutter/Git auf macOS und PowerShell identisch; Pythonhilfen unter Windows mit vorhandener `.\pipeline\.venv\Scripts\python.exe` statt python3. Wrapper `build/pack_read_performance_checks/run_check.py NAME BEFEHL` speichert vollständigen Output ohne ANSI und command.json mit Exitcode/Laufzeit. Es wurde keine komplette Flutter-/Pipeline-Suite ausgeführt.

```text
node .gitnexus/run.cjs analyze --index-only
Lokaler Index neu aufgebaut, --index-only ohne Dokument-/Skillinjektion; Prozessauflösung mit Budget-/Receiver-Grenzen (siehe vollständiges Log).
Exit 0; Gesamtprozess 13.79s
```

```text
dart analyze build/pack_read_performance_checks/instrumented_pack_test.dart
Analyzing instrumented_pack_test.dart...

  error - instrumented_pack_test.dart:522:23 - Undefined class 'ContentManifest'. Try changing the name to the name of an existing class, or creating a class with the name 'ContentManifest'. - undefined_class
   info - instrumented_pack_test.dart:514:27 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print
   info - instrumented_pack_test.dart:552:3 - Don't invoke 'print' in production code. Try using a logging framework. - avoid_print

3 issues found.
Exit 3; Gesamtprozess 0.95s
```

```text
dart analyze build/pack_read_performance_checks/instrumented_pack_test.dart
Analyzing instrumented_pack_test.dart...

warning - instrumented_pack_test.dart:421:20 - The diagnostic 'avoid_print' doesn't need to be ignored here because it's already being ignored. Try removing the name from the list, or removing the whole comment if this is the only name in the list. - duplicate_ignore
warning - instrumented_pack_test.dart:447:20 - The diagnostic 'avoid_print' doesn't need to be ignored here because it's already being ignored. Try removing the name from the list, or removing the whole comment if this is the only name in the list. - duplicate_ignore
warning - instrumented_pack_test.dart:461:18 - The diagnostic 'avoid_print' doesn't need to be ignored here because it's already being ignored. Try removing the name from the list, or removing the whole comment if this is the only name in the list. - duplicate_ignore

3 issues found.
Exit 2; Gesamtprozess 0.92s
```

```text
dart analyze build/pack_read_performance_checks/instrumented_pack_test.dart
Analyzing instrumented_pack_test.dart...
No issues found!
Exit 0; Gesamtprozess 0.83s
```

```text
flutter test --no-pub --reporter expanded --timeout 3m build/pack_read_performance_checks/instrumented_pack_test.dart
PERF body=61.389437s open=33.551985s practice=26.354185s; 14 decks /3768 fixed assignments /204 alternatives; All tests passed!
Exit 0; Gesamtprozess 62.86s
```

```text
dart analyze build/pack_read_performance_checks/validation_probe_test.dart
Analyzing validation_probe_test.dart...
No issues found!
Exit 0; Gesamtprozess 0.88s
```

```text
flutter test --no-pub --reporter expanded --timeout 3m build/pack_read_performance_checks/validation_probe_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/pack_read_performance_checks/validation_probe_test.dart
00:00 +0: diagnostic public validators: unchanged full staged schema-4 data
Shell: VALIDATION_PHASE {"phase":"validateSingleSentenceContent","us":668527,"sql_calls":10888,"sql_us":461518,"sql_rows":21803}
Shell: VALIDATION_PHASE {"phase":"validateLearningGroups","us":17108,"sql_calls":2,"sql_us":2762,"sql_rows":3786}
Shell: VALIDATION_PHASE {"phase":"validateFormContent","us":16027222,"sql_calls":21,"sql_us":98185,"sql_rows":80739}
00:17 +1: All tests passed!
Exit 0; Gesamtprozess 18.66s
```

```text
python3 build/pack_read_performance_checks/prepare_index_comparison.py
PASS: 22 Tabellen zeilengleich; Originalhash erhalten; SCAN t/SCAN df → SEARCH über zwei Indizes; Kopie 26095616 Bytes.
Exit 0; Gesamtprozess 0.31s
```

```text
flutter test --no-pub --reporter expanded --timeout 3m --dart-define=PERF_VARIANT=indexed build/pack_read_performance_checks/instrumented_pack_test.dart
PERF body=35.928214s open=33.455909s practice=0.995021s; gleiche vollständigen Assertions; All tests passed!
Exit 0; Gesamtprozess 39.56s
```


Die PERF-Zeilen oben sind aus den tatsächlichen JSON-Messlogs verdichtet, keine wörtlichen vollständigen stdout-Zeilen. Vollständige Logs: [Basis](../build/pack_read_performance_checks/baseline-instrumented.log), [Validator](../build/pack_read_performance_checks/comparison-1-validation.log), [Indexvergleich](../build/pack_read_performance_checks/comparison-2-indexed.log), [Index-/Zeilennachweis](../build/pack_read_performance_checks/comparison-2-preflight.log), [alle Phasen](../build/pack_read_performance_checks/summary.json).

Harness-Analyse zuerst Exit 3 wegen fehlendem ContentManifest-Import; danach Exit 2 wegen doppelter Diagnose-Logging-Ignore-Kommentare. Import korrigiert und zusätzliche Diagnoseausgabe über stdout geschrieben; finale gezielte Analyse Exit 0. Keine Validatoren, Testbudgets oder Produktionswarnungen abgeschwächt. Zwei frühe Dateipfadsondierungen fanden keine app_providers.dart/practice_providers.dart; tatsächliche Pfade anschließend per Imports/rg ermittelt. Ein `dart --version`-Wrapperzugriff auf SDK-Cache wurde vom Sandbox-Dateisystem verweigert; Version direkt vom vorhandenen SDK-Binary gelesen. Kein Paketupgrade/Installationsversuch. Diese Diagnosecode-/Sondierungsbefunde sind keine Contentfehler.

## GitNexus, Bestandsschutz und Commitgrenze

Ausgangsindex elf Commits zurück. Lokale Aktualisierung `node .gitnexus/run.cjs analyze --index-only`, Exit 0: HEAD `7e7bbc3397f9dd159fcd4979d0ec8c83acf8d107`, 17671 Knoten/35022 Beziehungen. MCP öffnete den neuen Index nach seiner Refresh-Verzögerung; unmittelbar vorherige Anfragen zeigten noch alte Staleness. Aktuelle context-Ergebnisse bestätigen Installer.open, selectionCards und practiceItems mit direkten Callees; offene Receiver-/Interface-Grenzen bleiben ausdrücklich bestehen. Top-Level validateContentSchema/validateFormContent sind trotz aktueller Datei nicht als Symbol auflösbar (**UNKNOWN**), Source und gemessene öffentliche Aufrufe bestätigen sie. File-Impact form_content_validation.dart LOW, 7 Dokument-/Codeimporte; export_sqlite LOW, ein direkter cmd_export-Aufrufer. Exporter wird zusätzlich aus finalize_curation.py:274 gerufen, diese Importbindung ist in der beschränkten Symbolsicht nicht vollständig repräsentiert.

**Warnung: `_tokens`-Impact CRITICAL**, im vollständigen Summary 254 erreichbare Symbole /130 Prozesse, direkte Caller practiceItems und historicalSentence. Die Graphliste enthält breite namengleiche Pipelinepfade und ersetzt keine bestätigte App-Aufrufkette. Der CRITICAL-Befund wird nicht durch riskSharedAxes heruntergestuft. Der Plan editiert _tokens nicht; geänderte Suchpläne benötigen trotzdem die genannten semantischen Reader-Regressionen. NEXTSTEPS/neuer Bericht/Build-Harness besitzen keine ausreichende Caller-/Symbolabdeckung; UNKNOWN ist keine Nullrisikofreigabe. [GitNexus-Rohbelege](../build/pack_read_performance_checks/gitnexus-evidence.json), [Indexrefresh](../build/pack_read_performance_checks/gitnexus-refresh.log). Prozesslisten sind im Analyzer budgetbegrenzt; fehlende Prozesse sind keine Abwesenheitsbelege.

3260 Ausgangsdateien inklusive Assets/current pack erfasst; Index vor Beginn leer. Produktionscode, Originaltest, Timeout-/Analyserkonfiguration, Asset/Manifest und historische Inhalte bleiben anhand Ausgangshashes erhalten. Erlaubte bestehende Änderung ausschließlich NEXTSTEPS; neuer Bericht und isolierte Build-Diagnoseartefakte. Keine echte user.db/Lernstände/Reviews, Cloud-/Modellaufrufe, Inhalts-/Glossen-/Auswahl-/Registry-/Gruppenänderungen oder öffentliche Freigabe. Gitignored Buildartefakte bleiben lokal; isolierter Dokumentationscommit nur für diesen neuen Bericht, vorbestehende NEXTSTEPS-Anteile ausgeschlossen. Repositoryweite Altbefunde werden nicht bereinigt.

**Plan zur Abnahme bereit.** Noch fehlender Nachweis: Umsetzung beider kleinen Änderungen, Semantik-/Exportregressionen, regulärer Originaltest-PASS innerhalb 30s und Geräteprüfung. Die heutige Diagnose ist keine Behebung.

## Abschließender tatsächlicher Bestandsschutz

```text
python3 build/pack_read_performance_checks/verify_protection.py
PASS: 3260 Ausgangsdateien geprüft; ausschließlich NEXTSTEPS.md geändert.
Neuer Git-sichtbarer Anteil: docs/pack-read-performance-diagnosis.md.
Originaltest, Produktionscode, Asset/Manifest und aktuelle Packdateien bytegleich.
Exit 0
git diff --check -- docs/pack-read-performance-diagnosis.md NEXTSTEPS.md
[keine Ausgabe]
Exit 0
```

| Geschütztes Objekt | Ausgangs-/Schluss-SHA256 |
|---|---|
| test/data/real_pack_test.dart | `1e26c91844fcc7692f08c279b085dc4a66aeb11b4014ce841377ea2ce1358551` |
| assets/content/en/content.sqlite | `843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9` |
| assets/content/en/content.manifest.json | `e7d08191f670df2b96d4401ac0891b2f49412661f106ba930de4f831f86b0abf` |
| lib/data/content/form_content_validation.dart | `55270396b24571a0f372f688f802c6783d264d2f255f7ff6569e2e57b0de654f` |
| pipeline/src/sprachpipe/export.py | `d3afb385ace060d49a663e04d5da7505305a73677e7cd82e835f0f1ab2f09f2f` |

Vollständiger Nachweis [protection.json](../build/pack_read_performance_checks/protection.json) / [protection.log](../build/pack_read_performance_checks/protection.log). NEXTSTEPS: 25 Zeilen. Bekannte historische Whitespace-/CRLF-Befunde in DESIGN und früheren Inhaltsberichten sind keine neuen Änderungen dieses Auftrags und wurden nicht bereinigt. Neue Datei zusätzlich direkt auf Whitespace geprüft. Graph-Änderungsprüfung und isolierter Commitstatus werden im Prüfverzeichnis gespeichert; keine Buildartefakte oder vorbestehenden NEXTSTEPS-Anteile im Commit.

Vor Commit: `detect_changes(scope="all")` erfasst vier NEXTSTEPS-Abschnitte, keine ermittelten Prozesse. `scope="staged"` erfasst genau den neuen Bericht, null zugeordnete Symbole/Prozesse, keine partial-/truncated-Markierung. Der neue Bericht ist nicht indexiert; null ist fehlende Symbolabdeckung, keine Freigabe eines Produktionsfixes. Staged-Whitespacecheck: keine Ausgabe, Exit 0. Rohbeleg [gitnexus-changes.json](../build/pack_read_performance_checks/gitnexus-changes.json).
