Arbeit & Bildung – Authoring-Gruppe 2, 82 von 245 Zielen
Basis: arbeit_bildung_batch_1_v1, Schema 3, Rohbyte-SHA256 ebe5fd764d290d671682cff10f55f1b06e35026b5a19b1c3216ab6dadd89b3a2.
Nur die entries in authoring_context.json redigieren. Es wurden noch keine Sätze erstellt.
Alle Identitäten, Ausschlüsse, Definitionen und Entscheidungen stehen in selection.json.
Das vollständige aktuelle Wörterbuch steht in dictionary_context.json und pack.json.
Gruppen sind unabhängig vom Wortbesitz: learning_groups.json enthält unveränderte
Altentscheidungen und separat reservierte neue Köpfe. Der historische Hash in
existing beschreibt die frühere Umstellung; der äußere Hash bindet an diese Basis.
Schema 3 verlangt cards.learning unverändert aus dem jeweiligen Auswahlziel.
Keine Variante/Synonymgruppe automatisch als gültige Lückenantwort freigeben.
Die vorhandene Satzprüfung (reviewer, reviews, Token-/Linkhashes und geprüfte
Alternativen) bleibt Teil des Imports; keine zusätzliche formelle Freigabe nötig.

Ergebnisformat: editorial_content_v2.schema.json im Pfad pipeline/data/curation/.
Genau ein neuer fester Übungssatz je ausgewählter Karte, vollständige Tokenabdeckung,
Wörterbuchglossen für jedes Wort, getrennte Kontextprüfung für Story-Lernziele.
Keine bestehenden Zeilen ändern. Benötigte neue Begleitwort-Senses explizit definieren.
Neue Karten referenzieren neue oder wiederverwendete Senses; keine alten Senses ändern.
Der Stapel besteht bereits. combined_display_mapping.json enthält die gemeinsame endgültige Zuordnung nach dem künftigen Import; aktuelle Pack-Positionen bleiben unverändert.
Die Redaktion darf weder Originalpositionen noch stabile IDs umnummerieren.
Lernreihenfolge bestimmt später die App, nicht die Reihenfolge in dieser ZIP.

Tokenizer: sprachpipe.annotate.tokenize(text, nlp). Linter: sprachpipe.linter.lint_sentence.
Modell offline: spacy.load('runtime/en_core_web_sm', disable=['ner']).
Echte Quellen, Modellgewichte, Konfiguration und Versionsangaben sind enthalten.
Python-Pakete müssen in passender lokaler Umgebung vorhanden sein; keine Venv enthalten.
Nur tokenize/lint/import verwenden, keine Generierungsfunktionen starten.

ZIP-Prüfung im Projekt (gleicher Befehl in PowerShell und macOS-Terminal bei aktivierter Pipeline-Umgebung):
python pipeline/scripts/export_authoring_context.py --verify-zip <Pfad-zur-geschlossenen-ZIP>
Späterer Import, erst nach Satzredaktion, mit dem bestehenden Importer:
python pipeline/scripts/import_editorial_patch.py --source pipeline/out/arbeit_bildung_batch_1_v1/pack.json --create <redaktion.json> --registry pipeline/data/words/en.arbeit_bildung_batch_2_context_v1.json --out <neues-Ausgabeverzeichnis>
Keine Zugangsdaten, Lernstände, Cloud-Aufrufe oder automatisches Staging.
manifest.json listet alle Nutzdateien mit SHA256; der ZIP-Gesamthash steht im Prüfbericht.

FORTSETZUNG: 82 importiert / 82 aktuell / 81 später.
Keinen Stapel anlegen. Nur aktuelle Karten hinzufügen; bestehende Satzbindungen sind in selection.json eingefroren.
sense_availability bezeichnet wiederzuverwendende Begleitwort-Senses; die Originalauswahl bleibt unverändert.
continuation_display_mapping.json trennt bestehende Positionen, Anhängepositionen und endgültige Display-Patch-Zeilen.
Die endgültige Zuordnung gilt erst nach dem künftigen Import plus hashgebundenem --display-patch.
