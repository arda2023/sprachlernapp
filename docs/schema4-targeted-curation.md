# Gezielte Schema-4-Kuration

## Vertrag vor Umsetzung (16.10.2026)

Bestehender Einstieg `pipeline/scripts/import_editorial_patch.py --targeted PATCH --source PACK --out NEUES_VERZEICHNIS`. Eigenes explizites Austauschformat `sprachapp.targeted-curation`, `format_version: 1`, nur Schema 4. Keine Änderungen am Vollkorpusmodus (`verify_exchange`), `content_contract.transition` oder Create-Modus. Kein neuer Transport: vorhandene `removed_in`/`replaced_by`-Tombstones, 22 Tabellen und Schema 4 bleiben.

Patchfelder exakt: `format`, `format_version`, `source_sha256` (Rohbytes), `version` (neues Release), `reviewer`, `operations`. Jede Operation hat `op`, `card_id`, `expect_card` (vollständige Quell-Kartenzeile inklusive Textfelder), `reason`. Pro Karte genau eine Operation; unbekannte Felder, inaktive/fehlende Ziele, veraltete Preconditions und erneute Anwendung werden abgewiesen. Keine Mutation der Eingaben, keine automatische Freigabe unbeteiligter Zeilen.

- `card_gloss`: zusätzlich `translation_de`; ausschließlich diese Metadaten ändern, ID bleibt.
- `replace_sentence`: zusätzlich `sentence_id`, `expect_sentence`, `expect_link` (je vollständige Quellzeile), `sentence`, `tokens`, `link`, `alternatives_checked`. Neue Satzreferenz/-identität, Linkposition 1; bestehende Stable-ID-/Gap-/Tokenizerfunktionen. Vollständige Annotation mit existierenden Lemma-/Sense-/Wörterbuchreferenzen erforderlich; keine implizite Wortschatzergänzung. Alternativenprüfung enthält die vollständigen eingesetzten Sätze. Nur alter Link erhält `removed_in` und `replaced_by`; alte Satz-/Token-/Alternativdaten unverändert, auch bei geteiltem Satz. Form-only und Formfunktion bleiben erhalten.
- `retire_card`: keine Zusatzfelder. Nur selbstrepräsentierter Singleton ohne Ersatz, aktiven Wortbesitz oder Form-/lexikalische Mitgliedschaften. Keine Besitzer-/Positionsänderungen. Eigene aktive Links, ausschließlich dafür verwendete Sätze/Token sowie gebundene Wörterbuchzeilen erhalten Tombstones. Geteilte aktive Kontexte/Stories werden abgewiesen statt implizit geändert. Historische IDs bleiben lesbar. Eine nicht unterstützte strukturelle Rückstellung ist ein Fehler, kein automatisches Umsortieren.

Historische Singletonvalidierung verlangt genau ein Mitglied, Selbstreferenz, gleiche Sprache/Gruppe, `removed_in` ohne Ersatz. Aktive Köpfe bleiben zwingend aktiv. Aktive Übungslinks/Annotationen dürfen nicht auf zurückgestellte Ziele zeigen. Historische Reader lesen alte Token und Wörterbuchdaten ausdrücklich mit; aktive Leser behalten ihre Filter.

Resolver sperrt kuratierte Tombstone-IDs und exakt dieselbe lokale Lernidentität inklusive Formfunktion. Keine user.db-Schreibvorgänge. Historische Reviews und Aktivität bleiben erreichbar. Story-Add und Reaktivierung prüfen den aktuellen Inhalt vor Zustandsänderungen. Andere Bedeutungen bleiben unabhängig.

## Konkrete Pfade und Gegenprüfung

