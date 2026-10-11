# Gemeinsamer Implementierungsplan: Unregelmäßige Verben

Stand 10.10.2026. **Pakete A und B implementiert und technisch geprüft; Inhaltsauswahl steht aus.** Der Ausgangsbefund in Abschnitten 1–2 dokumentiert den Stand vor Paket A. Der verbindliche Ist-Vertrag mit Prüfnachweisen und Abweichungen steht in [Verben-Paket A](irregular-verbs-package-a.md) und [Verben-Paket B](irregular-verbs-package-b.md). Die übrigen Abschnitte bleiben als Umsetzungsplan und historische Ausgangslage erhalten. Gilt gemeinsam für „Unregelmäßige Verben – Infinitiv/Präsens“, „Unregelmäßige Verben – Präteritum“ und „Unregelmäßige Verben – Partizip Perfekt“. Je ca. 130 Ziele nach Prüfung; keine Auffüllpflicht und keine Zusage von 390 neuen Wörtern. Die Roadmap bleibt bei 14 Stapeln. Nach zwei technischen Paketen folgt erst die Inhaltsauswahl und danach die Satzredaktion anhand geprüfter Authoring-ZIPs im Chat. Keine automatische Modellgenerierung.

## 1. Geprüfte Ausgangslage

Manifest `assets/content/en/content.manifest.json`: `natur_umwelt_batch_3_v1`, Content-Schema 3, `internal_test_pack=true`, Quelle `pipeline/out/natur_umwelt_batch_3_v1/content.sqlite`, 15024128 Bytes. `pack.json` im selben Verzeichnis ist die geprüfte JSON-Quelle. Keine echte user.db geöffnet.

| Größe | Tatsächlicher Stand | Bedeutung |
|---|---:|---|
| Primäre Lernziele | 2121 | Gruppen der aktiven Primärzuordnungen, ohne Nutzerzustand |
| Stapel | 8 | Allgemeine Sprache 160; Reisen 489; Alltag & Zuhause 241; Arbeit & Bildung 245; Menschen & Beziehungen 245; Körper & Gesundheit 249; Essen & Trinken 250; Natur & Umwelt 242 |
| Karten | 2236 | Stabile Übungsidentitäten einschließlich alter Nebenbedeutungen |
| Wortbesitzzeilen | 2132 | Sprache + normalisierte Oberfläche, kein Lemmawortzähler |
| Satztexte | 2770 | Einschließlich Historie und Storytexten |
| Satzverknüpfungen insgesamt | 2764 | Davon 2236 aktiv, 528 archiviert; nicht 2764 aktive Übungen |
| Tabellen | 18 | Vollständiger Zeilenabgleich gegen `build_rows` |

Die acht Stapel sind intern gestagt. 2121 ist der bisherige redaktionelle Lernzielumfang, keine Messung des Wortschatzes eines Nutzers. Natur 242/242 ist vollständig importiert. [Natur-Abschlussbericht](natur-umwelt-batch-3-import.md) und [Roadmap](content-roadmap-v1.md) stimmen mit dem Pack überein. Ältere Zahlen in historischen Abschnitten von SRS-/Gruppen-/Story-Dokumenten sind keine aktuellen Packzahlen.

| Datei | SHA256 vor und nach der Planung |
|---|---|
| `pipeline/out/natur_umwelt_batch_3_v1/pack.json` | `7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e` |
| Quell-SQLite und `assets/content/en/content.sqlite` | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| `assets/content/en/content.manifest.json` | `e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b` |

Der bereits umfangreich geänderte Arbeitsbaum wurde vor dem Schreiben mit `git status --short` und SHA256 für 2565 bestehende Dateien erfasst (Git-Dateibestand inklusive untracked plus explizite Pack-/Assetdateien). Nicht erfasste ignorierte Dateien wurden nicht bearbeitet. Prüfnachweise liegen außerhalb des Repositorys unter `/tmp/irregular-verbs-plan-checks/`; sie sind lokale Diagnosen, keine neuen Produktionswerkzeuge.

## 2. Tatsächliche Verträge und Grenzen

| Bereich / vorhandener Pfad | Tatsächliche Schnittstelle / Befund |
|---|---|
| `pipeline/src/sprachpipe/ids.py` | `KEY_FIELDS`, `stable_id`, `form_norm`: Karten-ID aus `cards, lang, form, sense_id`; Lemma aus Sprache/Lemma/POS, Sense aus Lemma-ID/Sense-Key. Formfunktion ist kein Karten-Schlüsselfeld. Alte Schlüssel bleiben eingefroren. |
| `pipeline/src/sprachpipe/word_registry.py` | `index_registry`, `validate_selection`, `bind_new_pack`: genau eine sprachbezogene Oberfläche inklusive Aliassperre; auch andere Senses dürfen keinen zweiten Besitzer erhalten. Nur exakt reservierte Primärkarte darf wiederverwendet werden. |
| `pipeline/src/sprachpipe/content_contract.py` | `validate_registry`, `validate_rows`: jede aktive Karte braucht einen Besitzer ihrer Oberfläche; aktive `deck_cards` müssen exakt den Primärzuordnungen in `deck_words` entsprechen. Mehrfachmitgliedschaft als zusätzliche deck_cards-Zeile ist derzeit **nicht zulässig**. |
| `pipeline/src/sprachpipe/selection.py` | `plan_selection`: nur NOUN/VERB/ADJ, `form_kind=base`, Form=Lemma, keine doppelten Lemmas/Oberflächen. `partition_selection`: Form/Lemma/POS/Sense, ohne Formfunktion. Unverändert kein geeigneter Verbenform-Auswahlvertrag. |
| `pipeline/src/sprachpipe/learning_groups.py` | `validate_learning`: jede Karte hat Gruppe, aktiven Kopf derselben Sprache, Thema, Kontrasttags und Notiz. `apply_learning_groups` bindet die Quelle per Hash. |
| `lib/domain/learning_groups.dart` | `LearningGroups.project`: alle bereits gelernten Mitglieder, sonst ältester vorhandener Box-0-Stand, sonst Kopf. Disabled/retired reservieren mit. Würden alle Formen eine solche Einführungsgruppe erhalten, unterdrückte eine gelernte Grundform die neuen Formziele. |
| `lib/domain/repositories.dart`, `lib/data/content/drift_content_repository.dart` | `deckCardIds` liefert rohe Besitz-Primärzuordnungen; `decks` zählt Gruppen; `selectionCards`, `practiceItems`, `historicalSentence` lesen Karten und feste/historische Sätze. `_lemmaForms` liest belegte Formen aus Karten/Wörterbuch. |
| `lib/data/learning/practice_item_resolver.dart` | `load`, `eligiblePrimaries`, `activePrimaryIds`, `bindingFor`: gemeinsame Auflösung von Content-/lokalen Karten, Bindungen und Gruppen. Lokale Zuordnung derzeit nur Sprache/Form/Sense. |
| `lib/domain/new_card_selection.dart` | `selectNewCards`: pro Sitzung höchstens ein neues normalisiertes Lemma, eine Oberfläche und eine Einführungsgruppe. Themenabstand 3→2→1→0, Storyvorrang, 4:1-Inhalts-/Funktionsquote. `selectionLemma` ist POS-übergreifend; `isContentWord` enthält explizite AUX-/Sense-Ausnahmen. |
| `lib/domain/srs_state.dart` | `buildDeckQueue`, `buildMixedQueue`, `deriveVocabBreakdown`, `withRepeat`: Zustände/Reviews nach cardId; fällige Karten vor neuen; Gruppenprojektion nur für Einführung. Vier Zähler zählen Übungsstände, nicht distinct Lemmas. |
| `lib/data/user/user_database.dart`, `drift_user_repository.dart` | Schema 4; `user_cards.card_id` PK. `ensureCards` insert-or-ignore. `recordReview` transaktional, idempotent nach Pass-ID, Box-Vorbedingung; Review-Trigger verhindern UPDATE/DELETE. `setCardFlags` wirkt auf eine Karten-ID. |
| `lib/domain/review_pass.dart`, `leitner.dart`, `answer_check.dart` | `ReviewPass.complete` → `scheduleReview` → `recordReview`; Wiederholung ohne weitere Buchung. `evaluateAnswer`: Ziel → geprüfte Alternative → belegte andere Form → Tippfehler → falsch. |
| `lib/presentation/practice/deck_session_controller.dart` | Session einmal aufbauen/einfrieren, `_items` nach cardId, `ensureCards` erst bei Anzeige, fester Satz. Beide Modi nutzen denselben Controller. |
| `lib/domain/story_learning.dart`, `lib/data/content/drift_content_repository.dart` | `LearningIdentity` und `resolveStoryWord`: Sprache/Form/Sense; mehrere passende Karten derzeit Konflikt. Tokenstelle bleibt genau referenziert. `dictionary_forms` kann nur eine card_id pro Form/Sense transportieren. |
| `lib/data/user/drift_user_repository.dart` | `storyLearningStatus`, `addStoryWord`: Gruppen-/Exaktbindung, atomarer Add mit Quelle, Box 0, kein Review; bestehender Kontext bleibt. `learning_identity_bindings` UNIQUE Sprache/Form/Anker kann mehrere Funktionen derselben Oberfläche bisher nicht unterscheiden. |
| `lib/presentation/providers/deck_providers.dart`, `learning_providers.dart` | Deckfortschritt, vier Zähler, Wortliste, Tagesziel. Wortliste erhält gelernte und explizite Story-Box-0-Zeilen; Favoriten/Notizen bleiben pro Karte. Tagesziel zählt verschiedene reviewte Karten je lokalem Tag. |
| `pipeline/scripts/import_editorial_patch.py` | `create_content`: Schema 2/3, jede neue Karte braucht reservierte Primärmitgliedschaft; Source-/Registryhash, vollständige Token-/Linkreviews. `export_offline` → vorhandener Export/Readback. Kein aktueller Importweg für besitzneutrale Übungsmitgliedschaften. |
| `pipeline/src/sprachpipe/pack.py`, `schema.py`, `export.py`; `pipeline/scripts/finalize_curation.py` | `build_rows`, `COLUMNS`, `TABLE_ORDER`, `export_sqlite`, `check_sqlite` sind gemeinsamer Inhaltsvertrag/Exportweg; keine zweite Importpipeline nötig. |
| `lib/data/content/content_database.dart`, `content_pack_installer.dart`; `tool/stage_content_pack.dart` | Leser unterstützt 1/2/3, prüft Inhalt/Version; Installer prüft Hash/Größe und Kandidat vor Dateiaustausch, user.db separat. Staging/Verify verwenden dieselben Prüfungen. |

