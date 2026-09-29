<!-- SEED: established with the user before implementation; re-run /impeccable document once there's code to capture the actual tokens and components. -->

---
name: Sprachapp
description: A dark, editorial vocabulary app that turns reading into mastery — no games, no mascots.
---

# Design System: Sprachapp

## Overview

**Creative North Star: "The Night Edition"**

Sprachapp reads like a language magazine that comes out after dark: a quiet, near-black page you read stories on, where the only color that ever appears is a mark of your own progress. Instead of stars, hearts, or streak flames, the two accent inks — violet and orange — behave like a copy editor's pen: they underline a word directly in the text to say where it stands, mastered or still active, and then get out of the way again.

The vibe is focused and editorial, not playful. There is no mascot, no confetti, no cartoon avatar, no rainbow of category colors — the explicit anti-reference is Duolingo's bright, gamified look. Density stays reading-first: long-form story text is the centerpiece, and interface chrome (nav, buttons, deck labels) stays quiet and out of the way in a distinct, plainer typeface so it never competes with the content.

**Key Characteristics:**
- Dark, near-black editorial ground; no light theme.
- Exactly two accent colors, each with one fixed, non-decorative meaning: mastered vs. active vocabulary.
- Serif for anything the learner reads as content; sans for anything that is app chrome.
- No gamified visual language (mascots, confetti, streak iconography, saturated multi-color palettes).

## Colors

A dark editorial ground with exactly two accent inks, each reserved for one meaning: marking a word's learning status.

### Primary
- **Editorial Violet** (#7B2CBF): marks words the learner has mastered. The reward is a permanent, elegant mark on the page itself, not a badge or popup.

### Secondary
- **Field Orange** (#F77F00): marks words currently activated/in practice — reads as "in progress," in contrast to violet's "done."

### Neutral
- **Night Page** (#0D0F14): base background — the darkest layer, where story text and primary reading surfaces sit.
- **Raised Ink** (#1A1D26): elevated surface tone for cards, decks, sheets, and navigation — one step lighter than the page so structure reads without needing borders.
- Text, border, and divider tones: [to be resolved during implementation]

### Named Rules
**The Two-Ink Rule.** Only two accent colors exist anywhere in the system — violet for mastered, orange for active — and neither is ever used decoratively (no brand-colored buttons, icons, or nav highlights). Color is only ever allowed to mean one of the two word states.

## Typography

**Display/Headline Font:** Source Serif 4 (serif fallback)
**Body Font (stories):** Source Serif 4
**UI/Label Font:** Figtree (sans-serif fallback)

**Character:** An editorial pairing — Source Serif 4 gives headlines and story text the weight and legibility of long-form reading, while Figtree keeps interface chrome (buttons, nav, labels, deck names, word-status chips) quiet, modern, and clearly separate from the content it frames.

### Hierarchy
- **Display/Headline** (Source Serif 4): story titles and section headers — carries the magazine feel.
- **Body** (Source Serif 4): story reading text, set for sustained reading rather than scanning.
- **Label/UI** (Figtree): buttons, navigation, deck names, word-status chips, form fields, and every other interface element that isn't content.
- Exact sizes, weights, and line-heights: [to be resolved during implementation]

### Named Rules
**The Story-Voice Rule.** Anything the learner reads as content (stories, sentences, headlines) is set in Source Serif 4; anything that is app chrome is set in Figtree. The two faces are never swapped or mixed within a role.

## Layout

[To be resolved during implementation — no spatial grammar has been established yet.] Directionally: reading-first density on the Story surface (generous line length and vertical rhythm, not a dense tile grid), consistent with the focused, non-gamified brief. Practice decks may run denser since they are task-oriented rather than reading-oriented, but should not adopt a game-board look.

## Elevation & Depth

Depth is tonal, not shadow-driven: surfaces separate by moving from Night Page (#0D0F14) to Raised Ink (#1A1D26) rather than by drop shadows or glow effects — an intentionally flat, print-like sensibility rather than a glossy app-game look.

### Named Rules
**The Flat Ground Rule.** No drop shadows or glow are used to indicate elevation; a tonal step (Night Page → Raised Ink) is the only depth cue.

## Shapes

[To be resolved during implementation — no corner radius or form language has been established yet.]

## Do's and Don'ts

### Do:
- **Do** treat violet (#7B2CBF) and orange (#F77F00) as status inks exclusively — mastered vs. active vocabulary — never as generic brand or decorative color.
- **Do** set story/sentence content in Source Serif 4 and app chrome in Figtree; never mix the two roles.
- **Do** build depth through the Night Page / Raised Ink tonal step, not shadows or glow.
- **Do** keep the reading surface (stories) the visual centerpiece; chrome stays quiet around it.

### Don't:
- **Don't** use bright, saturated, "gamified" color anywhere in the system — the Duolingo look is the named anti-reference.
- **Don't** add mascots, confetti, streak-flame icons, or other playful game-app iconography.
- **Don't** introduce a third accent color; the Two-Ink Rule is closed.
- **Don't** ship a light theme; dark is the only mode.
