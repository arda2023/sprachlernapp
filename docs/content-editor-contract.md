# Vertrag für Inhaltseditor, Austausch und Updates

**Paket 2 implementiert und auf macOS geprüft — 16.10.2026; Paket 3 bleibt geplant.** Ergänzt den [Umsetzungsplan](content-editor-and-updates-plan.md), einschließlich mehrerer Lernsprachen und umfangreicher externer Stapellieferungen. Die ursprünglichen Typen, Routen und Dateipfade sind Planverträge; der nachstehende Implementierungsnachtrag konkretisiert Paket 2. Paket 3 bleibt **geplant**. Bestehende Formate 2/3, Schema 1–4 und aktuelle IDs bleiben als Legacyverträge lesbar. Keine neue Sprache, Kategorie, Cloudressource oder echter Inhalt wird hier angelegt.

## 1. Zuständigkeit und Versionen

| Grenze | Autorität / Format |
|---|---|
| Bearbeitung | Basis-`pack.json` plus Registry und explizite Entwurfsoperationen; keine frei editierbare zweite SQLite |
| Austausch | `sprachapp.editorial-content`, neue `format_version: 4`; JSON kanonisch, ZIP vollständiger Transport, XLSX reversible Tabellenabbildung |
| Arbeitsstand | `sprachapp.editor-draft`, `format_version: 1`; darf unvollständig sein |
| Technischer Export | Bestehende `build_rows`-/Linter-/`export_sqlite`-/Readback-Kette, erweitert um Schema 5 |
| Distribution | Neues Release-Manifest `format: 2`; vorhandenes Assetmanifest `format: 1` bleibt lesbar |
| App | Bekannte Schema-/Profilfähigkeiten, unveränderliche Generation, eigene Integritätsprüfung; kein stilles Herabstufen |

`pipeline/src/sprachpipe/authoring_service.py` wird der gemeinsame Dienstkern. CLI, HTTP und Austauschadapter rufen ihn auf. `content_contract.py::validate_rows`, `sentence_count`, `validate_registry`, `form_targets.py`, `learning_groups.py`, `pack.py::build_rows`, `curate.py` und `export.py` behalten die fachliche Prüfung. Die UI prüft nur Bedienbarkeit; ein grünes UI-Feld ersetzt nie die gemeinsame Validierung.

Geplante Python-Signaturen (Domänentypen dieses Dokuments, keine Dateipfade aus HTTP): `normalize_delivery(raw, format, language) -> Delivery`, `preview_import(base, delivery) -> ImportPreview`, `apply_operations(base, operations, profile) -> WorkingPack`, `validate_draft(draft, base, profile) -> Validation`, `build_release(draft_id, expected_revision, validation_sha256) -> ReleaseBundle`. Persistenz und Jobs werden injiziert, Validatoren bleiben ohne HTTP-Abhängigkeit. `xlsx_to_delivery(workbook)`/`delivery_to_xlsx(delivery)` sind reine Transportadapter. `language_profiles.get(lang, profile_id)` muss bei unbekannter Kombination explizit fehlschlagen.

Bestehende Grenzen sind ausdrücklich nicht aufgehoben: `create_content` kann bisher keine beliebigen Bestandskorrekturen, targeted-Satzersatz verlangt eine neue Text-ID und bekanntes Begleitvokabular, targeted-Retirement blockiert aktive Owner-/Formbindungen. Änderungen dieser Grenzen werden durch die unten genannten neuen Operationen und Tests realisiert, nicht durch Umgehen vorhandener Prüfungen.

## 2. Grundtypen und kanonische Werte

- `Uuid`: zufällige UUID v4 für Entwurf, Lieferung, Import, Job und Operation; nicht als Content-ID verwenden.
- `ContentId`: bestehende 32-stellige Hex-ID aus `ids.stable_id`; bestehende Keyreihenfolge, NFC und Namespace unverändert.
- `Sha256`: 64 kleine Hexzeichen. Bytehash und kanonischer JSON-Hash heißen ausdrücklich verschieden.
- `Lang`: kanonischer BCP-47-Tag; exakte registrierte Form, keine Pfadseparatoren. Displayname ist frei änderbar; referenzierter Code nicht. `translation_lang` ist unabhängig und zunächst nur `de` freigabefähig.
- `Ref`: lieferungsintern stabiler Schlüssel, eindeutig je Tabelle und Lernsprache; niemals Excel-Zeilennummer. Bei Bestandsobjekten zusätzlich vorhandene Content-ID und Basishash.
- Canonical JSON verwendet die bereits vorhandene `word_registry.digest`-Serialisierung: UTF-8, `ensure_ascii=False`, sortierte Objektschlüssel, Trennzeichen `(',', ':')`. Keine NaN/Infinity, doppelten JSON-Schlüssel oder nicht definierten Felder. Zahlen für Zähler/Offsets sind ganze Zahlen. Listenreihenfolge bleibt signifikant, sofern das jeweilige Schema keine Sortierung festlegt.
- Texte werden vor Tokenisierung und neuem Identitätsaufbau nach NFC normalisiert; keine pauschale NFKC-, Accent- oder Kleinschreibungsumwandlung des Satzes. Identitätsschlüssel existierender Daten werden nicht nachträglich normalisiert oder verändert.

### LanguageDraft und LanguageProfile

```text
LanguageDraft {
  lang, display_name, name_native, translation_lang: "de",
  revision: int, state: "draft" | "blocked" | "ready",
  profile_id: string|null, profile_sha256: Sha256|null
}
LanguageProfile {
  id, revision, lang, translation_lang,
  identity_normalization, lookup_normalization, answer_policy,
  tokenizer_id, sentence_segmenter_id, model_version,
  allowed_functions[], frequency_policy, sentence_policy,
  direction: "ltr"|"rtl", capability_tests_sha256
}
```

`display_name` wird bei `translation_lang=de` auf `languages.name_de` abgebildet, `name_native` auf das gleichnamige bestehende Feld, `translation_lang` auf `gloss_lang`. Der Server berechnet `state`; die UI kann ihn nicht auf `ready` setzen. Das Profil ist eine im Code registrierte, getestete Implementierung mit unveränderlicher Versionskennung, kein hochladbarer ausführbarer Code. Es muss Tokenisierung, Satzgrenzen, Normalisierung, Formfunktionen, Antwortprüfung und Frequenz-/Längenregeln abdecken. Bei einer begründeten Sprache ohne geeignete Frequenzquelle braucht es eine ausdrücklich geprüfte Ersatzpolicy, kein automatisches Bestehen. Die App enthält die passenden Reader-/Antwortfähigkeiten. Profile werden nicht nach Sprachpräfix geraten. Bestehendes Englisch verwendet zunächst eingefrorene bisherige Identitätsregeln; ein späterer Profilwechsel darf alte IDs nicht neu berechnen.

## 3. Entwurf, Basis und Freigaben

```text
Draft {
  format: "sprachapp.editor-draft", format_version: 1,
  draft_id: Uuid, lang, translation_lang, revision: int,
  base: {
    release_id: string|null, version: string|null,
    pack_bytes_sha256: Sha256, pack_canonical_sha256: Sha256,
    sqlite_sha256: Sha256|null, registry_sha256: Sha256,
    profile_sha256: Sha256|null
  },
  delivery_ids: Uuid[], operations: Operation[],
  incomplete_records: Record[], import_inventory: Inventory,
  reviews: Review[], created_at, updated_at
}
```

Neue Sprache: `release_id/version/sqlite_sha256=null`, Basis ist ein kanonischer leerer Seed des vorhandenen Packmodells mit Sprachdatensatz und leerer Registry. Ohne Profil darf der Seed nur im Entwurf liegen; er ist kein gültiger Lernpack. Entwürfe referenzieren eine lokal eingefrorene Basis, nie einen sich unbemerkt ändernden Assetpfad.

`revision` steigt bei jeder gespeicherten Änderung. HTTP-ETag ist `"draft:<uuid>:<revision>:<canonical-hash>"`. `If-Match` ist für Änderungen/Prüfen/Export erforderlich. Fehlt er: 428; veraltet: 409 mit aktueller Revision und Diffverweis. Autosave wird bestätigt angezeigt; Transportfehler erzeugt keinen vorgetäuschten Speicherstatus.

Reviews sind getrennt von technischem Status:

```text
Review { scope, record_refs[], payload_sha256, decision: "approved",
         reviewer, reason, reviewed_at, origin: "local-editor" }
Validation { draft_revision, base_sha256, validator_version,
             technical: "valid"|"invalid"|"unsupported",
             editorial: "open"|"approved", findings[], coverage }
```

