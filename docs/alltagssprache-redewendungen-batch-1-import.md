# Alltagssprache & Redewendungen – Batch 1: interner Import, Fortsetzung blockiert

Stand: 11.10.2026. **89 aktuelle Ziele offline importiert und intern gestagt; technische Packprüfung bestanden. Batch-2-ZIP wegen eines konkreten Alternativ-/Auswahlkonflikts nicht erzeugt.** Kein vollständiger Abschluss des angeforderten Inkrements und keine öffentliche Inhaltsfreigabe.

## Verträge, Basis und Arbeitsbaum

Gelesen und abgeglichen: AGENTS.md, CLAUDE.md, NEXTSTEPS.md, Content-Roadmap, gemeinsamer Authoring-Bericht, normaler Schema-4-Kompatibilitätsbericht, Verben-Batch-4-Bericht, Content-Schema, Lerngruppenregeln, V2-Importschema, Auswahl/Registry/Gruppen, Importer, normaler ZIP-Exporter und Staging-Werkzeug. Bestehender normaler Kontextformat-2-/V2-Weg; Content-Schema bleibt 4. Keine erneute Kompatibilitätsimplementierung.

Konkrete Schnittstellen:

- `pipeline/scripts/import_editorial_patch.py`: `create_content` mit `--create` und ausdrücklich `--registry`; `export_offline`, `build_rows`, `finalize_curation.check_sqlite` prüfen und exportieren.
- `tool/stage_content_pack.dart`: `--from` nach nachgewiesener Asset-Sicherung, danach `--verify`.
- `pipeline/scripts/export_authoring_context.py`: normaler `--prepare-continuation VERSION` nutzt `authoring_context.prepare_continuation` und `validate_context`; nach erfolgreicher Vorbereitung wären `--selection … --batch 2 --out …` und `--verify-zip …` vorgesehen. Die Vorbereitung scheiterte vor dem Schreiben.
- `tool/report_learning_groups.dart`: produktive `LearningGroups.project` und `lexicalCountingKeys`; Zähler nicht aus Karten-/Besitzzeilen abgeleitet.
- `test/data/real_pack_test.dart`: bestehender echter Installer-/Repository-Lesetest; nur die neue Version mit zwölf Stapeln und 89 Zielen in dessen bestehende konkrete Schema-4-Prüfung aufgenommen. Alle Verben-/Altversionsprüfungen erhalten; keine Appänderung.

Vorheraufnahme: 2664 Dateien in `build/alltagssprache_batch_1_checks/baseline.json`, vollständiger Gitstatus und leerer Index. Bestehende umfangreiche V3-/Schema-4-/Dokumentänderungen erhalten. Eigene Dateien unten; kein Reset, kein Sammelstaging, kein Push.

## Lieferung und redaktioneller Abgleich

Original: `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_1_lieferung.zip`. CRCs aller 23 Archiveinträge und vollständiger Liefermanifest-Dateiabgleich bestanden. Die beigefügten Reference-Dateien entsprechen bytegenau der geprüften Batch-1-Authoring-ZIP. Einzig der beigefügte Dateiname `reference/editorial_content_v2.schema.json` entspricht dem darin enthaltenen Originalpfad `pipeline/data/curation/editorial_content_v2.schema.json`; Vergleich erfolgte gegen genau diesen Inhalt. Der Reference-Manifest beschreibt den vollständigen Authoring-Kontext, während die Lieferung nur dessen ausdrücklich beigefügte Teilmenge enthält.

Original-Basisbindung und Import-JSON-Hash entsprechen den erwarteten Werten. Registry-Dateibytes und kanonischer Registry-Digest getrennt geprüft. Alle 89 Karten entsprechen exakt der aktuellen Auswahl: Form, Sense, Karten-ID-Ableitung, Glosse, Definition, learning-Metadaten und Originalposition. memberships/deck_words entsprechen den Positionen 1–89 aus `combined_display_mapping.json`; kein Display-Patch nötig. 353 spätere Ziele wurden nicht importiert.

