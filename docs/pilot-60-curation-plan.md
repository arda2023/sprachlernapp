# Kurationsplan Pilot 60 → kuratiertes Test-Pack (Stand 04.10.2026)

**Status: Abschnitte 2.1, 2.2, 3 und 5 offline als Kurationsliste umgesetzt (Abschnitt 8); Annotation, QA und Finalisierung ausstehend. Abschnitt 4 nicht umgesetzt. Nichts live geprüft.** Grundlage: `docs/pilot-60-editorial-review.md`, `pipeline/out/pilot_60_v1.json` (160 Karten, 480 Sätze), `pipeline/out/pos_check_v1.json` (10 Karten, 30 Sätze). Keine Datei unter `pipeline/out/` wurde verändert. Satzreferenzen gelten nur innerhalb ihrer Quelldatei (`pilot_60_v1/s126`, `pos_check_v1/s9`). Satz-IDs sind `ids.stable_id("sentences", lang="en", text=…)`, lokal berechnet.

## 1. Nachprüfung der neun Satzbefunde

Ergebnis: **7 bestätigt**, **2 zu Entscheidungen herabgestuft** (s26, s399-Übersetzung).

| Satz | Ergebnis | Begründung der Nachprüfung |
|---|---|---|
| s26 | herabgestuft | „Is this nice photograph of your family?“ ist grammatisch lesbar als „Zeigt dieses schöne Foto deine/Ihre Familie?“ („The photo is of my family“). Kein klarer Fehler; Problem ist die Kartenfrage your#ihr (Sie + Vorname „Rosa“). → Abschnitt 4, Gruppe „your“. |
| s30 | bestätigt | „all the more“ setzt einen Grund oder Vergleich voraus („umso mehr, weil …“). Der Satz ist eine isolierte Frage ohne diesen Bezug; nach Regel 5 der Satzerzeugung (ohne Kontext verständlich) ist „umso mehr“ unverständlich. Die Wendung selbst ist korrekt, der Satz nicht. |
| s99 | bestätigt (nur DE) | Englisch korrekt („has had … for hours“ = andauernder Besitz). Deutsch „hat … seit Stunden gehabt“ ist falsch: andauernde Zustände mit „seit“ stehen im Präsens. |
| s126 | bestätigt | „quiet library books“: Eigenschaft „ruhig“ unsinnig den Büchern zugeordnet; fester QA-Fall weiterhin falsch akzeptiert. |
| s153 | bestätigt | „Ali blew gently because he was about to blow out the candles.“ begründet das Pusten mit dem bevorstehenden Auspusten (zirkulär). Kartenbedeutung „im Begriff“ selbst ist korrekt verwendet; der Satzinhalt ist unlogisch. |
| s171 | bestätigt | „just big enough“ steht im Kontext einer Größenfrage für „gerade so / knapp groß genug“ (Bedeutung „barely“), nicht für die Kartenbedeutung „genau, exakt (Übereinstimmung)“. Die Übersetzung „genau groß genug“ ist kein idiomatisches Deutsch und belegt die Fehlzuordnung. |
| s331 | bestätigt (nur DE) | „sein Englisches Buch“: Adjektiv kleinzuschreiben. |
| s399 | Satz herabgestuft; Alternative bestätigt | „vor dem Schlafengehen“ ist im Deutschen eine gebräuchliche Wiedergabe von „at bedtime“ (z. B. Einnahmehinweise). Kein klarer Übersetzungsfehler; Präzisierung bleibt Empfehlung (Abschnitt 4). Die Alternative `before` ist davon unabhängig falsch (Abschnitt 3). |
| s413 | bestätigt | „all right“ ist ein lexikalisierter Ausdruck („in Ordnung“); „all“ verstärkt hier kein Adjektiv im Sinn von „ganz, völlig“. Die Übersetzung „ganz gut“ verschiebt die Aussage („einigermaßen gut“ statt „in Ordnung“). |

## 2. Bestätigte Satzkorrekturen

Für jede Ersetzung wurden lokal geprüft: Zielform genau einmal (ganzes Token), Lücke über `generate.gap_offsets`, `linter.lint_sentence` ohne Befund (max. 14 Wörter, 1 Nebensatz, Zipf-Warnung), kein anderer Satz derselben Karte mit gleichem ersten Wort, Text weder im Pack noch in `tests/fixtures/qa_language_cases.json`. **Nicht geprüft** (erfordert Vertex): Blindtest, Bedeutungs-/Sprach-/Übersetzungsprüfung, Alternativsuche, Annotation.

