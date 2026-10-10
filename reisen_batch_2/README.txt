REISEN – BATCH 2
100 zusätzliche Lernwörter, jeweils ein englischer Übungssatz und eine deutsche Übersetzung.
Erstellt und redaktionell geprüft von ChatGPT. Keine unabhängige menschliche Freigabe.

SO VERWENDEN
1. Diesen Ordner als sprachapp/reisen_batch_2/ entpacken.
2. Bei Bedarf reisen_batch_2.html zum Lesen öffnen.
3. Den vollständigen Inhalt von PROMPT_CODEX.txt in eine neue Codex-Sitzung im Projekt kopieren.
Codex integriert die kleine Positionsanpassung, prüft, exportiert und stagt anschließend
in einem Auftrag. Keine Dateien per Hand in eine SQLite-Datenbank kopieren.

ENTHALTEN
reisen_batch_2.editorial.json: vollständiges unverändertes Create-v2-Schema;
 100 Karten, 100 Sätze, 984 Tokens, 14 redigierte Alternativen.
deck_display_patch.json: separate hashgebundene Reihenfolge für alle 200 Reisenwörter.
deck_display_patch.py: reine Referenzimplementierung der Positionsanpassung.
test_deck_display_patch.py: 6 bestandene Tests, einschließlich Fehlerszenarien.
verify_reisen_batch_2.py: read-only Prüfung; --repo zusätzlich gegen das aktuelle Projekt.
annotation_review.txt: alle Wortbindungen zum Nachlesen.
reference/: unveränderter kompletter Authoring-Kontext einschließlich Basis-Pack und Schema.
authoring_audit.json und validation.txt: tatsächliche Prüfungen und deren Grenzen.

POSITIONEN – KEIN WIDERSPRUCH ZUR REGISTRY
Das Create hängt die neuen Zeilen zunächst auf Anzeigen 101–200 an, damit das bisherige
Append-Verfahren einen gültigen Zwischenstand im Speicher erhält. Danach verändert die
separate Funktion ausschließlich die position-Spalten der Reisen-deck_cards/deck_words.
Das Endergebnis ist 1–200 nach den ursprünglichen Auswahlpositionen (siehe Referenzmapping).
95 bestehende Reisen-Anzeigen ändern ihre Position, keine IDs oder Texte. Die ersten
fünf bleiben 1–5; passport wechselt beispielsweise von Anzeige 6 zu Anzeige 11.
Auswahl und Registry behalten ihre ursprünglichen Positionen. Den Zwischenstand nicht stagen.
Das optionale --display-patch des Importers muss erst integriert werden. Es wird nicht
behauptet, dass der unveränderte aktuelle Importer diese Option schon unterstützt.

GEPRÜFT HIER
Alle 100 Satzpaare und Wortbindungen redaktionell gelesen; Alternativen wörtlich eingesetzt.
JSON-Schema, Quell-/Registrybindungen, Wortabdeckung, Tokens, Lücken, Review-Hashes.
Echte mitgelieferte tokenize-Funktion und Linter mit spaCy 3.8.16 / en_core_web_sm 3.8.0:
0 Fehler, 14 Häufigkeitswarnungen; Sätze mit 5–12 Wörtern. Die Warnungen sind keine
Grammatikfehler. Parser-POS-Etiketten wurden nicht blind als Wortbedeutungen übernommen.
Vollständige Neusortierung im Speicher geprüft: nur die beiden erlaubten Positionsfelder
ändern sich. Referenztests bestanden. Kein Gemini/Vertex-Aufruf.

NOCH IM PROJEKT ZU PRÜFEN
Aktuelles create_content/build_rows, neu integrierter CLI-Pfad, SQLite-Export,
Staging und echter Pack-Lesetest. Kein iOS-/Android-Test hier durchgeführt.
Erwarteter Endstand: 464 Karten, 998 Satztexte inkl. 6 Story-Sätzen, 992
Karten-Satz-Verknüpfungen inkl. Historie, 360 Primärwörter (160 Allgemeine Sprache + 200 Reisen).
Bestehende Wortglossen werden nicht überschrieben. Alte verkürzte Wörterbuchanzeigen sind
mit dieser Lieferung nicht pauschal bereinigt. Kartentexte nutzen die vorgegebenen Zielübersetzungen.
Das Pack bleibt intern; technische Prüfungen erklären keine öffentliche Inhaltsfreigabe.

QUELLEN
Basis: pipeline/out/reisen_batch_1_v1/pack.json
Raw SHA256: 874b4a95d0a060fc9a77d7dc0dc426018942fa35ad7b2119731fb5281ceb6540
Registry: pipeline/data/words/en.reisen_batch_2_v1.json
Canonical SHA256: e2331264c70e18c2bbb8e92ce8ead4e7d81f14a342da466e7b1c1c990c5a3642
Die historische source_sqlite_sha256-Angabe der Quellregistry bleibt unverändert;
für diese Übergabe sind ihr kanonischer Hash und der tatsächliche Pack-Rohbytehash maßgeblich.

LOKALE REVISION (06.10.2026)
14 gelieferte Alternativen vollständig gelesen; plane entfernt, front desk zu the front desk korrigiert. Jetzt 13 Alternativen. Satzpaare/Annotation unverändert. Originalaudit/validation.txt beschreiben den Lieferzustand. Details: local_corrections.json.
