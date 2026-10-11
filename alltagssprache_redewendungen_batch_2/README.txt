Alltagssprache & Redewendungen – Batch 2
89 Satzpaare für genau die 89 aktuellen Ziele; Gesamtumfang der Auswahl 441.
Ausgangspartition 89 importiert / 89 aktuell / 263 später.
Format sprachapp.editorial-content v2 auf Content-Schema 4.
Vorgesehene lokale Ausgabe: alltagssprache_redewendungen_batch_2_v1.

Einstieg: IMPORT_PROMPT.txt. Lieferung vollständig entpacken; Original behalten.
Basis: alltagssprache_redewendungen_batch_1_v1, ausdrücklich KEIN alter Verbenpack.
editorial_content_v2.json + deck_display_patch.json + reference/registry.json gehören zusammen.
Neue Mitgliedschaften zunächst 90–178 anhängen; der hashgebundene Display-Patch
ordnet ausschließlich die beiden Positionsspalten dieses Stapels neu auf 1–178.
Original-Auswahlpositionen, Registry, bestehende Identitäten und Formtabellen bleiben erhalten.

89 Satzpaare, 889 Tokenpositionen, davon 742 Wort-/Ausdruckstokens und 147 Satzzeichen.
2 Alternativen: no offence → no offense; if memory serves → if memory serves me.
Beide wurden wörtlich eingesetzt und mit 441 Zielen sowie Besitz/Aliasdaten abgeglichen.
Keine automatische Antwortfreigabe durch Gruppen oder Aliase.
Das ausgeschlossene zukünftige Ziel in my opinion bleibt ausgeschlossen;
die bestätigte Alternative im bestehenden to-my-mind-Satz bleibt bytegleich erhalten.
accepted enthält exakt die jeweilige card.form; Großschreibung von I erhalten.
Mehrwortlücken werden als ein lexical_span tokenisiert.

121 neue Sense-Zeilen und 138 Formübersetzungen, nur additive Wörterbucherweiterungen.
Alle neuen Formglossen ausdrücklich geprüft; keine offenen Token-/Glossenzuordnungen.
Sechs konkrete geerbte Formglossen-Befunde separat in inherited_gloss_comparison.json.
Keine gemeinsamen Altglossen geändert und keine früheren Befundlisten geschlossen.

Offline nachgewiesen: 83 Eingangsdateihashes, Source-SQLite-Abgleich aller 22 Tabellen,
Schema, Identitäten, Tokenisierung, Reviewhashes, Registry, build_rows,
Display-Patch und exakte create_content-Quellfunktion im Speicher bestanden.
Für die Funktionsprüfung wurden unveränderte reine Funktionen per AST geladen;
keine Modell-Clients, kein Aufruf der Produktions-CLI und kein Dateiexport daraus.
Quell-SQLite-Vergleich: exportgeneriertes content_releases.created_at nur auf Präsenz geprüft.
Linter: 0 Fehler; 2 Häufigkeitshinweise: unfairly 3,36 und unfriendly 3,10 (Grenze 3,5).
Satzentwürfe vor Lieferung sprachlich und bei Teilsatzüberschreitung angepasst;
Lintergrenzen unverändert. Ursprüngliche ZIP und Produktionsdateien unangetastet.

Keine Cloud-/Modell-API-Aufrufe, kein Produktionsimport oder Staging,
keine Flutter- oder Geräteprüfung. Die spätere lokale Importprüfung bleibt erforderlich.
Diese ChatGPT-Erstellung/Eigenprüfung ist keine unabhängige menschliche Sprachfreigabe.
Die Scripts unter authoring_evidence sind nachvollziehbare Entstehungsbelege,
keine neuen Produktionswerkzeuge; sie benötigen die originale Authoring-ZIP als Kontext.
