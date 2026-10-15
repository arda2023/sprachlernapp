# Pack-Leseperformance: lokaler Validatorindex und SQLite-Suchindizes

Stand: 15.10.2026. Reguläres Gate **PASS**, unveränderter `flutter test --no-pub test/data/real_pack_test.dart`: `00:08 +1: All tests passed!`, Exit 0, **10,84s Gesamtprozess**. Das bestehende 30s-Testbudget und die gesamte Abdeckung sind unverändert. Instrumentierter Testkörper **61,389437s → 8,046298s (7,63×)**. Keine Gerätemessung oder öffentliche Inhaltsfreigabe.

## Umsetzung und Semantik

Genau zwei Produktionsfunktionen geändert: `validateFormContent` in `lib/data/content/form_content_validation.dart` gruppiert aktive Token einmal nach Satz-ID und aktive Wörterbuchzeilen nach dem Record `(lang, sense_id, form_norm)`. Beide Werte sind vollständige Listen vorhandener Zeilenreferenzen. Zielsuche und Satzabdeckung nutzen die Satzliste; Sortierung, Anzahlprüfung, Codepoint-Offsets, get/require/live und Altdefinitionen bleiben erhalten. Nur die Tokenform der Wörterbuchprüfung wird einmal normalisiert; gespeicherte Formwerte unverändert. Fehlende Schlüssel liefern leere Listen. Keine last-write-wins-Verluste, kein dauerhafter Cache. Beide Installer-Validierungen bestehen weiter.

Der tatsächliche Altvertrag lehnt doppelte **aktive identische** Wörterbuch-Tupel bereits am Ende der Funktion ab (`dictionaryKeys`). Diese Prüfung ist unverändert. Unterschiedliche Senses/Formen bzw. inaktive Zeilen werden nicht durch neue Regeln verboten; es gibt keine neue UNIQUE-Constraint. Mehrere Formen pro Sense und gleich geschriebene Formen verschiedener Senses bleiben über die vorhandenen Fixtures und den vollständigen Pack erhalten.

`export_sqlite` in `pipeline/src/sprachpipe/export.py` erstellt nach allen Zeilen in derselben temporären Datenbank/Transaktion:

```sql
CREATE INDEX idx_sentence_tokens_active_sentence_idx
ON sentence_tokens(sentence_id,idx) WHERE removed_in IS NULL;
CREATE INDEX idx_dictionary_forms_active_lookup
ON dictionary_forms(sense_id,form_norm,rank,id) WHERE removed_in IS NULL;
```

`columns_for(1/2/3)` liefert LEGACY_COLUMNS, `columns_for(4)` COLUMNS; beide Tabellen und alle benötigten Spalten sind in allen vier unterstützten Wegen vorhanden. Deshalb kein Fallback nötig. Tabellen, Spalten, Schema, build_rows und atomarer Close/Replace-/Fehlerpfad unverändert. DDL-Regressionsprüfung parametrisiert Schema 1–4 mit isoliertem build_rows-Stub; echte Inhaltsvalidierung wird separat durch die übrigen Exporttests und den vollständigen Schema-4-Export geprüft. Kein Indexbau im App-Leser.

## Vergleichbare Diagnose

Basis aus [vorheriger Diagnose](pack-read-performance-diagnosis.md); keine identische Baseline wiederholt. Vor Beginn stimmen Asset- und Originaltesthash exakt. Derselbe bestehende Harness wurde einmal **ohne PERF_VARIANT=indexed** ausgeführt. Sein Standardpfad ist `assets/content/en`; geladene Dateigröße 26095616, vor/nachher identischer neuer Hash. 44 öffentliche Aufrufe und 3626 ausgeführte Assertions in beiden Messungen. Alte Diagnose-JSONs vor Überschreiben gesichert und anschließend wiederhergestellt; neue Ergebnisse unter [after-metrics.json](../build/pack_read_performance_fix_checks/after-metrics.json).