Der Reviewhash umfasst genau die freigegebenen Felder plus ihre Abhängigkeiten. Satzänderung öffnet Satzübersetzung, Lücke, Tokenbindungen, Alternativen und Storypolicy wieder; Lösungshinweisänderung öffnet Kartenhinweisreview; globaler Glosseneingriff öffnet alle tatsächlich berührten aktiven Kontextreviews. Semantische Bindungen sind auch bei übernommenen Textstellen nach Satzänderung erneut zu bestätigen. Unveränderte sichere Bindungen dürfen als Vorschläge vorbesetzt werden, nicht als erfundene neue Entscheidung. Technische Prüfergebnisse verfallen bei jeder abhängigen Änderung. Importierte Reviewbehauptungen bleiben Provenienz und werden nie als lokale Bestätigung übernommen.

Speicherort: macOS `~/Library/Application Support/SprachappContentEditor/`, Windows `%LOCALAPPDATA%\SprachappContentEditor\`. Darin `languages/<lang>.json`, `bases/<sha>/`, `drafts/<uuid>/revisions/<n>.json`, atomarer `current.json`, `imports/<uuid>/`, `releases/<lang>/<release-id>/`, `staging/<uuid>/`. Der Browser darf diese Pfade nicht setzen. Ein Prozesslock verhindert zwei schreibende Dienstinstanzen; ein Writer serialisiert Transaktionen. Schreiben: temporäre Datei im selben Verzeichnis, flush/fsync, atomarer Ersatz; Recovery ignoriert unbestätigte temporäre Revisionen. Journale enthalten nur IDs/Hashes/Status, keine Zugangstokens. Verwerfen setzt nur den Draftpointer zurück bzw. archiviert den Draft.

## 4. Gemeinsame Operationen und Preconditions

Jede `Operation` enthält `op_id`, `kind`, `lang`, `reason`, `target_ref`, `expect` und `payload`. `expect` bindet Basisrelease, betroffene Entity-Fingerprints und alle abhängigen Link-/Registry-/Gruppenfingerprints. Ein Fingerprint ist der kanonische Hash des vollständigen Rohobjekts, nicht nur des sichtbaren Feldes. `expect.absent=true` ist bei Neuerstellung nötig. Wiederholte identische Operation liefert den bestehenden Beleg; gleiche `op_id` mit anderem Hash ist ein Konflikt. Alle Operationen eines Builds werden auf einer Kopie angewandt und gemeinsam validiert; keine partielle Bestandsübernahme.

| `kind` | Payload und Voraussetzung | Wirkung |
|---|---|---|
| `create_deck` | neue Ref, Sprache, Slug, DE-Titel/Beschreibung, Art; ID/Slug abwesend | Neues Deck; Entwurf darf leer sein |
| `create_target` | vollständige Karten-, Sense-/Lemma-Refs, Gruppe, Einführung, Eigentümer-/Formbindung und ein ContextSpec | Neue Lern-ID; bestehende identische Identität wird als Reuse-Konflikt angeboten |
| `reuse_target` | vorhandene Karte/Funktion, Hash der Karte und ihrer festen Satzbindung; erlaubte Mitgliedschaft | Kein neuer Satz, keine neue Lern-ID, kein neuer Wortbesitz |
| `add_vocabulary` | neue Lemmas/Senses und `(lang, form_norm, sense)`-Formglossen; bisher abwesend | Explizite neue Begleitbedeutungen; kein Überschreiben gleichnamiger Refs |
| `revise_context` | Karten-ID, aktive Link-/Satz-/Tokenhashes; vollständiger ContextSpec | Neue Satzrevision, alter Link historisch; auch bei unverändertem Lernsprachtext |
| `set_solution_hint` | `translation_de`, exakter Kartenhash | Nur Kartenhinweis; unveränderte Identität und SRS |
| `set_shared_gloss` | Sense- oder Dictionary-ID, bisherige Glosse, neue Glosse, vollständiger Wirkungsmengenhash und bestätigte Verwendungen | Redaktionelle Wortlautkorrektur einer Bedeutung; Kontextrevisionen nur für bewusst ausgewählte aktive Verwendungen |
| `retire_target` | Karte, vollständiger RetirementPlan, Hash aller Abhängigkeiten | Tombstones und zulässige Membership-/Primärprojektion; nie löschen oder SRS übertragen |
| `correct_story_context` | Herkunft, alte lokale Fingerprints/Revision, neuer geprüfter ContextSpec und Policy | Append-only-Korrekturkante, keine pauschale Neuschreibung lokaler Karten |

`ContextSpec` enthält `text`, `translation_de`, `gap`, geordnete `tokens`, `accepted` (bestehende Semantik beibehalten), `valid_alternatives`, explizite Alternativenreviews und `provenance`. Zielbedeutung/-funktion muss exakt zur Karte passen. Neue Bedeutung oder neue Formfunktion ist **kein** `revise_context`; UI führt zu `create_target`, ohne alte Boxen/Notizen/Reviews zu übernehmen. Bestehende Synonym-/Gruppenentscheidungen bleiben unverändert, sofern nicht eine ausdrücklich ausgewiesene Gruppenoperation erforderlich ist. Keine automatisch generierten Synonymlisten aus Owneraliases.

### Redaktionelle Änderungspakete im Detail

`RetirementPlan.group_action = {mode: "unchanged"|"promote_existing"|"retire_group", group_id, expected_member_ids, next_primary_card_id|null}`; `owner_action = {mode: "unchanged"|"set_primary"|"retire", word_id, expected_owner_deck_id, next_primary_card_id|null}`. Dazu `membership_ids[]` und `dependent_context_operations[]`. Fehlende betroffene ID ist ein Fehler; `promote_existing` muss eine aktive vorhandene, bereits zur gleichen Gruppe gehörige Karte nennen. Ein Wechsel des Eigentümerstapels ist in diesem Vertrag nicht vorgesehen.

### Gebundene Rückstellung

`RetirementPlan` enthält `card_id`, `group_action`, `owner_action`, vollständige aktive Membership-IDs, geteilte Satz-/Storyverwendungen und deren explizite Nachfolgeaktionen. Der Server ermittelt die Wirkungsliste; der Client bestätigt ihren Hash, nicht eine selbst verkürzte Liste.

- Singleton ohne aktive Bindung: vorhandene targeted-Regel wiederverwenden.
- Mitgliedschaften an dieser Karte historisieren; unbetroffene Ziele bleiben bestehen. Bei aktiver Gruppe muss eine ausdrücklich bestätigte zulässige Primärkarte derselben bestehenden Gruppe erhalten bleiben oder die gesamte Gruppe wird zurückgestellt. Keine automatische Zusammenführung unabhängiger Senses.
- Wortreservierung bleibt bestehen. Bei nötigem Primärwechsel nur explizit geprüfte vorhandene Karte innerhalb derselben reservierten Oberfläche/Ownerbeziehung; anderenfalls Wortbesitz historisieren und Reservation erhalten, nicht an einen anderen Stapel verschenken.
- Dafür Registryformat 2 additiv planen: unveränderte bisherige `words`, `parent_sha256`, append-only `events[{id, kind, lang, form_norm, expect_effective_sha256, primary_card_ref|null, removed_in|null, reason}]`. Zulässige Kinds zunächst `set_primary`/`retire`; keine implizite neue Ownerzuweisung. `effective_registry` wird abgeleitet. Format 1 bleibt unverändert lesbar, alte Registryeinträge werden nie umgeschrieben.
- Aktive fremde Kontexte mit Kartenbindung müssen atomar auf eine gültige explizite Bindung revidiert werden; reiner Wörterbucheintrag kann mit derselben Sense ohne aktive Kartenbindung verfügbar bleiben. Historische Kontextsnapshots bleiben unverändert. Ist keine konsistente Lösung bestätigt, blockiert der Release.
- `replaced_by` bedeutet keine Nutzerzustandsmigration. `retiredLearningIdentities` und lokale Projektion behalten den Ausschluss der exakten Sprache/Form/Sense/Funktion.

## 5. Token, Lücke, Unicode und Alternativen

Ein Token im Liefermodell:

```text
Token {
  sentence_ref, idx, surface, start_pos, end_pos, is_word,
  lemma_ref|null, sense_ref|null, card_ref|null, form_target_ref|null,
  context_gloss_de|null,
  binding_status: "unresolved"|"proposed"|"confirmed",
  provenance_ref|null
}
Gap { start_pos, end_pos, surface, sentence_text_sha256 }
Alternative { target_ref, value, substituted_text, context_sha256,
              review: "open"|"approved", reason|null }
