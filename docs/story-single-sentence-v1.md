# Story-Einzelsätze: Plan und Abnahme

## Plan vor Implementierung

Basis: `story_contexts_v1`, Commit `1f554f0`, manifestgebundener Asset-SHA `ebe0063895e7d4dd7c6d0f93855102741fc95eef37485d0aeb76153420229351`. Arbeitsbaum und Hashes aller vorhandenen Änderungen sowie historischer Lieferung/Exporte in `build/story_single_sentence/baseline.json` und `baseline.patch` gesichert. UI-Höhe 40/30, Padding, Fehlerfeedback und fremde Dateien bleiben erhalten.

1. Den vorhandenen gezielten Import additiv um einen versionierten Ein-Satz-Vertrag ergänzen. Historische Version-1-Lieferung bleibt reproduzierbar. Neue Lieferung `pipeline/data/curation/story_single_sentence_v1.json`, exklusiver Export `pipeline/out/story_single_sentence_v1/`. Alle 14 Stellen erneut prüfen, ausschließlich passende Originale verwenden; keine Storytexte, globalen Karten oder Identitäten ändern.
2. Bestehende spaCy-Tokenisierung ohne Mehrwortzusammenfassung zur Wortzählung und deren Satzgrenzenerkennung verwenden. Ein oder zwei Originalwörter verlangen einen vollständig annotierten, redigierten Ersatz. Ab drei Wörtern bleibt das Original Standard. Ersatz benötigt eine konkrete Bedeutungs-/Übungsbegründung; Pronomen, Then, unbekannte Personen und fehlende Handlung allein reichen nicht. Jeder Übungstext hat genau einen vollständigen Satz und genau eine exakt annotierte Ziellücke. Keine Nachbarsätze.
3. Die neue QA-Bindung enthält bei tatsächlich geändertem Kontext die exakte vorherige Kontextannotation und Packrevision als versionierte Korrekturvorbedingung. Die App rekonstruiert daraus den bisherigen Herkunfts- und Kontextfingerprint mit denselben bestehenden Dart-Hashfunktionen. Keine heuristische Textsuche oder pauschale Umstellung globaler Karten.
4. Optionaler Repository-Vertrag liefert geprüfte Korrekturen; vor dem Laden lokaler Übungen wird in einer Transaktion ausschließlich der exakt passende aktive lokale Kontext ersetzt: neuen unveränderlichen `card_contexts`-Snapshot einfügen, nur `user_cards.primary_context_id` wechseln. Alte Herkunft, Karten-ID, Lernidentität, Kontext-ID/Fingerprint, Text, Übersetzung, Lücke und Tokens müssen übereinstimmen. Abweichende individuelle Kontexte bleiben unangetastet. Keine Änderung von Box, Fälligkeit, Favorit, Notiz, Aktivierung oder Reviewzeilen.
5. Keine Historien-Vertragslücke: `review_log.sentence_id` verweist bereits auf `card_contexts.id`; `localHistoricalSentence` liest alte unveränderliche Snapshots. Deshalb weder Migration noch neue Reviewspalte nötig. Deterministische neue Kontext-ID und aktive Alt-ID als Vorbedingung machen Wiederholung/Neustart idempotent. Bereits geladene Resolver/ReviewPass-Snapshots bleiben unverändert; nur nächste Projektionen verwenden den neuen Kontext.
6. Temporäre Nutzerdateien testen Altpack → neuer Pack für safely/Then, historische Reviews, sämtliche Zustandsfelder, aktiven Pass, Neustart, doppelte Adds und wiederholte Korrektur. Alle 14 Originaltexte, globale Wiederverwendung und Sperren prüfen. Synthetische Kurzsätze, Abkürzungen, Mehrwortziele und Unicode ergänzen. Keine echte user.db öffnen.
7. Alle 22 Tabellen gegen Quelle und Export vergleichen, nur QA-Kontext-/Releaseänderungen zulassen; Indizes, 402 Formmitgliedschaften, 530 historische Links, Tombstones und 137 bestehende Provenienzlücken erhalten. Asset/Manifest vor internem Staging sichern. Vorgeschriebene Tests sequenziell, originales 30s-Packtestbudget, Analyse und Verify. Eigene Änderungen isoliert committen; NEXTSTEPS gezielt ≤25 Zeilen, nicht mitcommitten. Kein Push, keine Installation oder Cloud.

