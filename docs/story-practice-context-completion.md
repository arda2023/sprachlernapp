# Story-Kontexte: Plan und laufende Abnahme

## Gesicherte Basis und Inventar vor Edit

Aktueller Pack context_quality_applied_v1, Schema 4; Manifest-SHA stimmt mit Asset überein. Basis und alle vorher veränderten Dateien unter build/story_contexts/baseline.json und baseline.patch gesichert. UI-Feedback, 40/30-Höhe, SRS, Reviews und fremde Dateien bleiben unberührt.

Echter read-only Dart-Resolver: 58 Tokens in The Open Pocket, sechs Sätze; 36 verfügbar, 14 lernbare Stellen ohne Freigabe, zwei Eigennamen Maya und sechs Satzzeichen. Vollständige IDs, UTF-16-Spannen, Senses, Bindungen und Meldungen: build/story_contexts/before.json. Keine zurückgestellte Identität in dieser Story. Vorhandene backpack/platform-Karten werden inzwischen korrekt wiederverwendet; die alten Berichte mit lokalem Neuanlegen sind historische Stände. Ablehnung der 14 Stellen: StoryLearningCandidate.validationProblem, fehlende contextApproved-Freigabe bei card==null. Keine belegte Retirementfilter-Regresssion.

## Konkreter Plan vor Implementierung

Bestehende Pfade per rg und Quelllektüre bestätigt: pipeline/scripts/import_editorial_patch.py (--targeted und export_offline), pipeline/src/sprachpipe/curate.py (apply_targeted_patch), pack.py (build_rows), export.py (export_sqlite), schema.py (22 Tabellen). Vorhandene Freigaben: sentences.qa_report.editorial_create.learning_contexts. Quelle pipeline/out/context_quality_applied_v1/pack.json; neuer exklusiver Output pipeline/out/story_contexts_v1/. Keine SQLite-Patches.

1. Dieselbe targeted-Schnittstelle um story_contexts ergänzen: exakte Story-/Satz-/Token-Preconditions, vollständige Annotation und Wörterbuchprüfung, konkrete Redaktion pro Ziel, höchstens 20 Wörter/1 Nebensatz weiter erhalten. Bereits vorhandene Ziele nicht umschreiben. Versionierte neue Lieferdatei pipeline/data/curation/story_contexts_v1.json.
2. Geprüfte Kontext-Snapshots unter zusätzlichem QA-Namensraum an bestehenden Storysätzen; kein Schemawechsel. Einzelsatz bevorzugt; zusammenhängende Nachbarsätze nur mit begründetem Bedarf, Ersatztext nur wenn der kurze Ausschnitt nicht geeignet ist. Snapshot wird im Importer aus geprüften Daten erzeugt, niemals als ungeprüftes QA-ok übernommen. Deterministische Kontextidentität, Quelltoken bleibt separat erhalten.
3. Domain StoryLearningCandidate bekommt optionalen geprüften Übungskontext. Exakte Identität bleibt Sprache/Form/Sense/Funktion des Originaltokens; sourceFingerprint umfasst zusätzlich Kontext. DriftContentRepository liest den Snapshot; DriftUserRepository speichert in der vorhandenen atomaren Transaktion Kontexttext/Offsets und ursprüngliche Story-/Satz-/Tokenherkunft. Kein neuer Store, keine Migration, keine Änderung von Reviewpersistenz/SRS.
4. Vorhandene Provider, Reader, Wortlisten-Navigation und PracticeItemResolver weiterverwenden. Retirement und Mehrdeutigkeit gehen vor Kontext. Fehlende Redaktion und bewusste Sperre behalten unterschiedliche Meldungen.
5. Vollinventar erneut durch echten Resolver/Add; isolierte Nutzerdateien für Neustart, identische Wiederholung/andere Quelle, Wortliste, Gemischt, ein Review. Synthetisch Unicode, Mehrwortziel, mehrfaches Vorkommen, ungültige Annotation/Freigabe. Gesamte Flutter-/Python-Gates und originaler 30s-Packtest. Alle Tabellen/Historien/Formmitgliedschaften vor Stage abgleichen, Assets sichern und sicheren Stageweg nutzen.

