# Verbalphrasen: Batch 2 und vollständiger interner Abschluss

Stand: **13.10.2026**. Die letzten **90 Ziele offline importiert und als `verbalphrasen_batch_2_v1` intern gestagt**. Vollständiger Abschluss **181/181**, Partition **181 importiert / 0 aktuell / 0 später**, Anzeigen **1–181**, **13 Stapel / 3189 Karten**. Tatsächliche App-Projektion **3075 Übungen / 2804 lexikalische Wörter**. Keine Batch-3-ZIP und keine Business-Auswahl. Technische interne Abnahme ist keine öffentliche Sprach- oder Gerätefreigabe.

## Tatsächliche Dateien und Verträge

AGENTS/CLAUDE, NEXTSTEPS, Roadmap, Verbalphrasen-Auswahlbericht und Batch-1-Abschluss, normale Schema-4-Kompatibilität, Content-/Lerngruppenregeln sowie tatsächliche V2- und Display-Verträge geprüft. Bestehender `import_editorial_patch.py --create --registry --display-patch` auf Schema 4. Keine neue Pipeline, Code-/Test-/Schemaänderung, Paketinstallation oder Indexneubau. Benötigte Implementierung bereits auf HEAD; die historische Commit-Blockerbeschreibung im Kompatibilitätsbericht ist kein aktueller Codeblocker.

- Original-ZIP: `/Users/ardasayar/Downloads/verbalphrasen_batch_2_lieferung.zip`.
- Tatsächlich vorhandener entpackter Ordner: `verbalphrasen_batch_2 2/`; dessen Name wurde nicht verändert. **34 ZIP-Dateien / 33 Liefermanifesthashes**, CRCs und alle entpackten Bytes geprüft. Referenzsubset bytegleich zur geprüften Batch-2-Authoring-ZIP.
- Originalauswahl: `pipeline/data/selection/verbalphrasen_v1.json`; vollständiger Importkontext `pipeline/data/selection/verbalphrasen_batch_2_context_v1.json`.
- Import-Registry: `pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json`.
- Historischer Batch-2-Gruppenkontext: `pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json` (3099 bestehende Kartenentscheidungen / 90 damals reservierte); finaler Gruppenbestand wird aus **3189 `cards.learning`-Entscheidungen / 3177 Gruppen** des tatsächlichen Abschluss-Packs geprüft. Keine neue Gruppen-/Registrydatei erfunden.
- Basis: `pipeline/out/verbalphrasen_batch_1_v1/{pack.json,content.sqlite}`.
- Ausgabe: `pipeline/out/verbalphrasen_batch_2_v1/{pack.json,content.sqlite,finalization_report.json}`.
- Internes Asset/Manifest: `assets/content/en/{content.sqlite,content.manifest.json}`.
- Neue Dokumentation: dieser Bericht; Roadmap/NEXTSTEPS auf tatsächlichen Abschluss fortgeschrieben.
- Prüfausgaben und Sicherung: `build/verbalphrasen_batch_2_checks/`, insbesondere `backup/`.

Keine Korrekturkopie erforderlich: **Original Create-Datei und Original Display-Patch unverändert verwendet**. Lieferskripte unter authoring_evidence wurden nicht ausgeführt; die gelieferte In-Memory-Prüfung ersetzt nicht den lokalen CLI-Import, Export, Tests und App-Lesetest.

## Lieferung, Bedeutungen und komplette Tokenprüfung

Basis exakt Version `verbalphrasen_batch_1_v1`, Schema 4. Basis-JSON-/SQLite-, Registry- und Gruppendigest stimmen mit dem Auftrag überein. Rohbytehashes von Create und Display-Patch unabhängig gegen Liefermanifest nachgerechnet; Create zusätzlich gegen validation_report und Patchbindung. Keine stille Umbasierung.

Vor Import **181 Gesamtziele / 91 vorhanden / 90 aktuell / 0 später**. Alle 123 ausgeschlossenen Kandidaten bleiben ausgeschlossen; keine Auffüllung auf 200. Originaldefinitionen, Form-/Sense-/Karten-IDs, `cards.learning`, Besitz-/Gruppenbindungen und ursprüngliche Positionen exakt erhalten.

