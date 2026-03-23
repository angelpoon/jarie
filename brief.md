# Jarie AI — Product Brief
> **Source of truth.** Merged 2026-03-16 from v1 (detailed specs) + v2 (strategic reframe + AI features).
> Everything needed to build Jarie is in this document.

---

## 1. Executive Summary

**Jarie AI** is the fastest way to build long-term memory for your AI. Press a hotkey on Mac or tap Share on iPhone/iPad, and whatever you found interesting is instantly saved — then AI does the work: generating a daily digest of what you consumed, and maintaining a living AI Profile that you can paste into any LLM for instant context.

**Tagline:** *Capture what you find. AI builds your memory. You stay in control.*

**Price:** $24.99/year (BYOK) or $19.99/month (AI included), direct download from easyberry.com
**Developer:** EasyBerry LLC (Angel Poon)
**Brand family:** EasyBerry — shares color DNA with MoveBrush

---

## 2. The Strategic Insight

Everyone is building a second brain. The problem isn't the second brain — it's the intake valve. People consume content all day across every surface (browser, X, YouTube, newsletters, Slack) and lose almost all of it. The gap isn't organizing; it's that nothing captures reliably enough, fast enough, to make the memory real.

Jarie solves the intake problem. And because the output is structured markdown, it becomes the context layer that makes any AI tool smarter — Claude, ChatGPT, Cursor, custom agents. The human is the curation layer. AI is the synthesis layer. Jarie is the bridge.

**Key principles:**
- **The capture** is framed as feeding your AI's memory, not saving bookmarks
- **The markdown export** is the primary handoff mechanism, not a nice-to-have
- **The AI features** are about memory — daily digest + AI profile — not just organization
- **The persona** is anyone who uses AI daily and is frustrated that their AI forgets everything

---

## 3. Product Positioning

**One-liner:** Jarie captures what you find all day and turns it into long-term memory your AI can actually use.

**The differentiation:** Every capture tool saves things. Jarie builds memory. The difference is what happens after capture — a daily digest of everything you consumed, and a living AI Profile that grows smarter over time and travels with you into any LLM conversation.

**The bridge, not the brain:** Jarie doesn't try to be your second brain. It's the intake layer that feeds whatever system you already use — Claude Code, Obsidian, your Life OS — already organized, enriched, and synthesized.

**The AI is the primary consumer.** When you capture something in Jarie, you're not just saving it for yourself. You're feeding it to your AI agent. The human decides what's worth capturing. The AI does the synthesis work.

---

## 4. Target Users

### Persona 1: The AI Power User *(primary buyer, first 100)*
Anyone who uses Claude Code, ChatGPT, Cursor, or AI-assisted workflows daily. Developers, PMs, founders, consultants. Constantly finding references, prompts, code snippets, articles worth saving. **The real pain:** their AI has no memory of what they've been reading, researching, or thinking about. Every new conversation starts from zero.

**Why Jarie:** Global hotkey fits how they already work. Markdown output drops into Claude Code context or Obsidian. AI Profile gives their AI instant context without manual bios. BYOK tier at $24.99/yr is an impulse buy.

### Persona 2: The White-Collar Knowledge Worker *(high volume, AI-included tier)*
Finance analysts, consultants, researchers, strategists. Highly text-savvy. Consuming enormous amounts of content daily — reports, newsletters, X threads, articles. **The real pain:** synthesis happens manually, late, or not at all. They're drowning in inputs with no way to surface what mattered at the end of the day.

**Why Jarie:** Daily digest does the synthesis automatically. AI Profile builds over weeks into a genuine professional context document. $19.99/mo is justified by time saved on manual synthesis.

### Persona 3: The Writer / Content Creator *(Angel's core YouTube audience)*
YouTubers, newsletter writers, journalists. Constantly hunting reference material. **The real pain:** research happens everywhere, saving happens nowhere. By write time, the research is unfindable.

**Why Jarie:** Captures across all surfaces with consistent format. Daily digest surfaces research clusters. AI Profile doubles as a media kit / bio that auto-updates.

---

## 5. The Three Hero Features

```
CAPTURE          →         DAILY DIGEST          →         AI PROFILE
(the intake)               (the payoff)                    (the moat)

Sub-2 second               Every evening:                  A condensed, living doc
global hotkey.             here's what you                 about you. Auto-updates
⌘⇧J = copy +              consumed today,                 from your captures.
capture in one.            summarized by theme.            Paste into any LLM.
                           Opens like email.               Rewrite for any purpose.
```

### Feature 1: Frictionless Capture

**The key interaction:** ⌘⇧J replaces ⌘C for anything worth keeping. One keystroke copies to clipboard AND captures to Jarie. No two-step process. The user never chooses between "copy" and "capture" — ⌘⇧J does both.

- **With selection:** Copies selection to clipboard + captures to Jarie + grabs source metadata (URL, app name, page title)
- **Without selection:** Captures current clipboard contents (for things already copied). If clipboard is empty, opens manual capture popover.
- **Right-click:** Services → "Copy & Capture to Jarie" for mouse-heavy users
- **Technical:** Requires Accessibility permissions on macOS to read selections directly. Fallback to clipboard-only if denied.

**Example workflows:**
| Scenario | Action | What Jarie captures |
|---|---|---|
| Safari article — highlight a quote | Select text → ⌘⇧J | Quote text + page URL + page title + "Safari" |
| Safari article — want the whole URL | No selection needed, just ⌘⇧J | Clipboard contents OR frontmost tab URL + title |
| Apple Notes — highlight all text | Select all → ⌘⇧J | Full text + "Apple Notes" as source app |
| Slack message — grab a snippet | Select text → ⌘⇧J | Text + "Slack" as source app |
| X/Twitter in Chrome — save a tweet URL | Select URL → ⌘⇧J | URL + tweet text (if fetchable) + "Chrome" |