Bestehend: `verify_exchange` und CLI in `pipeline/scripts/import_editorial_patch.py`; `validate_learning` in `pipeline/src/sprachpipe/learning_groups.py`; `transition`/`validate_rows` in `pipeline/src/sprachpipe/content_contract.py`; `build_rows` in `pipeline/src/sprachpipe/pack.py`; `export_sqlite` in `pipeline/src/sprachpipe/export.py`; Spalten in `pipeline/src/sprachpipe/schema.py`. Historische Leser: `lib/data/content/drift_content_repository.dart` und `lib/data/learning/practice_item_resolver.dart`, beide `historicalSentence`.

Geplante Änderungen: voriger Importer, `pipeline/src/sprachpipe/curate.py`, Gruppen-/Contentvalidator, `lib/data/content/content_database.dart`, Contentrepository, Resolver, `lib/domain/story_learning.dart`, `lib/presentation/providers/story_learning_providers.dart`; neue Tests `pipeline/tests/test_targeted_curation.py`, `test/data/targeted_curation_test.dart`, gemeinsame synthetische Fixtures nach Bedarf. Bestehende Formvalidatoren, Export, Stage und Installer werden durch Tests geprüft; nur bei belegtem Bedarf geändert. Keine Produktionsinputs oder Assets editieren.

GitNexus vor Edit: Importer LOW (1 direkter Aufrufer), Python-Gruppen LOW (3), Python-Contentvertrag LOW (1); betroffene Prozesse Upsert/Authoring. Dart-Gruppen-/Single-Sentence-Validator HIGH (je 1 direkter Aufrufer, Packöffnung und Auswertungstools); Warnung vor Edit ausgesprochen. Historischer Reader UNKNOWN wegen Interface-Dispatch: direkte Referenzen in Resolver, Lernprovider und Single-Sentence-Test zusätzlich geprüft. UNKNOWN ist keine Entwarnung.

Produktionsbasis/Arbeitsbaum gesichert unter `build/schema4_targeted_curation/`; fremde Änderungen bleiben ausgeschlossen. Kein Produktionsimport, kein Staging, kein Gerät, keine echten Lerndaten. Der Brotsatz bleibt aktiv.

## Verifikation

Abschlussresultate und Einschränkungen stehen unten; der eigentliche Produktionsimport bleibt Folgearbeit.

## Umsetzung und Grenzen

`apply_targeted_patch(raw, patch)` liegt in der bestehenden `curate.py` und wird ausschließlich über den ergänzten `--targeted`-Zweig des bisherigen Importers aufgerufen. Der bestehende `export_offline` übernimmt Linter, `build_rows`, atomaren `export_sqlite` und vollständigen SQLite-Readback. Die Vollkorpusprüfung, Create-/Transition-Wege, Exportimplementierung und zwei partiellen Performanceindizes bleiben unverändert. Ein vorhandenes Ausgabeverzeichnis wird abgewiesen. Keine neue Transportspalte oder Schemakennung nötig: der historische Singleton nutzt die bestehenden Tombstonefelder, deren eng begrenzte Validierung in Python/Dart jetzt übereinstimmt.

Die Rückstellung ist bewusst enger als eine allgemeine Löschoperation: aktive Besitz-, Deck-, Form- oder lexikalische Mitgliedschaften sowie fremde aktive Satz-/Storyverwendungen werden nicht umgebaut. Auch wenn ein stillzulegender gebundener Wörterbucheintrag anderswo noch gebraucht wird, blockiert die finale Validierung den Export. Keine Ersatzkarte, Reservation, Positionsverschiebung oder Zusammenführung. Read-only bestätigt: Das beanstandete `so` hat drei eigene Kontexte, keine zusätzlichen aktiven fremden Links und keinen eigenen aktiven Wortbesitz; der Besitzer `so#so_sehr` bleibt unangetastet. Dies ist ausschließlich eine Prüfung der Voraussetzungen, keine Anwendung.