**Wiederverwendung heute:** Eine bestehende Karten-ID könnte technisch in mehreren reinen Ansichten denselben SRS-Stand nutzen. Der aktuelle Packvertrag erlaubt diese zusätzlichen Stapelzuordnungen jedoch noch nicht. Die Lösung ist eine eigene Zuordnung für Übungsansichten, nicht ein zweiter Besitzer und nicht eine Kopie des Lernstands.

## 3. Empfohlenes gemeinsames Zielmodell

Die bestehende `cards`-Tabelle bleibt die einzige persistente SRS-Einheit. Ergänzt werden Content-Metadaten für lexikalische Zählzugehörigkeit, Formfunktion und Übungsmitgliedschaft. Es gibt keine zweite SRS-Tabelle und keinen zweiten Scheduler.

| Begriff | Zielvertrag |
|---|---|
| Lexikalisches Lernziel L | Ein explizit belegter lexikalischer Begriff eines Verbs; seine Flexionen teilen L. Unterschiedliche Bedeutungen/POS werden nicht automatisch gleichgesetzt. Bereits beschlossene synonymische Einführungsgruppen bleiben maßgeblich. L dient dem Wortzähler, besitzt selbst keine Box. |
| Formziel F | Exakte Bedeutung + exakte Oberfläche + grammatische Formfunktion; genau eine kanonische Übungskarte und ein fester Satz. Identische Buchstaben bei anderer Funktion sind verschiedene F. |
| Karten-ID C | Persistenzanker für UserCardState und Reviews. Bei nachgewiesen identischer vorhandener Übung bleibt C; sonst neue ID, zunächst ohne Nutzerzeile. |
| Stapelzugehörigkeit | Eigentümer bleibt `deck_words`. Zusätzlich darf eine Übungsansicht eine vorhandene Karte referenzieren. Mehrere Ansichten derselben C erzeugen weder neue Karte noch neuen Zustand. |
| Lernstand / Review | Ausschließlich pro C; keine Übertragung zwischen F, kein Gruppen-/Lemma-SRS. Bereits gelernte mehrere C bleiben jeweils wiederholbar. |
| Globale Wortzahl | Anzahl verschiedener L im berechtigten Lernvorrat, getrennt von der Anzahl Übungen und fälliger Reviews. Drei Formziele desselben Verbs ergeben höchstens ein zusätzliches L. |
| Verbenstapelfortschritt | Anzahl berechtigter Formübungen und ihrer tatsächlich vorhandenen Zustände; wiederverwendete Karte wird als bereits geübt erkannt. Kein Grundform-Stand für andere Funktionen. |

### Identitäten und Schema 4 (Planbasis; Paket-A-Iststand im Abschlussbericht)

Die folgenden Namen sind **geplante neue Felder/Tabellen/API-Erweiterungen**, keine Behauptung vorhandener Schnittstellen. Alle liegen in den bestehenden Datenbanken. Alle neuen Content-Referenzen werden auf Existenz, Aktivität, Sprache und passende Sense-/Lemma-Zugehörigkeit geprüft; aktive Zuordnungen zu Tombstones oder widersprüchliche F-/L-Zuordnungen brechen Export und Öffnen ab. Tombstones bleiben für Historie lesbar. IDs und Referenzen werden beim Export in fester Abhängigkeitsreihenfolge aufgelöst.