Alle **90 englisch-deutschen Satzpaare und 927 Tokenpositionen** vollständig gegengelesen, davon **816 Wort-/Ausdruckstokens / 111 Satzzeichen**. Offsets, lexikalische Spannen, vollständige Tokenabdeckung, Wörterbuchschlüssel und exakte Token-/Link-/Reviewhashes mit vorhandenen Funktionen geprüft. Ganze Zielform als zusammenhängende Lücke und ein lexical_span-Token, `accepted` exakt `[card.form]`. Keine getrennte Antwortkonstruktion und keine Ersatzsätze.

Besonders geprüft: go off = Lebensmittel verderben; pay for = negative Folgen eines Fehlers tragen; sort out = aussortieren; put down = verbal herabsetzen; see through = Täuschung durchschauen; pick up = mit dem Fahrzeug abholen. Kein Umdeuten zu Alarm, Geldzahlung, bloßem Sortieren, Ablegen, räumlichem Durchsehen oder Aufheben.

Begleitbindungen: cold bei come down with = Erkältung/NOUN, bei button up = kalt/ADJ; leaves bei blend in = Blätter, bei fade away = Abfahren des Zuges; speaker = sprechende Person, credit = Telefonguthaben, coach = Trainer. each/other im Stand-up-for-Satz reziprok als PRON gebunden. after bei pick up SCONJ; should bei blow over/turn out Erwartung, keine Pflicht. Die feste Definition des wiederverwendeten cool-Sense lautet An Temperatur verlieren; der intransitive Suppe-Satz passt dazu, obwohl der Authoring-Hinweis einen Körperkontext nahelegte. Keine Bedeutungs- oder Identitätsänderung.

Wörterbuchzusätze: **81 neue ausgewählte Ziel-Senses / 9 vorhandene Ziel-Senses wiederverwendet / 35 neue Begleit-Senses**, zusammen **116 neue Senses**, **141 neue Formglossen**, aber nur **90 neue Karten**. Über beide Batches insgesamt 20 vorhandene Zielbedeutungen wiederverwendet und 161 ausgewählte Bedeutungsvorschläge umgesetzt; Begleitwörter sind keine zusätzlichen Lernkarten.

Drei wörtlich geprüfte Satzersetzungen und Begründungen aus alternative_review.json: **get around to → get round to**, **doze off → nod off**, **turn off → switch off**. Keine Kollision mit 181 Auswahlzielen, aktiven/historischen Karten, Reservierungen, Besitzaliasen, vorhandenen Alternativen oder Gruppen. Keine automatische Freigabe aus Gruppen-/Aliaszugehörigkeit. Alle sechs Verbalphrasen-Alternativen beider Batches bleiben satzgebunden und lernstandsneutral.

## Vollständiger Abschluss und Bestandsschutz

`completion-181.json` und `identities-181.json` belegen alle **181 Identitäten / Definitionen / Gruppen / Besitzer / festen aktiven Sätze** gegen die unveränderte Gesamtauswahl. Genau ein aktiver Satz auf Position 1 je Karte, exakte Ziellücke, passende Sense-Bindung und komplette Reviewhashes. Anzeigeinventar 1–181, keine Lücke oder Dublette. **Partition 181/0/0**, keine offene Verbalphrasen-Reservierung als Satzauftrag. Die obsolete ungenutzte in-my-opinion-Reservierung außerhalb des Stapels bleibt als Altbestand erhalten: **2979 Registryzeilen / 2978 aktive Besitzer**, keine künstliche Gleichsetzung.

Hashgebundener Display-Patch über Source-/Create-/Registry-Digest und vollständige Vorherhashes beider Mitgliedschaftstabellen angewendet. **90 Anhänge 92–181**, anschließend Prüfung der gemeinsamen **181-zeiligen Originalreihenfolge**. Die vorherigen 91 Anzeigen entsprechen bereits den Originalpositionen: **0 bestehende Positionswerte geändert**. Keine Änderung fremder Stapel, Registry-/Auswahlpositionen, Karten-IDs oder Satzbindungen.

Alle **22 SQLite-Tabellen** erneut vollständig zeilen-/spaltenweise mit `build_rows` / `finalize_curation.check_sqlite` abgeglichen. Exportgenerierter `content_releases.created_at` gemäß bestehendem Vertrag auf Vorhandensein statt exakten Wert geprüft. Alle alten JSON-Listen als Präfixe und alle alten SQL-Zeilenwerte erhalten, außer autorisierter Release-/Registry-Fortschreibung. Die autorisierte Displayänderung wäre allein auf Positionen dieses Stapels begrenzt; tatsächlich keine alten Positionswerte verändert. Alle früheren gezielten Importkorrekturen in der Quelle erhalten.