Dieser Ein-Satz-Vertrag ersetzt die frühere Auswahl Original/Ausschnitt/Ersatz im historischen Bericht; dessen damalige Entscheidungen und Lieferungen bleiben als Nachweis erhalten.

## Präzisierung aus der Aufruferprüfung

Die Wortlistenprojektion `wordListProvider` bevorzugte bisher den Satz des letzten Reviews. Für lokale Karten verwendet sie künftig den aktiven lokalen Übungskontext; globale Karten behalten ihren bestehenden Pfad. Historienabfragen bleiben unverändert. Diese kleine Datenprojektionsänderung ist zusätzlich nötig, damit bereits geübte korrigierte Karten auch in der aktuellen Wortliste den neuen Satz zeigen. Direkte Provider-Aufrufer und Tests geprüft; GitNexus meldet hier UNKNOWN wegen fehlender Variablenreferenzen, keine Entwarnung. Der Migrationstest prüft ausdrücklich den tatsächlichen `VocabWord.sentence` und dessen Übersetzung.

## Erneute Redaktion aller 14 Wortstellen

| Quelle / Token | Ziel | Vorher | Nachher / Begründung |
|---|---|---|---|
| open-pocket/s1 / 1 | arrives | Maya arrives at the station early. | Maya arrives at the station early. — arrives bezeichnet das Ankommen am Bahnhof im Präsens; Original und Übersetzung belegen die Zielbedeutung. |
| open-pocket/s1 / 5 | early | Maya arrives at the station early. | Maya arrives at the station early. — early bezeichnet die frühe Ankunft; Original und Übersetzung sind als Satzübung geeignet. |
| open-pocket/s2 / 0 | She | Maya arrives at the station early. She puts her backpack on a table in the café. | She puts her backpack on a table in the café. — She ist das weibliche Subjektpronomen sie. Die Identität der Person ist zum Üben dieser Bedeutung nicht erforderlich; nur Originalsatz 2. |
| open-pocket/s2 / 1 | puts | She puts her backpack on a table in the café. | She puts her backpack on a table in the café. — puts bedeutet stellt den Rucksack auf den Tisch; Zielbedeutung und Übersetzung stehen im Original. |
| open-pocket/s3 / 2 | points | A man points to the open pocket of her backpack. | A man points to the open pocket of her backpack. — points bedeutet mit einer Geste zeigt; points to the open pocket belegt die Zielbedeutung. |
| open-pocket/s3 / 3 | to | A man points to the open pocket of her backpack. | A man points to the open pocket of her backpack. — to bedeutet auf in points to, keine Infinitivpartikel; Original und Übersetzung sind ausreichend. |
| open-pocket/s3 / 5 | open | A man points to the open pocket of her backpack. | A man points to the open pocket of her backpack. — open beschreibt das nicht geschlossene Fach als Adjektiv; Original ist geeignet. |
| open-pocket/s5 / 1 | puts | Her train ticket is about to fall out. Maya puts it safely inside and thanks the man. | Maya puts it safely inside and thanks the man. — puts bedeutet steckt hinein; Übersetzung belegt genau diese Bedeutung. it allein rechtfertigt keinen Nachbarsatz. |
| open-pocket/s5 / 3 | safely | Her train ticket is about to fall out. Maya puts it safely inside and thanks the man. | Maya puts it safely inside and thanks the man. — safely bedeutet sicher beim Hineinstecken; Original und Übersetzung sind geeignet, der it-Bezug erfordert keinen Zusatzsatz. |
| open-pocket/s5 / 4 | inside | Her train ticket is about to fall out. Maya puts it safely inside and thanks the man. | Maya puts it safely inside and thanks the man. — inside bedeutet hinein; der Originalsatz mit Übersetzung belegt die Richtung trotz it. |
| open-pocket/s5 / 6 | thanks | Maya thanks the man. | Maya puts it safely inside and thanks the man. — thanks bedeutet bedankt sich bei dem Mann. Der Originalsatz ist eine geeignete Übung, keine Verkürzung nötig. |
| open-pocket/s6 / 0 | Then | Maya arrives at the station. Then she walks to the platform. | Then she walks to the platform for her train. — Then bezeichnet die zeitliche Folge dann; welche vorherige Handlung stattfand ist für diese Bedeutung nicht erforderlich. |
| open-pocket/s6 / 1 | she | Maya arrives at the station. Then she walks to the platform. | Then she walks to the platform for her train. — she ist das weibliche Subjektpronomen sie; fehlender Name ist allein kein Ersatzgrund. |
| open-pocket/s6 / 2 | walks | Maya arrives at the station. Then she walks to the platform. | Then she walks to the platform for her train. — walks bedeutet geht zu Fuß zum Bahnsteig; Original und Übersetzung belegen genau diese Bedeutung. |