1. Neue Content-Tabelle `lexical_targets`: `id`, `lang`, `anchor_key`, `note`, Tombstones. ID nach neuem `stable_id('lexical_targets', lang, anchor_key)`. `anchor_key` ist ein eingefrorener redaktioneller Schlüssel, keine deutsche Glosse. Neue Tabelle `card_lexical_targets`: `id` nach card_id, `lang`, `card_id` UNIQUE, `lexical_target_id`, `note`, Tombstones. Eine Karte gehört höchstens einem L. Für nicht zugeordnete Altinhalte gilt als Zählschlüssel `learning.group_id`, bei Schema 1/2 die Karten-ID. Keine pauschale Neuordnung des gesamten Bestands.
2. Neue Content-Tabelle `form_targets`: `id`, `lang`, `sense_id`, `form`, `form_norm`, `function`, `card_id` UNIQUE, `lexical_target_id`, `note`, Tombstones. ID aus neuem Namespace `form_targets` und `(lang, sense_id, form, function)`. Funktionen in diesem Umfang: `base`, `past`, `past_participle`. Eindeutiger aktiver Schlüssel über diese vier Felder. Person-/Numerusangaben und Formlabel sind redaktionelle Metadaten; für be siehe Abschnitt 4. Die Karte muss exakt Sprache/Form/Sense entsprechen. Keine künstliche neue Bedeutung zur Trennung von Tempora.
3. Bestehende `cards` erhalten nullable `identity_function` und `introduction_scope` mit Default `ordinary`. Eine neue, bisher nicht vorhandene Formübung erhält `identity_function` entsprechend F und eine ID aus **neuem Hash-Namespace** `form_cards(lang, form, sense_id, function)`, gespeichert weiterhin in `cards`. `form_cards` ist nur ein ID-Namespace, keine zweite Kartentabelle. Alte `KEY_FIELDS['cards']` und alle alten IDs bleiben unverändert. Bei vorhandener passender Karte bleibt `identity_function` null; der explizite form_targets-Eintrag belegt die Zuordnung ohne ID-Änderung. `introduction_scope=form_only` nur für neu erzeugte reine Formkarten; Altwerte bleiben ordinary.
4. Die bisherige SQL-Unique-Regel `(lang, form, sense_id)` aus `supabase/migrations/20261003000002_content_tables.sql` braucht im künftigen Schema-Spiegel zwei partielle Unique-Regeln: Alt-/gewöhnliche Karten mit null identity_function behalten den alten Schlüssel, neue Formkarten verwenden zusätzlich identity_function. Zentraler Validator verbietet zusätzlich eine neue Formkarte, wenn ein freigegebenes F bereits auf eine erhaltene alte Karte zeigt. Kein stilles Abschalten der Dublettenprüfung. Bestehende Migration nicht editieren; neue lokale Spiegelmigration erst in Paket A, ohne Remote-Anwendung.
5. Neue Tabelle `deck_practice_targets`: `id` aus `(deck_id, form_target_id)`, `deck_id`, `form_target_id`, `position`, Tombstones; aktive Positionen 1..n, eindeutige Mitgliedschaft. Verbenstapel erhalten `decks.practice_kind` als `verb_base`, `verb_past`, `verb_participle`; sonst Default `ordinary`. Validator prüft passende Funktion. `deck_cards` bleibt unverändert der rohe Besitzvertrag, diese neue Tabelle bildet Übungsansichten ab.
6. Bestehende cards.learning-Metadaten nicht umschreiben. Neue Formkarten bekommen eigene Einführungsgruppen; **niemals** eine gemeinsame Lerngruppe für base/past/participle. Normale Ansichten behalten LearningGroups.project. Formansichten lösen F auf C auf; dabei nur exakt belegte gleiche Formfunktion wiederverwenden, nicht einen synonymischen Kopf anderer Form/Sense. Diese Entscheidung gilt auch nach dem Zusammenführen aller Quellen in Gemischt: keine anschließende pauschale Gruppenprojektion, die F wieder auf einen anderen Kopf abbildet.
7. Vorhandener Wortbesitz bleibt exakt erhalten. Bereits reservierte Oberflächen referenzieren ihren bisherigen Besitzer, auch bei anderem Sense/POS; eine Formübung ist kein neuer lexikalischer Primärplatz. Eine noch unreservierte Oberfläche wird genau einmal in derselben Registry und deck_words reserviert, mit Primärkarte/normaler deck_cards-Besitzzeile. Empfehlung für ihren Besitzer: Eigentümer der zugehörigen Grundform; ist auch diese neu, Stapel Infinitiv/Präsens. Das sind zusätzliche Oberflächenreservierungen, keine zusätzlichen L. Neue form_only-Karten sind aus gewöhnlicher automatischer Einführung ausgeschlossen und ausschließlich durch deck_practice_targets oder Story-Add zugänglich. Bestehende Deckpositionen bleiben, neue Besitzpositionen werden angehängt. So wachsen alte Themenstapel nicht unbemerkt um automatische Formübungen.
8. Homographe Formziele teilen denselben einzigen Besitzer, haben aber getrennte C. Ein Alias erzeugt keinen zweiten Besitz. Neue Formziele auf einem schon reservierten Alias erfordern einen expliziten Aliasbeleg; der Validator darf für form_only auf dessen vorhandenen word_id auflösen. Keine globale Lockerung der owner-Pflicht. Besitzaliase erlauben keine Antworten und keine Zustandsübernahme.

**Wiederverwendungskriterium:** Sprache, stabile Sense-ID (einschließlich POS), Oberfläche, redaktionell belegte Funktion und vorhandener fester Satz müssen passen. Ein altes `form_kind=base` allein ist kein Beleg. Bestehender Satz und Lernverlauf werden nicht ersetzt, um Wiederverwendung passend zu machen. Eine semantisch/funktional passende Altkarte erhält nur Zuordnungsmetadaten. Ist die Funktion unklar, bleibt sie ein Altziel; keine automatische Zuordnung. Kann deshalb kein eindeutiges neues F ohne konkurrierende gleiche Übung angelegt werden, bleibt der Kandidat bis zur Inhaltsklärung zurückgestellt statt doppelt importiert.

Die Zuordnung ist vor jeder neuen ID-Erzeugung hashgebunden zu prüfen. Bereits vorhandene getrennte lokale/kuratierte Lernstände gleicher exakter Übung werden nicht verschmolzen: kanonische Einführung einmal, beide alten Zustände weiter in Reviews und Wortliste; Konflikt sichtbar. Kein Tombstone/replaced_by zur Zusammenführung von Formen.

### Lexikalische Zählung und echter Produktkonflikt

`PRODUCT.md`, „Card (the unit of learning)“, „Four Derived Lingvist-Style Categories“ und `docs/srs.md`, „Abgeleitete Zähler“ verlangen heute eine disjunkte Summe **aus Kartenständen**; due muss der Queue entsprechen. Gleichzeitig sollen drei Verbformen nicht als drei neue Wörter erscheinen. Beides lässt sich nicht mit einem einzigen numerischen Gesamtwert erfüllen, sobald drei unabhängige Formstände fällig sind.

Optionen: (a) Formen zu einem SRS-Stand zusammenlegen, widerspricht Zustandserhalt und unabhängiger Wiederholung; (b) drei Formen weiterhin als drei Wörter ausweisen, widerspricht diesem Auftrag; (c) Wortzahl und Übungszahl getrennt ausweisen. **Empfehlung und Planbasis: c.** In Paket A den Zielvertrag dokumentieren, in B konsistent anzeigen. Keine heimliche Uminterpretation bestehender Zahlen.