```

Offsets sind halboffene **Unicode-Codepoint-Indizes** `[start_pos,end_pos)` im exakten NFC-Satz. Python ist maßgeblich. Browserselektion liefert zusätzlich UTF-16-Positionen und Satzhash; der Dienst wandelt um und prüft die Textstelle. Dart verwendet den vorhandenen Codepoint→UTF-16-Readerweg. Ungültige Surrogate, Teilgrapheme und Auswahl mitten im Token werden abgewiesen. Keine stillen Offsetkorrekturen nach Normalisierung. Zeilenenden im Satz sind LF; eine Änderung daran invalidiert den Text-/Kontexthash.

Die Lücke deckt vollständige zusammenhängende Worttokens ab, darf interne Leer-/Satzzeichen enthalten, aber keine disjunkten Teilstücke. `tokenize(..., lexical_spans=[gap])` führt den Übungsausdruck bei Bedarf zusammen. Der Editor kann zusätzlich die unverschmolzenen Bestandteile zum Annotieren anzeigen; gespeicherte Tokens müssen genau dem für diesen Kontext gewählten Tokenizer entsprechen. Das Ziel muss nach dem geprüften Sprachprofil genau einmal vorkommen. Mehrfachvorkommen zeigt alle Positionen, bleibt für die heutige Übungsregel aber ein Fehler; Auswahl allein hebt das Wiederholungsverbot nicht auf.

Bei Satzänderung wird ein Tokenalignment aus unveränderten, eindeutig zuordenbaren Teilspannen erzeugt. Automatisches Übernehmen nur bei gleicher Oberfläche, eindeutiger Umgebung, unveränderter Bindung und gleicher Profilversion; Mehrfachwörter, geänderte Morphologie, Lückenumfang oder Mehrdeutigkeit werden `unresolved`. Selbst übernommene Bindungen bleiben Vorschläge bis zur Kontextbestätigung. Jeder Worttoken benötigt zum Freigeben eine passende Sense, gültige Formglosse und nichtleere effektive Kontextglosse; Satzzeichen brauchen keine künstliche Übersetzung.

Alternativen sind an konkrete Karte, Satzrevision und Gap gebunden. Dienst berechnet `text[:start] + alternative + text[end:]`; geliefertes `substituted_text` muss bytegleich sein. Die Redaktion bestätigt genau diesen Satz. Änderung an Text/Lücke/Alternative öffnet das Review. Die vorhandene Antwortreihenfolge bleibt: Ziel → leere Eingabe als falsch → geprüfte Alternative als neutraler Hinweis → andere Form → Tippfehler → falsch; eine Alternative löst die Karte nicht.

Storypolicy bleibt v2: Original bevorzugen; genau ein Übungssatz; bei Ein-/Zweiwortoriginal zwingend Ersatz. Sonst Ersatz nur `target_meaning_unusable` oder `not_sentence_exercise` mit konkretem Beleg; `short_original` nur bei der kurzen Quelle. Zielidentität, Formfunktion, vollständige Tokens und geprüfte Wort-/Satzgrenzen müssen stimmen. Für neue Sprachen gelten erst deren abgenommene Zähl-/Segmentierungsregeln; keine Übernahme englischer Wortzählung ohne Profil.

## 6. Additives Content-Schema 5 und Historienabschluss

Geplante Erweiterung, keine aktuelle Schemafunktion:

| Tabelle | Neue Spalten/Zeilen |
|---|---|
| `sentences` | nullable `root_sentence_id TEXT`, `revision_sha256 TEXT` |
| `sentence_tokens` | nullable `context_gloss_de TEXT`, `context_snapshot JSONB` |
| `story_context_corrections` (neu) | `id TEXT PK`, `lang TEXT`, `identity_key TEXT`, `source_key TEXT`, `previous_fingerprint TEXT`, `next_fingerprint TEXT`, `previous_revision TEXT`, `next_revision TEXT`, `previous_context JSONB`, `next_context JSONB`, `introduced_in TEXT`, `reason TEXT` |

Das ergibt 23 Tabellen. Vorhandene Tabelle-/Spaltennamen bleiben erhalten. SQLite verwendet wie bisher JSON-Text; die additive SQL-Migration bleibt Schemaquelle für `schema.py` und den Schemavergleichstest. `context_snapshot` enthält die für die historische Tokenanzeige aufgelösten Werte `lemma`, `pos`, `sense_key`, `definition_de`, `function`, `form_label_de`; `context_gloss_de` ist die tatsächlich angezeigte Übersetzung. Referenz-IDs bleiben in den vorhandenen Spalten.

Legacy-Sätze behalten ihre alte ID, `root_sentence_id/revision_sha256=null`. Beim ersten Schema-5-Export werden ihre Tokenanzeigewerte aus dem exakten bisherigen Readerverhalten materialisiert, einschließlich historischer Filter und Rangfolge. Fehlende alte Werte werden als bestehende Lücke gemeldet, nicht erfunden. Neue/überarbeitete Kontexte müssen vollständig sein. Schema-4-Readerverhalten bleibt für Schema 4 unverändert.

Neue Satzrevision:

```text
root = bestehende root_sentence_id oder alte sentence_id
       (bei ganz neuem Text: legacy sentence_id(lang, text))
payload = {lang, text, translation_de, tokens_mit_Bindung_und_Snapshots,
           card_id, gap, accepted, valid_alternatives, profile_sha256}
revision_sha256 = canonical_sha256(payload)
new_sentence_id = stable_id("sentence_revisions",
                           lang=lang, root_sentence_id=root,
                           revision_sha256=revision_sha256)
