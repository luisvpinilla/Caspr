# Caspr — Invisible Meeting Recorder for macOS

## What is Caspr?

Caspr is a native macOS application for audio recording and transcription. Named after Casper the Friendly Ghost, the app is **completely invisible during screen sharing** — perfect for capturing meeting audio and generating transcripts and summaries using AI.

Caspr runs silently in the menu bar, records system audio and/or microphone input, and delivers transcripts and structured meeting summaries. It uses a **freemium model**: free users get local on-device transcription, paid users unlock cloud transcription (higher accuracy), AI-powered summaries, cloud storage, and cross-device sync.

## Core Principles

1. **Ghost Mode is non-negotiable** — The app must never appear in screen shares, screen recordings, or window pickers. This is the product's entire reason to exist. Every UI decision must preserve invisibility.
2. **Freemium that's genuinely useful** — The free tier is a real product, not a crippled demo. Local transcription works fully offline. Paid features are additive, not gated basics.
3. **Privacy by design** — Audio is captured locally. Free tier never touches the network. Paid tier uploads audio over TLS to our backend for processing, then deletes the audio after transcription. Users always know what goes where.
4. **macOS-native feel** — SwiftUI, SF Symbols, system fonts, respects Dark Mode and accessibility. No Electron, no web views, no cross-platform compromise.
5. **Commercial from day one** — Architecture supports subscriptions, team plans, usage tracking, and analytics from the start. No "bolt it on later" technical debt.

## Business Model

### Free Tier
- Unlimited local recordings
- Local transcription via WhisperKit (on-device, offline)
- Local storage only (SwiftData/SQLite)
- No account required
- No AI summaries
- No cloud sync

### Pro Tier ($12/month or $99/year)
- Everything in Free
- Cloud transcription via Deepgram (higher accuracy, speaker labels)
- AI-powered meeting summaries (decisions, action items, follow-ups)
- Cloud storage and recording history (Supabase)
- Export to Notion, Markdown, PDF
- Priority transcription queue
- 10 hours/month of cloud transcription

### Team Tier ($25/user/month) — Future
- Everything in Pro
- Shared meeting library
- Team action item tracking
- Admin dashboard
- SSO integration
- Unlimited cloud transcription

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| **macOS App** | SwiftUI + AppKit | Menu bar app + floating panel (NSPanel) |
| **Audio Capture** | AVFoundation / ScreenCaptureKit | System audio + mic. ScreenCaptureKit for loopback audio on macOS 13+ |
| **Local Transcription** | WhisperKit | On-device, offline. Free tier. |
| **Cloud Transcription** | Deepgram API | Server-side via Supabase Edge Function. Pro tier. |
| **AI Summarisation** | Claude API (claude-sonnet-4-5-20250929) | Server-side via Supabase Edge Function. Pro tier. |
| **Backend** | Supabase | Auth, PostgreSQL database, Edge Functions, Storage (audio files) |
| **Payments** | Stripe | Subscriptions with Stripe Checkout + Customer Portal |
| **Local Storage** | SwiftData | SQLite for offline recordings and local transcripts |
| **Audio Format** | CAF → M4A (AAC) | CAF for lossless capture, M4A for storage/export/upload |
| **Networking** | URLSession | API calls to Supabase backend |
| **Distribution** | Direct download (DMG) → Mac App Store later | Sandbox considerations for audio permissions |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   macOS App (Caspr)                      │
│                                                         │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Audio    │  │  WhisperKit  │  │  SwiftData       │  │
│  │  Capture  │  │  (Local      │  │  (Local DB)      │  │
│  │  Service  │  │  Transcript) │  │                  │  │
│  └─────┬────┘  └──────┬───────┘  └────────┬─────────┘  │
│        │              │                    │            │
│        │    FREE TIER │ (all offline)      │            │
│  ──────┼──────────────┼────────────────────┼──────────  │
│        │     PRO TIER │ (cloud features)   │            │
│        │              │                    │            │
│  ┌─────▼──────────────▼────────────────────▼─────────┐  │
│  │              Supabase Client SDK                   │  │
│  │         (Auth · Storage · Database · RPC)          │  │
│  └───────────────────────┬───────────────────────────┘  │
└──────────────────────────┼──────────────────────────────┘
                           │ HTTPS
                           ▼
┌──────────────────────────────────────────────────────────┐
│                  Supabase Backend                         │
│                                                          │
│  ┌──────────┐  ┌────────────┐  ┌──────────────────────┐ │
│  │  Auth     │  │  Storage   │  │  PostgreSQL          │ │
│  │  (email,  │  │  (audio    │  │  (recordings,        │ │
│  │  Google,  │  │  files)    │  │  transcripts,        │ │
│  │  Apple)   │  │            │  │  summaries, users)   │ │
│  └──────────┘  └─────┬──────┘  └──────────────────────┘ │
│                      │                                   │
│  ┌───────────────────▼───────────────────────────────┐  │
│  │              Edge Functions                        │  │
│  │                                                    │  │
│  │  transcribe/  → Deepgram API → save transcript     │  │
│  │  summarise/   → Claude API → save summary          │  │
│  │  webhook/     → Stripe webhook handler             │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Stripe (Payments)                      │  │
│  │  Checkout · Subscriptions · Customer Portal        │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## macOS App Structure