Gegenprüfung des Plans: Kontextwahl ist kein Teil der Lernidentität; bestehende lokale Karte gewinnt und behält ihren Kontext. Quelle und Übungsspanne sind getrennt, Codepoint→UTF-16 erfolgt genau einmal beim Lesen. Keine Alternativen aus anderen Sätzen/Gruppen übernehmen. Alte Packs ohne neuen QA-Namensraum bleiben kompatibel. Packwechsel wird vor Add über Fingerprint geprüft; Tombstones dürfen durch Kontext nicht umgangen werden.

GitNexus: Query wegen fehlendem FTS leer; Index aus voriger Aufgabe intern fehlerhaft. Impact StoryLearningCandidate MEDIUM (7 direkt/24 gesamt: Content/User/Resolver/Provider/Reader/Sheet), storyDocument LOW (resolveStoryWord direkt), apply_targeted_patch/resolveStoryWord/addStoryWord UNKNOWN. Direkte CLI-/Service-/Testreferenzen zusätzlich gelesen. Keine Nulltreffer-Entwarnung. Änderungen bleiben auf genannte Pfade plus neue Tests/Nachweise beschränkt.

## Redaktionelle Einzelfälle

Die 14 fehlenden Wortstellen ergeben 13 lokale Identitäten: She/she in Satz 2/6 ist dieselbe Identität. Die beiden puts-Senses bleiben getrennt. Keine neue globale Wortzahl. Eigennamen Maya (Sätze 1/5) und die sechs Punkte werden nicht freigegeben.

| Satz / Token | Ziel / Sense | Entscheidung und Begründung |
|---|---|---|
| 1 / 1 | arrives / arrive#ankommt | Original: open-pocket/s1 — arrives bezeichnet das Ankommen am Bahnhof, Präsens 3. Person; der vollständige Einzelsatz und die Übersetzung belegen genau arrive#ankommt. |
| 1 / 5 | early / early#frueh | Original: open-pocket/s1 — early bezeichnet den frühen Ankunftszeitpunkt, nicht frühere Lebensjahre; am Bahnhof früh ankommen ist als Einzelaufgabe verständlich. |
| 2 / 0 | She / she#sie | Original: open-pocket/s1, open-pocket/s2 — She ist das Subjektpronomen sie und verweist auf Maya im unmittelbar vorigen Satz; beide Sätze bilden den kurzen geprüften Kontext. |
| 2 / 1 | puts / put#stellt | Original: open-pocket/s2 — puts bedeutet hier stellt den Rucksack auf den Tisch, nicht steckt aus Satz 5. Handlung, Zielort und deutsche Übersetzung sind im Einzelsatz vollständig. |
| 3 / 2 | points / point#zeigt | Original: open-pocket/s3 — points bedeutet zeigt mit einer Geste auf das offene Fach; man und pocket stehen im Satz, nicht Punkte sammeln. |
| 3 / 3 | to / to#auf | Original: open-pocket/s3 — to ist die Richtungspräposition in points to und entspricht hier auf; keine Infinitivpartikel und keine Zielortbedeutung nach. |
| 3 / 5 | open / open#offen | Original: open-pocket/s3 — open beschreibt das nicht geschlossene Rucksackfach; Adjektiv, kein Verb öffnen. Einzelsatz und Übersetzung sind eindeutig. |
| 5 / 1 | puts / put#steckt | Original: open-pocket/s4, open-pocket/s5 — puts bedeutet hier steckt die Fahrkarte hinein. Der unmittelbar vorherige Fahrkartensatz klärt it/sie; andere Bedeutung als stellt in Satz 2. |
| 5 / 3 | safely / safely#sicher | Original: open-pocket/s4, open-pocket/s5 — safely bedeutet hier sicher/so dass die Fahrkarte nicht herausfällt. Satz 4 klärt den Bezug; keine Bedeutung gefahrlos reisen. |
| 5 / 4 | inside / inside#hinein | Original: open-pocket/s4, open-pocket/s5 — inside bedeutet hier hinein; Satz 4 klärt die zurückgesteckte Fahrkarte. Kein adjektivisches innerer. |
| 5 / 6 | thanks / thank#danken | Ersatz: Maya thanks the man. — thanks bezeichnet bedankt sich bei dem Mann, kein substantivischer Dank. Der Mann wird in Satz 3 eingeführt; drei Originalsätze überschreiten 20 Wörter. Der kurze Ersatzsatz macht die Handlung unabhängig von it/sie. |
| 6 / 0 | Then / then#danach | Ersatz: Maya arrives at the station. Then she walks to the platform. — Then bezeichnet die zeitliche Folge nach der Ankunft. Für den vollständigen ursprünglichen it-Bezug wären Sätze 4–6 mit 26 Wörtern nötig; der kurze Ersatz nennt Ankunft und anschließenden Weg. |
| 6 / 1 | she / she#sie | Ersatz: Maya arrives at the station. Then she walks to the platform. — she bezeichnet Maya als weibliches Subjekt. Der kurze Ersatz nennt Maya explizit und behält ihre anschließende Handlung, ohne unaufgelöstes it aus Satz 5. |
| 6 / 2 | walks / walk#geht-zu-fuss | Ersatz: Maya arrives at the station. Then she walks to the platform. — walks bezeichnet geht zu Fuß zum Bahnsteig, Präsens 3. Person. Der kurze Ersatz erhält genau diese Form/Bedeutung und macht den zeitlichen/personalen Bezug vollständig. |