| Phase | Vorher s | Nachher s | Verhältnis |
|---|---:|---:|---:|
| Testkörper inkl. Teardown | 61.389437 | 8.046298 | 7.63× |
| Installation inkl. Kandidatenvalidierung | 17.103647 | 2.413899 | 7.09× |
| Öffnen nach Installation inkl. Validierung | 16.447706 | 1.578393 | 10.42× |
| Installer.open gesamt | 33.551985 | 3.993273 | 8.40× |
| Satzlesen, alle Aufrufe | 26.354185 | 1.995535 | 13.21× |
| Letzter Allkarten-Aufruf | 13.463904 | 1.002041 | 13.44× |
| Assertions | 0.027409 | 0.048002 | 0.57× |

Diagnose-Gesamtprozess: 62,86s → 10.12s. Gesamtprozess, Testkörper und überlappende Teilphasen nicht addieren. Regulärer Testprozess separat 10,84s, Anzeige 00:08; eine exakte innere Körperzeit des unveränderten regulären Tests wird nicht behauptet. Historische 126,65s Gesamtprozess sind kein Vergleichswert für diese Phasen.

Direkte Validatorprobe: `validateFormContent` **16,027222s → 0,834561s (19,20×)**; weiterhin 21 SQL-Aufrufe /80739 Ergebniszeilen, SQL-Zeit 0,098185s → 0,141571s. SingleSentence 1,233519s und LearningGroups 0,032056s im neuen Probeprozess. Einzelmessungen, keine isolierte GC-/Heap-/CPU-Profilierung. Satzlesen 26,354185s → 1,995535s (13,21×); der frühere reine Indexversuch lag bei 0,995021s. Diese Streuung wird nicht als zusätzlicher Regressionsbefund oder universeller Faktor ausgegeben.

Regelfall App: gleiche installierte Prüfsumme überspringt Kandidatenersetzung; Öffnungsvalidierung bleibt. Erstinstallation/Packwechsel validieren Kandidat und geöffnete Datei. Der Volltest liest darüber hinaus alle Karten mehrfach; seine Laufzeit ist keine gemessene Nutzerwartezeit. Keine native Release-/Gerätebeschleunigung behauptet.

## Inhalt, Export und Staging

Quelle unverändert `pipeline/out/business_email_batch_6_v1/pack.json`; neuer Ordner `pipeline/out/business_email_batch_6_perf_v1/`. Pack-JSON bytegleich kopiert, keine Regeneration. Releasekennung `business_email_batch_6_v1`, Schema 4 bleiben erhalten. Installer vergleicht SHA; technische neue Versionskennung ist nicht erforderlich.

[export_verify.py](../build/pack_read_performance_fix_checks/export_verify.py) ruft den vorhandenen CLI-Export und `finalize_curation.check_sqlite` auf, vergleicht zusätzlich alle 22 Tabellen als vollständige Zeilen-Multimengen mit dem Original. `finalization_report.json` startet mit failed und erhält ok erst nach bestandenen Prüfungen. Keine übernommenen Erfolgseinträge. Einzige Metadatenabweichung: exportgeneriertes `content_releases.created_at`, 2026-10-14T10:21:40.690419+00:00 → 2026-10-15T14:17:37.689243+00:00. Alle anderen Werte einschließlich 4296 Links (3768 aktiv/528 historisch), 47082 Tokens, 4302 Sätzen, IDs, Glossen, Gruppen, Besitz und Formtabellen gleich. integrity_check=ok.

App-Projektion über das vorhandene `report_learning_groups.dart`: **14 Stapel, 3768 Karten, 3654 Übungen /3383 lexikalische Ziele, Business 579 einschließlich 43 E-Mail-Zielen**, Formansichten 134/134/134. Die 43 E-Mail-Ziele folgen aus der vollständig identischen Inhaltsbasis und bestehenden Batch-6-Abnahme; die Gesamt-/Formzahlen zusätzlich frisch über App-Projektion geprüft. [Projektionsausgabe](../build/pack_read_performance_fix_checks/projection-summary.json).