### 2.1 Englischer Text wird ersetzt (neue Satz-ID)

**pilot_60_v1/s30** · Karte `the|the/ADV|the#umso` · Position 3 · alte Satz-ID `02d203d8fc45b61eda7e716b723b8b3b`
- Bisher EN: Did Emma enjoy this stormy walk outside all the more?
- Bisher DE: Genoss Emma diesen stürmischen Spaziergang draußen umso mehr?
- Neu EN: Emma loves storms, so she enjoyed her windy walk all the more.
- Neu DE: Emma liebt Stürme, deshalb genoss sie ihren windigen Spaziergang umso mehr.
- Lücke: `Emma loves storms, so she enjoyed her windy walk all [the] more.` → Zeichen 53–56, Zielform `the`. Neue Satz-ID `1a06035523d22928d22d9759d52a8840`.
- Begründung: Der Grund („loves storms“) steht im Satz; „the“ ist Adverb vor Komparativ = „umso“.
- Alternativen: bisher keine; nach Blindtest neu ermitteln.

**pilot_60_v1/s126** · Karte `in|in/ADV|in#herein_drinnen` · Position 3 · alte Satz-ID `78aee2f111e4ed074667dff004de289c`
- Bisher EN: Ben stayed in all afternoon to read quiet library books.
- Bisher DE: Ben blieb den ganzen Nachmittag drinnen, um ruhige Bibliotheksbücher zu lesen.
- Neu EN: Ben stayed in all afternoon to read his library books.
- Neu DE: Ben blieb den ganzen Nachmittag drinnen, um seine Bibliotheksbücher zu lesen.
- Lücke: `Ben stayed [in] all afternoon to read his library books.` → 11–13, Zielform `in`. Neue Satz-ID `ae3e5830b7abe898f45b5e1a94487939`.
- Begründung: kleinste Änderung (falsche Eigenschaft entfernt); „stay in“ = drinnen bleiben bleibt unverändert. Bewusst nicht der Text des QA-Gegenfalls `library_books_quietly`, da Prüffälle nie in Packs stehen.
- Alternativen: bisher `inside`, `indoors` (für den alten Satz bestätigt) → **im neuen Satz erneut prüfen**, nicht übernehmen.

**pilot_60_v1/s153** · Karte `about|about/ADJ|about#im_begriff` · Position 3 · alte Satz-ID `8d70b1e4b16c1309002cec733d3a5b03`
- Bisher EN: Ali blew gently because he was about to blow out the candles.
- Bisher DE: Ali pustete sanft, weil er im Begriff war, die Kerzen auszublasen.
- Neu EN: Ali took a deep breath because he was about to blow out the candles.
- Neu DE: Ali holte tief Luft, weil er im Begriff war, die Kerzen auszublasen.
- Lücke: `Ali took a deep breath because he was [about] to blow out the candles.` → 38–43, Zielform `about`. Neue Satz-ID `8511d972677d42c22e4ea504c3bd8a35`.
- Begründung: Vorbereitung (Luft holen) vor der unmittelbar bevorstehenden Handlung; „about to“ = im Begriff.
- Alternativen: bisher keine; neu ermitteln.

**pilot_60_v1/s171** · Karte `just|just/ADV|just#genau` · Position 3 · alte Satz-ID `9a8f622e320e57b8523f79632198fbb0`
- Bisher EN: Is that seat next to Omar just big enough?
- Bisher DE: Ist dieser Platz neben Omar genau groß genug?
- Neu EN: Is that seat next to Omar just what you wanted?
- Neu DE: Ist dieser Platz neben Omar genau das, was du wolltest?
- Lücke: `Is that seat next to Omar [just] what you wanted?` → 26–30, Zielform `just`. Neue Satz-ID `9f7eb79c95c6e07ed552af3cd273ec6b`.
- Begründung: „just what“ = „genau das“ (Übereinstimmung); keine „gerade so“-Lesart. Unterscheidet sich vom Kartensatz s170 („just right“).
- Alternativen: bisher keine; `exactly` wäre zu prüfen, nicht vorab übernehmen.

**pilot_60_v1/s413** · Karte `all|all/ADV|all#vollstaendig_adv` · Position 2 · alte Satz-ID `d42941588da63661aeb290a39c87b876`
- Bisher EN: Is Ben all right after the hard week with his family?
- Bisher DE: Geht es Ben nach der anstrengenden Woche mit seiner Familie ganz gut?
- Neu EN: Is Ben all wet after the long walk in the rain?
- Neu DE: Ist Ben nach dem langen Spaziergang im Regen ganz nass?
- Lücke: `Is Ben [all] wet after the long walk in the rain?` → 7–10, Zielform `all`. Neue Satz-ID `0adf27a67b027d50f4c27b52e5d7ded0`.
- Begründung: „all“ verstärkt ein Adjektiv („völlig nass“); keine feste Wendung. Unterscheidet sich von s412 („all alone“) und s414 („all by himself“).
- Alternativen: bisher keine; `completely` wäre zu prüfen, nicht vorab übernehmen.

