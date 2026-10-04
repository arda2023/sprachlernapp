# Status / nächste Schritte
Stand: 04.10.2026
Paket A/B lokal umgesetzt; Abnahme in docs/decks-and-story-learning-plan.md, Abschnitte 10/11.
Aktives internes Pack unverändert: story_learning_v1, Content-Schema 2.
Asset-SHA256: b8231bbc7d1fe834b13ee81b901ad2d96dc06ac3dfbcdf72422718a68bb5e59b.
264 Karten/160 Primärwörter, 798 Sätze, 8532 Token; eine Story mit 6 Sätzen.
User-Schema 4; vorhandene 20 Kartenstände/19 Reviews bei Paket B erhalten.
Paket-A/B-Prüfstand: Python 345/Flutter 235 bestanden; analyze ohne Befund; iOS nicht ausgeführt.
Story-Lernen: lokale Box-0-Karten in Wortliste/Gemischt; Besitzauflösung nach stabilen IDs.
Weitere Story-Lernkontexte benötigen konkrete redaktionelle Freigabe; Kontextwahl/Sync fehlen.
Reisen-Auswahl: pipeline/data/selection/reisen_500_v1.json; 500 unveränderte Ziele, 5 Batches à 100.
Bedeutungen: 144 bestehende, 356 neue Vorschläge, 0 offene Bindungen; 141 Bestandssenses ohne Definition.
Registry: pipeline/data/words/en.reisen_500_v1.json; 160 Bestandswörter + 500 Reservierungen.
Registry-SHA256: 888632469bbf306e85bbe42de93082362af24a37be84f6a3c82e2258581d3a90.
Null Besitz-/Aliaskonflikte; 8 Schreibaliase, keine automatische Antwortfreigabe.
Import muss neue Registry explizit angeben; CLI-Standard en.v1.json unverändert.
Backpack/Rucksack- und Platform/Bahnsteig-Storyidentitäten erhalten.
Altbestand: cough/NOUN ist in einem Verbkontext falsch annotiert; dokumentiert, nicht verändert.
Auswahl-/Registry-/Packvalidatoren bestanden; bestehende Create-Fixture lokal validiert.
Austausch: build/reisen_authoring_v1.zip; Kontext, Schema, Fixture, Wörterbuch, Anleitung, Prüfergebnisse.
Bericht: docs/reisen-500-authoring.md; keine Reisesätze erzeugt oder Reisen-Karten exportiert.
Nächster Schritt: 100 Sätze für authoring_batch=1 im Chat redigieren und als Create-v2-Delta liefern.
Danach gegen konkrete Pack-/Registry-Hashes prüfen; noch kein Import oder Packwechsel erfolgt.
Keine Cloud-/Modellaufrufe, DB-Schreibzugriffe, Installation, Commits oder Pushes in dieser Vorbereitung.