```

Nur der **neue** Namespace `sentence_revisions` wird `KEY_FIELDS` hinzugefügt. Historische `sentences`-Schlüssel werden nicht geändert. Neue Sätze dürfen denselben Lernsprachtext besitzen, wenn der Kontextrevisionshash abweicht. Der Root muss als historische Zeile oder explizit dokumentierter synthetischer Wurzelanker nachweisbar sein; er ist keine aktive Lernidentität. Neue Token-IDs verwenden weiterhin `sentence_tokens(sentence_id, idx)`, neue Links `card_sentences(card_id,sentence_id)`. Reviewer/Zeitstempel gehören nicht in den Inhaltsfingerprint; eine wiederholte identische Revision ist keine neue Satzidentität.

Satzpayload, Tokenpayload und alte Karten-Satzlinks sind nach Freigabe unveränderlich; nur lifecyclebezogene Tombstone-/Nachfolgerfelder dürfen ergänzt werden. Gleiche neue Revision schon vorhanden: bestehende unveränderte Zeile wiederverwenden, keine doppelte ID. Aktiver Linkwechsel erfolgt erst nach vollständigem Build. Pro aktivem Ziel genau ein aktiver Link. Shared Sentence: andere Karten behalten ihre alte Bindung, bis ihre eigene Revision bestätigt ist.

`build_release` prüft den **Historienabschluss** gegen die Basis: alle bisherigen Lern-IDs bleiben auflösbar (gegebenenfalls retired); alle historischen Sätze/Token/Links bleiben inhaltlich erhalten; Registryereignisse und Storykorrekturen sind append-only; keine Reaktivierung einer Retirement-Sperre durch eine lokale Dublette. Zusätzlich wird eine sortierte Inventarliste aus IDs und unveränderlichen Payloadhashes erzeugt (`history_inventory.json`), inklusive expliziter Baseline-Altlücken. Neue Releases führen das kumulative Inventar fort. Rein lokale Notizen oder Lernstände gehören nie hinein.

Storykorrekturen werden aus bestehenden v1/v2-QA-Daten als exakte Kanten übernommen; neue Kanten dürfen keine alten verdrängen. `id` wird aus Sprache, Herkunft und den beiden Kontextfingerprints deterministisch gebildet (neuer Namespace). `(source_key, previous_fingerprint)` hat höchstens einen Nachfolger, keine Zyklen, gleiche Lernidentität. `previous_context/next_context` enthalten die vollständigen bisherigen Kandidaten-/Herkunftssnapshots, nicht nur Satztexte. Der Reader liefert eine topologisch sortierte Kette. Der Userrepository-Adapter prüft jede Kante wie bisher, fügt neuen `card_contexts`-/Herkunftseintrag an und ändert nur den aktiven Kontextzeiger. Unbekannte/revidierte Nutzersnapshots werden nicht angefasst; Boxen, Fälligkeit, Flags, Notizen und Reviewzeilen bleiben gleich.

Wichtig für übersprungene Releases: Ein lokaler Herkunftsfingerprint enthält auch die Erzeugungsrevision. Derselbe Übungskontext kann deshalb aus mehreren früheren Packversionen stammen. `history_inventory.json` führt zusätzlich einen append-only `story_source_snapshots`-Katalog der vollständigen, zum Story-Add zugelassenen Kandidaten pro freigegebenem Release. `build_release` ergänzt den aktuellen Satz dieser Kandidaten. Bei einer späteren Korrektur erzeugt die Pipeline für **jede** bekannte passende Ausgangsrevision eine exakt gebundene Kante zum neuen Kandidaten; gleiche Kontexttexte allein genügen nicht. Die App muss dann keine Guards lockern und keine fehlenden Zwischenreleases herunterladen. Ein Schema-5-Übergang importiert die belegten bisherigen QA-Kanten; nicht belegbare externe/alte Herkunftsversionen bleiben unverändert und werden als nicht automatisch korrigierbar gemeldet. Test: zwei lokale Karten gleichen Kontexts aus zwei verschiedenen Zwischenreleases, beide müssen dieselbe geprüfte Endrevision erreichen, SRS bleibt gleich.

## 7. Kanonische Lieferung und Authoring-Kontext

### JSON v4

```text
Delivery {
  format: "sprachapp.editorial-content", format_version: 4,
  delivery_id: Uuid, supersedes_delivery_id: Uuid|null,
  lang, translation_lang: "de",
  purpose: "new_deck"|"append"|"correction"|"roundtrip",
  base: Draft.base, context_sha256: Sha256,
  expected_target_refs: Ref[],
  selection: {policy: "editor-deck-v1", batches: [{number, target_refs[]}]},
  add: {<bestehende Packtabellen>: [Rohobjekte mit stabilen refs]},
  operations: Operation[], provenance: Provenance[],
  submitted_reviews: Record[], extensions: {}
}
```

`add` übernimmt die vorhandenen v2/v3-Rohobjekte und Ref-Auflösung, erweitert um Schema-5-Felder. Bestehende Pflichtfelder je Tabelle gelten für vollständige Exporte; Entwürfe dürfen fehlende Felder explizit `null` führen. Satz, Token, Card-Sentence-Link, Lemma, Sense, Dictionary, Lerngruppe in `cards.learning`, Owner, Form-/lexikalisches Ziel und Provenienz müssen enthalten oder eindeutig hashgebunden auf die Basis referenziert sein. `operations` wird für Änderungen an Bestandsobjekten verwendet. Neue und geänderte Refs dürfen sich nicht widersprechen. Veränderte Roundtrip-Zellen werden anhand der vorhandenen ID und ihres erwarteten Basishashes in explizite Operationen umgewandelt; Änderung eines Identitätsschlüssels wird als gewünschte Neuanlage mit separater Rückstellung angeboten, niemals unter alter ID überschrieben. Unbekannte Felder/Extension-Versionen bleiben in der Importquarantäne und blockieren technische Freigabe; kein stilles Wegwerfen.

`purpose=roundtrip` ist ein wiederimportierbarer redaktioneller Export ausgewählter Ziele samt vollständigem Abhängigkeitsabschluss und referenziertem Basisbestand, kein App-Release. Enthaltene Bestandsobjekte tragen `existing_id` und `expected_sha256`; unveränderte Objekte werden als „bereits vorhanden“ erkannt und nicht erneut in `add` übernommen. Roundtrip vergleicht den normalisierten Inhaltsgraphen, nicht Importzeit/Reviewstatus. Fremde Sprache in `add` oder Querverweis auf eine andere Sprachbasis ist ein Fehler.

Provenienz: `{ref, kind: "external"|"manual"|"existing", source_label, supplied_at, source_record_ref, notes}`. Keine personenbezogenen Lernstände, Anmeldedaten, Absolutpfade oder Secrets. Extern erzeugte Herkunft bedeutet nicht fachlich geprüft. Angebliche Anweisungen im Dateitext werden als Daten angezeigt, nie ausgeführt.

### ZIP

Feste Einträge: `delivery.json`, `FORMAT.md`, `editorial_content_v4.schema.json`, `authoring_context.json`, `files.sha256.json`; optional `editor.xlsx` als **Alternative**, nicht zweite Autorität. Wenn JSON und XLSX enthalten und inhaltlich verschieden: Konflikt, Nutzer wählt ausdrücklich eine Quelle für einen neuen Previewjob. Keine automatische Zusammenführung.

Der Kontext enthält Profilfähigkeiten, ausgewählte Sprache/Übersetzungssprache/Thema, Basisfingerprints, vorhandene Ziele einschließlich retired Identitäten, Bedeutungsdefinitionen, relevante Formglossen, Owner-/Alias-/Gruppen-/Forminformationen und reservierte Refs. Zur Vermeidung von Dubletten wird ein vollständiger kompakter sprachbezogener Identitäts-/Besitzindex beigefügt; ausführliche Glossenkontexte werden auf relevante Einträge beschränkt. Kontext ist eine abgeleitete Momentaufnahme, kein zweiter Master. Alle referenzierten Teildateien haben Hashes. Keine echten `user.db`, Quellcodeausführung oder Cloudzugangsdaten. Eine Vorlage enthält leere Felder mit Erklärungen und stabile Refslots, aber keine neu erfundenen Sprachinhalte.

Bestehende `export_authoring_context.py::export`/Formexport-/`verify_zip`-Prüfungen werden als gemeinsame Hilfen herausgelöst und erweitert; der heutige fest englische Assetpfad und komplette Quellcode-/Modellbeigaben sind nicht unverändert das neue Standard-Chatpaket. Alte ZIPs bleiben über Legacyadapter prüfbar, enthaltene Skripte werden beim Import nie ausgeführt.

Uploadgrenzen geplant: JSON 25 MiB, XLSX/ZIP jeweils 50 MiB komprimiert, 200 MiB insgesamt entpackt, 2.000 ZIP-Einträge, Verhältnis höchstens 100:1 und keine verschachtelten Archive. Keine absoluten Pfade, `..`, Symlinks oder Doppelnamen. Alle Grenzen gelten schon beim Lesen, nicht nach vollständigem Entpacken. Verletzung führt zu verständlichem Größen-/Formatfehler ohne Bestandsänderung. Vorschau maximal 1.500 Zielrefs pro Lieferung, Chunks ≤100; größere Lieferungen vor Import ausdrücklich teilen, nicht abschneiden.

### XLSX v1: vollständiger und einfacher Modus

Geplante Bibliothek `openpyxl` (erst Paket 2 installieren/pinnen). Nur `.xlsx`, keine `.xlsm`, Makros, externen Links oder eingebetteten Objekte. Formeln werden nicht berechnet oder als Inhalt übernommen; Formelzellen erhalten Feldfehler. Text, der mit `=`, `+`, `-` oder `@` beginnt, wird als expliziter String exportiert, ohne den fachlichen Text zu verändern. Ref/ID/Hash/Sprachcodes sind Textzellen; Zahlen nur für definierte Ganzzahlfelder. Keine stillen Datum-/Zahlkonvertierungen von Wörtern.

| Blatt | Pflichtspalten / Mapping |
|---|---|
| `Meta` | key/value für workbook_format=1, delivery_id, purpose, lang, translation_lang, Basis-/Kontexthashes, completeness=`full` oder `draft` |
| `Ziele` | ref, existing_id, expected_sha256, form, translation_de, lemma_ref, sense_ref, identity_function, introduction_scope, sentence_ref; übrige Kartendaten in `payload_json` |
| `Saetze` | ref, existing_id, expected_sha256, text, translation_de, provenance_ref; Restpayload für Metadaten |
| `Luecken` | target_ref, sentence_ref, gap_start, gap_end, surface, sentence_text_sha256, position; akzeptierte Bestandsfelder in `payload_json` |
| `Tokens` | sentence_ref, idx, start_pos, end_pos, surface, is_word, lemma_ref, sense_ref, card_ref, form_target_ref, context_gloss_de, binding_status, provenance_ref; Snapshotrest in `payload_json` |
| `Alternativen` | target_ref, ordinal, value, substituted_text, context_sha256, submitted_review, reason |
| `Lemmas` | ref, lemma, pos; Restpayload |
| `Bedeutungen` | ref, lemma_ref, sense_key, gloss_de, definition_de; Restpayload |
| `Formglossen` | ref, form, sense_ref, gloss_de, card_ref, rank; Restpayload |
| `Stapel` | ref, slug, title_de, description_de, practice_kind; Restpayload |
| `Bindungen` | table, record_ref, payload_json für deck_cards/deck_words/word_aliases/card_lexical_targets/form_targets/deck_practice_targets/lexical_targets |
| `Gruppen` | target_ref, group_id, primary_card_id, topic, related_json, note; vollständiges `cards.learning` |
| `Herkunft` | ref, kind, source_label, supplied_at, source_record_ref, notes |
| `Operationen` | op_id, kind, target_ref, expect_json, payload_json, reason |
| `Records` | table, record_ref, payload_json für weitere zugelassene Rohdaten wie stories/story_sentences/story_context_corrections; kein ausführbarer Inhalt |

`payload_json` enthält nur Felder, die keine eigene Spalte haben; doppelte Definitionen sind Fehler. Schema-/Spaltenbeschreibung steht im Blatt `Anleitung`. Jedes JSON-Objekt und jede Liste wird vollständig transportiert; Excel-Zellgrenze 32.767 Zeichen wird vor Export geprüft. Überschreitung blockiert **XLSX-Vollständigkeit** und bietet ZIP/JSON an, nie Abschneiden. Unbekannte Tabellen/Spalten werden als nicht unterstützte Erweiterung gemeldet; vorhandene Daten bleiben in der Quarantänedatei erhalten.

Einfachimport braucht nur `Meta` und `Ziele` mit ref, form, translation_de, sentence_text und sentence_translation_de. Er ist ausdrücklich `completeness=draft`. Der Adapter erzeugt stabile draftlokale Satzrefs aus delivery_id/target_ref; fehlende Token-/Sense-/Gap-/Alternativenangaben bleiben offen, nicht geraten. Ein fehlendes Alternativenblatt bedeutet **unbekannt**, nicht automatisch „keine Alternativen“. Im vollständigen Modus erklärt eine explizite leere Liste „redaktionell keine vorgesehen“. Der normale Tabellenexport aus dem Dashboard ist immer `full`, wenn der Abhängigkeitsabschluss darstellbar ist; sonst klar gekennzeichnet `draft` mit Blockerbericht.

## 8. Importvorschau, Idempotenz und Teilmengen

```text
Inventory {
  expected: int, parsed: int, processed: int, unresolved: int,
  new_refs[], existing_refs[], conflicting_refs[], incomplete_refs[],
  chunks: [{number, expected_refs[], state, report_sha256|null}]
}
ImportReceipt { import_id, delivery_id, payload_sha256, base_sha256,
                draft_id, draft_revision, inventory, completed_at }