Original-SHA: `843c127e2e4cdd0d0efd5c52f648db30adcb3a477e0bfd3f9a66eed869dfb1f9`.
Neuer Asset-SHA: **`4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`**.
Originaltest-SHA unverändert: `1e26c91844fcc7692f08c279b085dc4a66aeb11b4014ce841377ea2ce1358551`.

Sicherung vor Staging: 15.10.2026 16:17:39 MESZ /14:17:39 UTC, [backup.json](../build/pack_read_performance_fix_checks/backup.json); Asset und Manifest unter `build/pack_read_performance_fix_checks/backup-before-stage/`, Manifest-SHA `e7d08191f670df2b96d4401ac0891b2f49412661f106ba930de4f831f86b0abf`. Stage und --verify PASS, alle 22 Tabellenzahlen bestätigt. Neuer Manifestpfad verweist auf den neuen Export. Asset/Manifest und Export bleiben gemäß bestehender Konvention gitignoriert.

Dateigröße **23408640 → 26095616 Bytes**, **+2686976 Bytes (~2,56 MiB /11,48%)**. Validator-Zusatzspeicher O(Tokens + Wörterbuchzeilen): 47082 Token- und 8089 Wörterbuch-Zeilenreferenzen plus Listen/Map-/Record-Verwaltung, keine Kopien der Zeilendaten. Exakte Heapbytes nicht gemessen; satzweise sortierte Listen bleiben wie zuvor kurzlebig.

Realer Query-Plan verwendet `SEARCH t USING INDEX idx_sentence_tokens_active_sentence_idx` und `SEARCH df USING INDEX idx_dictionary_forms_active_lookup`. Keine versionsabhängigen vollständigen EXPLAIN-Texte in Assertions; Definitionen/Spalten/Partial-/Nonunique-Eigenschaften und Indexnamen im Plan geprüft. [Vollständiger Tabellen-/Indexnachweis](../build/pack_read_performance_fix_checks/export-verification.json).

## Tests und tatsächliche Befehle

Neue gezielte Regressionen: doppelte Zieltoken, fehlende/verschobene Abdeckung, inaktive Zieltoken/Wörterbuchkandidaten, unverändert gespeicherte Formnormalisierung; vorhandene nullable-Definition-/Alias-/Formkonflikt- und Unicode-/Historien-/Reader-Tests bleiben bestehen. Exportfehler beim ersten **und** zweiten Index erhalten vorhandenes Ziel bytegleich und entfernen temporäre Dateien. Vier bestehende Dart-Testdateien: **51 PASS**; Python: **30 PASS**; Analyse: `No issues found!`.

Temporärer [Installationsharness](../build/pack_read_performance_fix_checks/install_lifecycle_test.dart): neuer vollständiger Pack, gleiche Prüfsumme ohne Dateiersetzung (gesetzter Änderungszeitpunkt bleibt), alte Verbindung schließen, alter→neuer Pack mit gleicher Versionskennung, semantisch korrupter Kandidat mit korrektem Hash/Größe abgewiesen und gültige Datei erhalten. **PASS**. Ausschließlich temporäre Verzeichnisse, keine echte user.db oder installierte Appdatei.