Ersatzübersetzungen: „Maya bedankt sich bei dem Mann.“ und „Maya kommt am Bahnhof an. Dann geht sie zum Bahnsteig.“ Alle Einzelentscheidungen und vollständig annotierten Texte stehen in der versionierten Lieferung; keine freien KI-Aufrufe beim Tap. Keine Alternativen kopiert oder neu abgeleitet.

## Vollständiges Vorherinventar

Exakte Story-ID: `1fe9baf1b1a199b5bfb116e320a679b9`. Spannen sind UTF-16; die Lieferdatei verwendet Codepoints. Alle Realtexte liegen im BMP, synthetischer Emoji-Test deckt den Unterschied ab.

| Satz-ID / Token | Spanne | Oberfläche / Sense | Ausgangsbindung → Resolver | Ausgangsmeldung |
|---|---|---|---|---|
| `44b39ff345f2360308500786966a03bf` / 0 | [0,4) | Maya / maya#maya | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `44b39ff345f2360308500786966a03bf` / 1 | [5,12) | arrives / arrive#ankommt | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `44b39ff345f2360308500786966a03bf` / 2 | [13,15) | at / at#ort | eaf00558ad72608f9a7d1ad7f1899b79 → eaf00558ad72608f9a7d1ad7f1899b79 | verfügbar |
| `44b39ff345f2360308500786966a03bf` / 3 | [16,19) | the / the#bestimmter_artikel | d0980b611fd3e292e0dcdedf7c3d58b1 → d0980b611fd3e292e0dcdedf7c3d58b1 | verfügbar |
| `44b39ff345f2360308500786966a03bf` / 4 | [20,27) | station / station#bahnhof | f44ab874cc11564009cc1a2f754ae7a3 → f44ab874cc11564009cc1a2f754ae7a3 | verfügbar |
| `44b39ff345f2360308500786966a03bf` / 5 | [28,33) | early / early#frueh | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `44b39ff345f2360308500786966a03bf` / 6 | [33,34) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |
| `e545c372b421dff2f69f6c6c6f382462` / 0 | [0,3) | She / she#sie | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `e545c372b421dff2f69f6c6c6f382462` / 1 | [4,8) | puts / put#stellt | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `e545c372b421dff2f69f6c6c6f382462` / 2 | [9,12) | her / her#ihr_possessiv | c6f0a7e222aa7477f368428545fc5b4d → c6f0a7e222aa7477f368428545fc5b4d | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 3 | [13,21) | backpack / backpack#rucksack | — → 2a057122daf0d91c2335296703b66f6e | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 4 | [22,24) | on / on#auf | 352639235c92764f49c19d0fe464ba7e → 352639235c92764f49c19d0fe464ba7e | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 5 | [25,26) | a / a#ein | c5f36879ac1d89d23113aec9f32f32ba → c5f36879ac1d89d23113aec9f32f32ba | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 6 | [27,32) | table / table#tisch | 253982ff9b64b28ab49f9ef47e56b2ff → 253982ff9b64b28ab49f9ef47e56b2ff | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 7 | [33,35) | in / in#in_raeumlich | c02007a451a1b5e2f3bed287c846c212 → c02007a451a1b5e2f3bed287c846c212 | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 8 | [36,39) | the / the#bestimmter_artikel | d0980b611fd3e292e0dcdedf7c3d58b1 → d0980b611fd3e292e0dcdedf7c3d58b1 | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 9 | [40,44) | café / café#cafe | — → bf5445fbc08c6041c650166f24f5a6f4 | verfügbar |
| `e545c372b421dff2f69f6c6c6f382462` / 10 | [44,45) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 0 | [0,1) | A / a#ein | c5f36879ac1d89d23113aec9f32f32ba → c5f36879ac1d89d23113aec9f32f32ba | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 1 | [2,5) | man / man#mann | — → 07bf7cd843f5305d4b9326e97ba8606f | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 2 | [6,12) | points / point#zeigt | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 3 | [13,15) | to / to#auf | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 4 | [16,19) | the / the#bestimmter_artikel | d0980b611fd3e292e0dcdedf7c3d58b1 → d0980b611fd3e292e0dcdedf7c3d58b1 | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 5 | [20,24) | open / open#offen | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 6 | [25,31) | pocket / pocket#taschenfach | — → 7ebfa05c68973870d6f285bafcbe85f3 | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 7 | [32,34) | of / of#genitiv_besitz | e9633db20e856c02c7a48c74746cdb31 → e9633db20e856c02c7a48c74746cdb31 | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 8 | [35,38) | her / her#ihr_possessiv | c6f0a7e222aa7477f368428545fc5b4d → c6f0a7e222aa7477f368428545fc5b4d | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 9 | [39,47) | backpack / backpack#rucksack | — → 2a057122daf0d91c2335296703b66f6e | verfügbar |
| `fde52f7527b9430a9b5388d1a75b8e1b` / 10 | [47,48) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |
| `2509e1766e34a52d5b334053bfcb546c` / 0 | [0,3) | Her / her#ihr_possessiv | c6f0a7e222aa7477f368428545fc5b4d → c6f0a7e222aa7477f368428545fc5b4d | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 1 | [4,9) | train / train#zug | d0a8d9bc00ccffed5f69d58553dbba65 → d0a8d9bc00ccffed5f69d58553dbba65 | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 2 | [10,16) | ticket / ticket#fahrkarte | e4b05d00f7a0804f7f5e700cb1aea1cc → e4b05d00f7a0804f7f5e700cb1aea1cc | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 3 | [17,19) | is / be#sein_vollverb | b325798ce493fd8ad1968460d3a038ab → b325798ce493fd8ad1968460d3a038ab | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 4 | [20,25) | about / about#im_begriff | 4c1df047bfec531ec0211aa23731d2da → 4c1df047bfec531ec0211aa23731d2da | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 5 | [26,28) | to / to#infinitivpartikel | 8c4ff8b225bdf270519c5e557737aa74 → 8c4ff8b225bdf270519c5e557737aa74 | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 6 | [29,33) | fall / fall#fallen | — → f20a0dbef7e41dcd9ba4e01c7a78e941 | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 7 | [34,37) | out / out#hinaus | afbfe3a49f3493c1d30311e4718c872b → afbfe3a49f3493c1d30311e4718c872b | verfügbar |
| `2509e1766e34a52d5b334053bfcb546c` / 8 | [37,38) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |
| `9c8a0014817a5713e2b07bdad96192cb` / 0 | [0,4) | Maya / maya#maya | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `9c8a0014817a5713e2b07bdad96192cb` / 1 | [5,9) | puts / put#steckt | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `9c8a0014817a5713e2b07bdad96192cb` / 2 | [10,12) | it / it#es_ding | 083366a1da956c4c859d9474f969dc55 → 083366a1da956c4c859d9474f969dc55 | verfügbar |
| `9c8a0014817a5713e2b07bdad96192cb` / 3 | [13,19) | safely / safely#sicher | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `9c8a0014817a5713e2b07bdad96192cb` / 4 | [20,26) | inside / inside#hinein | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `9c8a0014817a5713e2b07bdad96192cb` / 5 | [27,30) | and / and#und | a20802b54e4c3489e763f4f701b144f2 → a20802b54e4c3489e763f4f701b144f2 | verfügbar |
| `9c8a0014817a5713e2b07bdad96192cb` / 6 | [31,37) | thanks / thank#danken | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `9c8a0014817a5713e2b07bdad96192cb` / 7 | [38,41) | the / the#bestimmter_artikel | d0980b611fd3e292e0dcdedf7c3d58b1 → d0980b611fd3e292e0dcdedf7c3d58b1 | verfügbar |
| `9c8a0014817a5713e2b07bdad96192cb` / 8 | [42,45) | man / man#mann | — → 07bf7cd843f5305d4b9326e97ba8606f | verfügbar |
| `9c8a0014817a5713e2b07bdad96192cb` / 9 | [45,46) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |
| `626a0b1e603b31e67f92fd0c210ab618` / 0 | [0,4) | Then / then#danach | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `626a0b1e603b31e67f92fd0c210ab618` / 1 | [5,8) | she / she#sie | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `626a0b1e603b31e67f92fd0c210ab618` / 2 | [9,14) | walks / walk#geht-zu-fuss | — → — | Für diese Bedeutung fehlt ein geprüfter Übungskontext. |
| `626a0b1e603b31e67f92fd0c210ab618` / 3 | [15,17) | to / to#nach_richtung | 9cbf63e6494fa806cd7c5d6a8c1ad60c → 9cbf63e6494fa806cd7c5d6a8c1ad60c | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 4 | [18,21) | the / the#bestimmter_artikel | d0980b611fd3e292e0dcdedf7c3d58b1 → d0980b611fd3e292e0dcdedf7c3d58b1 | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 5 | [22,30) | platform / platform#bahnsteig | — → 50319e70ff0290edc98958a74c2c38d9 | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 6 | [31,34) | for / for#fuer_zweck_empfaenger | 7834d8713b083f5b479d37fbbca21ae3 → 7834d8713b083f5b479d37fbbca21ae3 | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 7 | [35,38) | her / her#ihr_possessiv | c6f0a7e222aa7477f368428545fc5b4d → c6f0a7e222aa7477f368428545fc5b4d | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 8 | [39,44) | train / train#zug | d0a8d9bc00ccffed5f69d58553dbba65 → d0a8d9bc00ccffed5f69d58553dbba65 | verfügbar |
| `626a0b1e603b31e67f92fd0c210ab618` / 9 | [44,45) | . / — | — → — | Bedeutung oder Übersetzung ist nicht eindeutig belegt. |