```

Die Idempotenz gilt über die Laufzeit des Dienstes hinaus: Journal speichert `(lang, delivery_id, canonical_payload_sha256)` und den Beleg. Gleiche ID/gleicher Hash liefert denselben Beleg, auch wenn der Entwurf inzwischen lokal korrigiert wurde; die korrigierten Zellen werden nicht zurückgesetzt. Gleiche ID/anderer Hash → `DELIVERY_ID_REUSED`, 409. Neue Lieferung mit schon vorhandenem Ziel → Reuse bzw. Konflikt anhand vollständiger Identität; nicht nochmal anlegen. Korrektur benötigt neue delivery_id, `supersedes_delivery_id`, stabile Bestandsreferenzen und aktuelle Preconditions.

Preview verändert keinen Entwurf. Übernahme schreibt genau einen Gesamtentwurf mit allen lesbaren Datensätzen und sämtlichen Blockern. Ein beschädigter Container wird als Ganzes abgelehnt; valide Container mit Feldfehlern dürfen bewusst als unvollständiger Entwurf gespeichert werden. Beim Jobabbruch bleiben vorhandene Draftrevision und gültiger Bestand unberührt; Wiederaufnahme nutzt gespeichertes Inventar. Teilchunks sind interne Arbeitsstände. Ein Release verlangt `parsed=processed=expected`, keine fehlende Zielref, keine Konflikte, alle geforderten Prüfungen und lokale Reviews. Die bestehende 100er-/1.500er-Grenze wird angezeigt; keine stillen zusätzlichen Batches oder Vollständigkeitsbehauptung.

## 9. Lokale HTTP-API

Alle Routen unter `/api/v1`; JSON UTF-8, keine frei wählbaren Dateipfade. `POST` benötigt Origin, CSRF, idempotenten Requestkey; Mutationen bestehender Drafts zusätzlich If-Match. Long-running-Routen liefern 202 mit job_id, Fortschritt und erlaubtem Abbruch. Reiner Vorschau-/Validierungsjob darf nicht parallel eine neuere Draftrevision überschreiben.

| Route | Eingabe → Ergebnis |
|---|---|
| `POST /session/bootstrap` | einmaliger Fragmenttoken und eigener Origin → Sessioncookie und CSRF-Token |
| `GET /languages` | Sprachentwürfe und Fähigkeiten |
| `POST /languages` | lang/display_name/name_native/translation_lang → LanguageDraft |
| `GET /catalog?lang=&q=&status=&cursor=&limit=` | max. 100 Ziele pro Seite, Gesamtsummen und stabile Sortierung |
| `POST /authoring-contexts` | lang, topic, selected_refs, base, requested_count → ZIP-/XLSX-Vorlage als Jobartefakt |
| `POST /imports` | begrenzter Multipart-Upload, lang, target_deck_ref|null → Quarantäne und Previewjob |
| `GET /imports/{id}` | Inventar, neu/vorhanden/konflikt/unvollständig und lokalisierte Fehler |
| `POST /imports/{id}/accept` | preview_sha256, mode=`new_draft` oder `append_to_draft`, optional draft_id/If-Match → ImportReceipt |
| `POST /drafts` | lang, base, optional deck_ref → Draft |
| `GET /drafts/{id}` | gespeicherte Revision, ETag, Status |
| `POST /drafts/{id}/operations` | Operation[] → neue Revision und invalidierte Reviews |
| `POST /drafts/{id}/tokenize` | text, profile_id, previous_context_hash, UTF-16-Auswahl|null → Tokens/Gap/Vorschläge, keine automatische semantische Freigabe |
| `POST /drafts/{id}/validate` | revision → Job/Validation |
| `POST /drafts/{id}/reviews` | scope, payload_sha256, reviewer, reason → Review nach Hashprüfung |
| `GET /drafts/{id}/diff` | Basis/Entwurf bzw. aktuelle Basis als dreiseitiger Vergleich |
| `POST /drafts/{id}/rebase` | neue base, je Konflikt explizite Entscheidung → neue Revision, Prüfungen offen |
| `POST /drafts/{id}/discard` | erwartete Revision → archiviert; kein Release gelöscht |
| `POST /drafts/{id}/exchange` | format=`zip`/`xlsx`, selection → verlustfreies redaktionelles Exportartefakt |
| `POST /drafts/{id}/releases` | revision, validation_sha256, gewünschtes Versionslabel → lokaler Buildjob |
| `GET /jobs/{id}`, `POST /jobs/{id}/cancel` | Jobzustand/Abbruch; keine teilweise Veröffentlichung |
| `GET /artifacts/{uuid}` | nur serverregistrierte eigene Artefakte, sicherer Downloadname |
| `POST /releases/{id}/publish` | erst Paket 3: Kanal, erwartete Generation/Manifesthash → Publishjob |

Fehlerformat:

```json
{"code":"TOKEN_GLOSS_MISSING","message":"Die Übersetzung dieses Wortes fehlt.",
 "severity":"error","location":{"file":"editor.xlsx","sheet":"Tokens","row":18,
 "record_ref":"draft-ref","field":"context_gloss_de"},
 "retryable":false,"draft_revision":12}