### 2.2 Nur deutsche Übersetzung wird korrigiert (Satz-ID bleibt)

**pilot_60_v1/s99** · Karte `had|have/VERB|have#besitzen_partizip` · Position 3 · Satz-ID `0935eeb201be3974e20e21adf8a2ac63` (unverändert)
- EN unverändert: Maya has [had] that seat near the driver for hours. (Lücke 9–12, Zielform `had`)
- Bisher DE: Maya hat jenen Platz nahe beim Fahrer seit Stunden gehabt.
- Neu DE: Maya hat diesen Platz nahe beim Fahrer schon seit Stunden.
- Begründung: Deutsches Präsens für andauernden Zustand mit „seit“; „haben“ = innehaben bleibt erhalten. Alternativen: keine.

**pilot_60_v1/s331** · Karte `is|be/AUX|be#hilfsverb` · Position 1 · Satz-ID `38174450a03f9b931e02e3478c54a3a0` (unverändert)
- EN unverändert: Leo [is] reading his English book in the classroom right now. (Lücke 4–6, Zielform `is`)
- Bisher DE: Leo liest gerade sein Englisches Buch im Klassenzimmer.
- Neu DE: Leo liest gerade sein englisches Buch im Klassenzimmer.
- Begründung: Rechtschreibung. Alternativen: keine.

## 3. Alternativen entfernen (unabhängig von Satzänderungen)

**pilot_60_v1/s399** · Karte `at|at/ADP|at#zeit` · `valid_alternatives: ["before"]` → `[]`
- Original: Mia takes her medicine [at] bedtime. — eingesetzt: Mia takes her medicine **before** bedtime.
- Begründung: Direkter englischer Vergleich: „at bedtime“ = zum Zeitpunkt des Schlafengehens; „before bedtime“ = zu einem früheren, unbestimmten Zeitpunkt. Die Zeitangabe verschiebt sich. Die deutsche Übersetzung passt zu beiden und kann die Verschiebung nicht rechtfertigen (Regel `alternative-check-v3`). Gilt unabhängig davon, ob die Übersetzung geändert wird.

**pilot_60_v1/s140** · Karte `they|they/PRON|they#man_leute` · `valid_alternatives: ["you"]` → `[]`
- Original: Do [they] make reliable laptops in that factory, Luis? — eingesetzt: Do **you** make reliable laptops in that factory, Luis?
- Begründung: Durch die Anrede „Luis“ bezeichnet „you“ den Angesprochenen (bzw. seine Firma): Frage, ob Luis Laptops herstellt. „they“ = unbestimmte andere Leute. Die beteiligten Personen ändern sich. Die übrigen Kandidaten (`people`, `we`) wurden bereits abgelehnt. Der Satz selbst bleibt korrekt.

## 4. Offene Reviewfälle (35) und zwei herabgestufte Befunde

### 4.1 Entscheidung vor Aufnahme erforderlich

**Kartengruppen**

| Gruppe | Karten (pilot_60_v1) | Empfehlung | Begründung |
|---|---|---|---|
| your | `your#ihr` (s25–s27, inkl. herabgestuftes s26), `your#dein` (s145–s147), `your#euer` (s244–s246) | `your#dein` aufnehmen; `your#ihr` und `your#euer` bis zur Produktentscheidung nicht in das Test-Pack. | Englisch unterscheidet Höflichkeit und Zahl nicht; im Lückensatz ist die Kartenbedeutung nicht erkennbar. Die ihr-Sätze erzwingen „Sie“ mit Vornamen; s245 spricht nur „Nina“ an und begründet „euer“ nicht. dein-Sätze sind konsistent (Vorname, informell). |
| singular they | `they#singular_they` (s229–s231) | nicht aufnehmen bis Übersetzungskonvention entschieden. | Übersetzungen „sie/er“ mit Schrägstrich sind als Lerntext ungeeignet. |
| like Füllwort | `like#fuellwort` (s220–s222; Alternativen s220, s221) | nicht aufnehmen (bereits offener Punkt). | Umgangssprachlich; s220 wird als „ungefähr“ verstanden (bestätigte Alternativen about/around), Übersetzung „quasi“ trifft das nicht; `so to speak` (s221) verschiebt Bedeutung. |
| will Testament | `will#testament` (s109–s111) | nicht in den Anfänger-Teststapel; Produktentscheidung offen. | Bereits offener Punkt; Sätze selbst korrekt. |