Alle 89 englischen Sätze und deutschen Übersetzungen gegen Bedeutungsabsichten gegengelesen. Vollständiger mitgelieferter Tokenbericht mit allen 870 Positionen (719 Worttokens) gegen Importdaten abgeglichen, einschließlich Begleitwörtern. Bestehender Importer prüft echte Tokenisierung, Reviews und Wörterbuchreferenzen. Jede Gesprächsformel/Redewendung bleibt eine zusammenhängende Lücke und ein lexical_span. Apostrophe, Bindestrich in heads-up, Komma in so far, so good und `correct me if I'm wrong` bleiben erhalten; accepted bleibt exakt `[card.form]`.

Acht tatsächlich eingesetzte Alternativen, ausschließlich satzbezogen: nonetheless, a breeze, in my opinion, on second thought, occasionally, verbatim, cry over spilled milk, honestly. Vollständige Ersetzungstexte wurden mit den Begleitberichten und Importreviews abgeglichen und auf passenden Satzanschluss und Aussage geprüft. Keine globale Synonym-/Aliasfreigabe daraus abgeleitet. Die Alternative in my opinion verursacht allerdings den unten belegten Konflikt mit einem späteren Auswahlziel.

## Minimale gesonderte Importkopie

Original-Lieferung blieb bytegleich. Arbeitskopie: `build/alltagssprache_batch_1_checks/import_copy/alltagssprache_redewendungen_batch_1/`.

Drei echte Begleitwort-Zuordnungsfehler korrigiert, ohne Zielbindung oder Satzbedeutung zu ändern:

| Satz / Token | Vorher | Nachher und Begründung |
|---|---|---|
| alltagssprache-v1-0045-s1 / 6 | hear/VERB\|hear#hoeren | hear/VERB\|hear#erfahren: hear about bezeichnet das Erfahren von Informationen, der vorhandene Sense ausschließlich Geräuschwahrnehmung. |
| alltagssprache-v1-0080-s1 / 6 | hear/VERB\|hear#hoeren | Derselbe neue reine Wörterbuchsense; keine Lernkarte oder Besitzerreservierung. |
| alltagssprache-v1-0087-s1 / 4 | work/VERB\|work#funktionieren | Bestehender work/VERB\|work#gelingen passt zum Plan; funktionieren ist in der bestehenden Definition auf Geräte/Anlagen beschränkt. |

Ein neuer präziser Wörterbuchsense und zwei Wörterbuchformen ergänzt; alte Sinne/Glossen nicht verändert. Auch work/VERB\|work#funktionieren bleibt bei der Waschmaschine korrekt erhalten. close/VERB\|close#betrieb-einstellen im Geschäftssatz bleibt getrennt von close/VERB\|close#schliessen bei closing the window.

Zugehörige Tokensha256- und Linkhashbindungen mit der bestehenden `import_editorial_patch.digest`-Funktion erneuert, vollständigen token_review synchronisiert und Arbeitskopie-Manifest neu gehasht. `local_corrections.json` enthält die drei Einzeländerungen. Unverändert: alle 89 Zielkarten, learning, Zieldefinitionen, Texte/Übersetzungen, accepted/Alternativen, Lücken und Mitgliedschaften. Die alten authoring_evidence-/validation_report-Dateien in der Kopie bleiben ausdrücklich historische Chatbelege; maßgeblich sind der lokale Audit und finale Import-/Linterbericht, nicht deren frühere Zahlen.

## Bestands-/Exportprüfung und internes Staging

Alle alten JSON-Inhaltslisten bleiben identische Präfixe; außerhalb der erlaubten Release-/Registry-Metadaten bleiben alte Objekte unverändert. Jede exportierte alte Zeile mit allen IDs/Nutzwerten bleibt in allen 21 Nicht-Release-Tabellen erhalten. Alle 22 vollständigen neuen SQLite-Tabellen wurden mit `build_rows` verglichen; `content_releases.created_at` ist wie bisher exportgeneriert. Integritycheck ok, keine Foreign-Key-Verstöße. Eindeutige Schlüssel/Referenzen, Besitzer/Groups und genau ein aktiver fester Satz pro neuer Karte durch bestehende Builder/Importer geprüft.

