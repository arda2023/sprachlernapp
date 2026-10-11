Essen & Trinken – Authoring-Gruppe 1, 84 von 250 Zielen
Basis: koerper_gesundheit_batch_3_v1, Schema 3, Rohbyte-SHA256 c03047452c197a5bd4985af0faf64fb1e0614765a8a7c3f475f8c088a595f457.
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
Die erste Gruppe legt ausschließlich den neuen Stapel essen-trinken an.
combined_display_mapping.json enthält die Mitgliedschaftspositionen dieser Gruppe.
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
python pipeline/scripts/import_editorial_patch.py --source pipeline/out/koerper_gesundheit_batch_3_v1/pack.json --create <redaktion.json> --registry pipeline/data/words/en.essen_trinken_batch_1_context_v1.json --out <neues-Ausgabeverzeichnis>
Keine Zugangsdaten, Lernstände, Cloud-Aufrufe oder automatisches Staging.
manifest.json listet alle Nutzdateien mit SHA256; der ZIP-Gesamthash steht im Prüfbericht.