## Abnahme und Nachherinventar

**Funktional abgeschlossen und intern gestagt:** `story_contexts_v1`, Schema 4, 26.173.440 Bytes. Asset-SHA-256 `ebe0063895e7d4dd7c6d0f93855102741fc95eef37485d0aeb76153420229351`. Keine Geräteinstallation oder öffentliche Sprachfreigabe.

Vollständige maschinenlesbare Belege: [vorher](evidence/story-practice-context-completion/before.json), [nachher](evidence/story-practice-context-completion/after.json), [alle 50 Add-Ergebnisse mit exakter Ziel-ID und Übung](evidence/story-practice-context-completion/add-results.json). Vorher 36/58 verfügbar, nachher **50/58**; alle 14 zuvor blockierten lernbaren Stellen geprüft und hinzufügbar. Die 14 Stellen ergeben 13 lokale Identitäten, weil She/she dieselbe Bedeutung/Form ist. Alle Formfunktionen im tatsächlichen Storybestand sind unklassifiziert (`null`); keine Funktion wird geraten. Mehrwortziele und Nicht-BMP-Zeichen fehlen im realen Bestand und werden ausdrücklich synthetisch geprüft.

Weiter gesperrt: Maya in Satz 1 und 5 (Eigenname, Meldung „Eigennamen sind hier keine Lernziele.“); die sechs Punkte (keine annotierte lernbare Einheit). Kein übriger geeigneter Eintrag offen. Das zurückgestellte `so#auf_diese_weise` kommt in dieser Story nicht vor; seine tatsächlichen Tombstones und synthetischen Story-/lokalen Sperrfälle bleiben unverändert geprüft. Fehlende Freigabe meldet weiterhin „Für diese Bedeutung fehlt ein geprüfter Übungskontext“, Retirement dagegen „Diese Bedeutung ist nicht mehr zum Lernen verfügbar“.