The hotkey isn't about saving bookmarks. It's about feeding your AI's memory in real time.

### Feature 2: Daily Digest

Every day, Jarie generates a concise digest of everything captured. Delivered in-app (inbox-style) and optionally via notification.

**Format:**
- One short summary per capture (1–2 sentences, AI-generated)
- Grouped by theme/topic (AI-detected, not manual)
- Date-stamped, reverse chronological
- Scannable in under 2 minutes

**Why it matters:** This is the habit-forming payoff. Users open it like email. It closes the loop between "I captured this" and "I got value from this." Without the digest, Jarie is a write-only black hole. With it, Jarie is a daily ritual.

**Minimum threshold:** Even 1 capture gets a digest — it's a daily log of what you consumed, not a newsletter. A 1-capture day produces a short entry. A 30-capture day produces a themed summary. The digest always fires.

**Output:** Appears in the Dashboard inbox AND is written to a `digest/` subfolder within the user's designated capture folder (e.g., `~/mind/collected/digest/YYYY-MM-DD.md`).

### Feature 3: AI Profile *(the moat)*

A living, condensed document about you, auto-generated and maintained from your captures over time. Designed to be short enough to paste into any LLM — even those with limited context windows — while being rich enough to give the AI genuine understanding of who you are.

**What it contains:**
- Who you are professionally (derived from capture patterns)
- Your current projects and focus areas
- Your recurring interests and intellectual obsessions (rolling all-time)
- The content you've been consuming lately (rolling 30 days)
- Your communication and thinking style preferences
- Your tools and workflow context

**Cold start:** Purely derived from captures — no onboarding questionnaire. Users who already have an `aboutme.md` or similar can paste/import it to seed the profile immediately. Otherwise, it builds organically as captures accumulate.

**How it updates:** Automatically. Every capture potentially refines the profile. No manual maintenance. The longer you use Jarie, the more accurate and useful it becomes.

**Length constraint:** Must stay condensed — short enough to fit in a single LLM system prompt (~2,000-3,000 tokens). As captures grow over months/years, the AI distills rather than appends. Quality over quantity.

**Prompted rewrite:** From any profile, tap "Rewrite for..." and describe the context — VC pitch, conference bio, cold email, system prompt. Jarie rewrites the profile through that lens without losing the underlying truth. Unlimited rewrites on BYOK tier; capped on AI-included tier (e.g., 10/month — TBD based on usage data).

**Storage:** Syncs via CloudKit if cloud sync is enabled. Available on all devices. If no cloud sync, local only with manual export as markdown or plain text.

**Why it's the moat:** This is the feature users will never want to rebuild. A year of captures = a genuinely accurate, deeply personalized AI context document. Impossible to replicate by hand. Gets stickier every week.

**The hero demo:** User is in a meeting. Someone asks about their background. They pull up their phone, tap "Copy AI Profile," paste it into ChatGPT. Instant, accurate context. No typing.

---

## 6. Value Proposition

```
CAPTURE SPEED    ×    DAILY SYNTHESIS    ×    PORTABLE AI MEMORY
(sub-2 second         (digest every             (AI Profile you
 global hotkey)        evening, auto)             own and control)
```

Jarie captures what you find in under two seconds, synthesizes it daily so nothing gets lost, and builds a living AI Profile that makes every LLM conversation smarter. Your content is yours in open markdown. No lock-in.

**Why pay when free tools exist:** Free tools don't synthesize. They don't build a profile. They make you do the work of turning captures into memory. Jarie does that work for you.

---

## 7. Competitive Landscape

| | **Jarie** | **Notion Clipper** | **Raindrop** | **Pocket** | **Apple Notes** |
|---|---|---|---|---|---|
| Capture speed | Sub-2 sec, no UI | Opens panel | Requires app open | Fast but siloed | Medium friction |
| Mac global hotkey | Yes | No | No | No | No |
| iOS share sheet | Yes | Yes | Yes | Yes | Yes |
| Output format | Markdown (open) | Notion-only | Proprietary | Proprietary | Apple Notes only |
| Daily digest | Auto-generated | No | No | No | No |
| AI Profile | Auto-generated, portable | No | No | No | No |
| Long-term AI memory | Yes | No | No | No | No |
| Price | $24.99/yr (BYOK) or $19.99/mo | Free (Notion sub req.) | Free/$28/yr | Free/$44.99/yr | Free |
| Lock-in | None | High | Medium | Medium | Medium |

**The gap:** No tool combines hotkey-speed capture + daily AI synthesis + portable AI Profile + open markdown output + cross-Apple platform. Everyone else makes you organize manually or locks you into their ecosystem. Jarie captures fast and builds memory automatically.

---

## 8. Design Philosophy

### Children's Creativity Museum Aesthetic
Bold, creative, artsy, minimal. Predominantly white with joyful pops of color. Like a modern children's museum — clean walls, bright accents, generous space. Not dark/corporate productivity. Not colorful chaos. White-dominant with carefully placed bursts of EasyBerry color.

### 5 Design Principles

1. **Invisible Until Needed** — Near-zero presence until summoned. Lives in the periphery (menu bar, share sheet). Vanishes when capture is done.
2. **Speed Is the Feature** — Every interaction < 2 seconds. No confirmation dialogs, no required tagging, no loading states.
3. **Native to the Bone** — SwiftUI, SF Pro, system behaviors. Feels like Apple made it.
4. **The Dashboard Earns Its Keep** — Capture is frictionless, but the dashboard + AI features justify the license. Generous white space, typography-forward, content first.
5. **Trust Through Consistency** — iCloud sync invisible and instant-feeling. User never wonders "did that save?"

---

## 9. Brand Identity

### Name
**Jarie** = jar + AI. You throw interesting things into the jar — AI keeps it tidy, labeled, findable, and turns it into memory.

### Color Palette (EasyBerry Family)

