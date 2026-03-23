# Jarie AI — Technical Architecture Document

> **Generated:** 2026-03-16
> **Source of truth:** `brief.md` (product spec) + this document (technical architecture)
> **Audience:** Implementation team (Claude Code + Angel Poon)

---

## Table of Contents

1. [Decision Summary](#1-decision-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Backend Architecture](#3-backend-architecture)
4. [Auth & Account Flow](#4-auth--account-flow)
5. [CloudKit Sync Strategy](#5-cloudkit-sync-strategy)
6. [Security Architecture](#6-security-architecture)
7. [Data Privacy Architecture](#7-data-privacy-architecture)
8. [SwiftData Schema (Final v1)](#8-swiftdata-schema-final-v1)
9. [Shared Core (JarieCore) Module Structure](#9-shared-core-jariecore-module-structure)
10. [Mac-Specific Architecture (JarieMac)](#10-mac-specific-architecture-jariemac)
11. [iOS-Specific Architecture (JarieiOS)](#11-ios-specific-architecture-jarieiOS)
12. [Markdown Export Pipeline](#12-markdown-export-pipeline)
13. [Concurrency Model](#13-concurrency-model)
14. [Error Handling Patterns](#14-error-handling-patterns)
15. [Navigation Architecture](#15-navigation-architecture)
16. [Design Tokens / SwiftUI Theme System](#16-design-tokens--swiftui-theme-system)
17. [Interaction Specs](#17-interaction-specs)
18. [Key Screen Wireframes (ASCII)](#18-key-screen-wireframes-ascii)
19. [Empty States](#19-empty-states)
20. [Onboarding Flow](#20-onboarding-flow)
21. [Accessibility Requirements](#21-accessibility-requirements)
22. [Implementation Priority Order](#22-implementation-priority-order)
23. [Open Decisions](#23-open-decisions)

---

## 1. Decision Summary

All architectural decisions were reviewed by a simulated expert team (CTO/Architect, Senior iOS Engineers, UI/UX Designer) and approved by the founder.

| Decision | Choice | Rationale |
|---|---|---|
| Auth provider | Supabase Auth | Single vendor for auth + DB + edge functions |
| Auth methods | SIWA + email/password | Apple requires SIWA; devs prefer email option |
| iOS license model | Web purchase (no IAP) | Avoids 30% Apple cut; gate non-consumable features |
| Pre-sign-in captures | Yes, migrate on sign-up | Friction-free first experience |
| Free tier | None at launch | YouTube + landing page do the convincing |
| Digest generation | Server-side (ephemeral) | Solves multi-device coordination |
| Digest trigger | On app launch if not generated | Simplest, no background task scheduling |
| BYOK providers | Claude only at launch | Single SDK, single test surface |
| AI token budget | Soft caps, model after launch | 50 captures/day digest, 10 rewrites/month |
| AI retry strategy | 3x exponential backoff, then queue | Silent, non-disruptive |
| AI Profile sharing | v2 | Needs sharing infra, privacy controls |
| v1 capture types | Text + URL only | Image/file deferred; enum has all cases for compat |
| Profile versions | Manual UUID foreign key | Avoids CloudKit relationship sync issues |
| Digest captureIds | Blob (non-queryable) | Display-only, fine for v1 |
| Migration strategy | Lightweight for v1, VersionedSchema at v1.1 | No users to migrate yet |
| BYOK key storage | Keychain (device-local, no sync) | Only correct security posture |
| Hotkey clipboard | Overwrite (no save/restore) | ⌘⇧J IS a copy; intended behavior |
| App blocklist | Ship with defaults | 1Password, Terminal, banking apps |
| Toast multi-monitor | Active app's screen | Where the user is looking |
| Toast full-screen | Yes (floating panel) | Must confirm capture in all contexts |
| Rapid toast behavior | Replace | No stacking, no queue |
| Mac default mode | Menu bar only (no Dock) | "Invisible Until Needed" principle |
| Dashboard layout | Two-pane, detail slides in | Cleaner, matches Apple Mail |
| Share Extension IPC | JSON staging file | No SwiftData in extension (120MB limit) |
| Clipboard detection | `hasStrings` (no prompt) | Avoids jarring iOS 16+ paste banner |
| Widget data source | JSON file via App Group | No SwiftData in widget process |
| iOS tabs | Icon + text labels | Standard iOS, better accessibility |
| Digest location (iOS) | Card in Today tab | Digest is the payoff of Today's captures |
| Markdown cross-device | Originating device only | Prevents iCloud Drive conflicts |
| Typography | SF Pro, standard scale | Dynamic Type support |
| Shadows | Floating elements only | Museum aesthetic stays flat |
| Row separators | Divider lines (Apple Mail) | Native, familiar |
| Delete behavior | Swipe-to-reveal + undo | No modal confirmations |
| Empty states | SF Symbol + text | Middle ground, Phase 7 upgrades |
| Onboarding | Sign-in first, contextual perms | No carousel; product teaches through use |
| Dark mode | #1A1A24 base, adjusted accents | Brand-consistent |
| Offline indicator | Show only if pending > 5 min | Transparent offline, trust signal when needed |
| AI Profile loading | Show last version, swap on update | No spinners |
| AI Profile cold start | Explanation text | No progress bars |

---

## 2. System Architecture Overview

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                                  │
│                                                                     │
│  ┌──────────────────────┐      ┌──────────────────────────────────┐ │
│  │      JarieMac        │      │           JarieiOS               │ │
│  │                      │      │                                  │ │
│  │  • Menu bar UI       │      │  • Main app (3 tabs)             │ │
│  │  • Global hotkey     │      │  • Share Extension (target)      │ │
│  │    ⌘⇧J via           │      │  • Widget (target)               │ │
│  │    KeyboardShortcuts │      │  • Clipboard detection           │ │
│  │  • Browser URL fetch │      │  • App Store distribution        │ │
│  │    (AppleScript)     │      │                                  │ │
│  │  • Dashboard window  │      └──────────────┬───────────────────┘ │
│  │  • Direct download   │                     │                     │
│  └──────────┬───────────┘                     │                     │
│             │                                 │                     │
│             └──────────────┬──────────────────┘                     │
│                            │                                        │
│              ┌─────────────▼──────────────────┐                     │
│              │           JarieCore             │                     │
│              │                                │                     │
│              │  • SwiftData models             │                     │
│              │  • MarkdownFileActor            │                     │
│              │  • AI service clients           │                     │
│              │  • Account / license SDK        │                     │
│              │  • Metadata enrichment          │                     │
│              └──────────┬──────────────────────┘                     │
└─────────────────────────┼───────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
   ┌─────────────┐ ┌────────────┐ ┌─────────────────┐
   │   iCloud /  │ │  Jarie     │ │  Claude API      │
   │  CloudKit   │ │  Backend   │ │  (Anthropic)     │
   │             │ │            │ │                  │
   │  Encrypted  │ │ • Supabase │ │  BYOK: device    │
   │  sync across│ │   Auth     │ │  calls direct    │
   │  devices    │ │ • Stripe   │ │                  │
   │             │ │ • AI proxy │ │  AI-included:    │
   └─────────────┘ │   (CF/Edge)│ │  routed through  │
                   └─────┬──────┘ │  proxy, ephemeral│
                         │        └─────────────────┬┘
                         └──────────────────────────┘
                           JWT-validated forwarding
                           Input discarded post-response
```

### Module Boundaries

| Module | Owns | Does NOT touch |
|---|---|---|
| `JarieCore` | SwiftData schema, AI service protocol, markdown export, license validation logic | Any platform UI, AppKit, UIKit |
| `JarieMac` | Menu bar, hotkey registration, AppleScript, dashboard window | iOS Share Extension APIs |
| `JarieiOS` | UIKit/SwiftUI app shell, Share Extension, Widget, clipboard monitor | AppKit, global hotkeys |
| `Backend` | Auth state, subscription/tier, AI proxy routing | User content (captures, digests, profiles) |

### Dependency Graph

```
JarieMac ──────► JarieCore ◄────── JarieiOS
    │                │                  │
    │                ▼                  │
    │         SwiftData + CloudKit      │
    │                                   │
    ▼                                   ▼
KeyboardShortcuts             (no additional SPM deps)
(sindresorhus — only SPM dep)
```

**Single SPM dependency rule:** `KeyboardShortcuts` is the only allowed external SPM package. All other functionality is built on Apple frameworks or implemented in-house. This minimizes supply-chain risk and simplifies notarization.

---

## 3. Backend Architecture

The backend is intentionally thin. It handles identity, billing, and AI proxying — nothing else. No user content ever persists server-side.

### Component Breakdown

```
                    ┌────────────────────────────────────┐
                    │          Jarie Backend              │
                    │                                    │
  Client JWT ──────►│  ┌──────────────────────────────┐  │
                    │  │     Supabase Auth             │  │
                    │  │  • SIWA + email/password      │  │
                    │  │  • Issues short-lived JWTs    │  │
                    │  │    (15-min TTL)               │  │
                    │  └──────────────┬───────────────┘  │
                    │                 │                   │
                    │  ┌──────────────▼───────────────┐  │
                    │  │    Supabase Postgres          │  │
                    │  │  Stores ONLY:                 │  │
                    │  │  • user_id                    │  │
                    │  │  • email                      │  │
                    │  │  • tier (byok | ai_included)  │  │
                    │  │  • subscription_status        │  │
                    │  │  • license_key (hashed)       │  │
                    │  │  • server_validation_ts       │  │
                    │  │    (HMAC-signed)              │  │
                    │  └──────────────┬───────────────┘  │
                    │                 │                   │
                    │  ┌──────────────▼───────────────┐  │
                    │  │      Stripe Billing           │  │
                    │  │  BYOK:        $24.99/yr       │  │
                    │  │  AI-included: $19.99/mo       │  │
                    │  │  Webhook → updates tier in    │  │
                    │  │  Postgres on payment events   │  │
                    │  └──────────────────────────────┘  │
                    │                                    │
                    │  ┌──────────────────────────────┐  │
                    │  │   AI Proxy (CF Worker or     │  │
                    │  │   Supabase Edge Function)    │  │
                    │  │                              │  │
                    │  │  1. Validate JWT             │  │
                    │  │  2. Check tier = ai_included │  │
                    │  │  3. Check rate limit bucket  │  │
                    │  │  4. Forward to Claude API    │  │
                    │  │  5. Stream response to client│  │
                    │  │  6. Discard input payload    │  │
                    │  └──────────────────────────────┘  │
                    └────────────────────────────────────┘
```

### AI Proxy Detail

The proxy is a stateless function — no database writes during the request path, only the pre-flight JWT + rate-limit check.

```
Client (ai-included tier)
    │
    │  POST /proxy/ai
    │  Headers: Authorization: Bearer <15-min JWT>
    │  Body: { prompt, context_window }
    │
    ▼
CF Worker / Edge Function
    ├── Verify JWT signature (Supabase JWT secret)
    ├── Assert tier claim = "ai_included"
    ├── Increment Redis/Upstash counter (per user, per day)
    │     └── Reject if > 50 digest calls/day
    │         or > 10 profile rewrites/month
    ├── Forward body to Claude API (Anthropic key stored in env)
    ├── Stream response back to client
    └── [input payload discarded — never written to disk or DB]
```

**Technology choice:** Cloudflare Workers preferred over Supabase Edge Functions for lower cold-start latency and built-in Upstash Redis rate limiting. Either works; the interface contract is identical.

### Rate Limits

| Feature | Limit | Scope |
|---|---|---|
| Digest generation | 50 captures/day processed | Per user, per day |
| AI Profile rewrite | 10 rewrites/month | Per user, per calendar month |
| AI proxy requests | Derived from above; no separate cap | — |

---

## 4. Auth & Account Flow

### Pre-Auth Capture (Local-First Onboarding)

Users can capture content immediately without an account. No sign-in gate at launch.

```
Day 0 (no account)          Day N (signs up)
─────────────────           ────────────────────────────
Capture saved locally   →   Auth completes
SwiftData (device only)     JarieCore migrates local
No CloudKit sync yet        captures: assigns iCloud
                            record IDs, begins sync
                            Local-only flag cleared
```

### Auth Methods

**Sign in with Apple (primary)**
- Handled via `ASAuthorizationController` (SwiftUI `.signInWithAppleButton`)
- Identity token exchanged with Supabase Auth → session JWT issued
- Apple hidden email relay handled transparently by Supabase

**Email/Password (secondary)**
- Supabase Auth standard flow
- Magic link option recommended for better conversion (add in v1.1)

### License Flow (iOS — No IAP)

```
User visits easyberry.com
    │
    ▼
Stripe Checkout (web)
    │
    ▼
Webhook → Supabase Postgres
  • tier updated
  • license_key generated (UUID, stored hashed)
  • server_validation_ts issued (HMAC-signed)
    │
    ▼
License key emailed to user
    │
    ▼
User enters key in Jarie iOS app
    │
    ▼
App calls Supabase → validates key → receives signed timestamp
App stores timestamp in Keychain
App verifies HMAC locally on each launch
    │
    ▼
Features unlocked (7-day offline grace via HMAC timestamp)
```

**Why no IAP:** iOS distribution uses App Store but purchases flow through easyberry.com/Stripe. This avoids Apple's 30% cut on subscription revenue and keeps billing unified across Mac and iOS. See Section 6 for validation security details.

### Tier Gating Summary

| Feature | No Account | BYOK ($24.99/yr) | AI-included ($19.99/mo) |
|---|---|---|---|
| Capture (local) | Yes | Yes | Yes |
| CloudKit sync | Requires account | Yes | Yes |
| Markdown export | Yes | Yes | Yes |
| Digest (BYOK) | No | Yes | Yes |
| Digest (proxy) | No | No | Yes |
| AI Profile | No | BYOK only | Yes |

---

## 5. CloudKit Sync Strategy

### Sync Topology

```
Device A (Mac)          iCloud / CloudKit          Device B (iPhone)
──────────────          ──────────────────          ─────────────────
Capture created    →    Record written          →   Record received
SwiftData write         NSPersistentCloud-           SwiftData merge
                        KitContainer handles
                        all transport

                        Conflict window:
                        Last-write-wins
                        (captures are append-only;
                         true conflicts are rare)
```

### Field Ownership

| Field | Owned By | Sync Behavior |
|---|---|---|
| `content`, `url`, `tags`, `capturedAt` | Originating device | Syncs freely, last-write-wins |
| `aiSummary` | Device that ran BYOK generation | Syncs as opaque string |
| `digestIncluded` | Digest generation process | Set by server (AI-included) or local device (BYOK) |
| Digest body | Server (AI-included) / local device (BYOK) | Syncs as opaque markdown string |

### Multi-Device Digest Coordination

**Problem:** If Device A and Device B both trigger digest generation simultaneously, you get duplicate digests.

**Solution:** For AI-included tier, digest generation is server-side (ephemeral AI proxy call). The server uses a per-day idempotency key (`userId + date`). Devices receive the digest via normal CloudKit sync — they never independently generate it.

For BYOK tier, digest is generated locally on whichever device the user triggers it from. A `digestTriggeredAt` timestamp on the `DailyDigest` record prevents duplicate generation: device checks if today's digest exists before calling the API.

### Migration Rules (Non-Negotiable)

1. **Always Optional:** New SwiftData fields must be `Optional` with a default of `nil`. CloudKit cannot backfill existing records.
2. **Never rename:** Renaming a field is a breaking schema change. Add a new field, migrate data in-app, deprecate the old one in a future major version.
3. **No relationship changes without a migration plan:** Promote flat arrays (e.g., `tags: [String]`) to entities only in v2 with a dedicated migration coordinator.

### Offline Behavior

```
Network unavailable
    │
    ▼
Writes go to local SwiftData store normally
NSPersistentCloudKitContainer queues sync operations
    │
    ▼
Network restored
    │
    ▼
Queued operations replayed automatically
Merge conflicts resolved (last-write-wins)
No user action required
```

---

## 6. Security Architecture

> **Architecture principle:** Defense in depth. Each layer below is independently enforced — a failure in one does not cascade to compromise user data.

> **WARNING — API Key Storage:** BYOK API keys are stored exclusively in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. They are never written to `UserDefaults`, `NSUbiquitousKeyValueStore`, or any file. `ThisDeviceOnly` prevents iCloud Keychain sync, keeping keys off Jarie infrastructure entirely. Any code path that touches the API key must be audited to ensure it does not log, serialize, or transmit the value.

> **WARNING — JWT Validation:** The AI proxy validates short-lived JWTs with a 15-minute TTL. It never accepts bare user IDs, long-lived session tokens, or API keys as authentication. Clients must refresh their JWT before calling the proxy. Tokens are validated against the Supabase JWT secret stored as a Worker environment variable — never hardcoded.

> **WARNING — AppleScript Browser Scope:** The browser URL detection AppleScript is scoped to an explicit allowlist of bundle IDs: `com.apple.Safari`, `com.google.Chrome`, `company.thebrowser.Browser` (Arc). It will not execute against arbitrary frontmost apps. The bundle ID is validated before the AppleScript runs.

> **WARNING — License Offline Grace:** HMAC-signed server timestamps use a shared secret stored in Supabase Secrets (never in client code). The client verifies the HMAC on each cold launch. The 7-day grace window is encoded in the signed payload — the client cannot extend it locally. System clock rollback is mitigated by comparing against the last-verified timestamp stored in Keychain; if the current clock is earlier than the last verified time, the grace window is considered elapsed.

> **WARNING — App Blocklist:** The global hotkey checks the frontmost app against a default blocklist before capturing content. Blocklisted apps: 1Password, Keychain Access, Terminal, iTerm2, Warp, and known banking app bundle IDs. Users can modify the blocklist in Settings; the default is conservative.

> **WARNING — SwiftData Store Encryption:** The SwiftData store URL is configured with `NSFileProtectionComplete` on iOS. On macOS (direct download, no sandbox), the store path must never be world-readable — verify permissions on first launch and tighten if needed (`chmod 700`).

> **WARNING — Markdown Write Conflicts:** The `MarkdownFileActor` enforces single-device writes. If the configured folder is inside iCloud Drive, concurrent writes from multiple devices can produce conflict duplicates. JarieCore detects iCloud Drive paths and warns the user. See Section 12 for details.

> **WARNING — Color Contrast (WCAG AA):** Secondary text color bumped from `#8B8FA8` to `#6B6F83` (contrast ~5.1:1) for WCAG AA compliance. Verify with Accessibility Inspector before shipping.

---

## 7. Data Privacy Architecture

### Data Residency Map

```
What                        Where it lives          Server sees it?
──────────────────────────  ──────────────────────  ───────────────
Captures (text, URLs)       Device + iCloud only    No
Daily Digests               Device + iCloud only    Ephemeral only*
AI Profile                  Device + iCloud only    Ephemeral only*
API keys (BYOK)             Device Keychain only    Never
Auth tokens                 Device Keychain         Yes (issued by server)
Tier / subscription         Supabase Postgres       Yes (metadata only)
License key (hashed)        Supabase Postgres       Yes (hash only)

* Sent transiently to AI proxy for AI-included tier; discarded after response.
  BYOK: never touches Jarie backend.
```

### Ephemeral AI Processing Flow (AI-Included Tier)

```
Device
  │  Captures (in-memory, not persisted to request log)
  ──────────────────────────────────────────────────►
                                              AI Proxy
                                                │
                                                ├── Validates JWT
                                                ├── Forwards to Claude API
                                                ├── Receives response
  ◄──────────────────────────────────────────── │
  Digest / Profile text                         │
                                                └── Input payload discarded
                                                    (no DB write, no log)
```

The proxy is explicitly configured with no request body logging.

### BYOK Data Flow

```
Device Keychain
  │  API key retrieved (never leaves device)
  ▼
Device → Claude API (direct HTTPS)
  │  Jarie backend is not in this path
  ▼
Response returned to device → SwiftData → iCloud (Apple-encrypted)
```

### Privacy Policy Requirements

1. **AI-included tier:** Captures are transmitted transiently for digest/profile generation. Not stored, logged, or used for model training.
2. **BYOK tier:** Captures go directly from device to Anthropic's Claude API. Jarie never receives this data.
3. **iCloud sync:** Content stored in user's private iCloud account under Apple's privacy terms.
4. **Analytics:** None planned at launch. If added, must be disclosed.

---

## 8. SwiftData Schema (Final v1)

```swift
import SwiftData
import Foundation

// MARK: - Enums

enum CaptureType: String, Codable {
    case text
    case url
    case image  // Forward compat — not implemented in v1
    case file   // Forward compat — not implemented in v1
}

enum CaptureMethod: String, Codable {
    case hotkey
    case shareSheet
    case clipboard
    case services
    case manual
    case widget
}

// MARK: - Capture

@Model
final class Capture {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var content: String
    var type: CaptureType
    var method: CaptureMethod
    var sourceURL: String?
    var sourceTitle: String?
    var sourceDomain: String?
    var sourceBundleID: String?
    var tags: [String]           // Flat array — no Tag entity (v1)
    var isFavorite: Bool
    var aiSummary: String?       // One-liner, filled async post-capture
    var isDeleted: Bool          // Soft delete

    // Forward compat — Optional by convention
    var faviconURL: String?
    var imageData: Data?         // For .image type (v2)
    var filePath: String?        // For .file type (v2)

    init(
        content: String,
        type: CaptureType,
        method: CaptureMethod,
        sourceURL: String? = nil,
        sourceBundleID: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.type = type
        self.method = method
        self.sourceURL = sourceURL
        self.sourceBundleID = sourceBundleID
        self.tags = []
        self.isFavorite = false
        self.isDeleted = false
    }
}

// MARK: - DailyDigest

@Model
final class DailyDigest {
    @Attribute(.unique) var id: UUID
    var date: Date               // Calendar date this digest covers
    var summary: String          // AI-generated markdown
    var captureIds: [UUID]       // Blob — display-only, not a relationship
    var captureCount: Int
    var generatedAt: Date
    var modelUsed: String?       // e.g. "claude-haiku-4-5-20251001"

    init(date: Date, summary: String, captureIds: [UUID], captureCount: Int) {
        self.id = UUID()
        self.date = date
        self.summary = summary
        self.captureIds = captureIds
        self.captureCount = captureCount
        self.generatedAt = Date()
    }
}

// MARK: - AIProfile

@Model
final class AIProfile {
    @Attribute(.unique) var id: UUID
    var updatedAt: Date
    var fullText: String                    // Condensed profile markdown (~2-3K tokens)
    var lastCaptureCountAtGeneration: Int

    init(fullText: String, captureCount: Int) {
        self.id = UUID()
        self.updatedAt = Date()
        self.fullText = fullText
        self.lastCaptureCountAtGeneration = captureCount
    }
}

// MARK: - AIProfileVersion

@Model
final class AIProfileVersion {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var prompt: String?          // Rewrite prompt if user-requested
    var text: String             // Snapshot of profile text
    var profileId: UUID          // Manual foreign key — no SwiftData relationship

    init(text: String, profileId: UUID, prompt: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.text = text
        self.profileId = profileId
        self.prompt = prompt
    }
}
```

**Migration note:** v1 ships with implicit lightweight migration only. All future fields are `Optional`. `VersionedSchema` and `SchemaMigrationPlan` introduced at v1.1. The `AIProfileVersion.profileId` manual foreign key avoids CloudKit relationship sync issues.

---

## 9. Shared Core (JarieCore) Module Structure

```
JarieCore/
├── Models/          — SwiftData @Model classes + enums
├── Persistence/     — PersistenceController (CloudKit container config)
├── Services/        — CaptureService (actor)
├── Markdown/        — MarkdownExporter, DailyFileWriter, MarkdownFileActor
├── Enrichment/      — MetadataFetcher (URL title, favicon, domain)
├── AI/              — AIService protocol, ClaudeProvider, ProxyProvider,
│                      DigestGenerator, ProfileGenerator
├── Account/         — AccountManager, LicenseValidator
├── Utilities/       — URLExtractor, DateFormatters
```

### Module Responsibilities

**Models/** — Pure data definitions. All SwiftData `@Model` classes from Section 8. No business logic.

**Persistence/** — `PersistenceController` configures the `ModelContainer` with CloudKit sync. Provides a shared singleton for the app and an in-memory configuration for previews/tests.

**Services/** — `CaptureService` is a Swift `actor` that orchestrates the full capture pipeline: validate input → save to SwiftData → trigger markdown export → queue enrichment. All platform-specific callers funnel through this single entry point.

```swift
actor CaptureService {
    private let modelContainer: ModelContainer
    private let markdownActor: MarkdownFileActor
    private let enrichment: MetadataFetcher

    func save(_ content: String, type: CaptureType, method: CaptureMethod,
              sourceURL: String?, bundleID: String?) async throws -> Capture {
        // 1. Create & persist Capture (MUST succeed)
        // 2. Fire-and-forget markdown write (best-effort)
        // 3. Fire-and-forget enrichment (best-effort)
    }
}
```

**Markdown/** — `MarkdownFileActor` (actor) serializes file I/O. `MarkdownExporter` formats `Capture` → markdown string. `DailyFileWriter` manages the `YYYY/MM/YYYY-MM-DD.md` file structure.

**Enrichment/** — `MetadataFetcher` resolves URL metadata (page title, domain, favicon). Uses `URLSession` with 10-second timeout. Failures are silent.

**AI/** — `AIService` protocol with two implementations:
- `ClaudeProvider` — Direct Anthropic API calls (BYOK). Key from Keychain.
- `ProxyProvider` — Routes through Jarie backend (AI-included). JWT attached.

`DigestGenerator` builds the prompt, calls `AIService`, saves `DailyDigest`. `ProfileGenerator` diffs new captures against existing profile, saves updated `AIProfile` + `AIProfileVersion` snapshot.

**Account/** — `AccountManager` manages auth state and tier. `LicenseValidator` verifies HMAC-signed timestamps with 7-day offline grace.

**Utilities/** — `URLExtractor` (regex-based URL detection), `DateFormatters` (shared, pre-configured).

---

## 10. Mac-Specific Architecture (JarieMac)

### Menu Bar App

Jarie runs as a menu bar agent (`LSUIElement = YES`). No Dock icon by default. Toggle in Settings:

```swift
NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
```

### Global Hotkey

Uses `sindresorhus/KeyboardShortcuts`. Default: `⌘⇧J`, user-configurable.

**Capture flow:**

1. Check frontmost app bundle ID against blocklist. If blocked, abort silently.
2. Simulate `⌘C` via `CGEvent` — intentionally overwrites clipboard.
3. Read `NSPasteboard.general` after ~100ms delay.
4. If clipboard has content → `CaptureService.save()` with `.hotkey` method.
5. Show toast.

### App Blocklist

Default blocked bundle IDs (hotkey silently ignored):

- `com.1password.*`
- `com.apple.keychainaccess`
- `com.apple.Terminal`
- `com.googlecode.iterm2`
- `dev.warp.Warp-Stable`
- Banking apps matched by common patterns

Stored in `UserDefaults`. User-editable in Settings.

### BrowserURLDetector

AppleScript scoped to three browsers:

- **Safari** (`com.apple.Safari`) — `tell application "Safari" to get URL of current tab of front window`
- **Chrome** (`com.google.Chrome`) — `tell application "Google Chrome" to get URL of active tab of front window`
- **Arc** (`company.thebrowser.Browser`) — Same as Chrome (Chromium-based)

Each browser requires a separate Automation permission grant. Fails gracefully per-browser.

### Toast Notifications

Custom `NSPanel`:

```swift
let panel = NSPanel(contentRect: rect,
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered, defer: false)
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

- Appears on screen containing the active app.
- 1.8 seconds display, 0.3s fade out.
- Rapid captures: new toast replaces current (no stacking).
- Respects Reduce Motion: instant appear/disappear.

### Dashboard Window

`NavigationSplitView` — two-pane default:
- **Sidebar (~180pt):** Today, All, Starred, Digest, Sources, Labels, AI Profile.
- **List pane:** Reverse chronological captures. Inline `⌘F` search.
- **Detail pane:** Slides in on row selection.

### Services Menu

`"Copy & Capture to Jarie"` registered via `NSServices` in Info.plist. Routes to `CaptureService.save()` with `.services` method.

---

## 11. iOS-Specific Architecture (JarieiOS)

### Tab Structure

`TabView` with icon + text labels:

| Tab | SF Symbol | Content |
|---|---|---|
| Today | `clock` | Reverse-chronological inbox + Daily Digest card at top |
| All | `tray.full` | Full capture list, filter pills (All/URLs/Text/Starred) |
| Search | `magnifyingglass` | Full-text search, results as-you-type |

### Today Tab

- **Daily Digest card** pinned at top when available (tappable to expand).
- Today's captures below in reverse chronological order.
- Swipe actions: favorite (left), delete (right).

### Share Extension

Operates under 120MB memory limit. **Never initializes SwiftData.**

1. Extension receives shared content (text, URL).
2. Writes JSON staging file to App Group container (`group.com.easyberry.jarie`):
   ```json
   { "content": "...", "type": "url", "method": "shareSheet",
     "sourceURL": "...", "timestamp": "..." }
   ```
3. Posts Darwin notification (`com.easyberry.jarie.newCapture`).
4. Extension dismisses with haptic feedback.
5. Main app imports on foreground: reads JSON, creates `Capture` records, deletes staging files.

### Clipboard Detection

```swift
// No paste prompt triggered by this check
if UIPasteboard.general.hasStrings {
    // Show "Save clipboard?" banner
}
// UIPasteboard.general.string only read on explicit user tap
```

Banner: slides down from top, respects safe area / Dynamic Island, auto-dismiss after 8 seconds, prompted once per clipboard content hash.

### Widget

Reads JSON from App Group (not SwiftData):

```json
{ "todayCount": 7,
  "recentCaptures": [
    { "preview": "First 80 chars...", "type": "url", "timestamp": "..." }
  ] }
```

- Small widget: today's capture count.
- Medium widget: count + last 3 capture previews.

### Detail View

Half-sheet with `.presentationDetents([.medium, .large])`. Medium: content + metadata. Large: full view with tags, AI summary.

---

## 12. Markdown Export Pipeline

### Directory Structure

```
~/mind/collected/              ← User-configurable root (macOS default)
├── 2026/
│   ├── 03/
│   │   ├── 2026-03-15.md     ← Daily capture log (append-only)
│   │   └── 2026-03-16.md
├── digest/
│   ├── 2026-03-15-digest.md
│   └── 2026-03-16-digest.md
└── profile/
    └── ai-profile.md          ← Latest profile, overwritten on regeneration
```

iOS: root is the app's iCloud Drive container.

### MarkdownFileActor

```swift
actor MarkdownFileActor {
    private let rootURL: URL

    func appendCapture(_ capture: Capture) async throws {
        let fileURL = dailyFileURL(for: capture.createdAt)
        try ensureDirectoryExists(fileURL.deletingLastPathComponent())
        let markdown = MarkdownExporter.format(capture)
        try appendToFile(markdown, at: fileURL)
    }

    func writeDigest(_ digest: DailyDigest) async throws { ... }
    func writeProfile(_ profile: AIProfile) async throws { ... }
}
```

### Cross-Device Write Prevention

Markdown written **only on the originating device**. When CloudKit syncs a capture from another device, the markdown export step is skipped. Prevents iCloud Drive merge conflicts.

### Failure Handling

- SwiftData save is the commit point. Markdown failure does not block capture.
- Failed writes tracked in a local retry queue (`UserDefaults`).
- Retried on next app launch. No user-facing error.

---

## 13. Concurrency Model

All concurrency follows **Swift 6 strict concurrency** with complete `Sendable` checking.

### Actor Isolation

| Component | Isolation | Rationale |
|---|---|---|
| `CaptureService` | `actor` | Serializes capture pipeline |
| `MarkdownFileActor` | `actor` | Prevents concurrent file I/O corruption |
| SwiftData background ops | `@ModelActor` | Safe background context access |
| UI state | `@MainActor` | All SwiftUI views and view models |

### Async Patterns

```swift
actor CaptureService {
    func save(...) async throws -> Capture {
        let capture = try await persistToSwiftData(...)  // Must succeed

        // Non-blocking follow-ups — failures don't propagate
        Task { try? await markdownActor.appendCapture(capture) }
        Task { await enrichIfURL(capture) }

        return capture
    }
}
```

### SwiftData Threading

```swift
@ModelActor
actor BackgroundPersistence {
    func importStagedCaptures(_ files: [URL]) throws {
        for file in files {
            let data = try Data(contentsOf: file)
            let staged = try JSONDecoder().decode(StagedCapture.self, from: data)
            let capture = Capture(content: staged.content, type: staged.type,
                                  method: staged.method)
            modelContext.insert(capture)
        }
        try modelContext.save()
    }
}
```

All data flowing between actors is `Sendable`. Model IDs (`PersistentIdentifier`) are passed across isolation boundaries rather than model objects.

---

## 14. Error Handling Patterns

### Capture Save (Critical Path)

SwiftData write is the **only operation that must succeed**. Everything downstream is best-effort:

```swift
actor CaptureService {
    func save(...) async throws -> Capture {
        let capture = try await persist(...)  // CRITICAL

        Task {  // BEST-EFFORT
            do { try await markdownActor.appendCapture(capture) }
            catch { Logger.markdown.error("Write failed: \(error)") }
        }
        Task {
            do { try await enrichment.fetch(for: capture) }
            catch { Logger.enrichment.warning("Enrichment skipped: \(error)") }
        }
        return capture
    }
}
```

### AI Calls (Digest & Profile)

```
Attempt 1 → fail → wait 1s
Attempt 2 → fail → wait 4s
Attempt 3 → fail → mark "pending"
```

On final failure: `pendingDigestDate` stored in `UserDefaults`. Retried on next app launch. Subtle indicator in Digest view only after 24+ hours.

### Enrichment

10-second `URLSession` timeout. On failure: fields remain `nil`, capture saved with raw content. No retry.

### License Validation

```swift
struct LicenseValidator {
    func validate() async -> LicenseState {
        if let cached = loadCachedLicense(),
           cached.isValid, cached.age < .days(7) {
            return .valid(cached.tier)  // Offline grace
        }
        do {
            let license = try await fetchLicenseFromServer()
            cache(license)
            return .valid(license.tier)
        } catch {
            if let cached = loadCachedLicense(), cached.isValid {
                return .grace(daysRemaining: 7 - cached.age.days)
            }
            return .expired  // Features locked, captures continue
        }
    }
}
```

---

## 15. Navigation Architecture

### Mac

- **Menu bar app** — no Dock icon by default (`LSUIElement = YES`)
- **Menu bar dropdown:** today count, last capture preview, New Capture (⌘⇧J), Open Dashboard (⌘⇧D), Settings, Quit
- **Dashboard:** `NavigationSplitView`, two-pane default. Detail slides in on selection.
- **Sidebar (~180pt):** Today, All, Starred, Digest | Sources (auto-populated) | Labels (color-coded) | AI Profile
- **Settings:** Tabbed — General, Account, Capture, AI, Appearance, Export, About

### iOS (iPhone)

- **3 tabs** with icon + text: Today / All / Search
- **Today:** reverse chronological + Daily Digest card at top
- **All:** section headers by date, filter pills (All/URLs/Text/Starred)
- **Search:** inline, results as-you-type (~300ms debounce)
- **Detail:** half-sheet (`.medium`, `.large` detents)

### iPad

- `NavigationSplitView` three-column (sidebar + list + detail)
- **Portrait:** sidebar collapses to SwiftUI default toggle
- **Keyboard:** ⌘⇧J, ⌘F, arrows, Return, Delete, ⌘Z

---

## 16. Design Tokens / SwiftUI Theme System

### Colors (EasyBerry Palette)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `background` | `#FFFFFF` | `#1A1A24` | Primary surface |
| `textPrimary` | `#39383A` | `#E8E8EC` | Body text, titles |
| `textSecondary` | `#6B6F83` | `#9B9FB3` | Timestamps, metadata (WCAG AA compliant) |
| `accentTeal` | `#1CB6C5` | `#2DD4E3` | Primary actions, toast, active states |
| `accentPink` | `#F2809D` | `#F599B2` | Favorites/stars |
| `accentYellow` | `#F9B114` | `#FBBF3A` | Warnings, badges |
| `accentBlue` | `#75A4D8` | `#8FB8E8` | Links, source labels, secondary actions |

Dark mode accents shifted +10-15% brightness. All tokens in Asset Catalog with Any/Dark appearances, exposed via `Color` extension in JarieCore.

**Rule:** Colors as small accents only. Never a colored background on a primary surface.

### Typography (SF Pro, Dynamic Type)

| Style | Size | Weight | Usage |
|---|---|---|---|
| Display | 28pt | Bold | Dashboard header |
| Title | 20pt | Semibold | Section headers, digest title |
| Headline | 17pt | Semibold | Capture row title |
| Body | 15pt | Regular | Content text, profile text |
| Caption | 13pt | Regular | Source domain, timestamp |
| Footnote | 11pt | Regular | Metadata, counts |

All sizes are base values — Dynamic Type scales them.

### Elevation

- **Flat** for primary surfaces (no shadows on cards, rows, sidebars)
- **Subtle shadow** on floating elements only (toast, dropdown, sheets):
  `shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)`

### Row Separators

Thin divider lines (like Apple Mail). SwiftUI `Divider()` — 0.5pt system separator color.

### Spacing (4pt Grid)

| Token | Value | Usage |
|---|---|---|
| `xxs` | 4pt | Icon-to-text gap |
| `xs` | 8pt | Row internal spacing |
| `sm` | 12pt | Row vertical padding |
| `md` | 16pt | Section padding, margins |
| `lg` | 24pt | Between sections |
| `xl` | 32pt | Major section breaks |
| `xxl` | 48pt | Page-level margins |

---

## 17. Interaction Specs

### Capture Flow (Mac)

1. User selects text → presses `⌘⇧J`
2. Check app blocklist → if blocked, do nothing
3. Simulate `⌘C` → clipboard overwritten (intended)
4. Read clipboard → create `Capture` in SwiftData
5. `BrowserURLDetector` grabs URL + title via AppleScript (if browser)
6. **Toast** on active screen:
   - Entrance: slide down, 0.25s ease-out
   - Display: 1.8 seconds
   - Exit: fade out 0.3s
   - Rapid: replace (don't stack)
   - Reduce Motion: instant appear/disappear
   - Floats above full-screen apps
7. Enrichment runs async (non-blocking)
8. Markdown written by `MarkdownFileActor`

### Capture Flow (iOS Share Sheet)

1. Share → "Save to Jarie"
2. Compact UI: title + domain + Cancel/Save
3. Save → haptic → dismiss
4. Write JSON to App Group staging file
5. Main app imports on foreground

### Clipboard Detection (iOS)

1. App foregrounds → `hasStrings` check (no paste prompt)
2. Banner: "Clipboard detected: [preview]" + Save it / Dismiss
3. Slides down, respects safe area / Dynamic Island
4. Auto-dismiss 8 seconds (fade-up)
5. Once per clipboard content hash
6. "Save it" → paste permission dialog (user-initiated)

### Delete Behavior

- Swipe-left reveals delete button (like Mail)
- No modal confirmation
- `⌘Z` undo (Mac/iPad), shake-to-undo (iOS)
- Row animates out: slide left → collapse height

### Star Toggle

- Tap star → scale bounce (1.0 → 1.3 → 1.0, 0.2s spring)
- `star` ↔ `star.fill` crossfade with pink fill
- Reduce Motion: instant swap, no bounce

---

## 18. Key Screen Wireframes (ASCII)

### Mac — Menu Bar Dropdown
```
┌─────────────────────────────────┐
│  Jarie                          │
│  ─────────────────────────────  │
│  Today: 12 captures             │
│  Last: "Claude now cre…"        │
│        — 4 min ago              │
│  ─────────────────────────────  │
│  [+ New Capture]   ⌘⇧J         │
│  ─────────────────────────────  │
│  Open Dashboard        ⌘⇧D     │
│  ─────────────────────────────  │
│  Settings...                    │
│  Quit Jarie                     │
└─────────────────────────────────┘
```

### Mac — Dashboard (two-pane default)
```
┌────────────┬──────────────────────────────────────────────────┐
│            │                                                  │
│  SIDEBAR   │  INBOX                                           │
│            │                                                  │
│  Today     │  ★ Claude now creates interactive charts...      │
│  All       │    x.com/claudeai · Safari · 4:12 PM            │
│  ★ Starred │  ──────────────────────────────────────────────  │
│  Digest    │  How foundation models are commoditizing         │
│            │    x.com/a16z · Safari · 2:40 PM                │
│  SOURCES   │  ──────────────────────────────────────────────  │
│  Safari    │  AMI Labs raised $1.03B for world models         │
│  Chrome    │    techcrunch.com · Chrome · 1:15 PM             │
│            │                                                  │
│  LABELS    │  ─── Yesterday ─────────────────────────         │
│  🟢 tech   │                                                  │
│  🔵 ai     │  [more captures...]                              │
│            │                                                  │
│  ──────    │                                                  │
│  AI PROFILE│                                                  │
│  [View]    │                                                  │
└────────────┴──────────────────────────────────────────────────┘
```

### Mac — Dashboard with Detail (on selection)
```
┌────────────┬──────────────────────────┬───────────────────────┐
│  SIDEBAR   │  INBOX                   │  DETAIL               │
│            │                          │                       │
│  Today     │  ★ [selected row]        │  Claude now creates   │
│  All       │  ─────────────────────── │  interactive charts   │
│  ★ Starred │  How foundation models…  │  directly in...       │
│  Digest    │  ─────────────────────── │                       │
│            │  AMI Labs raised...      │  Source: x.com        │
│  ...       │                          │  App: Safari          │
│            │                          │  Time: 4:12 PM        │
│            │                          │  Method: Hotkey       │
│            │                          │                       │
│            │                          │  [Open URL] [Copy]    │
└────────────┴──────────────────────────┴───────────────────────┘
```

### Mac — Toast
```
                              ┌──────────────────────────┐
                              │  ✓  Copied & Saved       │
                              │  Claude now creates in…  │
                              │  x.com/claudeai          │
                              └──────────────────────────┘
                              ↑ top-right of active screen
```

### iPhone — Today Tab
```
┌─────────────────────────────────┐
│  Jarie                    [👤]  │
│─────────────────────────────────│
│ ┌─────────────────────────────┐ │
│ │ 📋 Daily Digest             │ │
│ │ 12 captures · 3 themes     │ │
│ │ Tap to read →              │ │
│ └─────────────────────────────┘ │
│                                 │
│  ★ Claude now creates charts…  │
│    x.com · Safari · 4:12 PM    │
│  ───────────────────────────    │
│  How foundation models are…    │
│    x.com · Safari · 2:40 PM    │
│  ───────────────────────────    │
│  AMI Labs raised $1.03B…       │
│    techcrunch.com · 1:15 PM    │
│                                 │
├─────────┬─────────┬─────────────┤
│  Today  │   All   │   Search    │
└─────────┴─────────┴─────────────┘
```

### iPhone — Share Extension
```
┌─────────────────────────────────┐
│  Save to Jarie                  │
│  ─────────────────────────────  │
│  Claude now creates charts...   │
│  x.com/claudeai                 │
│  ─────────────────────────────  │
│  [Cancel]              [Save]   │
└─────────────────────────────────┘
```

---

## 19. Empty States

Each view uses `ContentUnavailableView` (iOS 17+ / macOS 14+) with an SF Symbol + contextual message:

| View | SF Symbol | Message |
|---|---|---|
| Today (no captures) | `tray` | **Mac:** "Nothing captured today. Press ⌘⇧J to start." **iOS:** "Share something to get started." |
| All (no captures) | `square.stack` | "Your captures will appear here." |
| Starred | `star` | "Star your favorites to find them here." |
| Digest | `doc.text` | "Your first digest will appear after your first day of captures." |
| AI Profile | `person.text.rectangle` | "Keep capturing — your AI Profile builds automatically over the next few weeks." |
| Search (no results) | `magnifyingglass` | "No results found." |

---

## 20. Onboarding Flow

Minimal and progressive — no carousel, no feature tour.

1. **First launch:** Sign-in screen. SIWA (one tap) or email/password. Users can skip to capture locally first.
2. **Post-auth:** Empty dashboard (Mac) or Today tab (iOS). Empty state provides first hint.
3. **First hotkey (Mac):** Accessibility permission request with explanation: "Jarie needs Accessibility access to detect your text selection with ⌘⇧J."
4. **First browser capture (Mac):** Automation permission per browser (one-time each).
5. **Contextual tooltips:** Optional, non-blocking, on first interaction with key features. Dismissible.
6. **No forced walkthrough.** The product teaches through use.

---

## 21. Accessibility Requirements

1. **VoiceOver:** All interactive elements labeled. Toast posts `NSAccessibilityNotification` announcement ("Captured: [preview]") since it auto-dismisses.
2. **Dynamic Type:** All text scales. Base sizes are minimums. Layouts reflow at large sizes.
3. **Color contrast:** All text ≥ WCAG AA (4.5:1 body, 3:1 large). `textSecondary` bumped to `#6B6F83`.
4. **Non-color indicators:** Stars use shape change (`star.fill`), not just pink. Labels have text names alongside colored dots.
5. **Reduce Motion:** Toast instant appear/disappear. Star skip bounce. Delete skip slide. All animations check `accessibilityReduceMotion`.
6. **Keyboard (Mac):** Tab between sidebar/list/detail. Escape deselects/closes. Delete removes. `⌘Z` undo. Full shortcut list in Help menu.
7. **Touch targets (iOS):** 44x44pt minimum for all interactive elements.
8. **High Contrast:** Stronger borders, reduced transparency when system setting enabled.
9. **Focus management:** Dashboard opens focused on list. Delete moves focus to next item. Sheet dismissal returns focus.
10. **Clipboard banner (iOS):** VoiceOver announced. 8-second timeout provides adequate interaction time.

---

## 22. Implementation Priority Order

Follows the phased plan from `brief.md` Section 27, refined with architectural decisions:

### Phase 0: Project Setup (Manual — Angel)
- Xcode project, CloudKit container, capabilities, SPM dependency

### Phase 1: Data Foundation + Account (Week 1-2)
- SwiftData models (Section 8)
- `PersistenceController` with CloudKit
- `CaptureService` actor
- `MarkdownFileActor` + `MarkdownExporter` + `DailyFileWriter`
- `MetadataFetcher`
- Supabase Auth setup (SIWA + email)
- Stripe billing integration
- `LicenseValidator` with HMAC-signed timestamps
- AI proxy endpoint (Cloudflare Worker)

### Phase 2: Mac App (Week 3)
- Menu bar + dropdown
- Global hotkey (⌘⇧J) with blocklist
- `BrowserURLDetector` (AppleScript)
- Toast `NSPanel`
- Dashboard with `NavigationSplitView`
- Sign-in flow → license validation

### Phase 3: iOS App (Week 4)
- Tab bar (Today / All / Search)
- Share Extension (JSON staging → App Group)
- Clipboard detection (`hasStrings`)
- Sign-in → license validation

### Phase 4: Sync Verification (Week 5)
- Real hardware CloudKit testing
- Mac ↔ iPhone sync
- Offline → reconnect
- License status across devices

### Phase 5: Daily Digest (Week 6)
- Server-side digest generation (AI-included)
- BYOK digest generation (local)
- Digest card in Today tab (iOS) / Digest sidebar item (Mac)
- Markdown export to `digest/`

### Phase 6: AI Profile (Week 7)
- Profile generation from captures
- Profile view + copy button + "Rewrite for..."
- `AIProfileVersion` history
- Export to `profile/ai-profile.md`

### Phase 7: Polish (Week 8-9)
- Services Menu, Settings, Stars, Auto-labels
- Onboarding, empty states, tooltips
- App icon, design system refinement
- Widget (JSON data source)
- Accessibility audit

---

## 23. Open Decisions

These items were explicitly deferred and should be revisited based on real usage data:

| Item | When to Revisit | Context |
|---|---|---|
| Free tier / trial | After first 100 paying users | If conversion is too low |
| OpenAI BYOK support | v1.1 | Add once AI abstraction layer proven |
| AI Profile public link | v2 | Needs sharing infra + privacy controls |
| Image/file capture | v1.1+ | Memory limits, asset storage |
| iPad-specific split view | v1.1 | Ship universal iOS first |
| Capture expiry/archival | v1.1 | Based on user feedback |
| On-device AI (Core ML) | v2 | Evaluate after API costs are known |
| VersionedSchema migration | v1.1 | Set up before first non-trivial migration |
| Tag → entity promotion | v2 | After CloudKit sync is stable |
| Mac App Store distribution | Revisit at 1,000 users | If sandbox constraints are manageable |
| Scheduled background digest | v1.1 | On-launch trigger sufficient for v1 |
| AI-included token caps (hard) | After 90 days usage data | Soft caps for now |

---

*This document is the technical source of truth for implementation. `brief.md` remains the product source of truth. When they conflict, discuss with Angel before proceeding.*