**Einzelsätze**

| Satz | Text | Empfehlung | Begründung |
|---|---|---|---|
| pilot_60_v1/s64 | Luca holds the guitar so and strikes the strings. | ersetzen (Kurationsrunde) | „so“ = „auf diese Weise“ mitten im Satz unnatürlich; ohne Vorführung unverständlich. |
| pilot_60_v1/s292 | Mia has been tired after tennis training. | ersetzen | Present Perfect ohne passenden Zeitrahmen unnatürlich. |
| pilot_60_v1/s294 | Omar has already been busy with the laundry. | ersetzen | wie s292. |
| pilot_60_v1/s390 | Why does David talk on about his old car? | ersetzen | idiomatisch „go on about“; „talk on about“ selten. |
| pilot_60_v1/s398 | Can you meet Noah at noon? / … um die Mittagszeit … | DE korrigieren: „Kannst du Noah um zwölf Uhr mittags treffen?“ (Satz-ID bleibt) | „at noon“ ist ein Zeitpunkt, „um die Mittagszeit“ ein Zeitraum. |
| pilot_60_v1/s399 (DE) | Mia nimmt ihre Medizin vor dem Schlafengehen. | DE präzisieren: „Mia nimmt ihre Medizin zur Schlafenszeit.“ (Satz-ID bleibt) | Für Lernende soll die Übersetzung den Zeitpunkt „at“ abbilden; bisherige Fassung idiomatisch, aber mehrdeutig. |
| pilot_60_v1/s466 | Can you take the bus across this big city, Amir? | ersetzen | Mit Anrede ist „you“ = Amir naheliegend; Karte verlangt „man“. |
| pos_check_v1/s9 | Here are two birthday cakes, and Zoe chooses which tastes best. | ersetzen | „wählen, welcher am besten schmeckt“ semantisch schief. Karte `which#fragepronomen` erst mit drei tragfähigen Sätzen aufnehmen. |

**Alternativen** (Empfehlung jeweils: entfernen; eine nicht gelistete Antwort gilt in der App als Fehler, daher konservativ nur eindeutige Bedeutungsgleichheit behalten)

| Satz | eingesetzt | Begründung |
|---|---|---|
| pilot_60_v1/s18 | … the pain was not **too** bad. | „not that bad“ (weniger schlimm als erwartet) ≠ „not too bad“ (ganz in Ordnung). |
| pilot_60_v1/s105 | Can Noah **go** to the doctor without a car? | „get to“ = hingelangen (Erreichbarkeit); „go“ allgemeiner. |
| pilot_60_v1/s141 | Mia knows that **you** keep old books on the top floor. | „you“ als Anrede lesbar; gleiche Personenverschiebung wie s140. |
| pilot_60_v1/s180 | Can Sara **plan** our break before the rain starts? | verliert die zeitliche Abstimmung; Lesart „vor dem Regen planen“. |
| pilot_60_v1/s180 | Can Sara **arrange** our break before the rain starts? | wie `plan`. |
| pilot_60_v1/s221 | … Ali was **so to speak** totally surprised … | Teil der like-Gruppe; Bedeutung verschoben. |

### 4.2 Reine Stilfrage, verhindert Aufnahme nicht

Sätze (pilot_60_v1): s28 („all the quicker“ mit schwacher Begründung), s118 und s120 („his“ ohne Bezugsperson, im Einzelsatz verständlich), s168 (Begründung schwach), s194 („felt at fault“ belegt, selten), s268 und s270 (elliptischer Vergleich, idiomatisch), s271 („out on holiday“), s273, s368, s409 („just solution“), s442 und s444 (Kontext gezwungen), s474 („wears no warm coat“).
Karten (Glossen; Inventar in eigenem Inkrement): `that#das` (Glosse vermischt Demonstrativ und Relativ, Sätze s58–s60 korrekt), `have#besitzen` (Glosse nennt „3. Person Singular“ an der Grundform; Sätze s184–s186 korrekt).
Zusätzlich die 24 Stilhinweise aus dem Review.

Kontrollsumme: 21 Satz-Prüffälle (7 entscheidungsbedürftig, 14 Stil) + 6 Alternativen (entscheidungsbedürftig) + 8 Karten (6 entscheidungsbedürftig in 4 Gruppen, 2 Stil) = 35.

