# NEXTSTEPS
Stand: 11.10.2026 – Alltagssprache Batch 2 intern gestagt; Batch-3-ZIP geprüft. Paket 2 lokal implementiert: docs/content-editor-package-2.md; Python 542+19, Flutter 330, Browser-250/ZIP/XLSX/Story/Tempstage geprüft; Produktionsasset und fremde UI unverändert; Windows-Geräteabnahme offen, Paket 3 nicht begonnen.
## Erledigt
- 89 Batch-2-Ziele importiert: 89 Satzpaare, 889 Tokens (742 Wörter/Ausdrücke), zwei Alternativen.
- Alltagssprache: 178 Ziele, Anzeigen 1–178; Original-/Besitzpositionen unverändert.
- Pack: pipeline/out/alltagssprache_redewendungen_batch_2_v1/, Schema 4, zwölf Stapel, 2745 Karten.
- Produktive Projektion: 2631 Übungen / 2360 Wörter; 402 Formen/je 134 Verbenübungen erhalten.
- Assets/Manifest vor Staging unter build/alltagssprache_batch_2_checks/backup/ bytegleich gesichert.
- Intern gestagt; Asset-Verifier und echter Zwölfstapel-Lesetest PASS, Exit 0.
- Auswahl v2: 441 Ziele; Batch-3-Partition 178 importiert / 88 aktuell / 175 später.
## Dateien und Prüfungen
- Bericht: docs/alltagssprache-redewendungen-batch-2-import.md; NEXTSTEPS aktualisiert.
- test/data/real_pack_test.dart um diese Version und 178 Ziele erweitert.
- Batch-3-Kontexte: selection/words/learning_groups, *_batch_3_context_v2.json.
- ZIP: build/alltagssprache_redewendungen_authoring_batch_3.zip; checks im Batch-2-Ordner.
- 447 Pipeline-Tests plus 19 Subtests PASS; Flutter-Analyse ohne Befund; Exit 0.
- Vollständiger 22-Tabellen-/Bestandsabgleich und Anzeigenprüfung PASS.
- ZIP geschlossen/erneut geprüft: CRCs, 83 Dateihashes, Referenzen, 441 Identitäten PASS.
## Abweichungen und offen
- Importkopie: vier Tokenbindungen korrigiert (high-Betrag, cancelled zweimal, made-Zustand).
- Ein neuer Wörterbuchsense/eine Form; Zielkarten, Sätze, learning und Alternativen unverändert.
- Linter 0 Fehler/465 Hinweise; neu unfairly 3,36 und unfriendly 3,10 unter 3,5.
- Sechs geerbte Formglossen sowie frühere Listen offen; Original-Lieferung erhalten.
- Nächste Aktion: geprüfte ZIP hochladen und 88 Batch-3-Ziele im Chat redigieren.
- Kein Commit: uncommittete Schema-4-/450-/V3-Abhängigkeiten und gemischte Hunks; Index leer.
