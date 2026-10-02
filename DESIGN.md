---
name: Sprachapp
description: A dark, editorial vocabulary app that turns reading into mastery — no games, no mascots.
---

# Design System: Sprachapp

## Overview

**Creative North Star: "The Night Edition"**

Sprachapp reads like a language magazine that comes out after dark: a quiet, near-black page you read stories on, where the only color that ever appears is a mark of your own progress. Instead of stars, hearts, or animated mascots, the two accent inks — violet and orange — behave like a copy editor's pen: they underline a word directly in the text or mark progress in dedicated tracks to say where it stands, mastered or still active, and then get out of the way again.

The vibe is focused and editorial, not playful. There is no mascot, no confetti, no cartoon avatar, no rainbow of category colors — the explicit anti-reference is Duolingo's bright, gamified look. Density stays reading-first: long-form story text is the centerpiece, and interface chrome (nav, buttons, deck labels) stays quiet and out of the way in a distinct, plainer typeface so it never competes with the content.

**Key Characteristics:**
- Dark, near-black editorial ground; dark is the only mode.
- Exactly two accent colors, each with one fixed, non-decorative meaning: mastered vs. active vocabulary. Two scoped exceptions exist: the Memory Level Indicator (Wortliste and the deck practice card only) and the Audio Playback Highlight (only while something is read aloud); see the Two-Ink Rule.
- Categories outside active/mastered (*Verfügbare Wiederholungen* and *Noch nicht angezeigt*) receive no new accent color; they are rendered in neutral text or an unfilled hairline track.
- The streak is supported, but strictly quiet: a neutral week row of checks and crosses, no flame iconography, no orange highlight.
- Deck difficulty is shown with three bolt icons — the one sanctioned piece of pictorial metadata, always backed by a text or semantics label.
- Serif for anything the learner reads as content; sans for anything that is app chrome.
- No gamified visual language (mascots, confetti, flame badges, saturated multi-color palettes). Difficulty bolts describe content, never reward the learner.

## Colors

A dark editorial ground with exactly two accent inks, each reserved for one meaning: marking a word's learning status.

### Primary (Mastered Ink)
- **Editorial Violet** (`#7B2CBF` / `AppColors.mastered`): marks words the learner has mastered (e.g. Leitner Box 5). The reward is a permanent, elegant mark on the page or track, not an animated badge or popup.

### Secondary (Active Ink)
- **Field Orange** (`#F77F00` / `AppColors.active`): marks words currently activated and in practice — reads as "in progress," in contrast to violet's "done."

### Neutral
- **Night Page** (`#0D0F14` / `AppColors.nightPage`): base background — the darkest layer, where story text and primary reading surfaces sit.
- **Raised Ink** (`#1A1D26` / `AppColors.raisedInk`): elevated surface tone for cards, decks, sheets, and bottom navigation bar — one step lighter than the page so structure reads without requiring heavy outlines.
- **Hairline** (`#2A2F40` / `AppColors.hairline`): fine border strokes, card outlines, and unfilled progress track grooves.
- **Text Primary** (`#F0F2F5` / `AppColors.textPrimary`): high-contrast text for body reading, headlines, primary metrics, and active tab icons.
- **Text Muted** (`#8E95A5` / `AppColors.textMuted`): secondary labels, level indicators, percentage stats, and inactive tab icons.
- **Icon Off** (`#4A5063` / `AppColors.iconOff`): unlit difficulty bolts and inactive chrome elements.
- **Newsprint Sand** (`#C2B49A` / `AppColors.newsKicker`, 8.2:1 on Raised Ink): the category kicker on news cards ("WIRTSCHAFT"), and nothing else. A warm, low-chroma neutral — the tint of newsprint, not an ink. It is the same for all five categories: categories are named, never color-coded (no rainbow of category colors). Never a status, a fill, a border or an icon color.
- **Active Deck Tint** (`#2C2523` / `AppColors.activeTint`): Field Orange at 8% over Raised Ink. Only as the background of an active deck tile; see the Active Deck Rule.

### Feedback (exercise answers only)
- **Quiet Sage** (`#6FB38A` / `AppColors.success`, ~7.6:1 on Night Page): a correct answer in an exercise. **Sage Tint** (`#273435` / `AppColors.successTint`): background of a correct answer chip.
- **Muted Brick** (`#D9726B` / `AppColors.error`, ~5.9:1 on Night Page): a wrong answer, shown as a short flash. **Brick Tint** (`#372A30` / `AppColors.errorTint`): background of a wrongly chosen chip during its flash.
- Both are desaturated so they sit inside the Night Edition palette instead of reading as signal lights.
- **Stand-in Cover Tones**: `#1A1D26`, `#20242F`, `#161922` used as subtle editorial masthead canvas tones when a story has no cover illustration.

### Exceptions (scoped)
- **Memory Level Indicator** (`AppColors.memoryLevel1`–`memoryLevel5`, via `AppColors.memoryLevel(level)`), contrast on Night Page: Level 1 Field Orange (`#F77F00`, 7.3:1), Level 2 Pale Sky (`#7DB2E0`, 8.5:1), Level 3 Mint (`#6FCFB4`, 10.3:1), Level 4 Light Green (`#8BCF7A`, 10.3:1), Level 5 Deep Green (`#2FA65A`, 6.1:1). Unlit dashes stay Hairline.
- **Audio Playback Highlight** (`#2A3A55` / `AppColors.playback`): muted slate blue behind a word or sentence while it is read aloud; `textPrimary` on it reaches 10.2:1. It is deliberately one step lighter than a darker `#1C2A3A`, which would sit at only 1.3:1 against the Night Page and vanish.

