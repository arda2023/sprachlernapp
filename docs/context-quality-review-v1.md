# Kontextqualität v1 — Offline-Review

## Plan vor Inhaltsmutation (15.10.2026)

Basis: Commit 5c1c605, Branch codex/context-quality-review-v1. Die UI-Änderungen und der Performancefix bleiben erhalten. NEXTSTEPS.md enthält vorbestehende Änderungen; unversionierte redaktionelle Lieferungen bleiben unberührt.

Verifizierte Quelle: `pipeline/out/business_email_batch_6_perf_v1/pack.json`, SHA-256 `48f8c3037e37cf8aaa83188c868af6706fd7f749592785433ee30b74070800d4`. Manifest: business_email_batch_6_v1, Schema 4, 22 Tabellen. Asset: 26095616 Bytes, SHA-256 `4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`.

1. Aktive Karte-Satz-Verknüpfungen vollständig durchsuchen; Muster sind nur Kandidatensignale. Kandidaten einzeln mit Bedeutung, Formfunktion, EN/DE und wörtlich eingesetzten Alternativen lesen. Alte Pilotbefunde auf die heutigen aktiven Sätze abbilden. Historische Sätze getrennt ausweisen.
2. Entscheidungen im vorhandenen `sprachapp.editorial-patch`, Version 1, dokumentieren. Rohhash, kanonischer Hash, Satz-/Link-Preconditions und unveränderliche IDs binden jede vorgeschlagene Änderung. Keine neue Importschnittstelle.
3. Vor Anwendung den tatsächlichen Offline-Vertrag prüfen: `import_editorial_patch.py` (`--create`, `--single-sentence`, `--legacy`, `--finish`); `curate._editorial_sentence`, `pack.build_rows`, `content_contract.transition`, `export.export_sqlite`, `finalize_curation.check_sqlite`. Bestehende CLI-Flags nicht als Unterstützung anderer Operationen auslegen.
4. Englische Korrektur braucht neue Satz-/Link-IDs, vollständige neue Tokenannotation und im Pack lesbare alte Referenzen. DE-/Glossenkorrekturen erhalten IDs. Karten-/Sense-/Form-/Gruppenidentitäten bleiben erhalten. Nur so#auf_diese_weise darf nötigenfalls über einen vorhandenen sicheren Vertrag zurückgestellt werden. Kein Ändern einer echten user.db.
5. Erst bei vollständigem Vertrag und null Pending: neuer Ausgabeordner, Linter, atomarer Export mit beiden Performanceindizes, vollständiger 22-Tabellen-Abgleich. Vor Staging Asset und Manifest sichern/hashprüfen. Bei fehlendem Vertrag sichere Reviewartefakte abschließen und Export/Staging ausdrücklich blockiert lassen.
6. Pipelinetests, unveränderter 30s-Packtest, Flutter-Analyse, Asset-Verifikation und eigener Diffcheck; tatsächliche Ausgaben dokumentieren. Isolierter Commit ohne Push; NEXTSTEPS wegen Überlappung nicht mitcommitten.

## Identifizierter Ausgangsfehler

- Karte `so|so/ADV|so#auf_diese_weise`, ID `1bbe26267773ad288ddd7bf7063c4437`.
- Sense `bda23837a15322457cb8b35042563e1a`, Lemma `c4ac4a6a23d97edc0d68d69086bb2dc0`.
- Aktiver Satz `1e047de6e0a0f09136a14753a634cb52`, Link `1d4823e6d50251a33f70c10582ae2fce`, Lücke [14,16), accepted=[so], Alternative=[thus].
- EN: Cut the bread so, Luis, with long smooth cuts.
- DE: Schneide das Brot so, Luis, mit langen gleichmäßigen Schnitten.
- Die Glosse „so / auf diese Weise“ passt zur ausgewählten Bedeutung. Die isolierte Aufgabe verlangt jedoch eine nicht vorgeführte Art der Ausführung; die nachgeschobene Beschreibung und Anrede ergeben keinen natürlichen Alltagssatz. „thus“ macht ihn formeller, behebt die didaktische Schwäche nicht. „like this“/„this way“ sind keine identische Zielform; „like this way“ ist kein geeigneter Ersatz.
- Genau ein aktiver Satz dieser Sense; zwei historische Links: `6b16d298c448ea845b600cfd8eb27637` (Luca holds the guitar so and strikes the strings.) und `d35bd278154554f67175421eda5326d1` (Stick the address label on the box so.), beide seit single_sentence_v1 archiviert. Beide haben ebenfalls keinen eigenständigen Demonstrationsbezug und werden nicht reaktiviert.