Vier Formtabellen byteinhaltlich auf JSON-/Zeilenebene unverändert: 134 lexikalische Anker, 406 Kartenzuordnungen, 402 Formziele und Mitgliedschaften, je 134 Übungen in den drei Ansichten; 71 vorhandene feste Satzpaare wiederverwendet. Keine SRS-, Antwort- oder App-Einstiegsänderung.

Ergebnis: zwölf Stapel, 2656 Karten, 2542 projizierte Übungen / 2271 lexikalische Wörter. 89 neue Satzpaare und 870 Tokens; 118 neue Wörterbuchsenses und 129 neue Dictionary-Formzeilen einschließlich der drei Zuordnungskorrekturen. 2445 Besitzzeilen sind ausdrücklich nicht die Wortzahl.

Linter: **0 Fehler, 463 Warnhinweise insgesamt; genau ein neuer Hinweis**, beim Satz von in other words: reopen, Zipf 3,42 unter 3,5. Die 462 vorhandenen Hinweise bleiben getrennte Altbefunde, keine Warnung wegretuschiert.

Vor Staging nachweislich gesichert und bytegleich geprüft: `build/alltagssprache_batch_1_checks/backup/content.sqlite` und `content.manifest.json`. Staging und anschließende Asset-Verifikation erfolgreich; interner Test-Pack, keine öffentliche Freigabe. Echte user.db/Lernstände nicht geöffnet, kopiert oder verändert; echter Pack-Lesetest ausschließlich über temporäre Testdatenbank. Kein Gerätetest ausgeführt.

## Batch-2-Blocker – keine Vertragsumgehung

Der normale Fortsetzungsexporter lehnt die unveränderte Auswahl ab:

```text
ValueError: authoring: already offered word
Exit 1
```

Exakter Konflikt: **alltagssprache-v1-0377**, Originalposition 377, Batch 5, `in my opinion`: „Kennzeichnung einer folgenden Aussage als persönliche Einschätzung.“ Diese Oberfläche ist jetzt die bestätigte Alternative im aktuellen Satz **alltagssprache-v1-0020-s1** von `to my mind|to my mind/ADV|to-my-mind#nach-meinem-dafurhalten`: „To my mind, this plan is much too risky.“ Die tatsächliche Ersetzung lautet „in my opinion, this plan is much too risky.“ Beide Ziele überschneiden sich semantisch; der vorhandene Validator verbietet eine bereits angebotene Alternative als weiteres neues Ziel (`authoring_context.py`, `validate_context`, require … already offered word).

Nur dieser eine Konflikt wurde durch vollständigen Vergleich aller 353 späteren Oberflächen mit allen gespeicherten Alternativen festgestellt. Die unveränderte Auswahl hat rechnerisch 89 importiert / 89 für Batch 2 / 264 später. Diese Partition ist **nicht als gültiger Fortsetzungskontext abgenommen**, weil die Gesamtauswahl abgewiesen wird.

Die geprüfte Alternative zu streichen, das historische Auswahlziel umzuschreiben, einen neuen Sinn zu erfinden, Ziele stillschweigend auszuschließen oder den Validator zu lockern wäre keine minimale Reparatur eines Satzlieferfehlers. Deshalb keine Batch-2-Auswahl-/Registry-/Gruppendatei und keine ZIP veröffentlicht; die Vorbereitung prüft vor dem Schreiben. Export und ZIP-Verifier für Batch 2 wurden mangels gültigem Kontext nicht ausgeführt. Der bereits geprüfte interne Batch-1-Pack bleibt gestagt.

Kleinster nächster Schritt: ausdrücklich genehmigtes **versioniertes Auswahlkorrektur-Inkrement**, das den Doppelauftrag für in my opinion auflöst und die 442er-Zählung/Partition entsprechend neu festlegt; historische Originalauswahl und geprüfte Alternative erhalten. Bei ausschließlichem Ausschluss dieses künftigen Doppelziels wären es 441 Ziele, Batches 89/89/88/88/87 und Partition 89/89/263. Das ist ein Vorschlag, hier nicht umgesetzt. Kein Auffüllen oder Ersatzsatz erzeugt.

## Tatsächliche Prüfkommandos, Output und Exitcodes

