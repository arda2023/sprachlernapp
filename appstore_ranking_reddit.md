# 📱 Wie man im App Store hoch rankt – was Reddit-Devs wirklich berichten

*Recherche: 13.11.2026 · Basis: 94 gelesene Reddit-Threads, davon **75 ausgewertet** (1.603 Kommentare) und **14 ausgeschlossen** (Werbung, Agentur-/Tool-Shills, KI-Posts). Zeitraum: Apr 2024 – Nov 2026, Schwerpunkt 2025/26.*

> **Kurzfazit:** Das Ranking selbst wird über **Titel/Untertitel/Keyword-Feld** und **Nutzerverhalten** (Downloads, Ratings, Conversion) entschieden. Screenshots entscheiden über die **Conversion**. Featuring bringt Sichtbarkeit, aber oft wenig Downloads. **Liquid Glass** und „alle Geräte“ bringen kein Such-Ranking. Sie helfen höchstens beim **Featuring** (z. B. in Apples Kollektionen zu neuen OS-Versionen).

---

## 🏆 Top-Faktoren auf einen Blick

Gezählt habe ich die **Threads (von 75), in denen der Faktor ernsthaft diskutiert wird**. Die Evidenz bewertet, wie viele Leute mit **eigenen Zahlen** berichten.

| # | Faktor | Threads | Evidenz |
|---|---|---|---|
| 1 | Titel + Untertitel + Keyword-Feld | 14 | 🟢 stark |
| 2 | Long-Tail statt Head-Terms | 10 | 🟢 stark |
| 3 | Erste 1–3 Screenshots (Conversion) | 13 | 🟢 stark |
| 4 | Externer Traffic (ASO als Verstärker) | 10 | 🟢 stark |
| 5 | Ratings/Reviews (frisch, pro Land) | 11 | 🟡 mittel |
| 6 | Featuring / Nominierungen | 18 | 🟡 viel Sichtbarkeit, wenige Downloads |
| 7 | Conversion & Keyword-Intent | 12 | 🟡 mittel |
| 8 | Lokalisierung | 10 | 🟡 sehr gemischt |
| 9 | Updates & Re-Indexierung | 10 | 🟡 gemischt |
| 10 | Download-Velocity | 5 | 🟡 plausibel, wenig Zahlen |
| 11 | Neue Apple-Technik (Widgets, LG …) | 8 | 🟠 nur fürs Featuring |
| 12 | Multi-Device (iPad/Mac/Watch/Vision) | 9 | 🟠 Einzelfälle |
| 13 | Liquid Glass | 17 | 🟠 viel Meinung, kein Ranking-Beleg |
| 14 | Apple Search Ads | 7 | 🟠 umstritten |
| 15 | In-App Events | 6 | 🟠 gemischt |
| 16 | New-App-Boost (Tag 4–7) | 5 | 🟢 konsistent beobachtet |
| 17 | PPO-A/B-Tests | 4 | 🟠 braucht viel Traffic |
| 18 | Video, Icon, CPP, Retention | je 2–3 | ⚪ dünn |

⚠️ Die Zahlen hängen von meinen Suchbegriffen ab. Zu Liquid Glass und Featuring habe ich gezielt gesucht, deshalb sind die Werte dort hoch. Eine Nennung heißt nicht, dass etwas wirkt.

---

## 1. 🔎 Ranking-Faktoren