## Ergebnis und technische Grenze

**Review abgeschlossen, Inhaltsanwendung blockiert. Der Brotsatz ist weiterhin aktiv; das Haupt-Akzeptanzkriterium ist nicht erfüllt.** Keine Änderung an Asset, Manifest, Quellen, App-Code oder Lerndaten. Die Nutzeranweisung sieht für einen fehlenden sicheren Importvertrag ausdrücklich dokumentierte Teilarbeit vor; es wurde deshalb keine neue Rückstellungsarchitektur improvisiert.

Der heutige Stand unterscheidet sich von der alten Empfehlung: Die ursprüngliche deck_cards-Zeile der so-Karte (Position 70) ist bereits seit `single_sentence_v1` historisch. Aktiver Wortbesitzer für `so` ist Karte `edaf95dbbdd46375bc6a288b2e215c3f`, Sense `so#so_sehr`, Position 33. Die beanstandete Karte und ihr Brotsatz sind dennoch selbst aktiv und können bestehenden Lernständen dienen. Ein bloßes Entfernen einer Stapelzuordnung wäre wirkungslos; kein künstliches Abziehen von eins von den Neunutzerzahlen.

Konkrete, separat belegte Grenzen:

1. `create_content` erweitert Listen, untersagt `removed_in/replaced_by` bei neuen Zeilen (`create cannot retire content`) und bietet kein Update vorhandener Karten/Sätze. V3 verbietet ausdrücklich neue Links zu bestehenden festen Sätzen. `--display-patch` ändert nur Anzeigeplätze; `--single-sentence` ist der gebundene Schema-1→2-Übergang, keine Rückstellungsschnittstelle.
2. Ein **nur im Speicher** gesetztes removed_in an der so-Karte wird von `build_rows` abgewiesen: **`learning: missing/retired/foreign primary`**. Ihre Singleton-Gruppe zeigt auf sich selbst. `validate_learning` prüft auch diese historische Karte gegen einen aktiven Kopf. Umgruppieren auf so#so_sehr wäre eine verbotene Bedeutungsänderung. Keine Änderung der Validierung vorgenommen.
3. Der alte `make_plan` setzt deck_cards für jede Karte voraus und scheitert auf der realen Schema-4-Quelle mit **`KeyError: 'irregular:beat:past'`**. Form-only-Karten sind keine fehlenden Daten; der Legacy-Adapter passt nicht zu diesem Bestand.
4. `_editorial_sentence` ersetzt die alte Satzzeile/Token im Arbeitsstand und bewahrt sie nur in `curation_log.history`. Das genügt nicht für weiterhin per Satz-ID lesbare Reviews. Ein Änderungslog außerhalb des Packs ist kein Ersatz für historische Pack-Zeilen.
5. `verify_exchange` verlangt ein vollständiges Korpus aller **4296** aktiven und historischen Links. Die **111 tatsächlich gelesenen** Paare bestehen die Einzel-Preconditions; anschließend erwartete Ablehnung **`corpus does not cover every sentence link`**. Die übrigen 4185 Links wurden nicht fälschlich als redaktionell gelesen/„keep“ markiert. Diese Abdeckungsgrenze allein könnte durch weitere Redaktion geschlossen werden, die Update-/Historien-/Rückstellungsgrenzen dadurch jedoch nicht.

Benötigte Folgearbeit: vorhandenen Offline-Patchvertrag gezielt für Schema 4, historische Satzzeilen und gezielte Rückstellung eines Singleton-Gruppenkopfes erweitern, einschließlich kompatibler Leser-/Queue-/Reviewtests. Der genaue Umgang mit bereits gespeicherten Zuständen muss zum Verbot einer unkontrollierten user.db-Änderung passen. Das ist hier dokumentierte Restarbeit, keine ausgeführte Architekturänderung.

