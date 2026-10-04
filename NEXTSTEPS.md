# Status / nächste Schritte
Stand: 04.10.2026
Reisen Batch 1 vollständig offline importiert, exportiert und intern gestagt.
Packversion reisen_batch_1_v1, Schema 2; kein öffentliches Release.
Genau immigration (030) und ask (401) durch freigegebene Sätze ersetzt.
stop ist NOUN/Haltestelle; andere 98 Satzpaare und 15 Alternativen unverändert.
Neue Lieferung: 134 Lemmas, 147 Senses, 182 Formglossen, 1040 Tokens.
Originalauswahl/-Registry unverändert; Reisen-Anzeigen dicht 1–100.
Übergabe-Validator Exit 0, vollständiger Exportlinter 0 Fehler / 163 Warnbefunde.
SQLite: integrity_check ok, foreign_key_check leer, alle 18 Tabellen abgeglichen.
Bestand erhalten; Exportzeitstempel separat validiert, neuer Release-Deskriptor.
364 Karten, 898 Satztexte, 892 Satzlinks, 260 Primärwörter.
Reisen: 100 aktive Karten mit je einem festen Satz; Allgemein: 160 Primärkarten.
Assetsicherung bytegleich zur Baseline: build/reisen_batch_1_checks/asset_rollback/.
Staging, --verify und test/data/real_pack_test.dart jeweils Exit 0.
SQLite SHA256: fd0962fe5b4958338fe46f1101db520f69b5e5c7f101762b1bdade1cef847678
Bericht und Prüfoutputs: docs/reisen-batch-1-import.md.
Batch-2-Übergabe: build/reisen_authoring_batch_2.zip, 13 Dateien, Hashes/CRC geprüft.
Registryrevision: pipeline/data/words/en.reisen_batch_2_v1.json; 660 Wortzeilen erhalten.
Batch 2: exakt 100 Ziele, 35 vorhandene / 65 vorgeschlagene neue Senses.
Sieben inzwischen vorhandene Begleitwort-Senses gebunden; keine Batch-2-Sätze erzeugt.
Nächster Schritt: Batch 2 redigieren und gezielte Reisen-Neupositionierung beim Import vorbereiten.
Create-Importer unterstützt das Umordnen bestehender Anzeigen bisher nicht.
Keine Cloud-Aufrufe, Modellwechsel, user.db-Zugriffe, Emulatorläufe, Commits oder Pushes.
