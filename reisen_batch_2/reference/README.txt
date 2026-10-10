REISEN – AUTHORING BATCH 2 (100 Ziele, keine Sätze erzeugt)

Maßgeblich: authoring_context.json entries; alle 500 unveränderlichen Identitäten
stehen in all_500_identities.json. Originalpositionen sind keine Pack-Anzeige.
Basis: tatsächlich exportiertes internes reisen_batch_1_v1 (pack.json unverändert).
Byte-SHA256 für source_sha256: 874b4a95d0a060fc9a77d7dc0dc426018942fa35ad7b2119731fb5281ceb6540
Kanonischer Packhash: f26c698420824d9028c6654678fbf1816a10a743080dbd7e2271593ea0649223
Registry: en.reisen_batch_2_v1
Kanonischer registry_sha256: e2331264c70e18c2bbb8e92ce8ead4e7d81f14a342da466e7b1c1c990c5a3642
parent_sha256: 888632469bbf306e85bbe42de93082362af24a37be84f6a3c82e2258581d3a90

Die neue Registryrevision erweitert den tatsächlichen Pack-Snapshot als Elternstand.
Alle 660 Wortreservierungen sind identisch; 260 sind exportiert, 400 noch reserviert.
Quellbindung und Version fortgeschrieben, keine Identitäten oder Besitzer geändert.
Lokaler Pfad: pipeline/data/words/en.reisen_batch_2_v1.json.

Batch 2: 35 vorhandene Zielsenses, 65 neue Vorschläge. Inzwischen vorhanden:
campsite, tax, castle, ambulance, reserve, cancel, miss. Diese Senses nicht erneut
anlegen oder umbenennen. Vorhandene Glossen/Definitionen bleiben unverändert.
Aktueller Wörterbuchkontext enthält auch alle neu importierten Begleitwort-Senses.
Genau ein Satz pro ausgewählter Wortform und Bedeutung. accepted exakt [form].
Alternativen nur nach vollständiger wörtlicher Einsetzung, keine Aliaslisten kopieren.
Keine menschliche oder externe Freigabe erfinden. Review-Hashes erst nach Prüfung.
Editorial-Create-Schema liegt unverändert bei; neue Sätze vollständig annotieren,
alle Wortformen müssen zum gebundenen Sense eine vorhandene oder neue Formglosse haben.

TATSÄCHLICHER TOKENIZER UND LINTER
spaCy 3.8.16, Modell en_core_web_sm 3.8.0, NER deaktiviert.
Originalimplementierungen: annotate.py (Funktion tokenize), linter.py (lint_sentence).
Diese Dateien sind Referenzkopien; ihre Projektimporte setzen den vorhandenen
Pipeline-Checkout voraus. Keine AI-Annotationsfunktion aufrufen, nichts installieren.
Konfiguration und freigegebene Namen: tokenizer_linter_environment.json.
Voller Export-Linter: maximal 14 Wörter, maximal 1 untergeordneter Teilsatz.
Das frühere 20-Wörter-Limit für Storykontexte ersetzt dieses Exportlimit nicht.
Echte Projektfunktion nutzen, nicht nur spacy.blank('en'); Parserbindungen werden
für die Teilsatzzählung benötigt. Keine Modell-/Cloudaufrufe nötig.

IMPORTVORAUSSETZUNGEN FÜR DIE SPÄTERE LIEFERUNG
source: pipeline/out/reisen_batch_1_v1/pack.json; explizite Registry wie oben.
Neues Outputverzeichnis verwenden; Basispaket nicht überschreiben.
Reisen existiert bereits: keinen zweiten Deckdatensatz erzeugen.
combined_display_mapping.json zeigt die 200 Anzeigen nach Originalposition.
Die 100 bestehenden Reisen-Karten benötigen dabei eine Neupositionierung.
Der aktuelle Create-Importer hängt nur Zeilen an; ein unverändertes Append-Delta
kann diese bestehenden Anzeigen NICHT umsortieren. Vor Batch-2-Import ist dafür
eine gezielte, geprüfte Importanpassung nötig, die nur Reisen-Anzeigen verändert.
Diese Übergabe behauptet deshalb keinen sofort ausführbaren Batch-2-Import.
Weder alte deck_cards/deck_words duplizieren noch den Packvertrag 1..n umgehen.
Andere Stapel, Lernstände, IDs, Sätze und historische Links bleiben unverändert.

Keine Batch-2-Sätze in diesem ZIP. Keine Datenbanken, Lernstände oder Geheimnisse.
manifest.json bindet alle Austauschdateien an ihre Rohbyte-Hashes.
