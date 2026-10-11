# Unregelmäßige Verben: gemeinsame Auswahl und Authoring

Stand: 10.10.2026. **Die drei Verbenstapel sind technisch intern abgeschlossen: 134/134/134 Übungen, 134 lexikalische Verbidentitäten, 402/402 Formziele importiert.** Über vier Batches 331 neue feste Satzpaare und 71 unveränderte Wiederverwendungen. `irregular_verbs_batch_4_v1` ist intern gestagt und verifiziert; gemeinsame App-Projektion: 2453 Übungen / 2182 Wörter. Kein Restbatch oder Batch 5. Öffentliche Sprach-/Inhaltsfreigabe bleibt getrennt. Nachweis: [Gesamtabschluss](irregular-verbs-batch-4-import.md).

## Historischer Ausgangsstand und Auswahl-/Authoring-Dateien

Manifest: `assets/content/en/content.manifest.json`; Basis `pipeline/out/natur_umwelt_batch_3_v1/pack.json` und `content.sqlite` derselben Lieferung. Schema 3, 18 Tabellen, 2236 Karten, 2770 Satztexte, 2764 historische Satzlinks, 2236 aktive feste Links. Acht bestehende Stapel und 2121 besitzgebundene primäre Lernziele:

| Stapel | Primäre Ziele |
|---|---:|
| Allgemeine Sprache | 160 |
| Reisen | 489 |
| Alltag & Zuhause | 241 |
| Arbeit & Bildung | 245 |
| Menschen & Beziehungen | 245 |
| Körper & Gesundheit | 249 |
| Essen & Trinken | 250 |
| Natur & Umwelt | 242 |

Ausgangssnapshots: `pipeline/data/words/en.natur_umwelt_batch_3_context_v1.json`, `pipeline/data/learning_groups/en.natur_umwelt_batch_3_context_v1.json`, `pipeline/data/selection/natur_umwelt_batch_3_context_v1.json`. Die tatsächlich im Pack gebundenen `cards.learning`-Zeilen sind für die aktuellen Gruppen maßgeblich. Der Registry-Elternhash ist `f6e248b3e64c5a956ef7997cf0a2fab0dcfd2bd66c33335c3879a110e681c8f5`.

Dateien des ursprünglichen Auswahl-/Authoring-Schritts:

- `pipeline/data/selection/irregular_verbs_v1.json`: ein gemeinsamer Form-Auswahlvertrag v2, vollständiger Katalog, Wiederverwendungsbelege und vier Metadatendeltas.
- `pipeline/data/words/en.irregular_verbs_v1.json`: alter Wortbesitz als unverändertes Präfix; nur neue Reservierungen angehängt.
- `pipeline/data/learning_groups/en.irregular_verbs_v1.json`: beschreibender Gesamtsnapshot aller bisherigen und geplanten Karten mit bestehenden Gruppenfeldern; Status `planned-form-metadata-only`, keine Anwendung auf Produktionsdaten.
- `build/irregular_verbs_authoring_batch_1.zip`: geprüfter Chat-Kontext.
- Dieser Bericht; aktualisierte `NEXTSTEPS.md`.

Kleine Werkzeugkorrektur: `pipeline/scripts/export_authoring_context.py`; Regression: `pipeline/tests/test_form_authoring_details.py`.

## Auswahl, Wiederverwendung und Zählung

134 nützliche heutige Verben wurden gemeinsam ausgewählt; keine Auffüllung auf eine exakte Quote. Jede Familie hat eine abgegrenzte Bedeutung und die Funktionen Grundform, Präteritum, Partizip. Die bevorzugten Formen und Bedeutungen stehen vollständig unten und in `selection.editorial_catalog`.

| Größe | Anzahl |
|---|---:|
| Lexikalische Ziele insgesamt | 134 |
| Bereits mit Lernkarten vorhanden | 67 |
| Tatsächlich neue Lernbedeutungen | 67 |
| Bedeutungen bereits im Wörterbuch vorhanden | 104 |
| Neu erforderliche Sense-Zeilen | 30 |
| Formziele je Ansicht | 134 |
| Formübungen insgesamt | 402 |
| Exakt wiederverwendete Karten samt festen Sätzen | 71 |
| Neue Formkarten und später zu redigierende Satzpaare | 331 |
| Neue Oberflächenreservierungen | 224 |
| Alte zusätzlich/vollständig lexikalisch zugeordnete Karten | 75 |

Die 67 neuen Lernbedeutungen bestehen aus 37 bereits nur im Wörterbuch vorhandenen und 30 neuen Bedeutungen. 134 neue **technische** `lexical_targets`-Zeilen sind kein Nachweis für 134 neue Wörter: Die Schema-3-Basis hatte noch keine expliziten Lexikalzeilen.

