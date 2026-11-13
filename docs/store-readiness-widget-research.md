# Linglossa: Widget-Recherche und Entwürfe vor der Umsetzung

Stand: 13. November 2026. Diese Datei ist ein Recherche- und Entwurfsbericht; sie belegt noch keine implementierten Widgets. Das Repository wurde durch diesen Teilauftrag nur gelesen.

## Umfang und Nachweis

13 echte Widget-Screens über Refero MCP geladen, visuell angesehen und mit ihren vollständigen Metadaten abgeglichen. Die ersten sechs Bilder wurden direkt aus den Refero-Tools angezeigt, die weiteren sieben als MCP-Bilder mit `view_image` betrachtet. Die verlinkten Refero-IDs dokumentieren die Quellen; fremde Screenshots sind nicht Teil der ausgelieferten App.

Die Refero-MCP-Konfiguration funktioniert. Im Subagent-Kontext stehen inzwischen die nativen Refero-Tools bereit. Es wurden ausschließlich generische Suchbegriffe und Refero-IDs übermittelt, keine Projektinhalte, Zugangsdaten oder Nutzerdaten.

Recherche: „language learning bold typography duolingo“, „editorial reading publishing strong serif typography“, „home screen widget streak habit“, „reading progress widget“, „Duolingo Babbel widget“. Die letzte Suche lieferte überwiegend Übungsscreens und wurde deshalb nicht als Widget-Beleg gezählt. Drei vollständige Stilreferenzen wurden ergänzend ausgewertet: Duolingo, Brilliant und The New Yorker. Mobbin wurde nicht zusätzlich benötigt.

## Gesehene Widget-Referenzen

„Hell/dunkel“ beschreibt die Oberfläche des Widgets. Einige helle Widgets stehen im Refero-Screenshot auf einem dunklen Home-Screen.