Alle deutschen Übersetzungen entsprechen exakt dem jeweiligen Originalsatz. Vollständige Vorher-/Nachher-Annotationen, Offsets, Sense-IDs und Korrekturvorbedingungen: [contexts.json](evidence/story-single-sentence-v1/contexts.json). Acht Kontexte geändert, sechs Kontextfingerprints unverändert; 14 Wortstellen, 13 lokale Identitäten (She/she identisch). Keine globale Karte erzeugt.

## Lokaler Updatepfad und Historienschutz

`StoryContextCorrectionSource` liefert pro Content-Repository gecachte Korrekturen. `PracticeItemResolver.load` wendet sie über die optionale `StoryContextCorrectionStore`-Fähigkeit vor der nächsten lokalen Projektion an. Jede Transaktion verlangt die deterministische lokale ID, passende Sprache/Form/Sense/Funktion, aktive alte Kontext-ID, alte Release-Revision, exakte Story-/Satz-/Tokenherkunft samt gespeicherter Herkunftszeile, bisherigen Source-Fingerprint sowie identische Kontexttexte, Lücke und Tokenübersetzungen. Globale oder zurückgezogene Ziele werden nicht korrigiert. Deaktivierung bleibt unverändert; auch deaktivierte lokale Karten erhalten lediglich den neuen Kontextverweis.

Die Transaktion fügt den neuen Kontext mit deterministischer ID und eine neue Herkunftszeile hinzu. Nur `primary_context_id` wird aktualisiert; selbst `updated_at`, Box, due_at, Favorit, Playlist, Notiz, Aktivierung, Ursprung und Erstellungszeit bleiben exakt gleich. Alte `card_contexts` und `review_log` sind weiterhin durch Immutable-Trigger geschützt. Replays scheitern bereits an der inzwischen gewechselten aktiven Alt-ID und schreiben nichts. Ein schon laufender `ReviewPass` und sein Resolver behalten den alten Snapshot und speichern dessen alte Satz-ID auch bei Abschluss nach dem Packwechsel. Historische Texte bleiben über `historicalSentence` auflösbar.

Die Tests verwenden ausschließlich neu erzeugte temporäre user.db-Dateien. safely (aktiv) und Then (deaktiviert) werden aus `story_contexts_v1` hinzugefügt, beantwortet, mit Favorit/Notiz/Playlist versehen und anschließend über den echten Wortlistenprovider auf den neuen Pack umgestellt. Sämtliche Zustandsfelder außer dem vorgesehenen Kontextverweis und sämtliche bereits bestehenden Reviewzeilen werden vollständig verglichen. Zwei parallele Korrekturaufrufe, Neustart, doppelte Adds und ein vor dem Wechsel gestarteter Pass sind abgedeckt. Abweichende Herkunft und individuelle Übersetzung bleiben unverändert.