- Die vier Kategorien bleiben dynamisch nach exakt demselben Vorrang und Zustand abgeleitet, heißen in der Oberfläche jedoch „Fällige Übungen“, „Übungen im Aufbau“, „Gemeisterte Übungen“, „Noch nicht geübte Ziele“. Ihre Summe ist der Übungsvorrat; due bleibt Anzahl erreichbarer fälliger Karten. Keine gespeicherten Counter.
- Daneben „Lexikalische Lernziele“: distinct L über denselben berechtigten Vorrat, einschließlich ungesehener Ziele aktiver Stapel; „Bereits geübte lexikalische Lernziele“: distinct L mit mindestens einer aktiven gelernten Karte. Dieser Wert behauptet weder volle Paradigmabeherrschung noch Gemeistertsein aller Formen. Keine künstliche lexikalische Box.
- Keine Summe der einzelnen Stapel als globale Wortzahl: wiederverwendete Übungen können in mehreren Ansichten vorkommen. Deaktivierte/retirierte Karten zählen nicht; L entfällt erst, wenn kein berechtigtes Ziel dieses L übrig ist. Fehlende Inhalte werden separat gemeldet, nicht als verfügbare Übungen gezählt.
- L-Zuordnung berücksichtigt bestehende Einführungsgruppen: vorhandenes äquivalentes lexikalisches Ziel wiederverwenden, vorhandene Gruppenmitglieder konsistent auf denselben L-Zählschlüssel abbilden. Keine Form-/POS-/Sinnvereinigung allein aufgrund gleicher Glosse. Umfangreiche schon gelernte Synonym-/Formstände dürfen die Übungszahl erhöhen, nicht die Zahl desselben L.
- Die alte Basis 2121 bleibt als historischer redaktioneller Umfang dokumentiert. Die neue distinct-L-Projektion kann durch die belegte Zusammenfassung schon vorhandener Formen geringer ausfallen. Späterer Auswahlbericht muss Altbasis, Umklassifizierung, wirklich neue L, wiederverwendete C, neue F und neue Oberflächenreservierungen getrennt ausweisen; keine Zahl passend machen.
- Tagesziel/Streak bleiben reviewbasiert (`learningProgressProvider`), distinct card_id pro Tag; UI nennt dies „Übungen“, nicht „neue Wörter“. Story-Add zählt nicht. Derselbe C in zwei Ansichten zählt täglich einmal, drei getrennt geübte F dreimal als Übungen.

## 4. Formregeln ohne Auswahl oder Satzproduktion

**Infinitiv/Präsens umfasst genau die Grundform**, in einem festen Kontext als Infinitiv oder passende unmarkierte Präsensform. Kein vollständiges Präsensparadigma, keine automatische zusätzliche Übung für 3. Person Singular. Stapeltitel bleibt wie beauftragt; Beschreibung muss „Grundformen; kein vollständiges Präsensparadigma“ erklären. Pro ausgewähltem lexikalischem Ziel normalerweise ein F je Stapel.

| Synthetischer Formfall | Technische und redaktionelle Behandlung |
|---|---|
| go / went / gone | Drei F/C, ein L bei derselben Bewegungsbedeutung. Alte passende C wiederverwenden. Past-Kontext klar vergangen, Partizip syntaktisch durch Perfect-Hilfsverb bestimmt. |
| run / ran / run | Grundform und Partizip gleiche Oberfläche, gleiche Sense möglich, aber verschiedene function und feste Sätze. Kein zweiter Besitz von run; keine Grundform-Box für Partizip. |
| cut / cut / cut | Drei Funktionen, drei F/C, eine Oberfläche/ein L. Eindeutige grammatische Satzkontexte nötig; Eingabe cut löst nur den gerade präsentierten C. |
| read / read / read | Wie cut hinsichtlich Identität. Grundform und Vergangenheitsformen haben unterschiedliche Aussprache; Formlabel und später vorhandenes Audio müssen zur Funktion passen. Schreibübung kann die Aussprache nicht prüfen; kein Aussprache-Erfolg behaupten. |
| be | Grundformstapel nur be in geeignetem Infinitivkontext; am/is/are sind kein automatisch neu anzulegendes Paradigma. Bereits gelernte Präsensformen bleiben mit eigenen C/Reviews. Past: eine offen benannte repräsentative Form, Empfehlung was mit eindeutigem Singularsubjekt; were bleibt vorhandenes eigenständiges Ziel und ggf. Wörterbuchform, aber kein stilles zweites Ziel dieser Auswahl. Partizip: been. being gehört nicht zum Partizip-Perfekt-Stapel. Bestehende AUX-/VERB-Senses und Kopula-/Hilfsverbkonventionen bleiben unverändert; keine Umschreibung nach heutiger POS-Vorliebe. |
| Unterschiedliche Bedeutungen | Beispielsweise hängen und hinrichten sind unterschiedliche semantische Anker; keine Formübernahme zwischen ihnen. Ein L kann nur ausdrücklich bedeutungsgleiche Flexionen enthalten. Unterschiedliche alte Sense-IDs nur nach begründetem semantischem Mapping zählen, nie durch Übersetzungsvergleich. |
| Regelmäßige/unregelmäßige Varianten | Pro ausgewähltem Sinn/Funktion eine Zielform; regionale Variante nur nach Satzprüfung neutral, kein automatisches accepted und kein zusätzlicher Platz. Bereits separat gelernte Varianten behalten ihre C. Bedeutungsspezifische Formen nicht als regionale Synonyme ausgeben. Kein Zwang, dass jeder Kandidat alle drei Stapel füllt. |

Dies sind Modellfälle, keine reservierten Verben, ID-Liste oder Satzlieferung. Präsens-Sonderformen wie has/does vergrößern die Zielzahl ebenfalls nicht automatisch. Nicht abgedeckte Paradigmateile sind klar im Umfang benannt; später keine zusätzliche Kategorie vorbereiten.

Jedes F hat einen natürlichen festen englischen Satz und passende idiomatische deutsche Übersetzung. Zeitangabe allein reicht bei mehrdeutigem Satz nicht immer; Subjekt, Hilfsverb und Syntax müssen zusammen die Funktion bestimmen. Redaktion prüft Kontext, Sinn, Label, Lücke, vollständige Tokenannotation und sämtliche Alternativen. Alternative Tempora werden nicht aufgrund des gemeinsamen Lemmas neutral. Ist dieselbe Schreibung korrekt, kann die Tastatureingabe die gedachte Formfunktion nicht erkennen; die Aufgabe prüft die Einsetzung in den belegten Kontext, keine unsichtbare Grammatikentscheidung.

## 5. App-Abläufe und gemeinsame Projektion

Geplante Erweiterung in `lib/domain/repositories.dart`: `deckPracticeTargets(deckId)` liefert typisierte Einführungsreferenzen (`ordinary` mit Karten-/Gruppenbezug oder `form` mit F/C). `deckCardIds` bleibt unverändert für Besitzdiagnose. `selectionCards`, `practiceItems`, `historicalSentence` bleiben die gemeinsamen Auflösungswege. Ergänzende Metadaten werden über ContentCard/PracticeItem transportiert; keine zweite Satz- oder Bewertungslogik.

Im `PracticeItemResolver` eine gemeinsame Projektion solcher Referenzen ergänzen: ordinary → bisherige Gruppenregel; form → exakte F-Bindung, vorhandener gleicher Stand, sonst kanonische C. Ergebnis nach C deduplizieren und Herkunft/lexikalischen Zählschlüssel behalten. **Formprojekte nicht erneut durch ordinary-Gruppenprojektion schicken.** Sowohl Queues als auch Zähler, Wortliste und Deckfortschritt verwenden dieses Ergebnis. Bereits gelernte Zustände bleiben unabhängig davon in der globalen Reviewmenge.

