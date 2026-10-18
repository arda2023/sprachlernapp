# Brasilianisches Portugiesisch · Authoring-Vertrag v1 (PLANENTWURF)

Status: vorhandener Austausch **v4**, als unvollständiger Entwurf transportvalidiert.
Kein portugiesischer Release, kein freigegebenes Sprachprofil, keine reservierten Wörter.
Die ZIP-Hauptlieferung enthält 20 leere Refslots. Nicht als fertige Inhalte importieren.
Vor einer späteren echten Lieferung zuerst Sprachprofil implementieren/abnehmen und
im Editor einen neuen pt-BR-Sprachentwurf erzeugen; Vorlage aus dessen exakter Basis
neu exportieren. Die hier verwendete leere synthetische Basis ist kein Produktionshead.

## Kennungen und Rahmen

- `lang`: exakt `pt-BR`; `translation_lang`: `de`.
- Sprachname: `Portugiesisch (Brasilien)`; Eigenname: `Português do Brasil`.
- Vorgeschlagenes Profil: `pt-BR-editorial-v1`; Hash noch NICHT definiert.
  Er entsteht erst aus implementiertem Profilmanifest und bestandenen Fähigkeitsprüfungen.
- Stapel: `Allgemeine Sprache`; Slug `allgemeine-sprache`, Art `ordinary`,
  `cefr_band=anfaenger`, Sortierung 1. 20 echte, redaktionell erstellte Ziele;
  später ungefähr 160, keine Auffüllpflicht. Keine Stories/Formstapel voraussetzen.
- `pt`, `pt-PT` und `pt-BR` sind keine austauschbaren Inhaltsidentitäten.

## ZIP und Autorität (heute implementiert)

Genau `delivery.json`, `FORMAT.md`, `editorial_content_v4.schema.json`,
`authoring_context.json`, `files.sha256.json`, optional `editor.xlsx`.
Hashliste: SHA256 der exakten Bytes aller übrigen Einträge. JSON ist kanonische
Lieferung; abweichendes XLSX erzeugt SOURCE_CONFLICT, keine automatische Mischung.
Keine Skripte, verschachtelten Archive oder zusätzlichen Einträge im Import-ZIP.
25 MiB JSON, 50 MiB Archiv, 200 MiB entpackt, 2000 Einträge, Verhältnis ≤100:1.
`read_delivery` prüft Container/Transport, nicht sprachliche Releasefähigkeit.
Das mitgelieferte Schema ist das unveränderte bestehende Repositoryschema; seine
Rohobjektfelder sind absichtlich nicht vollständig typisiert. Die folgenden
strengeren Lieferregeln und `authoring_contract` im Kontext schließen diese Lücke.

## Envelope: alle Felder der späteren Chatlieferung

| Feld | Wert / Verantwortung |
|---|---|
| format / format_version | `sprachapp.editorial-content` / `4` |
| delivery_id | UUID aus exportierter Vorlage; neue fachliche Lieferung neue UUID, nicht vom Chat erfinden |
| lang / translation_lang / purpose | `pt-BR` / `de` / `new_deck` (später `append`) |
| base | exakte exportierte Basis: release_id, version, pack_bytes_sha256, pack_canonical_sha256, sqlite_sha256, registry_sha256, profile_sha256; keine Hashes raten |
| context_sha256 | kanonischer Hash des exportierten authoring_context; unverändert übernehmen |
| expected_target_refs | alle 20 Zielrefs genau einmal; derselbe Satz in den Batches und create_target-Operationen |
| selection | policy `editor-deck-v1`, batches mit number ab 1 und target_refs, höchstens 100 pro Batch |
| add | im empfohlenen Weg nur neue `lemmas`, `senses`, `dictionary_forms`; keine `languages`, keine SQL-IDs |
| operations | zuerst ein create_deck, dann 20 create_target; keine zusätzlichen add.cards für dieselben Ziele |
| provenance | manuelle Herkunft mit ref, kind=`manual`, source_label, supplied_at (ISO-Zeit), source_record_ref, notes; wahrheitsgemäß, keine Freigabebehauptung |
| submitted_reviews | `[]`; lokale redaktionelle Bestätigung erst im Editor |
| extensions | `{}`; unbekannte Felder blockieren |
| completeness | `draft` bis vollständig geprüft; `full` ist keine redaktionelle Freigabe |
| supersedes_delivery_id | optional null oder bekannte Vorgänger-Liefer-UUID; keine erfundene Beziehung |