## Bestandsprüfung und internes Staging

Alle 22 Tabellen entsprechen dem neuen Offline-Export; gegenüber der vorherigen Quelle ändern sich ausschließlich fünf QA-Satzzeilen und die Release-Metadaten. Sämtliche Indexdefinitionen stimmen exakt mit dem alten Export überein. 3768 Karten (3767 aktiv), 402 Formmitgliedschaften, 530 historische Links und dieselben 137 bereits bekannten Provenienzlücken bleiben erhalten. Tatsächlicher Resolver: 58 Tokens, 50 verfügbar, zwei Eigennamen und sechs Satzzeichen weiterhin gesperrt.

Asset und Manifest wurden nach Hashabgleich unter `build/story_single_sentence/prestage-backup/` gesichert. Stage-Output: `story_single_sentence_v1`, Schema 4, 26.198.016 Bytes; SHA-256 `b85793932825a22e92ac744a42255e9f333acd35809aaba46edb5a395f099bdb`; 22 Tabellen stimmen mit dem Abschlussbericht überein, Exit 0. Historische Lieferdatei und beide bisherigen Exportdateien unverändert. Vollständige [Tabellenprüfung](evidence/story-single-sentence-v1/audit-result.json), [Inventar](evidence/story-single-sentence-v1/inventory.json) und [geschützte Hashes](evidence/story-single-sentence-v1/hashes.json).

## Manuelle Prüfung bereits hinzugefügter Wörter

Mit einer bereits vorhandenen safely-/Then-Karte den neuen App-/Packstand öffnen, ohne die Wörter zu entfernen oder erneut hinzuzufügen. In der Wortliste und beim nächsten regulären Üben muss safely genau „Maya puts it safely inside and thanks the man.“ und Then genau „Then she walks to the platform for her train.“ zeigen. Übersetzung und einzelne Lücke müssen passen; Box, Fälligkeit, Notiz und Favorit unverändert. Ein bereits geöffneter Durchgang behält bis zu seinem Ende den alten Satz. Nach Neustart bleiben die neuen aktiven Sätze erhalten. Diese Geräteprüfung wurde nicht durchgeführt.

## Dateien und Graphprüfung

Eigene Implementierung: `pipeline/src/sprachpipe/curate.py`, `lib/domain/story_learning.dart`, `lib/data/content/drift_content_repository.dart`, `lib/data/user/drift_user_repository.dart`, `lib/data/learning/practice_item_resolver.dart`, `lib/presentation/providers/learning_providers.dart`. Der vorhandene Import-CLI bleibt unverändert; nur seine bereits bestehende Dispatch-Funktion erhält die neue Operation. Lieferung: `pipeline/data/curation/story_single_sentence_v1.json`. Tests: `pipeline/tests/test_story_contexts.py`, `test/story_context_completion_test.dart` (neuer Pack als Abnahmequelle; Schutzassertionen erhalten), `test/story_single_sentence_test.dart`. Vertrag/Bericht: `docs/schema4-targeted-curation.md`, dieser Bericht und `docs/evidence/story-single-sentence-v1/`.

Vor Edit: `_apply_story_contexts` LOW, direkter Aufrufer `apply_targeted_patch`; Contentrepository MEDIUM mit Installer/Provider/Diagnosepfaden; Userrepository und PracticeItemResolver LOW mit Lern-/Wortlisten-/Sessionprovidern. `resolveStoryWord`, `apply_targeted_patch` und `wordListProvider` UNKNOWN; direkte Service-/CLI-/Provider-/Testreferenzen zusätzlich geprüft. Kein Nulltreffer als Entwarnung.

