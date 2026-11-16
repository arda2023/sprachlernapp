# Linglossa: Umsetzung deiner Auswahl

Stand: 15.11.2026. Die Nummern beziehen sich auf den [gekürzten Bericht](paywall-retention-optimierungsbericht-2026-11-15.md).

## Eingebaut

- **1 – Gratisstory:** „Sprachenlernen“ mit vier Kurzgeschichten je Lernsprache. Die Linglossa-Story steht oben und bleibt kostenlos; drei weitere erklären Kontext, Abruf und verteiltes Üben. Offline-Worterklärungen und deutsche Satzübersetzungen für den kostenlosen Einstieg.
- **2 – Gratisgenerierung:** Einmal pro bestätigtem Konto bis zu 50 Wörter, gemeinsam über alle Sprachen. Serverseitig begrenzt. Unterbrochene Aufträge sind nach Neustart wieder abrufbar, ohne automatische neue Generierung. Ausgewählte Gratiswörter bleiben auf dem speichernden Gerät übbar.
- **3 – Nutzen vor Paywall:** Eine echte Ein-Wort-Übung speichert Lernfortschritt vor der ersten Paywall. Überspringen führt direkt in Free.
- **4 – Passender Anlass:** Eigene Ansprache für Stories, Themenwörter, Textimporte, Übungen und Übersetzungen.
- **7 – Neue erste Paywall:** Ohne Testabo oder animierte Hintergrundwörter. Scrollbarer Free/Premium-Vergleich mit Grenzen, anschließend drei Mitmach-Beispiele: Wörter aufdecken, selbst abrufen, Wiederholung mit Abstand. Quellen sind aufklappbar. Kurze Texte, Hell/Dunkel, große Schrift und reduzierte Bewegung.
- **8 – Zurückhaltender Hinweis:** Nach echtem Erfolg eine freiwillige Premium-Einladung. Derselbe Anlass höchstens einmal, sieben Tage Abstand; nach Ablehnung 30 Tage Ruhe. Lokal pro Konto gespeichert.
- **9 – Nach Kauf weiter:** Gewählte Story, Stapel, Übung, Import oder Übersetzung fortsetzen. Kaufabbruch und Kontextwechsel verwerfen die vorgemerkte Aktion. Vorbereitete Themen bleiben erhalten; Generierungen starten weiterhin ausdrücklich.
- **13 – Onboarding fortsetzen:** Optionale Themenwahl überspringbar; Zwischenstand inklusive Ziel und KI-Einstellung wird gespeichert.
- **15 – Individuelle Erinnerungen:** Regelbasierte wechselnde Texte. Fällige Wiederholungen haben Vorrang, der freiwillige Lernzweck beeinflusst selten einen Text. Keine KI-Auswertung persönlicher Nutzungsdaten und kein PostHog-System.
- **18 – Freiwillige Benachrichtigungen:** Einladung nach gespeichertem Lernerfolg. Erst „Erinnerungen aktivieren“ fragt die Systemberechtigung an.
- **19 – Weniger bei Inaktivität:** Höchstens drei Hinweise an Tag 0, 2 und 5, danach Pause. Neue gespeicherte Aktivität startet einen neuen Zyklus. Sichtbarer Lernstand-Sync aktualisiert die Planung; bei geschlossener App bleibt sie lokal.
- **23 – Echte Meilensteine:** Erste Story, erstes geübtes eigenes Themenwort und erstes gemeistertes Wort. Einmalige kleine Animation mit bestehendem Sound, Haptik und Rücksicht auf reduzierte Bewegung.
- **25 – Nächste Aufgabe:** Home priorisiert fällige Wörter, eine begonnene/kurze zugängliche Story und neue Wörter. Keine zusätzliche Interessenempfehlung.

Die abgelehnten Punkte bleiben außen vor; **6 (echte Nutzerstimmen)** bleibt für später. Die zusätzlichen Punkte 29–32 wurden nicht beauftragt. Für Animationen reichen Flutter und vorhandene Audio-Dateien; ein neuer Rive- oder Epidemic-Import war nicht nötig.

## Wissenschaft und Gestaltung

Die Beispiele erklären Methoden, keine bereits bewiesene Wirksamkeit von Linglossa. Produktiver Wortabruf ergänzt Lesen; eine Überlegenheit gegenüber allen anderen Apps wird nicht behauptet. Der Slider zählt sichtbare Wörter in genau diesem Beispiel, keine universelle Textabdeckung.