```
Caspr/
├── CasprApp.swift                  # App entry point, menu bar setup
├── Models/
│   ├── Recording.swift             # SwiftData model for recordings
│   ├── Transcript.swift            # SwiftData model for transcripts
│   ├── Summary.swift               # SwiftData model for AI summaries
│   └── UserProfile.swift           # Local user/subscription state
├── Services/
│   ├── AudioCaptureService.swift   # AVFoundation / ScreenCaptureKit audio recording
│   ├── LocalTranscriptionService.swift  # WhisperKit (free tier)
│   ├── CloudTranscriptionService.swift  # Calls Supabase Edge Function (pro tier)
│   ├── SummarisationService.swift  # Calls Supabase Edge Function (pro tier)
│   ├── GhostModeService.swift      # Window-level management for screen share invisibility
│   ├── AuthService.swift           # Supabase Auth wrapper
│   ├── SyncService.swift           # Upload/download recordings and transcripts
│   ├── SubscriptionService.swift   # Stripe subscription state management
│   └── HotkeyService.swift         # Global keyboard shortcuts
├── Views/
│   ├── MenuBarView.swift           # NSStatusItem menu bar interface
│   ├── RecordingPanel.swift        # Floating NSPanel (ghost mode compatible)
│   ├── TranscriptView.swift        # Full transcript viewer/editor
│   ├── SummaryView.swift           # AI-generated summary display
│   ├── RecordingListView.swift     # History of past recordings
│   ├── SettingsView.swift          # Preferences (audio, AI, account, billing)
│   ├── AuthView.swift              # Sign in / sign up (for Pro features)
│   ├── PaywallView.swift           # Upgrade prompt for Pro features
│   └── OnboardingView.swift        # First-launch walkthrough
├── Utilities/
│   ├── AudioLevelMonitor.swift     # Real-time audio level metering
│   ├── TimestampFormatter.swift    # Formatting utilities
│   ├── ExportManager.swift         # Export to markdown, PDF, clipboard
│   └── TierGate.swift              # Helper to check free vs pro feature access
├── Resources/
│   ├── Assets.xcassets             # App icon, menu bar icons
│   └── Caspr.entitlements          # Audio, microphone, network permissions
└── Tests/
    ├── AudioCaptureTests.swift
    ├── TranscriptionTests.swift
    └── SummarisationTests.swift
```

## Supabase Backend Structure

```
supabase/
├── migrations/
│   ├── 001_initial_schema.sql      # Users, recordings, transcripts, summaries tables
│   ├── 002_rls_policies.sql        # Row Level Security (users see only their data)
│   └── 003_stripe_tables.sql       # Subscription and billing tables
├── functions/
│   ├── transcribe/index.ts         # Receive audio → call Deepgram → save transcript
│   ├── summarise/index.ts          # Receive transcript → call Claude → save summary
│   ├── stripe-webhook/index.ts     # Handle Stripe subscription events
│   └── create-checkout/index.ts    # Create Stripe Checkout session for upgrade
└── seed.sql                        # Test data for development
```

## Database Schema (Supabase PostgreSQL)

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'team')),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  cloud_minutes_used INTEGER DEFAULT 0,
  cloud_minutes_limit INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Recordings
CREATE TABLE public.recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles NOT NULL,
  title TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  audio_storage_path TEXT,
  is_cloud_synced BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Transcripts
CREATE TABLE public.transcripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID REFERENCES public.recordings NOT NULL,
  full_text TEXT NOT NULL,
  segments JSONB,
  source TEXT NOT NULL CHECK (source IN ('local', 'cloud')),
  language TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Summaries