Erzwungener PDG-Reindex erfolgreich: 84.880 Knoten, 260.273 Kanten, 392 Flows, Exit 0. `detect_changes(scope=all)` nach Vormerken der eigenen Dateien: 75 Symbole, elf Prozesse, Gesamtrisiko **high**, weder partial noch truncated, alle 75 Symbole geliefert. Die vollständige [Graphausgabe](evidence/story-single-sentence-v1/graph-check.json) enthält auch die unveränderten, nicht mitcommitteten UI-Altänderungen. HIGH-Warnung ausgesprochen; Import-/Kanonisierungs-/Tombstone-/Satzanzahlpfade mit vollständiger Python-Suite, Tabellenvergleich und direkten Diffs geprüft. Bekannte Graphgrenzen bleiben: 2215 nicht ausgewählte Einstiegspunkte, 1041 übersprungene Callees, drei budgetbegrenzte Walks sowie unvollständige Dart-Methodenkörper/Interfaceauflösung. Reale Repository-/Provider-/Reviewtests ergänzen diese Abdeckung. MCP zeigte zunächst einen veralteten Commit-Metadatenhinweis trotz erfolgreichem CLI-Reindex; `.gitnexus/meta.json` und erneute CLI-Diffprüfung bestätigten den aktuellen Index auf `1f554f0`.

## Ausgeführte Prüfungen

Alle sieben vorgeschriebenen Befehle liefen in der angegebenen Reihenfolge, jeweils mit Exit 0. Keine parallelen Flutter-Prozesse, kein erhöhtes Testtimeout. Vollständige Befehlsargumente, Laufzeiten und Outputenden stehen in [checks.json](evidence/story-single-sentence-v1/checks.json); Rohlogs lokal unter `build/story_single_sentence/`.

| Befehl ab Repository-Root | Tatsächlicher Output | Exit |
|---|---|---|
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_story_contexts.py -q` | 28 passed in 67.64s | 0 |
| `flutter test --no-pub test/story_context_inventory_test.dart test/story_context_completion_test.dart test/story_context_synthetic_test.dart test/story_learning_flow_test.dart test/story_target_navigation_test.dart test/data/targeted_curation_test.dart` | 00:37 +27: All tests passed! | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | 510 passed, 19 subtests passed in 100.76s | 0 |
| `flutter test --no-pub` | 00:59 +326: All tests passed! | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | 00:08 +1: All tests passed! | 0 |
| `flutter analyze --no-pub` | No issues found! (ran in 4.1s) | 0 |
| `dart run tool/stage_content_pack.dart --verify` | verified; story_single_sentence_v1 / Schema 4 / 26198016 bytes; 22 table counts match | 0 |

Der originale Packtest ist per Hash unverändert; sein 30s-Budget bleibt erhalten. Zusätzlicher Entwicklungslauf der vier neuen Darttests: 00:12 +4 PASS. Ein früher Analyseversuch meldete vier fehlende Blockklammern in neuen Guards (Exit 1); gezielt behoben, die abschließende Analyse ist sauber. Keine Testlockerung.

Python-Aufrufe oben wurden auf macOS mit `pipeline/.venv-macos/bin/python` ausgeführt. Unter Windows PowerShell lautet der Interpreter `.\pipeline\.venv\Scripts\python.exe` mit denselben Argumenten; Flutter-/Dart-Befehle sind auf beiden Plattformen gleich.

CRLF-bewusster Diffcheck ausschließlich für eigene Dateien: keine Ausgabe, Exit 0. UI-/Fehlerfeedback-/Höhenänderungen, fremde Dateien und überlappendes NEXTSTEPS bleiben außerhalb des Commits. Arbeitsbranch `codex/story-single-sentence-v1`; keine echte user.db bearbeitet, keine Installation, Cloudaufrufe, öffentliche Freigabe oder Push.