75 alte Karten aus 74 Lerngruppen werden vollständig 67 belegten Konzepten zugeordnet. Davon gehören 73 Gruppen zur bisherigen besitzgebundenen Primärzielzählung: nach Zuordnung 67, also **sechs weniger**. Für die gemeinsame sichtbare lexikalische Zielmenge ist nach sämtlichen künftigen Importen **2121 − 6 + 67 = 2182** zu erwarten. Diese Vorausrechnung zählt die 402 Übungen nicht als neue Wörter und verändert jetzt keinen Zähler. Über sämtliche Karten gibt es im Ausgangspack 2224 Gruppen, einschließlich nicht als eigene Besitzer-Primärziele gezählter Gruppen; die vollständige Gruppenprojektion reduziert hier sieben Altgruppen. Diese beiden Zählräume dürfen nicht vermischt werden.

Wiederverwendung wurde anhand von Lemma/POS, konkreter Bedeutung, tatsächlichem festen Satz, syntaktischer Formfunktion, Besitzer und Gruppe entschieden. Alte `form_kind`-Werte und gelegentlich flektierte Altglossen sind keine Entscheidungsgrundlage. Jede Wiederverwendung bindet den vollständigen Karten- und Satzkontext durch `card_sha256`/`context_sha256`. Alle alten IDs, Texte, Tokens, Gruppen und Besitzer bleiben unverändert. Neue Karten besitzen funktionsgebundene IDs und eigene Singleton-Übungsgruppen.

Sonderzuordnungen:

- **be:** Kopula für Zustand/Eigenschaft, `be / was / been`. Die vorhandenen konkreten Kontexte sind Imperativ `be`, Vergangenheitsfrage `was` und Perfect `been`. Historisch getrennte Sense-IDs werden erhalten; `is` und `are` derselben Kopulabedeutung vollständig mit zugeordnet. Hilfsverb, Ortsangabe, Besuchsbedeutung und hypothetisches `were` bleiben getrennt. `was` ist repräsentativ; kein vollständiges Präsensparadigma, vorhandene andere Formen bleiben bestehen.
- **have:** Besitz/Verfügbarkeit, vorhandenes `have / had / had`; tatsächliche Past-/Perfect-Sätze unterscheiden die zwei alten `had`-Karten. `has` wird vollständig mit zugeordnet. Hilfsverb, Nahrungsaufnahme und Verpflichtung bleiben getrennt.
- **understand:** Die bestehende Gruppe umfasst bereits `get` in der Bedeutung „verstehen“. Beide Karten werden derselben Lexikalidentität zugeordnet. `get` als eigenes Formziel bedeutet dagegen „bekommen“; kein Zusammenlegen nur wegen gleicher Schreibweise.
- **run**, **cut**, **read:** Gleich geschriebene Funktionen bleiben eigenständige Formidentitäten. `read` Grundform /riːd/, Vergangenheit/Partizip /red/; Aussprachehinweis ohne Audioleistung.
- **lie** bedeutet liegen (`lay/lain`), die vorhandene Karte „lügen“ ist keine Wiederverwendung. **lay** bedeutet etwas legen (`laid/laid`). `lain` ist weniger alltagshäufig, bleibt aber das heutige Partizip dieser Grundbedeutung.
- **hang**: Gegenstände aufhängen, `hung`; Hinrichtung/`hanged` ausgeschlossen. **bear**: ertragen, `borne`; bestehendes Wörterbuch-`born` für Geburt nicht übernommen.
- **shine**: Licht aussenden, `shone`; Polieren/`shined` ausgeschlossen. **cost**: einen Preis haben, `cost`; Kosten kalkulieren/`costed` ausgeschlossen. **strike**: Saiten anschlagen, `struck`, keine pauschale Freigabe von `stricken`.
- Bestehende engere Bedeutungen gelten weiter: `fly` Flugreise, `ride` als Fahrgast, `hurt` seelisch verletzen, `wake` jemanden wecken, `spread` weiche Masse aufstreichen, `set` einen Gegenstand hinstellen, `tell` jemandem etwas mitteilen.

Bevorzugt werden verbreitete britische unregelmäßige Varianten, etwa `learnt`, `dreamt`, `burnt`, `smelt`, `spelt`, `spilt`, `spoilt`. `proven` ist ausdrücklich als moderne Partizipvariante ausgewählt; `proved` bleibt ein später satzbezogen zu prüfender Kandidat. Entsprechendes gilt für regelmäßige Varianten, `gotten`, `kneeled`, `leaned`, `leaped`, `lighted`, `mowed`, `sowed` und regionale `spit`-Formen. Der Katalog dokumentiert diese Varianten, ohne Antworten vorab freizugeben. Aliase, gleiche Bedeutungen und Verbverwandtschaft erlauben niemals automatisch eine Antwort. Ein primäres Ziel erhält einen festen Übungssatz; bestätigte Alternativen bleiben lernstandsneutral.

