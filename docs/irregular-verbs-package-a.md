# Unregelmäßige Verben: Paket A

Stand 10.10.2026. Content-Schema 4, kompatibler Leser und Offline-Formworkflow sind implementiert. Es gibt keine produktive Verbenauswahl, neue Produktionssätze oder gestagten Schema-4-Inhalte. Paket B ist offen. Ausgangsarchitektur und unveränderte Roadmap: [gemeinsamer Plan](irregular-verbs-implementation-plan.md).

## Implementierter Vertrag

- `schema.columns_for(version)` erhält den alten 18-Tabellen-Vertrag für Schema 1/2/3 und liefert 22 Tabellen für Schema 4. Der bestehende `build_rows` bleibt der öffentliche strikt validierende Einstieg. `export_sqlite` baut die komplette Datenbank temporär und ersetzt das Ziel erst nach erfolgreichem Abschluss.
- `lexical_targets`, `card_lexical_targets`, `form_targets` und `deck_practice_targets` ergänzen den vorhandenen Pack. Karten erhalten `identity_function` und `introduction_scope`, Stapel `practice_kind`, Satztoken nullable `form_target_id`. Exakte Spalten, Identitäten und Regeln: [Content-Schema](content-schema.md#schema-4-explizite-formübungen-10102026-paket-a).
- Neue Karten-ID nur bei einer neuen Formfunktion: Namespace `form_cards`, Schlüssel Sprache/Form/Sense/Funktion. Die Zeile liegt in `cards`. Alle bisherigen ID-Namespace-Schlüssel bleiben gleich. Funktionen sind `base`, `past`, `past_participle`; ein Formziel braucht einen Verb-/Auxiliar-Sense. `base` ist Grundform, kein vollständiges Präsensparadigma.
- `form_targets` bindet genau eine aktive Karte je normalisierter Formidentität; auch die umgekehrte aktive Bindung ist eindeutig. Falsche Sprachen, Funktionen, Oberflächen, Senses, fehlende/retirierte Referenzen und konkurrierende unklassifizierte Altkarten scheitern. Eine schon kanonisch belegte Altkarte wird nicht zusätzlich als neue Formkarte eingeführt.
- Alte ordinary-Karten behalten ID, Gruppe und festen Satz. Neue `form_only`-Karten benötigen eigene Singleton-Gruppen und genau einen festen aktiven Satz mit explizitem Formziel im Zieltoken. Besitzerprüfung und Primärmitgliedschaften gelten weiterhin; eine explizite Besitzaliasauflösung berechtigt nicht zur Antwort. `accepted` bleibt exakt die Zielform; Satzalternativen durchlaufen den bisherigen Reviewvertrag.
- Lexikalische Zuordnungen sind vollständig je bestehender aktiver Lerngruppe und je aktiver Sense-Menge: entweder keine explizite Zuordnung oder alle Mitglieder auf dasselbe L. So darf derselbe erfasste Begriff nicht gleichzeitig explizit und über einen Gruppen-Fallback gezählt werden. Andere Senses werden nicht automatisch gleichgesetzt; deren semantische Zuordnung bleibt redaktionell.
- `deck_words`/`deck_cards` bleiben Besitzinventar. Zusätzliche `deck_practice_targets` verwenden eigene Positionen 1..n. Ansichten vervielfachen weder Karten noch Besitzer.

## Auswahl, Redaktion und Fortsetzung

Der Formmodus heißt `sprachapp.form-selection`, `format_version: 2`. Er ist zusätzlich zum bestehenden base-Auswahlmodus implementiert. Die Auswahl ist ein Metadatenkatalog ohne Satzgenerierung:

| Feld | Vertrag |
|---|---|
| `entries` | Genau `form_target`, `authoring_batch`, `reuse`; alle katalogisierten Formziele genau einmal |
| `batches` | Schlüssel `1` bis `n`, je Batch das genaue additive Metadatendelta; keine Satztexte |
| `authoring_batch` | Genau der aktuelle Batch; Quelle enthält genau die früheren Formziele |
| `source_sha256` | SHA256 der tatsächlichen Quell-JSON-Bytes |
| `registry_sha256`, `registry_path` | Kanonischer Registryhash und vorhandene lokale Datei; Parent und alte Reservierungen bleiben gebunden |
| `source_pack` | Für ZIP/Continuation: `path`, `sqlite_path`, `sqlite_sha256` |
| `reuse` | Altkarte, Funktion, Begründung, `card_sha256`, `context_sha256`; letzterer bindet festen Link, Satz und Tokenhash |

`validate_form_selection` prüft auch den vollständigen späteren Metadatenkatalog, ohne nicht vorhandene Sätze vorzutäuschen. Es meldet `imported/current/future`, `reused_cards`, `new_form_targets`, `new_lexical_targets`, `new_surface_reservations`, `new_cards` getrennt. „new“ bezeichnet den gegenüber der jeweiligen Quelle noch fehlenden Katalogumfang; `reused_cards` zählt die expliziten Altkartenbelege des gesamten Katalogs. Reservierungen können bereits vor dem ersten Import auch spätere Oberflächen enthalten; nachfolgende Batches dürfen sie nicht erneut reservieren.

`import_editorial_patch.py --create` akzeptiert unverändert V2 sowie strikt V3. V3 bindet Auswahl und deren kanonischen Hash zusätzlich zu Quelle/Registry. Aktuelle Karten-, Deck-, Besitz-, Alias-, Lexikal- und Formmetadaten müssen exakt dem aktuellen Delta entsprechen. Geplante Lemmas/Senses müssen vorhanden sein; zusätzliche Begleitwortdaten sind explizit möglich. Bestehende Zeilen bleiben erhalten; es gibt keinen V3-Weg zum Umschreiben alter fester Sätze oder Tokens. Reviews binden jeden neuen Satz, seine Übersetzung, Tokens, Links und Alternativsubstitutionen. Tokenizer/Linter, Export und Readback sind die vorhandenen Wege. Unbekannte Formate oder unvollständige Bindungen erzeugen keine erfolgreiche Ausgabe.

ZIP-Kontextformat 3 bindet Ziel-Schema 4 und tatsächliches Quellschema 3/4. Enthalten sind Pack/SQLite, Auswahl, Registry, Gruppen, Wörterbuch, getrennte Besitz-/Übungspositionen, relevante Quellen/Verträge, Konfiguration, Paketversionen und vorhandene Offline-Tokenizergewichte. Aktuelle und spätere Gruppenmetadaten stehen im eingefrorenen Auswahlkatalog. Keine Zugangsdaten, Venv oder Lernstände. Geschlossener temporärer ZIP → CRC-/Hashprüfung → aktuelle Validatoren → vollständiger Tabellen-/Spalten-/Zeilenabgleich → exklusive Veröffentlichung. Archivierter Quellcode wird niemals ausgeführt.

`check_sqlite` öffnet mit `mode=ro` und vergleicht die vollständige Tabellenmenge, Spaltenreihenfolge und alle Nutzwerte mit `build_rows`; wie bisher ist der beim Export gesetzte `created_at`-Zeitstempel vom Nutzwertvergleich ausgenommen. Die Bytes der SQLite sind zusätzlich per SHA256 gebunden.

Befehle nach Aktivierung der vorhandenen Pipeline-Umgebung identisch in Windows PowerShell und macOS Terminal; Platzhalter durch eigene neue lokale Testpfade ersetzen:

```text
python pipeline/scripts/export_authoring_context.py --selection SELECTION.json --batch 1 --out NEW_AUTHORING.zip
python pipeline/scripts/export_authoring_context.py --verify-zip NEW_AUTHORING.zip
python pipeline/scripts/import_editorial_patch.py --source BASE/pack.json --create EDITORIAL_V3.json --registry REGISTRY.json --out NEW_IMPORT
python pipeline/scripts/export_authoring_context.py --prepare-continuation NEW_VERSION --selection SELECTION.json --source-pack NEW_IMPORT/pack.json --source-sqlite NEW_IMPORT/content.sqlite --batch 2 --out NEW_SNAPSHOTS
python pipeline/scripts/export_authoring_context.py --selection NEW_SNAPSHOTS/selection.json --batch 2 --out NEW_BATCH_2.zip
```

Fortsetzungen gehen genau einen Batch weiter und schreiben neue `selection.json`/`registry.json` erst nach Prüfung. Vorhandene Snapshots werden nicht überschrieben; der Schema-4-Teilimport braucht kein Produktionsstaging. Programmatische Entsprechung: `prepare_form_continuation(...)`. Alte ZIPs können mit `--verify-zip DATEI --historical` gegen ihre eingefrorene Basis und aktuelle Validatoren geprüft werden; diese Option bestätigt ausdrücklich keine Übereinstimmung mit dem heutigen Asset-/Quellcodestand.

## Dart-Schnittstellen und Grenze zu Paket B

- `ContentDatabase.open`/`validateContentSchema`: Schema 1/2/3 weiter lesbar, Schema 4 über `validateFormContent`; unbekannte Versionen und ungültige Referenzen werden als `ContentUnavailable` abgelehnt.
- `ContentCard`: nullable `formTarget`, `identityFunction`, `lexicalTargetId`; `introductionScope` mit Altstandard ordinary. `FormTarget` transportiert `id`, `cardId`, `senseId`, `form`, `function`, `lexicalTargetId`.
- `ContentRepository.deckPracticeTargets(String deckId) -> Future<List<DeckPracticeTarget>>`: bei Formstapeln positionsgeordnete konkrete Formkarten; bei ordinary/Altinhalten bisherige Primärbesitzkarten mit ordinary-Scope. `deckCardIds` bleibt Besitzdiagnose. `DeckSummary.practiceKind` trennt Deckarten; Formdeckgröße ist die Anzahl seiner Übungsmitgliedschaften.
- `StoryToken.formTarget`: konkrete belegte Referenz oder null. `resolveStoryWord` transportiert bei expliziter Funktion die genaue Karte, blockiert deren Add aber mit „Formbezogenes Story-Hinzufügen benötigt Paket B.“ Unbelegte mehrdeutige Treffer wählen keine beliebige Karte. Wörterbuchglossen bleiben Form/Sense-bezogen.
- `stageContentPack` verweigert Schema 4 vor Zielkopie. `ContentPackInstaller` verweigert es vor Installation. Tests weisen Erhalt vorhandener Inhaltsdateien nach. Reine Leserunterstützung ist keine Freigabe für die App.

Paket B muss nun `deckPracticeTargets` in gemeinsame Einführung, Session-/Gemischt-/Revue-Projektion übernehmen; gleiche C global deduplizieren, getrennte Funktionen dagegen nicht als Synonyme zusammenlegen. Lexikalische Zahl als eindeutige L mit vollständig unzugeordnetem Gruppen-Fallback, SRS-Übungszahlen weiterhin nach Karten und Zustand ableiten. UI-Benennung und Sichtbarkeit müssen diese Unterscheidung erklären. Die bisherigen vier globalen Zähler sind in A unverändert.

Weiter offen: additive user.db-v4→v5-Migration für lokale Formbindung, formbezogene `LearningIdentity`/Fingerprint, idempotenter Story-Add, lokale/contentseitige Wiederverwendung und Konfliktdarstellung ohne Review-/Zustandsverschmelzung. Bestehende `ensureCards`/`recordReview` bleiben der einzige Lernstandsschreibweg. Erst nach B-Tests und kompatibler App-Abnahme Staging-/Installationssperren entfernen. Geräteprüfung und öffentliche Inhaltsfreigabe stehen aus. Erst danach gemeinsame echte Verbenauswahl und Chat-Satzredaktion.

## Dateien und begründete Abweichungen

| Bereich | Geänderte / neue Dateien |
|---|---|
| Pipeline-Vertrag | `pipeline/src/sprachpipe/{ids,schema,pack,content_contract,selection,authoring_context,deck_display,export,db}.py`; neu `form_targets.py` |
| Bestehende CLI | `pipeline/scripts/{import_editorial_patch,export_authoring_context,finalize_curation}.py`; neu `pipeline/data/curation/editorial_content_v3.schema.json` |
| Leser/Transport | `lib/domain/{content,repositories,story_learning}.dart`; `lib/data/content/{content_database,drift_content_repository,content_pack_installer}.dart`; neu `form_content_validation.dart`; `tool/stage_content_pack.dart` |
| Tests | neu `pipeline/tests/{form_fixture,test_form_targets}.py`, `test/fixtures/form_content_v4.sql`, `test/data/form_content_test.dart`; angepasst `pipeline/tests/test_pack_db_export.py`, `test/fixtures/deck_repositories.dart` |
| SQL-Spiegel | neu `supabase/migrations/20261010000001_form_targets.sql` |
| Dokumentation | `PRODUCT.md`, `NEXTSTEPS.md`, `docs/{content-schema,pipeline,srs,learning-groups-v1,decks-and-story-learning-plan,irregular-verbs-implementation-plan}.md`; dieser Bericht |

Der neue pure Validator bündelt Formregeln; `learning_groups.py` und `word_registry.py` bleiben unverändert und werden weiterhin aufgerufen. `db.py` ist unmittelbar abhängig: Legacy-Upserts müssen die tatsächlich vorhandenen Tabellen verwenden statt den neuesten 22-Tabellen-Katalog auf Schema 3 anzuwenden; kein Datenbankaufruf wurde ausgeführt. `story_learning.dart` ergänzt nur das Token-Transportfeld. `tool/content_pack.dart` ist ein separater CSV-Wortlistendiagnostiker und bleibt unverändert, weil er kein SQLite-Paket staged oder liest. Keine Drift-Tabellenklassen oder Codegen-Eingaben geändert; kein Codegen erforderlich.

Die neue lokale SQL-Spiegelmigration wird über den vorhandenen Schema-Abgleich gegen `COLUMNS` geprüft. Sie ergänzt Spalten/FKs/Checks und partielle Identitätsindizes; bestehende Migrationen bleiben unverändert. Keine Ausführung gegen PostgreSQL, keine Remote-Migration behauptet.

## Nachweise

Ausschließlich synthetische Technikfixtures: go/went/gone, cut/cut/cut, run/ran/run. Drei Importe erzeugen insgesamt **9 Formziele, 9 Karten (1 erhaltene Altkarte, 8 neue), 3 lexikalische Ziele, 6 Besitzer und 12 Übungsmitgliedschaften**. Die gleiche Grundformansicht referenziert dieselben Karten erneut. Partitionen: **0/3/6 → 3/3/3 → 6/3/0**. Alle 22 SQLite-Tabellen werden nach jedem Import vollständig abgeglichen. Die eingecheckte SQL-Testfixture wird ihrerseits mit dem tatsächlichen Python-Workflow abgeglichen und durch den Dart-Leser gelesen.

Negative Fälle umfassen doppelte Besitzer/Formidentitäten, falsche Deckfunktion, fehlenden/mehrdeutigen Satz, falsche Sprache/POS/Sense/Tokenreferenzen, fehlende/retirierte lexikalische Ziele, unvollständige Gruppen-/Sense-Zuordnung, unklassifizierte Konkurrenz, unnötige neue Karte trotz kanonischer Altkarte, ungültige Aliasse, nicht automatisch erlaubte Aliasantwort, Dictionary-Konflikt, veraltete Quell-/Kontexthashes, unbekannte Version/Felder, fehlende Reviews und nicht überschreibbare Ausgaben. Vorhandene ID-Testvektoren und Legacy-Import-/Export-/Lesetests bleiben erhalten.

Die folgenden Befehle wurden lokal auf macOS ausgeführt. Auf Windows steht nach Aktivierung der vorhandenen Umgebung `python` statt `pipeline/.venv-macos/bin/python`; Flutter-Befehle sind identisch. Vollständige lokale Logs: `/tmp/irregular-verbs-package-a/`.

| Tatsächlich ausgeführter Befehl | Tatsächlicher Output (relevanter Ausschnitt) | Exitcode |
|---|---|---:|
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | `431 passed, 19 subtests passed in 17.85s` | 0 |
| `flutter test` | `00:32 +261: All tests passed!` | 0 |
| `flutter analyze` | `No issues found! (ran in 3.0s)` | 0 |
| `pipeline/.venv-macos/bin/python /tmp/irregular-verbs-package-a/verify_pack.py` | `PASS build_rows + check_sqlite: 18 tables, complete row comparison, read-only`; `primary_goals=2121 cards=2236 owners=2132 sentences=2770 links_total=2764 active_links=2236`; Asset/Manifestprüfung PASS | 0 |
| `pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_authoring_batch_3.zip --historical` | `zip_verification: PASS`, `hashed_files: 82`, `sqlite_tables: 18`, `sqlite_cards: 2156`, `selected: 242` | 0 |
| `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check -- <eigene Dateiliste>` | keine Ausgabe | 0 |
| `python3 /tmp/irregular-verbs-package-a/audit.py` | vollständiger Bestands-/Hashaudit und eigene Whitespaceprüfung; Ergebnisse unten | 0 |

Die Dateiliste und die tatsächlich pro Datei ausgeführten Befehle stehen in `/tmp/irregular-verbs-package-a/changed-files.json` sowie `whitespace-crlf.json`. Zusätzlicher Vergleich jeder eigenen Änderung gegen die Vorherkopie: `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --no-index --check BEFORE AFTER` (bei neuen Dateien BEFORE=`/dev/null`). Kein Whitespaceoutput; Git liefert hier **1 für vorhandene Unterschiede**, nicht 0. Der Audit akzeptiert nur 0/1 ohne Ausgabe. Ohne `cr-at-eol` melden erhaltene CRLF-Zeilen `trailing whitespace` (Exit 3 = Unterschied plus Befund). Es wurden keine alten Zeilenenden vereinheitlicht.

Bekannte repositoryweite Altbefunde bleiben getrennt und unverändert: `DESIGN.md:162–164`, `docs/alltag-zuhause-continuation.md:148/153`, `docs/arbeit-bildung-batch-1-import.md:127`, `docs/arbeit-bildung-batch-2-import.md:121`. Keine pauschale Bereinigung und keine Behauptung eines sauberen Gesamtarbeitsbaums.

Frühe gezielte Läufe deckten echte Integrationsanpassungen auf: Legacy-Tabellenschleifen und das Export-Fault-Injection-Testdouble mussten versionsbezogen werden (anfangs 4 Fehler; danach 70/70 grün). Ein neuer Dart-Test verwendete zunächst einen falschen Methodennamen; ein neuer Fortsetzungs-CLI-Test fand einen fehlenden Import. Beide wurden korrigiert. Analysehinweise zu Blockklammern wurden behoben. Der erste Flutter-Aufruf benötigte freigegebenen Zugriff auf den vorhandenen SDK-Cache; es wurden keine Pakete installiert. Alle abschließenden Prüfbefehle oben sind erfolgreich. Die erste Audit-Hilfe behandelte den erwarteten `--no-index`-Exit 1 fälschlich als Fehler; die Auswertung unterscheidet jetzt Unterschiede und tatsächliche Whitespacebefunde.

## Erhaltener Bestand

Audit gegen 2566 vorab erfasste Dateien: **29 auftragsgemäß geänderte Bestandsdateien, 2537 bytegleich; 9 neue Auftragsdateien**. Alle 73 erfassten geschützten Produktionsdateien sind hashgleich. Vorbestehende Änderungen bleiben erhalten; unveränderte Bereiche gemischter LF/CRLF-Dateien wurden bytegleich aus dem gesicherten Stand beibehalten.

| Datei | SHA256 vor und nach Paket A |
|---|---|
| `pipeline/out/natur_umwelt_batch_3_v1/pack.json` | `7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e` |
| `pipeline/out/natur_umwelt_batch_3_v1/content.sqlite` | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| `assets/content/en/content.sqlite` | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| `assets/content/en/content.manifest.json` | `e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b` |

Die historische Natur-Batch-3-ZIP wurde nur gelesen; SHA256 `a06984d08bb50530fcc812fb39123545b5307c684c12038c01e8996c07602956`. Ihre 2156 Karten sind die damalige Basis vor Batch 3, kein abweichender heutiger Produktionsstand. Heute bleiben 2121 primäre Lernziele in acht Stapeln intern gestagt. Keine echte user.db, Zustände oder Reviews geöffnet; keine Cloud-/Modellaufrufe, Remote-Migrationen, Commits oder Pushes. Synthetische Satzreviews sind ausschließlich Testdaten. Geräte-/App-Abnahme für Formstapel und öffentliche Freigabe wurden nicht durchgeführt.