Ein Profilobjekt, Sprachname oder `language_definition` ist **heute kein erlaubtes
Top-Level-Lieferfeld**. Profil/Sprachmetadaten stehen im hashgebundenen Kontext und
im separat angelegten Sprachseed. Der vorgeschlagene Ein-Datei-Bootstrap im Kontext
ist ein zukünftiger Vertrag, kein heute importierbares Feld.

## Neue Semantik ohne erratene Wörterbuch-IDs

Die Chatlieferung definiert neue lokale Refs und Inhalte, niemals vorhandene IDs:

| Record | Erforderliche Felder / Werte |
|---|---|
| lemmas | ref, lemma (exakte NFC-Grundform), pos (UD-Wortart, Liste im contract.json) |
| senses | ref, lemma (Ref), sense_key (stabiler bedeutungsspezifischer Schlüssel), gloss_de, definition_de; alle nichtleer |
| dictionary_forms | form (konkrete Wort-/Ausdrucksoberfläche), sense (Ref), gloss_de, rank=0; optional card nur bei belegter eigener Zielref |
| create_deck | op_id, kind=`create_deck`, lang, target_ref, expect={absent:true}, reason; payload={ref:target_ref, slug, title_de, description_de, practice_kind:ordinary, cefr_band:anfaenger, sort:1} |
| create_target | op_id, kind=`create_target`, lang, target_ref, expect={absent:true}, reason; payload={deck_ref, topic:allgemeine-sprache, card, context} |
| payload.card | form, sense (eigene oder exakt exportierte Ref), translation_de (Zielglosse), cefr_band=anfaenger, introduction_scope=ordinary; identity_function weglassen; optional form_label_de nur ausdrücklich redaktionell |
| payload.context | text, translation_de, gap, tokens, valid_alternatives, reason; keine alten Sentence-IDs |
| context.gap | start_pos/end_pos: ganze Unicode-Codepointoffsets [start,end), nach NFC; 0≤start<end≤Textlänge |
| context.tokens | geordnete vollständige Liste mit idx=0..n-1, surface, start_pos, end_pos; Worttokens zusätzlich lemma, sense, context_gloss_de, binding_status=confirmed; Satzzeichen ohne künstliche Sense |

Jedes Worttoken braucht eine explizite passende Lemma-/Sensebindung **und** eine
Formglosse in dictionary_forms; Kontextglosse darf von der Wörterbuchglosse
abweichen. Neu angelegte Begleitbedeutungen sind keine neuen Lernziele und erzeugen
keine SRS-Karten. Keine automatische Sensewahl nach Schreibweise, keine Übersetzung
als Identität. Refs sind lieferungsintern stabil und werden nicht neu nummeriert.
Bestehende Refs nur aus dem exportierten Kontext übernehmen; Kollision ist ein
sichtbarer Konflikt, keine stillschweigende Umdeutung.

## Lücke, Tokenisierung und Alternativen

Text zuerst NFC, Zeilenende LF. Akzente, ã/õ und ç erhalten. Keine NFKC-/Accent-
Entfernung; Satzgroßschreibung bleibt. Ziel erscheint genau einmal vollständig
und zusammenhängend; `do`/`na` bleiben eigene Oberflächen mit expliziter Bedeutung,
werden nicht in `de o`/`em a` umgeschrieben. Mehrwortlücke umfasst vollständige
zusammenhängende Tokens; der vorhandene lexical_spans-Weg verschmilzt nur diese
Lücke. Keine disjunkten Teile oder erste Fundstelle bei Wiederholung.