Zurückgestellt wurden `awake` zugunsten des alltagsnäheren `wake`, außerdem `creep`, `fling`, `spring`, `stink`, `weep` nach Priorisierung dieses Umfangs. `speed` wurde wegen zusätzlicher bedeutungs-/variantenbezogener Abgrenzung nicht aufgenommen. Literarische/seltene Kandidaten wie `abide`, `beseech`, `cleave`, `forbear`, `forsake`, `slay`, `smite`, `stride` und `strive` dienen nicht als Mengenfüller. Das sind Auswahlentscheidungen, keine Behauptung, alle ausgelassenen Verben seien veraltet. Keine ungelöste konkurrierende Altkarte wurde durch Umbenennung oder eine künstliche Tempus-Sense umgangen.

## Quellen und redaktionelle Abgrenzung

Recherche am 10.10.2026, ausschließlich lesend. Formen sind Sprachfakten; Definitionen und Auswahlentscheidungen wurden für diesen Katalog formuliert. Keine Beispielssätze aus Quellen übernommen oder neu erzeugt.

- [Cambridge University Press: Irregular verbs](https://www.cambridge.org/core/services/aop-file-manager/file/5bd88a176431f1de07115e71/216-Irregular-verbs.pdf): vollständige achtseitige Formliste, alle 134 ausgewählten Paradigmen abgeglichen. Die Quelle weist selbst auf unterschiedliche Gebräuchlichkeit/Standardnähe von Varianten hin; seltene Nebenformen wurden nicht pauschal übernommen.
- [British Council: Irregular verbs](https://learnenglish.britishcouncil.org/free-resources/grammar/english-grammar-reference/irregular-verbs): verbreitete Grundparadigmen und regionale Einordnung von `got/gotten`.
- [Cambridge: Lie or lay](https://dictionary.cambridge.org/grammar/british-grammar/lie-lay), [Lay and lie](https://dictionary.cambridge.org/grammar/british-grammar/word-choice-lay-and-lie): liegen, legen und lügen getrennt.
- [Cambridge: hang](https://dictionary.cambridge.org/dictionary/english/hang), [read](https://dictionary.cambridge.org/us/dictionary/english/read): Bedeutungsabhängigkeit und Aussprache.
- [American Heritage: shine](https://ahdictionary.com/word/search.html?q=shine): Licht aussenden gegenüber polieren.
- [Cambridge: born or borne](https://dictionary.cambridge.org/us/grammar/british-grammar/born-or-borne), [prove](https://dictionary.cambridge.org/us/dictionary/english/prove), [Oxford: prove](https://www.oxfordlearnersdictionaries.com/definition/english/prove): ergänzende Suchauszüge zu Bedeutung/Varianten. Die Cambridge-Einzelseiten lieferten beim erneuten direkten Abruf HTTP 403; nicht als vollständig gelesene Seiten ausgegeben. `bore/borne` und `proved/proven` sind zusätzlich in der vollständig gelesenen CUP-Liste belegt.

## Batchbildung und ZIP-Vertrag

| Batch | Familien / Ziele je Funktion | Formziele | Wiederverwendet | Neue Satzpaare |
|---|---:|---:|---:|---:|
| 1 | 33 | 99 | 16 | 83 |
| 2 | 35 | 105 | 22 | 83 |
| 3 | 33 | 99 | 15 | 84 |
| 4 | 33 | 99 | 18 | 81 |
| Gesamt | 134 | 402 | 71 | 331 |

Alle drei Funktionen sind in jedem Batch vertreten; vollständige Familien, Gruppen-/Sense-Zuordnungen und Besitzerabhängigkeiten bleiben zusammen. Besitzerpositionen werden angehängt, Praxispositionen sind pro Ansicht fortlaufend. Batch 1: **0 importiert / 99 aktuell / 303 später**, wobei nur 83 der aktuellen Ziele neue Satzaufträge sind. Die 16 alten festen Sätze werden unverändert wiederverwendet.

Der bestehende Form-Exporter schreibt die tatsächliche hashgebundene JSON-/SQLite-Basis, sämtliche zukünftigen Metadaten, Registry, ursprüngliche Gruppen, neuen Gesamtsnapshot, Funktionen/Definitionen, Wörterbuch, Importer/V3-Schema und Offline-Tokenizerkontext in dieselbe ZIP. `authoring/current_authoring_tasks.json` trennt `new_sentence_pairs` von `unchanged_reuse`; Letzteres enthält unveränderte Kontexte und Belege. `authoring/selection.json` enthält alle späteren Ziele und redaktionellen Variantenhinweise. `authoring/planned_learning_groups.json` entspricht dem neuen lokalen Gruppensnapshot.

Die notwendige Werkzeugergänzung beschränkt sich auf diese abgeleiteten Gruppen-/Auftragsdateien, semantische Verifikation auch nach manipulierten Dateihashes und die erneute Gruppenbindung bei Fortsetzungen. Alte Form-ZIPs bleiben prüfbar. Kein zweiter Exportweg, keine Import-/App-/SRS-/Antwortlogik geändert. Die Regression prüft Trennung von Reuse und Aufträgen, zukünftige Gruppen, nach Neuhashung gefälschte Gruppen/Aufträge sowie Export nach synthetischem Batch-1-Import und Fortsetzung.

**Historische Prüfgrenze vor Batch 1:** Alle damaligen aktuellen und zukünftigen Identitäten, Referenzen, Registry-/Gruppenbindungen und vier Metadatenpräfixe sind geprüft. Die 331 noch fehlenden Sätze, Übersetzungen, Zieltoken, Reviews und konkreten Alternativen sind ausdrücklich nicht geprüft oder vorab genehmigt. Es wurden keine Produktionssatzzeilen oder Tokenreviews erzeugt. Erst nach Chat-Redaktion folgt der bestehende Importpfad.

## Historische Prüfungen des Auswahl-/Authoring-Schritts

Die folgenden Python-Aufrufe sind plattformgleich; auf macOS wurde `pipeline/.venv-macos/bin/python` verwendet. Auf Windows/PowerShell ist der vorhandene Projektinterpreter gemäß Setup an dessen Stelle einzusetzen. Es wurden keine Pakete installiert. Der temporäre Auditpfad unten gehört nur zum ausführenden macOS-Arbeitslauf.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_form_targets.py pipeline/tests/test_form_authoring_details.py pipeline/tests/test_word_registry.py pipeline/tests/test_selection.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py -q
........................................................................ [ 80%]
..................                                                       [100%]
90 passed in 17.54s
Exit 0
```

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_v1.json --batch 1 --out build/irregular_verbs_authoring_batch_1.zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_1.zip
Exit 0
```

Beide Ausgaben waren identisch bis auf den Aufruf; die folgende tatsächlich ausgegebene Zusammenfassung ersetzt nur die 402 ausgeschriebenen Referenzen durch Partitionslängen (alle Referenzen liegen in der ZIP):

```json
{
  "zip_verification": "PASS",
  "zip_sha256": "6ea74bff18c1d2b4d37051ce34805f11860576983476ad91cefe341ec5c17f10",
  "content_schema_version": 4,
  "sqlite_tables": 18,
  "counts": {
    "imported": 0,
    "current": 99,
    "future": 303,
    "reused_cards": 71,
    "new_form_targets": 402,
    "new_lexical_targets": 134,
    "new_surface_reservations": 224,
    "new_cards": 331
  },
  "partition_counts": {
    "imported": 0,
    "current": 99,
    "future": 303
  }
}
```

Die ZIP wurde geschlossen, erneut geöffnet und vollständig mit dem vorhandenen Verifier geprüft: CRCs, alle Manifest-Dateihashes, semantischer Kontext und alle Zeilen der 18 Quell-SQLite-Tabellen. `content_schema_version: 4` bezeichnet das Importziel mit 22 Tabellen, nicht die enthaltene Schema-3-Basis.

```text
pipeline/.venv-macos/bin/python /tmp/irregular-verbs-authoring/audit.py
BASE: schema 3, 18 tables, 8 decks, 2121 primary goals; source/asset/manifest binding PASS
SELECTION: {"current": 99, "future": 303, "imported": 0, "new_cards": 331, "new_form_targets": 402, "new_lexical_targets": 134, "new_surface_reservations": 224, "reused_cards": 71}
GROUP_SNAPSHOT: all old and planned cards, identities and group heads PASS
PREFIX 1: metadata PASS; 99 forms; new sentence pairs 83; missing sentences NOT approved
PREFIX 2: metadata PASS; 204 forms; new sentence pairs 83; missing sentences NOT approved
PREFIX 3: metadata PASS; 303 forms; new sentence pairs 84; missing sentences NOT approved
PREFIX 4: metadata PASS; 402 forms; new sentence pairs 81; missing sentences NOT approved
COUNTING: 134 lexical targets = 67 existing + 67 new; 75 old cards in 74 groups map to 67 concepts. Of these, 73 owner-primary goals map to 67 concepts: visible reclassification -6; forecast 2121-6+67=2182 after ALL imports, not staged. Total source learning groups: 2224 (not the 2121 owner-primary goals).
PARTITION: 0 imported / 99 current (83 new + 16 reused) / 303 future; disjoint and exhaustive PASS
NEW OWNERS: 224; old reservations unchanged; no new aliases PASS
SOURCE HASHES:
7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e pipeline/out/natur_umwelt_batch_3_v1/pack.json
34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7 pipeline/out/natur_umwelt_batch_3_v1/content.sqlite
34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7 assets/content/en/content.sqlite
e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b assets/content/en/content.manifest.json
BASELINE: 2592 pre-existing files checked; changed: ['pipeline/scripts/export_authoring_context.py'] ; all other files unchanged PASS
Exit 0
```

Abweichungen im Arbeitslauf: Ein temporärer Auswahlentwurf nahm zunächst ein `sort`-Feld bei allen acht Decks an (`KeyError`, Exit 1); tatsächliche Bestandsdecks ohne dieses optionale Feld wurden berücksichtigt. Ein erster Audit verglich fälschlich alle Gruppen mit der Besitzer-Primärzahl 2121 (`AssertionError`, Exit 1). Der Abgleich wurde anhand der tatsächlichen Besitzer-Primärbindungen korrigiert; 2224 Gesamtgruppen werden gesondert ausgewiesen. Keine Produktionsdaten wurden an Erwartungen angepasst.

## Vollständiger redaktioneller Katalog

Reihenfolge zugleich eingefrorene Praxisposition. „Alt“ bedeutet wiederverwendete Formkarten, keine neuen Satzaufträge. Exakte Sense-/Kartenrefs, vollständige zusätzliche Gruppenabdeckung und Hashbelege stehen im JSON-Auswahlkatalog.

| Nr. | Grundform | Präteritum | Partizip | Gewählte Bedeutung | Batch | Alt |
|---:|---|---|---|---|---:|---:|
| 1 | arise | arose | arisen | Ein Problem oder eine Situation entsteht. | 1 | 0 |
| 2 | be | was | been | Einen Zustand oder eine Eigenschaft haben. | 1 | 3 |
| 3 | bear | bore | borne | Etwas Belastendes aushalten. | 1 | 0 |
| 4 | beat | beat | beaten | Zutaten durch wiederholtes Schlagen vermischen. | 1 | 0 |
| 5 | become | became | become | In einen anderen Zustand übergehen. | 1 | 0 |
| 6 | begin | began | begun | Mit einer Tätigkeit anfangen. | 1 | 0 |
| 7 | bend | bent | bent | Einen Körperteil anwinkeln. | 1 | 1 |
| 8 | bet | bet | bet | Geld auf den Ausgang eines Ereignisses setzen. | 1 | 0 |
| 9 | bind | bound | bound | Etwas mit einer Schnur fest zusammenhalten. | 1 | 0 |
| 10 | bite | bit | bitten | Mit den Zähnen in etwas eindringen. | 1 | 1 |
| 11 | bleed | bled | bled | Blut aus einer Wunde verlieren. | 1 | 1 |
| 12 | blow | blew | blown | Luft mit dem Mund ausstoßen. | 1 | 0 |
| 13 | break | broke | broken | Einen festen Gegenstand in Stücke gehen lassen. | 1 | 1 |
| 14 | breed | bred | bred | Tiere gezielt zur Fortpflanzung bringen. | 1 | 0 |
| 15 | bring | brought | brought | Etwas zu einer Person oder an einen Ort tragen. | 1 | 1 |
| 16 | broadcast | broadcast | broadcast | Eine Sendung über Radio oder Fernsehen verbreiten. | 1 | 0 |
| 17 | build | built | built | Aus Bestandteilen etwas errichten oder zusammensetzen. | 1 | 0 |
| 18 | burn | burnt | burnt | Brennstoff durch Feuer verbrauchen. | 1 | 0 |
| 19 | burst | burst | burst | Durch inneren Druck plötzlich aufreißen. | 1 | 0 |
| 20 | buy | bought | bought | Etwas gegen Geld erwerben. | 1 | 1 |
| 21 | catch | caught | caught | Einen bewegten Gegenstand mit den Händen aufnehmen. | 1 | 1 |
| 22 | choose | chose | chosen | Sich für eine von mehreren Möglichkeiten entscheiden. | 1 | 1 |
| 23 | cling | clung | clung | Sich an etwas festhalten, um nicht loszulassen. | 1 | 0 |
| 24 | come | came | come | Sich auf einen Bezugspunkt zubewegen. | 1 | 0 |
| 25 | cost | cost | cost | Einen bestimmten Kaufpreis haben. | 1 | 0 |
| 26 | cut | cut | cut | Etwas mit einer scharfen Klinge teilen. | 1 | 1 |
| 27 | deal | dealt | dealt | Spielkarten an die Mitspielenden verteilen. | 1 | 0 |
| 28 | dig | dug | dug | Mit einem Werkzeug Erde ausheben. | 1 | 0 |
| 29 | do | did | done | Eine Tätigkeit ausführen. | 1 | 1 |
| 30 | draw | drew | drawn | Ein Bild mit Linien anfertigen. | 1 | 1 |
| 31 | dream | dreamt | dreamt | Im Schlaf Bilder und Ereignisse erleben. | 1 | 0 |
| 32 | drink | drank | drunk | Flüssigkeit zu sich nehmen. | 1 | 1 |
| 33 | drive | drove | driven | Ein Fahrzeug steuern. | 1 | 1 |
| 34 | eat | ate | eaten | Nahrung zu sich nehmen. | 2 | 1 |
| 35 | fall | fell | fallen | Sich durch Schwerkraft nach unten bewegen. | 2 | 1 |
| 36 | feed | fed | fed | Einem Tier Nahrung geben. | 2 | 1 |
| 37 | feel | felt | felt | Einen körperlichen oder emotionalen Zustand empfinden. | 2 | 1 |
| 38 | fight | fought | fought | Sich körperlich mit jemandem auseinandersetzen. | 2 | 1 |
| 39 | find | found | found | Etwas Gesuchtes entdecken. | 2 | 1 |
| 40 | flee | fled | fled | Einen gefährlichen Ort rasch verlassen. | 2 | 0 |
| 41 | fly | flew | flown | Als Reisender mit einem Flugzeug unterwegs sein. | 2 | 1 |
| 42 | forbid | forbade | forbidden | Eine Handlung ausdrücklich nicht erlauben. | 2 | 0 |
| 43 | forget | forgot | forgotten | Etwas nicht mehr im Gedächtnis haben. | 2 | 1 |
| 44 | forgive | forgave | forgiven | Jemandem einen Fehler nicht mehr vorwerfen. | 2 | 1 |
| 45 | freeze | froze | frozen | Durch Kälte vom flüssigen in den festen Zustand übergehen. | 2 | 1 |
| 46 | get | got | got | Etwas erhalten. | 2 | 1 |
| 47 | give | gave | given | Etwas einer anderen Person überlassen. | 2 | 0 |
| 48 | go | went | gone | Sich zu einem anderen Ort bewegen. | 2 | 0 |
| 49 | grow | grew | grown | An Größe zunehmen. | 2 | 0 |
| 50 | hang | hung | hung | Etwas von oben befestigen, sodass es herabhängt. | 2 | 1 |
| 51 | have | had | had | Etwas besitzen oder darüber verfügen. | 2 | 3 |
| 52 | hear | heard | heard | Einen Laut mit den Ohren wahrnehmen. | 2 | 0 |
| 53 | hide | hid | hidden | Etwas so unterbringen, dass man es nicht sieht. | 2 | 0 |
| 54 | hit | hit | hit | Mit der Hand oder einem Gegenstand treffen. | 2 | 0 |
| 55 | hold | held | held | Etwas mit den Händen festhalten. | 2 | 1 |
| 56 | hurt | hurt | hurt | Jemandem seelischen Schmerz zufügen. | 2 | 1 |
| 57 | keep | kept | kept | Etwas behalten und sicher verwahren. | 2 | 0 |
| 58 | kneel | knelt | knelt | Auf einem oder beiden Knien ruhen. | 2 | 1 |
| 59 | know | knew | known | Eine Information im Gedächtnis haben. | 2 | 0 |
| 60 | lay | laid | laid | Etwas in eine liegende Lage bringen. | 2 | 0 |
| 61 | lead | led | led | Jemandem den Weg zeigen und vorangehen. | 2 | 0 |
| 62 | lean | leant | leant | Den Oberkörper in eine Richtung beugen. | 2 | 1 |
| 63 | leap | leapt | leapt | Mit einem kräftigen Sprung eine Strecke überwinden. | 2 | 0 |
| 64 | learn | learnt | learnt | Sich Wissen oder Fähigkeiten aneignen. | 2 | 1 |
| 65 | leave | left | left | Von einem Ort weggehen. | 2 | 1 |
| 66 | lend | lent | lent | Etwas vorübergehend jemandem zur Nutzung geben. | 2 | 1 |
| 67 | let | let | let | Jemandem eine Handlung ermöglichen oder erlauben. | 2 | 0 |
| 68 | lie | lay | lain | In waagerechter Lage auf einer Fläche ruhen. | 2 | 0 |
| 69 | light | lit | lit | Etwas zum Brennen bringen. | 3 | 0 |
| 70 | lose | lost | lost | Etwas nicht mehr finden oder bei sich haben. | 3 | 1 |
| 71 | make | made | made | Etwas durch Arbeit anfertigen. | 3 | 0 |
| 72 | mean | meant | meant | Einen bestimmten Sinn haben. | 3 | 0 |
| 73 | meet | met | met | Mit jemandem an einem Ort zusammenkommen. | 3 | 1 |
| 74 | mistake | mistook | mistaken | Eine Person oder Sache irrtümlich für eine andere halten. | 3 | 0 |
| 75 | mow | mowed | mown | Gras mit einem Mäher kürzen. | 3 | 1 |
| 76 | overcome | overcame | overcome | Eine Schwierigkeit erfolgreich bewältigen. | 3 | 0 |
| 77 | overtake | overtook | overtaken | An einem langsameren Fahrzeug vorbeifahren. | 3 | 0 |
| 78 | pay | paid | paid | Geld für eine Ware oder Leistung geben. | 3 | 1 |
| 79 | prove | proved | proven | Mit Nachweisen zeigen, dass eine Aussage zutrifft. | 3 | 1 |
| 80 | put | put | put | Etwas an einem bestimmten Ort ablegen. | 3 | 0 |
| 81 | quit | quit | quit | Eine Tätigkeit endgültig beenden. | 3 | 0 |
| 82 | read | read | read | Geschriebene Wörter verstehen. | 3 | 1 |
| 83 | ride | rode | ridden | Als Fahrgast in einem Fahrzeug befördert werden. | 3 | 1 |
| 84 | ring | rang | rung | Ein deutliches Glocken- oder Klingelgeräusch erzeugen. | 3 | 0 |
| 85 | rise | rose | risen | Sich nach oben bewegen. | 3 | 0 |
| 86 | run | ran | run | Sich schnell mit Laufschritten fortbewegen. | 3 | 0 |
| 87 | say | said | said | Wörter laut äußern. | 3 | 1 |
| 88 | see | saw | seen | Etwas mit den Augen wahrnehmen. | 3 | 0 |
| 89 | seek | sought | sought | Versuchen, etwas Benötigtes zu finden. | 3 | 0 |
| 90 | sell | sold | sold | Etwas gegen Geld abgeben. | 3 | 1 |
| 91 | send | sent | sent | Eine Nachricht an einen Empfänger übermitteln. | 3 | 1 |
| 92 | set | set | set | Einen Gegenstand an einem bestimmten Ort abstellen. | 3 | 0 |
| 93 | shake | shook | shaken | Etwas mehrfach rasch hin und her bewegen. | 3 | 1 |
| 94 | shine | shone | shone | Licht aussenden. | 3 | 0 |
| 95 | shoot | shot | shot | Ein Geschoss mit einer Waffe abfeuern. | 3 | 0 |
| 96 | show | showed | shown | Die Aufmerksamkeit auf etwas Sichtbares lenken. | 3 | 1 |
| 97 | shut | shut | shut | Eine Tür oder Öffnung zumachen. | 3 | 0 |
| 98 | sing | sang | sung | Mit der Stimme eine Melodie erzeugen. | 3 | 1 |
| 99 | sink | sank | sunk | Unter die Wasseroberfläche hinabgehen. | 3 | 0 |
| 100 | sit | sat | sat | Mit abgestütztem Gesäß ruhen. | 3 | 1 |
| 101 | sleep | slept | slept | Im natürlichen Ruhezustand schlafen. | 3 | 1 |
| 102 | slide | slid | slid | Etwas gleitend entlang einer Fläche bewegen. | 4 | 0 |
| 103 | smell | smelt | smelt | Einen Geruch mit der Nase wahrnehmen. | 4 | 1 |
| 104 | sow | sowed | sown | Samen zum Keimen in den Boden bringen. | 4 | 1 |
| 105 | speak | spoke | spoken | Sich in einer Sprache mündlich ausdrücken. | 4 | 1 |
| 106 | spell | spelt | spelt | Die Buchstaben eines Wortes der Reihe nach nennen. | 4 | 1 |
| 107 | spend | spent | spent | Zeit mit einer Tätigkeit oder an einem Ort verbringen. | 4 | 0 |
| 108 | spill | spilt | spilt | Flüssigkeit versehentlich aus einem Gefäß gelangen lassen. | 4 | 1 |
| 109 | spin | spun | spun | Sich schnell um die eigene Achse bewegen. | 4 | 0 |
| 110 | spit | spat | spat | Speichel aus dem Mund ausstoßen. | 4 | 1 |
| 111 | split | split | split | Etwas der Länge nach in Teile trennen. | 4 | 0 |
| 112 | spoil | spoilt | spoilt | Etwas Angenehmes beeinträchtigen oder zunichtemachen. | 4 | 0 |
| 113 | spread | spread | spread | Eine weiche Masse gleichmäßig auf einer Fläche verteilen. | 4 | 1 |
| 114 | stand | stood | stood | Aufrecht auf den Füßen sein. | 4 | 1 |
| 115 | steal | stole | stolen | Etwas ohne Erlaubnis wegnehmen. | 4 | 0 |
| 116 | stick | stuck | stuck | An einer Oberfläche festkleben. | 4 | 0 |
| 117 | sting | stung | stung | Mit einem Stachel Gift in die Haut bringen. | 4 | 1 |
| 118 | strike | struck | struck | Durch einen Schlag einen Ton erzeugen. | 4 | 0 |
| 119 | swear | swore | sworn | Etwas mit einem feierlichen Versprechen zusichern. | 4 | 0 |
| 120 | sweep | swept | swept | Schmutz mit einem Besen entfernen. | 4 | 1 |
| 121 | swim | swam | swum | Sich mit Körperbewegungen durch Wasser bewegen. | 4 | 1 |
| 122 | swing | swung | swung | Sich pendelnd hin und her bewegen. | 4 | 0 |
| 123 | take | took | taken | Etwas greifen und an sich nehmen. | 4 | 0 |
| 124 | teach | taught | taught | Jemandem Wissen oder Fähigkeiten vermitteln. | 4 | 1 |
| 125 | tear | tore | torn | Material durch Ziehen auseinanderreißen. | 4 | 0 |
| 126 | tell | told | told | Jemandem eine Information mündlich geben. | 4 | 1 |
| 127 | think | thought | thought | Eine Meinung über etwas haben. | 4 | 0 |
| 128 | throw | threw | thrown | Etwas durch eine Armbewegung durch die Luft bewegen. | 4 | 1 |
| 129 | understand | understood | understood | Den Sinn einer Äußerung erfassen. | 4 | 1 |
| 130 | wake | woke | woken | Bewirken, dass jemand nicht mehr schläft. | 4 | 1 |
| 131 | wear | wore | worn | Kleidung am Körper haben. | 4 | 1 |
| 132 | win | won | won | In einem Wettbewerb erfolgreich sein. | 4 | 0 |
| 133 | withdraw | withdrew | withdrawn | Geld von einem Konto entnehmen. | 4 | 0 |
| 134 | write | wrote | written | Wörter schriftlich festhalten. | 4 | 1 |

## Abschließender Dateiabgleich und Whitespace

```text
git diff --check -- NEXTSTEPS.md pipeline/scripts/export_authoring_context.py docs/irregular-verbs-authoring.md pipeline/tests/test_form_authoring_details.py pipeline/data/selection/irregular_verbs_v1.json pipeline/data/words/en.irregular_verbs_v1.json pipeline/data/learning_groups/en.irregular_verbs_v1.json
(keine Ausgabe)
Exit 0
WHITESPACE: 7 task files PASS (including untracked files)
FINAL ZIP/LOCAL: exact selection, registry, planned groups, exporter bytes PASS; CRC PASS; new tasks 83 reuse 16
NEXTSTEPS: 25 lines
Exit 0
```

Die zusätzliche Dateiprüfung verglich ZIP-Einträge bytegenau mit den lokalen neuen Snapshots und dem Exporter und prüfte auch ungetrackte Dateien auf nachgestellte Leerzeichen. Der finale Baseline-Abgleich über 2592 vorbestehende Dateien ergab ausschließlich Änderungen an `pipeline/scripts/export_authoring_context.py` und `NEXTSTEPS.md`; alle anderen vorbestehenden Dateien einschließlich Produktionsdateien blieben hashgleich.

Getrennt davon: `git diff --check` ohne Pfadbegrenzung meldet **Exit 2** und umfangreiche bereits vorhandene Whitespace-/CRLF-Befunde. Tatsächliche Auszüge: `.agent/skills/impeccable/scripts/impeccable:1: trailing whitespace.` und `test/widget_test.dart:2197: trailing whitespace.` Die Gesamtausgabe wurde vom Tool gekürzt. Keine pauschale Bereinigung, keine Änderung dieser Dateien; ihre Hashes stimmen mit der Ausgangsaufnahme überein. Frühere dokumentierte Altbefunde werden ebenfalls nicht bereinigt.

Die damalige Batch-1-Redaktionsaufgabe ist inzwischen mit allen vier Batches abgeschlossen. Nächster Inhaltsschritt laut Roadmap: Alltagssprache & Redewendungen (ca. 450 nach Dublettenprüfung), anschließend Verbalphrasen und Business & E-Mail. Hierfür wurde in diesem Abschlussauftrag nichts ausgewählt oder reserviert.

Historischer geprüfter Batch-1-ZIP-Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/irregular_verbs_authoring_batch_1.zip`.

## Gesamtabschluss aller vier Batches

| Batch | Formziele | Neue Satzpaare | Unveränderte Wiederverwendungen |
|---|---:|---:|---:|
| 1 | 99 | 83 | 16 |
| 2 | 105 | 83 | 22 |
| 3 | 99 | 84 | 15 |
| 4 | 99 | 81 | 18 |
| Gesamt | 402 | 331 | 71 |

Alle ursprünglichen Auswahlreferenzen und Metadatendeltas sind exakt im fertigen Pack enthalten. Pro belegter Verbidentität drei unabhängige Formübungen, je ein vertraglicher fester Satz und eine gültige Funktion. Kein offenes Ziel; keine neue Auswahl/Registry zur künstlichen Darstellung eines Batch 5. Die komplette Kartenzahl beträgt 2567; alle acht normalen Ansichten behalten ihre bisherigen Lernziele. 406 Karten-Lexikalzuordnungen decken auch zusätzliche alte Gruppen-/Sense-Mitglieder ab; die 100 Zuordnungen des letzten Batches bleiben vollständig erhalten.

Der tatsächliche vollständige 22-Tabellen-Abgleich, App-Lesetest und die gemeinsame Projektion bestätigen 2453 Übungen / 2182 Wörter. Die ehemalige Wortprognose 2121 − 6 + 67 = 2182 ist damit im vollständigen Pack bestätigt; die Übungszahl wurde tatsächlich gelesen und berücksichtigt die zusätzlich zugängliche alte had-Partizipkarte. IDs, feste Sätze, Tokens, Besitzer und Lernstände wurden nicht verschmolzen. Geerbte Glossenbefunde bleiben separat offen: 20 frühere Befunde plus Vergleichslisten mit 12 und 14 Einträgen, ohne pauschales Fehlerurteil.

Export und internes Asset: `pipeline/out/irregular_verbs_batch_4_v1/`, Schema 4. 96 Pipeline-Tests, 27 Formtests, Elf-Stapel-Lesetest und `flutter analyze` bestanden. [Vollständiger Batch-4-Abschlussbericht](irregular-verbs-batch-4-import.md) enthält die tatsächlichen Befehle, Outputs, Exitcodes, Hashes, Sicherung und eine iPhone-Aktualisierungsanleitung ohne Deinstallation. Kein Geräteversuch oder unabhängige menschliche Sprachfreigabe behauptet.