| Role | Color | Hex | Usage |
|---|---|---|---|
| Background | White | `#FFFFFF` | Dominant surface — 80%+ of UI |
| Text / Primary | Charcoal | `#39383A` | Body text, titles, navigation |
| Accent 1 | Teal | `#1CB6C5` | Primary actions, "Saved" toast, active states |
| Accent 2 | Pink | `#F2809D` | Favorites/stars, highlights |
| Accent 3 | Yellow | `#F9B114` | Warnings, badges, streak indicators |
| Accent 4 | Blue | `#75A4D8` | Links, source labels, secondary actions |
| Secondary text | Light gray | `#8B8FA8` | Timestamps, metadata, counts |
| Surface (dark mode) | Near-black | `#1A1A24` | Dark mode base |

**Rule:** White dominates. Colors appear as small accents — a teal checkmark, a pink star, a yellow badge. Never a colored background on a primary surface.

### App Icon Direction
A stylized jar or clip mark on a white or light background with teal accent. Rounded, modern, geometric. Should feel at home next to MoveBrush on an iPhone home screen. Not a dark icon — light and airy to match the museum aesthetic.

### Brand Personality
Jarie feels like a tool made by someone who uses it every day. It has warmth in its typography and lightness in how it confirms your actions. Creative, not corporate. An EasyBerry app — part of a family of tools that believe software should be joyful.

---

## 10. Mac Experience

### Menu Bar

**Icon:** Single-color template glyph (adapts to dark/light). Stylized clip/jar mark. 18x18px.

**Dropdown:**
```
┌─────────────────────────────────┐
│  Jarie                          │
│  ─────────────────────────────  │
│  Today: 12 captures             │
│  Last saved: "Claude now cre…"  │
│             — 4 min ago         │
│  ─────────────────────────────  │
│  [+ New Capture]   ⌘⇧J         │
│  ─────────────────────────────  │
│  Open Dashboard        ⌘⇧D     │
│  ─────────────────────────────  │
│  Settings...                    │
│  Quit Jarie                     │
└─────────────────────────────────┘
```

### Hotkey Capture Flow (⌘⇧J, configurable)

**Core principle:** ⌘⇧J replaces ⌘C for anything worth keeping. One keystroke copies to clipboard AND captures to Jarie. The user never has to choose between "copy" and "capture" — ⌘⇧J does both.

**With text/URL selected:**
1. User selects text, URL, or content in any app
2. Presses **⌘⇧J**
3. Jarie copies the selection to the system clipboard (same as ⌘C) AND captures it simultaneously
4. **Smart enrichment:** If in a browser → grab page URL + title via AppleScript. If in another app → record source app name. Whatever metadata is available, grab it.
5. Save to SwiftData + write markdown
6. Toast slides in from top-right:
```
┌──────────────────────────┐
│  ✓  Copied & Saved       │
│  Claude now creates in…  │
│  x.com/claudeai          │
└──────────────────────────┘
```
Toast: 1.8 seconds, fades out. Custom NSPanel overlay — not Notification Center. Non-interactive. Teal checkmark accent.