Die finale Chatdatei muss exakte Offsets liefern. Sie werden mit dem festgelegten
Tokenizer/Gapwerkzeug lokal deterministisch berechnet und geprüft, **nicht vom
Modell geschätzt**. Der aktuelle Importer berechnet fehlende Offsets nicht selbst;
fehlende Angaben bleiben ein Entwurfsblocker. Tokenbindung und deutsche Semantik
sind redaktionelle Entscheidungen, keine deterministisch erratbaren Daten.

Für den 20er-Pilot ausdrücklich `valid_alternatives: []`: keine Alternativen
vorgesehen, erst nach redaktioneller Prüfung bestätigen. Das fehlende Feld ist
kein Beweis einer Prüfung. Später nur exakte Stringwerte nach Einsetzen im ganzen
Satz und Review des gebundenen Kontextes; keine pauschale pt-PT-, Akzent- oder
Flexionsalternative. Alternative bleibt neutraler neuer Versuch, löst nicht.

## Was vorhandener Importer/Build erzeugt

create_target erzeugt aus gelieferten Refs: Content-IDs via stable_id/card_id,
Singleton-Lerngruppe und primary_card_id, Ownerreservierung, deck_words,
deck_cards, fortlaufende Position, Satzref `new:<target_ref>`, Satz-/Token-/Link-IDs,
accepted=[form], eingefrorene Kontextsnapshots und Historieninventar. Der
Releasebuild erzeugt SQLite, Byte-/Inhaltshashes und Berichte. Nichts davon muss
Chat erraten. `create_target` läuft heute erst bei Materialisierung/Prüfung;
Entwurfsannahme allein reserviert keine produktiven Wörter.

Chat liefert Texte, Bedeutungsdefinitionen, Refs, explizite Bindungen, Glossen,
Stapelmetadaten und vollständig überprüfte Kontextdaten. Lokale Redaktion prüft
brasilianische Verwendung, Eindeutigkeit, Grammatik, Übersetzungen, Niveau,
Kontraktionen/Mehrwortlücke und jede Bindung. Freigabe ist payloadhashgebunden.
Synthetisches Beispiel nie bestätigen; Marker `SYNTHETIC_NON_PUBLISHABLE` beachten.

## Tatsächliches XLSX v1 (nicht die ältere Plandokument-Tabelle)

Meta: `key,value_json`; Metawerte sind JSON, xlsx_version=1, xlsx_mode=full,
xlsx_add_tables hält die Addtabellen. Full bedeutet verlustloser Transport, nicht
releasefähig. Detailblätter: Ziele, Saetze, Luecken, Tokens, Lemmas, Bedeutungen,
Formglossen, Stapel, Herkunft, Operationen, Bindungen, Gruppen, Alternativen,
Records; zusätzlich Anleitung. `_table`, `_index`, `payload_json` sind notwendig.
Sichtbare Felder stehen exakt in `authoring_contract.xlsx.visible_columns`.
Restpayload ist `{fields:{...},present:[...]}`; present unterscheidet fehlend/null.
Gruppen/Alternativen sind getrennte Teilobjekte derselben `_table/_index`-Zeile.
Keine doppelten Felddefinitionen. XLSX vom vorhandenen write_workbook erzeugen,
keine von Hand erfundene Tabellenvariante. Zelllimit 32767 Zeichen, keine Formeln.
Einfachmodus ist nur Draft: ref,form,translation_de,sentence,sentence_translation_de,
sense,gap_start,gap_end; nicht die geplanten Spaltennamen sentence_text verwenden.

## Dateien im Kontext

`authoring_contract`: maschinenlesbarer Planstatus/Feldvertrag und präzise künftige
Bootstrap-Erweiterung. `synthetic_example_delivery`: separat durch den aktuellen
JSON-/XLSX-Reader geprüfte reine Strukturprobe mit erfundenem Marker, keine
portugiesischen Lernziele. Keine zweite Autorität neben delivery.json.
`profile.supported=false` bleibt ehrlich. Der vorhandene validate_draft meldet
für pt-BR `technical=unsupported`, `PROFILE_UNSUPPORTED`, `editorial=open`.