- **Stapelübung:** deckPracticeTargets des ausgewählten Stapels, eigene fällige Übungen vor neuen; auch inaktiv direkt startbar. Bereits vorhandene C/F und genau passende lokale Bindungen mit demselben festen Kontext wiederverwenden. Kein Benutzerstand durch bloßes Öffnen/Installieren. Neue C erst bei Anzeige Box 0.
- **Revue:** alle gelernten passenden Formstände des Stapels, einschließlich erhaltenen exakten lokalen/alten Doppelständen, niemals bloß wegen gleicher Oberfläche alle Bedeutungen. Sauber unverändert, Fehler Box 1. Revue erhält keine ungeübten F durch Lemmafortschritt.
- **Gemischt:** alle auflösbaren aktiven fälligen C zuerst, unabhängig von Stapelschaltern; dann explizite Story-Box-0-Ziele und neue berechtigte Ziele aktiver Stapel; anschließend frühzeitiges Üben. C in mehreren Ansichten erscheint einmal. Unterschiedliche fällige F oder erhaltene Alt-C niemals nach Lemma/Oberfläche entfernen.
- **Wortliste:** L darf als sichtbare Gruppierung dienen; darunter bedienbare Formzeilen mit Bedeutung, Formlabel, Box, Termin, Favorit, Deaktivierung, Notiz und Historie. Kein zusammengefasster vermeintlicher SRS-Stand. Explizite Story-Box-0 weiterhin sichtbar. Neue Stapel-Box-0 bleibt gemäß vorhandenem Vertrag erst nach Review sichtbar; kein unaufgeforderter Wechsel dieses Verhaltens. Mengenlabels nennen Übungen bzw. lexikalische Ziele eindeutig.
- **Favoriten/Deaktivierung:** `setCardFlags(C)` unverändert. Dieselbe C in mehreren Ansichten teilt Flags; andere F unabhängig. Ein deaktiviertes F darf nicht durch Alias, lokalen Ersatz oder erneute Mitgliedschaft neu entstehen. Grundform deaktiviert bedeutet nicht automatisch Verbot anderer ausdrücklich verschiedener F. Kein neuer globaler „Verb deaktivieren“-Schalter in diesem Umfang.
- **Antworten/Hinweise/Aufdecken:** vorhandene `evaluateAnswer`, `ReviewPass`, Leitner und Repeat-Regeln wiederverwenden. Andere belegte Form bleibt Fehler vor Tippfehlertoleranz. Synonyme nur aus konkretem Karte-Satz-Link. Wrong-form-Label enthält Funktion. Kein Freigeben über L, Gruppe, Besitzer oder Wortfamilie. Auswahlchips dürfen gleiche Antwortschreibweisen nicht mehrfach als vermeintlich unterschiedliche Optionen anzeigen.

### Ähnliche neue Formen und Dublettensperre

Empfehlung: harte **höchstens-eine-neue-Form-pro-normalisiertem-Lemma-und-Oberfläche-pro-Sitzung** beibehalten. Damit können cut-Grundform und cut-Past nicht unmittelbar als neue Aufgaben aufeinanderfolgen; die andere Funktion rückt in späterer Sitzung nach. Die Einführung wird nicht durch einen bereits bekannten Lemma-Stand global gesperrt: knownLemmas ist weiterhin nur Priorität.

Gezielte Anpassung in `selectNewCards` und den Aufrufern: Kandidaten kommen aus der neuen typisierten Projektion; globale Einführungsgruppen dienen nur ordinary-Zielen, Formziele verwenden F als Einführungsidentität. Hart nach tatsächlicher C deduplizieren, Lemma-/Oberflächensperre **nur im neuen Segment** anwenden. Formfamilie zusätzlich als related-Kontrast berücksichtigen, vorhandenen 3/2/1/0-Abstand und stabile Reihenfolge erhalten. Keine Umdeutung in dauerhafte Exklusion und keine Wiederauffüllung durch ähnliche Formen. Kleine Restmengen ergeben kurze Sessions. Sessionfreeze und notwendige In-Session-Repeats bleiben. Fällige Reviews werden nicht der Neuziel-Dublettensperre unterworfen; alle bleiben erreichbar, selbst unmittelbar nebeneinander.

### Story → Zum Lernen hinzufügen

Die bisherige Sprache/Form/Sense-Bindung reicht für run/cut/read nicht. Content-Schema 4 ergänzt nullable `sentence_tokens.form_target_id` für **redaktionell belegte** Funktion sowie eine neue Formzuordnung im StoryToken/Kandidaten. Alte Token bleiben unverändert und erhalten keine geratene Funktion. Dictionary-Formglosse bleibt Form/Sense-basiert, ihr einzelner card_id-Zeiger darf bei mehreren Funktionen nicht als Funktionsnachweis dienen.

Auflösungsreihenfolge: explizit belegtes F und dazu passender Token-C → bestehende exakte Formbindung → eindeutige freigegebene alte Übung. Fehlt Funktionsbeleg, keine automatische Auswahl eines F anhand gleicher Buchstaben oder der höchsten Box. Ein klar referenzierter alter Token bleibt als alte Übung verwendbar; er beweist keine zusätzliche neue Funktion. Bei mehreren Kandidaten sichtbarer Konflikt, kein Erfolg und kein Write. Story-Übersetzung bleibt trotzdem verfügbar.

Für lokale Formziele geplante additive user.db-Version 5: nullable `user_cards.form_function`; neue Tabelle `form_identity_bindings` mit PK identity_key, UNIQUE(lang, form_norm, semantic_anchor, function), card_id. Bestehende learning_identity_bindings bleibt byte-/zeileninhaltlich erhalten. Neue Schlüssel: Hash über JSON `["form-learning-identity-v1", lang, form_norm, semantic_anchor, function]`; neue lokale ID `u:` plus Hash über `["local-form-card-v1", lang, form_norm, semantic_anchor, function]`. Bestehende u:-IDs niemals neu berechnen. Alte lokale Karte nur durch belegten Kontext/Funktion zuordnen, keine Bulk-Migration nach Oberfläche.

`attachLocalLearning`/`bindingFor` müssen Formfunktion berücksichtigen; ihr heutiges Dictionary nach Sprache/Form/Sense darf bei mehreren Formkarten keinen stillen letzten Treffer wählen. Alte untypisierte Bindung kann genau einer belegten Funktion entsprechen, niemals allen drei. Beleg fehlt → Altstand weiter übbar, neue automatische Gleichsetzung gesperrt/diagnostiziert. Unabhängige bereits gelernte Formen behalten eigene Reviews.

`storyLearningStatus` und `addStoryWord` nutzen dieselbe Projektion und Transaktion wie bisher. Passendes vorhandenes F → derselbe C, bestehende Box/Termin/Quelle/Satz unverändert, ggf. neue Quellenreferenz. Andere Funktion desselben L → separates neues F mit Box 0 erst nach explizitem Add, **kein neuer lexikalischer Begriff**. Ohne Content-Karte lokale Anlage nur mit vollständiger, freigegebener Form-/Kontextannotation, derselben bestehenden Kontextvalidierung und leerer Alternativenliste. Doppeltipp/Parallelzugriff idempotent; kein Review beim Add, kein Aktivieren des Besitzerstapels. Deaktivierung/Retirierung nicht umgehen.

## 6. Synthetische Zustands- und Zählerprüfung

Notation: L = ein lexikalisches Ziel, Cb/Cp/Cpp = unabhängige Grundform-/Past-/Partizipkarten. Alle drei Ansichten seien aktiv, alle Karten auflösbar und nicht deaktiviert. „Übungszähler“ = fällig / Aufbau / gemeistert / ungesehen. Box 5 sei jeweils noch nicht fällig. Diese Beispiele erzeugen keine Dateien, Reservierungen oder Sätze.

