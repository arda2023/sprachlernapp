# AGENTS.md

Guidance for Codex and other agents. Same mandatory rules as `CLAUDE.md`; details live in the files listed below, not here.

## Mandatory Rules

1. **No keys**: Never commit API keys or secrets to the repository or embed them in the app. Pipeline and tools read credentials from local login (ADC) or environment variables.
2. **No direct AI calls from the client**: The client never calls an AI provider directly. Runtime AI only via Supabase Edge Functions that call Vertex AI, for user-generated content (see `PRODUCT.md`).
3. **AI access: Vertex AI only** (project `sprachlernapp-510508`, see `docs/pipeline.md`, `docs/backend.md`).
4. **Derived counters**: The four vocabulary counts (*Verfügbare Wiederholungen*, *Wörter im Aufbau*, *Wörter gemeistert*, *Noch nicht angezeigt*) are always derived from card state and due dates, never stored as columns (`docs/srs.md`).
5. **Source of truth**: Product logic is governed by `PRODUCT.md`, visuals and accessibility by `DESIGN.md`. If code contradicts them, the documentation wins; do not edit the documentation to match a code regression, record the discrepancy and align the code.
6. **Shell**: WENN ein Befehl Shell-spezifisch ist → NIE nur Bash angeben; Windows (PowerShell) und macOS getrennt nennen. Entwicklung läuft auf Windows und macOS.
7. **Verification**: Nie "fertig" ohne gezeigten Output (Test, Analyse, Befehlsausgabe).
8. **Domain purity**: `lib/domain/` has no Flutter imports (`dart:ui`, `package:flutter/...`).

## Where to look

- Product rules: `PRODUCT.md`. Visuals and accessibility: `DESIGN.md`.
- Layers and data flow: `ARCHITECTURE.md`.
- Spaced repetition: `docs/srs.md`. Content schema: `docs/content-schema.md`.
- Backend: `docs/backend.md`. Pipeline: `docs/pipeline.md`. Setup: `docs/setup.md`.
- Status and open points: `NEXTSTEPS.md`.

## Commands

Flutter commands (`flutter pub get`, `flutter analyze`, `flutter test`) are identical on Windows (PowerShell) and macOS (Terminal). More in `CLAUDE.md`.