Alle Läufe ab Repository-Root auf macOS. Unter Windows PowerShell identische Python-Argumente mit `.\pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`; Dart-/Flutter-/Git-Befehle identisch. Diagnosehilfen `/tmp/everyday-import/*.py` sind rein lokale Audits, kein zweiter Importer. Logs unter `build/alltagssprache_batch_1_checks/`.

```text
pipeline/.venv-macos/bin/python /tmp/everyday-import/audit_delivery.py
DELIVERY hashes/reference subset/source/registry/schema PASS; 89 exact selected identities, learning, definition, membership positions; 870 exact token review positions; 8 actual alternative substitutions; 8 inherited gloss findings
3 semantic token binding errors identified (see correction table).
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import/correct.py
CORRECTION COPY: build/alltagssprache_batch_1_checks/import_copy/alltagssprache_redewendungen_batch_1
3 token bindings; 1 dictionary-only sense; 2 dictionary forms; checked token hashes renewed with existing digest; complete token_review synchronized; local manifest renewed.
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
usage includes --prepare-continuation VERSION, --selection, --batch, --out, --verify-zip
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/irregular_verbs_batch_4_v1/pack.json --create build/alltagssprache_batch_1_checks/import_copy/alltagssprache_redewendungen_batch_1/editorial_content_v2.json --registry pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json --out pipeline/out/alltagssprache_redewendungen_batch_1_v1
status: ok; internal_test_pack: true; ai_calls: 0; ai_cost_usd: 0
sqlite_counts: 22 tables; cards 2656; decks 12; sentence_tokens 35088; form_targets 402
sha256: f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-import/audit_pack.py
JSON preservation PASS: all old lists exact prefixes; all non-release/registry metadata unchanged
SQL preservation PASS: all old 21 non-release tables contain every identical old row/ID; 22 complete tables checked against build_rows; integrity/foreign keys PASS
FORMS PASS: four identical form tables; 134/134/134 memberships; 402 form targets; 406 lexical mappings
GOALS PASS: 89 current imported; 353 future absent; 2656 cards; 12 decks; one active fixed sentence each
LINTER 463 warnings total; 0 errors; NEW reopen Zipf 3.42 below 3.5
VERIFIED BACKUP content.sqlite e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
VERIFIED BACKUP content.manifest.json 88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 23.89s
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/alltagssprache_redewendungen_batch_1_v1/content.sqlite
mixed: raw_words=2623; learning_targets=2542; lexical_words=2271; form_memberships=402
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/alltagssprache_redewendungen_batch_1_v1
staged assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_1_v1, schema 4, 17309696 bytes
  sha256 f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version alltagssprache_redewendungen_batch_1_v1, schema 4, 17309696 bytes
  sha256 f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.9s)
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2542 lexical=2271; 402 forms / 71 reuse / cut 3 identities PASS
deck allgemeine-sprache: 160 learning targets, 181 ownership cards, 181 fixed sentence assignments verified
deck reisen: 489 learning targets, 519 ownership cards, 519 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 262 ownership cards, 262 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 252 ownership cards, 252 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 251 ownership cards, 251 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 264 ownership cards, 264 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 248 ownership cards, 248 fixed sentence assignments verified
deck irregular_verbs_base: 134 learning targets, 129 ownership cards, 129 fixed sentence assignments verified
deck irregular_verbs_past: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck alltagssprache-redewendungen: 89 learning targets, 89 ownership cards, 89 fixed sentence assignments verified
pack alltagssprache_redewendungen_batch_1_v1 (schema 4, internal: true); 12 decks: 2445 cards, 2656 card sentences, 170 with valid_alternatives, 2656 cards in the pack
01:12 +1: All tests passed!
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_v1.json --batch 2 --prepare-continuation alltagssprache_redewendungen_batch_2_context_v1
ValueError: authoring: already offered word
Exit 1
```

Arbeitslaufabweichungen: erster Reference-Audit verwendete zunächst den verkürzten Schema-Dateinamen direkt im ZIP (KeyError, Exit 1); nach Prüfung der Archivliste gegen dessen nachgewiesenen echten Pfad verglichen. Eine vorzeitige Lesung des noch laufenden Projektionslogs ergab JSONDecodeError (Exit 1); erst nach beendetem Prozess ausgewertet, Diagnose blieb erfolgreich. Eine Wiederprüfung der alten Basis nach Staging verglich zunächst gegen das nun neue Asset (AssertionError); stattdessen korrekt gegen die vor Staging geprüfte Sicherung und unveränderte alte Quelle verglichen. Keine dieser Diagnosen änderte Inhalte/Verträge; keine Wiederholungsserie am selben Blocker. Einmaliger Fortsetzungsversuch mit belegter Ursache, keine erneute Generierung.