Vier Schema-4-Formtabellen mit exakt gleichen Zeilenwerten: **134 lexikalische Verbanker / 402 Formziele / 134 Übungen je Verbenansicht**, auch alle 406 Kartenanker-Zuordnungen unverändert. Alle 13 Stapel erhalten. Tatsächliche App-Projektion via vorhandenem `tool/report_learning_groups.dart`: **3075 Übungen / 2804 Wörter**, Verbalphrasen **181**, Formmitgliedschaften **402**. Karten, Besitzer, Lernköpfe, Übungen und lexikalische Wörter werden nicht gleichgesetzt.

Die beiden Batch-1-Formglossen zwingend und exakt als ganze Wörterbuchzeilen erhalten:

| Form / Sense | Erhaltene Formglosse |
|---|---|
| pick out / pick out/VERB&#124;pick-out#wiedererkennen | aus einer Menge erkennen |
| pull over / pull over/VERB&#124;pull-over#rechts-ranfahren | an den Straßenrand fahren und anhalten |

Die bereits in der Auswahl enthaltenen Karten-/Sense-Labels wiedererkennen und rechts ranfahren bleiben unverändert und als zwei separate Auswahlglossenbefunde offen. Keine alte Glosse global geändert, keine künstlichen Senses zur Umgehung einer gemeinsamen Formglosse angelegt.

Linter **0 Fehler / 476 Hinweise**: **475 unveränderte Altbefunde**, genau ein neuer erwarteter Hinweis **unfairly Zipf 3,36 < 3,5** beim stand-up-for-Satz. Nicht umformuliert, um Warnungen zu unterdrücken. Die 14 neuen Kontextvergleiche ergänzen die zwölf Batch-1-Vergleiche und ältere Listen; keine Liste ersetzt die anderen.

## Sicherung, Staging und reale App-Abnahme

**Vor Staging**, nach erfolgreichem CLI-Import/22-Tabellen-Abgleich und Testsuite, bytegleich gesichert:

- `build/verbalphrasen_batch_2_checks/backup/content.sqlite`
- `build/verbalphrasen_batch_2_checks/backup/content.manifest.json`
- Nachweis `backup/hashes.json`, verified_before_staging true, jeweilige Hashgleichheit zur Ausgangslage.

Erst danach mit vorhandenem Staging-Werkzeug intern ersetzt und `--verify` bestanden. Neues internes Asset bytegleich zur neuen Source-SQLite. Der unveränderte echte Pack-Lesetest aus dem letzten Bericht liest das dynamische gesamte Inventar; 13 Stapel und 3189 feste Satzzuordnungen bestanden. Keine Teständerung erforderlich, keine echte user.db geöffnet/kopiert/migriert. Test-Content-Installer verwendet ausschließlich ein temporäres Supportverzeichnis. Keine komplette Flutter-Suite oder Gerätetest behauptet.

## Tatsächliche Befehle, Outputs und Exitcodes

Ab Repository-Root, **macOS Terminal**. Python unter Windows PowerShell entsprechend `.\pipeline\.venv\Scripts\python.exe`; Dart-/Flutter-/Git-Befehle für diese Offlineprüfungen identisch. Logs neu in diesem Auftrag erzeugt, relevante Outputs hier; Terminal-Leerzeichen nur für die Darstellung gekürzt, Original-Logs erhalten.