## Reproduzierbare Suche und tatsächliches Lesen

Vollständiger Suchraum: **3768 aktive Karten-Satz-Links** (`removed_in IS NULL` an Karte, Link und Satz), unabhängig von primärer Neueinführung. Historie: 528 weitere Links; zusätzlich sechs Storysätze außerhalb des Übungssuchraums. SQL, sämtliche Regexe, historische Referenzlisten und genaue Quellwerte stehen in [review.json](evidence/context-quality-v1/review.json); das reine Prüfscript [audit.py](evidence/context-quality-v1/audit.py) berechnet die Treffermenge erneut und verlangt exakte Übereinstimmung.

Suchfamilien: demonstrative Art-und-Weise-Ausdrücke und so vor Interpunktion; eingefügte/anfängliche/abschließende Anreden; nackte this/that-Bezüge; exemplarische unnatürliche Kombinationen (u. a. like this way, makes a photo, do a decision, strong rain) sowie bewusst breite Kontrollwörter strong/heavy/smooth/sprawling/metropolis. Hinzu kommen die dokumentierten Pilotfälle aus Abschnitt 4 und Glossenschlüssel aus Abschnitt 9 des alten Kurationsplans sowie which#fragepronomen. Die Glossenschlüssel ohne aktive Zielkarte werden nicht als vermeintlich fehlende Übungen erfunden. Dies ist keine semantische Vollsuche über alle denkbaren Sprachfehler.

Erste Musterrunde einschließlich Kartenbefunden: 15 Treffer. Erweiterte Muster: 69 weitere. Aktuelle Sätze der alten Einzel-/Alternativenfälle: 18 weitere. Alte Glossenschlüssel und which: neun weitere. Insgesamt **111 eindeutige aktive Paare redaktionell gelesen**, mit sämtlichen **11 vorhandenen Alternativen wörtlich eingesetzt**: **102 unproblematisch, sechs Grenzfälle, drei bestätigte Befunde**. Die JSON enthält für jedes Paar Nummer, stabile IDs/Refs, vollständigen EN/DE-Text, Ziel-/Sense-Glosse, vorhandene Definition (null bleibt null), Wortart/Formlabel, Alternativsätze und begründete Entscheidung. Keine maschinelle Trefferliste als Sprachfreigabe ausgegeben.

Grenzfälle vollständig: Nr. 1 höfliches your mit Vorname (möglich, soziale Situation unklar); Nr. 2 that als Relativpronomen mit zu breiter Kartenglosse; Nr. 11 I didn't mean it that way (Gesprächsreparatur, vorangegangene Äußerung fehlt); Nr. 13 I suppose so (natürliche Antwortformel ohne vorausgehende Proposition); Nr. 73 introduce … colleague, Sara (Apposition oder Anrede); Nr. 111 Sense-Glosse Klassenzimmer- (alte Attributschreibweise, Satz/Formglosse korrekt). Keine dieser Karten zurückgestellt oder zusammengeführt.

Beispiele bewusster Entwarnung: that green jacket on the shelf benennt den Gegenstand; so heavy that benennt Grad/Folge; has been … so far hat einen Zeitrahmen; your … you and Ben trägt den Plural; singular they bezieht sich auf someone. Heavy rain, strong current und smooth landing sind passende Kombinationen. Ein winziger Hund an einer schweren Tür ist überraschend, aber plausibel. Gehobenes but und seltene Wörter wurden nicht allein wegen Register/Schwierigkeit verworfen.

Historische so-Sätze separat gelesen, nicht in den 111 gezählt:
- Luca holds the guitar **thus** and strikes the strings. Gleiche fehlende Demonstration, stärker formelles Register.
- Stick the address label on the box **thus / this way / like so**. Alle drei Varianten verweisen ebenfalls auf eine nicht gezeigte Ausführung. Keine Wiederaktivierung; this way/like so bleiben historische neutrale Alternativen, keine neue Zielform.