Neue Kontextdaten werden ausschließlich durch die neue Operation im vorhandenen `apply_targeted_patch` erzeugt. Der bestehende atomare Add speichert Original-Story-/Satz-ID und Tokenindex getrennt von Übungstext/-spanne. Neue geprüfte Kontext-IDs sind deterministische Hashes aus lokaler Karten-ID und Kontextfingerprint; vorhandene alte UUID-Kontexte bleiben erhalten. Ein geänderter Kontext verändert den Source-Fingerprint, nicht die Lernidentität. Bestehende Bindung gewinnt, und wiederholtes Add oder dieselbe Identität in einem zweiten Storysatz verändert weder gespeicherten Kontext noch Reviews. Keine Migration, zweite Architektur oder neue globale Karten.

Nachweis in temporären user.db-Dateien: station als vorhandenes Ziel, early als Einzelsatz, safely mit Satz 4+5, Then mit Ersatztext. Jeweils paralleles Add, Close/Neuöffnung, exakte Wortlisten-ID, identischer Satz/Lücke/Übersetzung, Gemischt-Auswahl bei ausreichendem Rest und ein Review auch nach doppeltem Commit desselben Durchgangs. Die bestehenden Tests decken Tagesrest, fällige Priorität, Deaktivierung/Reaktivierung und exakte UI-Navigation „In Wortliste ansehen“ ab. Neues Storywort bedeutet keine Zusage einer unmittelbar nächsten Übung. Zweimal she aus Satz 2/6 behält explizit den zuerst gespeicherten Kontext. Synthetischer Mehrwort-/Emoji-/Mehrfachvorkommen-Test verwendet die zweite Tokenstelle, speichert/reöffnet sie und prüft vollständige Tokens; keine sprachliche Freigabe dieses Testtexts. Bestehender SQL-Reader-Test prüft Codepoint→UTF-16 nach Emoji. Fehlende Freigabe, unvollständiger Kontext und Retirement bleiben gesperrt; alte Bindungen/Reviews bei Packwechsel bleiben durch targeted_curation-Tests geschützt.