**With nothing selected:**
- If clipboard has content → capture clipboard contents (for when user already ⌘C'd something)
- If clipboard is empty → open manual capture popover (text field, Return to save, Escape to cancel)

**Technical note:** Capturing the selection (not the clipboard) requires Accessibility permissions on macOS. Jarie requests this on first launch. Fallback: if Accessibility is denied, ⌘⇧J reads the clipboard instead (user must ⌘C first, then ⌘⇧J).

### Right-Click Capture (Services Menu)
1. Select text/URL in any app
2. Right-click → Services → **"Copy & Capture to Jarie"**
3. Copies selection to clipboard + captures to Jarie + same toast

### Dashboard Window (⌘⇧D)

**Gmail/Outlook inbox style** — reverse chronological, rich metadata per row.

```
┌────────────┬──────────────────────────────────────────────────────┐
│            │                                                      │
│  SIDEBAR   │  INBOX                                               │
│            │                                                      │
│  Today     │  ★ Claude now creates interactive charts...          │
│  All       │    x.com/claudeai · Safari · 4:12 PM                │
│  ★ Starred │                                                      │
│  Digest    │  How foundation models are commoditizing             │
│            │    x.com/a16z · Safari · 2:40 PM                    │
│  SOURCES   │                                                      │
│  Safari    │  AMI Labs raised $1.03B for world models             │
│  Chrome    │    techcrunch.com · Chrome · 1:15 PM                 │
│  X/Twitter │                                                      │
│            │  ─── Yesterday ────────────────────                  │
│  LABELS    │                                                      │
│  🟢 social │  [more captures...]                                  │
│  🔵 tech   │                                                      │
│  🟡 idea   │                                                      │
│            │                                                      │
│  AI PROFILE│                                                      │
│  [View]    │                                                      │
└────────────┴──────────────────────────────────────────────────────┘
```

**Sidebar (~180px):**
- Smart views: Today, All, Starred, Digest
- Sources: auto-populated from captured domains
- Labels: auto-assigned by source domain + AI-detected topic. Color-coded with EasyBerry palette.
- AI Profile: link to profile view

**Inbox list (flexible):**
- Grouped by date ("Today", "Yesterday", "March 14")
- Each row: star toggle, title/content preview, source domain + favicon, source app, timestamp
- Row shows all available metadata from smart enrichment
- Hover: subtle background reveal, quick actions (star, delete)
- Keyboard: arrow keys navigate, Return opens detail, ⌘F for search

**Detail pane (320px, right):**
- Full content + all metadata
- "Open in Browser" / "Copy URL" / "Copy Text"
- Source, timestamp, capture method, platform

**Search:** ⌘F → searches title, URL, content simultaneously. Filters inline.

### Settings (tabbed)

| Tab | Contents |
|---|---|
| General | Launch at login, hotkey picker, show in Dock toggle |
| Account | Sign in status, tier, manage subscription (Stripe portal link) |
| Capture | Toast duration (1s/2s/3s/none), toast position |
| AI | API key configuration (BYOK), AI provider selection, digest schedule |
| Appearance | Accent color, list density (compact/comfortable), follow system dark/light |
| Export | Markdown folder picker, file naming preview |
| About | Version, changelog link, EasyBerry branding |

---

## 11. iPhone Experience

### Share Sheet (primary capture)
1. User in any app → tap Share → "Save to Jarie"
2. Compact extension UI:
```
┌─────────────────────────────────┐
│  Save to Jarie                  │
│  ─────────────────────────────  │
│  Claude now creates charts...   │  ← auto-fetched title
│  x.com/claudeai                 │  ← domain
│  ─────────────────────────────  │
│  [Cancel]              [Save]   │
└─────────────────────────────────┘
```
3. Save → haptic feedback (success) → extension dismisses
4. No notes field. Pure capture.

### Clipboard Detection
- On app foreground, detect clipboard content
- iOS 16+ shows paste permission prompt — handle gracefully
- Show banner at top: "Clipboard detected: [preview]" → [Save it] / [Dismiss]
- Auto-dismisses after 8 seconds
- Only prompted once per clipboard content

### Main App (3 tabs: Today / All / Search)

**Today:** Reverse chronological inbox. Each row: favicon, title, source + time. Swipe-left for star/delete. Tap opens half-sheet detail.

**All:** Same list, all captures. Section headers by date. Filter pills: All / URLs / Text / Starred.

**Search:** Inline search across title, URL, content. Results appear as you type.

### Widget
**Small (2x2):** Today's count (large number) + last capture time
**Medium (4x2):** Last 2 captures with titles and sources

---

## 12. iPad Experience

iPad is a **research companion**, not a bigger iPhone.

- **Layout:** Three-column split view (sidebar + list + detail) using UISplitViewController
- **Split View with Safari:** Jarie on right, browser on left. Captures appear in real-time as you research.
- **Keyboard support:** ⌘⇧J (capture), ⌘F (search), arrow keys, Return, ⌘Delete
- **Portrait:** Sidebar collapses, list + detail remain

---

## 13. Smart Enrichment

When a capture is saved, Jarie auto-fetches whatever metadata is available:

| Source | What's Fetched |
|---|---|
| Any URL | Page title, domain, favicon |
| YouTube URL | Video title, channel name |
| X/Twitter URL | Tweet text (if accessible) |
| Article URL | Title, publication name |
| Plain text | Source app name, URL from frontmost browser |

**Principle:** Grab whatever's available. Don't fail silently — if metadata can't be fetched, save what you have (the raw clipboard content + timestamp). Enrichment is best-effort, not blocking.

---

## 14. Organization

### Stars / Favorites
- Tap star on any capture to mark as favorite
- Filter by starred in sidebar (Mac) or filter pills (iOS)
- Star icon uses pink accent (#F2809D)

### AI-Powered Daily Digest
See Feature 2 (Section 5). Auto-generated each day. Grouped by theme. Delivered in Dashboard inbox + `digest/` subfolder.

### AI Profile
See Feature 3 (Section 5). Condensed, auto-updating. Promptable rewrite. CloudKit sync or local.

### AI-Powered Auto-Labels & Grouping
- Captures are auto-labeled by source domain/app AND by AI-detected topic/theme
- AI groups related captures (e.g., all captures about "foundation model pricing" cluster together)
- Labels are color-coded from the EasyBerry palette
- User can customize label colors and names in settings
- Labels appear in sidebar for filtering
- No manual tagging required — AI assigns and refines them over time

### Archive Behavior
- No explicit archive action
- Captures are always accessible via "All" view
- "Today" view shows today only — older captures scroll down naturally
- AI surfaces older captures when they become relevant to new ones

---

## 15. Account System

A Jarie account is the single identity that ties together Mac, iPhone, iPad, license, and subscription.

### Why an account is required
- **License portability:** User buys on easyberry.com, needs to activate on Mac + iOS + iPad with the same license
- **Subscription management:** AI-included tier ($19.99/mo) needs a persistent identity for billing
- **AI-included tier routing:** API calls for digest/profile need to authenticate against a paid subscription
- **BYOK tier:** Still needs an account to validate the $24.99/yr license, even though AI calls use the user's own keys

### Account flow
```
easyberry.com/jarie
     │
     ├── Sign up (email + password, or Sign in with Apple)
     ├── Choose tier: BYOK ($24.99/yr) or AI-included ($19.99/mo)
     ├── Payment via Stripe
     └── Account created → license key generated
                │
     ┌──────────┴──────────┐
     │                     │
  Mac App              iOS App
  (direct download)    (App Store, free)
     │                     │
  Sign in with         Sign in with
  email or SiwA        email or SiwA
     │                     │
  License validated    License validated
  Full features        Full features
  unlocked             unlocked
```

### Sign in with Apple (primary)
- Preferred auth method — no password to manage, native on all Apple devices
- Falls back to email + password for users who prefer it
- Account lives on Jarie backend (lightweight — auth + license + subscription status only)

### What the backend manages
| Concern | Backend | On-device |
|---|---|---|
| Auth / identity | Yes | Token cached locally |
| License validation | Yes (periodic check) | Offline grace period (7 days) |
| Subscription billing | Yes (Stripe) | Status cached locally |
| AI-included API calls | Yes (proxy to Claude/OpenAI) | N/A |
| Capture data | No — stays on device + iCloud | Yes (SwiftData + CloudKit) |
| Digest / profile data | No — generated on device or via API, stored locally | Yes |

**Key principle:** The account system manages identity, licensing, and AI-included API routing. It never touches capture data. Your content stays on your devices and in your iCloud.

### Backend infrastructure (lightweight)
- Auth: Supabase, Firebase Auth, or Clerk (managed, low-maintenance)
- Billing: Stripe (subscriptions + one-time yearly payments)
- AI proxy (AI-included tier only): Simple API gateway that validates subscription → forwards to Claude/OpenAI → returns response
- No database for user content — all content lives on-device via SwiftData/CloudKit

---

## 16. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        JARIE AI SYSTEM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │   MAC APP    │    │  iPhone/iPad │    │  SHARED LAYER    │  │
│  │ • Menu Bar   │    │ • Share Ext  │    │ • SwiftData      │  │
│  │ • Hotkey     │    │ • Widget     │    │ • CloudKit sync  │  │
│  │ • Services   │    │ • Clipboard  │    │ • Markdown gen   │  │
│  │ • Dashboard  │    │   detection  │    │ • Enrichment     │  │
│  │ • Sign in    │    │ • Sign in    │    │ • Search         │  │
│  └──────┬───────┘    └──────┬───────┘    │ • Account SDK    │  │
│         └──────────────┴─────────────────┴──────────────────┘  │
│                            │                                    │
│         ┌──────────────────┼──────────────────┐                 │
│         │                  │                  │                 │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────────┐     │
│  │ iCloud Drive  │  │ SwiftData +  │  │ Jarie Backend    │     │
│  │ /collected/   │  │ CloudKit     │  │ • Auth (SiwA)    │     │
│  │ /digest/      │  │ (offline-    │  │ • License check  │     │
│  │ /profile/     │  │  first)      │  │ • Stripe billing │     │
│  └───────────────┘  └──────────────┘  │ • AI proxy       │     │
│                                        │   (included tier)│     │
│                                        └─────────┬───────┘     │
│                                                  │              │
│                                        ┌─────────▼───────┐     │
│                                        │ Claude / OpenAI  │     │
│                                        │ API              │     │
│                                        └─────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

**Flow:** Capture hits SwiftData (instant, local) → CloudKit syncs in background → markdown written. AI features: BYOK calls APIs directly from device; AI-included routes through Jarie backend proxy.

---

## 17. Data Model

```swift
@Model
class Capture {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Content
    var text: String
    var sourceURL: String?
    var sourceDomain: String?         // "x.com" — derived, stored for perf
    var title: String?                // page title (auto-fetched)

    // Classification
    var captureType: CaptureType      // .text, .url, .image
    var tags: [String]                // auto-labels (flat array, no Tag entity in v1)
    var isFavorite: Bool

    // Metadata
    var capturedOnPlatform: String    // "mac", "iphone", "ipad"
    var captureMethod: CaptureMethod  // .hotkey, .shareSheet, .clipboard, .services, .manual
    var sourceApp: String?            // "Safari", "Chrome", "Arc"
    var enrichmentData: String?       // JSON blob for extra metadata (channel name, etc.)

    // AI synthesis
    var aiSummary: String?            // one-sentence AI summary (for daily digest)
    var digestIncluded: Bool          // whether this capture has been included in a digest

    // Markdown sync
    var markdownFilePath: String?
    var markdownWritten: Bool
}

@Model
class DailyDigest {
    var id: UUID
    var date: Date
    var summary: String               // full digest text (markdown)
    var captureIds: [UUID]            // captures included in this digest
    var generatedAt: Date
}

@Model
class AIProfile {
    var id: UUID
    var updatedAt: Date
    var fullText: String              // condensed profile (markdown, ~2000-3000 tokens)
    var lastCaptureCountAtGeneration: Int
    var versions: [AIProfileVersion]  // history of rewrites
}

@Model
class AIProfileVersion {
    var id: UUID
    var createdAt: Date
    var prompt: String?               // rewrite prompt if user-requested
    var text: String                  // version content
}

enum CaptureType: String, Codable { case text, url, image, file }
enum CaptureMethod: String, Codable { case hotkey, shareSheet, clipboard, services, manual, widget }
```

**Why flat tags, no Tag entity:** SwiftData relationships + CloudKit sync is complex. Flat array first. Promote to entity in v2 once sync is stable.

---

## 18. Tech Stack

**Client (Apple):**

| Layer | Choice | Why |
|---|---|---|
| Language | Swift 6 | Required for Apple ecosystem |
| UI | SwiftUI | One codebase, all platforms. Beginner-friendly |
| Data | SwiftData | Apple's modern ORM, built-in CloudKit bridge |
| Sync | NSPersistentCloudKitContainer | Automatic CloudKit sync via SwiftData |
| Hotkey (Mac) | `KeyboardShortcuts` (sindresorhus) | Free, sandboxed, SPM-compatible |
| Browser URL | AppleScript via `NSAppleScript` | Safari + Chrome + Arc. Most reliable |
| Services Menu | NSServices (Info.plist) | Native, no library needed |
| Share Extension | NSExtension target | App Groups for IPC |
| Search | SwiftData `#Predicate` | Good enough for v1 |
| Markdown write | FileManager + String actor | Dead simple + thread-safe |
| Min OS | macOS 14, iOS 17 | SwiftData stability baseline |
| Distribution | Mac: direct download. iOS: App Store (free, license unlock) | No sandbox restrictions on Mac; iOS reach via App Store |
| Dependencies | `KeyboardShortcuts` via SPM only | One dependency. Everything else Apple-native |

**Backend (lightweight):**

| Layer | Choice | Why |
|---|---|---|
| Auth | Supabase Auth or Clerk | Sign in with Apple + email. Managed, low-maintenance |
| Billing | Stripe | Subscriptions (monthly) + one-time (yearly). Industry standard |
| AI proxy | Cloudflare Worker or simple Express API | Validates subscription → forwards to LLM API → returns. Stateless |
| Hosting | Vercel, Railway, or Fly.io | Minimal infra. AI proxy is the only real endpoint |
| Database | Supabase Postgres (or Stripe-only) | Only stores: user ID, email, tier, subscription status. No content |

**AI layer:**
- BYOK: User configures API keys in Settings (Claude, OpenAI — TBD which to support at launch). Calls go directly from device.
- AI-included: Calls route through Jarie backend AI proxy. Backend validates subscription, forwards to Claude/OpenAI, returns response.
- On-device vs API: Start with API-based for v1. Evaluate Core ML for profile summarization in v2.

---

## 19. Project Structure

```
JarieCore/              (shared)
├── Models/Capture.swift, DailyDigest.swift, AIProfile.swift
├── Persistence/PersistenceController.swift
├── Markdown/MarkdownExporter.swift, DailyFileWriter.swift, MarkdownFileActor.swift
├── Enrichment/MetadataFetcher.swift
├── AI/DigestGenerator.swift, ProfileGenerator.swift, AIService.swift
├── Account/AccountManager.swift, LicenseValidator.swift
├── Utilities/URLExtractor.swift, DateFormatters.swift

JarieMac/               (Mac-specific)
├── App/JarieMacApp.swift
├── MenuBar/MenuBarController.swift, MenuBarView.swift
├── Hotkey/HotkeyManager.swift
├── BrowserURL/BrowserURLDetector.swift
├── Services/ServicesHandler.swift
├── Dashboard/DashboardWindow.swift, CaptureListView.swift, CaptureDetailView.swift
├── Profile/ProfileView.swift, ProfileRewriteView.swift
├── Auth/SignInView.swift

JarieiOS/               (iOS/iPadOS)
├── App/JarieApp.swift
├── Main/ContentView.swift, CaptureDetailView.swift
├── Profile/ProfileView.swift
├── Auth/SignInView.swift
├── ShareExtension/ShareViewController.swift, ShareView.swift   (SEPARATE TARGET)
├── Widget/JarieWidget.swift                                     (SEPARATE TARGET)
```

---

## 20. CloudKit Sync Strategy

```swift
let config = ModelConfiguration(
    schema: Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self]),
    cloudKitDatabase: .automatic
)
```

- **Conflict resolution:** Last-write-wins (captures are append-only, never edited)
- **Offline:** SwiftData writes locally immediately. Syncs when connectivity returns.
- **Migrations:** Always add new fields as `Optional`. Never rename fields.
- **Manual setup required:** Angel must configure CloudKit + Push Notifications in Xcode Signing & Capabilities

---

## 21. Markdown Export Pipeline

User designates a local folder for all output. Default: `~/mind/collected/`. All captures organized by date.

**Folder structure:**
```
~/mind/collected/              (user-configurable root)
├── 2026/03/2026-03-16.md      (daily captures)
├── 2026/03/2026-03-15.md
├── digest/                    (daily digests, separate subfolder)
│   ├── 2026-03-16.md
│   └── 2026-03-15.md
└── profile/                   (AI Profile, auto-updated)
    └── ai-profile.md
```

**iOS:** Writes to iCloud Drive container (`iCloud Drive/Jarie/collected/...`) with same structure.

**Mac:** Writes directly to configurable folder. Swift actor for concurrency protection.

**Daily capture file format:**
```markdown
# Collected — 2026-03-15

---
**4:12 PM** | x.com/claudeai
Claude now creates interactive charts directly in conversation — no code needed.

---
**2:40 PM** | x.com/a16z
"2026 is when foundation models commoditize fast. Value accrues at the app layer."

---
```

**Key principle:** Everything lands as markdown files in a folder the user controls. This is what makes Jarie a bridge to any system — Claude Code, Obsidian, Life OS — they just point at the folder.

---

## 22. Key Technical Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Accessibility permission required for direct selection capture | MEDIUM | Request on first launch with clear explanation. Fallback: clipboard-only mode if denied |
| Browser URL detection requires Automation permission | MEDIUM | Direct distribution (no sandbox), user grants permission on first run |
| iOS clipboard permission dialog (iOS 16+) feels jarring | MEDIUM | Only read on explicit "Capture Clipboard" button tap, not silently |
| Share Extension 120MB memory limit | MEDIUM | Text + URL only in v1. Defer images |
| Direct distribution requires notarization + code signing | MEDIUM | Set up Apple Developer notarization workflow; document steps |
| CloudKit entitlements require manual Xcode setup | MEDIUM | Document as checklist. Angel does steps 1–6 by hand |
| Account system adds onboarding friction | MEDIUM | Sign in with Apple = one tap. Frame as "activate your license" |
| AI costs on AI-included tier | LOW | ~$0.40/user/month, 98% gross margin. Not a constraint |
| Markdown concurrent write corruption | LOW | Use Swift actor |

---

## 23. Pricing Strategy

**Distribution:**
- **Mac:** Direct download from easyberry.com. License key required.
- **iOS/iPad:** App Store (free download), but requires a license purchased on easyberry.com to unlock full features.
- YouTube videos sell the Mac experience; iOS users are driven to the website for license purchase.

| Tier | Price | What's included |
|---|---|---|
| **Jarie Pro (BYOK)** | $24.99/year | Full capture + AI features (digest, AI Profile), user provides own API keys |
| **Jarie Pro + AI** | $19.99/month | Everything above + AI built in, no API keys needed |

**Who buys BYOK:** AI power users (developers, Claude Code users) who already have API keys. $24.99/yr is an impulse buy. They're paying for the convenience — an app that captures fast, organizes automatically, and builds an AI Profile they can use anywhere. That's the value, not the AI inference.

**Who buys AI-included:** White-collar knowledge workers and content creators who don't want to manage API keys. $19.99/mo is justified by the daily synthesis and AI Profile value — effectively a personal AI assistant for $20/mo.

### API Cost Model (AI-Included Tier)

Using Claude Haiku 4.5 for digest (summarization) and Claude Sonnet for profile generation:

| Component | Per-call cost | Frequency | Monthly cost |
|---|---|---|---|
| Daily Digest | ~$0.007 | 30x/month | $0.21 |
| AI Profile generation | ~$0.03 | 4x/month (weekly) | $0.13 |
| Profile rewrites | ~$0.03 | ~2x/month avg | $0.06 |
| **Total per user/month** | | | **~$0.40** |

**Margin:** At $19.99/month, API cost is ~$0.40/user → **98% gross margin on LLM costs.** At 1,000 AI-included users, total monthly API spend is ~$400. The real costs are infrastructure, payment processing, and Apple's 30% cut on iOS.

**Note:** GPT-4o-mini for digest would drop cost to ~$0.16/user/month. Prompt caching (Anthropic offers up to 90% savings on repeated system prompts) would reduce further.

### Usage Limits (AI-Included Tier)
- Daily digest: unlimited (1/day, auto)
- AI Profile generation: weekly (auto) + on-demand (capped at ~4 additional/month)
- Profile rewrites: capped (e.g., 10/month — TBD based on usage data)
- BYOK tier: no limits (user's own API bill)

**Revenue math:**
- BYOK: 1,000 users x $24.99/yr = $24,990/yr
- AI-included: 200 users x $19.99/mo = $47,976/yr
- Blend target: ~$73K ARR at scale
- No free tier. No trial. YouTube demo + website landing page do the convincing.

---

## 24. Go-to-Market

### The YouTube Origin Story (primary channel)
Video concept: *"I built an AI that remembers everything I read"* — demo Jarie capturing across devices throughout a day, then the evening digest, then the AI Profile in action (paste into Claude for instant context). Show the before (lost context, 47 tabs) and after (one paste, Claude knows everything). **YouTube sells the Mac app. Mac users become license buyers.**

### Distribution Flow
```
YouTube video → viewer sees Mac demo → downloads from easyberry.com → purchases license
                                     → also gets iOS app from App Store (free, license unlocks)
```

### First 100 Users (0–30 days)
1. YouTube origin story video with Jarie as the product being built live
2. Product Hunt launch: target top-5 Productivity
3. Indie Hackers: "I built a $25 app that gives your AI a memory"
4. Personal network: 10 DMs to YC + Meta contacts
5. Landing page on easyberry.com/jarie: demo video, AI Profile demo as hero moment

### First 1,000 Users (30–180 days)
```
YouTube video → viewer downloads Jarie → uses Jarie to capture content
     ↑                                                    ↓
Angel captures comments via Jarie              viewer shares AI Profile demo
     ↑                                                    ↓
     └──────────── new video ideas ←───────────────────────┘
```

The AI Profile is inherently shareable — users will post screenshots of their profile being used in a ChatGPT or Claude conversation. That's organic social proof that's hard to engineer.

- Monthly workflow demo videos (not feature demos)
- Reddit: r/productivity, r/MacApps, r/workflow — genuine contribution posts
- Cross-promotion with 3–5 indie tool makers
- SEO on easyberry.com/jarie: "Jarie — Fast Capture for Mac & iOS"

---

## 25. Risk Assessment

### Risk 1: iOS Constraints Kill Core UX
Share sheet = 3 taps, not 1 hotkey.
**Mitigation:** Over-invest in Mac experience first. iOS is a companion. The daily digest and AI Profile work best on desktop anyway.

### Risk 2: AI Costs Eat the AI-Included Tier
Heavy users with 50+ captures/day could make the $19.99/mo tier unprofitable.
**Mitigation:** Monitor cost per user in first 90 days. Soft cap on digest length (max N captures per digest). AI Profile regeneration is weekly, not real-time. Current model shows 98% margin even with heavy usage.

### Risk 3: Larger Player Ships This
Apple could build memory into Siri. Notion could add a daily digest.
**Mitigation:** Moat is the AI Profile — a year of captures = genuine, irreplaceable personal context. Plus Angel's audience trusts her workflow. Stories are harder to copy than features.

### Risk 4: Account System Adds Friction
Users have to create an account before they can use the app. That's a barrier.
**Mitigation:** Sign in with Apple makes it one tap. No forms, no passwords. Frame sign-in as "activate your license" not "create an account."

### Risk 5: Market Too Niche
Power users are a small market.
**Mitigation:** YouTube IS the distribution. The AI-included tier ($19.99/mo) has a much broader addressable audience once the AI Profile use case is demonstrated.

---

## 26. Success Metrics

### The One Metric That Matters
**Captures per active user per day.** Above 5 = habit formed. Below 2 = activation problem.

### Health (weekly)
| Metric | 30-day target | 90-day target |
|---|---|---|
| Paying customers | 100 | 500 |
| ARR run rate | $5K | $25K |
| Crash-free rate | >99% | >99.5% |
| Support tickets | <10/week | <10/week |

### Engagement (monthly)
| Metric | 90-day target |
|---|---|
| Captures/active user/day | 5+ |
| 30-day retention | >40% |
| Power users (10+/day) | >50 |
| Daily digest open rate | >60% |
| AI Profile copy events/week/user | 3+ |

### Leading Indicators (first 30 days)
- YouTube comments asking "where do I download this?"
- Organic social mentions of Jarie-powered workflows
- Social shares featuring AI Profile in use
- Early users asking about roadmap / upcoming features

---

## 27. MVP Scope — Mac First

### Phase 0: Project Setup (Day 1–2, MANUAL)
Angel does these in Xcode. Claude Code cannot.
1. Create Xcode "Multiplatform App" project: `JarieAI`, `com.easyberry.jarie`
2. Signing & Capabilities: add iCloud, enable CloudKit, create container `iCloud.com.easyberry.jarie`
3. Add Push Notifications (required for CloudKit sync)
4. Add `sindresorhus/KeyboardShortcuts` via SPM
5. Create App Group: `group.com.easyberry.jarie`
6. Sign in with Apple capability

### Phase 1: Data Foundation + Account System (Week 1–2)
- SwiftData models: `Capture`, `DailyDigest`, `AIProfile`, `AIProfileVersion`
- `PersistenceController` (CloudKit container)
- `MarkdownExporter` + `DailyFileWriter` + `MarkdownFileActor`
- `MetadataFetcher` (URL title resolution)
- `CaptureService` (wraps save + markdown + enrichment)
- **Backend:** Supabase/Clerk auth + Stripe billing integration
- **Account SDK:** Sign in with Apple / email auth in shared layer
- **License validation:** Periodic check with offline grace period (7 days)
- **AI proxy endpoint:** Stateless endpoint that validates subscription → forwards to LLM API

**Checkpoint:** Can create Capture, it persists in SwiftData, markdown written. Account sign-in works.

### Phase 2: Mac App (Week 3)
- Menu bar icon + popover
- Global hotkey via KeyboardShortcuts (⌘⇧J = copy + capture)
- BrowserURLDetector (AppleScript for Safari + Chrome)
- Toast notification on save ("Copied & Saved")
- Dashboard window with inbox-style list + search
- Sign-in screen on first launch → license validation → unlock

**Checkpoint:** ⌘⇧J → copy + capture → enrichment → toast → markdown. Full Mac flow working.

### Phase 3: iOS App (Week 4)
- Main app: inbox list + detail
- Explicit clipboard capture button
- Share Extension (Angel creates target in Xcode, Claude writes code)
- App Group shared container
- App Store free download → sign-in → license validation → unlock

**Checkpoint:** Share Sheet from Safari → saves → appears on Mac after sync.

### Phase 4: Sync Verification (Week 5)
Real hardware only. Simulators don't sync CloudKit reliably.
- Mac → iPhone sync
- iPhone → Mac sync
- Offline → sync on reconnect
- Markdown files appear in correct locations
- License status syncs across devices via account

### Phase 5: Daily Digest (Week 6)
- Background job: collect day's captures → call AI → generate digest → store as `DailyDigest`
- Dashboard: new "Digest" tab showing daily summaries
- Markdown export to `digest/` subfolder
- Notification: optional evening push

**Checkpoint:** End of day → digest auto-generates → readable in dashboard + markdown folder.

### Phase 6: AI Profile (Week 7)
- Background job: weekly profile generation from all captures → store as `AIProfile`
- Profile view: full text, copy button, "Rewrite for..." prompt input
- Export: write to `profile/ai-profile.md`
- Import: paste existing aboutme.md to seed profile

**Checkpoint:** After 1+ week of captures → profile generated → copy → paste into Claude → instant context.

### Phase 7: Polish (Week 8–9)
- Services Menu registration ("Copy & Capture to Jarie")
- Settings panel (all tabs)
- Stars/favorites
- Auto-labels by domain + AI topic detection
- Onboarding, empty states
- App icon + launch screen
- Stripe customer portal link in settings

### Deferred to v1.1+
| Feature | Why Defer |
|---|---|
| iPad-specific split view | Ship universal iOS first, optimize later |
| Widget | Separate target, adds complexity |
| Safari iOS Extension | High complexity, low value over Share Sheet |
| Image capture | Memory limits, storage complexity |
| Custom label names | Auto-labels sufficient for v1 |
| On-device AI (Core ML) | Start with API, evaluate later |
| Profile version history UI | Store versions from day 1, build UI later |
| Scheduled digest delivery | Manual/auto in v1, custom timing in v1.1 |
| "Send to Claude" button | Nice-to-have, not core |
| App Store for Mac | Revisit if/when transitioning to subscription |
| Spotlight integration | SwiftData search sufficient |

---

## 28. Open Questions

- Which AI providers to support for BYOK at launch? (Claude only first? Claude + OpenAI?)
- Should AI Profile have a "public link" sharing option (like a Linktree for your AI context)?
- Exact rewrite cap number for AI-included tier (10/month? 20?)
- Should captures have an expiry concept (auto-archive after 30/90 days)?
- Should the markdown format match the existing Life OS `collected/` format exactly?
- On-device AI (Core ML) vs API vs hybrid for digest + profile generation in v2?
- Should AI-generated summaries/tags be editable by the user?
- At what capture count does AI Profile become meaningfully accurate? (30 days? 100 captures?)
- Auth provider: Supabase Auth vs Clerk vs Firebase Auth? (cost, DX, Sign in with Apple support)
- Should there be a free tier at all? (e.g., capture-only, no AI features, 30-day trial?)
- What does the app look like before sign-in? (locked screen with demo? or limited free mode?)

---

## 29. Manual Checklist (Things Claude Code Cannot Do)

**Xcode / Apple:**
1. ☐ Xcode project creation
2. ☐ CloudKit container setup in Apple Developer portal
3. ☐ All Signing & Capabilities configuration
4. ☐ Adding Share Extension target
5. ☐ Adding Widget target (when ready)
6. ☐ Sign in with Apple capability + configuration
7. ☐ Real device testing for CloudKit sync
8. ☐ AppleScript permission approval on first Mac run
9. ☐ Code signing + notarization for direct Mac distribution
10. ☐ App Store Connect setup for iOS (free app, license unlock)
11. ☐ TestFlight for beta testing

**Backend / Infra:**
12. ☐ Supabase or Clerk project setup (auth)
13. ☐ Stripe account + products (BYOK yearly, AI-included monthly)
14. ☐ AI proxy endpoint (Cloudflare Worker / Vercel function)
15. ☐ License validation API endpoint
16. ☐ Stripe customer portal configuration

**Website / Marketing:**
17. ☐ Landing page on easyberry.com/jarie
18. ☐ Stripe checkout integration on website
19. ☐ Download page + demo video
20. ☐ App icon design (final asset)

---

*This brief is the source of truth. Update it as decisions change.*
*Last updated: 2026-03-16.*
