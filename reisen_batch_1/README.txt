REISEN – BATCH 1 / 100 WÖRTER, 100 SÄTZE

ENTHALTEN
reisen_batch_1.editorial.json: vollständige additive Create-Lieferung nach dem
mitgeschickten Format v2, mit Tokenzuordnungen, Wörterbuchergänzungen und Reviews.
reisen_batch_1.html: lesbare Satzliste mit Übersetzungen und Alternativen.
PROMPT_CODEX.txt: Auftrag für lokale Prüfung, Import und internes Staging.
verify_reisen_batch_1.py: strukturelle Prüfung; --repo ergänzt den echten Import
in den Arbeitsspeicher und den Abgleich mit dem Projekt-Tokenizer.
reference/: unveränderte maßgebliche Dateien aus deiner Authoring-ZIP.
validation.txt: hier tatsächlich ausgeführte Prüfungen und ihre Grenzen.
authoring_audit.json: Umfang, Quellenbindung und redaktionelle Hinweise.

ANWENDUNG
1. Diesen ganzen Ordner als sprachapp/reisen_batch_1/ entpacken.
2. PROMPT_CODEX.txt vollständig in eine neue Codex-Session kopieren.
3. Den Ergebnisbericht zurückschicken. Die übrigen 400 Sätze sind noch nicht erstellt.

WICHTIG ZUR GRUPPIERUNG
Maßgeblich ist authoring_batch=1 im gelieferten authoring_context.json.
Die README des Ausgangsarchivs widerspricht hier den Daten: Batch 1 umfasst
NICHT die Auswahl-IDs 001–100, sondern jeweils fünf Wörter aus 20 Themenbereichen.
Die Auswahlpositionen 1..5, 26..30, ... 476..480 bleiben erhalten. In Auswahl und Registry bleiben sie erhalten. Die ausdrücklich freigegebene
Pack-Anzeige wird getrennt dicht 1..100 nummeriert.
Es wird genau ein Stapel „Reisen“ angelegt. Weitere Batches füllen dessen Lücken.
Der einzige Besitz-Alias dieses Batches ist cafe -> café; traveler, airplane
und take-off gehören zu späteren Batches. café/cafe wurde auch im Satz geprüft.

INHALT UND GRENZEN
Die Sätze und deutschen Übersetzungen wurden hier von ChatGPT geschrieben
und redaktionell durchgesehen. Ebenso wurden die Zielbedeutungen, die vollständigen
Tokenbindungen und die 15 freigegebenen Alternativantworten geprüft.
Keine Gemini-/Vertex-Aufrufe. Keine behauptete menschliche oder externe Freigabe.
Jeder Satz enthält 6–12 Worttokens und genau ein Vorkommen seines Lernworts.
Die übrigen Wörter dürfen in anderen Stapeln vorkommen. Nur die 100 Lernziele
bekommen neue Karten und Besitzzeilen. Neue Begleitwort-Senses sind Wörterbuchdaten.
Die Sprache orientiert sich überwiegend am britischen Englisch; regionale
Alternativen sind nur aufgenommen, wenn der konkrete Satz passt.
valid_alternatives ist bewusst nicht vollständig. Eine leere Liste beweist
nicht, dass ausschließlich die Zielform möglich wäre.

Die lokale Pipeline wurde hier nicht ausgeführt. Geprüft wurden das übergebene
JSON-Schema, Quellenbindungen, Referenzen, Lücken, Wörterbuchabdeckung, Review-
Hashes und die Token-Grenzen mit spaCy blank('en'). Die echte Projektfunktion
annotate.tokenize, create_content und build_rows laufen erst bei dir mit --repo.
Es gibt noch keinen Export, kein installiertes App-Pack und keine Lernstandänderung.

BESTANDSDATEN
Vorhandene Senses, Formglossen und IDs werden nicht überschrieben. Unter anderem
stehen im alten Wörterbuch noch travel -> „Reise-“, airport -> „Flughafen-“ und
railway -> „Eisenbahn-“. Die neuen Kartenübersetzungen lauten korrekt „Reisen“,
„Flughafen“ und „Eisenbahn“. Auch history -> „Geschichts-“ stammt aus dem Bestand.
Diese alten Anzeigeeinträge sind keine neu erzeugten Übersetzungen. Sie sind im
Abnahmebericht ausdrücklich zu nennen, falls die Oberfläche sie beim Antippen zeigt.

SÄTZE NACH DEM IMPORT
Unveränderter Bestand: 264 Karten, 798 Satztexte (792 bisherige Übungssätze + 6 Storys).
Erwarteter Gesamtstand: 364 Karten, 898 Satztexte, 892 Karten-Satz-Verknüpfungen,
260 Primärwörter; davon Reisen genau 100 neue Karten mit je einem Übungssatz.
Die 500 Reservierungen bedeuten nicht, dass bereits 500 Reisekarten vorhanden sind.

LOKALER ABSCHLUSS
Internes Pack reisen_batch_1_v1 exportiert und gestagt. Validator, voller Linter,
SQLite-Readback, Staging --verify und Zweistapel-Lesetest bestanden.
Originalpositionen unverändert; Packanzeige nach Originalposition dicht 1..100.
Zwei ausdrücklich gelieferte Ersatzsätze für immigration/ask übernommen.
stop ist das bestehende Nomen Haltestelle. Andere 98 Satzpaare/Annotationen/Reviews
und alle 15 Alternativen unverändert. Nur zwei Token-/Link-Review-Hashes erneuert.
Die früheren rain/get/off-Bindungskorrekturen wurden nicht zurückgenommen;
get/off werden vom Ersatzsatz nicht mehr benötigt. Referenzfreie neue have/let-
Senses und drei Formglossen entfernt, keine Bestandszeilen.
Endstand: 134 neue Lemmas, 147 neue Senses, 182 neue Formglossen, 1040 Token.
local_corrections.json dokumentiert den Verlauf; authoring_audit.json und
validation.txt bleiben ursprüngliche Chat-Lieferbelege, nicht aktueller Exportstatus.
Bericht: docs/reisen-batch-1-import.md. Originalquellen/Registry unverändert.