## Inhaltsschutz und technische Lieferung

[Audit](evidence/story-practice-context-completion/audit.py) und [Ergebnis](evidence/story-practice-context-completion/audit-result.json): alle **22 Tabellen** gegen `build_rows` vollständig abgeglichen; identische ID-Mengen und Altinhalte. Nur `qa_report` von fünf Storysätzen und Release-Metadaten ändern sich. 3.768 Karten insgesamt / 3.767 aktive Karten, 402 Formmitgliedschaften, 530 historische Links sowie dieselben 137 älteren Provenienzlücken bleiben erhalten. Beide partiellen Performanceindizes vorhanden. Keine globalen Wörter aus lokalen Karten erzeugt; keine neue Historienlücke. Alle historischen Reader wurden in der Gesamtsuite erneut ausgeführt.

Vor Stage: sämtliche Anfangshashes geprüft, Asset und Manifest nach `build/story_contexts/prestage-backup/` kopiert und Kopien hashverifiziert. [Hashnachweis](evidence/story-practice-context-completion/hashes.json) dokumentiert die Basis und den Stand vor der abschließenden NEXTSTEPS-Aktualisierung. Alle ursprünglichen UI-Dateien/Tests inklusive 40/30-Höhe und Padding, Quellpack, devtools_options.yaml und originaler Packtest byteidentisch. Kein SRS-/Review-/Synonymcode geändert; keine reale user.db geöffnet. Alter Export und Quellen unverändert. Zwei frühe eigene Exportfassungen mit noch fehlendem Gap-Bericht sind unter build/story_contexts/ erhalten; der finale exklusive Output wurde danach über denselben Importer neu erzeugt und geprüft, nicht per SQLite nachbearbeitet.