| Fall | Identitäten / Anfang | Erwartetes Verhalten und Zahlen |
|---|---|---|
| a) Verb unbekannt | Ein L; drei F und C ohne Userzeilen | Lexikalisch 1, bereits geübt 0; Übungen 0/0/0/3. Erster sauberer Grundformpass erstellt nur Cb und führt ihn in Box 3: 0/1/0/2, lexikalisch weiterhin 1, bereits geübt 1. Past/Partizip unverändert ungelernt. |
| b) Grundform gelernt | Vorhandene Cb Box 5, Cp/Cpp noch ohne Zustand | Cb unverändert wiederverwenden. Übungen 0/0/1/2; drei Stapel je 1 Ziel, gesehen 1/0/0. Neues Cp übernimmt keine Box 5. Neue zusätzliche Ansicht von Cb verändert keine dieser Zahlen. |
| c) Mehrere eigene Stände | Cb Box 5, Cp fällig Box 2, Cpp Box 3 künftig fällig | Lexikalisch 1, Übungen 1/1/1/0; ein fälliger Review für Cp, alle drei Stände separat. Werden alle fällig: 3/0/0/0, weiterhin ein L. Historische Reviews/Flags bleiben genau an ihren C. |
| d) Gleiche Schreibweise | cut: Cb/Cp/Cpp haben gleiche Oberfläche/Sense, verschiedene function und Sätze | Ein Besitzer, ein L, drei F. Nur Cb gelernt Box 3: 0/1/0/2; Eingabe cut in Cp beeinflusst nur Cp. Drei fällige C bleiben drei Reviews, obwohl die Oberfläche identisch ist. |
| e) Story trifft Verb | Cb gelernt, Storytoken eindeutig Cp | Ist Cp bereits vorhanden/gelernt: wiederverwenden, Zahlen unverändert, kein Review beim Add. Ist Cp nur ungesehen in aktivem Stapel: eine Box-0-Zeile ersetzt den ungesehenen Platz, Summe unverändert 3. War nur Grundform berechtigt und Cp bisher nicht aktiv: expliziter Add erweitert Übungsvorrat von 1 auf 2, L bleibt 1. Kein neues Cb; Tooltip bleibt getipptes Wort. |
| Erhaltener exakter Doppelstand | Lokales Cp und kuratiertes Cp beide gelernt | Beide C mit eigener Historie/Reviews bleiben, Konflikt sichtbar; keine dritte Anlage. Ein L; Übungszahl um den erhaltenen zusätzlichen Zustand höher. Stapel weist zusätzliche Altübung ausdrücklich aus, statt sie als neues Wort zu verkaufen. |

Zusätzlich: drei Ansichten derselben vorhandenen C ergeben nur eine globale Übung/einen Zustand; der erste Pass bucht einmal. Ein regulärer späterer Review in einer anderen Sitzung ist kein Duplikat, sondern wird mit aktuellem Zustand/Modus bewertet. Deaktiviertes Cp entfernt nur Cp aus allen Queues/Zählern; Cb/Cpp bleiben. Keine Wiederholungen gehen durch eine Ansicht oder Lexikalsumme verloren.

## 7. Umsetzung in genau zwei prüfbaren Paketen

### Paket A — Inhaltsvertrag, kompatibler Leser und Import

Abhängigkeit: dieser gemeinsame Plan. Noch keine realen Verben auswählen/reservieren; ausschließlich synthetische Testfixtures für die Technik.

**Bestehende Dateien und genaue Eingriffe:**

- `pipeline/src/sprachpipe/ids.py`: nur neue Namespaces/Schlüssel ergänzen; bestehende Testvektoren unverändert. `schema.py`, `pack.py`, `content_contract.py`, `learning_groups.py`: Schema 4, neue Metadaten/Tabellen, strikte Zuordnung, echte Wiederverwendung, Ein-Satz-Regel, Besitzerprüfung und Tombstones. `export.py` und `pipeline/scripts/finalize_curation.py`: alle neuen Tabellen in denselben Export/Readback aufnehmen.
- `pipeline/src/sprachpipe/selection.py`, `word_registry.py`: versionierter Form-Auswahlmodus zusätzlich zum unveränderten base-Vertrag; F-Identität in Partitionierung, getrennte Berichte für Wiederverwendung/neue F/neue L/Oberflächen, Ownerreuse ohne erneute Reservierung. Exakte Registryparent-/Quellhash-Prüfung beibehalten. Noch keine Produktionsauswahldatei erstellen.
- `pipeline/scripts/import_editorial_patch.py::create_content`: versionierte Erweiterung desselben Create-Wegs für Formzuordnungen, Mitgliedschaften und neue Formkarten ohne zweite Primärreservierung einer vorhandenen Oberfläche. Bereits existierende Karte/Satz bleibt unverändert; wiederverwendete F benötigt expliziten geprüft-begründeten Metadateneintrag. Transaktionales Gesamtvalidieren vor Ausgabe, kein stilles Skip. Altes `editorial_content_v2.schema.json` unverändert weiter akzeptieren; neue Formatspezifikation als **neu anzulegende** `pipeline/data/curation/editorial_content_v3.schema.json` planen, gleicher Importer, kein zweites Importprogramm.
- `pipeline/scripts/export_authoring_context.py`, `pipeline/src/sprachpipe/authoring_context.py`, `deck_display.py`: F-basierte Partitionen und neue Übungsreihenfolge neben unverändertem Besitz-Display; ZIP enthält vollständigen aktuellen Kontext, alte IDs/Sätze, Funktionen, L-Zählmapping, Ownerreuse und geprüfte Hashes/CRCs. Keine alte ZIP regenerieren. Release-/Form-/Importformat explizit binden; kein stiller Rückfall auf Schema 3.
- `lib/domain/content.dart`, `repositories.dart`; `lib/data/content/content_database.dart`, `drift_content_repository.dart`, `content_pack_installer.dart`: Metadaten/typed deckPracticeTargets, Schema-1/2/3-Fallback ohne erfundene Formfunktion, neuer Schema-4-Leser/Validator, disambiguierbarer Storytoken, historische Auflösung. `tool/stage_content_pack.dart`, `tool/content_pack.dart`: neuen Tabellenumfang/Versionsprüfung über gemeinsame Validierung führen.
- Neue lokale Schema-Spiegelmigration unter vorhandenem `supabase/migrations/` erst bei Umsetzung benennen; alte Migrationen nicht ändern oder remote anwenden. `PRODUCT.md`, `docs/content-schema.md`, `docs/srs.md`, `docs/pipeline.md`, `docs/learning-groups-v1.md`, `docs/decks-and-story-learning-plan.md` dann um den ausdrücklich neuen Vertrag ergänzen, Historien behalten.

**Tests/Abnahme A:** Bestehende `pipeline/tests/test_ids.py`, `test_content_contract.py`, `test_selection.py`, `test_word_registry.py`, `test_learning_groups.py`, `test_editorial_import.py`, `test_pack_db_export.py`, `test_cost_schema.py`, `test_authoring_context.py`, `test_authoring_schema3.py`, `test_authoring_continuation.py`, `test_deck_display.py` gezielt erweitern; Dart `test/data/content_repository_test.dart`, `stage_content_pack_test.dart`, `single_sentence_content_test.dart`, `story_content_test.dart` mit synthetischem Schema-4-Pack.

Akzeptanz: cut erzeugt drei unterscheidbare F, aber nur eine Oberflächenreservierung; reuse behält alte ID/Satz/Gruppe. Zweiter Owner, falsche Funktion, künstlicher Sense, mehrere aktive F derselben Identität, ungültiges aliasbasiertes Mapping, fehlender fester Satz, alte Hashes und unbekannte Version scheitern konkret. Vollständiger SQL-Zeilenabgleich, vorhandene ID-/Satz-/Ownerzeilen erhalten. Schema 1/2/3 und alte ZIP-Verifikation weiterhin erfolgreich. Der aktuelle echte Pack bleibt unverändert; noch kein Produktions-Staging von Verben.

### Paket B — Projektion, Storybindung, Oberfläche und kompatible Abnahme

Abhängigkeit: grünes A mit gemeinsamem Schema-/Importvertrag. Ein gemeinsamer Lernpfad in der App, keine zweite Form-SRS-Engine.

**Bestehende Dateien und genaue Eingriffe:**

