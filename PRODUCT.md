# Product

<!-- impeccable:product-schema 1 -->

## Platform

iOS and Android (Flutter). One unified custom design system across both platforms — the brand sets the visual language, not the OS (not Cupertino/Material-adaptive).

## Stack

Flutter (existing scaffold; SDK constraint `^3.13.2`, see `pubspec.yaml`).

## Users

Serious adult self-learners who want to actually acquire a language, not casually drill it. They find gamified, brightly-colored consumer apps (Duolingo named explicitly as the anti-reference) too childish and want something that feels substantive and respects their intelligence.

## Product Purpose

Helps adults build real vocabulary in a target language through two connected loops: reading stories with inline word lookup, and deliberate fill-in-the-blank sentence practice organized into topic decks. Success means a word genuinely moving from unknown, through active practice, to mastered.

## Positioning

Where gamified apps drill isolated vocabulary out of context, this app roots every word in something worth reading first (a story), then trains it deliberately through targeted sentence practice — a reading-led, editorial approach to vocabulary acquisition rather than a game-loop.

## Operating Context

Two core surfaces:

- **Themed practice decks** (e.g. Reisen, Allgemeine Sprache, Medizin): a sentence with a blank; the learner fills it in via keyboard or by choosing from provided word options.
- **Story page**: readable stories on various topics; tapping a word shows its translation inline, with an option to add that word to the learner's practice list.

## Capabilities and Constraints

- Every word carries a visible state used throughout the UI: **activated** (added to practice from a story, not yet mastered) and **mastered** (learned through repeated correct practice). This two-state vocabulary model is the app's defining mechanic — the color system exists to represent it.
- Topic decks and stories span multiple domains (travel, general language, medical, etc.); the domain list is open/extensible.
- Undecided: which target language(s) are taught, whether multiple source/target language pairs are supported, the mastery threshold/algorithm, and whether audio/pronunciation is included.

## Brand Commitments

- Explicit anti-reference: must not resemble Duolingo's playful, saturated, gamified visual style.
- Dark mode as the visual foundation.
- Named typefaces: Figtree (UI/labels), Source Serif 4 (stories/headlines).
- Named colors: near-black background tones (#0D0F14 / #1A1D26); purple #7B2CBF marks mastered words; orange #F77F00 marks activated words.

## Evidence on Hand

None yet — no existing story content, sentence banks, or copy on hand. Any story/sentence content authored before real content exists must be labeled as placeholder/synthetic.

## Product Principles

1. Reading comes first — vocabulary is learned in context, not as an isolated list.
2. Word state (activated → mastered) is always visible and legible; it is the app's core feedback loop.
3. Respect the learner's intelligence: no juvenile gamification, no cartoon mascots or forced streak mechanics.
4. One consistent design language across iOS and Android — the brand, not the OS, sets the visual rules.
5. Calm, editorial density over playful, high-stimulus UI.
