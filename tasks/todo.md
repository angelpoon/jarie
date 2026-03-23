# Jarie AI — Implementation Progress

## Phase 0: Project Setup
- [x] 0.1 Xcode project exists (created by Angel)
- [ ] 0.2 Add iCloud + CloudKit capability — **Angel in Xcode** (deferred: using local SQLite until configured)
- [ ] 0.3 Add Push Notifications capability — deferred until backend (Phase 1.5A)
- [ ] 0.4 Add Sign in with Apple capability — deferred until auth (Phase 1.5A)
- [ ] 0.5 Create App Group — deferred until Share Extension (Phase 3)
- [x] 0.6 KeyboardShortcuts SPM added
- [x] 0.7 JarieCore extracted to local Swift Package (Packages/JarieCore/)
- [ ] 0.8 Min deployment targets (macOS 14, iOS 17) — currently 26.2, needs API availability audit
- [ ] 0.9 Create Share Extension target — deferred until Phase 3
- [x] 0.10 LSUIElement = YES
- [x] 0.11 Swift 6 — all targets SWIFT_VERSION = 6.0, SWIFT_STRICT_CONCURRENCY = complete
- [x] 0.12 Item.swift template deleted, replaced with real models
- [x] 0.13 VersionedSchema foundation (JarieSchemaV1 + JarieMigrationPlan)
- [x] 0.14 ENABLE_APP_SANDBOX = NO (direct distribution, needs Accessibility + AppleScript)
- [x] 0.15 cloudKitDatabase set to .none until 0.2 is done

## Phase 1: Data Foundation
### 1A: SwiftData Models & Persistence
- [x] 1.1 CaptureType + CaptureMethod enums
- [x] 1.2 Capture @Model
- [x] 1.3 DailyDigest @Model
- [x] 1.4 AIProfile @Model
- [x] 1.5 AIProfileVersion @Model
- [x] 1.6 PersistenceController
- [x] 1.7 Unit tests (6 test files, 25+ test cases)

### 1B: Core Services
- [x] 1.8 MarkdownExporter
- [x] 1.9 DailyFileWriter
- [x] 1.10 MarkdownFileActor
- [x] 1.11 MetadataFetcher
- [x] 1.12 CaptureService actor
- [x] 1.13 URLExtractor utility
- [x] 1.14 DateFormatters utility

### 1C: Design System Foundation
- [x] 1.16 Asset Catalog color sets (7 colors, Any/Dark, precise 4-decimal floats)
- [x] 1.17 Color extension (JarieColors.swift)
- [x] 1.18 Spacing enum (4pt grid)
- [x] 1.19 Typography helpers (Dynamic Type scaled via semantic text styles)

### Code Review Fixes (iOS Tech Lead Review)
- [x] C1 Sendable snapshot value types (CaptureSnapshot, DigestSnapshot, ProfileSnapshot)
- [x] C2 No @Model objects cross actor boundaries — snapshots used everywhere
- [x] C3 DateFormatters + URLExtractor marked @unchecked Sendable with rationale
- [x] W1 Modern throwing FileHandle API (seekToEnd, write(contentsOf:))
- [x] W2 PersistenceController.preview()/test() now throw instead of fatalError
- [x] W3 Fire-and-forget Task pattern documented with lifecycle note
- [x] W4 Cached URLExtractor result — no double NSDataDetector scan
- [x] W5 MarkdownFileActor methods have async in signatures
- [x] W6 Timezone documentation on all DateFormatters
- [x] S2 captureIds blob documented in DailyDigest
- [x] S3 JarieFont uses semantic text styles for Dynamic Type scaling
- [x] S4 HTML entity decoding TODO in MetadataFetcher
- [x] S5 CaptureService + MetadataFetcher tests added (11 new test cases)
- [x] S6 Asset catalog colors fixed to exact 4-decimal precision
- [x] C1 (Angel) Set Swift Language Version to 6 + SWIFT_STRICT_CONCURRENCY=complete in Xcode

## Phase 1.5: Account System & Backend
### 1.5A: Backend Infrastructure (Angel + Backend agent)
- [ ] 1.20-1.27 Supabase project, Auth, Postgres schema, Stripe, Edge Functions, AI proxy, Redis

