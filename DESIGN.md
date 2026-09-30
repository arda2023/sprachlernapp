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
- Exactly two accent colors, each with one fixed, non-decorative meaning: mastered vs. active vocabulary.
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
- **Active Deck Tint** (`#2C2523` / `AppColors.activeTint`): Field Orange at 8% over Raised Ink. Only as the background of an active deck tile; see the Active Deck Rule.
- **Stand-in Cover Tones**: `#1A1D26`, `#20242F`, `#161922` used as subtle editorial masthead canvas tones when a story has no cover illustration.

### Named Rules

**The Two-Ink Rule.** Only two accent colors exist anywhere in the system — Editorial Violet (`#7B2CBF`) for mastered words and Field Orange (`#F77F00`) for active/in-progress words. Neither is ever used decoratively (no brand-colored buttons, decorative illustrations, or colorful category chips).
- *Verfügbare Wiederholungen* (Due repetitions) and *Noch nicht angezeigt* (New/unseen words) **do not** receive a third or fourth accent color; they are rendered neutrally in text (`textPrimary`/`textMuted`) or represented by the unfilled hairline track.
- **Contrast & Underline Rule**: Editorial Violet text against the `#0D0F14` ground yields low contrast (~2.7:1), violating WCAG legibility for plain body text. Therefore, word statistics and emphasized counts use high-contrast primary text (`#F0F2F5`) paired with colored ink underlines (`TextDecoration.underline` with `decorationThickness: 3` and `decorationColor: AppColors.mastered` or `AppColors.active`).

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
- **Deck Library**: screen title "Stapel" → count line → "Aktiv" section → "Weitere Stapel" section, tiles `12pt` apart. It is the "Inhalte" tab and the target of "Mehr ansehen".
- **Deck Details**: icon ring + level name and bolts → screen title → description (Source Serif 4, 17pt w400, `textMuted`) → progress legend ("53 von 532 neuen Wörtern" with an orange-underlined count, "30 Wörter gelernt" with a violet-underlined count) over an `8pt` track (violet mastered, orange seen-not-mastered, hairline rest) → "Stapel lernen" toggle row → primary button "Lerne mit diesem Stapel" → expandable "Deine letzten 5 gesehenen Wörter" → `44pt` → "Mehr davon" section with the Stapel-Revue card.
- **Home order**: header → `28pt` → Weekly Goal card → `28pt` → vocabulary overview (due count, segmented track, three-row ledger with hairline separators) → `44pt` → sections.
- **Stories Library**: screen title → `28pt` → "Weiterlesen" tile (deck-tile geometry) → one carousel per topic, `44pt` apart, each headed by a section heading with a story count in metadata style.
- **Reader**: `20pt` gutter, text measure capped at `600pt`, `20pt` between paragraphs. Meta line, screen title, then the story body.
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
- **Pills & Chips**: Fully rounded pill radius `999pt` (`BorderRadius.circular(999)`). Used on level chips, streak badges, difficulty indicators, and progress tracks.
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
- **Don't** introduce a third accent color; the Two-Ink Rule is closed.
- **Don't** ship a light theme; dark is the only mode.
