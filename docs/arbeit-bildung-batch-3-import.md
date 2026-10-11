# Arbeit & Bildung – Batch 3: Abschlussimport
Stand: 10.10.2026. `arbeit_bildung_batch_3_v1`, Schema 3, offline importiert und intern gestagt.
81 neue Ziele; 81 Satzpaare, 915 Tokenpositionen (833 Wörter, 82 Satzzeichen) und vier Alternativen gegengelesen.
Keine belegte Lieferkorrektur; Original-Lieferung, Manifest, Review- und Displayhashes unverändert.
minutes=Sitzungsprotokoll, agreement=Einigkeit, training=berufliche Schulung, simple=einfacher Aufbau; Begleitwortbindungen geprüft.
Alternativen wörtlich geprüft: vacancy→job opening, eraser→rubber, practise→practice, academic→scholarly; accepted nur Zielform.
Keine unabhängige menschliche Sprachfreigabe behauptet; Alternativen bleiben lernstandsneutral.
1250 Karten, 1784 Satztexte, 1778 Verknüpfungen einschließlich Historie, 1146 Wortbesitzzeilen.
1135 primäre Lernziele: 160 Allgemeine Sprache / 489 Reisen / 241 Alltag & Zuhause / 245 Arbeit & Bildung.
Alle 245 Identitäten, Definitionen, Gruppen und Besitzbindungen exakt gegen Ursprungsauswahl/Referenz geprüft; je ein aktiver fester Satz.
Abschluss 245 importiert / 0 aktuell / 0 später; kein Restbatch und keine Batch-4-ZIP.
Alle 1169 alten Karten und Inhalte einschließlich front-Korrektur erhalten; ausschließlich erlaubte Arbeit-Anzeigepositionen verändert.
Mitgliedschaften 165–245 angehängt, hashgebundener Display-Patch auf 1–245; Originalpositionen unverändert.
Pack: `pipeline/out/arbeit_bildung_batch_3_v1/`; Pack-SHA256: `d170e0ca41784fae6e888043b53e53af6ba0e5288b79ad1f91fd3e9f0983b3ba`.
SQLite-/Asset-SHA256: `4239a32d45354539ce5aee74a61ec8ed7ac20d39902ff060f2a0bc94e1fcaa91` (9326592 Bytes).
Python 3.13.15: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/.venv-macos/bin/python`; Installation aus `pipeline[test]`, pip check erfolgreich; Windows-.venv erhalten.
Verifier, Import, Exportaudit aller 18 Tabellen gegen build_rows, Staging und --verify: Exit 0; keine Besitz-/Alias-/Identitäts-/Gruppenkonflikte.
Pipeline: `97 passed, 19 subtests passed in 7.73s`; Vierstapel-Lesetest: `All tests passed!`; Analyse: `No issues found!`; jeweils Exit 0.
Linter neue Sätze: 0 Fehler, 2 Hinweise: confidently 3,41 und learners/learner 3,48 unter Zipf 3,5; keine Umformulierungen.
Nachweise: `build/arbeit_batch_3_checks/` mit verifier/import/audit/pytest/stage/stage-verify/flutter-test/flutter-analyze.log, environment.txt und audit_export.py.
Abweichungen: Paketdownload und SDK-Cache erforderten Sandbox-Eskalation; erfolgreich. Auftragsspezifisches Audit zunächst TypeError bei Satzzeichen, anschließend korrekte Null-Sense-Prüfung; keine Inhaltsänderung.
Repositoryweites git diff --check: Exit 2 wegen bestehender CRLF-/Leerzeichenbefunde; CRLF-tolerant bleiben sieben Altbefunde in vier hashunveränderten Dateien. Eigene Änderungen separat geprüft.
Bestandsänderungen: Asset, Manifest, acht konkrete Testzeilen und NEXTSTEPS.md; neu: Export, dieser Bericht, lokale Mac-Umgebung und Prüfarbeitsordner. Sicherungen unter `build/arbeit_batch_3_checks/backup/`.
1505 von 1509 Ausgangsdateien byteidentisch; genau die vier autorisierten Bestandsdateien geändert. Original-Lieferung, historische Packs, Registry/Auswahl, App-/SRS-/Synonymlogik unverändert.
Keine echte user.db oder Lernstände geöffnet/geändert, keine Cloud-/Modellaufrufe, Veröffentlichung, Commits, Pushes oder Geräteprüfung. Offen: Geräteprüfung und bestehende Altbefunde; kein Importblocker.