```

Weitere Codes: `BASE_CHANGED`, `ENTITY_CHANGED`, `OWNER_CONFLICT`, `AMBIGUOUS_SENSE`, `GAP_REPEATED_TARGET`, `OFFSET_INVALID`, `PROFILE_UNSUPPORTED`, `REVIEW_STALE`, `DELIVERY_ID_REUSED`, `INCOMPLETE_BATCH`, `FORMAT_UNSUPPORTED`, `HISTORY_LOSS`, `UPLOAD_LIMIT`, `STORAGE_FAILURE`. 400 Syntax, 401 Sitzung, 403 Origin/Rechte, 409 Konflikt, 413 Größe, 422 technische/fachliche Blocker, 428 If-Match fehlt, 503 temporäre Ressourcen. Keine Tracebacks oder Secrets im Browser.

### Loopback-Schutz

Bindung ausschließlich `127.0.0.1`, zufälliger freier Port. Exakter Hostcheck einschließlich Port; keine Wildcards/Proxyweiterleitungen. Server öffnet Browser mit einmaligem kurzlebigem Bootstrap-Token im URL-Fragment. Statische JS liest/entfernt das Fragment und tauscht es einmalig gegen HttpOnly/SameSite=Strict-Sessioncookie und CSRF-Token. Token wird nicht geloggt; bei deaktiviertem Browserstart wird die einmalige lokale URL im Terminal ausgegeben. HTTP nur Loopback, keine Behauptung eines Secure-Cookies über ungesichertes HTTP; keinerlei LAN-Freigabe.

Schreiben nur mit passender eigener Origin, Session und Custom-CSRF-Header; `Origin:null`, fehlender Origin bei Browsermutation und fremde Origins abweisen. Kein CORS, keine zustandsändernden GETs. CSP nur eigene Skripte/Styles/Verbindungen, `frame-ancestors 'none'`, kein HTML aus Inhaltstexten. Uploads bleiben Daten; feste Dateinamen/UUID-Containment und Größenlimits. Dienst ruft keine vom Nutzer gelieferten Shellstrings auf. Ein notwendiger Dart-Stage-Prozess hat feste Executable/Argumentstruktur, `shell=false` und servergenerierte Pfade.

## 10. Lokaler Build, Konflikte und Releasebundle

`build_release(draft_id, expected_revision, validation_sha256)` führt aus:

1. Prozess-/Draftlock, Basisbytes und alle Fingerprints erneut prüfen; aktuelle lokale Sprach-Headbindung prüfen. Veraltete Entwürfe benötigen expliziten Rebase.
2. Vollständige Lieferinventare, Sprachfähigkeiten und gültige lokale Reviews kontrollieren. Gemeinsame Operationen auf Basis-Kopie anwenden; bisherige v2/v3-/Targeted-Verträge über Adapter wiederverwenden.
3. Schema-5-Revisionen/Snapshots erzeugen; vollständiges `build_rows`, Inhalts-/Gruppen-/Registry-/Form-/Story-/Alternativen-/Linterprüfung; keine KI. Historiensuperset gegen Basis bestätigen.
4. `export_sqlite` in ein neues temporäres Releaseverzeichnis; Tabellen-/Spalten-/Zeilenreadback gegen die erwarteten Rows, SQLiteintegrität, Dartreader-/Stageprüfung. Keine automatische Assetänderung.
5. Manifest/Inventar/Report erzeugen, alle Handles schließen, temporäres Verzeichnis als neue unveränderliche Release-ID finalisieren; erst dann lokalen Head per CAS aktualisieren. Bestehender Versionsname oder abweichender Inhalt unter gleicher ID ist Konflikt.

Rebase übernimmt nur konfliktfreie **unveränderte** Operationen nach erneuter Preconditionprüfung und zeigt verbleibende Konflikte; keine semantischen Entscheidungen automatisch auf neue Senses übertragen. Alle betroffenen Freigaben öffnen. Basen/alte Releases bleiben erhalten.

Bundle: `pack.json`, `content.sqlite`, `content.manifest.json`, `registry.json`, `history_inventory.json`, `finalization_report.json`, `editorial_reviews.json`, `provenance.json`. Release-ID ist eine UUID; Label menschenlesbar und innerhalb Sprache eindeutig. Manifest bindet Bytehashes des JSON/SQLite und kanonische Inhalts-/Registry-/Inventar-/Reviewhashes; ZIP-Metadaten oder Uhrzeiten sind kein fachlicher Fingerprint. Rebuild ist fachlich deterministisch, aber SQLitebytes können sich wegen Exportzeit unterscheiden; publiziert wird deshalb stets das bereits geprüfte immutable Bundle, nicht ein späterer Neubuild unter derselben ID.

## 11. Veröffentlichung und Manifest 2 (Paket 3)

```text
ReleaseManifestV2 {
  format: 2, release_id, lang, translation_lang, version, schema_version: 5,
  channel: "internal", generation: int,
  parent_release_id, parent_manifest_sha256,
  min_reader_version: int, required_features: string[],
  profile_id, profile_sha256,
  sha256, size_bytes, pack_json_sha256, registry_sha256,
  history_inventory_sha256, editorial_reviews_sha256,
  internal_test_pack: true, created_at, notes
}
```

`sha256/size_bytes` gelten für SQLite. `generation` wird ausschließlich serverseitig bei erfolgreicher Veröffentlichung zugeteilt, streng monoton pro `(lang,channel)`, nicht aus Versionslabels verglichen. Der lokale Export enthält einen Manifestentwurf ohne Generation; Server bestätigt die unveränderlichen Felder und erzeugt daraus das endgültige Manifest. Dessen Hash ist extern im Kanalzeiger, nicht selbstreferenziell im Manifest. Die innere `content_releases.version/schema/lang` muss passen; eigene SQLite-SHA wird nicht in die SQLite hinein rückgekoppelt. Readerfähigkeiten sind monotone Protokollfähigkeiten, nicht lexikografisch verglichene Appversionsstrings.

### Private Infrastruktur und Rechte

Neue Tabellen im nicht öffentlich schreibbaren Distributionsbereich: `content_readers(user_id,channel,lang)`, `content_publishers(user_id)`, `content_release_uploads`, `content_release_catalog`, `content_channels`, `content_publish_audit`. `content_channels` hat PK `(lang,channel)`, Generation, release_id, manifest_sha256. `content_release_catalog` speichert immutable Metadaten, geprüfte Storagekeys, Status und Uploadowner. Rechte nicht aus selbständerbaren User-Metadaten ableiten. Normaler Tester ist niemals Publisher.

Neuer privater Bucket `content-private`; kein Upload in vorhandenes öffentliches `packs`. Keine direkten Client-Schreibpolicies; Leser nur über kontrollierte Berechtigung bzw. kurzlebige signierte Download-URL. Edge prüft JWT und Rollenliste vor jeder Aktion. Servercredentials bleiben in der Functionumgebung. Publisher und Flutter melden bestehende Benutzer mit E-Mail/Passwort über Supabase Auth an; E-Mail-OTP bleibt eine ausdrücklich gewählte Alternative bei geprüfter Zustellung. Passwortlogin setzt weder OTP noch SMTP voraus und registriert keine Benutzer. Tokens bleiben beim Publisher nur im Pythonprozessspeicher, erneute Anmeldung nach Neustart; Flutter speichert ausschließlich die Supabase-Session im sicheren Plattform-Sessionspeicher. Eingabepasswörter werden nicht gespeichert/protokolliert und nach erfolgreicher Anmeldung aus dem Formular entfernt. Publisher-Authanfragen liegen außerhalb des lokalen Idempotenzcaches. Projekt-URL und öffentlicher Authclientkey sind Konfiguration, keine Schreibberechtigung. Weder Browser noch Flutter bekommen Service-Role- oder Publisherprivilegien. Einmaliges administratives Passwortsetzen für die bestehende UID ist vom Editor getrennt und in [content-password-login.md](content-password-login.md) beschrieben.

API (geplant):

| Route | Verhalten |
|---|---|
| `POST /content-publish/start` | JWT+Publisherrecht, lokale Bundlemetadaten, lang/channel, Basisrelease/-hash → Upload-ID und begrenzte private Uploadberechtigung für exakt diese unveränderlichen Objekte |
| `POST /content-publish/{id}/finalize` | Objektgrößen/-hashes, Bericht/Inventar/Reviewbindungen prüfen; Zustand `verifying/ready/failed`, idempotent |
| `POST /content-publish/{id}/commit` | erwartete Generation und Parentmanifesthash; transaktionale RPC veröffentlicht nur `ready` |
| `GET /content-publish/{id}` | Eigentümer/Publisher erhält Status nach Retry/Verbindungsabbruch |
| `GET /content-release?lang=&channel=&generation=` | gültiges Leserrecht → kein Update oder Manifest/Hash; keine anonymen Metadaten interner Packs |
| `POST /content-release/{id}/download` | Leserrecht/Sprachfreigabe erneut prüfen → kurzlebige URL für genau den Packhash |

Server prüft tatsächlich die hochgeladenen Bytegrößen/Digests, Objektnamen, Rollen, Basis/Registry-/Inventarverkettung und die Vollständigkeit der authentisierten Freigabeberichte. Er führt **keinen zweiten linguistischen Validator** in TypeScript ein. Der Publisher ist die autorisierte Redaktion; dessen Bericht über fachliche Pipelineprüfung ist eine gebundene Attestation, kein unabhängiger serverseitiger Semantikbeweis. Die App validiert den SQLiteinhalt unabhängig vor Aktivierung. Ein Publisher mit absichtlich falsch attestiertem Inhalt ist durch Rechte-/Auditentzug zu behandeln, nicht durch vorgetäuschte serverseitige Sprachprüfung.

Maximaler Packdownload zunächst 256 MiB; Server/Storagegrenzen konsistent konfigurieren. Größere Packs werden ausdrücklich abgewiesen, keine Teilveröffentlichung. Hashprüfung gestreamt; für lange Finalisierung persistenter Status und fortsetzbare Requests, kein Erfolg nach bloßem Upload. Objekte nach erfolgreicher Prüfung unveränderlich; Commit prüft deren gespeicherten Digest/Status. Uploadberechtigung darf keine vorhandenen finalisierten Objekte überschreiben.

RPC `publish_content_release(upload_id, expected_generation, expected_manifest_sha256, request_id, verified_actor_id)` ist ausschließlich für die serverseitige Functionrolle ausführbar; `verified_actor_id` stammt aus der zuvor verifizierten JWT, niemals aus dem Browserpayload. Sie prüft erneut Publisher, Uploadstatus und vollständige Scopebindung, sperrt die Kanalzeile, vergleicht CAS, schreibt Release/Kanal/Audit in einer Transaktion. Erster Kanal hat erwartete Generation 0 und null Parent. Retry derselben request_id liefert den bestehenden Release; anderer Upload unter derselben ID ist Konflikt. Paralleler Verlierer erhält 409. Verwaiste unpublizierte Uploads können nach Ablauf gelöscht werden; veröffentlichte Historie bleibt erhalten. Kein ABA-Problem durch monoton steigende Generation.

TLS und authentisierte Manifestabfrage bilden die Vertrauensgrenze; ein SHA allein authentifiziert keinen Herausgeber. Download-URLs sind Bearertokens, kurzlebig, nicht loggen oder im exportierten Bundle speichern. Alte installierte Packs bleiben offline nutzbar, auch bei abgelaufener Anmeldung. Rechteentzug verhindert neue Downloads, kann bereits verteilte Offlinebytes nicht rückwirkend zurückholen.

## 12. Installation, mehrere Sprachen und Recovery

Geplante Zustandsmaschine je Sprache:

```text
idle → checking → available → downloading → verifying → ready_waiting
     → quiescing → activating → active