`DriftContentRepository.historicalSentence` schaltet die Token-/Sense-/Kartenglossen-/Wörterbuchfilter ausdrücklich auf Historie. Aktive Aufrufe von `_tokens` behalten ihre bisherigen Filter. `retiredLearningIdentities` liefert genaue Sprache/Form/Sense/Funktion. Der packgebundene `PracticeCatalog` hält diese einmalig gelesenen Ausschlüsse; der Resolver entfernt nur die aktive Projektion entsprechender lokaler IDs/Bindings. Historischer lokaler Zugriff bleibt erhalten. Die Queuefunktionen `buildDeckQueue` und `buildMixedQueue` filtern zusätzlich unbekannte IDs, auch wenn der Aufrufer eine bereits aufgelöste alte Liste übergibt. Keine persistierte Queue ist implementiert; erneute Projektion alter IDs und tatsächliche Queuefunktionen sind getestet. Ein laufender Pass ist weiterhin an seinen geöffneten, unveränderlichen Pack gebunden.

Story-Reaktivierung liest den Kandidaten vor einem Flag-Schreibzugriff erneut und vergleicht den Fingerprint. Story-Add hatte bereits dieselbe Inhaltsprüfung und die Retirement-Sperre. Ein synthetischer Storytoken derselben Oberfläche mit anderer Bedeutung/Formfunktion bleibt über den echten Resolver addierbar. Kein Schreiben oder Öffnen einer echten user.db. Die Test-Lernstände sind ausschließlich temporäre Dateien.

Zusätzliche Graphprüfung: Queuefunktionen LOW, direkte Aufrufer Sessionstart/Auswertung; `_tokens` LOW, direkte Leser `practiceItems`/`historicalSentence`; Contentrepository MEDIUM. `reactivate` UNKNOWN, direkte Referenz im Storyreader per Textsuche bestätigt. Die Grenzen statischer Interface-Auflösung werden durch Repository-/Provider-Tests ergänzt. Kein UNKNOWN als Entwarnung verwendet.

## Nachgewiesener Bestand

Alle 22 Tabellen des Produktionsassets entsprechen weiterhin zeilen-/spaltenweise `build_rows` der unveränderten Quelle (nur Release-Erstellungszeit ausgenommen). 402 Formmitgliedschaften über die tatsächlichen Repository-Stapelpfade abgeglichen. Alle 528 vorhandenen historischen Karten-Satzlinks samt Tokenanzahl und Text über `historicalSentence` gelesen.

**Bestehende Historienlücken:** 190 Satz-Provenienzen enthalten `historical_source_sentence_id`; davon fehlen bereits 137 ältere Satz-IDs im Produktionspack. Für diese 137 Referenzen liefert der historische Reader erwartungsgemäß `null`. Beispiele: `5e57912561d1295fa2a4d71e3d637f3b` (heutiger Satz `1e1cf5676e3ef1593fbf612602b61133`) und `99fdf7f20d705bd82f802574d51bd0c6` (heute `649c6a643cc42d02bb1aff38da60c350`). Das sind Altverluste des früheren Wegs, keine neu fehlenden Referenzen. Keine Rekonstruktion oder redaktionelle Neubewertung in diesem Auftrag. Die neuen synthetischen Ersatzsätze behalten dagegen sämtliche alten Satz-/Link-/Token-IDs, Texte und Alternativen im exportierten Pack.

Geschützte SHA-256 (vor/nach gleich):
- Quelle `pipeline/out/business_email_batch_6_perf_v1/pack.json`: `48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4`.
- Asset `assets/content/en/content.sqlite`: `4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`.
- Manifest: `7070f43a6fb04c377703488590a6054fcf28a7fdb79bf644bc9f5ba70027bcdd`.
- Originaler 30s-Packtest: `1e26c91844fcc7692f08c279b085dc4a66aeb11b4014ce841377ea2ce1358551`.
- Read-only Kurationsliste und Review-JSON zusätzlich gegen ihre gesicherten Hashes geprüft.

## CLI für einen späteren, separat beauftragten Import