| Nr. | App / Refero-Link mit ID | Sichtbarer Aufbau | Übernahme / Entscheidung |
| --- | --- | --- | --- |
| 1 | [Clearful, hell — 24bd0c22-311a-43a6-a71d-3d22ab4cd321](https://refero.design/screens/24bd0c22-311a-43a6-a71d-3d22ab4cd321) | Weiße mittlere Karte; zwei Streak-Zahlen, sieben Datums-Kreise, heutiger Kreis blau. | Die gleichmäßig verteilte Woche und den kräftigen heutigen Tag übernehmen; zwei konkurrierende Streak-Zahlen weglassen. |
| 2 | [Clearful, dunkel — fb27ca19-75d1-4f9e-9649-615e70a06c7c](https://refero.design/screens/fb27ca19-75d1-4f9e-9649-615e70a06c7c) | Identisches Raster auf Schwarz, weiße Zahlen; blauer heutiger Tag. | Gleiches Layout in beiden Erscheinungsbildern. Die sehr dunklen historischen Kreise nicht übernehmen; offene Tage brauchen erkennbare Konturen. |
| 3 | [Imprint, mittel — 8ddf290f-1214-45a9-b558-764446731d48](https://refero.design/screens/8ddf290f-1214-45a9-b558-764446731d48) | Grüne Fläche, sieben Wochentage, Flammen an aktiven Tagen, heutiger Tag als hohe Kontur-Kapsel. | Stärkste Referenz für das Wochen-Widget: heutiger Tag ist auch ohne Farbe erkennbar. Bei Linglossa Mo–So und Häkchen statt sieben bunter Flammen. |
| 4 | [Imprint, klein — 41a87b4c-ed4a-461e-b841-9f55014bbdde](https://refero.design/screens/41a87b4c-ed4a-461e-b841-9f55014bbdde) | Drei Tage passen in die kleine Karte, der aktuelle Tag steht in der Mitte; große Markeninitiale. | Zeigt die sinnvolle Reduktion für klein. Bei Linglossa die ganze Woche auf mittel/groß beschränken; der kleine Platz gehört Streak und Tagesziel. |
| 5 | [Train Fitness — 4578d3ed-a12b-4e1d-8f7e-7f69f923e786](https://refero.design/screens/4578d3ed-a12b-4e1d-8f7e-7f69f923e786) | Kleine helle Karte; kräftiger Titel, leichtere Zielzeile, darunter Punktkalender. | Die klare Gewichtshierarchie übernehmen. Der mehrwöchige Punktkalender ist für das tägliche Sprachlernziel unnötig dicht. |
| 6 | [Gentler Streak, dunkel — 30ab95f2-2a4c-4301-b7ff-120f257b435a](https://refero.design/screens/30ab95f2-2a4c-4301-b7ff-120f257b435a) | Große grüne Bogenanzeige mit orangefarbenem Symbol, kurze zentrierte Aufforderung. | Ein einfaches, großes Fortschrittssignal funktioniert ohne Maskottchen. Kein zweiter großer Ring neben der Streak-Zahl; Linglossa nutzt unten eine ruhige Zielspur. |
| 7 | [Apple Books, klein / Ziel erreicht — 6a831f9a-cff2-4722-9157-df459602aa39](https://refero.design/screens/6a831f9a-cff2-4722-9157-df459602aa39) | Orange kleine Karte mit großem Cover und einer einzigen bestätigenden Zeile mit Häkchen. | Starker Beleg für knappe Erfolgszustände und reale Inhaltsbilder. Textkontrast für Linglossa verbessern: dunkle Schrift auf Orange. |
| 8 | [Apple Books, groß / Ziel offen — cabaaee5-a0a0-465b-95f0-c877073a5a76](https://refero.design/screens/cabaaee5-a0a0-465b-95f0-c877073a5a76) | Oben mehrere Cover mit Fortschritt, unten Wochenreihe und verbleibendes Tagesziel. | Hauptreferenz für die große Karte: Lesefortsetzung und Lernfortschritt in zwei klaren Bereichen. Linglossa zeigt nur die zuletzt gelesene Story, damit Titel und weitere Aktion Platz haben. |
| 9 | [Apple Books, groß / Ziel erreicht — 2efea626-ff68-4fc7-ba97-29498a99d848](https://refero.design/screens/2efea626-ff68-4fc7-ba97-29498a99d848) | Gleiches Raster, Tageszielzeile wechselt zur Bestätigung; die Lesefortsetzung bleibt erreichbar. | Nach erreichtem Ziel das Weiterlesen anbieten und den Erfolg bestätigen; keine neue Pflicht oder künstliche Sperre erzeugen. |
| 10 | [PocketShelf, hell — a0145e5c-5eff-4d98-ac77-037db6273f29](https://refero.design/screens/a0145e5c-5eff-4d98-ac77-037db6273f29) | Echtes Cover links, konkrete Leseposition rechts, unten Titel und Aktion. | Cover plus Fortschritt eindeutig koppeln. Bei Linglossa Titel zwei Zeilen und prozentualer Fortschritt statt Seitenzahl, weil die Stories keine festen Seiten haben. |
| 11 | [PocketShelf, dunkel — 9096852c-8ec9-4b66-93bd-83f09c68763a](https://refero.design/screens/9096852c-8ec9-4b66-93bd-83f09c68763a) | Gleicher Aufbau; das Cover bleibt farbig, Text und Aktion wechseln zum dunklen Modus. | Cover als Inhalt erhalten, Hintergrund und Typografie semantisch anpassen. Die knappe abgeschnittene Titelzeile ist eine Warnung, ausreichend Textraum vorzusehen. |
| 12 | [LookUp, dunkel — 570e93e6-f3bd-427f-a608-8f9fbdbee5b5](https://refero.design/screens/570e93e6-f3bd-427f-a608-8f9fbdbee5b5) | Lernsammlung, Wortzahl und Fortschrittsbalken; darunter ein klar abgesetzter „Learn“-Bereich. | Die eindeutige Lernaktion übernehmen. Die zusätzliche verschachtelte Karte im kleinen Widget vermeiden. |
| 13 | [LookUp, hell — d4ccd087-f6e8-4a88-bea4-565d6d764c01](https://refero.design/screens/d4ccd087-f6e8-4a88-bea4-565d6d764c01) | Derselbe Lernaufbau mit weißem Rahmen und heller Aktionsfläche. | Zeigt, dass Aktionen ohne neue Informationsdichte sichtbar bleiben können. Bei Linglossa auf mittel/groß je ein klarer Zielbereich statt vieler kleiner Schaltflächen. |

Die Refero-Metadaten benennen manche Größen ungenau. Die Größenangaben dieser Tabelle folgen den tatsächlich betrachteten Screenshots: Apple Books Nr. 7 ist klein; Nr. 8 und 9 sind groß.

## Stilrichtung und Quellenbindung

Die bestehende Linglossa-Typografie und Palette bleiben die Grundlage: Figtree für Zahlen und Interface, Source Serif 4 für den Storytitel; aktive Lernfarbe Orange. Die Quellen liefern die Aufteilung, Informationshierarchie und Zustandsdarstellung.

| Stilreferenz | ID | Begrenzter Beitrag |
| --- | --- | --- |
| Duolingo — buoyant bite-sized delight | `bd4b3de7-fd30-4620-a8ca-e850b0f2817b` | Ein klarer großer Blickfang und optimistische, knappe Sprache. Figuren, Duolingo-Grün, Spielzeugknöpfe und dessen Schrift werden nicht übernommen. |
| Brilliant — hands-on optimism | `b36dc35b-59df-4a85-8927-9a46308575e0` | Klare Trennung von inhaltlicher Serifenschrift und praktischer Sans-Schrift. Farben behalten ihre Rollen; keine Übernahme von Marketingflächen oder Demonstrationsgrafiken. |
| The New Yorker — wit in print | `5349ab39-7e39-4f7f-b6d1-79967ec8e672` | Echtes Cover und lesbarer Storytitel als Inhalt; daneben ruhige Interface-Metadaten. Keine dekorativen Schriftwechsel innerhalb eines Satzes. |

**Festgelegte Richtung:** Große Zahl und kleine Flamme geben dem Streak eine eigene Silhouette. Eine schlanke horizontale Zielspur und eine Woche mit eindeutigen Häkchen machen Fortschritt sichtbar. Die große Karte ergänzt eine echte Cover-Kachel als einzigen bildhaften Bereich. Es braucht dafür kein generiertes Bild und kein Maskottchen.

Bewahren: eine dominante Zahl; kurze leichtere Folgezeile; klare heutige Kontur in der Woche; echte Story-Cover; deutlicher Wechsel zwischen offen und geschafft. Verwerfen: dekorative Kartenverschachtelung, graue Zahlenwände, mehrere große konkurrierende Ringe, erfundene Illustrationen und Textabsätze.

## Drei konkrete Entwürfe

Die unten genannten Schriftgrößen sind Startwerte in Punkten für normale Dynamic Type. Sie sind mit relativen Schriftmetriken und adaptivem Layout umzusetzen, keine festen Höhen für Textcontainer.

### Klein: „Streak“ — systemSmall

Eine große Figtree-Zahl links, z. B. **14**, und eine einfache Flamme rechts oben. Darunter „Tage in Folge“ in Medium. Die untere Zeile zeigt „Noch 4 Wörter“, darunter eine schlanke Zielspur. Der gesamte Inhalt ist ein großes Tippziel für die gemischte Übung.

- Zahl etwa 54–60 pt, kräftig und tabellarisch; bei langen Werten kleinere Stufe wählen, bevor sie abgeschnitten werden. „1 Tag in Folge“ korrekt im Singular.
- Normalfall: kräftige orange Fläche und dunkle Schrift. Geschafft: grüne Fläche, dunkle Schrift, Häkchen plus „Geschafft“; die Zahl bleibt der Blickfang.
- Bei Streak 0: große `0`, „Heute starten“ und der echte Tagesstand. Kein trauriges Symbol und kein Verlusttext.
- Keine Wochentage auf klein: Der reduzierte Aufbau folgt dem Größenvergleich bei Imprint und schützt die Lesbarkeit.
- Galerie-Beschreibung: „Dein Streak und Tagesziel.“

### Mittel: „Diese Woche“ — systemMedium

Oben links Zahl plus „Tage“, darunter „Heute dranbleiben“ in Medium. Oben rechts Tagesziel als `6/10` mit der leichteren Zeile „Wörter“. Darunter eine durchgehende Mo–So-Reihe: erledigte Tage mit Häkchen, offene mit Kontur, heute zusätzlich mit einer länglichen Umrandung wie bei Imprint. Der ganze Bereich führt zur gemischten Übung.

- Obere Informationszeile ungefähr 36 pt für die Streak-Zahl und 20–24 pt für den Tagesstand; normale Folgezeilen 13–15 pt.
- Weiße bzw. dunkelblaue Grundfläche, orange große Zahl/Zielspur; erreichtes Tagesziel wird zusätzlich mit Häkchen und „Geschafft“ markiert. So bleiben Kalender und Zahlen auch in Dark Mode ruhig.
- Wochentage werden kalendarisch aus echten aktiven Tagen abgeleitet. Ein Häkchen bedeutet „geübt“ und darf nicht fälschlich „Tagesziel erreicht“ suggerieren. Die Fortschrittszahl daneben ist das Tagesziel.
- Keine einzelnen Mini-Tippziele für die sieben Tage; sie sind Information.
- Galerie-Beschreibung: „Deine Woche auf einen Blick.“

### Groß: „Weiterlernen“ — systemLarge

Oben eine kompakte Streak-Zeile mit Tagesstand, darunter dieselbe Wochenreihe. In der Mitte eine große Lesefortsetzung: links das echte Story-Cover, rechts der Storytitel in Source Serif 4 über maximal zwei Zeilen, anschließend `37 % gelesen` und eine schlanke Fortschrittslinie. Unten ein klarer Übungsbereich mit `12 fällig` und „Üben“. Der Lesebereich und der Übungsbereich erhalten getrennte Links.

- Cover ungefähr 64–80 pt breit, mit dem vorhandenen Bildausschnitt statt künstlichem 3D-Buch oder Schlagschatten. Titel etwa 20–24 pt; Fortschritt 13–15 pt Medium.
- Kicker „Weiterlesen“ nur einmal, dann der echte Storytitel. Keine Titelzeile plus selbsterklärender zweiter Satz.
- Eigene importierte Texte und deren Titel werden nie im Widget gezeigt. Nur eine erlaubte Story aus dem Inhaltskatalog darf die Fortsetzung liefern.
- Wenn keine begonnene erlaubte Story vorliegt: den Lesebereich durch „Geschichte entdecken“ mit Buchsymbol ersetzen; Tippen führt zu Home, ohne erfundene Auswahl oder Fortschritt.
- `0 fällig`: „Für heute geschafft“ nur falls das Tagesziel tatsächlich erreicht ist, sonst „Üben“ mit dem echten verbleibenden Tagesziel. Keine falsche Gleichsetzung von „keine Wiederholungen“ und „kein Lernbedarf“.
- Galerie-Beschreibung: „Üben und weiterlesen.“

## Zustände und Darstellung

| Zustand | Zahl / Ziel | Woche | Aktion |
| --- | --- | --- | --- |
| Heute offen | Echte Streak-Zahl, `Noch N Wörter` bzw. `x/y` | Heute umrissen; nur tatsächlich aktive Tage gehakt | Gemischte Übung |
| Heute geschafft | Echte Zahl, Häkchen plus „Geschafft“ | Heute gehakt und weiterhin umrissen | Übung bleibt erreichbar; großes Widget bietet Weiterlesen |
| Streak 0 | `0`, „Heute starten“ | Echte historische Woche; keine erfundene Serie | Gemischte Übung |
| Keine Daten / abgemeldet | „Linglossa“, „App öffnen“; keine alten Zahlen und kein altes Cover | Weglassen | Home |

Bei einem Kontowechsel muss der leere Zustand sofort sichtbar werden, bis ein Snapshot des neuen Kontos vorliegt. Keines der Layouts braucht E-Mail, Kontonamen, eigene Importtexte oder Kontokennungen in der Anzeige.

## Farben und Kontrast

Werte aus `lib/theme/app_theme.dart`, nach ihren bestehenden Rollen:

| Rolle | Hell | Dunkel |
| --- | --- | --- |
| Neutrale Widget-Fläche | `#FFFFFF` | `#1A1D26` |
| Primärer Text auf neutraler Fläche | `#202632` | `#F0F2F5` |
| Sekundärer Text auf neutraler Fläche | `#596477` | `#8E95A5` |
| Offen / aktiv | `#F77F00` | `#F77F00` |
| Tagesziel erreicht | `#1FA463` | `#34C77B` |
| Text auf gefüllter Orange-/Grünfläche | `#202632` | `#0D0F14` |

Rechnerische WCAG-Kontraste, ohne Transparenz: `#202632` auf `#F77F00` **5,77:1**; auf `#1FA463` **4,73:1**. `#0D0F14` auf `#34C77B` **8,76:1**. Die sekundären Textfarben auf neutraler Fläche erreichen **5,98:1** (hell) und **5,60:1** (dunkel). Weiß auf Orange erreicht nur **2,63:1** und wird für kleine Widget-Texte deshalb ausgeschlossen. Diese Berechnung ersetzt noch keine Prüfung der finalen gerenderten Widgets.

Für getönt und klar liest die Implementierung `widgetRenderingMode`. Die eigenständige Hintergrundfarbe gehört in den Widget-Containerhintergrund; bei `accented` bleibt die vom System erzeugte Fläche sichtbar. Zahl, Zielspur und Häkchen werden als Akzentgruppe markiert, unterstützender Text bleibt in der primären Gruppe. Keine großflächige deckende innere Karte, die in diesem Modus als weißer Block erscheint. Das Story-Cover nutzt eine bewusste desaturierte Darstellung; ein Vollfarb-Cover ist als Medieninhalt möglich, muss aber separat visuell geprüft werden. Form, Häkchen und Kontur tragen die Zustandsinformation auch ohne Orange/Grün. [Apple: Accented Rendering und Liquid Glass](https://developer.apple.com/documentation/widgetkit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass).

## Barrierefreiheit und Abnahme für die Umsetzung

- Die Folgezeile steht immer in Medium; keine Kette gleich schwerer Titel.
- Zahl und zugehöriger Text werden zu einer sinnvollen VoiceOver-Gruppe zusammengefasst: „14 Tage Streak. Heute 6 von 10 Wörtern. Übung öffnen.“ Flamme und Fortschrittsdekoration erhalten keine doppelten Labels.
- Die Wochenzeile wird als eine sinnvolle Zusammenfassung vorgelesen oder mit ausgeschriebenen Tagen und Zuständen. „Heute“ darf nicht nur aus der Farbe hervorgehen.
- Das Cover ist dekorativ, wenn direkt daneben derselbe Storytitel als beschrifteter Link steht. Dieser Link nennt Titel und Fortschritt.
- Bei großen Textgrößen verschwindet zuerst sekundäre Dekoration, dann wechselt das Layout. Keine Skalierung des gesamten Widgets unter die gewählte Schriftgröße. Kernwerte und Handlungsziel behalten Vorrang; die volle Information bleibt in der VoiceOver-Beschriftung.
- Es gibt keine laufende Animation. Zustandswechsel brauchen weder Blinken noch Pulsen; reduzierte Bewegung ist damit von Anfang an berücksichtigt.
- Nach Implementierung mindestens alle drei Größen in hell und dunkel, jeweils offen, geschafft, Streak 0 und ohne Daten abbilden. Zusätzlich getönt und klar insbesondere mit Cover, Kalenderkonturen und Häkchen prüfen. Die Bilder in diesem Rechercheordner sind Referenzen, keine Screenshots der eigenen Implementierung.

Apple empfiehlt, Layout und Informationsmenge pro Widget-Größe anzupassen und die vom System gewählte Darstellung zu berücksichtigen. Das stützt die klare Aufteilung in Streak, Woche und Lesefortsetzung. [Apple: Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets).

## Entscheidungsprotokoll

| Entscheidung | Quelle | Rolle / Grund |
| --- | --- | --- |
| Große Streak-Zahl ohne Maskottchen | Nutzerauftrag + Duolingo-Stilprinzip | Ein sofort erkennbarer Blickfang, passend zu den vorhandenen Interface-Schriften |
| Heute als Kontur, aktive Tage als Häkchen | Imprint mittel + Clearful | Aktueller Tag und erledigte Tage auch ohne Farbe unterscheidbar |
| Keine ganze Woche auf klein | Imprint klein vs. mittel | Platz für lesbares Tagesziel und große Schrift |
| Ein Cover mit Fortschritt auf groß | Apple Books + PocketShelf | Konkrete Fortsetzung statt abstrakter Statistik |
| Serif nur für Storytitel | Bestehendes App-Theme + Brilliant + New Yorker | Inhalt und Bedienoberfläche bleiben unterscheidbar |
| Kurze Titel, leichtere zweite Zeile | Nutzerauftrag + Train Fitness | Gewichtshierarchie ist trotz geringer Fläche klar |
| Dunkle Schrift auf Orange | App-Palette + berechneter Kontrast | 5,77:1 statt 2,63:1 bei Weiß |
| Semantische Flächen im getönten/klaren Modus | Apple-WidgetKit-Dokumentation | Kein unlesbarer weißer Bild- oder Kartenblock |

## Prüfoutput dieses Rechercheauftrags

```text
13 MCP-Bilder gespeichert
13 vollständige Refero-Metadatensätze gespeichert
13 Bilder visuell geprüft
#202632 on #F77F00: 5.77:1
#202632 on #1FA463: 4.73:1
#0D0F14 on #34C77B: 8.76:1
#596477 on #FFFFFF: 5.98:1
#8E95A5 on #1A1D26: 5.60:1
```

Keine Flutter-Tests oder Builds ausgeführt, da dieser Teilauftrag ausschließlich Recherche und Entwurf war. Keine Behauptung über die Laufzeitfunktion oder die Darstellung der noch umzusetzenden Widgets auf einem echten Gerät.