Alte Pilotprobleme wurden anhand der heutigen aktiven Fassung beurteilt, nicht blind weitergeführt: the quieter hat eine Begründung; been einen so-far-Zeitrahmen; drives on ersetzt talk on about; allgemeines you hat keine persönliche Anrede; which hat zwei genannte Schlüssel; die alten noon-/bedtime-Sätze sind nicht mehr aktive Sätze dieser Karte. Die getrennte Form-/Sense-Glossenharmonisierung und vollständige Wörterbuchredaktion bleiben offen.

## Gebundene Entscheidungen, noch nicht angewendet

Die Datei [context_quality_v1.json](../pipeline/data/curation/context_quality_v1.json) verwendet das vorhandene **sprachapp.editorial-patch v1** als Entscheidungsformat, ausdrücklich kein ausführbares Pack. Keine erfundene retire-Operation. `card_recommendations.status` bleibt `recommendation_not_applied`; sentence-/metadata_operations sind Vorschläge, die Statistik beschreibt gelesene bzw. vorgeschlagene Datensätze, nicht erfolgte Mutationen.

| Befund | Vorher | Vorgeschlagene Entscheidung |
|---|---|---|
| so#auf_diese_weise | Cut the bread so, Luis, with long smooth cuts. | Genau dieses Ziel zurückstellen, sobald ein sicherer Vertrag existiert; keine Ersatzbedeutung und kein künstlicher Erklärsatz. |
| let's keep it that way | Let's keep it that way for the rest of the week. / Lassen wir es für den Rest der Woche so. | The kitchen is clean. Let's keep it that way. / Die Küche ist sauber. Sorgen wir dafür, dass sie so bleibt. |
| like#fuellwort, Kartenglosse | quasi / sozusagen | so (umgangssprachlich als Zitateinleitung). Der vorhandene Satz und seine DE-Übersetzung bleiben unverändert. |

Der neue Zweitsatz bezieht sich auf die vorher ausdrücklich saubere Küche. Karte `ca8c7f9b1f100ebc671639b0d71fdf64`, bisheriger Satz `dd8ab9cfb2023421fe9e62249c9e509a`, vorgeschlagener Satz `ffc8ac9d8c30d444dc471a2c1425bbf4`, Lücke **[22,44)**; accepted bleibt exakt `let's keep it that way`, Alternativen bleiben leer. Neue Satz-/Link-ID werden mit stable_id gebildet, gap_offsets wurde ausgeführt. Die neue ID existiert noch nicht im Pack. Vollständige Satz-/Link-Hashes, Quellidentität und Vorher-/Nachher-Felder stehen im Patch. Die like-Karte bleibt `7e36dbaded1247f91a76a6577dfe5345`; keine neue Sense oder Formfunktion.

Begleitwortprüfung separat: Brotsatztokens Cut/the/bread/so/Luis/with/long/smooth/cuts passen lexikalisch zu den gespeicherten Glossen; fehlender Demonstrationskontext bleibt ein Satzproblem. Keine Formziel-ID gebunden. Im like-Satz sind Feier, Eva, was, This chocolate cake tastes wonderful konsistent; die Wörterbuchglosse „umgangssprachliches Füllwort oder Zitat-Einleiter“ umfasst die aktuelle Verwendung, die knappe Kartenglosse dagegen nicht. Im alten keep-it-that-way-Satz bezeichnet for eine Dauer; seine allgemeine Formglosse „seit / lang“ ist kein idiomatischer deutscher Ersatz für diesen zukünftigen Zeitraum. Sie wird nicht als neue Freigabe übernommen oder global überschrieben. Der Ersatz entfernt diesen Begleitkontext. **Vollständige neue Token-/Wörterbuchannotation des Ersatzsatzes bleibt vor einem künftigen Import erforderlich**; kein fingiertes QA=ok und keine ungelösten Schritte als exportfertig bezeichnet.