### Named Rules

**The Two-Ink Rule.** Only two accent colors exist anywhere in the system — Editorial Violet (`#7B2CBF`) for mastered words and Field Orange (`#F77F00`) for active/in-progress words. Neither is ever used decoratively (no brand-colored buttons, decorative illustrations, or colorful category chips).
- *Verfügbare Wiederholungen* (Due repetitions) and *Noch nicht angezeigt* (New/unseen words) **do not** receive a third or fourth accent color; they are rendered neutrally in text (`textPrimary`/`textMuted`) or represented by the unfilled hairline track.
- **Official exceptions.** Exactly two, each with a fixed scope. Nowhere else may these colors appear.
  1. **Memory Level Indicator** (Wortliste tab and its sheets — Memory Level Legend, Word Details — and the sentence card of the deck practice session, only). Five rounded dashes (`14 × 4pt`, `3pt` gaps, `999pt` radius) above a word show its Leitner box (1–5). The first *n* dashes take the color of level *n*; the rest stay Hairline. Level 1 is Field Orange (a new word is "active"), Level 2 Pale Sky, Level 3 Mint, Level 4 Light Green, Level 5 a saturated Deep Green. The color describes the word's memory strength, never a reward: no animation, no glow, no badge. The level is always also given as text (legend sheet, details sheet) or as a semantics label (`'Erinnerungsstufe 3 von 5: Gut verankert'`); tapping the dashes opens the Memory Level Legend. In practice the card shows the level the word had when the session started; it never changes mid-card, so a right answer is not rewarded with a lit dash. Outside these places, word status keeps the two inks: a Level 5 word is still underlined in Editorial Violet in the reader.
     *Reveal hint (deck practice only).* After "Wort erfahren", the word stands in the gap as the field's hint in Pale Sky at 60% opacity. It is the one use of a level color that is not a level: it says "this is the word, type it", disappears as soon as the learner types, and is always announced ("Das Wort lautet …"). Pale Sky is never used for any other hint.
  2. **Audio Playback Highlight** (wherever audio plays: Wortliste and its sheets, story narration, the solved word in deck practice). While a word or sentence is read aloud, it sits on an `AppColors.playback` background and its speaker icon switches from `CupertinoIcons.speaker_2` (`textMuted`) to `speaker_2_fill` (`textPrimary`). On a standalone word or sentence the mark has a `6pt` radius, a `6pt` horizontal inset and a 150 ms fade (none under reduced motion); in running story text it is a plain span background on the sentence being read, so it follows line breaks. The mark is transient: it shows only while playback runs (not while paused) and disappears when it ends, and only one item plays at a time. A tapped word's Hairline background wins over it. It never marks status, selection or progress.
- **Contrast & Underline Rule**: Editorial Violet text against the `#0D0F14` ground yields low contrast (~2.7:1), violating WCAG legibility for plain body text. Therefore, word statistics and emphasized counts use high-contrast primary text (`#F0F2F5`) paired with colored ink underlines (`TextDecoration.underline` with `decorationThickness: 3` and `decorationColor: AppColors.mastered` or `AppColors.active`).

**The Feedback Rule.** Quiet Sage and Muted Brick are not accents and do not reopen the Two-Ink Rule: they say "this answer was right / wrong" and nothing else. They appear only inside exercise screens (gaps, answer chips, answer cards, the typed field, and the thumbs-up of the Success Feedback Card). Muted Brick is always transient (a flash of about 600ms); Quiet Sage may stay on an answer that has been placed. They never color navigation, cards, progress, word status or buttons outside exercises. Color is never the only cue: every check is announced to the screen reader ("Richtig", "Falsch", "Fast richtig") and wrong answers trigger a light haptic.

**The Neutral Chrome Rule.** Application navigation and interactive controls must never be filled with status inks. Specifically, the central Play button in the bottom navigation bar must **not** be colored violet, because violet exclusively denotes "mastered". The central button must adopt a neutral Raised Ink styling (e.g. `#1A1D26` background, `#2A2F40` hairline border, and `#F0F2F5` primary text icon). The same holds for the "Zum Lernen hinzufügen" action in the word lookup sheet: Night Page fill, Hairline border, `textPrimary` label and icon; once added it reads "Wird gelernt" in `textMuted` and is disabled.

The central practice button follows the same rule inside the notched bar: Raised Ink fill, Hairline edge, `textPrimary` icon. The daily-goal ring around it is neutral progress (see below), never an ink.

**The Reader Mark Rule.** In running story text, words already in the learner's vocabulary carry their status ink as an underline (thickness 2): Field Orange for active, Editorial Violet for mastered. A word the learner has just tapped gets a neutral Hairline background while its lookup sheet is open. Unmarked words stay plain.

**The Neutral Progress Rule.** Progress that is not a word's learning status — the daily goal (hairline track or the ring around the practice button) and the reading position in a story — uses a `textMuted` fill on a Hairline groove. It never borrows Editorial Violet or Field Orange.

**The Understated Streak Rule.** The streak is an orientation aid, shown as a week row inside the Weekly Goal card (Mo–So): a met day is a `textPrimary` check in a hairline circle, a missed day a `textMuted` cross, a future day an empty hairline circle, and today a circle with a `textPrimary` edge and a `textPrimary` w700 day label. No day count, no Field Orange, no flame iconography, no celebratory animation.