CREATE TABLE public.summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID REFERENCES public.recordings NOT NULL,
  overview TEXT NOT NULL,
  decisions JSONB,
  action_items JSONB,
  follow_ups JSONB,
  parking_lot JSONB,
  model TEXT DEFAULT 'claude-sonnet-4-5-20250929',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own recordings"
  ON public.recordings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users see own transcripts"
  ON public.transcripts FOR ALL
  USING (recording_id IN (
    SELECT id FROM public.recordings WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users see own summaries"
  ON public.summaries FOR ALL
  USING (recording_id IN (
    SELECT id FROM public.recordings WHERE user_id = auth.uid()
  ));
```

## Ghost Mode — Technical Implementation

### How it works on macOS:

1. **NSPanel with `.nonactivatingPanel` style** — Panels with this style mask are excluded from screen capture by default on macOS.
2. **`window.sharingType = .none`** — Setting `sharingType` to `.none` on any `NSWindow` excludes it from screen sharing and screen recording APIs.
3. **`window.level = .floating`** — Keeps the panel above other windows but below screen capture overlays.
4. **Menu bar icon** — `NSStatusItem` is inherently invisible in screen shares (it's part of the system UI, not the app's window list).
5. **No Dock icon** — Set `LSUIElement = true` in Info.plist. The app runs as an agent (menu bar only, no Dock presence).

### What to test:
- Start a Zoom/Teams/Meet screen share → Caspr panel must NOT appear
- Use macOS Screenshot (⌘⇧5) → Caspr must NOT appear in window picker
- Use QuickTime screen recording → Caspr must NOT appear
- Use OBS window/display capture → Caspr must NOT appear

## AI Summarisation Prompt Strategy

When the Supabase Edge Function sends transcripts to the Claude API:

```
You are summarising a meeting transcript. Extract:

1. **Meeting Summary** — 3-5 sentence overview of what was discussed
2. **Key Decisions** — Bullet list of decisions made (with who decided if clear)
3. **Action Items** — Bullet list with [Owner] and [Due date if mentioned]
4. **Follow-ups** — Topics that need further discussion
5. **Parking Lot** — Ideas or topics raised but intentionally deferred

Keep language concise and professional. Use Australian English spelling.
Preserve speaker names/labels if present in the transcript.
```

## Tier Gating Logic

```swift
enum Feature {
    case cloudTranscription
    case aiSummaries
    case cloudSync
    case systemAudioCapture
    case exportNotion
    case exportPDF
}

func isAvailable(_ feature: Feature) -> Bool {
    switch feature {
    case .cloudTranscription, .aiSummaries, .cloudSync,
         .systemAudioCapture, .exportNotion, .exportPDF:
        return currentUser?.tier == .pro || currentUser?.tier == .team
    }
}
// When a free user taps a pro feature, show PaywallView
// NEVER block the core recording + local transcription flow
```

## Key Behaviours

- **Recording indicator**: Subtle pulsing dot on menu bar icon (visible only to the user, not in screen shares)
- **Auto-pause**: Detect when no audio input for 60+ seconds, auto-pause and resume
- **Hotkey**: Global shortcut (default: ⌥⌘R) to start/stop recording from anywhere
- **Auto-transcribe**: Begin local transcription immediately when recording stops (free). Upload for cloud transcription if Pro.
- **Auto-summarise**: Send transcript to cloud for AI summary (Pro only, with user toggle)
- **Export**: Copy summary to clipboard, export as Markdown, export as PDF (PDF is Pro)
- **Retention**: Local recordings kept for 30 days by default, configurable. Cloud recordings persist while subscribed.
- **Offline resilience**: If Pro user is offline, fall back to local transcription. Queue cloud upload for when connectivity returns.

## Environment Variables

### macOS App (.env — gitignored, or stored in Keychain)
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

### Supabase Edge Functions (.env in Supabase dashboard)
```
DEEPGRAM_API_KEY=...
ANTHROPIC_API_KEY=sk-ant-...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Note: API keys for Deepgram, Claude, and Stripe live on the SERVER only. The macOS app never holds these keys. It only holds the Supabase anon key, which is safe to ship because RLS protects the data.

## Phases

### Phase 1: Ghost Shell (Free tier MVP)
- Menu bar app skeleton (SwiftUI + NSStatusItem)
- NSPanel with ghost mode (sharingType = .none)
- Basic start/stop recording UI
- Audio capture (microphone only via AVFoundation)
- Save recordings to local SwiftData storage

### Phase 2: Local Transcription (Free tier complete)
- Integrate WhisperKit for local on-device transcription
- Transcript viewer with timestamps
- Search within transcripts
- Copy/export transcript as Markdown
- This completes the free tier

### Phase 3: Supabase Backend
- Set up Supabase project (auth, database, storage, edge functions)
- Database migrations
- Auth flow in the app (sign up, sign in, sign out)
- Edge Function: transcribe/ (Deepgram)
- Edge Function: summarise/ (Claude API)
- Audio upload to Supabase Storage

### Phase 4: Pro Features
- Cloud transcription flow
- AI summary generation
- Summary viewer
- Cloud sync
- Usage tracking
- Paywall view

### Phase 5: Payments (Stripe)
- Checkout session creation
- Webhook handler for subscription events
- Customer portal
- Tier enforcement

### Phase 6: Power Features
- System audio capture via ScreenCaptureKit
- Speaker diarisation (Deepgram)
- Global hotkeys
- Auto-pause on silence
- Calendar integration
- Export to Notion, PDF

### Phase 7: Polish & Distribution
- App icon and branding
- Onboarding flow
- Auto-update (Sparkle)
- DMG packaging and notarisation
- Landing page
- Analytics
- Mac App Store submission

## Brand

- **Name**: Caspr
- **Tagline**: "Your friendly invisible recorder"
- **Personality**: Friendly, invisible, trustworthy, effortless
- **Icon direction**: Ghost silhouette or translucent/glass aesthetic — friendly, not spooky
- **Colour palette**: TBD

## Build & Run

```bash
git clone https://github.com/luisvpinilla/caspr.git
cd caspr
open Caspr.xcodeproj
# ⌘R in Xcode
```

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 16+
- Swift 6.0+
- Apple Developer account
- Supabase project (for cloud features)
- Stripe account (for payments)