Geänderte eigene Pfade: `lib/domain/story_learning.dart`, `lib/data/content/drift_content_repository.dart`, `lib/data/user/drift_user_repository.dart`; `pipeline/src/sprachpipe/curate.py`, `pipeline/scripts/import_editorial_patch.py`, `pipeline/data/curation/story_contexts_v1.json`, `pipeline/tests/test_story_contexts.py`; `test/story_context_inventory_test.dart`, `test/story_context_completion_test.dart`, `test/story_context_synthetic_test.dart`; dieser Bericht, `docs/schema4-targeted-curation.md` und `docs/evidence/story-practice-context-completion/`. NEXTSTEPS wird lokal aktualisiert und wegen seiner Altanteile nicht committed. Assets/Export bleiben gemäß bestehender Repo-Regel ignoriertes internes Material.

## Tatsächliche Abschlussbefehle

Ab Repository-Root. Flutter-/Dart-/Git-Befehle identisch in macOS Terminal und Windows PowerShell. Python ausgeführt auf macOS als `pipeline/.venv-macos/bin/python`; Windows verwendet `.\pipeline\.venv\Scripts\python.exe` mit denselben Argumenten, nicht hier ausgeführt. Rohlogs/Argumente/Exitcodes: `build/story_contexts/`, kompakte Belege in `checks.json`.

| Befehl | Tatsächlicher Output | Exit |
|---|---|---:|
| `pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/context_quality_applied_v1/pack.json --targeted pipeline/data/curation/story_contexts_v1.json --out pipeline/out/story_contexts_v1` | status ok, 22 Tabellen, ai_calls 0; nur 2 Eigennamen im Authoring-Bericht | 0 |
| `pipeline/.venv-macos/bin/python docs/evidence/story-practice-context-completion/audit.py` | status passed, 402 Formmitgliedschaften, 530 Links, 137 unveränderte Alt-Lücken | 0 |
| `flutter test --no-pub test/story_learning_flow_test.dart test/story_target_navigation_test.dart test/data/targeted_curation_test.dart` | `00:10 +14: All tests passed!` | 0 |
| Vorige drei Testdateien plus `test/story_context_completion_test.dart test/story_context_synthetic_test.dart` | `00:39 +26: All tests passed!` | 0 |
| `pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q` | `496 passed, 19 subtests passed in 89.32s` | 0 |
| `flutter test --no-pub` | `01:33 +322: All tests passed!`, Nachherinventar 50/58 | 0 |
| `flutter test --no-pub test/data/real_pack_test.dart` | `00:09 +1: All tests passed!`; ursprüngliches 30s-Limit unverändert | 0 |
| `flutter analyze --no-pub` | `No issues found! (ran in 4.5s)` | 0 |
| `dart run tool/stage_content_pack.dart --from pipeline/out/story_contexts_v1` | staged; story_contexts_v1; Schema 4; 22 table counts match | 0 |

Entwicklungsbefunde: erster Import wegen fehlendem Python-Import `form_norm` abgebrochen; Import ergänzt, kein Output gestagt. Drei Analysehinweise (zwei if-Klammern, Test-Print) korrigiert. Gap-Bericht zunächst versehentlich an einer anderen gleichnamigen Report-Zuweisung ergänzt, bei direkter Diffprüfung sofort entfernt und ausschließlich in `export_offline` platziert. Keine Testassertion gelockert oder Timeout erhöht. Alle finalen Gates oben sind tatsächlich ausgeführt.