- `lib/domain/learning_groups.dart`, `srs_state.dart`, `new_card_selection.dart`, `story_learning.dart`: typisierte Projektion und explizite Formidentität, additive lexikalische Zählprojektion, neue Kandidaten korrekt deduplizieren. `lib/data/learning/practice_item_resolver.dart`: gleicher Resolver für alle Quellen, exakte lokale Formbindung, keinerlei last-match-Auflösung bei Homographen.
- `lib/data/user/user_database.dart` und generierte `user_database.g.dart`: additive v4→v5-Migration und Formbindung wie oben. `drift_user_repository.dart`: atomarer formbezogener Story-Add, changes-Stream für neue Bindungen; `ensureCards`, `recordReview`, Flags-/Reviewtrigger als einziger Schreibweg erhalten. `lib/domain/repositories.dart` nur um benötigte Metadaten-/Bindungszugriffe ergänzen.
- `lib/presentation/practice/deck_session_controller.dart`, `lib/presentation/providers/deck_providers.dart`, `learning_providers.dart`, `story_learning_providers.dart`: eine Projektion, kein erneutes F-zu-Gruppe-Zusammenfallen, Sessionfreeze/ID-Dedup, getrennte Wort-/Übungszahlen und korrekter Deckfortschritt. `lib/domain/review_pass.dart`, `answer_check.dart`, `leitner.dart` fachlich unverändert; nur vorhandene Schnittstellen verwenden und Regressionen testen.
- `lib/models/home_models.dart`, `word_list_models.dart`, `lib/screens/home/widgets/vocab_progress.dart`, `lib/screens/decks/deck_details_screen.dart`, `deck_practice_screen.dart`, `lib/screens/words/word_list_screen.dart`, `widgets/word_list_item.dart`, `lib/screens/stories/story_reader_screen.dart`: Formlabel, passende Einheiten, getrennte Formzeilen, Status/Konflikt beim Add. `lib/screens/decks/widgets/practice_input.dart`: bestehende Eingabe-/Hinweisregeln mit funktionsbezogenen Labels erhalten. `lib/screens/practice/choice_exercise_screen.dart` nutzt separate ChoiceExercise-Daten für Hören/Grammatik; dies ist kein belegter Formkarten-SRS-Weg. Ihn nicht als vorhandene SRS-Integration ausgeben oder dafür eine zweite Reviewlogik ergänzen. Die Regel eindeutiger Antwortchips gilt bei späterer Nutzung von Auswahlaufgaben ebenfalls. Keine neue allgemeine UI oder zusätzliche Kategorie.
- `docs/user-schema.md`, `PRODUCT.md`, `docs/srs.md`, `DESIGN.md`, `ARCHITECTURE.md` und zugehörige Inhalts-/Storydokumentation bei tatsächlicher Umsetzung angleichen. `tool/report_learning_groups.dart`, `tool/inspect_new_card_selection.dart`: Übungs- und Lexikalprojektion read-only getrennt ausgeben.

**Tests/Abnahme B:** Vorhandene `test/domain/learning_groups_test.dart`, `new_card_selection_test.dart`, `vocab_breakdown_test.dart`, `story_learning_test.dart`, `review_pass_test.dart`, `answer_check_test.dart`; `test/data/story_learning_repository_test.dart`, `story_migration_test.dart`, `preferences_migration_test.dart`, `review_flow_test.dart`, `learning_groups_test.dart`; `test/deck_flow_test.dart`, `learning_integration_test.dart`, `story_learning_flow_test.dart`, `practice_ui_test.dart`, `widget_test.dart`, `test/data/real_pack_test.dart` erweitern.

Akzeptanz: alle sechs Fälle aus Abschnitt 6 durch Domain-, Repository- und Ablaufprüfungen. Gesondert mehrere zugleich fällige gleich geschriebene Formen, inactive deck, disabled/retired, synonymischer Gruppen-Kopf anderer Funktion, lokale Doppelstände, Add-Retry/Parallelität und Provider-Neuberechnung. Neue Form nie mit übernommener Box; gleicher C nie doppelt in Session; Repeat ohne zweite Reviewzeile. Typo/neutral/wrong-form/reveal/early/DST-Termine unverändert. Migration aus v1–v4 auf synthetischen DBs: alte Werte und append-only Reviews exakt, neue Tabellen leer/nullable, Neustart und Rückfall ohne Datenverlust. Bestehendes Schema-3-Asset im realen Lesetest unverändert lesbar; klare neue Einheiten, keine behauptete 390-Wörter-Erweiterung.

Erst nach beiden grünen Paketen folgt **eine gemeinsame Inhaltsauswahl für drei Ansichten** mit tatsächlich geprüftem Reuse-/Owner-/Funktionsmapping. Keine drei unabhängigen Reservierungsläufe. Passende Bestandsübung nicht neu redigieren; neue F anschließend über vorhandenen erweiterten Authoring-ZIP-/Create-Weg. Mengen sind Richtwerte nach diesem Abgleich.

## 8. Installation, Versionen und Rückfall

Content-Schema 4 erst mit kompatiblem Leser aus A+B intern stagen. Der aktuelle Installer validiert Kandidat und Manifest vor Austausch; dieses Verhalten bleibt. Manifestformat muss nicht für Wortzahlen missbraucht werden: schema_version/Release/Hash/Größe und Tabellenzählung genügen. Unbekannte höhere Version ablehnen, funktionierendes installiertes Pack erhalten. Keine In-place-Migration historischer Packs, neue Ausgabe in neuem Versionsverzeichnis.

user.db-v5 migriert nur additiv, keine Aktualisierung alter Reviews oder Umschreibung ihrer card_id/sentence_id. Neue Formmetadaten für bestehende Content-Karten liegen im Content; Installation erzeugt keine Userkarten. Alte lokale Funktionen bleiben null bis belegte Bindung vorliegt. Review-/Kontexttrigger und Geräte-ID erhalten. Schema-Spiegel lokal dokumentieren, keine Servermigration oder Sync in diesen Paketen.

Vor zukünftigem Staging Pack und Manifest sichern und Hashes bestätigen. Erst Validator/Readback, dann Staging/Verify, dann Ablaufprüfung mit synthetischer oder ausdrücklich angefertigter Testkopie. Technische Abnahme bleibt getrennt von öffentlicher Inhaltsfreigabe und Geräte-/Sprachabnahme.

**Rückfall:** bevorzugt kompatible neue App mit vorherigem Schema-3-Pack. Sämtliche neuen Nutzerstände/Reviews/Formbindungen bleiben in v5 gespeichert; fehlende Forminhalte werden als nicht verfügbar gemeldet, niemals gelöscht/retired/umgebunden. Rückkehr zum Schema-4-Pack macht dieselben IDs wieder übbar. Wer die neue Funktion deaktiviert, darf bereits gelernte auflösbare Formreviews nicht unterdrücken; nur Einführung stoppen. Für durchgängige Übbarkeit kann das zuletzt gültige Schema-4-Pack weiterlaufen.

Kein Zurückkopieren einer alten user.db über inzwischen erfolgte neue Reviews. Ein altes App-Binary mit v4-Leser ist **kein unterstützter Datenbank-Downgrade**; dafür kompatiblen Fehlerbehebungsbuild verwenden. Backup dient Sicherung/Diagnose, nicht pauschalem Verlust neuer Lernstände. Keine Löschmigration vorsehen.

## 9. Gegenprüfung und verbleibende Entscheidungen