## Geerbte Glossenbefunde – unverändert offen

Die acht gelieferten Befunde beziehen sich auf bestehende Dictionary-Zeilen und wurden nicht zurückgeschrieben. Prüfung der originalen Zeilen und ihrer Kontextverwendungen bestanden; frühere Glossenlisten bleiben eigenständige offene Aufgaben.

| Alter Schlüssel | Alte Glosse → Vorschlag | Kontext und Befund |
|---|---|---|
| show\|show/VERB\|show#zeigt | zeigt → zeigen; zeige | Vorhandene Formglosse zeigt ist auf die 3. Person beschränkt. courtesy: Please show some courtesy and let her finish speaking. |
| home\|home/NOUN\|home#hause | Hause → zu Hause; nach Hause | Hause allein ist als Übersetzung des Ortsadverbs unvollständig. under the weather: I am feeling under the weather, so I will stay home.; on second thoughts: On second thoughts, I would rather stay home tonight. |
| parking\|parking/NOUN\|parking#park | Park- → Parken | Gebundene Glosse Park- ist im eigenständigen Gerundium unvollständig. hassle: Parking in this town is always a hassle. |
| found\|find/VERB\|find#finden | gefunden → fand; gefunden | Gefunden passt zum Perfekt bei never mind, nicht als einfache Vergangenheitsform bei tactful. tactful: She found a tactful way to tell him about his mistake.; never mind: Never mind, I have found my keys now. |
| leaving\|leave/VERB\|leave#belassen | liegen lassen → lassen; belassen | Die Formglosse liegen lassen passt nicht wörtlich zu einer unverschlossenen Tür; die Sense-Definition belassen passt. uneasy: I felt uneasy about leaving the door unlocked. |
| low\|low/ADJ\|low#niedrigen | niedrigen → niedrig | Vorhandene flektierte Glosse niedrigen passt nicht zum prädikativen Gebrauch. on the other hand: The room is small; on the other hand, the rent is low. |
| sent\|send/VERB\|send#schicken | schickte → geschickt; schickte | Vorhandene Formglosse schickte deckt das Partizip nach have nicht ab. oops: Oops, I have sent the message to the wrong person! |
| name\|name/NOUN\|name#namen | Namen → Name | Vorhandene flektierte Glosse Namen ist als alleinige Wortübersetzung unpassend. mortified: I was mortified when I forgot my best friend's name. |

Zusätzliche Einschränkung beim Begleitwortvergleich: worker#arbeiter definiert den vorhandenen Sinn mit „hier handwerklich“, während younger workers im Satz zu bias allgemeiner verwendet wird; keine bestätigte neue Wortbedeutung und kein künstlicher Alternativsense erzeugt. Geerbte flektierte/gebundene Glossen (z. B. asked/fragte, washing/Wasch-, instead/anstatt) bleiben ebenfalls unverändert; die acht gelieferten Befunde sind keine behauptete vollständige Altglossenbereinigung.

## Hashes und eigener Dateiumfang