## Manuell nachvollziehen

In einem separaten Testprofil mit diesem internen Pack **The Open Pocket / Die offene Tasche** öffnen. In Satz 1 „Maya arrives at the station early.“ **early** antippen → „Zum Lernen hinzufügen“ → gespeicherte Bestätigung abwarten → „In Wortliste ansehen“. Exakte Ziel-ID: `u:d9e229d4a9a3068092def7f260283cc3a51976b5f01dc086a821cef1d9dfc0f7`. Erwartete Übung: „Maya arrives at the station [early].“, Übersetzung „Maya kommt früh am Bahnhof an.“; nur early ist die Lücke. Nach Neustart dieselbe Karte, wiederholtes Add keine Dublette. Gemischt berücksichtigt Tagesrest und zuerst fällige Reviews; deshalb keine feste nächste Position zugesagt.

Zusatzkontext kontrollieren: **safely** in Satz 5, Übung aus „Her train ticket is about to fall out. Maya puts it safely inside and thanks the man.“ mit genau einer Lücke bei safely. Ersatz kontrollieren: **Then** in Satz 6, Übung „Maya arrives at the station. Then she walks to the platform.“ mit Lücke bei Then. Keine Geräteprüfung behauptet.

## Abschließendes Commit-Gate

`dart run tool/stage_content_pack.dart --verify`: **verified**, story_contexts_v1, Schema 4, 26.173.440 Bytes, SHA wie oben, 22 Tabellen stimmen, **Exit 0**. Keine offenen technischen Pending-Schritte für die 14 freigegebenen Stellen.

Finaler GitNexus-PDG-Reindex erfolgreich: **84.595 Knoten, 259.479 Kanten, 392 Flows**, 35,9s, Exit 0. Anders als im früheren fehlerhaften Indexlauf sind FTS und Strukturzählung wieder vorhanden. Globale Abdeckungsgrenzen bleiben: begrenzte Prozesseinstiege/Callees sowie Dart-Interface-/Sprachgrenzen. `detect_changes(scope=all)` liefert **75/75 Symbole, 11 Prozesse, 27 Dateien**, Risiko **HIGH**, ohne partial/truncated. Der Umfang enthält die ausdrücklich nicht vorgemerkten UI-/NEXTSTEPS-Altänderungen. [Vollständiger Graphbefund](evidence/story-practice-context-completion/graph-check.json).

Die elf Prozesse führen vom gezielten Import über bestehende Normalisierung, Registry-Digest, Referenz-, Gruppen-, Tombstone-, Spalten- und Satzanzahlprüfung. Context-Abfragen und direkte Diffs bestätigen: keine Änderung an diesen gemeinsamen Validatoren; nur der neue story_contexts-Zweig und ein lesender Exportbericht. Vor Änderung des gemeinsamen Exporters wurde dessen CRITICAL-Risiko (20 direkt/46 insgesamt) ausdrücklich gemeldet. Alle bestehenden Create-/Form-/Targeted-Importtests liefen in der vollständigen Python-Suite mit. HIGH/CRITICAL wird nicht durch einen niedrigeren Teilwert oder Nulltreffer weginterpretiert.

Vorgemerkte Dateiliste enthält ausschließlich die eigenen Storykontext-Dateien; kein UI-Altanteil, NEXTSTEPS oder fremdes Verzeichnis. CRLF-bewusster `git diff --cached --check` ohne Ausgabe, Exit 0; dieselbe Prüfung nur für die eigenen Arbeitskopiepfade ohne Befund. Kein persistentes Git-Setting, keine globale Formatierung. Commit auf `codex/story-contexts-v1`, kein Push.

Die automatische Freigabeprüfung lehnte ein vollständiges Überschreiben von NEXTSTEPS wegen seiner uncommitteten Altanteile ab. Sichere Alternative ausgeführt: gezielte Ergänzungen in bestehenden Zeilen, alle alten Fakten erhalten, weiterhin 25 Zeilen und nicht vorgemerkt. Kein verbleibender Freigabeblocker.