### 1.5B: Client Account SDK
- [x] 1.28 AccountManager (@MainActor @Observable, auth state machine, tier management)
- [x] 1.29 LicenseValidator (HMAC verification, 7-day offline grace, clock rollback detection)
- [x] 1.30 KeychainStore (generic secure storage, kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
- [ ] 1.31 SignInView (shared SwiftUI — SIWA button + email/password form)
- [ ] 1.32 Local capture migration on sign-up
- [x] 1.33 LicenseValidator tests (7 tests)
- [x] 1.34 AccountManager tests (12 tests)

### 1.5C: AI Service Layer (added per tech lead review)
- [x] AIService protocol + AIResponse + AIServiceError
- [x] ClaudeProvider (BYOK direct Anthropic API calls)
- [x] ProxyProvider (AI-included tier, JWT-authenticated proxy)
- [x] PromptBuilders (DigestPromptBuilder + ProfilePromptBuilder, pure functions)
- [x] DigestGenerator actor (3x exponential backoff, pending queue, markdown export)
- [x] ProfileGenerator actor (threshold-based regeneration, rewrite support)
- [x] MockAIService + DigestGenerator tests (10 tests)
- [x] PromptBuilder tests (15 tests)

## Phase 2: Mac App

### Batch 0: Prerequisites
- [x] 0.6 KeyboardShortcuts SPM added to project
- [x] 0.10 LSUIElement = YES (menu bar agent, no Dock icon)
- [x] ENABLE_APP_SANDBOX = NO (direct distribution, needs Accessibility + AppleScript)
- [x] SWIFT_STRICT_CONCURRENCY = complete on app target

### Batch 1-2: App Shell + Menu Bar
- [x] 2.1 MenuBarController (NSStatusItem + NSPopover, AppDelegate composition root)
- [x] 2.2 MenuBarView (SwiftUI popover: today count, last capture, shortcuts, dashboard link)

### Batch 3: Hotkey + Blocklist
- [x] 2.3 HotkeyManager (KeyboardShortcuts, ⌘⇧J default)
- [x] 2.4 App blocklist (UserDefaults, default blocked: 1Password, Terminal, iTerm2, Warp, etc.)

### Batch 4: Capture Pipeline + Browser Detection + Toast
- [x] 2.5 HotkeyCapturePipeline (CGEvent ⌘C → clipboard → CaptureService, Accessibility fallback)
- [x] 2.6 BrowserURLDetector (AppleScript: Safari, Chrome, Arc, 2s timeout)
- [x] 2.7 Browser URL → capture integration (wired into pipeline)
- [x] 2.8-2.11 Toast (NSPanel + ToastCoordinator + ToastView, 1.8s auto-dismiss, Reduce Motion)

### Batch 5: Dashboard
- [x] 2.12-2.18 Dashboard (NavigationSplitView, sidebar, list with date grouping, detail, search, delete+undo, star toggle)

### Batch 6: Services Menu
- [x] 2.19 ServicesHandler (NSServices right-click "Copy & Capture to Jarie", NSApp.servicesProvider)

### Batch 7: Settings Window
- [x] 2.20 SettingsView (TabView root, 7 tabs, wired to ⌘,)
- [x] 2.21 GeneralSettingsTab (launch at login via SMAppService, show in Dock toggle)
- [x] 2.22 AccountSettingsTab (stub — awaiting Phase 1.5A backend)
- [x] 2.23 CaptureSettingsTab (KeyboardShortcuts.Recorder, blocklist display)
- [x] 2.24 AISettingsTab (SecureField → Keychain, never displays stored key)
- [x] 2.25 AppearanceSettingsTab (minimal v1 — follows system theme)
- [x] 2.26 ExportSettingsTab (NSOpenPanel folder picker, @AppStorage path)
- [x] 2.27 AboutSettingsTab (version, build, EasyBerry branding)

### Tech Lead Review Fixes (applied)
- [x] R1 CRITICAL: CaptureService race — snapshot created in same @MainActor hop as persist
- [x] R2 CRITICAL: Pipeline skips CGEvent in terminals (SIGINT risk), polls clipboard up to 400ms
- [x] R3 CRITICAL: BrowserURLDetector uses serial DispatchQueue + LockedFlag (no thread pileup)
- [x] R4 WARNING: DashboardWindow.isReleasedWhenClosed = false (no dangling pointer)
- [x] R5 WARNING: ToastCoordinator uses MainActor.assumeIsolated in DispatchWorkItem
- [x] R6 WARNING: AppBlocklist cached per call (acceptable v1, noted as tech debt at scale)
- [x] R7 WARNING: MenuBarView Settings selector (TODO to switch to @Environment openSettings)
- [x] R9 SUGGESTION: ToastCoordinator uses guard-return for NSScreen instead of NSScreen()

## Phase 3: iOS App
- [ ] 3.1-3.7 Main app (TabView, Today, All, Search, detail sheet, swipe actions, sign-in)
- [ ] 3.8-3.11 Share Extension (JSON staging, Darwin notification, importer)
- [ ] 3.12-3.14 Clipboard detection + Widget

## Phase 4-8: Sync Verification, Digest UI, Profile UI, Polish, Launch Prep