## 5. Zusammenführung mit pos_check_v1

Aus den tatsächlichen Referenzen berechnet (lokal):

- Pilot: 160 Karten. POS-Lauf: 10 Karten, davon 5 nicht im Pilot, 5 mit identischer Referenz. Kein Satztext kommt in beiden Packs vor.
- **Ergänzen (4):** `are|be/AUX|be#sein_vollverb` (pos s1–s3), `was|be/AUX|be#sein_vollverb` (pos s10–s12), `be|be/AUX|be#sein_existieren` (pos s19–s21), `which|which/PRON|which#fragepronomen` (pos s7–s9; s9 siehe 4.1).
- **Ersetzen (1):** `be|be/VERB|be#befinden` (pilot s196–s198) → `be|be/AUX|be#befinden` (pos s28–s30, neue Karten-ID `d2ef9df94be5dd1c9ec9e98860c00764`).
- **Doppelt (5), gewählt wird jeweils der Pilot-Satzsatz:**

| Karte | Pilot | POS | Wahl und Begründung |
|---|---|---|---|
| `was\|be/AUX\|be#hilfsverb` | s49–s51 | s4–s6 | Pilot: ohne Befund, bestehende Satz-IDs bleiben; pos s5 ist fast identisch mit pilot s50 und darf nicht zusätzlich übernommen werden. |
| `are\|be/AUX\|be#sein_hilfsverb` | s163–s165 | s13–s15 | Pilot: ohne Befund; pos s13 ähnelt pilot s163. |
| `which\|which/DET\|which#determiner_auswahl` | s199–s201 | s16–s18 | Pilot: ohne Befund; pos s17 ähnelt pilot s200. |
| `which\|which/PRON\|which#relativpronomen` | s256–s258 | s22–s24 | Pilot: beide Sätze mit Stilhinweis („welche/welches“); Pilot vermeidet Änderungen. |
| `be\|be/AUX\|be#hilfsverb` | s328–s330 | s25–s27 | Pilot: ohne Befund; keine Qualitätsdifferenz, Stabilität der IDs. |

- **Erwartete Kartenanzahl:** 160 − 1 + 5 = **164** eindeutige Referenzen (lokal gezählt, keine Doppelten, alte VERB-Karte nicht enthalten). Werden die Empfehlungen aus 4.1 übernommen (`your#ihr`, `your#euer`, `they#singular_they`, `like#fuellwort`, `will#testament` nicht aufnehmen): **159**. `which#fragepronomen` erst nach Ersatz von pos s9.
- Veröffentlichungsstatus alter IDs (insbesondere `be|be/VERB|be#befinden`, `7194af61bee4d3bae01d152bb82975ae`) bleibt **ungeklärt**. Keine Lernstandsübertragung, keine Tombstones in diesem Schritt.

## 6. Technischer Umsetzungspfad (vorhandene Implementierung)

**Lokal berechenbar (ohne Vertex):**
- `pipeline/src/sprachpipe/ids.py`: `stable_id(table, **key_fields)`, `form_norm(form)`.
- `pipeline/src/sprachpipe/generate.py`: `gap_offsets(text, form)` (Lücke, ganzes Token, case-insensitiv).
- `pipeline/src/sprachpipe/linter.py`: `lint_sentence(...)` (spaCy + wordfreq lokal).
- `pipeline/src/sprachpipe/annotate.py`: `tokenize(text)` (spaCy-Tokens mit Offsets; **ohne** Lemma/Glosse).
- `pipeline/src/sprachpipe/pack.py`: `load_pack(path)`, `build_rows(pack)` (alle IDs aus Referenzen), `sentence_lint_items(pack)`.
- `pipeline/src/sprachpipe/export.py`: `export_sqlite(pack, path)`.

**Nur modellgestützt (Vertex, Budget):**
- `annotate.annotate_card(llm, cfg, card, finals)`: Lemma und Glosse je Wort-Token; verlangt **genau drei** Sätze einer Karte und annotiert sie gemeinsam. Eine Einzelsatz-Annotation existiert nicht; eine Neuannotation einer Karte kann Token-Bedeutungen der unveränderten Schwestersätze ändern.
- `blindtest.ask`, `meaning_check.check`, `alternative_check.check`: QA eines neuen oder geänderten Satzes und erneute Prüfung von Alternativen (z. B. s126 `inside`/`indoors`).