`--help` wurde am vorhandenen Script ausgeführt (Exit 0). Das neue Argument heißt `--targeted TARGETED`. Die vorhandene `pipeline/data/curation/context_quality_v1.json` ist **keine** Eingabe dieses neuen Vertrags: Für den Folgeauftrag muss eine eigene Datei mit obigem Format, vollständigen Preconditions und vollständiger Annotation erstellt werden. `NEUER_TARGETED_PATCH.json` unten ist ein Platzhalter, kein bereits vorhandenes oder freigegebenes Artefakt. Der Output muss neu sein. Kein automatisches Staging.

macOS Terminal:
```sh
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --help
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_6_perf_v1/pack.json --targeted NEUER_TARGETED_PATCH.json --out pipeline/out/NEUES_RELEASE
```
Windows PowerShell:
```powershell
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/import_editorial_patch.py --help
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_6_perf_v1/pack.json --targeted NEUER_TARGETED_PATCH.json --out pipeline/out/NEUES_RELEASE
```

Die in Tests ausgeführte CLI verwendet ausschließlich temporäre synthetische Quell-/Patch-/Outputdateien. Beide SQL-Fixtures sind deterministische Dumps genau dieses Python-Import-/Exportwegs; der Python-Test gleicht sie vollständig ab, der Dart-Test öffnet sie über echte Repository-/Installerpfade. Die festen Erstellungszeitstempel dienen ausschließlich dem Fixturevergleich.

## Eigene Dateiliste

- `docs/schema4-targeted-curation.md`, `docs/content-schema.md`, `docs/learning-groups-v1.md`.
- `pipeline/scripts/import_editorial_patch.py`.
- `pipeline/src/sprachpipe/curate.py`, `pipeline/src/sprachpipe/content_contract.py`, `pipeline/src/sprachpipe/learning_groups.py`.
- `pipeline/tests/targeted_fixture.py`, `pipeline/tests/test_targeted_curation.py`.
- `lib/data/content/content_database.dart`, `lib/data/content/drift_content_repository.dart`.
- `lib/data/learning/practice_item_resolver.dart`.
- `lib/domain/story_learning.dart`, `lib/domain/srs_state.dart`.
- `lib/presentation/providers/story_learning_providers.dart`.
- `test/data/targeted_curation_test.dart`.
- `test/fixtures/targeted_curation_before.sql`, `test/fixtures/targeted_curation_after.sql`.

`NEXTSTEPS.md` wird auf höchstens 25 Faktenzeilen aktualisiert, wegen seiner bereits vorhandenen, überlappenden Änderungen nicht mitcommittet. Alle übrigen fremden/untracked Altdateien bleiben unberührt. Arbeitsbranch `codex/schema4-targeted-curation`, Ausgangscommit `d67e4e0`; kein Push.

## Abschlussprüfungen (jeweils tatsächlicher Output)