### Titel, Untertitel, Keyword-Feld: der wichtigste Hebel
- **Belege mit Zahlen:**
  - Nach einer Metadaten-Änderung stieg ein Keyword von **#228 auf #66**, die US-Impressions von **30 auf 150 pro Tag** ([1ca78fc](https://www.reddit.com/r/iOSProgramming/comments/1ca78fc/)).
  - Allein durchs Title-Keyword landete eine App auf **#7 (iPhone) und #2 (iPad)** für „RPG Offline“ ([1u9q868](https://www.reddit.com/r/AppStoreOptimization/comments/1u9q868/)).
  - Mit **null Wort-Überschneidung** zwischen Titel, Untertitel und Keywords plus zusätzlichen Locale-Feldern stieg ein Keyword um **+231 auf #8**, und die Such-Downloads haben sich **verdoppelt** ([1we92js](https://www.reddit.com/r/AppBusiness/comments/1we92js/)).
    - ⚠️ Dort wurden auch Konkurrenz-Markennamen eingetragen. Das verstößt gegen die Richtlinien.
  - **824 Downloads in 20 Tagen** mit 27,4 % Conversion und 17 Lokalisierungen, nur durch ASO ([1t7v0r4](https://www.reddit.com/r/iosdev/comments/1t7v0r4/), Eigenwerbung).
  - Bei der 6. App kam der Dev durch Keyword-Recherche in die Top 10 ([1otk9im](https://www.reddit.com/r/iOSProgramming/comments/1otk9im/)).
- **Was alle sagen:**
  - Kein Wort doppelt in den Feldern.
  - Das wichtigste Keyword gehört in den Titel.
  - Die Beschreibung wird für die iOS-Suche **nicht** indexiert, der Promo-Text auch nicht ([1olbrqm](https://www.reddit.com/r/AppStoreOptimization/comments/1olbrqm/)).
- **Warnung:**
  - Ein Tippfehler in den türkischen Metadaten hat den TR-Store **7 Wochen** lang blockiert ([1t5bcak](https://www.reddit.com/r/iosdev/comments/1t5bcak/)).
  - KI-Keyword-Recherche halten mehrere für unzuverlässig.

### Long-Tail statt Head-Terms
- Eine neue App mit **20 Reviews** hat Apps mit **5.000 Reviews** auf Long-Tail-Begriffen überholt ([1lpy5j7](https://www.reddit.com/r/iOSProgramming/comments/1lpy5j7/)).
- Ein Dev mit **15–25 Downloads pro Tag** (inklusive Search Ads auf Exact Match) hing auf einem Head-Term bei **#180 fest** ([1qz6tsg](https://www.reddit.com/r/AppStoreOptimization/comments/1qz6tsg/)).
  - Head-Terms brauchen viel mehr Velocity und frische Reviews.
- Gegenbeispiel: Platz 1 auf einem Begriff ohne Suchvolumen bringt fast nichts. Das Volumen muss man prüfen.

### Downloads, Velocity, Ratings
- Die Charts richten sich nach dem **Download-Volumen**. Ratings werden **pro Land** gezählt ([1fiqnsa](https://www.reddit.com/r/iOSProgramming/comments/1fiqnsa/)).
- Bei Rang-Verlusten trotz guter Zahlen vermuten Devs: Was zählt, ist **die Velocity im Vergleich zur Konkurrenz**, nicht die Gesamtzahl ([1tr1goq](https://www.reddit.com/r/AppStoreOptimization/comments/1tr1goq/)).
  - Dort hatten sich die Ratings verdoppelt, und der Rang fiel trotzdem.
- Tipp mit Praxisbezug: Den Review-Prompt nach einem **Erfolgsmoment** zeigen ([1ljcqx7](https://www.reddit.com/r/iOSProgramming/comments/1ljcqx7/)).

### ASO als Verstärker, nicht als Quelle (größter Konsens)
- Der Mehrheits-Tenor in [1ttild2](https://www.reddit.com/r/appledevelopers/comments/1ttild2/): „ASO multipliziert vorhandene Nachfrage.“
  - Ein Dev hatte **29 Sprachen** und trotzdem nur **50–60 Impressions pro Tag**.
  - Einzelne widersprechen: Bekannte hätten **5.000 $** allein mit ASO verdient.
- In einer gesättigten Nische hat ein Jahr monatlicher Updates nicht gereicht, um den Marktführer zu schlagen ([1v3giwe](https://www.reddit.com/r/AppStoreOptimization/comments/1v3giwe/)).
- Eine App mit tollen **Live Activities und Widgets** hatte trotzdem **fast null Downloads**, weil niemand danach sucht ([1v2q2wc](https://www.reddit.com/r/iosdev/comments/1v2q2wc/), [1tdhgvk](https://www.reddit.com/r/iosdev/comments/1tdhgvk/)).
- Positivbeispiel: Durch TikTok stiegen die Impressions von **600 auf 62.000 pro Tag** und die Downloads von **25 auf 600 pro Tag**. **66 %** kamen danach über die Suche ([1ljcqx7](https://www.reddit.com/r/iOSProgramming/comments/1ljcqx7/)).
- Web-SEO plus ASO: Die Downloads stiegen von **151 auf 772 pro 30 Tage** ([1x94hrl](https://www.reddit.com/r/AppBusiness/comments/1x94hrl/)).

### New-App-Boost
Drei unabhängige Devs berichten dasselbe Muster: **Tag 4–5 fallen die Rankings stark** ([1oky6qe](https://www.reddit.com/r/AppStoreOptimization/comments/1oky6qe/), [1nscae9](https://www.reddit.com/r/AppStoreOptimization/comments/1nscae9/), [1qmb53r](https://www.reddit.com/r/AppStoreOptimization/comments/1qmb53r/)). Den Launch also mit externem Traffic koordinieren.

### Updates & Re-Indexierung
- Eine Metadaten-Änderung bringt **1–2 Wochen Schwankung**. Ein *nicht geändertes* Title-Keyword fiel von **#16 auf #167** und erholte sich danach ([1uho2iq](https://www.reddit.com/r/AppStoreOptimization/comments/1uho2iq/)).
- Wenn die Impressions steigen, aber die Downloads nicht, passt meist der **Keyword-Intent** nicht. Dann 2–3 Wochen warten ([1t9cpf6](https://www.reddit.com/r/AppStoreOptimization/comments/1t9cpf6/)).
- Ob häufige Updates helfen, ist **umstritten**, siehe Mythen.

### In-App Events, Custom Product Pages, Search Ads
- **IAE:** Ein Dev berichtet von etwa **50.000 Impressions pro Tag über 3 Tage** ([1owe2cq](https://www.reddit.com/r/iOSProgramming/comments/1owe2cq/)). Ein anderer hatte bei rund **10 Events 0 Impressions** ([1oe023s](https://www.reddit.com/r/AppStoreOptimization/comments/1oe023s/)). Tenor: Events verstärken Nachfrage, die schon da ist ([1spw74t](https://www.reddit.com/r/iOSAppsMarketing/comments/1spw74t/)).
- **CPP:** Seit Juli 2025 können CPPs eigene Keywords bekommen ([1md0jin](https://www.reddit.com/r/ASO/comments/1md0jin/)). Laut 2025-Recap wurden die Limits erhöht: IAE von 10 auf 15, CPP von 35 auf 70 ([1pujdnp](https://www.reddit.com/r/AppStoreOptimization/comments/1pujdnp/)).
- **Search Ads:** Mehrere sagen, ASA verbessert den organischen Rang **nicht direkt** ([1qz6tsg](https://www.reddit.com/r/AppStoreOptimization/comments/1qz6tsg/)). Andere berichten von besseren Rankings, solange Ads laufen. Das ist unbelegt.

> 📘 **Apple offiziell (keine Reddit-Quelle):**
> - Die Suche wertet **Textrelevanz** aus (Titel, Untertitel, Keywords, Primärkategorie) und **Nutzerverhalten** (u. a. Downloads, Ratings und Reviews).
> - Das Keyword-Feld hat 100 Zeichen, ohne Wiederholungen. **Promo-Text beeinflusst das Ranking nicht.**
> - In den Suchergebnissen erscheinen **bis zu 3 Screenshots**.
>
> Quelle: [developer.apple.com/app-store/search](https://developer.apple.com/app-store/search/)

---

## 2. 🎨 UI/UX & Funktionen

- Ob die App **gut** ist, hat laut Reddit **kaum direkten Einfluss auf die Suche**.
  - Sie wirkt indirekt über Ratings, Retention und Mundpropaganda.
  - Sie wirkt direkt beim **Featuring**.
- Was Apple-Editoren laut Berichten mögen:
  - Barrierefreiheit (Accessibility)
  - Lokalisierung
  - **neue Apple-Frameworks und APIs** (Widgets, Live Activities, App Intents, neues Design)
  - Bei [1o0eq4e](https://www.reddit.com/r/iOSProgramming/comments/1o0eq4e/) hat Apple einem Dev geraten, „so viele Apple-Frameworks wie möglich“ zu nutzen.
  - Eine Tastatur-App mit einer neuen API kam auf **über 1 Mio. Downloads in 21 Tagen** (Bericht eines Kommentators).
- **Native Komponenten** schlagen eigene Controls. Ein Senior-Designer und mehrere Devs raten, der HIG zu folgen, z. B. beim Standard-Tab-Bar ([1ooec6g](https://www.reddit.com/r/iOSProgramming/comments/1ooec6g/)).
- **Widgets und Live Activities** sind gut für die Bindung, schaffen aber **keine Nachfrage** ([1v2q2wc](https://www.reddit.com/r/iosdev/comments/1v2q2wc/), [1s4gkwq](https://www.reddit.com/r/AppBusiness/comments/1s4gkwq/)).
  - Beim zweiten Beispiel: Liquid Glass, 6 Widgets und eine Watch-App ergaben trotzdem nur **41 Downloads in der ersten Woche**.
- Gegenstimme: Schnell veröffentlichen und ein Problem lösen ist wichtiger als eine perfekte UI ([1q6ni4j](https://www.reddit.com/r/iosdev/comments/1q6ni4j/)).
- Eine App zu verbessern hat bei einem Dev die Downloads **nicht automatisch** erhöht. Sie blieben bei etwa 5 pro Tag ([1vw6hc9](https://www.reddit.com/r/iosdev/comments/1vw6hc9/)).

---

## 3. 🖼️ Screenshots & Store-Seite

**Konsens:** Screenshots beeinflussen die **Conversion**, nicht das Ranking. Über die Velocity wirken sie aber indirekt auch aufs Ranking.

- **Belege mit Zahlen:**
  - Nach PPO-Tests der ersten 3 Screenshots stieg die CVR von **4–5 % auf 12,3 %** ([1ufjstp](https://www.reddit.com/r/AppStoreOptimization/comments/1ufjstp/)). Gewonnen hat das Value Proposition **ohne UI-Screenshot**.
  - Ein erster Screenshot mit **einer** klaren Botschaft brachte **11 % → 16,3 %** ([1sinyza](https://www.reddit.com/r/AppStoreOptimization/comments/1sinyza/), Eigenwerbung).
- **Gegenbeleg:** 4 PPO-Tests bei 9.000 Impressions blieben ohne Ergebnis (Unterschied unter 1 %) ([1im4eg4](https://www.reddit.com/r/indieappdev/comments/1im4eg4/)).
  - Die **Traffic-Quelle** wog viel schwerer: FB etwa 50 % gegenüber ASA 0,8 %.
  - PPO lohnt sich erst mit viel Traffic.
- **Lesbarkeit auf dem Handy:** In [1ssw8o4](https://www.reddit.com/r/iosdev/comments/1ssw8o4/) kritisieren etwa 20 Kommentare die Screenshots als „zu voll, unlesbar“.
  - Faustregel: ein Satz pro Bild, große Schrift, **Nutzen** statt Feature-Liste.
  - Beim OP haben Landscape-Screenshots besser funktioniert.
- **Video:** Die Ergebnisse sind gemischt. Apple ist streng: Erlaubt sind nur echte Screen-Recordings ([1mgwe0v](https://www.reddit.com/r/iOSProgramming/comments/1mgwe0v/)).
  - Laut Apples PPO-Seite hat bei Simply Piano die Version **ohne** Video gewonnen.
- **Featuring-Traffic** ist Browse-Traffic mit niedriger Kaufabsicht. Auch beim Featuring entscheiden Icon und erster Screenshot.

---

## 4. 🍎 Alle Apple-Geräte optimieren?

**Kurz: Es hilft nicht beim iPhone-Ranking. Jedes Gerät ist ein eigener Markt mit eigener Platzierung.**

- **Mac:**
  - Stärkster Einzelfall: Nach **3 erfolglosen Jahren auf iOS** kam ein nativer Mac-Port **in einer Woche in die Top 100 der bezahlten Produktivitäts-Apps** (US-Mac) ([1n1y6c9](https://www.reddit.com/r/ProductivityApps/comments/1n1y6c9/)).
  - Der Mac App Store ist weniger umkämpft.
- **iPad:**
  - Das iPad-Ranking ist **getrennt** vom iPhone. Siehe #2 auf dem iPad gegenüber #7 auf dem iPhone ([1u9q868](https://www.reddit.com/r/AppStoreOptimization/comments/1u9q868/)).
  - In [1tipaym](https://www.reddit.com/r/iOSProgramming/comments/1tipaym/) waren 8 % der Nutzer auf dem iPad. Ein Dev sagt, die **iPad-Optimierung hat ihm nichts gebracht**.
  - Andere meinen, ein iPad-Layout erleichtert Mac und visionOS.
  - Achtung: Ist der iPad-Support einmal aktiviert, muss er bleiben.
- **Apple Watch:**
  - Die Auffindbarkeit ist schlecht.
  - Watch-Apps installiert man übers iPhone. „Niemand sucht nach reinen Watch-Apps.“ Ein Dev hatte **99 % seiner Downloads über Social Media** ([1i2e34a](https://www.reddit.com/r/AppleWatch/comments/1i2e34a/)).
  - Eine Watch-App war im iPhone-Store nicht mal über den Namen zu finden (808phone in [1otk9im](https://www.reddit.com/r/iOSProgramming/comments/1otk9im/)).
  - Aber: Eine Watch-App mit Liquid-Glass-Refresh kam ins Featuring „Great Apps Updated for watchOS 26“ ([1q3zqrr](https://www.reddit.com/r/apple/comments/1q3zqrr/)).
- **Vision Pro:** Sehr kleine Nutzerbasis. Die Auffindbarkeit ist schwer ([1qpz6x8](https://www.reddit.com/r/visionosdev/comments/1qpz6x8/)).

**Fazit:** Mehr Geräte bedeuten mehr Märkte und mehr Featuring-Chancen. Ein Boost für das iPhone-Ranking ist **nicht belegt**.

---

## 5. 💧 Liquid Glass?

**Es gibt keinen einzigen Beleg, dass Liquid Glass das Such-Ranking verbessert.** Diskutiert wird es fast nur im Zusammenhang mit **Featuring** und **Wahrnehmung**.

**Pro:**
- bsoci hat 2 Apps auf Liquid Glass umgestellt und wurde **am iOS-26-Launchtag gefeatured** ([1npmh3y](https://www.reddit.com/r/iosdev/comments/1npmh3y/)). Eigene Erfahrung, ohne Download-Zahlen.
- Die Watch-App aus [1q3zqrr](https://www.reddit.com/r/apple/comments/1q3zqrr/) wurde nach dem LG-Refresh in einer watchOS-26-Kollektion gefeatured.
- Weitere Stimmen, alles **Meinungen ohne Belege:**
  - „Apple promotet aktualisierte Apps“ (16 Punkte in [1njnt6h](https://www.reddit.com/r/iOSProgramming/comments/1njnt6h/)).
  - „Apps, die das Design richtig umsetzen, werden öfter gefeatured“ ([1niof9p](https://www.reddit.com/r/iOSProgramming/comments/1niof9p/)).
  - Neue APIs und Liquid Glass ab Tag 1 helfen ([1o4vkvo](https://www.reddit.com/r/iOSProgramming/comments/1o4vkvo/)).
  - Sinngemäß: Wenn große Apps zögern, haben kleine Devs eine Chance (47 Punkte in [1nyst81](https://www.reddit.com/r/ios/comments/1nyst81/)).
- Wer es nicht unterstützt, wirkt auf manche Nutzer **veraltet** ([1otg591](https://www.reddit.com/r/iosapps/comments/1otg591/), [1u7dhry](https://www.reddit.com/r/LiquidGlassDesign/comments/1u7dhry/)). Ein Nutzer sagt: „Fehlt Liquid Glass, gehe ich woanders hin“ ([1ooec6g](https://www.reddit.com/r/iOSProgramming/comments/1ooec6g/)).

**Contra:**
- „Den Nutzern ist es egal“ (61 Punkte, [1njnt6h](https://www.reddit.com/r/iOSProgramming/comments/1njnt6h/)). Die Gegenstimme sagt: Kunden wollen vor allem **Konsistenz**.
- **Übertreibung schadet:** Glas auf Glas macht die Tab-Bar unlesbar. Laut HIG gehört Liquid Glass nur auf die **Navigationsebene** (58 Punkte, [1rb3u70](https://www.reddit.com/r/iOSProgramming/comments/1rb3u70/)). Dazu kommen Bedenken wegen der Barrierefreiheit.
- Viele große Apps übernehmen es nur minimal und behalten ihre eigene Optik ([1nqf2rr](https://www.reddit.com/r/iOSProgramming/comments/1nqf2rr/)).

**Technisch:**
- Native Controls übernehmen Liquid Glass **automatisch**, sobald man mit Xcode 26 neu kompiliert. Eigene Controls gehen dabei teils kaputt.
- Das Opt-out `UIDesignRequiresCompatibility` gilt nur **vorübergehend** ([1niof9p](https://www.reddit.com/r/iOSProgramming/comments/1niof9p/), [1nqf2rr](https://www.reddit.com/r/iOSProgramming/comments/1nqf2rr/)).

**Empfehlung (Synthese):** Liquid Glass **sauber und sparsam** nutzen, mit nativen Komponenten und nur auf der Navigationsebene. Das ist günstig, wirkt zeitgemäß und kann bei Nominierungen ein Argument sein. Es ist aber **kein Ranking-Hebel**.

---

## 6. ⚖️ Mythen & Widersprüche

| Behauptung | Stand auf Reddit |
|---|---|
| „Apple indexiert Text in Screenshots (OCR)“ | **Umstritten bis widerlegt.** Kam von einem Vendor-Post. Gegenbeispiele: Eine Agentur mit 80 Apps sah keinen Effekt, ein Selbsttest brachte keinen Boost ([1lav1w2](https://www.reddit.com/r/AppStoreOptimization/comments/1lav1w2/)). |
| „Häufige Updates verbessern das Ranking“ | **Widersprüchlich.** Top-Apps gehen ein Jahr ohne Update. Ein Dev sah Vorteile bei wöchentlichen Updates ([1n00jh2](https://www.reddit.com/r/iOSProgramming/comments/1n00jh2/)). Ein Vendor sagt, jedes Update löst eine Re-Indexierung aus ([1r11st7](https://www.reddit.com/r/AppStoreOptimization/comments/1r11st7/)). Ein anderer sah keinen Umsatzeffekt ([1ogkkb0](https://www.reddit.com/r/iOSProgramming/comments/1ogkkb0/)). |
| „ASO allein reicht“ | Die **Mehrheit sagt nein**. Einzelne Gegenbeispiele ohne Belege ([1ttild2](https://www.reddit.com/r/appledevelopers/comments/1ttild2/)). |
| „Lokalisierung bringt immer viel“ | **Gemischt.** Ein Dev mit 10 Sprachen: Deutschland stieg von 2 % auf 18 % der Downloads, die Impressions von 4.300 auf 14.900 ([1qa83ar](https://www.reddit.com/r/AppStoreOptimization/comments/1qa83ar/), Eigenwerbung). Ein anderer sagt, es habe sich nicht gelohnt ([1lo84uu](https://www.reddit.com/r/AppStoreOptimization/comments/1lo84uu/)). |
| „Featuring = Erfolg“ | **Nein.** 2 Mio. Impressions brachten 3.800 Downloads (0,02 %) ([1tsav3o](https://www.reddit.com/r/iosdev/comments/1tsav3o/)). Eine App wurde in 84 Ländern gefeatured, aber in den falschen Regionen ([1u02cm3](https://www.reddit.com/r/iosdev/comments/1u02cm3/)). Ein anderer Dev hatte 7 Wochen lang 5-fache Impressions bei 0,1 % CVR ([1mf063c](https://www.reddit.com/r/AppStoreOptimization/comments/1mf063c/)). Positiv: Platz 14 in den UK-Charts mit etwa 400 Downloads pro Tag ([1lrioi8](https://www.reddit.com/r/iosapps/comments/1lrioi8/)). |
| „Ranking-Effekte zeigen sich am selben Tag“ | Das sagt ein Vendor. Devs berichten von 1–2 Wochen Schwankung, mit Wirkung nach 2–6 Wochen. |
| „Search Ads boosten den organischen Rang“ | Mehrere sagen: nicht direkt. Einzelne erleben es anders. Unbelegt. |
| „Video steigert die Conversion“ | Gemischt. Ein offizielles Apple-Beispiel zeigt sogar einen Verlust. |

---

## 7. ✅ Praktische Checkliste *(meine Synthese)*

1. **Keyword-Recherche:** Begriffe finden, die Volumen haben **und** gewinnbar sind (Long-Tail). Das Haupt-Keyword in den Titel.
2. **Titel, Untertitel und Keywords** (100 Zeichen) ohne Wortdoppelungen. Keine Plurale, keine Füllwörter, keine fremden Marken.
3. **Zusätzliche Locales** nutzen (in Deutschland z. B. Englisch (UK)), dazu echte Lokalisierung für die Zielmärkte. Tippfehler vermeiden!
4. **Die ersten 3 Screenshots:** je eine Botschaft, große Schrift, Nutzen zuerst, auf dem Handy lesbar.
5. **Launch mit externem Traffic** zeitlich abstimmen (TikTok, Reddit, Web-SEO). Der Boost hält nur etwa 4–5 Tage.
6. **Ratings:** Den Prompt nach einem Erfolgsmoment zeigen. Auf frische Reviews in den Kernländern achten.
7. **Metadaten selten ändern.** Danach 2–3 Wochen warten und erst dann bewerten.
8. **PPO-Tests** erst ab spürbarem Traffic. Vorher qualitativ testen und Feedback holen.
9. **Featuring:** Jedes größere Update **3–4 Wochen vorher** nominieren. Die App sollte schon freigegeben sein. Erwähnen: native Technik, Accessibility, Lokalisierung. Mit niedriger Conversion rechnen.
10. **In-App Events** nutzen, wenn es echte Anlässe gibt. Sie verstärken, sie erzeugen keine Nachfrage.
11. **Liquid Glass:** native Komponenten, sparsam, nur auf der Navigationsebene. Als Pluspunkt fürs Featuring sehen, nicht fürs Ranking.
12. **Weitere Geräte** nur, wenn sie zum Use-Case passen (Mac und iPad bei Produktivität). Jedes Gerät hat eigene Rankings.

---

## 8. 💡 Was heißt das für deine Apps? *(Synthese, nicht aus den Quellen belegt)*

### 📚 Notiz- und Karteikarten-App (à la RemNote)
- **iPad und Mac lohnen sich hier wohl am ehesten.** Lernen passiert oft am Tablet und Laptop, und der Mac App Store ist weniger umkämpft (vgl. den Mac-Fall [1n1y6c9](https://www.reddit.com/r/ProductivityApps/comments/1n1y6c9/)).
  - Dann aber **echt nativ** bauen, kein gestrecktes iPhone-Layout.
- **Long-Tail-Keywords** wie „Karteikarten“, „Spaced Repetition“, „Lernkarten PDF“, „Anki Alternative“. Auf Markennamen verzichten, das verstößt gegen die Richtlinien.
- **Widgets** (Karten des Tages) und **App Intents/Shortcuts** sind gut für die Retention und sprechen beim Featuring für dich. Rechne aber nicht mit einem Ranking-Boost.
- **Screenshots** zeigen Ergebnisse, z. B. „Lerne 2× schneller“ oder „aus Notizen werden automatisch Karten“.

### 🚇 Kontrolleur-Warn-App (ÖPNV)
- Gefahr wie bei [1v2q2wc](https://www.reddit.com/r/iosdev/comments/1v2q2wc/): Wenn kaum jemand nach so etwas **sucht**, bringt ASO wenig.
  - Dann treibt **lokale Community** das Wachstum (Stadt-Subreddits, Telegram, Mundpropaganda). Das schiebt über die Velocity auch die Suche an.
- Lokale deutsche Keywords für jede Stadt, z. B. „Kontrolleure [Stadt]“ oder „Ticketkontrolle melden“. Vorher die Volumen prüfen.
- **Live Activities und Widgets** passen inhaltlich gut (Warnung auf der aktuellen Linie). Eine **Watch-App** wird kaum gefunden. Höchstens als Bonus für Benachrichtigungen.
- Featuring durch Apple ist bei diesem Thema eher unwahrscheinlich. Plane nicht damit.

---

## 9. 🔬 Methode & Grenzen

- **Suche:** Die Threads habe ich per Websuche gefunden. Gelesen habe ich sie über das öffentliche Reddit-Archiv Arctic Shift: Post plus kompletter Kommentarbaum.
  - Die direkte Reddit-API war gesperrt (403). Die Archiv-Suche brach mit Timeouts ab. Ich habe nichts umgangen.
- **Umfang:** 94 Threads mit 1.766 Kommentaren gelesen. **75 Threads mit 1.603 Kommentaren** wertet dieser Bericht aus.
  - **14 habe ich ausgeschlossen:** Werbung oder Tool-Shills (u. a. AstroASO, Applyra, PreviewPro, Appthetics, Screenshot-Tools), Agentur-Posts und KI-Texte, die in den Kommentaren als solche entlarvt wurden.
  - 5 weitere waren kaum relevant.
- **Flags:** Posts mit Eigenwerbung oder von Vendoren habe ich behalten, wenn die Daten plausibel waren. Sie sind im Anhang markiert.
- **Grenzen:**
  - Fast alle Zahlen sind **Einzelberichte**, die sich nicht prüfen lassen. Kausalität ist nie sicher.
  - Die Auswahl der Threads hängt von meinen Suchbegriffen ab.
  - Gezählt habe ich Nennungen pro Thread. Das ist **keine** Messung der Wirkung.
  - Apples Algorithmus ist nicht öffentlich. Apple-Quellen sind als „offiziell“ markiert.
- **Offizielle Ergänzungen:**
  - [App Store Search](https://developer.apple.com/app-store/search/)
  - [Getting Featured](https://developer.apple.com/app-store/getting-featured/): Kriterien sind u. a. UX, UI-Design, Innovation, Accessibility, Lokalisierung und die Produktseite. Nominierungen mindestens 2 Wochen, ideal bis 3 Monate vorher. Die Connect-Hilfe nennt mindestens 3 Wochen.
  - [Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/)

---

## 📎 Anhang: alle gelesenen Threads

Flags: 🟢 ok · 🏷️ Eigenwerbung · 🏢 Agentur/Vendor · 🤖 KI-Verdacht · ⛔ ausgeschlossen · ⚪ kaum relevant/ohne Kommentare

### Ausgewertete Threads (80 – davon 5 ⚪ kaum relevant)

- **[Update on my $200 marketing experiment: v2.3 is live! (ASO &](https://www.reddit.com/r/iosdev/comments/1xlxe9t/)** · r/iosdev · 2026-11-02 · 🟢<br>200-$-Experiment ASO & Search Ads
- **[Solo dev, no ads, no backlinks to speak of: what 3 months of](https://www.reddit.com/r/AppBusiness/comments/1x94hrl/)** · r/AppBusiness · 2026-10-18 · 🟢<br>SEO + ASO: 151→772 DL/30 Tage
- **[Three months of metadata work on one iOS listing, actual num](https://www.reddit.com/r/AppBusiness/comments/1we92js/)** · r/AppBusiness · 2026-09-12 · 🟢<br>3 Monate Metadaten: +231 auf #8, Suche ×2
- **[I'm awful at iOS ASO - Need Advice](https://www.reddit.com/r/iosdev/comments/1w35nkr/)** · r/iosdev · 2026-08-31 · 🟢<br>ASO-Hilfe: Titel, Screenshots, Icon, Video
- **[What I Learned From Getting 1,000 Downloads on My First App](https://www.reddit.com/r/iosdev/comments/1vw6hc9/)** · r/iosdev · 2026-08-23 · ⚪<br>1.000 DL erste App, ~5/Tag konstant
- **[Does Apple's editorial team actually reward accessibility? I](https://www.reddit.com/r/iosdev/comments/1vcraey/)** · r/iosdev · 2026-08-01 · ⚪<br>Belohnt Apple Accessibility? Keine Kommentare
- **[Question: Can ASO alone get you anywhere in a saturated nich](https://www.reddit.com/r/AppStoreOptimization/comments/1v3giwe/)** · r/AppStoreOptimization · 2026-07-22 · 🟢<br>ASO in gesättigter Nische: reicht nicht
- **[I'm a solo dev, i think my app is genuinely good, but acquis](https://www.reddit.com/r/iosdev/comments/1v2q2wc/)** · r/iosdev · 2026-07-21 · 🟢<br>Gute App, Live Activities/Widgets, ~0 Downloads
- **[Lost all the rank on keyword I didnt change](https://www.reddit.com/r/AppStoreOptimization/comments/1uho2iq/)** · r/AppStoreOptimization · 2026-06-28 · 🟢<br>Nicht geändertes Keyword 16→167 nach Update
- **[Reached 12.3% App Store Conversion Rate via Screenshot PPO t](https://www.reddit.com/r/AppStoreOptimization/comments/1ufjstp/)** · r/AppStoreOptimization · 2026-06-25 · 🟢<br>PPO erste 3 Screenshots: CVR 4–5 % → 12,3 %
- **[Small ASO win: my indie RPG is now #7 on iPhone and #2 on iP](https://www.reddit.com/r/AppStoreOptimization/comments/1u9q868/)** · r/AppStoreOptimization · 2026-06-19 · 🟢<br>Title-Keyword: #7 iPhone, #2 iPad
- **[iOS26/27 Liquid Glass App support Rant](https://www.reddit.com/r/LiquidGlassDesign/comments/1u7dhry/)** · r/LiquidGlassDesign · 2026-06-16 · ⚪<br>Nutzer-Rant: Apps ohne LG wirken alt
- **[(Showcase) I rebuilt my clipboard manager as one native app ](https://www.reddit.com/r/MacOSApps/comments/1u52rvt/)** · r/MacOSApps · 2026-06-13 · ⚪<br>Clipboard-App nativ für alle Geräte, keine Kommentare
- **[Has anyone here actually been featured or nominated by the A](https://www.reddit.com/r/iOSAppsMarketing/comments/1u32zz1/)** · r/iOSAppsMarketing · 2026-06-11 · 🟢<br>Featuring-Erfahrungen; früher 6.000 $, heute 150 $
- **[My app got featured by apple in 84 countries and it was a di](https://www.reddit.com/r/iosdev/comments/1u02cm3/)** · r/iosdev · 2026-06-08 · 🟢<br>Featured in 84 Ländern, falsche Regionen, 6 % CVR
- **[ASO is a lie and nobody who "made it" is telling you the ful](https://www.reddit.com/r/appledevelopers/comments/1ttild2/)** · r/appledevelopers · 2026-06-01 · 🟢<br>„ASO ist eine Lüge“: Multiplikator-Debatte
- **[Stats from my indie game after an 8 week App Store feature](https://www.reddit.com/r/iosdev/comments/1tsav3o/)** · r/iosdev · 2026-05-30 · 🟢<br>8 Wochen Featuring: 2M Impressions, 3,8K DL
- **[Lost 8 ranks in 48 hours while every metric is improving. WT](https://www.reddit.com/r/AppStoreOptimization/comments/1tr1goq/)** · r/AppStoreOptimization · 2026-05-29 · 🟢<br>Rangverlust trotz besserer Metriken; Velocity relativ
- **[I made an app for creating cool profile pictures](https://www.reddit.com/r/iosapps/comments/1trchmq/)** · r/iosapps · 2026-05-29 · ⚪<br>Profilbild-App, kaum relevant
- **[Gaining Users](https://www.reddit.com/r/AppleWatchApps/comments/1tnf5t6/)** · r/AppleWatchApps · 2026-05-25 · ⚪<br>Watch-App: wie Nutzer gewinnen
- **[8% of my users are on iPad, but I’ve never officially suppor](https://www.reddit.com/r/iOSProgramming/comments/1tipaym/)** · r/iOSProgramming · 2026-05-20 · 🟢<br>8 % iPad-Nutzer; Optimierung brachte nichts
- **[When is it time to reconsider ASO](https://www.reddit.com/r/iosdev/comments/1tdhgvk/)** · r/iosdev · 2026-05-15 · 🟢<br>Wann ASO aufgeben? Nachfrageproblem
- **[ASO impressions are up after metadata changes, but downloads](https://www.reddit.com/r/AppStoreOptimization/comments/1t9cpf6/)** · r/AppStoreOptimization · 2026-05-10 · 🟢<br>Impressions ↑, Downloads flat: Intent-Mismatch
- **[824 iOS downloads and $96 with fully ASO within 20 Days with](https://www.reddit.com/r/iosdev/comments/1t7v0r4/)** · r/iosdev · 2026-05-09 · 🏷️<br>824 DL in 20 Tagen nur ASO, 17 Sprachen
- **[My 2nd app has made $10 in 7 weeks. I just spent a week doin](https://www.reddit.com/r/iosdev/comments/1t5bcak/)** · r/iosdev · 2026-05-06 · 🏷️<br>TR-Tippfehler blockiert Store 7 Wochen
- **[Working on ASO - would these screenshots make you download?](https://www.reddit.com/r/iosdev/comments/1ssw8o4/)** · r/iosdev · 2026-04-22 · 🟢<br>Screenshot-Review: zu voll, unlesbar
- **[First In-App Event live on May 1st. Any tips & tricks on how](https://www.reddit.com/r/iOSAppsMarketing/comments/1spw74t/)** · r/iOSAppsMarketing · 2026-04-19 · 🟢<br>Erstes IAE: verstärkt nur vorhandene Nachfrage
- **[Switching one screenshot took my conversion from 11% to 16.3](https://www.reddit.com/r/AppStoreOptimization/comments/1sinyza/)** · r/AppStoreOptimization · 2026-04-11 · 🏷️<br>Erster Screenshot mit einer Botschaft: 11 → 16,3 %
- **[First iOS app, first week: 41 downloads, 15.5% conversion ra](https://www.reddit.com/r/AppBusiness/comments/1s4gkwq/)** · r/AppBusiness · 2026-03-26 · ⚪<br>LG + 6 Widgets + Watch: 41 DL in Woche 1
- **[Refreshed screenshots after only 220 downloads in 2 months](https://www.reddit.com/r/AppStoreOptimization/comments/1rgiwyx/)** · r/AppStoreOptimization · 2026-02-27 · 🟢<br>Screenshot-Refresh nach 220 DL in 2 Monaten
- **[We adopted Liquid Glass on our wellness app's home screen — ](https://www.reddit.com/r/iOSProgramming/comments/1rb3u70/)** · r/iOSProgramming · 2026-02-21 · 🟢<br>Zu viel LG: Lesbarkeit, HIG = nur Navigation
- **[Do code-only app updates affect keyword rankings?](https://www.reddit.com/r/AppStoreOptimization/comments/1r11st7/)** · r/AppStoreOptimization · 2026-02-10 · 🏢<br>Code-Updates und Keyword-Rankings (Vendor-Antwort)
- **[I’m getting downloads and some revenue, but my App Store ran](https://www.reddit.com/r/AppStoreOptimization/comments/1qz6tsg/)** · r/AppStoreOptimization · 2026-02-08 · 🟢<br>15–25 DL/Tag, Head-Term #180: frische Reviews
- **[Proof that App Store Nominations actually work!](https://www.reddit.com/r/iosdev/comments/1qvdmfi/)** · r/iosdev · 2026-02-04 · 🟢<br>Game of the Day nach 8 Monaten Nominierungen
- **[Distribution Activities](https://www.reddit.com/r/visionosdev/comments/1qpz6x8/)** · r/visionosdev · 2026-01-29 · 🟢<br>visionOS: Distribution schwierig
- **[Day 4 of my new app](https://www.reddit.com/r/AppStoreOptimization/comments/1qmb53r/)** · r/AppStoreOptimization · 2026-01-25 · 🟢<br>Tag 4: gleicher Einbruch
- **[Localized my app into 10 languages. Germany went from 2% to ](https://www.reddit.com/r/AppStoreOptimization/comments/1qa83ar/)** · r/AppStoreOptimization · 2026-01-11 · 🏷️<br>10 Sprachen: DE 2→18 % der Downloads
- **[Indie iOS dev isn’t dead (small but real data point)](https://www.reddit.com/r/iosdev/comments/1q6ni4j/)** · r/iosdev · 2026-01-07 · ⚪<br>Indie lebt: schnell shippen > perfekte UI
- **[I made an Apple Watch app to guide people to running their f](https://www.reddit.com/r/apple/comments/1q3zqrr/)** · r/apple · 2026-01-04 · 🏷️<br>Watch-App mit LG-Refresh gefeatured
- **[ASO Recap of 2025](https://www.reddit.com/r/AppStoreOptimization/comments/1pujdnp/)** · r/AppStoreOptimization · 2025-12-24 · 🟢<br>ASO-Recap 2025: IAE/CPP-Limits, App Tags
- **[Feedback on App Store Screenshots, Thoughts on Preview Video](https://www.reddit.com/r/iOSProgramming/comments/1pquc85/)** · r/iOSProgramming · 2025-12-19 · ⚪<br>Screenshot-/Video-Feedback
- **[I spent 6 months building Nutbox for iOS to save the stuff I](https://www.reddit.com/r/SideProject/comments/1pgsl6s/)** · r/SideProject · 2025-12-07 · ⚪<br>Nutbox-Launch, Featuring-Erwähnung
- **[Update Event lead to 150k impressions in three days but from](https://www.reddit.com/r/iOSProgramming/comments/1owe2cq/)** · r/iOSProgramming · 2025-11-13 · ⚪<br>Update-Event: ~150k Impressions in 3 Tagen
- **[Has anyone successfully got a “Nomination” section or “Nomin](https://www.reddit.com/r/iOSProgramming/comments/1ousgdu/)** · r/iOSProgramming · 2025-11-12 · 🟢<br>Nominierung: Mo/Di, Saisonalität, Widgets/LG (Hörensagen)
- **[I created a guide on App Store keyword research to rank high](https://www.reddit.com/r/iOSProgramming/comments/1otk9im/)** · r/iOSProgramming · 2025-11-10 · 🟢<br>Keyword-Guide; Top 10 bei 6. App; Watch-App per Name unauffindbar
- **[Do you use liquid glass](https://www.reddit.com/r/iosapps/comments/1otg591/)** · r/iosapps · 2025-11-10 · 🟢<br>Nutzer zu LG: ohne wirkt veraltet / Accessibility
- **[Liquid Glass update question](https://www.reddit.com/r/iOSProgramming/comments/1ooec6g/)** · r/iOSProgramming · 2025-11-04 · 🟢<br>LG-Tab-Bar vs. eigene: Standard bevorzugt
- **[Is iOS ASO really just Title, Subtitle, and Keywords?](https://www.reddit.com/r/AppStoreOptimization/comments/1olbrqm/)** · r/AppStoreOptimization · 2025-11-01 · 🟢<br>Nur Titel/Untertitel/Keywords? Beschreibung nicht indexiert
- **[Downloads Dropped After Day 4 – Any Insight on ASO or Algori](https://www.reddit.com/r/AppStoreOptimization/comments/1oky6qe/)** · r/AppStoreOptimization · 2025-10-31 · 🟢<br>Downloads fallen ab Tag 4
- **[Senior iOS dev by day, indie developer by night - lessons fr](https://www.reddit.com/r/iOSProgramming/comments/1ogkkb0/)** · r/iOSProgramming · 2025-10-26 · 🟢<br>Learnings eines Indie-Devs; Updates ohne Umsatzeffekt
- **[Home-screen widgets for iOS games: undervalued UX opportunit](https://www.reddit.com/r/AppBusiness/comments/1odtwb1/)** · r/AppBusiness · 2025-10-23 · ⚪<br>Widgets für Spiele, keine Kommentare
- **[Has anyone tried In-App Events with Success ?](https://www.reddit.com/r/AppStoreOptimization/comments/1oe023s/)** · r/AppStoreOptimization · 2025-10-23 · 🟢<br>In-App Events: oft 0 Impressions
- **[Switched My Icon to Liquid Glass](https://www.reddit.com/r/iOSProgramming/comments/1oa1qdl/)** · r/iOSProgramming · 2025-10-18 · ⚪<br>Icon auf LG umgestellt
- **[Get your app featured in App Store - please share your exper](https://www.reddit.com/r/iOSProgramming/comments/1o4vkvo/)** · r/iOSProgramming · 2025-10-12 · 🟢<br>Featured mit 2,4k Downloads; neue APIs/LG helfen (Meinung)
- **[How to get featured on the App Store? Any experience?](https://www.reddit.com/r/iOSProgramming/comments/1o0eq4e/)** · r/iOSProgramming · 2025-10-07 · 🟢<br>Apple rät: viele Frameworks; Accessibility/Lokalisierung
- **[Are devs actually adopting Liquid Glass?](https://www.reddit.com/r/ios/comments/1nyst81/)** · r/ios · 2025-10-05 · 🟢<br>Adoptieren Devs LG? Große Apps zögern
- **[Keyword Rankings Have Plummeted on Day 4 After iOS App Launc](https://www.reddit.com/r/AppStoreOptimization/comments/1nscae9/)** · r/AppStoreOptimization · 2025-09-28 · 🟢<br>Rankings fallen an Tag 4 nach Launch
- **[curious developer here... how much are you all working on tw](https://www.reddit.com/r/iOSProgramming/comments/1nqf2rr/)** · r/iOSProgramming · 2025-09-25 · 🟢<br>Wie viel LG-Umbau? Meist minimal
- **[Icon Composer icon on App Store looking weird for my app, an](https://www.reddit.com/r/iOSProgramming/comments/1nql3rq/)** · r/iOSProgramming · 2025-09-25 · ⚪<br>Icon-Composer-Icon sieht im Store komisch aus
- **[Liquid glass apps](https://www.reddit.com/r/iosdev/comments/1npmh3y/)** · r/iosdev · 2025-09-24 · 🟢<br>LG-Update von 2 Apps → Featuring am iOS-26-Launchtag
- **[Do you think the new Liquid Glass design will lead to a rise](https://www.reddit.com/r/iOSProgramming/comments/1njnt6h/)** · r/iOSProgramming · 2025-09-17 · 🟢<br>Bringt LG mehr Nachfrage? Mehrheit: Nutzern egal
- **[Anyone else updating to iOS 26 just to know how bad their ow](https://www.reddit.com/r/iOSProgramming/comments/1niof9p/)** · r/iOSProgramming · 2025-09-16 · 🟢<br>iOS-26-Recompile: LG automatisch, Custom bricht
- **[OS2 / Liquid Glass version got approved and officially relea](https://www.reddit.com/r/iOSProgramming/comments/1ndqisj/)** · r/iOSProgramming · 2025-09-10 · ⚪<br>LG-Version veröffentlicht, kaum Diskussion
- **[My app sold almost nothing for 3 years. I ported it to macOS](https://www.reddit.com/r/ProductivityApps/comments/1n1y6c9/)** · r/ProductivityApps · 2025-08-28 · 🟢<br>Mac-Port: Top 100 Paid Productivity in 1 Woche
- **[How much is the recommended time of time between updates?](https://www.reddit.com/r/iOSProgramming/comments/1n00jh2/)** · r/iOSProgramming · 2025-08-25 · 🟢<br>Wie oft updaten? Widersprüchlich
- **[Anyone here added App Store videos to their iOS listings? Cu](https://www.reddit.com/r/iOSProgramming/comments/1mgwe0v/)** · r/iOSProgramming · 2025-08-03 · 🟢<br>App-Preview-Videos: gemischt
- **[getting featured on the App Store](https://www.reddit.com/r/iOSProgramming/comments/1mfudsz/)** · r/iOSProgramming · 2025-08-02 · 🟢<br>Kurze Nominierung → US-Featuring; 5 %/15 % Funnel
- **[Impressions spiked for 6 weeks, and conversion rate plummete](https://www.reddit.com/r/AppStoreOptimization/comments/1mf063c/)** · r/AppStoreOptimization · 2025-08-01 · 🟢<br>6 Wochen Impressions-Spike, CVR ~0,1 %
- **[🚀 Custom Product Pages for organic keywords in the App Store](https://www.reddit.com/r/ASO/comments/1md0jin/)** · r/ASO · 2025-07-30 · 🟢<br>CPPs mit organischen Keywords (News)
- **[(Update) My indie health app, Thryve, was featured by Apple ](https://www.reddit.com/r/iosapps/comments/1lrioi8/)** · r/iosapps · 2025-07-04 · 🏷️<br>Featured → #14 UK, ~400 DL/Tag
- **[learning aso and how apps rank](https://www.reddit.com/r/iOSProgramming/comments/1lpy5j7/)** · r/iOSProgramming · 2025-07-02 · 🟢<br>App mit 20 Reviews schlägt 5k-Review-Apps (Long-Tail)
- **[How critical is app ASO localization on App store & what % r](https://www.reddit.com/r/AppStoreOptimization/comments/1lo84uu/)** · r/AppStoreOptimization · 2025-06-30 · 🏢<br>Lokalisierung: gemischte Erfahrungen
- **[(Follow up) Got featured on the App Store - here’s the stats](https://www.reddit.com/r/iOSProgramming/comments/1ljcqx7/)** · r/iOSProgramming · 2025-06-24 · 🟢<br>Featuring + TikTok: 600→62K Impressions, 25→600 DL/Tag
- **[Apple's extracting keywords from app store screenshots 🚨](https://www.reddit.com/r/AppStoreOptimization/comments/1lav1w2/)** · r/AppStoreOptimization · 2025-06-14 · 🏢<br>OCR-Screenshot-Indexierung: umstritten
- **[(Case Study) 1 ASO iteration = +15 organic installs/day (🇮🇹 ](https://www.reddit.com/r/ASO/comments/1kkwp3w/)** · r/ASO · 2025-05-12 · 🏢<br>IT-Lokalisierung + Long-Tail: +15 Installs/Tag
- **[🧪Product Page Optimization, A/B testing, Download Conversion](https://www.reddit.com/r/indieappdev/comments/1im4eg4/)** · r/indieappdev · 2025-02-10 · 🟢<br>4 PPO-Tests ohne Ergebnis; Traffic-Quelle dominiert
- **[The Apple Watch App Store is a joke. Same old Apps, rarely u](https://www.reddit.com/r/AppleWatch/comments/1i2e34a/)** · r/AppleWatch · 2025-01-16 · 🟢<br>Watch-Store: Auffindbarkeit schlecht, 99 % Social
- **[Why do some apps rank easily with no reviews whereas others ](https://www.reddit.com/r/iOSProgramming/comments/1fiqnsa/)** · r/iOSProgramming · 2024-09-17 · 🟢<br>Charts = Volumen; Ratings pro Land
- **[Behind the Scenes: How CaptionKit Rose to #1 Without a Marke](https://www.reddit.com/r/iOSProgramming/comments/1fcqsk1/)** · r/iOSProgramming · 2024-09-09 · 🏷️<br>CaptionKit #1 ohne Budget: Launch-Traffic + Reviews
- **[ASO Challenge Day 4: First Results and Small ASO Secret](https://www.reddit.com/r/iOSProgramming/comments/1ca78fc/)** · r/iOSProgramming · 2024-04-22 · 🟢<br>Metadaten-Änderung: #228→#66, 30→150 Impressions/Tag

### Ausgeschlossen (14)

- **[I scored 12,000 App Store listings. The same 3 metadata mist](https://www.reddit.com/r/AppStoreOptimization/comments/1wu0hu7/)** · r/AppStoreOptimization · 2026-09-30 · ⛔ 🏢<br>„12.000 Listings bewertet“, Applyra-Vendor
- **[ASO does nothing until you already have traffic. Learned thi](https://www.reddit.com/r/buildinpublic/comments/1vs2tgt/)** · r/buildinpublic · 2026-08-18 · ⛔ 🤖<br>„Thanks Claude“-KI-Callout
- **[Your App Store screenshots are probably doing more selling t](https://www.reddit.com/r/AppBusiness/comments/1ujn7p2/)** · r/AppBusiness · 2026-06-30 · ⛔ 🏷️<br>Screenshot-Post mit Appthetics-Werbung
- **[If your app has fewer than 50 ratings, ASO is the wrong figh](https://www.reddit.com/r/iosdev/comments/1twwppy/)** · r/iosdev · 2026-06-04 · ⛔ 🏢 🏷️<br>Applyra-Gründer, „Spam“-Callout
- **[5 things I learned making App Store screenshots for my Expo ](https://www.reddit.com/r/expo/comments/1tmmcuh/)** · r/expo · 2026-05-24 · ⛔ 🏷️<br>Expo-Screenshots, Werbung/Copy-Callout
- **[how we got a stuck app from ~50 → ~1.4k daily organic instal](https://www.reddit.com/r/iOSAppsMarketing/comments/1tfpcvu/)** · r/iOSAppsMarketing · 2026-05-17 · ⛔ 🏢<br>Agentur-Case 50→1,4k Installs
- **[I tested 20 different first-screenshot styles on the same ap](https://www.reddit.com/r/iOSAppsMarketing/comments/1t0vey2/)** · r/iOSAppsMarketing · 2026-05-01 · ⛔ 🏷️<br>20 Screenshot-Stile, Tool-Werbung
- **[40 installs per day to 130. 34 USD per day to 130. 5 aso cha](https://www.reddit.com/r/SideProject/comments/1sbcsil/)** · r/SideProject · 2026-04-03 · ⛔ 🏷️<br>„40→130 Installs“ mit aso-skills-Werbung, Sockenpuppe
- **[Apple won't tell you how App Store ranking works. Here's wha](https://www.reddit.com/r/SideProject/comments/1rh3mnc/)** · r/SideProject · 2026-02-28 · ⛔ 🤖 🏷️<br>Ranking-„Erkenntnisse“ mit vibecode-Werbung, Bot-Antworten
- **[our app store conversion is 12% and I have no idea if that's](https://www.reddit.com/r/iOSProgramming/comments/1qbp7rz/)** · r/iOSProgramming · 2026-01-13 · ⛔ 🏷️<br>CVR-Frage, Mobbin-Spam-Callout
- **[here's what you need to know about ASO, if you're launching ](https://www.reddit.com/r/iosdev/comments/1qc0xq6/)** · r/iosdev · 2026-01-13 · ⛔ 🏷️<br>ASO-Tipps als Screenshot-Tool-Werbung
- **[Coding is easy, marketing is hell. Here is the data I use to](https://www.reddit.com/r/iOSProgramming/comments/1p16iu5/)** · r/iOSProgramming · 2025-11-19 · ⛔ 🏷️<br>Daten-Post mit AstroASO-Affiliate, als Werbung entlarvt
- **[A/B testing app store creatives: my 7-day sprint that consis](https://www.reddit.com/r/ASO/comments/1mq82pm/)** · r/ASO · 2025-08-14 · ⛔ 🤖 🏢<br>KI-Stil-Post mit Agentur-Angebot
- **[App Store now indexes your text elements form your screensho](https://www.reddit.com/r/swift/comments/1lb3ewa/)** · r/swift · 2025-06-14 · ⛔ 🏷️<br>OCR-Behauptung als PreviewPro-Werbung