**Fehlende Bausteine:** `pack.assemble_pack` baut nur aus Generierungsdaten (Slots, Versuche), nicht aus einem bestehenden Pack. Für eine reproduzierbare Kuration fehlt eine Funktion, die eine versionierte Kurationsliste auf ein geladenes Pack anwendet (Text/Übersetzung ersetzen, Alternativen entfernen, Karten ergänzen/ersetzen, Referenzen beim Zusammenführen eindeutig neu vergeben) und danach `build_rows` nutzt. Ebenso fehlt eine Neuberechnung von `dictionary_forms` (Rang aus Tokenhäufigkeit) und `deck_cards.position` für ein bestehendes Pack; heute liegt beides nur in `assemble_pack`.

**Aktualisierungsbedarf je Änderungsart (aus dem Datenvertrag):**

| Änderung | Satz-ID | card_sentences-ID | Lücke | sentence_tokens | weitere Folgen |
|---|---|---|---|---|---|
| Nur `translation_de` (s99, s331; Empfehlung s398, s399) | bleibt (Schlüssel ist nur `lang`+`text`) | bleibt | bleibt | bleiben (Offsets und englische Tokens unverändert) | `qa_report.meaning_check_result` bezieht sich auf die alte Übersetzung → `translation_ok` neu prüfen (Vertex) oder als kuratiert kennzeichnen. |
| Englischer Text ersetzt (s30, s126, s153, s171, s413) | **neu** | **neu** (`card_id`+`sentence_id`) | neu über `gap_offsets` | **neu**: Offsets lokal (`tokenize`), Lemma/Glosse nur über `annotate_card` (Vertex) | volle QA (Linter lokal; Blindtest, Bedeutungs-/Sprachprüfung, Alternativen per Vertex); `valid_alternatives` leer bis geprüft; `dictionary_forms` und Token-Senses neu ableiten; alte Zeilen nach `content-schema.md` als Tombstone mit `replaced_by`, **falls** veröffentlicht (ungeklärt). |
| Alternative entfernt (s399, s140; Empfehlungen 4.1) | bleibt | bleibt | bleibt | bleiben | nur `card_sentences.valid_alternatives`; `qa_report.alternative_check` bleibt als historischer Befund. |
| Karte ergänzt (4 aus POS-Lauf) | aus Text (neu) | neu | aus POS-Pack | aus POS-Pack | Satzreferenzen beim Zusammenführen neu vergeben (`s1…` kollidieren); `deck_cards.position` neu berechnen. |
| Karte ersetzt (be#befinden VERB → AUX) | Sätze des POS-Packs | neu | aus POS-Pack | aus POS-Pack | alte Karten-, Sense- und Satzzeilen nur bei Veröffentlichung tombstonen (ungeklärt). |

## 7. Reihenfolge eines späteren Kurationsinkrements (Vorschlag)

1. Produktentscheidungen aus 4.1 treffen.
2. Kurationsliste versioniert anlegen (diese Ersatztexte, Alternativ-Entfernungen, Kartenauswahl).
3. Anwendungsfunktion implementieren und offline testen (IDs, Lücken, Referenzen, 164 bzw. 159 Karten, keine Doppelten).
4. Modellgestützt nur die geänderten Karten annotieren und prüfen (5 Karten mit englischem Textersatz plus Ersatzsätze aus 4.1; Budget gesondert festlegen).
5. Kuratiertes Test-Pack exportieren; erst danach Veröffentlichungsstatus alter IDs klären.

## 8. Umsetzung offline (04.10.2026)

- Kurationsliste `pipeline/data/curation/pilot_60_v1.json` (`pilot-60-curation-v1`): 5 × `replace_text` (s30, s126, s153, s171, s413), 2 × `replace_translation` (s99, s331), 2 × `remove_alternative` (s399 `before`, s140 `you`), 4 × `add_card`, 1 × `replace_card` (be#befinden VERB → AUX), 5 × `keep_base_card`. Jede Satzoperation nennt Quelle, Kartenreferenz, stabile Satz-ID, lesbares Label und erwarteten Text/Übersetzung. Keine Kartenausschlüsse aus Abschnitt 4.
- `pipeline/src/sprachpipe/curate.py`: `curate(packs, curation, card_meta)` → (Arbeitsstand, Änderungsnachweis), Eingaben unverändert; `finalize(work)`; `card_meta_from_inventory(packs, inventory)` liest `usage` und Bedeutungsreihenfolge (nur lesend) für die Stapelreihenfolge. Fehlende, mehrfache oder abweichende Treffer, nicht entschiedene Quellkarten und abweichende Endzahlen brechen mit `CurationError` ab.
- Satzreferenzen werden je Quelle präfixiert (`pilot_60_v1/s126`, `pos_check_v1/s1`); ersetzte Sätze erhalten `pilot-60-curation-v1/pilot_60_v1/<label>`. Satz-IDs bleiben aus `stable_id` abgeleitet.
- Englischer Textersatz: neue Satz-ID, Lücke über `gap_offsets`, keine Tokens, `valid_alternatives` leer, `qa_status = pending`, `qa_report` nur mit Herkunft (`replaces_sentence_id`). Entfallene Alternativen (s126 `inside`, `indoors`) stehen im Nachweis und in der ausstehenden QA zur erneuten Prüfung.
- Nur Übersetzung: Satz-ID, Tokens und historischer `qa_report` bleiben; neue Übersetzungsprüfung ausstehend.
- `pack.py`: Stapelreihenfolge als `deck_order_key` aus `assemble_pack` herausgelöst (Regel unverändert); `build_rows` (und damit SQLite-Export und DB-Upsert) verweigert einen Arbeitsstand mit ausstehenden Schritten.
- **Befund `dictionary_forms`:** Die Einträge tragen die formspezifische Token-Glosse (z. B. „biegt ab“), Pack-Tokenzeilen speichern nur den Sense. Eine Neuableitung aus Pack-Zeilen ergab in `pilot_60_v1` 9, in `pos_check_v1` 2 und in `smoke_pack_v8` 1 abweichende Glossen; sie ist daher nicht exakt möglich. Seit Abschnitt 9 werden die Quelleinträge mit Herkunft gesichert; `dictionary_forms` selbst bleibt bis zur Annotation leer.
- Lokaler Lauf im Speicher (keine Datei geschrieben): 164 eindeutige Karten, 492 Satzzuordnungen, je Karte genau drei; 492 Sätze, 5146 Tokens; 21 Senses und 8 Lemmata ohne Verweis entfernt; relative Stapelreihenfolge der Pilotkarten unverändert, Positionen 1–164. 10 Glossenkonflikte bei gemeinsamen Senses protokolliert (Pilotwert behalten). 13 ausstehende Schritte: 5 × `annotate_card`, 5 × `sentence_qa`, 2 × `translation_check`, 1 × `dictionary_forms`. `finalize` und `build_rows` verweigern den Stand.

**Verbleibende Schritte bis zum Test-Pack:**
1. `annotate.annotate_card` (Vertex) für `the#umso`, `in#herein_drinnen`, `about#im_begriff`, `just#genau`, `all#vollstaendig_adv`, jeweils alle drei Sätze; Herkunft neuer Tokens im Nachweis führen.
2. Satz-QA der fünf neuen Sätze: Linter (lokal), Blindtest, Bedeutungs-/Sprach-/Übersetzungsprüfung, Alternativprüfung; s126 `inside`/`indoors` nur nach Bestätigung übernehmen.
3. Übersetzungsprüfung für s99 und s331.
4. `dictionary_forms` nach der Annotation bestimmen (Abschnitt 9).
5. Offene Entscheidungen aus Abschnitt 4 (u. a. pos_check_v1/s9) bleiben offen.

## 9. Wörterbuch-Quelldaten und Glossenkonflikte (04.10.2026)

**Vertrag:** `dictionary_forms` hat den Schlüssel `lang` + `form_norm` + `sense_id` (`content-schema.md`); im Pack (`form`, `sense`-Referenz), die Referenz enthält Lemma, Wortart und `sense_key`. Zu unterscheiden:
- **Bedeutungsglosse** `senses.gloss_de`: eine je Sense.
- **Formübersetzung** `dictionary_forms.gloss_de`: Glosse der konkreten Wortform aus der Token-Annotation (bei Kartentokens die Kartenglosse der Form, z. B. `had` „Hilfsverb zur Bildung des Past Perfect“). Wird nie aus der Bedeutungsglosse abgeleitet.
- **Rang** `dictionary_forms.rank`: Reihenfolge der Senses einer Form nach Tokenhäufigkeit im Pack.

**Umsetzung (`curate.py`):** Alle Quelleinträge beider Packs werden je Schlüssel in `curation.dictionary_sources` gesichert: Werte mit Herkunft (Quelle, Karte, Quellrang); identische Werte zusammengeführt, verschiedene Werte nebeneinander und als Konflikt gelistet. Kein Wert wird nach Dateireihenfolge gewählt. Einträge entfernter oder geänderter Karten bleiben erhalten (z. B. Verweis auf `be|be/VERB|be#befinden`). `dictionary_forms` bleibt leer; der ausstehende Schritt nennt die Konfliktschlüssel.

**Lokaler Lauf (Speicher):** 1979 Quelleinträge (1785 + 194) → 1838 Schlüssel mit 1850 Werten, 12 Schlüssel mit abweichender Formübersetzung. Alle 1795 Token-Schlüssel des Arbeitsstands sind abgedeckt; 43 gesicherte Schlüssel werden von keinem aktuellen Token verwendet (ersetzte bzw. nicht übernommene Sätze). **Offen und noch nicht bestimmbar:** Schlüssel und Formübersetzungen der fünf neuen englischen Sätze (ohne Annotation), endgültige Eintragsmenge und Ränge.

**Konflikte.** Ergebnis: kein Bedeutungswiderspruch; alle Fälle sind Formulierungsvarianten. Bedeutungsglossen: Pilotfassung bleibt mit Herkunft (Änderungsnachweis). Formübersetzungen: beide Werte bleiben gesichert; Auswahl erst bei der Ableitung nach Annotation.

| Schlüssel | Glossentyp | pilot_60_v1 | pos_check_v1 | Einordnung | Empfehlung |
|---|---|---|---|---|---|
| `be/AUX\|be#sein_vollverb` | Bedeutung (Kartensense) | sein (als Vollverb oder Kopula zur Angabe von Zustand, Identität oder Eigenschaft) | sein (als Kopula zur Angabe von Zustand, Identität oder Eigenschaft) | Variante (beide kopular); im Log bisher doppelt gezählt (are, was) | Pilot vorerst; Inventarglosse von `is` später an „als Kopula“ angleichen (eigenes Inkrement). Formübersetzungen `is`/`are`/`was` haben verschiedene Schlüssel, kein Konflikt. |
| `time/NOUN\|time#zeit` | Bedeutung und Form | Zeit (fortlaufende Dauer, Zeitpunkt oder Uhrzeit) (Kartenglosse) | Zeit (Token-Glosse) | Variante (erklärend vs. knapp) | Für Kartentokens Kartenglosse; Form `time` → Pilotwert. |
| `not/PART\|not#nicht` | Bedeutung und Form | nicht (drückt Verneinung … aus) (Kartenglosse) | nicht (Token-Glosse) | Variante | wie `time`. |
| `city/NOUN\|city#stadt` | Bedeutung und Form | Stadt- | Stadt | Variante (attributive Verwendung „city shuttle“) | Form ohne Bindestrich („Stadt“). |
| `classroom/NOUN\|classroom#klassenzimmer` | Bedeutung und Form | Klassenzimmer- | Klassenzimmer | Variante (attributiv) | „Klassenzimmer“. |
| `phone/NOUN\|phone#telefon` | Bedeutung und Form | Telefon | Telefon- | Variante (attributiv „phone call“) | „Telefon“. |
| `shop/NOUN\|shop#laden` | Bedeutung und Form | Laden | Laden- | Variante (attributiv „shop assistant“) | „Laden“. |
| `please/INTJ\|please#bitte` | Bedeutung und Form | Bitte | bitte | Variante (Satzanfang) | „bitte“. |
| `here/ADV\|here#hier` | Bedeutung und Form | Hier | hier | Variante (Satzanfang) | „hier“. |
| `photo/NOUN\|photo#foto` | nur Form | Foto | Foto- | Variante (attributiv) | „Foto“. |
| `this/DET\|this#dieses` | nur Form | Dieses | dieses | Variante (Satzanfang) | „dieses“. |
| `can/AUX\|can#kann` | nur Form | kann | Kann | Variante (Satzanfang) | „kann“. |
| `why/SCONJ\|why#warum` | nur Form | warum | Warum | Variante (Satzanfang) | „warum“. |

Zählung: 9 Bedeutungsglossen-Konflikte (bisher als 10 gemeldet, `be#sein_vollverb` doppelt) und 12 Formübersetzungs-Konflikte; 8 Schlüssel betreffen beide Typen.

**Ausstehender `dictionary_forms`-Schritt:** Quelldaten sind gesichert. Nach Annotation der fünf geänderten Karten aus den resultierenden Tokens die Eintragsmenge (`form_norm` + Sense) und die Ränge bestimmen; Formübersetzungen aus den gesicherten Werten bzw. der neuen Annotation übernehmen; Schlüssel ohne Formübersetzung und Schlüssel mit mehreren Werten einzeln ausweisen und redaktionell entscheiden. Bis dahin verweigern `finalize` und `build_rows` den Stand.