```text
pipeline/.venv-macos/bin/python build/verbalphrasen_batch_2_checks/check_delivery.py

DELIVERY PASS: 34 ZIP entries; 33 manifest hashes; extracted bytes/reference subset identical;90 identities/pairs,927 tokens(816 words,111 punctuation),3 alternatives;partition91/90/0;14 inherited comparisons;2 prior corrections preserved;display181 rows/bindings PASS
CREATE SHA256 3dc1aa1e073ff891a887e2454558a5c2c0201855eedd23d73b68be587664c000
DISPLAY PATCH SHA256 95782b2af00f5991d183d230480f0023400f7a0afc767ef9f310e625f79a353a
DELIVERY ZIP SHA256 1c11e3194683778272114b7d1f753a05b6b208e7726a41ce61d9c4cfbfca33fa

Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/verbalphrasen_batch_1_v1/pack.json --create 'verbalphrasen_batch_2 2/editorial_content_v2.json' --registry pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json --display-patch 'verbalphrasen_batch_2 2/deck_display_patch.json' --out pipeline/out/verbalphrasen_batch_2_v1
status ok; internal_test_pack true; ai_calls 0; ai_cost_usd 0
22 sqlite_counts: cards3189/decks13/sentences3723/sentence_tokens40354

sha256 f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6

Exit 0

pipeline/.venv-macos/bin/python build/verbalphrasen_batch_2_checks/check_completion.py

COMPLETION PASS:181/181 exact identities/definitions/groups/owners/fixed sentences;partition181/0/0;display1..181;90 new cards,3189 total,13 decks;all22 SQLite tables and old rows/4 form tables/134x3 unchanged;2 batch1 corrections retained
DISPLAY prior changes 0 (append92..181 and final181-row mapping verified)
LINTER0 errors, 476 hints; 1 new: 'unfairly'/'unfairly' Zipf 3.36 below 3.5
PACK SHA 308171f13f4ee479f80f4dfc5667cde63ece850fb2b813d1825f9b22c4715e56
SQLITE SHA f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6

Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q

........................................................................ [ 16%]
........................................................................ [ 32%]
..................................................... [ 44%]
........................................................................ [ 60%]
........................................................................ [ 76%]
........................................................................ [ 92%]
..................................                                       [100%]
447 passed, 19 subtests passed in 12.55s

Exit 0

dart run tool/report_learning_groups.dart pipeline/out/verbalphrasen_batch_2_v1/content.sqlite
mixed: raw_words3156; learning_targets3075; lexical_words2804; form_memberships402
verbalphrasen: raw_words181; learning_targets181; lexical_words181
Exit 0

# Nach Prüfabnahme und nachgewiesener Sicherung vor Staging:
dart run tool/stage_content_pack.dart --from pipeline/out/verbalphrasen_batch_2_v1

Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version verbalphrasen_batch_2_v1, schema 4, 20152320 bytes
  sha256 f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0

dart run tool/stage_content_pack.dart --verify

Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version verbalphrasen_batch_2_v1, schema 4, 20152320 bytes
  sha256 f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0

flutter analyze --no-pub

Analyzing sprachapp...
No issues found! (ran in 2.5s)

Exit 0

flutter test --no-pub test/data/real_pack_test.dart

deck allgemeine-sprache: 160 learning targets, 181 ownership cards, 181 fixed sentence assignments verified
deck reisen: 489 learning targets, 519 ownership cards, 519 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 262 ownership cards, 262 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 252 ownership cards, 252 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 251 ownership cards, 251 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 264 ownership cards, 264 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 248 ownership cards, 248 fixed sentence assignments verified
deck irregular_verbs_base: 134 learning targets, 129 ownership cards, 129 fixed sentence assignments verified
deck irregular_verbs_past: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 134 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck alltagssprache-redewendungen: 441 learning targets, 441 ownership cards, 441 fixed sentence assignments verified
deck verbalphrasen: 181 learning targets, 181 ownership cards, 181 fixed sentence assignments verified
pack verbalphrasen_batch_2_v1 (schema 4, internal: true); 13 decks: 2978 cards, 3189 card sentences, 187 with valid_alternatives, 3189 cards in the pack
00:45 +1: All tests passed!

Exit 0

pipeline/.venv-macos/bin/python build/verbalphrasen_batch_2_checks/check_protection.py

PROTECTION PASS: 2892 original files; authorized changes ['assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite'] ; source/delivery/history/app/tests/instructions protected; backups verified; no batch3 ZIP

Exit 0
```

`--no-pub` nutzt vorhandene Abhängigkeiten ohne Paketauflösung/Installation. Lokaler SDK-Cachezugriff autorisiert, keine Modell-/Provider-/Generierungsaufrufe oder Konfigurationsänderung. Der Pack-Lesetest dauerte 0:45 und blieb bytegleich; keine echten Lernstände berührt. Alle fachlichen Prüfungen beim ersten gültigen Daten-/CLI-Lauf bestanden. Der anfangs gesuchte Ordner ohne Zusatz 2 existierte nicht (rg Exit 2); der tatsächliche Ordner wurde anschließend gefunden und nachweislich unverändert verwendet. Kein Vertragsfehler oder Importschleife.

Windows PowerShell, gleicher Import mit tatsächlichem Ordner:

```powershell
.\pipeline\.venv\Scripts\python.exe pipeline/scripts/import_editorial_patch.py --source pipeline/out/verbalphrasen_batch_1_v1/pack.json --create "verbalphrasen_batch_2 2/editorial_content_v2.json" --registry pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json --display-patch "verbalphrasen_batch_2 2/deck_display_patch.json" --out pipeline/out/verbalphrasen_batch_2_v1
.\pipeline\.venv\Scripts\python.exe -m pytest pipeline/tests -q
```

Keine Windows-Ausführung behauptet. Keine Batch-3-ZIP oder neue Authoring-/Kontext-/Registry-/Gruppenauswahl erzeugt, kein Business-Ziel vorbereitet.

## Rohbytehashes und kanonische Bindungen

| Gegenstand | SHA256 / Scope |
|---|---|

| Original-Liefer-ZIP, Rohbyte | `1c11e3194683778272114b7d1f753a05b6b208e7726a41ce61d9c4cfbfca33fa` |
| Original Create, Rohbyte | `3dc1aa1e073ff891a887e2454558a5c2c0201855eedd23d73b68be587664c000` |
| Original Display-Patch, Rohbyte | `95782b2af00f5991d183d230480f0023400f7a0afc767ef9f310e625f79a353a` |
| Unverändertes Basis-JSON, Rohbyte | `6bf01b919a800c61332ce13a4c5092d448a32524da1c0021f696652e8b5414ed` |
| Unveränderte Basis-SQLite/Asset vor Staging/Backup | `b8a482b09351025886188d705b8203b2391c9a45042d706b983d094ecfbe90fb` |
| Manifest vor Staging/Backup | `ebc62c901723e8a699475a3eeab1f04f406a9c3d3f0ce59ddc508769cf677471` |
| Import-Registry, kanonisch | `bf311a26def8442871fbafa688b230af0456a9d462cf8c843997785e537b3ff8` |
| Batch-2-Gruppen, kanonisch | `70cce1d99c8377f256a4129e3164badfc98639e74683acac23ab5cade5598b1b` |
| Abschluss-Pack, Rohbyte | `308171f13f4ee479f80f4dfc5667cde63ece850fb2b813d1825f9b22c4715e56` |
| Neue SQLite/App-Asset, Rohbyte | `f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6` |
| Neues Asset-Manifest, Rohbyte | `748852813e408a2950bbf07bb8e3e79888f6bdeaa33effbd193a861358ea34b3` |

Rohbytehashes und kanonische Digests getrennt. Original-Lieferung, historische Packs/Registrys/Gruppen/Auswahlen bytegleich erhalten. Keine Korrekturkopie und keine Patch-Umbindung notwendig.

| SQLite-Tabelle | Tatsächliche Zeilen |
|---|---:|

| languages | 1 |
| lemmas | 4287 |
| senses | 5906 |
| cards | 3189 |
| dictionary_forms | 7067 |
| decks | 13 |
| deck_cards | 3082 |
| deck_words | 2978 |
| word_aliases | 37 |
| sentences | 3723 |
| sentence_tokens | 40354 |
| card_sentences | 3717 |
| stories | 1 |
| story_sentences | 6 |
| exercises | 0 |
| grammar_rules | 0 |
| audio_assets | 0 |
| content_releases | 1 |
| lexical_targets | 134 |
| card_lexical_targets | 406 |
| form_targets | 402 |
| deck_practice_targets | 402 |

## Vierzehn geerbte Kontextvergleiche – weiterhin offen

Unveränderte gemeinsame Wörterbuchzeilen, keine neuen Fehlbindungen unter dem Altglossenetikett verborgen. Ergänzt Batch 1 und sämtliche älteren Vergleichslisten, keine globale Reparatur:

| Form / Sense | Altglosse | Kontextdarstellung / Grund |
|---|---|---|