| Risiko | Konkrete Sperre / Abnahme |
|---|---|
| Dreifache Wortzahl | distinct L getrennt von drei F; globale Summe nicht aus Decksummen; Umklassifizierung separat berichten |
| Doppelte Verbuchung | Session nach C dedupliziert, bestehender Pass-ID-/Transaktionsschutz, Repeat ohne Log; gleiche Karte in zwei Ansichten Test |
| Verlorene Reviews | Gelernte C unabhängig von neuer Gruppierung/Deckaktivierung; keine Lemma-/Oberflächensperre für due; alle Alt-C auflösbar oder sichtbar fehlend |
| Ungewollte Übernahme | Wiederverwendung nur identisches F, keine Box von L/Grundform/Synonym, keine rekey/replaced_by-Kette zwischen Formen |
| Homographenkollision | Neuer ID-Namespace/F-Schlüssel; Storyfunktion explizit, kein Dictionary-last-match; read/cut/run-Test |
| Falsche Antwortfreigabe | accepted nur Zielform; Alternative nur geprüftes konkretes Linkpaar, keine Ableitung aus Gruppen/Alias/L |
| Besitzerwechsel | Alte Registryzeilen exakt erhalten, separate deck_practice_targets; neue Oberfläche höchstens einmal, kein Umhängen alter Karte |
| Falscher alter Gruppenvertreter | ordinary bleibt gruppenbezogen, form bleibt funktionsbezogen bis zur Queue; Test mit gelerntem Synonym anderer Form |
| Rollbackverlust | Keine Userlöschung/kein DB-Downgrade; fehlendes Content nur pausiert verfügbar, Wiederkehr gleicher IDs getestet |

Zwei echte Vertragsänderungen sind klar benannt: Formfunktion erweitert die Identität **neuer** Formkarten (statt Änderungen an alten Hashschlüsseln); die Oberfläche trennt lexikalische Zahl und Übungszähler. Die begründeten Empfehlungen oben schließen diese Architekturentscheidungen für die Umsetzungsvorlage. Sie sind noch nicht implementierter Produktvertrag. Keine zusätzliche pauschale Reviewer-Freigabe gefordert.

Keine offene Grundsatzentscheidung blockiert die technische Umsetzung der Empfehlung. Erst bei späterer Inhaltsauswahl offen: welche ca. 130 geeigneten Bedeutungen, welche vorhandenen festen Sätze/Funktionen exakt wiederverwendbar sind, welche regionalen Varianten im konkreten Satz passen und wie viele wirklich neue L verbleiben. Diese Daten dürfen jetzt nicht erfunden werden. Nicht abgedeckte Präsens-/be-Formen sind bewusst begrenzter Umfang, keine verschwiegene Auffüllaufgabe. Öffentliche Inhaltsfreigabe und Geräteabnahme bleiben außerhalb dieser Planung.

## 10. Tatsächliche Prüfungen dieser Dokumentationsarbeit

Keine Flutter-/Python-Testsuiten, Cloud-Aufrufe, Installationen, Auswahl, Reservierung, Satzlieferung, Migration, Commits oder Pushes. Ausschließlich diese Datei und NEXTSTEPS geändert; Prüfskripte/Logs nur unter `/tmp/irregular-verbs-plan-checks/`.

macOS Terminal, ab Repository-Root:

```text
pipeline/.venv-macos/bin/python /tmp/irregular-verbs-plan-checks/verify_pack.py
```

Der lokale Diagnoseadapter verwendet die **vorhandenen** `build_rows` und `finalize_curation.check_sqlite`. Ausschließlich für diesen Aufruf wird sqlite3.connect auf URI `mode=ro` plus `PRAGMA query_only=ON` begrenzt; Produktionscode unverändert. Beide SQLite-Dateien vollständig mit allen 18 Tabellen gegen die JSON-Zeilen verglichen (wie beim vorhandenen Prüfer ohne created_at), dazu Hash/Größe und Gruppenanzahl aus Primärbesitz. Erstlauf: Exit 1, `TypeError: '<' not supported between instances of 'NoneType' and 'int'` bei Sortierung der Berichtsausgabe, weil Deck-sort nullable ist. Diagnose korrigiert auf explizite NULL-Reihenfolge; keine Datenänderung.

Tatsächlicher zweiter Lauf, Exit 0:

```text
alltag-zuhause 241
arbeit-bildung 245
essen-trinken 250
koerper-gesundheit 249
menschen-beziehungen 245
natur-umwelt 242
allgemeine-sprache 160
reisen 489
PASS natur_umwelt_batch_3_v1 schema 3 internal True
PASS build_rows + check_sqlite: 18 tables, complete row comparison, read-only
PASS primary_goals=2121 cards=2236 owners=2132 sentences=2770 links_total=2764 active_links=2236
PASS asset/source/manifest hash and size
```

Windows PowerShell: dasselbe lokale Diagnoseprogramm nach Übernahme in einen lokalen Temp-Pfad mit `.\pipeline\.venv\Scripts\python.exe <Temp-Pfad>\verify_pack.py` ausführen; es setzt nur Repository-Root als Arbeitsverzeichnis voraus. Hier ausschließlich macOS ausgeführt. Git-Prüfbefehle sind auf beiden Systemen identisch; für neue untracked Dateien ist zusätzlich ein No-index-Check nötig.

Abschließende tatsächliche Dokument-/Bestandsprüfung:

```text
git diff --check -- docs/irregular-verbs-implementation-plan.md NEXTSTEPS.md
Exit 2: NEXTSTEPS.md:1 bis :25: trailing whitespace (erhaltenes CRLF).
git -c core.whitespace=cr-at-eol diff --check -- docs/irregular-verbs-implementation-plan.md NEXTSTEPS.md
Exit 0; keine Ausgabe.
git diff --no-index --check /dev/null docs/irregular-verbs-implementation-plan.md
Exit 1; keine Ausgabe (untracked neue Datei, keine Whitespace-Diagnostik).
git -c core.whitespace=cr-at-eol diff --no-index --check /tmp/irregular-verbs-plan-checks/NEXTSTEPS.before.md NEXTSTEPS.md
Exit 1; keine Ausgabe (Dateiunterschied, keine Whitespace-Diagnostik).
PASS baseline: 2565 files; 2564 unchanged; changed: ['NEXTSTEPS.md']
PASS unchanged assets/content/en/content.sqlite 34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7
PASS unchanged assets/content/en/content.manifest.json e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b
PASS unchanged pipeline/out/natur_umwelt_batch_3_v1/pack.json 7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e
PASS unchanged pipeline/out/natur_umwelt_batch_3_v1/content.sqlite 34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7
NEXTSTEPS lines: 25
PASS CRLF retained: 25
Exit 0 (Bestands-/Hashprüfung).
```

Für Windows beim No-index-Check `NUL` statt `/dev/null` und den tatsächlichen Temp-Pfad verwenden. Die vollständige gezielte CRLF-Ausgabe ist `diff-0.log`, weitere Ausgaben `diff-1.log` bis `diff-3.log` im genannten temporären Prüfverzeichnis. Bestehende Dateipfade des Plans gegen das Repository geprüft; nur die ausdrücklich **neu geplante** v3-Importspezifikation existiert noch nicht. Keine Produktionsschnittstelle als bereits umgesetzt ausgegeben.

Getrennte bekannte repositoryweite Altbefunde aus den vorhandenen Berichten: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Hier weder global erneut ausgegeben noch bereinigt. CRLF in NEXTSTEPS vollständig erhalten; neue Plandatei verwendet LF. Kein fachlicher Pack-/Mengenkonflikt festgestellt; die oben benannten Produkt-/Identitätskonflikte sind zukünftige Vertragsarbeit, keine vorweggenommene Implementierung.