| Datei | SHA256 |
|---|---|
| `/Users/ardasayar/Downloads/alltagssprache_redewendungen_batch_1_lieferung.zip` | `49c1fc4d6a737293e1e2bc0fa7e70cfd1dcbf18860a6b2e298e1b8b6cd7205a4` |
| `build/alltagssprache_batch_1_checks/delivery/alltagssprache_redewendungen_batch_1/editorial_content_v2.json` | `b3b45ab5f4c3142565db74ae4468ebfd48eda6fb514595031dbf6bff1404a388` |
| `build/alltagssprache_batch_1_checks/import_copy/alltagssprache_redewendungen_batch_1/editorial_content_v2.json` | `f79999a36336d74e15ecdbc4226687e2eb2992f12a08846bc0142852cb20efd8` |
| `pipeline/out/irregular_verbs_batch_4_v1/pack.json` | `bf13af162d0cd12122665f9f8dc2edfd57daaf38c9e2a6ee58125452c3a267dc` |
| `pipeline/out/irregular_verbs_batch_4_v1/content.sqlite` | `e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3` |
| `build/alltagssprache_batch_1_checks/backup/content.manifest.json` | `88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5` |
| `pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json` | `51d19fc324afed93c74dc8a4918797977bc35da797f78b8816a7da0d6da6cc1b` |
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/pack.json` | `109fed4daf499923b41147f75352dcaf30e5b7d109bc6a1b3dbd838163fc5b5b` |
| `pipeline/out/alltagssprache_redewendungen_batch_1_v1/content.sqlite` | `f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802` |
| `assets/content/en/content.sqlite` | `f1b4269482f8f27b2152529af13343236e51a8d1148eb0121adcf30443104802` |
| `assets/content/en/content.manifest.json` | `27f1cbfaf5e43c72d227ad9b6291038b40e808560dfcd5d02536e414e2083b56` |

Registry-Digest (kanonisch, Import und Kontext): `555b95a300d0aadd8245cdac8f8cd50b2f650905f5dbd037ed51549d91b0b2d2`; Registry-Dateihash getrennt oben. Originalauswahl-/Batch-1-/Gruppendateien und sämtliche historischen Lieferungen bleiben bytegleich.

Eigene Änderungen: neuer Pack `pipeline/out/alltagssprache_redewendungen_batch_1_v1/` (pack.json, content.sqlite, finalization_report.json), internes Asset/Manifest über Staging, dieser Bericht, NEXTSTEPS.md sowie versionbezogene Erwartungswerte im bestehenden `test/data/real_pack_test.dart`. Neue Checks/Originalentpackung/Importkopie/Sicherung in `build/alltagssprache_batch_1_checks/`. Keine Batch-2-Kontextdateien geschrieben.

Kein Commit: angefordertes Gesamtinkrement durch den Fortsetzungsblocker unvollständig. Zusätzlich benötigt der neue normale V2-Pack die vorbestehende uncommittete Schema-4-Kompatibilität in Importer/Authoring-Validator/Exporter und die uncommitteten Form-V3-Vorarbeiten; HEAD unterstützt diesen Weg nicht eigenständig. NEXTSTEPS und Pack-Lesetest enthalten vorbestehende gemischte Änderungen. Index vor/nach leer erhalten; keine fremden Hunks oder Abhängigkeiten pauschal aufgenommen, kein Push.

Bekannte globale CRLF-/Whitespacebefunde getrennt erhalten. Eigene Dokument-/Testpfade gezielt geprüft; keine pauschale Bereinigung. Keine Modelle/Provider gestartet, keine Paketupdates, Supabasezugriffe, echten Lernstände, Geräteläufe oder öffentliche Freigabe.

## Abschließender Datei-/Whitespacecheck

```text
git diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-1-import.md test/data/real_pack_test.dart
189 trailing-whitespace findings in the inherited CRLF portions of the existing mixed real_pack_test diff; first at test/data/real_pack_test.dart:1.
Exit 2

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-batch-1-import.md test/data/real_pack_test.dart
Output: leer
Exit 0

Direct scan: trailing-whitespace PASS; NEXTSTEPS 25 lines.
2664-file baseline: only NEXTSTEPS.md, test/data/real_pack_test.dart, assets/content/en/content.sqlite and assets/content/en/content.manifest.json changed among pre-existing files.
Original ZIP, old source/registries/selections/groups and App/SRS/V3/compatibility unchanged; index empty.
Exit 0

git status --short
Actual complete output saved as build/alltagssprache_batch_1_checks/status-after.txt; large inherited mixed worktree retained.
Exit 0
```

Die 189 Standard-Git-Befunde sind erhaltene CRLF-Zeilen im bestehenden Testdiff, keine globale Bereinigung vorgenommen. Der konfigurierte Check und direkte Zeilenscan bestehen. Build-Ausgaben sind ignorierte interne Artefakte; ein neuer Bericht liegt zusätzlich zum Baselineumfang vor.