| met / meet/VERB&#124;meet#treffen | trafen | traf — ask out: he met, geerbte Formglosse nur Plural. |
| concert / concert/NOUN&#124;concert#konzert | Konzert- | Konzert — ask out: eigenständiges Nomen statt gebundener Kompositumsform. |
| used / use/VERB&#124;use#benutzen | benutzte | benutzten — patch up: we used, Altglosse nur Singular. |
| kept / keep/VERB&#124;keep#fortsetzen | fuhr fort (kept walking on = ging weiter) | fuhren fort — give in: children kept asking, Altglosse Singular und anderes Beispiel. |
| summer / summer/NOUN&#124;summer#sommer | Sommer- | Sommer — look back on: eigenständiges Nomen. |
| are / be/AUX&#124;be#sein_vollverb | sein (als Kopula zur Angabe von Zustand, Identität oder Eigenschaft) | sind — grow up: Formglosse enthält Bedeutungsdefinition. |
| sleeves / sleeve/NOUN&#124;sleeve#aermeln | Ärmeln | Ärmel — roll up: Akkusativ, nicht Dativ. |
| cooking / cook/VERB&#124;cook#kocht | kocht | Kochen — turn off: substantivierter Vorgang nach after. |
| ignored / ignore/VERB&#124;ignore#missachten | ignoriert | ignorierte — pay for: einfache Vergangenheit. |
| could / could/AUX&#124;could#konnten | konnten | konnte — see through: I could, Altglosse Plural. |
| had / have/VERB&#124;have#muessen | mussten (in had to) | musste — step in: teacher had to, Altglosse Plural. |
| careful / careful/ADJ&#124;careful#vorsichtig | vorsichtig | sorgfältig — turn out: sorgfältige Planung; bestehende Glosse nur vorsichtig. |
| cooked / cook/VERB&#124;cook#kocht | garte | hast gekocht — wash up: allgemeines Kochen, nicht allein Garen. |
| did / do/AUX&#124;do#hilfsverb | Hilfsverb für die Frage in der Vergangenheit | Vergangenheits-Hilfsverb (hier Verneinung) — live up to: geerbte Glosse nennt nur Fragen. |

## GitNexus und sicherer Commitumfang

Graph zuerst für konkrete Import-/Display-Patch-Symbole per UID verwendet; vorhandene Vertragsquellen und Offlineprüfungen ergänzen die Grenzen. Index `sprachlernapp`, Stand 11.10.2026, Commit 90c2930, **drei Commits hinter Start-HEAD 98c5a12**. create_content und apply_deck_display_patch gefunden; der statische Index benennt 30 bzw. einen eingehenden Aufruf und keine erfassten Prozesse. Das ist keine vollständige aktuelle Abdeckung. Keine Funktion geändert, kein Indexneubau.

Vor Edit: Roadmap-Impact LOW, neun Dokumentabhängigkeiten, zwei direkt, keine erfassten Prozesse. NEXTSTEPS mit null aufgelösten Callern UNKNOWN; neuer Bericht/Assets nicht indexiert und UNKNOWN. Nicht als all-clear ausgegeben. Literal-Referenzen/Dateiscope sowie tatsächliche Tabellen-/Identitäts-/Hash-/Schema-/App-Prüfungen bestätigen die erlaubte Änderung; keine HIGH/CRITICAL-Warnung. Rohbelege `preflight-tools.json`, `pre-edit-impacts.json`; tatsächliche Änderungsanalyse vor Commit gesondert.

Index vor Beginn leer. Vorbestehende NEXTSTEPS-Anteile und fremde untracked Lieferungen/Berichte/Kontexte erhalten. Eigenes Inkrement nur dieser neue Abschlussbericht und begrenzte Roadmap-Aktualisierung. NEXTSTEPS wegen Altanteilen außerhalb des Commitumfangs. Pack/Assets/build sind etablierte gitignored interne Testartefakte (`git check-ignore` bestätigt), keine Binärdateien zwangsweise gestagt. Kein pauschales git add, kein fremder Inhalt oder uncommittierter Code übernommen, kein Push.

Bestandsschutz: 2892 vorbestehende Dateien erfasst, nur internes Asset/Manifest und angeforderte Statusdokumente dürfen sich ändern. Neue Ausgabe/Prüfprotokolle/Abschlussbericht zusätzlich. Keine App-/Test-/Instruktions-/Modell-/API-/Supabaseänderung; keine echte user.db, Reviews, Deinstallation oder Lernstandrücksetzung. Abschlussabgleich `completion-181.json`, alle Identitäten `identities-181.json`, Bestandsschutz/Endhashes `final-protection.json`.

## iPhone aktualisieren, vorhandene App und Lernstände behalten

Angelehnt an die vorhandene [iPhone-Anleitung](irregular-verbs-batch-4-import.md). **macOS Terminal**, bisheriges Projekt und bisherige Signierung verwenden. Runner-Bundle-ID im unveränderten `ios/Runner.xcodeproj/project.pbxproj`: **com.example.sprachapp**; nicht wechseln. Auf Windows ist der iOS-Build nicht verfügbar; dort lassen sich die oben beschriebenen Offlineprüfungen durchführen.

