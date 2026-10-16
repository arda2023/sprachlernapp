# Drei Kontextkorrekturen intern angewendet

Am 16.10.2026 über den bestehenden `--targeted`-Importer angewendet, vollständig geprüft und als **context_quality_applied_v1**, Schema 4, intern gestagt. Keine Pending-Schritte der drei beauftragten Änderungen. Keine öffentliche Sprachfreigabe, Cloud-/Modellaufrufe, Geräteinstallation oder echte user.db. Der alte Blockadeoutput `pipeline/out/context_quality_v1/` und sämtliche Ausgangslieferungen bleiben erhalten.

## Herkunft und konkrete Änderungen

Technische Voraussetzung: `docs/schema4-targeted-curation.md`, Implementierungscommit `9e578ca`. Entscheidungsquelle `pipeline/data/curation/context_quality_v1.json` und Einzelreview `docs/evidence/context-quality-v1/review.json` unverändert. Die ausführbare Kopie `pipeline/data/curation/context_quality_apply_v1.json` enthält genau drei Operationen, volle Quellzeilen als Preconditions und Herkunft mit Dateipfaden/SHA-256 in den vertragskonformen reason-Feldern. Quellpack: `pipeline/out/business_email_batch_6_perf_v1/pack.json`, Release business_email_batch_6_v1. Alle erfassten Basis-Hashes entsprechen dem vorher dokumentierten Stand; keine Neubindung.

