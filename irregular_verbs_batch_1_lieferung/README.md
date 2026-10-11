# Unregelmäßige Verben – Satzlieferung Batch 1

83 neue Satzpaare, vier satzgebunden geprüfte regionale Varianten, 851 Tokenpositionen (759 Worttokens, 92 Satzzeichen). 99 aktuelle Formziele: 83 neue Übungen und 16 unveränderte Bestandsübungen. Die 71 Wiederverwendungen betreffen den gesamten Katalog.

## Anwendung

Diesen Ordner im Projekt entpacken und IMPORT_PROMPT.txt an den lokalen Coding-Agenten geben. Die Datei enthält bereits den kompletten Prüf-, Import-, Staging- und Fortsetzungsauftrag. In diesem Chat wurde nichts im App-Pack installiert. Keine Modell-API wurde aufgerufen.

## Dateien

- editorial_content_v3.json: vollständige V3-Lieferung mit eingefrorener Auswahl und exakt aktuellem Metadatendelta, neuen Satzpaaren, Lücken, Tokens, Wörterbuchergänzungen und satzgebundenen Reviews.
- satzuebersicht.html: alle 83 Satzpaare, Formfunktionen und Alternativen zum Lesen.
- token_review.json: alle Wortbindungen mit den tatsächlich verfügbaren Formglossen zur nachvollziehbaren Prüfung.
- validation_report.json: tatsächliche eigenständige Prüfungen und ihre Grenzen.
- IMPORT_PROMPT.txt: lokaler Folgeauftrag.
- manifest.json: SHA256 der Lieferdateien.

## Redaktion

Jede neue Übung hat genau einen festen Satz. Grundformen stehen in passenden Präsens-, Modal-, Infinitiv- oder Imperativkontexten. Besonders bei bet, broadcast und cost machen Modal-/Infinitivkontexte die Grundform deutlich. Vergangenheitsformen besitzen einen passenden narrativen oder ausdrücklich vergangenen Kontext; Partizipien stehen nach have/has.

Alle 83 Satzpaare und ihre Wortbindungen wurden in diesem Chat redaktionell gelesen. Die vier Alternativen ersetzen exakt die Lücke: burned für burnt (s045/s046), dreamed für dreamt (s078/s079). Bedeutung und Zeitform bleiben jeweils erhalten. Keine Vollständigkeit der Alternativensuche und keine unabhängige menschliche Sprachfreigabe werden behauptet.

Die 16 wiederverwendeten Übungen dieses Batches sind unverändert im Metadatenkatalog referenziert. Es gibt keine neuen Satz-/Tokenzeilen für sie. Die neue Lieferung bewertet ihre bisherigen Formglossen nicht neu.

## Tatsächliche Prüfungen

- Eingangs-ZIP: CRC bestanden; alle 77 manifestierten Dateien SHA256-geprüft.
- Importformat: JSON Schema editorial_content_v3 bestanden.
- Quell-, Registry- und Auswahlhash stimmen mit dem gelieferten Kontext überein.
- Aktuelles Metadatendelta exakt erhalten, nur erlaubte Begleitwort-Lemmas/Senses ergänzt.
- Neue Referenzen eindeutig; jede Wortbindung hat einen vorhandenen oder ausdrücklich ergänzten Sense und eine Formglosse.
- Lücken, Formzielreferenzen, Reihenfolge, Offsets und vollständige Tokenabdeckung geprüft.
- Review-Hashes und alle vier Alternativsubstitutionen geprüft.
- Entsprechende Linterregeln eigenständig geprüft: höchstens 14 Wörter, höchstens ein untergeordneter Teilsatz, genau ein Zielvorkommen, passende Lücke und Satzabschluss. 0 Fehler. Ein Häufigkeitshinweis: spoonful, Zipf 2,87.
- Enthaltene Quell-SQLite read-only geöffnet: integrity_check=ok, 18 Tabellen; Bytes durch SHA256 an die geprüfte Basis gebunden.
- Dieselbe spaCy-Version 3.8.16 und das mitgelieferte Modell 3.8.0 verwendet. Keine archivierten Python-Skripte ausgeführt.

Hier nicht ausgeführt: aktueller Repository-Importer, build_rows, vollständiger SQL-Export/Zeilenabgleich, Flutter, Staging oder Geräteprüfung. Diese Prüfungen sind Teil des beigefügten lokalen Importprompts.

## Erhaltene Grenzen des alten Wörterbuchs

Das Wörterbuch hat genau eine Formglosse je Oberfläche/Sense, nicht je Formfunktion. Bereits vorhandene Glossen wie bent→„beugte“, brought→„brachte“, caught→„fing“ und cost→„kostete“ sind deshalb nicht für jede neue Formfunktion passend. Einige Begleitwortglossen tragen noch Kompositumshinweise, etwa software→„Software-“, concert→„Konzert-“ und bedroom→„Schlafzimmer-“. Die Satzübersetzungen sind hiervon unabhängig korrekt formuliert. Diese Bestandswerte wurden nicht überschrieben und sind nicht als neu freigegeben zu verstehen.

Neue Wörterbuchzeilen verwenden bei identischen Formen funktionsübergreifend geeignete Glossen, z. B. bound→„band; gebunden“. Für alte gleichlautende Formen werden keine künstlichen Senses zur Tempustrennung angelegt. Eine spätere Bereinigung der alten gemeinsamen Formglossen muss ausdrücklich und versionsgebunden erfolgen.

Ergänzt werden 31 Begleitwortbedeutungen und 81 fehlende Formglossen. Diese Ergänzungen erzeugen keine zusätzlichen Lernkarten oder Besitzer. Sie vermeiden unpassende Altbindungen: Rundfunksender statt Bahnhof, Interview statt Bewerbungsgespräch, Pfosten statt Post und Spielkarten statt Ausweise.

## Umfang und Fortsetzung

Gesamtkatalog: 134 lexikalische Ziele, 402 Formübungen, davon 71 wiederverwendete Karten und 331 neue Satzaufträge. Formziele je Batch: 99 / 105 / 99 / 99. Neue Satzaufträge: 83 / 83 / 84 / 81.

Batch 1 bindet 33 Formziele je Verbenstapel ein. Nach dem Import muss die Fortsetzung 99 importierte / 105 aktuelle / 198 spätere Formziele ausweisen. Das sind Formziele, keine neue globale Wortzahl. Die nächste ZIP verlangt 83 neue Sätze und enthält zusätzlich 22 Wiederverwendungen für Batch 2.

Produktionsversion als Vorschlag für den tatsächlichen Import: irregular_verbs_batch_1_v1, Content-Schema 4. Bei unveränderter Quelle ergeben sich 2319 Karten (2236+83); die lexikalische Gesamtzahl muss der lokale Prüfer aus den Zuordnungen berechnen.