Fehler vor active → alter gültiger Stand bleibt aktiv
```

Layout im App-Supportverzeichnis: `content/<lang>/generations/<release-id>/content.sqlite` plus geprüftes Manifest/Inventar; `active.json`, `previous.json`, `install-journal.json`. Sprache wird validiert und nicht als unkontrollierter Pfad verwendet. Für initiales Englisch wird das bestehende Format-1-Asset nach bisheriger Prüfung als Bootstrapgeneration übernommen. Neue Sprache ohne Asset zeigt „Noch nicht installiert“, nicht englischen Inhalt. Neustart öffnet zuerst eine gültige aktivierte Generation, Asset nur beim echten Bootstrap bzw. nach bewiesener kompatibler Rückfallentscheidung.

1. Manifest authentisiert abrufen, Sprache/Kanal/Generation/Readerprofil/Größenlimit prüfen. Generation muss größer als die zuletzt aktivierte Generation derselben Sprache sein; gleiche Generation darf nur denselben Manifesthash tragen. Der lokale High-Water-Mark wird mit dem Aktivierungsjournal atomar fortgeschrieben. Keine Inhaltsaktivierung während Authfehler; vorhandener Offlinepack bleibt benutzbar.
2. Download in `.part`, Streaminghash und Bytezähler. Resume nur mit demselben Releasehash und passendem Server-ETag; sonst neu beginnen. Speicherplatz für aktiven, Kandidaten und Recoverybestand vorab prüfen, keine aktive Datei für Platzgewinn löschen.
3. Datei flushen/schließen, Digest/Größe prüfen. SQLite in Hintergrundisolate read-only öffnen, `quick_check`, erforderliche Spalten, genau eine passende Releasezeile, Sprachzeile, vollständige Inhalts-/Form-/Kontextprüfungen. Nur erwartete Tabellen/Indizes; keine Trigger/Views oder Schreibaktionen aus Packdaten. Inventar und Historiensuperset gegen installierten Stand und referenzierte lokale Karten/Reviewkontexte prüfen. Candidatehandle schließen.
4. `ready_waiting`: Lernen mit bisheriger Generation bleibt möglich. Session hat explizit `(lang, generation, profile_id, contentLease, userFacade)`. Update/Sprachwahl ersetzt weder Queue noch Rückblick. Ungespeicherter Review/Retrystate blockiert Übergang; keine versteckte Zwangsbeendigung.
5. Sicherer Übergang nach beendetem/ausdrücklich verlassenem Durchgang: Aktivierungslock, neue Contentleases sperren, auch Reader-/Sheetleases lösen, Close-Barriere abwarten. Closefehler blockiert und erhält alten Zeiger. UserDatabase bleibt geöffnet.
6. Journal enthält alte/neue Manifesthashes und Zustand `prepared`. Kandidat liegt als unveränderliche geschlossene Generation bereit. Neuer aktiver Zeiger wird über Tempdatei/Flush/atomaren Ersatz geschrieben; keine Ersetzung einer geöffneten SQLite. So funktioniert der Übergang auch unter Windows.
7. Neue Repositorygeneration öffnen und Provider konsistent umschalten. Bei Openfehler vor Benutzerzugriff alten Zeiger wiederherstellen. Erst erfolgreiche Öffnung markiert `committed`; anschließend dürfen Sessions/Storykorrekturen starten. Danach nur Vorwärts-Reparatur, kein stiller Downgrade.

Startup-Recovery prüft Journal und beide Zeiger: unvollständiger Download wird verworfen/fortgesetzt; `prepared` ohne neuen Zeiger lässt alten aktiv; neuer gültiger Zeiger ohne Abschluss wird zunächst vollständig geprüft und fertiggestellt, bevor ein Nutzerzugriff erlaubt wird. Ein defekter Kandidat ohne bisherigen Nutzerzugriff fällt auf vorherigen gültigen Stand zurück. Nach `committed` können neuere Lernstände existieren; Rückfall erfordert Historiensuperset. Wenn kein kompatibler Pack vorhanden ist, Nutzerzustand erhalten, betroffene globale Übungen als nicht verfügbar markieren, vorhandene vollständige lokale Storykontexte weiter anbieten; Reparaturdownload ermöglichen. Keine Datenlöschung oder SRS-Neuanlage.

### Sprachgetrennter Lernstand

Eine physische `user.db` behalten, ein gemeinsamer DB-Owner; mehrere `DriftUserRepository(db, lang: ...)`-Fassaden. Alle Karten-/Bindings-/Aktivitäts-/Reviewabfragen müssen Sprache explizit filtern oder vorher nachweisen, dass jede angefragte ID dieser Sprache gehört. Schreibzugriff auf fremde ID wird abgewiesen. Neue Sprachprofile übernehmen keine englischen Boxen, Registryeinträge oder Gruppen.

Paket 3 plant User-Schema 6 für `language_learning_preferences(lang TEXT PK, daily_goal INTEGER NOT NULL, include_diacritics BOOLEAN NOT NULL, show_grammar BOOLEAN NOT NULL)`; bestehende Werte initial nach `en` kopieren, UI-Motiv und Auto-Weiter bleiben global. Die bisher festen `base/past/past_participle`-CHECKs an `UserCards.formFunction` und `FormLearningBindings.function` werden in derselben Migration durch Nichtleer-Prüfungen ersetzt; erlaubte Codes prüft das sprachbezogene Domainprofil vor jedem Write. Ein dafür erforderlicher Drift-Tabellenrebuild kopiert alle Zeilen und Werte unverändert und stellt Constraints/Indizes/Trigger wieder her; er ist keine Neuinitialisierung des Lernstands. Reviews bleiben unverändert. Migration nur atomar mit vorherigem lokalen DB-Backup und getesteter Wiederaufnahme; bei Fehler kein Profilwechsel. Sprachwahl wird separat gespeichert, während der Session eingefroren. Contentprovider werden nach `(lang,generation)` parametrisiert, Userfassade nach `lang`, UserDatabaseowner bleibt global. Alle vier Vokabelzähler und Tagesprojektionen weiter aus dem jeweiligen Zustand ableiten, keine Zählerspalten.

## 13. Rücknahme und weitere Releasekompatibilität

`rollback` ist keine Kanaloperation auf ein altes Release. Die Redaktion erzeugt auf aktueller Basis einen neuen Reparaturdraft, bewahrt alle neu eingeführten Identitäten/Kontexte, stellt fehlerhafte Aufgaben zurück und revidiert aktive Kontexte. Version/Generation steigen. Bereits gelernte neuere Karten behalten Zustand und Historie; lokale Storykorrekturketten bleiben vollständig. Auf Wunsch wiederhergestellter alter Wortlaut erscheint als neue oder bereits vorhandene unveränderte Kontextrevision, nicht als Löschung neuerer Geschichte.

Ein übersprungener Release darf keine notwendige Migration voraussetzen: Pack führt kumulative historische Daten/Registryevents/Storykorrekturen. Appprüfungen kontrollieren Übergang vom tatsächlich installierten Stand, nicht nur vom unmittelbaren Serverparent. Unbekanntes Schema/Profil → „App-Aktualisierung erforderlich“, Pack nicht aktivieren. Neue Sprachen benötigen erst einen passenden geprüften Codeadapter; ohne ihn bleibt ein Downloadangebot unlernbar und wird vor Installation blockiert.

## 14. Umsetzungseigentum und Abnahme

**Paket 2:** Abschnitte 1–10 einschließlich Sprachentwürfen, kanonischer Lieferung, ZIP/XLSX, Tabellenworkflow, Kontextrevisionen und lokalem Reader/Staging. Dateien und genaue neue Tests stehen im Plan Abschnitt 8. Insbesondere vorhandene `content_contract.py` und die erwähnten gemeinsamen Validatoren erweitern, keine zweite Validierungsimplementierung im Editor. Profile nicht allein durch Konfiguration als unterstützt erklären.

**Paket 3:** Abschnitte 11–13 sowie lokale Publisheranbindung, Auth, mehrere installierte Sprachpacks, sprachbezogene Lernpräferenzen und App-Aktivierungsprotokoll. Verwendet das geprüfte Bundle aus Paket 2 unverändert. Auth-/Storage-/Dartabhängigkeiten erst dort auswählen/pinnen und testen; kein Cloudsetup in Paket 2.

Verbindliche End-to-End-Abnahme zusätzlich zu Unit-/Vertragstests:

1. Vorbereitete 250-Ziel-Lieferung importieren, zwei Sätze und einen Lösungshinweis ändern; alle Abhängigkeiten prüfen/bestätigen, komplett exportieren/stagen. Unverarbeitete Zeilen verhindern Freigabe.
2. Identische Lieferung nochmals importieren: kein zusätzliches Ziel, lokale Korrekturen bleiben erhalten. Korrekturimport mit neuer ID und alter Basis zeigt Konflikt.
3. Weitere Sprache als Entwurf mit synthetischen Zielen derselben Schreibweise anlegen: weder englische Identitäten noch Lernstände wiederverwenden. Fehlende Sprachfunktionen verhindern Release; geprüfter Testadapter weist Sprachisolation nach.
4. Fehlerhafte/unvollständige Tabellenlieferung zeigt Datei/Blatt/Zeile/Feld und speichert bei gültigem Container einen unvollständigen Entwurf; gültige Basis bleibt unverändert.
5. Vollständiger ZIP/JSON- und XLSX-Export wird erneut importiert: Bindungen, Lücke, Alternativen, Gruppen, Formfunktionen und Herkunft sind kanonisch identisch; redaktioneller Status bleibt separat.
6. Historien-/Storyketten-, CAS-/Rollen-, Crash-/Session- und Offlinefälle entsprechen A6–A8 und B1–B7 im Plan. Alle Tests nutzen synthetische Daten/temporäre DBs.

Offene technische Routineentscheidungen werden durch diese Verträge festgelegt. Keine zusätzliche Umsetzungskategorie erforderlich: Der Sprach-/Importumfang vergrößert Paket 2, Mehrpack-/Lernzustandsisolation Paket 3. Die einzige notwendige Grenzpräzisierung ist der Schema-5-Reader bereits in Paket 2, da dessen Export sonst nicht mit dem tatsächlichen Dart-Staging abnehmbar wäre.

## Implementierungspräzisierungen Paket 2 – 16.10.2026

Nachweise, Bedienung und Grenzen: [Abschlussbericht](content-editor-package-2.md). Die vorherigen Istbelege beschreiben den Planungszeitpunkt; sie sind keine Behauptung über den jetzigen Arbeitsbaum. A1–A7 und der macOS-Anteil von A8 sind geprüft; Windows-Geräte-/Browserabnahme bleibt offen.

- Der gemeinsame fachliche Kern liegt in `authoring_service.py`; `EditorService` übernimmt Persistenz, UI-Projektionen und Jobs. `build_release(draft, base, directory, *, version, expected_validation, progress)` ist die konkrete Kernsignatur; Draft-ID/ETag werden vorher im lokalen Service aufgelöst. Legacy-CLI-Einstiege bleiben unverändert und nutzen weiterhin dieselben bestehenden Validatoren/Exporter. Kein erzwungener Umbau aller Importer.
- Dateizuschnitt: `editor/xlsx.py` statt `xlsx_exchange.py`; `web/app.js` und `web/style.css` statt fünf separater JS-Dateien/`styles.css`. Zusätzlich `tool/editor_content_pack.dart` für echte Readerinventare und den bestehenden Stagingadapter sowie drei synthetische Fixtures unter `test/fixtures/editor_*`. `form_content_validation.dart`, Userrepository, Resolver und Stagingwerkzeug benötigen keine Änderung.
- English-Answer-Verhalten bleibt unverändert: Zieltreffer, danach leere Eingabe falsch, danach geprüfte Alternative, andere Form, Tippfehler, falsch. Das Profil deklariert die vorhandenen Fähigkeiten; Paket 2 verdrahtet keine neue Antwortlogik in Sessions. Unbekannte Sprachprofile erlauben manuelle Entwürfe und blockieren sprachabhängige Freigabe.
- Speicherung konkret: Metadatensätze als `<kind>/<id>.json`, Draftrevisionen unter `drafts/<id>/revisions/` mit atomarem Pointer, unveränderliche Bundleverzeichnisse unter `bundles/<id>/`, sprachbezogene Basis-/Headreferenzen. Die HTTP-Routen stehen explizit in `server.py::route`; strukturierte Projektionsrouten (`target`, `story-target`, `vocabulary`, `story-history`) ergänzen die allgemeinen Commands. Browser setzen keine Dateipfade.
- Vollständiger Austausch verwendet hashgebundene `roundtrip_records` für Basisobjekte. `existing_id` ist hier der kanonische Rohobjektfingerprint; Entity-IDs werden beim bestehenden Rowbuild aufgelöst. Identitätsänderungen unter alter Referenz blockieren und verlangen ausdrückliche Neuanlage. Neue UI-Aufgaben bleiben als `create_target` im Blatt `Operationen` vollständig erhalten; `Ziele` enthält die additiven Kartenzeilen. Beides zählt zur Gesamtzielmenge. Flüchtige Suchvorschläge (`candidates`) sind keine redaktionellen Inhaltsdaten und werden nicht exportiert.
- XLSX hat ein hartes Zelllimit von 32.767 Zeichen. Eine Überschreitung erzeugt einen konkreten Fehler; ZIP kann in diesem Fall ohne die optionale XLSX-Kopie erzeugt werden, behält jedoch das vollständige kanonische JSON und einen Hinweis. Unbekannte Felder werden mit Originalupload quarantänisiert, nicht still entfernt oder freigegeben.
- Der Revisionshash verwendet kanonisches JSON nach `word_registry.digest`, auch `sentence_text_sha256` hasht den JSON-String. Das tatsächliche `context_payload` umfasst die sortierten Token und Linkliste. Legacy-IDs werden nicht neu berechnet. Vollständige reale Readerinventare sind Autorität für eingefrorene Anzeigen; neu angelegte Kontexte dürfen keine Legacy-Lückenmarkierung einschleusen.
- Registryformat 1 bleibt unverändert. Paket 2 reserviert neue Identitäten und erlaubt geprüfte ungeteilte Singleton-Rückstellung. Gruppen-/Owner-/Form-/fremde Kontextbindungen liefern konkrete erforderliche Folgeentscheidungen und blockieren ohne konsistente Lösung. Die skizzierte generelle Registryformat-2-Neuzuordnung ist nicht implementiert; es gibt keine automatische Ersatz-Ownerwahl.
- Releasebuild erzeugt ein unveränderliches geprüftes Bundle und ersetzt keine Assets. Erst die getrennte Aktion nach Auswirkungsprüfung sichert Asset/Manifest, ruft das bestehende Stagingwerkzeug auf und verifiziert. Paket-2-Abnahme verwendet ausschließlich temporäre Testassets. Paket 3 und Cloudveröffentlichung bleiben unimplementiert.


## Interne Erstübernahme · 16.10.2026

Der lokale Weg `internal-baseline-adoption-v1` ist ergänzend implementiert:
**Versionen → Vorhandenes App-Pack als erste interne Version übernehmen**.
Vorschau und ausdrückliche Bestätigung übernehmen den bereits intern verwendeten
Bestand; sie behaupten keine neue sprachliche Gesamtprüfung. Quelle und gesamtes
konvertiertes Bundle sind eng hashgebunden. Eigener Releaseeintrag ohne Draft-ID,
leere neue Reviewliste, `editorial=existing-evidence-only`; normale Releases
benötigen weiterhin ihre gebundene redaktionelle Freigabe. Nur Englisch/internal,
Generation 0/null-Parents; tatsächlicher Kanalzustand und CAS bleiben serverseitig.
Lokale Vorbereitung schaltet weder Produktionsasset noch Editorhead um.
Umsetzung, Grenzen, echte Testoutputs und exakte spätere Deployment-/Klickfolge:
[Erste private Bestandsversion](content-editor-initial-release.md).
Clouddeployment und echte Veröffentlichung sind in diesem Auftrag nicht erfolgt.