Quellen: [Webb 2005, rezeptives/produktives Wortwissen](https://doi.org/10.1017/S0272263105050023), [Yanagisawa et al. 2020, Worterklärungen beim Lesen](https://www.cambridge.org/core/journals/studies-in-second-language-acquisition/article/abs/how-do-different-forms-of-glossing-contribute-to-l2-vocabulary-learning-from-reading/38124150D59DF3039EE1FF5AE88FE922), [Cepeda et al. 2006, verteilte Übung](https://pubmed.ncbi.nlm.nih.gov/16719566/), [Karpicke & Roediger 2008, Abruf](https://doi.org/10.1126/science.1152408).

Refero-Inspiration: Brilliant für Mitmach-Erklärungen; [Clearful](https://refero.design/screens/5fa5947e-ffd9-4904-a1ed-6b8ba8f3fb74) für die Vergleichshierarchie. Die bestehenden Linglossa-Farben und Schriftarten bleiben maßgeblich.

## Auslieferung und Grenzen

- Supabase: `generate-vocabulary` Version 12 aktiv, anschließend Migration `20261115000001` angewandt. JWT-Prüfung bleibt aktiv; Aufruf ohne Anmeldung liefert HTTP 401. Live geprüft: eindeutiges Gratis-Kontingent, keine Freigabe-RPC-Rechte für Clients.
- Adapty: Monats-/Jahresabo ohne zugeordnete Angebote, Angebotslisten leer. **Apple-eigene Einführungsangebote bleiben zu prüfen:** App Store Connect verlangt eine Anmeldung. Die App blendet SDK-Produkte mit Einführungsangebot konsequent aus; falls Apple noch ein solches Angebot liefert, ist dieser Tarif bis zu dessen Entfernung nicht kaufbar.
- Die iOS-App wurde für den Simulator gebaut. Kein App-Store-/TestFlight-Upload und kein echter Storekauf durchgeführt.
- Gratis-Herkunft, Hinweis-Ablehnungen und einmalige Meilensteine sind lokal pro Konto gespeichert. Ihr geräteübergreifender Abgleich gehört nicht zu dieser Umsetzung.

## Prüfung

- Gesamte Flutter-Suite: **1.334 bestanden, 9 übersprungen**, keine Fehler. Enthält Kauf/Abbruch, Neustart, Konten-/Sprachwechsel, Migrationen, Home und Reader. Nach der letzten Korrektur am angehefteten Kaufknopf nochmals **63 gezielte UI-/Ablauftests bestanden**.
- `flutter analyze --no-pub`: **No issues found**. iOS-Simulator-Build erfolgreich.
- Paywall: acht Kombinationen aus Hell/Dunkel, 320/390 Punkten und 1×/2× Schrift; Interaktionen funktionieren. Barrierefreiheit mit echten Schriftarten: 26 Fälle bestanden. Alte Layout-Goldens verwenden weiterhin ihre bestehende Ersatzschrift.
- Backend: **18 Deno-Tests**, 11 PostgreSQL-Prüfgruppen für die Generation sowie bestehende Premium-/Geschenk-/Budgetprüfungen bestanden; zusätzliche Liveprüfung von Deployment, Index und RPC-Rechten.
- GitNexus-Änderungsanalyse ausgeführt. Geteilte Einstiege ergeben hohes/kritisches Risiko; gezielte Ablauf- und Gesamttests sind deshalb Bestandteil der Prüfung. Die begrenzte Pfadenumeration des Index wird nicht als Beweis vollständiger Aufrufabdeckung behandelt.

Ansichten: [Paywall hell](/Users/ardasayar/.codex/visualizations/2026/11/15/01a1e0d7-120b-7362-944c-edbbc85593e4/paywall-light-390-1.0-top.png), [Paywall dunkel](/Users/ardasayar/.codex/visualizations/2026/11/15/01a1e0d7-120b-7362-944c-edbbc85593e4/paywall-dark-390-1.0-top.png), [Wörter aufdecken](/Users/ardasayar/.codex/visualizations/2026/11/15/01a1e0d7-120b-7362-944c-edbbc85593e4/paywall-dark-390-1.0-words.png).