1. Im Repository `dart run tool/stage_content_pack.dart --verify` ausführen: erwartet verbalphrasen_batch_2_v1, Schema 4 und SQLite-SHA256 `f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6`.
2. iPhone verbinden und entsperren; `flutter devices` ausführen und die tatsächlich angezeigte Geräte-ID verwenden.
3. `flutter run --no-pub -d "IPHONE-ID"` mit dieser ID ausführen. Bestehende Installation aktualisieren, keine Deinstallation oder Datenrücksetzung.
4. Verbalphrasen 181 Ziele und die drei Verbenansichten je 134 prüfen; bestehende Favoriten, Notizen und Lernstände kontrollieren. Bei allen aktivierten Ansichten beträgt das vollständige Inhaltsinventar 3075 Übungen / 2804 Wörter; persönliche Filter/Lernstände können die sichtbaren Zustandszahlen beeinflussen.

Der bestehende ContentPackInstaller validiert Asset/Manifest und tauscht nur die Inhaltsdatei atomar aus; user.db liegt außerhalb dieses Austauschs. Gerätekommandos wurden hier **nicht ausgeführt**, diese Anleitung ist keine Geräteabnahme. Öffentliche Inhalts-/Sprachfreigabe und offene Glossenbefunde bleiben gesondert offen.

## Nächste und letzte geplante Inhaltsaufgabe

**Business & E-Mail: ca. 1500 eigenständige Ziele nach Dublettenprüfung, davon ca. 70 zum E-Mail-Verkehr als Teilmenge.** Noch keine Auswahl, Reservierungen oder Sätze angelegt. Geplanter v1-Umfang weiterhin genau 14 Stapel; Verbalphrasen ist als dreizehnter Stapel vollständig intern abgeschlossen. Keine zusätzliche Kategorie vorbereiten.

## Abschluss der Dokument- und Commitprüfung

Tatsächlich ausgeführt, Git-Kommandos identisch unter macOS/Windows:

```text
git diff --check -- NEXTSTEPS.md docs/content-roadmap-v1.md docs/verbalphrasen-batch-2-import.md
Keine Ausgabe; Exit 0

git diff --cached --check -- docs/content-roadmap-v1.md docs/verbalphrasen-batch-2-import.md
Keine Whitespace-Diagnostik; Exit 0

git diff --cached --name-only
docs/content-roadmap-v1.md
docs/verbalphrasen-batch-2-import.md
Exit 0
```

Neue eigene Dokumente mit LF, kein CRLF-Erhaltungsfall; kein cr-at-eol-Lauf erforderlich. Bekannte repositoryweite Altbefunde (DESIGN.md:162–164, Alltag-Zuhause-/Arbeit-Bildung-Berichte) bleiben getrennt und unangetastet. Der gestagte Check erfasst auch den zuvor untracked Bericht. Gezielte Logs: `diff-check.log`, `staged-diff-check.log`; keine pauschale Bereinigung.

MCP `detect_changes({repo: "sprachlernapp", scope: "all"})`: sieben erfasste Dokumentabschnitte / drei geänderte Dateien, null erfasste Prozesse, risk_level low. `scope: "staged"`: drei erfasste Roadmapabschnitte / zwei gestagte Dateien, null erfasste Prozesse, risk_level low. Beide Antworten ohne partial/truncated-Markierung, aber Index stale und neuer Bericht weiterhin nicht indexiert: keine vollständige Graphabdeckung. Interne ignoredbasierte Pack-/Assetänderungen sind nicht im Git-Diff erfasst und separat vollständig durch Daten-/App-Checks geprüft.

Bestandsschutz-Endabgleich: 2892 vorbestehende Dateien, nur die vier angeforderten Änderungen Asset/Manifest/NEXTSTEPS/Roadmap. Original-Lieferung und sämtliche historischen Quellen/Kontexte, App-/Test-/Instruktionsdateien bytegleich. Baseline-, Sicherungs-, Identitäts- und Hashnachweise im Prüfverzeichnis. Index vor Beginn leer, vor Commit ausschließlich zwei eigene Dokumente; NEXTSTEPS mit Altanteilen uncommittet. Lokaler Commit und Endstatus: `commit.log`, `status-final.txt`; kein Push. Kein Batch-3-Artefakt und kein Business-Authoring erzeugt.