**The Active Deck Rule.** A deck the learner is currently practising is "in progress", so it may carry Field Orange: a 1pt Field Orange border, the Active Deck Tint background and a `textPrimary` "Aktiv" label (color is never the only cue). Inactive and former decks stay on Raised Ink with a Hairline border.

**The Difficulty Bolt Rule.** Deck difficulty is shown as three `CupertinoIcons.bolt_fill` at 14pt: lit bolts in `textPrimary`, unlit in `iconOff` (1 = Einsteiger, 2 = Mittelstufe, 3 = Fortgeschritten). Bolts are content metadata, not a reward: they are never animated, never colored with an ink, and always paired with the level name as visible text or as a semantics label. Stories keep the CEFR level as text.

## Typography

**Display/Headline Font:** Source Serif 4 (serif fallback)  
**Body Font (stories/sentences):** Source Serif 4  
**UI/Label Font (chrome/navigation/stats):** Figtree (sans-serif fallback)  

**Character:** An editorial pairing — Source Serif 4 gives headlines, sentences, and story text the weight and dignity of long-form reading, while Figtree keeps interface chrome quiet, modern, and distinct from the content it frames.

### Hierarchy

- **Editorial Section Heading** (Source Serif 4): 24pt, w600, height 1.2, letter-spacing -0.2. Used for section titles ("Aktive Stapel", "Stories").
- **Screen Title** (Source Serif 4): 32pt, w600, height 1.2, letter-spacing -0.2. Used for the Stories library title and the story title in the reader.
- **Story Body** (Source Serif 4): 19pt, w400, height 1.6, letter-spacing 0 (`AppType.storyBody()`). Used for running story text in the reader.
- **Lookup Headword** (Source Serif 4): 28pt, w600. **Lookup Translation** (Source Serif 4): 22pt, w400, height 1.3. Used in the word lookup sheet.
- **Story Card Title** (Source Serif 4): 17pt, w600, height 1.2. Used for story titles on cards.
- **News Card Title** (Source Serif 4): 22pt, w600, at most two lines. **News Kicker** (Figtree): 13pt, w700, letter-spacing 1.2, uppercase, Newsprint Sand.
- **News Subheading** (Source Serif 4): 22pt, w700, height 1.3 — bold and a step above Story Body (19pt); a header for screen readers.
- **Word List Headword** (Source Serif 4): 22pt, w600. **Word List Sentence** (Source Serif 4): 16pt, w400, height 1.45. Used on word rows in the Wortliste.
- **Grammar Rule Body** (Source Serif 4): Story Body for German prose; section headings 22pt w600; examples 19pt w400, height 1.45, with their German translation at 16pt `textMuted`. English forms inside prose and examples are set in *italic w600* `textPrimary` (the citation convention of print grammars) instead of an ink.
- **Story Masthead Stand-in** (Source Serif 4): 52pt, w700, height 1.0, letter-spacing -1.0, rendered with 9% opacity text on neutral cards.
- **Chrome Stat / Large Metric** (Figtree): 22pt, w600 (w700 for counts), height 1.3. Used for headline vocabulary counts.
- **Deck Title** (Figtree): 17pt, w600. Used for deck names in active deck tiles.
- **Button / Standard Chrome** (Figtree): 15pt, w500 / w600. Used for standard buttons ("Mehr entdecken") and secondary stat lines.
- **Week Row Labels** (Figtree): 13pt, w600 `textMuted`; today w700 `textPrimary`.
- **Daily Goal Line** (Figtree): 17pt, w700 tabular count + w500 "von 10 Wörtern".
- **Metadata / Chip Labels** (Figtree): 13pt, w600 (`AppType.meta()`). Used for the language chip ("🇬🇧 Englisch"), deck completion percentages, story meta lines (`A2 · 4 Min · Reisen`, level first so the genre truncates first) and word classes.
- **Counts** use tabular figures so numbers don't shift as they change.
- **Tab Bar Labels** (Figtree): 11pt, w600. Used under navigation icons.

### Named Rules

**The Story-Voice Rule.** Anything the learner reads as content (stories, practice sentences, reading prompts, editorial headings) is set in Source Serif 4. Anything that is app chrome (buttons, navigation, deck titles, word counts, difficulty indicators, progress meters) is set in Figtree. The two typefaces are never swapped or mixed within a role.

## Layout

A spacious, reading-first spatial grammar with disciplined vertical pacing:

- **Horizontal Screen Gutter**: `20pt` standard padding (`EdgeInsets.symmetric(horizontal: 20)`).
- **Vertical Spacing Rhythm**:
  - Top safe area offset: `8pt`.
  - Spacing after header row: `28pt`.
  - Major section separation: `44pt` between dashboard modules.
  - Section title to content gap: `14pt` (decks) / `10pt` (carousel).
  - Inter-item spacing: `12pt` between vertical deck tiles and horizontal story cards.
  - Bottom scroll padding: `32pt` above the navigation bar.
