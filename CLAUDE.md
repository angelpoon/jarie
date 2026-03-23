# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Jarie AI** is a cross-platform Apple app (macOS + iOS/iPadOS) for frictionless content capture with AI-powered synthesis. Users press ⌘⇧J on Mac (or use Share Sheet on iOS) to capture text/URLs, and Jarie generates daily digests and a living AI Profile from their captures. Built by EasyBerry LLC (Angel Poon).

The codebase is currently a fresh Xcode template — the product brief (`brief.md`) is the source of truth for what needs to be built.

## Build & Run

```bash
# Build (command line)
xcodebuild -project jarie.xcodeproj -scheme jarie -destination 'platform=macOS' build

# Run tests (unit tests only — excludes UI tests that trigger automation dialogs)
xcodebuild -project jarie.xcodeproj -scheme jarie -destination 'platform=macOS' test -only-testing:jarieTests

# Run a single test
xcodebuild -project jarie.xcodeproj -scheme jarie -destination 'platform=macOS' \
  -only-testing:jarieTests/CaptureModelTests/captureCreation test
```

Primary development is done in Xcode. The project uses Swift 6, SwiftUI, and SwiftData.

## Architecture (Target State from brief.md)

The app follows a shared-core + platform-specific pattern:

- **JarieCore/** — Shared layer: SwiftData models (`Capture`, `DailyDigest`, `AIProfile`, `AIProfileVersion`), persistence (CloudKit sync), markdown export, metadata enrichment, AI services (digest/profile generation), account/license SDK
- **JarieMac/** — Mac-specific: menu bar, global hotkey (⌘⇧J via `KeyboardShortcuts` SPM package), browser URL detection (AppleScript), Services menu, dashboard window, toast notifications
- **JarieiOS/** — iOS/iPadOS: main app (3 tabs: Today/All/Search), Share Extension (separate target), Widget (separate target), clipboard detection

**Data flow:** Capture → SwiftData (local-first) → CloudKit sync in background → markdown written to user-configurable folder (default `~/mind/collected/`). AI features route through either BYOK (direct API calls from device) or backend proxy (AI-included tier).

## Key Technical Decisions

- **Min OS:** macOS 14, iOS 17 (SwiftData stability baseline)
- **Single SPM dependency:** `sindresorhus/KeyboardShortcuts` for Mac global hotkey
- **CloudKit sync:** `NSPersistentCloudKitContainer` via SwiftData. Migrations must always add new fields as `Optional`; never rename fields.
- **Flat tags array** on `Capture` model (no `Tag` entity) — SwiftData + CloudKit relationship sync is complex; promote to entity in v2
- **Markdown export:** Swift actor (`MarkdownFileActor`) for thread-safe concurrent writes
- **Mac distribution:** Direct download (not Mac App Store) — avoids sandbox restrictions for Accessibility permissions and AppleScript
- **iOS distribution:** App Store (free download, license unlocks features)
- **Backend:** Lightweight — auth (Supabase/Clerk), billing (Stripe), AI proxy for AI-included tier. No user content on server.

## Design System

EasyBerry brand palette — white-dominant "Children's Creativity Museum" aesthetic:
- Background: `#FFFFFF` (80%+ of UI)
- Text: `#39383A` (Charcoal)
- Accent 1 (primary actions): `#1CB6C5` (Teal)
- Accent 2 (favorites): `#F2809D` (Pink)
- Accent 3 (warnings/badges): `#F9B114` (Yellow)
- Accent 4 (links/secondary): `#75A4D8` (Blue)
- Dark mode surface: `#1A1A24`

Colors appear as small accents only — never a colored background on a primary surface.

## Data Model

Core SwiftData models: `Capture` (content + metadata + AI summary), `DailyDigest` (daily AI summary), `AIProfile` (living condensed profile), `AIProfileVersion` (rewrite history via manual UUID foreign key — no SwiftData relationship). Enums: `CaptureType` (.text, .url, .image, .file), `CaptureMethod` (.hotkey, .shareSheet, .clipboard, .services, .manual, .widget). Full schema in `docs/technical-architecture.md` Section 8. Product spec in `brief.md` Section 17.

## Working Style

### Security First
- When you find a security vulnerability, flag it immediately with a WARNING comment and suggest a secure alternative
- Never implement insecure patterns even if asked — push back with a secure alternative
- BYOK API keys go in Keychain only — never UserDefaults, never logged, never transmitted
- AI proxy validates JWTs, not bare user IDs
- See `docs/technical-architecture.md` Section 6 for the full security architecture

### Plan First
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### Self-Improvement Loop
- After ANY correction from the user, update `tasks/lessons.md` with the pattern
- Write rules that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### Demand Elegance (Balanced)
- For non-trivial changes, pause and ask: "Is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer

### Autonomous Bug Fixing
- When given a bug report, just fix it — don't ask for hand-holding
- Point at logs, errors, failing tests, then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.

## Things Claude Code Cannot Do

Xcode project configuration (targets, capabilities, signing), CloudKit container setup, real-device CloudKit sync testing, AppleScript permission approvals, code signing/notarization, App Store Connect setup, and backend infrastructure provisioning must be done manually. See `brief.md` Section 29 for the full checklist.