| Prüfung | Ergebnis / Exitcode |
|---|---|
| Neue Python-Tests plus bestehende Editorial-/Gruppentests | `61 passed in 2.27s`, Exit 0 |
| Gezielte Dart-Reader-/Queue-/Reviewtests | 13 Tests PASS; finaler gezielter Gesamtfall 9 Tests PASS, Exit 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | `482 passed, 19 subtests passed in 41.05s`, Exit 0 |
| `flutter test --no-pub` | `00:25 +300: All tests passed!`, Exit 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:08 +1: All tests passed!`, Prozess 11,70s, Exit 0; originales 30s-Limit unverändert |
| `flutter analyze --no-pub` | `No issues found! (ran in 3.9s)`, Exit 0 |
| `dart run tool/stage_content_pack.dart --verify` | Version business_email_batch_6_v1, Schema 4, 26095616 Bytes, 22 Tabellen stimmen, Exit 0 |

Die vollständigen Abschlussgates liefen nach den gezielten Tests jeweils einmal. Vorherige Testentwicklungsbefunde betrafen Set/List-Typen, einen fehlenden Extension-Import, den 14-Tage-Intervallwert für den ersten sauberen Review, die bestehende Exception-Semantik bei Story-Add sowie falsch benannte Test-/Runnerpfade; korrigiert und durch gezeigte erfolgreiche Läufe ersetzt. Keine Timeout-Erhöhung und keine Endlosschleife.

GitNexus vor Commit frisch erzwungen indiziert: 83.994 Knoten, 258.059 Kanten, 392 Flows. `detect_changes(scope=all)` meldete zunächst 27 geänderte Symbole und 17 betroffene Prozesse, Gesamtrisiko **critical**, ohne partial-/truncated-Flag. Warnung ausgesprochen, zentrale Validator-/Import-/Autorenpfade gegen konkrete Diffs und vollständige Tests gegengeprüft. Bekannte Abdeckungsgrenze: Dart-Methodenkörper werden teilweise nur bis zur Signatur indiziert (z.B. `validateLearningGroups` 162–162, `buildDeckQueue` 261–269); deshalb fehlen deren Körperänderungen teilweise in `changed_symbols`. Direkte Referenzen, vorherige Symbol-Impactchecks und echte Repository-/Queue-/Installer-Tests ergänzen die Graphprüfung. Kein Nulltreffer als Beleg fehlender Auswirkungen gewertet.

Lokale Rohlogs und Exitcodes: `build/schema4_targeted_curation/` (nicht versionierter Laufnachweis). Keine globale Formatierung. Bestehende CRLF-Zeilen bleiben erhalten: normales `git diff --check` meldete dafür CR als trailing whitespace; die CRLF-bewusste Prüfung verwendet `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check -- <eigene Dateiliste>`, ohne persistente Git-Konfigurationsänderung.

Nach Aufnahme der neuen Dateien in den Index: `detect_changes(scope=all)` erfasst **46 Symbole, 17 Prozesse und 19 Dateien** einschließlich der nicht zum Commit gehörenden NEXTSTEPS-Änderung; Risiko weiterhin **critical**, weder `partial` noch `truncated`, alle 46 Symbole ausgegeben. Kein zusätzlicher ungeprüfter Produktionspfad gefunden. Die 18 vorgemerkten Dateien entsprechen exakt der eigenen Liste. CRLF-bewusstes `git diff --cached --check -- <eigene Dateiliste>`: keine Ausgabe, **Exit 0**. Sämtliche geschützten Hashes nach allen Abschlussprüfungen erneut unverändert bestätigt.

## Additive Storykontext-Prüfung (16.10.2026)

Derselbe `--targeted`-Einstieg akzeptiert zusätzlich `story_contexts`. Exakte Felder: `op`, `story_id`, `sentence_id`, `expect_sentence` (vollständige Quellzeile), `expect_tokens` (vollständige geordnete Quellannotation), `reason`, `contexts`. Pro Satz höchstens eine Operation; globale Quellenhash-/Versionsprüfung bleibt unverändert. Aktive Story-/Satzzugehörigkeit ist Pflicht.

Jeder Kontexteintrag nennt `token_index`, `surface`, `sense`, `reason` und entweder `sentence_refs` (ein bis drei zusammenhängende Originalsätze einschließlich des Quellsatzes) oder `replacement` mit `text`, `translation_de`, `tokens`, `target_index`, `reason`. Vorzugsreihenfolge: geeigneter Originalsatz, nötiger kurzer Ausschnitt, begründeter Ersatz. Alle Kontexte bleiben auf 20 Wörter und einen Nebensatz begrenzt. Vollständige Tokenabdeckung, bestehende aktive Lemma-/Sense-/Wörterbuchbindung, exakte Zielidentität und Retirement-Sperre werden geprüft. Keine neue globale Karte und keine implizite Wortschatzergänzung. Mehrfachvorkommen sind ausschließlich hier zulässig, weil die explizite Tokenposition die einzige Ziellücke bestimmt; andere Linterregeln bleiben erhalten.

Der Importer erzeugt `qa_report.story_practice_contexts` selbst: Formatversion 1, Reviewer, Quellhash, konkrete Bindungen mit Originalposition, begründete Quellauswahl und vollständig aufgelöster Kontext-Snapshot. Kontext-ID wird aus Sprache/Text deterministisch gebildet. Bestehende Satztexte, Übersetzungen, Tokens, Karten, Besitz-, Form- und Gruppenidentitäten bleiben unangetastet. Alte QA-Daten bleiben neben dem neuen Namensraum erhalten. Die App revalidiert Quelle, Zielidentität, vollständige Annotation und UTF-16-Spannen; ursprüngliche Story-/Satz-/Tokenherkunft bleibt von der Übungsspanne getrennt.

`export_offline` ergänzt `story_authoring_gaps` im Abschlussbericht. Fehlende Bindungen mit Story-/Satz-/Token-/Sense-/Offsetdaten werden zur Redaktion ausgewiesen; Eigennamen sind getrennt gekennzeichnet. Dieser Bericht erteilt keine Freigaben und ersetzt weder Resolverprüfung noch semantische Redaktion. Ein technischer Exportstatus `ok` bedeutet nicht, dass alle gemeldeten Authoring-Lücken erledigt sind.

Konkrete Lieferung, Bestandserhebung, Einzelfallentscheidungen und Abnahme: [Story-Kontextabschluss](story-practice-context-completion.md).

## Story-Einzelsatzvertrag v2 (16.10.2026)

Für neue Lieferungen gilt `story_single_sentence_contexts` am selben `--targeted`-Einstieg. Die alten `story_contexts`-Lieferungen bleiben für historische Reproduktion lesbar; ihre Ausschnittregel wird für neue Redaktion durch v2 ersetzt. Operationsfelder und exakte Quellen-/Token-Preconditions bleiben gleich. `sentence_refs` muss genau den eigenen Originalsatz enthalten. spaCy-Satzgrenzen bestimmen genau einen Satz; die bestehende Tokenisierung zählt Wörter ohne Mehrwortzusammenfassung und ohne Satzzeichen. Ein/zwei Originalwörter erfordern einen geprüften Ersatz, die Übung enthält 3–20 Wörter. Ab drei Originalwörtern gilt das unveränderte Original mit seiner Übersetzung als Standard. Pronomen, Then, unbekannte Personen oder fehlende Handlung allein rechtfertigen keinen Ersatz.

Ersatz ergänzt `justification: {kind, evidence}`: `short_original` nur für ein/zwei Wörter, sonst `target_meaning_unusable` oder `not_sentence_exercise` mit konkretem redaktionellen Befund. Diese semantische Entscheidung wird vor dem Import redigiert; keine Laufzeit-KI und keine automatisierte Behauptung semantischer Eignung. Vollständige Annotation, identische Zielform/-bedeutung/-funktion, genau eine Ziellücke und sämtliche bisherigen Sperren bleiben Pflicht. Die Abkürzung `Dr.` bildet keine künstliche Satzgrenze.

Der Import erzeugt QA-Formatversion 2 mit geprüfter `sentence_policy` (Original-/Übungswortzahl, Satzanzahl 1, Ersatzflag). Nur bei tatsächlicher Kontextänderung ergänzt er `correction` aus dem exakten alten Snapshot, alter Release-Revision und neuer Korrekturversion. Die App berechnet die bisherigen Fingerprints mit den unveränderten Domain-Hashfunktionen. Die optionale Repository-Korrektur ergänzt einen unveränderlichen lokalen Snapshot und eine Herkunftszeile, wechselt ausschließlich den aktiven Kontextverweis und erhält sämtliche alten Snapshots/Reviews/Zustandsfelder. Keine Schemaänderung. Herkunft, Fingerprint, Kontext-ID, Text, Übersetzung, Tokens und Lücke müssen übereinstimmen. Unbeteiligte/individuell abweichende Kontexte bleiben erhalten. Details und Nachweise: [Story-Einzelsätze](story-single-sentence-v1.md).