- **Bottom Navigation Bar**: a `BottomAppBar` with `CircularNotchedRectangle` (notch margin `6pt`), fixed height `64pt` (excluding the safe-area inset), Raised Ink, zero elevation. The bar's edge is the tonal step; no hairline, since it can't follow the notch. Tabs: Home, Stories, [Lernen], Wortliste, Inhalte. The practice button is a `FloatingActionButton` (`centerDocked`, `56pt`) inside a `72pt` daily-goal ring, so it rises half above the bar; the label "Lernen" sits in the bar slot beneath it.
- **Home Header**: language chip ("🇬🇧 Englisch", hairline pill) left; Profil and Einstellungen as `44pt` icon buttons right. The flag emoji is the only pictorial color allowed in chrome, because it identifies the language, not a status.
- **Story Carousel**: Fixed container height `200pt`; individual cards measured at `140pt` width × `200pt` height.
- **Deck Tiles**: Full-width cards with `16pt` internal padding. Left: the deck icon inside a `52pt` progress ring (mastered share, Editorial Violet). Right of it: deck title, "[X]% gemeistert" in metadata style, then the difficulty bolts; an "Aktiv" label trails active decks.
- **Weekly Goal Card**: Raised Ink card, `16pt` padding. Week row (7 equal columns, `30pt` day circles), hairline rule, then "4 von 10 Wörtern" with a `44pt` gear button that opens the daily-goal sheet.
- **Content Dashboard** ("Inhalte" tab): screen title "Inhalte" → `28pt` → a two-column grid of category cards (`12pt` gaps), nothing else: Texte ("5 Texte"), Hören ("6 Übungen"), Grammatik ("7 Übungen"), Grammatikregeln ("9 Regeln"). Decks are not part of this tab; they live on Home ("Aktive Stapel", "Mehr ansehen") and in the deck library. Category card: Raised Ink, 1pt Hairline, `12pt` radius, `16pt` padding, at least `132pt` tall; 28pt icon top left, title (Figtree 17 w600) and a metadata line ("4 Texte") at the bottom. Categories that don't exist yet read "Bald verfügbar" in `textMuted`, with the icon in `iconOff`, and are not tappable.
- **Deck Library**: pushed from "Mehr ansehen" on Home, with a back bar. Screen title "Stapel" → count line → "Aktiv" section → "Weitere Stapel" section, tiles `12pt` apart.
- **Text Library**: back bar → screen title "Texte" → section "Aus deinen Stories" (exercise texts built from stories the learner has opened; omitted when empty) → sections by level, each a story-card carousel. Tapping a card opens the exercise choice sheet.
- **Exercise Choice Sheet**: standard sheet; text title (Source Serif 4 24pt) and meta line, then one option row per mode (Figtree 17 w600 title, metadata description with the gap count, chevron), Hairline separators, `56pt` min height. A mode without gaps is disabled.
- **Text Exercise**: back bar with a "x von y" progress count → the text in Story Body style. A gap shows its base word in `textMuted` over a Hairline underline; the active gap's underline is `textPrimary`. Verb mode: the gap is an inline text field sized to the longer of base word and answer. Choice mode: no keyboard; a Raised Ink chip panel with a Hairline top edge sits above the toolbar. Answer chips: Night Page fill, Hairline border, `999pt` radius, Figtree 15 w600, `44pt` min height; wrong → Brick Tint + Muted Brick border for 600ms; right → Sage Tint + Quiet Sage border, the chip flies into the gap (skipped when the OS asks for reduced motion) and is greyed out (`iconOff` label, no fill) after 1s. A placed answer reads in Quiet Sage, w600, and can't be edited. Once every gap is solved, the Success Feedback Card closes the text ("Alle 6 Lücken gelöst", "Text abgeschlossen", "Zurück zu den Texten").
- **Success Feedback Card** (`SuccessFeedbackCard`, every exercise): Raised Ink, Hairline, `12pt` radius, `20pt` padding; a `48pt` Sage Tint disc with `CupertinoIcons.hand_thumbsup_fill` (24pt, Quiet Sage), then a title (Figtree 17 w600) over an optional metadata subtitle, then an optional explanation (Source Serif 4 17pt w400, height 1.45, English forms in italic w600), then one outline button. No illustration, mascot or confetti.
- **Reading Toolbar** (reader and text exercise): Raised Ink bar with a Hairline top edge, `56pt` tall plus the safe area. It holds the "Übersetzen" toggle (`CupertinoIcons.textformat_abc` + label, `44pt` min height): off = `textMuted`; on = `textPrimary` on a Hairline-filled pill. The pill takes at most 55% of the bar; at large Dynamic Type its label ellipsizes (the semantics label stays whole) instead of pushing the bar off screen. While translation mode is on, the toolbar shows "Tippe auf einen Satz, um ihn zu übersetzen".
- **Translation Mode**: sentences replace words as tap targets. The tapped sentence gets a Hairline background while its sheet is open; status underlines stay visible. **Sentence Translation Sheet**: "Satz" label, the original sentence (Source Serif 4 20pt w400), hairline rule, "Deutsch" label, the translation (Source Serif 4 20pt w400). In exercises, unsolved gaps appear as "…" in the original so the sheet never gives the answer away.
- **Deck Details**: icon ring + level name and bolts → screen title → description (Source Serif 4, 17pt w400, `textMuted`) → progress legend ("53 von 532 neuen Wörtern" with an orange-underlined count, "30 Wörter gelernt" with a violet-underlined count) over an `8pt` track (violet mastered, orange seen-not-mastered, hairline rest) → "Stapel lernen" toggle row → primary button "Lerne mit diesem Stapel" (opens a practice session) → expandable "Deine letzten 5 gesehenen Wörter" → `44pt` → "Mehr davon" section with the Stapel-Revue card, whose "Stapel nochmals durchsehen" opens the same session as early practice.
- **Deck Practice** (`DeckPracticeScreen`, a full-screen route without edge swipe; leaving is explicit):
  - *Session bar*: `44pt` Home button (`CupertinoIcons.house`, "Session beenden", ends the session without a prompt) → centre: how many words are left, "Noch 4 Wörter" ("Noch 1 Wort", at the end "Alle Wörter geübt"; metadata, tabular; read as "Noch 4 von 5 Wörtern") over the Session Track → `44pt` menu (`ellipsis_vertical`, "Mehr"), which opens a `CupertinoActionSheet` titled with the headword: "Wort deaktivieren" / "Wort wieder aktivieren", "Zu Favoriten hinzufügen" / "Aus Favoriten entfernen", "Abbrechen". Action labels in Figtree 17 `textPrimary`; each choice is confirmed by a snack bar.
  - *Session Track* (`SessionTrack`, Neutral Progress Rule): one `3pt` pill segment per word of the session, `3pt` apart, spanning the bar between the two buttons; a solved word's segment is `textMuted`, a word still to do is Hairline, so the words left can be counted off the bar. Sessions longer than 12 words fall back to one `HairlineTrack`.
  - *Sentence card*: Raised Ink, Hairline, `12pt` radius, `20pt` sides. The Memory Level Indicator in a `44pt` tap row (opens the legend) → `8pt` → the English sentence in Source Serif 4 26pt w400, height 1.5, with the word as an inline field: sized to the answer, text and cursor starting at the left like running text, a 2pt underline (`textMuted`, `textPrimary` while focused) → `4pt` → right under the sentence, the grammar hint: the word class and form ("Substantiv, Plural", "Verb, Vergangenheit"; Figtree 15 w600 `textMuted`) with `CupertinoIcons.info_circle` (17pt), a `44pt` tap row, read as "Substantiv, Plural, Grammatik-Hinweis". It opens the Form Info Sheet at any time.
  - *Form Info Sheet* (`FormInfoSheet`, standard sheet): "Grammatik" (metadata) → the word class and form (Source Serif 4 24pt, a header) → `12pt` → what that form is and how it is built (Source Serif 4 17pt w400, height 1.45), with examples outside the practice vocabulary ("book → books"). It never names the answer. Once the word is solved or revealed it adds the outline button "Wort-Details ansehen", which closes it and opens the Word Details Sheet.
  - *Translation card* (`12pt` below): Raised Ink, Hairline, `12pt` radius. Header (`56pt` button, exposed as expandable): the German translation of the word (Source Serif 4 20pt w600) and `chevron_up` / `chevron_down` (`textMuted`). Body: Hairline rule, then the whole German sentence (Source Serif 4 18pt w400 `textMuted`, height 1.45). Folding (200 ms, none under reduced motion) is kept for the rest of the session.
  - *Answer toolbar*: Raised Ink with a Hairline top edge; it sits on the bottom edge (above the home indicator) and, while the keyboard is open, directly above it (`MediaQuery.viewInsetsOf(context).bottom`; the screen doesn't resize). Left: "Aussprechen" (`speaker_2`, `44pt`): `iconOff` and disabled until the word is solved or revealed, then `textPrimary`; while it plays, `speaker_2_fill` and the solved word sits on the Audio Playback Highlight. Middle: a `textMuted` 13pt hint ("Fast richtig – prüf die Schreibweise.", "Tippe das Wort ab, um weiterzumachen."), a live region that takes all free space, so the action button always sits flush right. Right: a `44pt` pill (at most 60% of the bar; its label wraps at large Dynamic Type) — "Wort erfahren" (Hairline outline, `textPrimary`; disabled in `iconOff` once used), or after solving "Weiter" with `checkmark_alt` (`textPrimary` fill, Night Page label, the Primary button's grammar).
  - *Answers* (PRODUCT.md): Return checks the field. Exact (case-insensitive) → the word replaces the field in Quiet Sage w600, the keyboard closes, "Richtig" is announced. One edit off (four letters or more) → "Fast richtig", the input stays, no error. Anything else → the field clears, the attempt flashes as the hint in Muted Brick at 75% on a Brick Tint fill with a Muted Brick underline for 600 ms, light haptic, "Falsch" announced; it counts as an error. "Wort erfahren" counts as an error too. A card with any error sends the word back to box 1; a clean card moves it up one box, except in the Stapel-Revue (early practice), where it keeps its box.
  - *End*: after the last "Weiter" the cards and the toolbar give way to the Success Feedback Card ("5 Wörter geübt", "4 auf Anhieb richtig · 1 zurück auf Stufe 1", the box rule of the mode, "Zurück zum Stapel"); the session bar reads "Alle Wörter geübt" over a fully `textMuted` track.