Alle Läufe durch `build/pack_read_performance_fix_checks/run_check.py` mit monotoner Prozesszeit und gespeichertem argv/Exitcode. Befehle ab Repository-Root, macOS mit vorhandener venv:

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_pack_db_export.py -q
pipeline/.venv-macos/bin/sprachpipe export --help
pipeline/.venv-macos/bin/python build/pack_read_performance_fix_checks/export_verify.py
```

Der letzte Befehl führt exakt aus:

```text
pipeline/.venv-macos/bin/sprachpipe export pipeline/out/business_email_batch_6_v1/pack.json pipeline/out/business_email_batch_6_perf_v1/content.sqlite
```

Windows PowerShell: entsprechende vorhandene Programme `.\pipeline\.venv\Scripts\python.exe` und `.\pipeline\.venv\Scripts\sprachpipe.exe`, gleiche Argumente. Windows wurde hier nicht ausgeführt. Export-Prüfscript verlangt einen noch nicht existenten Zielordner; kein unkontrolliertes Wiederholen auf dem fertigen Export.

Windows PowerShell und macOS Terminal (identisch):

```text
flutter test --no-pub test/data/form_content_test.dart test/data/single_sentence_content_test.dart test/data/content_repository_test.dart test/data/stage_content_pack_test.dart
flutter analyze --no-pub
dart run tool/stage_content_pack.dart --from pipeline/out/business_email_batch_6_perf_v1
dart run tool/stage_content_pack.dart --verify
flutter test --no-pub test/data/real_pack_test.dart
flutter test --no-pub --reporter expanded --timeout 3m build/pack_read_performance_checks/instrumented_pack_test.dart
flutter test --no-pub build/pack_read_performance_fix_checks/install_lifecycle_test.dart
flutter test --no-pub --reporter expanded --timeout 3m build/pack_read_performance_checks/validation_probe_test.dart
dart run tool/report_learning_groups.dart pipeline/out/business_email_batch_6_perf_v1/content.sqlite
node .gitnexus/run.cjs analyze --index-only --pdg
node .gitnexus/run.cjs status --json
git diff --check
git status --short
```

| Lauf | Exit | Gesamtprozess s | Beleg |
|---|---:|---:|---|
| python-tests | 0 | 1.08 | [Output](../build/pack_read_performance_fix_checks/python-tests.log) |
| dart-tests | 0 | 8.50 | [Output](../build/pack_read_performance_fix_checks/dart-tests.log) |
| export-verify | 0 | 5.24 | [Output](../build/pack_read_performance_fix_checks/export-verify.log) |
| stage | 0 | 7.54 | [Output](../build/pack_read_performance_fix_checks/stage.log) |
| verify | 0 | 4.81 | [Output](../build/pack_read_performance_fix_checks/verify.log) |
| real-pack | 0 | 10.84 | [Output](../build/pack_read_performance_fix_checks/real-pack.log) |
| instrumented | 0 | 10.12 | [Output](../build/pack_read_performance_fix_checks/instrumented.log) |
| lifecycle | 0 | 19.18 | [Output](../build/pack_read_performance_fix_checks/lifecycle.log) |
| validation-probe | 0 | 4.48 | [Output](../build/pack_read_performance_fix_checks/validation-probe.log) |
| projection | 0 | 5.68 | [Output](../build/pack_read_performance_fix_checks/projection.log) |
| analyze | 0 | 4.64 | [Output](../build/pack_read_performance_fix_checks/analyze.log) |

## GitNexus, Isolation und Grenzen

Ausgangs-HEAD `175f7c2cef63071193cffe976c417c7a4ae6927f`; eigener Branch `codex/pack-read-performance-fix`. Index vor Impact auf diesen HEAD aktualisiert, Runner 1.6.12 /Identity-Schema 4 current, incompleteReasons leer, status up-to-date; nach Code-/Teständerungen erneut aktualisiert. Build-/Dependency-Digests und Quellstand im [Statusbeleg](../build/pack_read_performance_fix_checks/gitnexus-final-status.json). MCP-Abfragen zeigen einen veralteten ein-Commit-Stalenesshinweis aus ihrem Cache; typed Resource und CLI belegen den aktuellen Commit. CLI-Impact zusätzlich gespeichert.

Validator **HIGH**, 9 erreichte Symbole: direkt validateContentSchema, darüber ContentDatabase.open, Installer.install/open und Stage/Verify sowie zwei Tool-Prozesse. Exporter **LOW**, direkt cmd_export; Finalisierungsaufruf zusätzlich im Source bestätigt. Frühere `_tokens`-Warnung **CRITICAL** bleibt berücksichtigt, selbst wenn die jetzige exakt eingegrenzte Methodensicht LOW/3 Symbole meldet. Direkte Reader-Aufrufer sind practiceItems und historicalSentence. Keine Änderung dieser Methode. Globale Prozessauflistung ist budgetbegrenzt und beweist keine vollständige Abwesenheit weiterer Pfade. Test-main und NEXTSTEPS UNKNOWN durch fehlende Caller; Einstieg/Referenzen anhand Quelltext geprüft, keine Nullrisikofreigabe daraus.

Anfangsfehler: GitNexus-Refresh EPERM auf ~/.gitnexus/Registry-Lock, Flutter-SDK-Cache EPERM sowie Branch-Ref-Schreiben im Sandboxmodus; mit genehmigtem lokalen Zugriff erfolgreich wiederholt. Erster CLI-Hilfeversuch `python -m sprachpipe export --help` scheiterte mangels __main__; vorhandener pyproject-Einstieg `sprachpipe` danach verwendet. Keine Installation/Abhängigkeitsänderung. Keine funktional fehlgeschlagenen Tests, keine Timeout-Anhebung am Originaltest.

Geänderte eigene Dateien: zwei Produktionsdateien, `test/data/form_content_test.dart`, `pipeline/tests/test_pack_db_export.py`, dieser Bericht und lokales NEXTSTEPS. Neue lokale Artefakte: Prüfverzeichnis, neuer Export, kontrolliertes Asset/Manifest. Bestandsschutz umfasst 3261 Ausgangsdateien; historische Quellen und fremde Dateien bleiben bytegleich. NEXTSTEPS war vor Beginn geändert und bleibt vollständig außerhalb des Commits; Ausgangsversion/-Patch gesichert. Kein git add -A, kein Push.

Offen bleiben spezielle versionsabhängige 402-Formmitgliedschaftsassertions im Volltest und explizite historische Repository-Lesepfade für alle 528 archivierten Links. Global liest der Test weiterhin sämtliche 3768 aktiven Kartensätze. Vollständiger Zeilenvergleich ersetzt keine zusätzliche historische Reader-Abdeckung. Altglossen-/Labelredaktion, Geräteprüfung und öffentliche Sprachfreigabe bleiben offen. Keine Cloud-/Modellaufrufe, neuen Stapel, Inhaltsänderungen, Lernstands-/user.db-Migration oder Veröffentlichung.

## Abschlussprüfung und Graphgrenzen

`detect_changes(scope=all)` nach vollständigem Neuaufbau: 5 geänderte getrackte Dateien, 9 Symbole, keine zugeordneten Prozesse; keine partial-/truncated-Markierung. Der inkrementelle Index hatte zuvor beschädigte Kennungen/Dateipfade geliefert. `analyze --index-only --pdg --force` repariert diese (Exit 0, 32,6s); erneuter context liefert korrekte UID, Datei und validateContentSchema-Aufruf. Finale Runneridentität current, incompleteReasons leer und Quellstand aktuell.

Verbleibende Analyzergrenze: Dart-Funktionsbereiche werden hier nur als Deklarationszeile gespeichert (`validateFormContent` startLine=endLine=8), sodass Körperänderungen nicht automatisch in detect_changes erscheinen. Deshalb den tatsächlichen Diff manuell auf genau validateFormContent und Test-main abgegrenzt und expliziten Validator-Impact erneut geprüft; HIGH bleibt maßgeblich, nicht das niedrige aggregierte detect_changes-Urteil. Keine unerwartete Produktionsdatei geändert. Python-Exporter und neue Exporttests werden nach Neuaufbau korrekt erfasst. Neuer Bericht wird erst nach gezieltem Staging im Commit-Gate erfasst.

Abschließender Bestandsschutz: `python3 build/pack_read_performance_fix_checks/verify_protection.py`, Exit 0: 3261 Dateien, ausschließlich sieben erlaubte bestehende Dateien geändert und dieser Bericht neu; NEXTSTEPS genau 25 Zeilen. Erstlauf des Prüfscripts klassifizierte die bei der Baseline absichtlich ausgelassenen `.env.example`-Pfade irrtümlich als neu; gleicher Filter und separater `git diff --quiet` (Exit 0) bestätigen unveränderte Beispieldateien. Keine Geheimnisdatei gelesen. `git diff --check`: keine Ausgabe, Exit 0. Prüflogs/Commitbeleg bleiben im lokalen Nachweisverzeichnis.