Die erste Ersatzfassung („The kitchen is tidy, so let's keep it that way.“) wurde nicht übernommen: Linter meldete zwei Nebensätze sowie tidy unter der Häufigkeitsschwelle. Neue belegbare Hypothese: koordinierendes so/let-Konstruktion wurde im komplexeren Satz ungünstig analysiert. Die einfachere Zwei-Satz-Fassung mit clean besteht unveränderte Regeln: **0 Fehler, 0 Warnungen**. Ein Fehlversuch, anschließend begründete Textänderung; keine Testschleife und keine Regeländerung.

## Bestand, Export und Zähler

`build_rows` validiert die vollständige unveränderte Schema-4-Quelle. `check_sqlite` vergleicht sämtliche fachlichen Spalten und Zeilenmultimengen aller **22 Tabellen**, nur exportseitiges created_at ausgenommen. Beide partiellen Performanceindizes vorhanden. [Vollständiger Auditoutput](evidence/context-quality-v1/audit-result.json) enthält jede Tabellenzahl und die konkreten Blocker.

Damit bleiben insbesondere **3768 Karten, 6759 Senses, 402 Formziele, sämtliche learning-Metadaten, 4302 Sätze, 4296 Links einschließlich 528 historischer Links und 47082 Tokens** unverändert. Historische Satzreferenzen sind in SQLite enthalten; kein zusätzlicher Beweis aller 528 Reader-Aufrufpfade behauptet. Die historischen 402-/528-Spezialassertions bleiben wie zuvor offen.

Frisch ausgeführt: echte App-Projektion über `tool/report_learning_groups.dart`, ohne reale Lernstände. Gemischt: **3654 Übungen / 3383 Wörter**, Formmitgliedschaften 402, Formansichten 134/134/134, 14 Stapel. Keine Differenz zum Ausgangsstand, weil nichts angewendet wurde; keine Summe von Besitzzeilen. [Projektionszusammenfassung](evidence/context-quality-v1/projection-summary.json).

`pipeline/out/context_quality_v1/` wurde zuvor nicht existent vorgefunden und exklusiv angelegt. Er enthält **nur review_audit.json**, ausdrücklich `blocked_not_applied`, **kein pack.json, kein content.sqlite und kein erfolgreicher finalization_report**. Kein Export, kein Stage --from. Deshalb auch keine vorgetäuschte Staging-Sicherung: der spätere ausführbare Lauf muss Asset/Manifest unmittelbar vor seinem Austausch sichern und die Hashes prüfen. Vorhandene Outputs wurden nicht überschrieben.

Hashnachweise:
- Asset unverändert: `4861110b1e0ab90b2487db79e47afbe9581f54b6cab3987c1a6d9e9fdd7e64b6`.
- Manifest unverändert: `7070f43a6fb04c377703488590a6054fcf28a7fdb79bf644bc9f5ba70027bcdd`.
- Originaler Packtest unverändert: `1e26c91844fcc7692f08c279b085dc4a66aeb11b4014ce841377ea2ce1358551`.
- Entscheidungspatch: `ba6226567b49b914e51fd8f38211f3d975ff9d7753929b7ddee950f9b818b3c4`.
- Einzelreview: `6470ef180b597a672ec855733564809caba524ccc1861a8b27a37e60ad620f74`.

## Tatsächliche Prüfungen

Ab Repository-Root, macOS. Logs mit argv, Exitcode und monotoner Prozessdauer unter `build/context_quality_v1/`; kompakte versionierte Belege daneben. Flutter-/Dart-/Git-Befehle sind unter Windows PowerShell gleich. Python auf Windows mit `.\pipeline\.venv\Scripts\python.exe`, auf diesem Mac mit `pipeline/.venv-macos/bin/python`; Windows nicht ausgeführt.

| Ausgeführter Befehl | Tatsächlicher Output | Exit |
|---|---|---:|
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | 461 passed, 19 subtests passed in 29.32s | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | 00:08 +1: All tests passed!; Prozess 10,94s | 0 |
| `flutter analyze --no-pub` | No issues found! (ran in 3.3s) | 0 |
| `pipeline/.venv-macos/bin/python docs/evidence/context-quality-v1/audit.py --out pipeline/out/context_quality_v1` | Erster Lauf: subclauses=2, tidy Zipf 3.53 | 1 |
| derselbe Auditbefehl nach Korrektur des Vorschlags | 3768 durchsucht, 111 gelesen; 22 Tabellen identisch; proposed_sentence_lint=[]; blocked_not_applied | 0 |
| `dart run tool/stage_content_pack.dart --verify` | business_email_batch_6_v1, Schema 4, 22 table counts match | 0 |
| `dart run tool/report_learning_groups.dart assets/content/en/content.sqlite` | Gemischt 3654 Übungen, 3383 Wörter | 0 |
| `node .gitnexus/run.cjs analyze --index-only --pdg --force` | Repository indexed successfully (34.5s) | 0 |
| `node .gitnexus/run.cjs status --json` | Indexcommit 5c1c605, Runner current; nur neue Reviewdateien als Drift | 0 |

Der Audit ist ein neues **reines Nachweiswerkzeug**, kein paralleler Importer. Er verändert weder Pack noch Datenbank, verwendet die bestehenden Validatoren und prüft erwartete Blocker in Speicherkopien. Wiederholung braucht einen anderen neuen --out-Pfad; der vorhandene Ordner wird abgewiesen. `dart run tool/stage_content_pack.dart --from pipeline/out/context_quality_v1` wurde wegen des fehlenden sicheren Exports **nicht ausgeführt**. Kein neues vollständiges Linter-/Export-PASS behauptet; der Nullfehlerbefund betrifft den vorbereiteten Ersatzsatz.

## Geräteprüfung und verbleibende Arbeit

Keine Geräteinstallation und keine echte user.db geöffnet. Die offene iPhone-Freigabe aus der UI-Aufgabe bleibt unverändert; hier wurde keine erneute Installation versucht. Nach einem später sicheren Import in einem isolierten Testprofil: Brotsatz aus aktiven Aufgaben ausschließen, alte Satz-ID im Review weiterhin lesen; feste neue keep-it-that-way-Aufgabe mit vollständiger Tokenübersetzung prüfen; like-Glosse gegen Zitateinleitung prüfen; Formansichten und gemischte Zähler vor/nach Neustart vergleichen. Keine Neuinstallation/Lernstandsübertragung als Prüfweg.

Fachlich offen: sechs oben gelistete Grenzfälle, übrige nicht einzeln gelesene Inhalte, vollständige Begleitwort-/Formglossenredaktion, menschliche Sprachabnahme. Technisch offen: Schema-4-Änderungsvertrag, sichere Rückstellung, neue Annotation, vollständiger Import/Export, Sicherung und Staging. Keine öffentliche Sprachfreigabe, keine Cloud-/Modell-API-Aufrufe, keine neuen Stapel.

Commitgrenze: sieben neue eigene Dateien — dieser Bericht, `pipeline/data/curation/context_quality_v1.json` sowie `docs/evidence/context-quality-v1/{audit.py,audit-result.json,review.json,projection-summary.json,checks.json}`. NEXTSTEPS lokal auf genau 25 Faktenzeilen aktualisiert, wegen vorbestehender überlappender Arbeit vollständig außerhalb des Commits. Andere unversionierte Lieferungen unverändert belassen. Keine bestehende Produktionsfunktion geändert; deshalb keine Vor-Edit-Impactfreigabe für eine Produktionsänderung benötigt. GitNexus-query/context verifizieren die Diagnosepfade create_content, _editorial_sentence und validate_learning; direkte Quelllektüre und reproduzierte Ablehnungen ergänzen den Graph. Der MCP-Stalenesscache meldete zunächst Rückstand, CLI bestätigt Indexcommit 5c1c605; anschließend mit den neuen Nachweisen vollständig neu indexiert. Globale Prozessgrenzen bleiben eine Analyzergrenze, kein Beweis unerreichbarer Aufrufer.

Commit-Gate: `detect_changes({scope: "all", repo: "sprachlernapp"})` liefert 37 Symbole in acht Dateien (einschließlich ungestagtem NEXTSTEPS), 37 vollständig ausgegebene Einträge, Risiko low, keine betroffenen Prozesse, keine partial-/truncated-Markierung. Änderungen sind Dokumentationsabschnitte und Variablen des neuen Read-only-Audits, keine App-/Pipelinefunktion. `git diff --check -- docs/context-quality-review-v1.md docs/evidence/context-quality-v1 pipeline/data/curation/context_quality_v1.json NEXTSTEPS.md` sowie `git diff --cached --check`: jeweils keine Ausgabe, Exit 0. Keine Whitespacebefunde in diesen eigenen Dateien; fremde CRLF-/Altänderungen wurden nicht global normalisiert. Kein Push.