- **Home order**: header → `28pt` → Weekly Goal card → `28pt` → vocabulary overview (due count, segmented track, three-row ledger with hairline separators) → `44pt` → sections. "Aktive Stapel" lists only active decks (at most three), never inactive ones, even started ones; those live in the deck library ("Mehr ansehen"). With no active deck it reads "Noch kein Stapel aktiv. Unter „Mehr ansehen“ findest du alle Stapel." in `textMuted`.
- **Stories Library**: screen title → `28pt` → "Weiterlesen" tile (deck-tile geometry; its "40 % gelesen" label takes at most 60% of the row and wraps at large Dynamic Type) → `44pt` → "Nachrichten" → one carousel per topic, `44pt` apart, each headed by a section heading with a story count in metadata style.
- **Nachrichten** (Stories tab): section heading "Nachrichten" → `6pt` → the subheading "Wöchentlich aktualisierte Nachrichten zu deinen Lieblingsthemen zusammengefasst." (metadata, full width) → `14pt` → the news carousel: a `PageView` with `viewportFraction: 0.9` and `padEnds: false`; each page carries a `20pt` left gutter, so the focused card's left edge sits exactly on the screen gutter, the cards are `20pt` apart and the next one peeks in from the right. It pages one desk at a time and never ends: no item count, the page index wraps with modulo, and it starts on a far multiple of the article count so the learner can swipe back from the first desk too. Five cards, one per desk: Politik, Wirtschaft, Technologie, Medizin, Unterhaltung.
- **News Card**: `340pt` tall, `12pt` radius, 1pt Hairline edge drawn over the content. Top 60%: the article image (`BoxFit.cover`), or until artwork exists the type cover (the category as a 96pt serif masthead at 9% opacity on a neutral tone). A Hairline rule. Bottom 40% on Raised Ink, `16pt` padding: the title (News Card Title), `8pt`, the kicker in Newsprint Sand right under it, `4pt`, and under that the level and reading time ("B1 · 2 Min", metadata). The title shrinks first at large Dynamic Type; the card keeps its height. One button, read as "Wirtschaft in 100 Sekunden. Nachrichten, Wirtschaft, 2 Minuten Lesezeit, Niveau B1".
- **Reader**: `20pt` gutter, text measure capped at `600pt`, `20pt` between paragraphs. Meta line, screen title, then the story body. News open in the same reader (word lookup, translation mode and narration work unchanged); their meta line names the category ("A2 · 2 Min · Politik") and each paragraph is led by its subheading (News Subheading, `8pt` above except on the first, `8pt` below). Subheadings are not tap targets and narration reads only the paragraphs.
- **Narration Panel** (reader): "Vorlesen" in the reading toolbar, left of "Übersetzen" — an icon-only `44pt` circle with a Hairline edge; off: `speaker_2` in `textMuted`, on: `speaker_2_fill` in `textPrimary` on a Hairline fill, exposed as a toggle. Turning it on docks the panel between the text and the toolbar and starts playback; turning it off stops and rewinds. Panel: Raised Ink with a Hairline top edge. A centred row: "15 Sekunden zurück" (`gobackward_15`, 28pt, `48pt` target) → `28pt` → play/pause (`56pt` `textPrimary` disc with a Night Page `play_fill`/`pause_fill` glyph, the panel's one filled control, like the Primary button) → `28pt` → "15 Sekunden vor" (`goforward_15`). Below, a `44pt` tall slider on the Neutral Progress Rule (`3pt` track, `textMuted` fill on Hairline, `7pt` `textPrimary` thumb, no elevation, no overlay), then elapsed and total time (`m:ss`, metadata style, tabular) flush with the track ends. The slider reads "0:12 von 0:44" to screen readers. While it plays, the sentence being read carries the Audio Playback Highlight.
- **Grammatikregeln** (from the "Grammatikregeln" category card): back bar → screen title → `4pt` → metadata line ("9 Regeln · erklärt auf Deutsch") → `20pt` → level filter → `8pt` → rule rows. Level filter: `CupertinoSlidingSegmentedControl` with "Anfänger", "Mittleres Niveau", "Fortgeschrittene"; Raised Ink groove, `2pt` padding, Hairline thumb, `44pt` segments, Figtree 13 w600 labels (`textPrimary` selected, `textMuted` otherwise), text scaling clamped to 1.3× like the tab labels. Rule row: a Chevron Row.
- **Segmented Tabs** (`SegmentedTabs`, the level filter and "Meine Übungen" / "Fertig"): `CupertinoSlidingSegmentedControl` with a Raised Ink groove, `2pt` padding, Hairline thumb, `44pt` segments, Figtree 13 w600 labels (`textPrimary` selected, `textMuted` otherwise), text scaling clamped to 1.3×.
- **Chevron Row** (`ChevronRow`, rule and exercise lists): `72pt` min height, title (Figtree 17 w600) → summary (Figtree 15 `textMuted`) → optional metadata line (`6pt` above, "Zeitformen · Level 2"); `textMuted` chevron on the right, Hairline rule below. The whole row is one button.
- **Practice Library** ("Hören", "Grammatik"; pushed from their category cards): back bar → screen title → `4pt` → metadata line ("6 Übungen · 1 fertig") → `20pt` → Segmented Tabs "Meine Übungen" / "Fertig" → `8pt` → Chevron Rows. Solving an exercise moves it to "Fertig", where it can be done again. Empty shelves read, in `textMuted`, "Noch keine Übung abgeschlossen." or "Alles erledigt. Unter „Fertig“ kannst du jede Übung wiederholen."
- **Choice Exercise** (Hören, Grammatik): back bar with the metadata line trailing → category (metadata) → title (Source Serif 4 28pt) → instruction (Figtree 13 `textMuted`: "Hör zu und wähle die Antwort, die du hörst." / "Wähle die Form, die in die Lücke passt.") → `28pt` → Hören: a clip player (Raised Ink card, Hairline, `12pt` radius: a `72pt` play/pause disc centred over the playback track, "0:00" and "0:02") → `28pt` → the question (Source Serif 4 22pt); Grammatik: the sentence (Source Serif 4 24pt w400, height 1.5) with its gap as ten non-breaking spaces underlined 2pt in `textMuted`, read as "Lücke"; once solved the answer stands in the gap in Quiet Sage w600 → `24pt` → answer cards, `12pt` apart: Raised Ink, 1pt Hairline, `12pt` radius, `56pt` min height, Figtree 17 w600. Wrong: Brick Tint fill and Muted Brick edge for 600ms, light haptic, "Falsch" announced. Right: Sage Tint fill, Quiet Sage edge and label and a `checkmark_alt` (22pt, Quiet Sage) that stay; "Richtig" announced; the other cards retire (`textMuted` label, disabled). The Success Feedback Card then slides up from the bottom edge (300 ms ease-out, none under reduced motion) below the scrolling content, at most half the screen tall (it scrolls inside at large text), and the list scrolls to its end so the confirmed answer stays visible. Title "Richtig", Hören adds "Zu hören war: „…“", the explanation of the rule, and "Nächste Übung" (the next open exercise of the library) or "Zurück zur Übersicht".
- **Playback Controls** (`PlayPauseButton`, `PlaybackTrack`; Narration Panel and clip player): the play/pause disc is `textPrimary` with a Night Page glyph, the one filled control of a player; the track is a `44pt` tall slider on the Neutral Progress Rule with `m:ss` times flush with its ends.
- **Grammar Rule Detail**: a reader page on the Night Page (`20pt` gutter, `600pt` measure): back bar → meta line ("Anfänger · 2 Min") → screen title → summary (Source Serif 4 17pt `textMuted`) → sections `36pt` apart. Section: heading → paragraphs (`12pt`) → "Beispiele" label → examples (`12pt` apart), each hung on a 2pt Hairline rule at the left with `14pt` indent → "Typischer Fehler" card (Raised Ink, Hairline, `12pt` radius, `16pt` padding): "Nicht" label + the wrong sentence struck through in `textMuted`, "Sondern" label + the right sentence. The labels carry the meaning; Muted Brick and Quiet Sage stay inside exercises. Paragraphs, examples and the card are separate screen reader nodes.
- **Wortliste** (tab): screen title "Wortliste" → `4pt` → metadata line ("10 Wörter · 2 in der Playlist") → `20pt` → search row → `16pt` → word rows, back to back, `32pt` bottom padding. Title and search row stay pinned; only the cards scroll (drag dismisses the keyboard). Search row: `CupertinoSearchTextField` (Raised Ink, 1pt Hairline, `12pt` radius, Figtree 16, `textMuted` placeholder "Wörter suchen" and icons) and, `12pt` to its right, a `48 × 48pt` square playlist button (same chrome, `CupertinoIcons.music_note_list` in `textPrimary`). Search matches headword and German translation; no match reads "Keine Wörter für „…“" in `textMuted`. Words are ordered most recently seen first.
- **Word Row**: no card — the row sits directly on the Night Page, without border or fill, and is closed by a 1pt Hairline rule that runs from the text's left edge to the `20pt` gutter on the right. The list is padded by the gutter minus the playback inset, so text inside the playback mark lines up with the screen gutter; `14pt` between the metadata line and the rule. Left column, top to bottom: the Memory Level Indicator in a `44pt` tap row → headword (Source Serif 4, 22pt w600) with a speaker icon (`44pt` tap row) → example sentence (Source Serif 4, 16pt w400, height 1.45, `44pt` minimum) → `6pt` → metadata line in `AppType.meta()` ("Zuletzt gesehen: vor 2 Tagen · Wiederholt: 5 Mal", "·" as in every meta line). Headword and sentence are separate tap targets that start playback. Right of it, stacked: three `44pt` toggles — "Deaktiviert" (document with an X), "In der Playlist" (`music_note`), "Favorit" (`heart`). Off: `textMuted` icon; on: `textPrimary` icon (filled glyph where one exists) on a `34pt` Hairline disc, the same grammar as the "Übersetzen" toggle — never an ink, never a red heart. Each change is confirmed by a snack bar ("Wort deaktiviert", "Zur Playlist hinzugefügt", …) and exposed as a toggled state to screen readers. A deactivated word dims its left column to 45% opacity and leads its metadata with "Deaktiviert" (color is never the only cue). Far right, vertically centred: a `44pt` chevron (`textMuted`) that opens the Word Details Sheet.
- **Snack Bar**: floating, Raised Ink with a 1pt Hairline edge, `12pt` radius, zero elevation, Figtree 15 `textPrimary`, 2 seconds. Only for confirming a quiet action; never for errors in exercises.
- **Memory Level Legend Sheet**: standard sheet. Title "Erinnerungsstufen" (Source Serif 4 24pt) → one `textMuted` line on how levels move (a right answer +1, an error back to 1) → five rows from Level 1 to 5 with Hairline separators, `56pt` min height: indicator, then title (Figtree 15 w600) and the derived interval in metadata style ("Nächste Wiederholung nach 14 Tagen"; Level 5 adds "Gemeistert"). The tapped word's row has a w700 title and a `textPrimary` "Dieses Wort" line. Level titles: Neues Wort · Wird vertraut · Gut verankert · Sicher im Gedächtnis · Maximales Erinnerungsvermögen.
- **Word Details Sheet**: standard sheet. Indicator + level title (metadata) → headword (Source Serif 4 28pt, with speaker and playback highlight) → word class (metadata) → hairline rule → "Deutsch" label + translation (Source Serif 4 22pt w400) → ledger (Hairline separators, `44pt` rows, `textMuted` label left, Figtree w600 tabular value right): Zuletzt gesehen, Wiederholt, Zeit zwischen Wiederholungen (derived from the Leitner box, never stored) → "Beispielsatz" label + sentence (Source Serif 4 20pt, tappable for playback) → "Deutsch" label + translation (20pt) → "Notizen" label + a multiline field (Night Page fill, Hairline border, `textMuted` when focused, `12pt` radius, Figtree 15, placeholder "Füge eigene Notizen hinzu …"). The sheet lifts above the keyboard.
- **Word Lookup Sheet**: modal bottom sheet on Raised Ink with a 1pt Hairline edge, `12pt` top radius, zero elevation, Night Page scrim at 70%. `20pt` gutter. Headword + word class, hairline rule, "Deutsch" label + translation, then one full-width action button (`52pt` min height).
- **Progress Track Metrics**:
  - Segmented vocabulary track: height `8pt`, rounded pill shape (`Radius.circular(999)`).
  - Neutral progress track (daily goal, reading position): height `3pt`, rounded pill shape.
  - **Progress Ring** (`ProgressRing`): `3pt` stroke with round caps on a Hairline circle, starting at 12 o'clock and running clockwise. `52pt` around deck icons (Editorial Violet = mastered share), `72pt` around the practice button (`textMuted` = daily goal).

## Elevation & Depth

Depth is purely tonal, not shadow-driven: surfaces separate by stepping from Night Page (`#0D0F14`) to Raised Ink (`#1A1D26`), outlined with Hairline (`#2A2F40`), rather than by drop shadows or glows. This maintains an intentional, print-like sensibility.

### Named Rules

**The Flat Ground Rule.** No drop shadows or glow effects are used to indicate elevation. The tonal step from Night Page to Raised Ink, supported by a 1pt Hairline border, is the sole depth cue.

## Shapes

- **Cards & Content Tiles**: Corner radius `12pt` (`BorderRadius.circular(12)`). Used on Deck Tiles and Story Cards.
- **Pills & Chips**: Fully rounded pill radius `999pt` (`BorderRadius.circular(999)`). Used on level chips, answer chips, the translation toggle, and progress tracks.
- **Central Action Button**: `FloatingActionButton` with `CircleBorder` (1pt Hairline side), `56 × 56 pt`, inside a `72pt` progress ring; the notch follows the ring.
- **Buttons**: `12pt` radius, `52pt` minimum height, full width. *Primary* ("Lerne mit diesem Stapel"): `textPrimary` fill with a Night Page label, the only filled button. *Outline* ("Zum Lernen hinzufügen", "Stapel nochmals durchsehen"): Night Page fill, Hairline border, `textPrimary` label. Neither ever uses a status ink.
- **Toggle**: `CupertinoSwitch` with a `textMuted` track when on, a Hairline track when off and a `textPrimary` thumb; never an ink.
- **Border Strokes**: `1pt` solid hairline borders (`AppColors.hairline` = `#2A2F40`) on elevated containers and chips.

## Accessibility

- **Semantics Labels on Custom Controls**: Every custom interactive component (`DeckTile`, `StoryCard`, `_TabItem`, `PracticeButton`) wraps its visual tree in `MergeSemantics` and provides a descriptive `Semantics(label: ...)` string (e.g. `'Reisen & Unterwegs, 42 Prozent gemeistert, Schwierigkeit Einsteiger, aktiv'`, `'Lernen, Tagesziel 4 von 10 Wörtern'`), explicitly exposing `isButton: true` and `hasTapAction: true`.
- **Minimum Tap Targets**: All tappable elements strictly satisfy the `44 × 44 pt` minimum dimension required by platform accessibility guidelines (`iOSTapTargetGuideline`).
- **Dynamic Type & Text Scaling**: Dashboard layouts must survive at least 2.0× text scaling (`textScaleFactor = 2.0`) without clipped text or render-overflow exceptions. Bottom tab bar labels clamp text scaling to a maximum of 1.3× to preserve core navigation reachability.
- **Heading Semantics**: Section titles explicitly declare `Semantics(header: true)` for assistive screen-reader navigation.

## Do's and Don'ts

### Do:
- **Do** treat Editorial Violet (`#7B2CBF`) and Field Orange (`#F77F00`) strictly as status inks denoting mastered vs. active vocabulary.
- **Do** pair the Memory Level Indicator with its level as text or a semantics label, and keep its colors inside the Wortliste and the deck practice card.
- **Do** format word counts with high-contrast text and colored ink underlines to ensure contrast compliance.
- **Do** present the streak as a neutral week row without flame icons or orange highlights.
- **Do** style the central practice button in neutral Raised Ink chrome with a hairline border, docked in the notch.
- **Do** show deck difficulty with three bolts, always paired with the level name.
- **Do** set editorial content in Source Serif 4 and app chrome in Figtree; keep roles strictly segregated.
- **Do** ensure all tappable areas meet or exceed `44 × 44 pt` and carry complete VoiceOver/TalkBack semantics.
- **Do** build depth exclusively through the Night Page → Raised Ink tonal step and hairline borders.

### Don't:
- **Don't** assign new accent colors to "Verfügbare Wiederholungen" or "Noch nicht angezeigt"; keep them neutral.
- **Don't** color the central play button in violet or orange.
- **Don't** use playful game-app iconography such as flame icons, mascots, confetti, or star badges. Bolts are allowed only as the deck difficulty indicator.
- **Don't** use drop shadows, glows, or glossy skeuomorphic gradients.
- **Don't** introduce a third accent color; the Two-Ink Rule is closed. The feedback colors are not accents and stay inside exercises (see the Feedback Rule); the memory level and playback colors are the Two-Ink Rule's only exceptions — memory levels stay inside the Wortliste and the deck practice card, the playback highlight appears only while audio plays.
- **Don't** highlight grammar examples with a status ink; English forms are set in italic w600 instead.
- **Don't** use memory level colors as a word's status anywhere else (reader underlines, deck rings, home tracks keep Editorial Violet and Field Orange), and don't leave the playback highlight on after playback ends.
- **Don't** let a wrong answer stay red; Muted Brick only flashes.
- **Don't** ship a light theme; dark is the only mode.