1. Karte `1bbe26267773ad288ddd7bf7063c4437` (so#auf_diese_weise) zurückgestellt. Brotsatz `1e047de6e0a0f09136a14753a634cb52`, Link `1d4823e6d50251a33f70c10582ae2fce`, beide alten Demonstrationssätze und sämtliche Tokens bleiben historisch lesbar. Tombstones betreffen die Karte, ihren aktiven Link, drei ausschließlich eigene Sätze, 31 Tokens und eine gebundene Wörterbuchzeile. Keine Wiederaktivierung; so#so_sehr, Besitz, Gruppenidentitäten und persönliche Zustände unverändert.
2. Karte `ca8c7f9b1f100ebc671639b0d71fdf64`: „The kitchen is clean. Let's keep it that way.“ / „Die Küche ist sauber. Sorgen wir dafür, dass sie so bleibt.“ Neue Satz-ID `ffc8ac9d8c30d444dc471a2c1425bbf4`, Link `4d42271ef9265b522be3945a192f5316`, Lücke **[22,44)** erneut mit `sentence_id`/`gap_offsets` bestätigt. Zielform und accepted bleiben let's keep it that way, keine Alternativen. Genau ein neuer aktiver Link; alter Link erhält removed_in/replaced_by. Alter Satz `dd8ab9cfb2023421fe9e62249c9e509a` samt Tokens unverändert im Pack.
3. Karte `7e36dbaded1247f91a76a6577dfe5345`: nur translation_de von „quasi / sozusagen“ auf „so (umgangssprachlich als Zitateinleitung)“. Satz-ID, EN-/DE-Satz, Wörterbuch- und Senseglossen unverändert. Der Reader verwendet bei gebundenen Tokens die Kartenglosse und zeigt folgerichtig auch in einem alten Review die korrigierte like-Glosse; der gespeicherte Review wird nicht umgeschrieben.

Die sechs dokumentierten Grenzfälle und übrigen Altglossen wurden nicht verändert oder neu freigegeben.

## Offline-Annotation und tatsächlicher Renderer

Bestehender spaCy-Tokenizer mit ausdrücklich zusammengefasster lexikalischer Zielspanne; sieben Tokens. Alle Offsets sind Codepoints (hier ausschließlich ASCII, daher zugleich UTF-16-kompatibel). Keine erfundenen Lexikoneinträge:

| Token | Spanne | Bestehende Sense | Formglosse |
|---|---|---|---|
| The | [0,3) | the/DET\|the#die | die |
| kitchen | [4,11) | kitchen/NOUN\|kitchen#kueche | Küche |
| is | [12,14) | be/AUX\|be#ist | ist |
| clean | [15,20) | clean/ADJ\|clean#sauber | sauber |
| . | [20,21) | keine | keine |
| Let's keep it that way | [22,44) | unveränderte Zielsense/Karte | belassen wir es dabei |
| . | [44,45) | keine | keine |

Die Küche ist ein Raum, clean bezeichnet ihren sauberen Zustand, is ist die Kopula. Keine Verwechslung mit clean#putzen, clean#unbeschrieben oder is als Continuous-Hilfsverb. Editorial-review-Status nur für die vollständig annotierte neue Aufgabe, keine automatische Neubewertung anderer Zeilen. Gesamtlinter: **4297 Links, 0 Fehler**; neue Aufgabe **0 Fehler, 0 Warnungen**.

`test/data/context_quality_applied_test.dart` liest die Aufgabe aus dem tatsächlichen Export und rendert `PracticeSentence` bei Breiten 320 und 800, jeweils ungelöst und gelöst: ein TextField, unveränderte vollständige Lösung, korrekter erster Satz/Punkt, alle vier Begleitwort-Taps mit richtiger Übersetzung/Offset, keine Flutter-Exception. Kein UI-Code geändert.

## Bestand, Historie und Zustände

Read-only-Audit `docs/evidence/context-quality-applied-v1/audit.py` vergleicht den vollständigen fachlichen Inhalt aller 22 SQLite-Tabellen gegen `build_rows` (exportgeneriertes created_at ausgenommen). Zusätzlich zeilenweise Vorher-/Nachher-Differenz mit enger erlaubter Operationsliste: keine gelöschten IDs, keine unbeteiligten Änderungen. Detail-IDs und Felder in `audit-result.json` neben dem Script. Alle Karten-, Sense-, Form-, Gruppen-, Besitz- und Lexikalzielidentitäten erhalten. Release-Metadaten wechseln wie vertraglich vorgesehen.

| Kennzahl | Vorher | Nachher |
|---|---:|---:|
| Karten insgesamt | 3768 | 3768 |
| Aktive Karten / aktive Übungslinks | 3768 | 3767 |
| App-Projektion Gemischt: Übungen | 3654 | 3654 |
| App-Projektion Gemischt: lexikalische Ziele | 3383 | 3383 |
| Formmitgliedschaften | 402 | 402 |
| Je Verbenansicht | 134 | 134 |
| Historische Links | 528 | 530 |
| Sätze insgesamt | 4302 | 4303 |
| Tokens insgesamt | 47082 | 47089 |
| Synthetische persönliche Altstände | 3 | 3 |
| Synthetische gespeicherte Reviews | 3 | 3 |

Die App-Zahlen wurden vor Exportstaging, am neuen Output und am gestagten Asset tatsächlich berechnet. Alle Stapelprojektionen einschließlich first30 identisch; `projections.json` enthält die einzelnen Zahlen. Kein blindes Abziehen: so#auf_diese_weise hatte keinen aktiven Neunutzer-Stapelbesitz.

Der echte Reader liest **alle 530 historischen Links** samt Text/Tokenanzahl. Die **137 bereits vorher fehlenden Provenienz-Satz-IDs** bleiben exakt dieselben; keine neue Historienlücke und keine Rekonstruktion behauptet. Historische so-Sätze bleiben trotz Tombstones erreichbar. Vollständige Formmitgliedschaften mit echten Repository-Stapelpfaden geprüft.

Isolierter temporärer synthetischer Nutzerbestand: drei fällige Altstände und drei gespeicherte Reviews aus dem alten Pack, anschließend neuer Pack/Resolver. so fehlt in Gemischt, Lernen, Revue und erneuter Projektion alter IDs; die anderen fälligen Karten bleiben verfügbar. Alte Reviews lösen ihre ursprünglichen Sätze auf. user_cards und review_log sind zeilenweise und nach Schließen die gesamte Testdatei bytegleich. Keine echte Nutzerdatei geöffnet. Bestehende technische Tests decken zusätzlich lokale Aliasidentitäten und Story-Reaktivierung ab.

## Export, Sicherung und Hashes

Atomarer Export durch unveränderten `export_sqlite`: temporäre Datei, Transaktion, beide partiellen Indizes, Close, Rename. Indizes `idx_sentence_tokens_active_sentence_idx` und `idx_dictionary_forms_active_lookup` nachgewiesen. Exklusiver Output `pipeline/out/context_quality_applied_v1/`, kein bestehendes Exportverzeichnis überschrieben. Exportbericht `status=ok` bezeichnet den bestandenen Linter-/22-Tabellen-Exportcheck; Staging erst nach zusätzlichem Inhaltsaudit und bestandenem tatsächlichen Pack-/Renderertest.

Unmittelbar vor Stage alle sechs geschützten Basis-Hashes erneut geprüft und Asset/Manifest nach `build/context_quality_applied_v1/prestage-backup/` kopiert, Kopie hashverifiziert. Neuer Assetumfang **26107904 Bytes**. Asset und Manifest bleiben entsprechend bestehender Repositoryregel ignoriertes internes Material; Patch, Tests und Nachweise werden versioniert.

- Alter Asset-SHA: `4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`.
- Neuer Asset-SHA: `0352850bd9352dc876b0ae560da81d1f35f701c91180cd0f08015e042ddcf191`.
- Neuer Manifest-SHA: `d99fca40c08e399f6b0b2917f5411dc2a461785e0ae146c976b5a3ec72fd1815`.
- Quellpack unverändert: `48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4`.
- Neuer pack.json: `b48c224ef0b2538d2b97f77130742b1a0f23df6215e8feb12bec785d8f98560c`.
- Alle weiteren Vorher-/Nachher-Hashes einschließlich Originalentscheidungen und unverändertem Standardtest: `docs/evidence/context-quality-applied-v1/hashes.json`.

## Tatsächlich ausgeführte Befehle

Repository-Root, macOS Terminal. Python hier `pipeline/.venv-macos/bin/python`; Windows PowerShell verwendet `.\pipeline\.venv\Scripts\python.exe` vor denselben Argumenten (Windows nicht ausgeführt). Flutter-/Dart-/Git-Befehle auf beiden Systemen gleich. Rohlogs und Prozesszeiten lokal unter `build/context_quality_applied_v1/`, argv/Exitcodes zusätzlich in `docs/evidence/context-quality-applied-v1/checks.json`.

| Befehl | Tatsächlicher Output | Exit |
|---|---|---:|
| `pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/business_email_batch_6_perf_v1/pack.json --targeted pipeline/data/curation/context_quality_apply_v1.json --out pipeline/out/context_quality_applied_v1` | status ok; 22 sqlite_counts; ai_calls 0; SHA wie oben | 0 |
| `pipeline/.venv-macos/bin/python docs/evidence/context-quality-applied-v1/audit.py` | content_export_audit_pass; pending 0; 22 Tabellen; 528→530 historische Links | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | 482 passed, 19 subtests passed in 31.74s | 0 |
| `flutter test --no-pub test/data/context_quality_applied_test.dart` | 00:10 +2: All tests passed! | 0 |
| `dart run tool/report_learning_groups.dart pipeline/out/context_quality_applied_v1/content.sqlite` | Gemischt 3654 / 3383; alle Projektionen identisch zur Basis | 0 |
| `dart run tool/stage_content_pack.dart --from pipeline/out/context_quality_applied_v1` | staged; context_quality_applied_v1; schema 4; 22 table counts match | 0 |
| `flutter test --no-pub` | 00:32 +302: All tests passed!; 530 historical readers OK | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | 00:09 +1: All tests passed!; Prozess 13,92s | 0 |
| `flutter analyze --no-pub` | No issues found! (ran in 3.1s) | 0 |
| `dart run tool/stage_content_pack.dart --verify` | verified; SHA wie oben; 22 table counts match | 0 |
| `dart run tool/report_learning_groups.dart assets/content/en/content.sqlite` | vor und nach Stage ausgeführt; alle Stapel/first30 identisch | 0 |
| `node .gitnexus/run.cjs analyze --index-only --pdg --force` | Repository indexed successfully (35.4s); 84118 Knoten, 258352 Kanten, 392 Flows | 0 |

Standard-Packtestdatei und **30s-Limit unverändert**. Bestehender targeted_curation-Test ausschließlich Erwartung/Bezeichnung 528→530 angepasst; alle fachlichen Assertions erhalten. Die Analyse-Stilkorrektur ergänzt nur Klammern um eine if-Anweisung der neuen Testdatei.

Entwicklungsbefunde offen dokumentiert: erster Flutterstart benötigte SDK-Cachezugriff; neuer Test zunächst Compilefehler durch await auf void; dann unzulässiger Gemischt-Aufruf über buildDeckQueue; danach falsche Leermengenannahme trotz zwei anderer fälliger Zustände; schließlich alte like-Glosse im historischen Reader erwartet. Jeder Befund wurde anhand konkreter API-/Inhaltssemantik behoben, ohne Validator-/Appänderung. Der Mixed-Test verlangt jetzt exakt die beiden anderen fälligen Karten. Queuegröße 50 entspricht einer Sitzung statt eines unnötigen 5000-Karten-Auswahltests. Ein Analysehinweis zu fehlenden if-Klammern behoben. Keine Timeout-Erhöhung; finale vollständige Tests und Analyse bestanden.

## Commitgrenze und manuelle Geräteprüfung

Branch `codex/context-quality-applied-v1`, eigener Commit ohne Push. Eigene Dateien: ausführbarer Patch, dieser Bericht, `docs/evidence/context-quality-applied-v1/`, neuer `test/data/context_quality_applied_test.dart`, präzise Zählerkorrektur in `test/data/targeted_curation_test.dart`. NEXTSTEPS lokal auf 24 Faktenzeilen aktualisiert, wegen überlappender Altänderungen nicht mitcommittet. Fremde Lieferungen/Änderungen erhalten.

Vor Edit der bestehenden Testfunktion GitNexus impact: UNKNOWN, keine aufgelösten Aufrufer/Prozesse; ergänzende Textsuche und direkte Lektüre bestätigen den Flutter-Testeinstieg. Neue Testfunktion zunächst nicht indiziert (UNKNOWN), direkt geprüft und danach neu indiziert. Keine Produktionsfunktion editiert. Index meldet begrenzte globale Flow-Erfassung; fehlende Flows sind keine Entwarnung.

Noch manuell, ausschließlich in einem getrennten Testprofil nach separat autorisierter Installation: fälliges so aus Gemischt/Stapel/Revue ausschließen, alten Review samt Brotsatz öffnen; neue Küchenaufgabe mit einer Lücke lösen und vier Wortübersetzungen antippen; like-Glosse bei unverändertem Feier-Satz prüfen; drei Verbenansichten und Zähler nach Neustart vergleichen. **Kein Geräte-PASS**, insbesondere keine Installation auf „iPhone von Claus“, keine öffentliche Sprachfreigabe.

## Vollständige Tabellenzahlen

| Tabelle | Vorher | Nachher | Geänderte Altzeilen | Neue Zeilen |
|---|---:|---:|---:|---:|
| languages | 1 | 1 | 0 | 0 |
| lemmas | 5007 | 5007 | 0 | 0 |
| senses | 6759 | 6759 | 0 | 0 |
| cards | 3768 | 3768 | 2 | 0 |
| dictionary_forms | 8089 | 8089 | 1 | 0 |
| decks | 14 | 14 | 0 | 0 |
| deck_cards | 3661 | 3661 | 0 | 0 |
| deck_words | 3557 | 3557 | 0 | 0 |
| word_aliases | 37 | 37 | 0 | 0 |
| sentences | 4302 | 4303 | 3 | 1 |
| sentence_tokens | 47082 | 47089 | 31 | 7 |
| card_sentences | 4296 | 4297 | 2 | 1 |
| stories | 1 | 1 | 0 | 0 |
| story_sentences | 6 | 6 | 0 | 0 |
| exercises | 0 | 0 | 0 | 0 |
| grammar_rules | 0 | 0 | 0 | 0 |
| audio_assets | 0 | 0 | 0 | 0 |
| content_releases | 1 | 1 | Releasewechsel | 0 |
| lexical_targets | 134 | 134 | 0 | 0 |
| card_lexical_targets | 406 | 406 | 0 | 0 |
| form_targets | 402 | 402 | 0 | 0 |
| deck_practice_targets | 402 | 402 | 0 | 0 |

Abschließendes Commit-Gate: `detect_changes(scope=all, repo=sprachlernapp)` meldet 27 vollständig ausgegebene Symbole, 11 Dateien einschließlich ungestagtem NEXTSTEPS, Risiko **low**, keine betroffenen Prozesse, weder partial noch truncated. Vollständiger Output in `graph-check.json`. Bekannte Graphgrenze: die kleine Erwartungsänderung im bestehenden Dart-Testkörper wird nicht als Symboländerung aufgeführt; konkreter Diff besteht aus genau drei Ersetzungen 528→530 und wurde direkt geprüft. Keine Entwarnung allein aus Nulltreffern. `git diff --check -- <eigene Dateiliste>` und `git diff --cached --check`: keine Ausgabe, jeweils Exit 0. Die neue Bericht-/JSON-Dokumentation führt keine weiteren Produktionspfade ein.
