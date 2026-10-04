SPRACHAPP – SPRACHREDAKTION V1

Das ist eine Änderungsliste mit vollständigem Lesekorpus, kein fertiges App-Pack.
Das hochgeladene Original pack.json bleibt unverändert.

Dateien:
- review.html: im Browser öffnen; durchsuchbarer Vorher-/Nachher-Bericht über alle 792 Satzstellen.
- corrections.json: 190 Satzoperationen, 10 Metadatenoperationen, 2 Kartenempfehlungen; exakte Vorbedingungen und stabile Referenzen.
- reviewed_sentences.json: alle 792 geprüften Satzpaare; Original und redaktioneller Vorschlag.
- verify_editorial_patch.py: nur lesender Quellen-/Strukturtest, keine Installation.
- IMPORT_PROMPT.txt: vollständiger Auftrag zum kontrollierten Übernehmen im lokalen Projekt.
- validation.txt: tatsächlich ausgeführte lokale Prüfungen.

So geht es weiter:
1. ZIP entpacken und diesen Ordner im Projekt unter editorial_review ablegen.
2. review.html öffnen. Die Suche findet z. B. „so#auf_diese_weise“ oder „Geschenkbox“.
3. IMPORT_PROMPT.txt in Codex/Claude Code im Projekt ausführen lassen.
4. pack.json NICHT durch corrections.json oder reviewed_sentences.json ersetzen.

Die englischen Ersatzsätze sind fertig redigiert. Bei ihrer Übernahme müssen
Wortannotation, Formübersetzungen, IDs und Lücken konsistent aufgebaut werden.
Es gab in dieser Redaktion keine Cloud-/Vertex-Aufrufe. Kein altes QA-Urteil
wird als neue erfolgreiche Prüfung ausgegeben. Keine Änderung an user.db.
Die Kartenempfehlungen sind noch nicht umgesetzt.

Die 190 Satzänderungen umfassen Fehlerkorrekturen UND redaktionelle Verbesserungen.
596 Satzstellen sind beibehalten, 6 stehen bei den beiden Rückstellungsempfehlungen.
Die Wort-für-Wort-Lookup-Daten wurden nicht vollständig lektoriert.
