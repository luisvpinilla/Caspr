# Caspr — Claude Code Build Prompts

> Paste these prompts into Claude Code sequentially. Each builds on the previous.
> Before each session, start with: "Read CLAUDE.md and DESIGN_SYSTEM.md and tell me where we're at."

---

## 🔧 Phase 0: Project Scaffolding

### Prompt 0.1 — Create the Xcode project

```
Create a new macOS app project called "Caspr" in this directory using Swift and SwiftUI.
Set it up as a menu bar app (LSUIElement = true in Info.plist, no Dock icon).
Use SwiftData for local persistence.
Minimum deployment target: macOS 14.0.
Create the folder structure from CLAUDE.md including the Components/ directory:
  Models, Services, Views, Components, Utilities, Resources, Tests
Add a basic NSStatusItem with a ghost icon (use SF Symbol "waveform" as placeholder).
Add the entitlements file with:
  - com.apple.security.device.audio-input (microphone)
  - com.apple.security.network.client (for API calls)
Set the bundle identifier to com.luisvpinilla.caspr.
Create DesignTokens.swift in Utilities/ with all colour constants from DESIGN_SYSTEM.md
(bgApp, bgPanel, bgSurface, textPrimary, textSecondary, ledRecording, speaker colours, etc).
Include a Color(hex:) extension for hex string initialisation.
```

### Prompt 0.2 — Add Swift Package dependencies

```
Add the following Swift Package dependencies to the Xcode project:
1. WhisperKit (https://github.com/argmaxinc/WhisperKit) — local transcription
2. KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts) — global hotkeys
3. Supabase Swift SDK (https://github.com/supabase/supabase-swift) — auth, database, storage
4. Sparkle (https://github.com/sparkle-project/Sparkle) — auto-updates (configure later)

Don't integrate them into views yet — just add the packages so they resolve and compile.
```

---

## 👻 Phase 1: Ghost Shell (Free Tier MVP)

### Prompt 1.1 — Menu bar popover

```
Read DESIGN_SYSTEM.md before building.

Build the menu bar interface for Caspr following the Hardware Industrial design system.

NSStatusItem icon: SF Symbol "waveform" (default), "waveform.circle.fill" (recording).
Clicking opens a popover (NOT a dropdown menu) styled per DESIGN_SYSTEM.md:
  - Glassmorphism background (bgPanel at 92% opacity + ultraThinMaterial + noise overlay)
  - 1px borderSubtle, 12px corner radius
  - App title "CASPR" in display style (SF Pro Display, 12px, semibold, tracking 0.2em, uppercase)
  - LED StatusBadgeView: STANDBY (grey) or RECORDING (red with pulsing LED dot)
  - Timer: SF Mono 28px light weight, monospacedDigit()
  - Large circular RecordButton (56px): bgSurface when idle, ledRecording with glow when recording
  - Compact LevelMeterView showing mic input level (segmented bar, green→yellow→red)
  - "Recordings" button → opens main window
  - Gear icon → Settings
  - "Quit Caspr" at bottom
  - Width: ~280px, auto-height

Use DesignTokens.swift for all colours. Popover dismisses on click outside.
Create LEDIndicatorView and StatusBadgeView in Components/.
```

### Prompt 1.2 — Ghost Mode panel

```
Read DESIGN_SYSTEM.md for styling.

Create GhostModeService and a floating RecordingPanel.

RecordingPanel is an NSPanel (not NSWindow) with:
- styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView]
- sharingType = .none (CRITICAL — excludes from screen sharing)
- level = .floating
- isMovableByWindowBackground = true
- titlebarAppearsTransparent = true
- backgroundColor = .clear
- collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]
- hidesOnDeactivate = false

Panel content (glassmorphism background per DESIGN_SYSTEM.md):
- Timer (SF Mono, monospacedDigit)
- Pulsing red LED dot (6px, glow shadow, 2s pulse)
- Compact segmented level meter
- Stop button (ledRecording accent)
- Drag handle area

Optional — toggled in Settings. Menu bar popover is the primary interface.
The main RecordingListView window does NOT use ghost mode.
```

### Prompt 1.3 — Audio capture service

```
Build AudioCaptureService using AVFoundation's AVAudioEngine.

- Capture from default input device (microphone)
- Save to CAF during recording (lossless), convert to M4A (AAC 128kbps) on stop
- Expose Combine publisher for real-time audio levels (RMS, 0.0–1.0)
- Methods: start(), stop(), pause(), resume()
- Request microphone permission on first use with friendly explanation
- Store recordings in: ~/Library/Application Support/Caspr/Recordings/
- File naming: caspr_YYYY-MM-DD_HH-mm-ss.m4a
- Handle mic permission denied with clear message pointing to System Settings
```

### Prompt 1.4 — Data models

```
Create SwiftData models:

Recording:
- id: UUID, title: String (default "Recording — {date}"), createdAt: Date
- duration: TimeInterval, audioFileURL: URL
- transcript: Transcript? (relationship), summary: Summary? (relationship)
- isCloudSynced: Bool (default false)

Transcript:
- id: UUID, createdAt: Date, fullText: String
- segments: [TranscriptSegment] (Codable JSON: startTime, endTime, text, speaker, confidence)
- source: String ("local" or "cloud")
- recording: Recording (inverse)

Summary:
- id: UUID, createdAt: Date, overview: String
- decisions: [String], actionItems: [ActionItem] (Codable: text, owner, dueDate)
- followUps: [String], parkingLot: [String]
- recording: Recording (inverse)

UserProfile (UserDefaults + Keychain, NOT SwiftData):
- isSignedIn: Bool, email: String?, tier: enum (free, pro, team)
- supabaseAccessToken in Keychain

Set up SwiftData container in CasprApp.swift.
```

### Prompt 1.5 — Main window (Hardware Industrial layout)

```
Read DESIGN_SYSTEM.md for all styling.

Create the main Caspr window as an NSWindow (NOT ghost mode — fine in screen shares).

HEADER STRIP (~80px, bgHeader):
- Left: Ghost app icon (32px) + StatusBadgeView + Timer (SF Mono 28px)
- Centre: WaveformView (live amplitude bars — 2-3px wide, 1-2px gap, amplitude gradient)
- Right: Dual LevelMeterView (SYS + MIC, segmented bars, green→yellow→red)
         + Dual RotaryKnobView (SYS + MIC — radial gradient dome, inset shadow bezel,
         grip notches, pointer indicator, LED dot below with label + value)

Create these in Components/:
- RotaryKnobView.swift: 48-56px, DragGesture rotation, radial gradient, inset shadows
- LevelMeterView.swift: 8-12 segments, colour-coded fill, hardware label
- WaveformView.swift: Canvas drawing vertical bars from audio buffer

SIDEBAR (~180px, bgSidebar):
- Recording (with LIVE badge when recording), Transcripts (with count badge), Audio, Settings
- Active: 2px left accent border + textPrimary + subtle bg tint
- Mode toggle at bottom

CONTENT (bgApp):
- Tab bar: TRANSCRIPT / Timestamps toggle
- Search ⌘F top-right
- Scrollable transcript list (TranscriptSegmentView per segment)
- Sticky footer: Copy ⌘C, Save ⌘S, Export ⌘E, Clear

TranscriptSegmentView.swift in Components/:
- [Timestamp SF Mono 12px muted] [LED dot + SPEAKER N label] [Body text 14px]
- Speaker colours from DesignTokens

Also add TierGate.swift + PaywallView.swift for free vs pro gating.

All borders, shadows, colours from DesignTokens.swift.
```

### Prompt 1.6 — Wire Phase 1 together

```
Connect everything:
- Record button → AudioCaptureService.start() / .stop()
- Level meters subscribe to audio level publisher
- Timer updates every second during recording
- On stop → create Recording in SwiftData with audio file
- Menu bar icon changes to filled + red tint while recording
- Waveform animates during recording
- Global hotkey ⌥⌘R toggles recording (KeyboardShortcuts)
- "Recordings" opens main window
- Settings opens placeholder SettingsView

Test flow:
1. Menu bar icon → popover → Record → icon changes, timer, levels animate
2. Stop → recording saved, appears in list
3. ⌥⌘R toggles from anywhere
4. Ghost panel invisible during screen share

Commit: "Phase 1 complete — Ghost Shell MVP" and push to origin main.
```

---

## 🎙️ Phase 2: Local Transcription (Free Tier Complete)

### Prompt 2.1 — WhisperKit integration

```
Build LocalTranscriptionService using WhisperKit.

- First use: download + cache WhisperKit "base" model, show progress in a sheet
- Accept audio file URL → return Transcript with timestamped segments
- Background thread — never block UI
- Show progress (percentage or spinner)
- Support cancellation
- Auto-transcribe on recording stop (toggle in Settings to disable)
- Save Transcript to SwiftData linked to Recording, source = "local"
- Handle: model not downloaded → prompt, failure → error + retry, long recordings → ETA
```

### Prompt 2.2 — Transcript viewer

```
Read DESIGN_SYSTEM.md for styling.

Build TranscriptView in the content area using TranscriptSegmentView components:

Each segment:
- Timestamp: SF Mono 12px, textSecondary, fixed 60px column
- Speaker: LED dot (6px, speaker colour, glow shadow) + "SPEAKER 1"
  (SF Mono 11px, semibold, tracking 1, uppercase, speaker colour)
- Text: SF Pro Text 14px, textPrimary, line-height 1.6
- Active (during playback): 2px left accent border
- New segments: fade in (opacity 0→1, translateY 8→0, 0.3s)

Tab bar: TRANSCRIPT / Timestamps toggle (show/hide time column)

Mini audio player in footer:
- Play/pause, seek slider, current time (SF Mono)
- Playback highlights matching segment

Footer actions: Copy ⌘C, Save ⌘S, Export ⌘E (Markdown via NSSavePanel), Clear
Search ⌘F with match highlighting

No transcript yet → "Transcribing..." with progress, or "Transcribe" button
Free user + pro tease: "Upgrade to Pro for cloud transcription" with ledPro badge
```

### Prompt 2.3 — Commit free tier

```
Review everything. Fix compiler warnings and issues.
Test full free tier flow end to end:
1. App opens → ghost icon in menu bar
2. Click record → audio captures, waveform + meters animate
3. Stop → recording appears in list
4. Auto-transcribe → transcript with timestamps + speaker segments
5. Search, copy, export transcript
6. ⌥⌘R works globally
7. Ghost panel invisible in screen share
8. Hardware Industrial design matches DESIGN_SYSTEM.md

Commit: "Phase 2 complete — Free tier with local transcription" and push.
```

---

## ☁️ Phase 3: Supabase Backend

### Prompt 3.1 — Database setup

```
Create /supabase directory with migration files:

supabase/migrations/001_initial_schema.sql:
- profiles, recordings, transcripts, summaries tables (schema from CLAUDE.md)

supabase/migrations/002_rls_policies.sql:
- RLS on all tables, users only access own data

supabase/migrations/003_functions.sql:
- Trigger: on auth.users insert → create profiles row (tier='free')
- Function: increment_cloud_minutes(user_id, minutes)

supabase/seed.sql with test data.
```

### Prompt 3.2 — Auth flow

```
Build AuthService wrapping Supabase Swift SDK:
- signUp, signIn, signInWithApple, signOut
- currentUser published property (email, tier)
- Session in Keychain, auto-refresh on launch

AuthView: sign in/up form, "Sign in with Apple", error handling
Update MenuBarView: show email + tier badge if signed in, "Sign in for Pro" link if not
Free users never need to sign in. Auth only for Pro features.
```

### Prompt 3.3 — Edge Functions

```
Create Supabase Edge Functions (Deno):

supabase/functions/transcribe/index.ts:
- Input: { recording_id, audio_storage_path }
- Download audio from Storage → send to Deepgram (nova-2, en-AU, diarisation, punctuation)
- Save transcript to DB → return transcript_id. Requires auth JWT.

supabase/functions/summarise/index.ts:
- Input: { recording_id }
- Fetch transcript → send to Claude API (claude-sonnet-4-5-20250929) with prompt from CLAUDE.md
- Parse structured response → save to summaries table. Requires auth.

supabase/functions/create-checkout/index.ts:
- Create/retrieve Stripe customer → create Checkout Session → return URL. Requires auth.

supabase/functions/stripe-webhook/index.ts:
- Handle: checkout.session.completed, subscription.updated, subscription.deleted
- Update profiles.tier accordingly.

Proper error handling and logging in all functions.
```

---

## ⭐ Phase 4: Pro Features

### Prompt 4.1 — Cloud transcription

```
Build CloudTranscriptionService:
1. Upload M4A to Supabase Storage (bucket: recordings, path: {user_id}/{recording_id}.m4a)
2. Create cloud recording row
3. Call transcribe Edge Function
4. Poll for transcript (every 2s) or use Supabase Realtime
5. Save locally to SwiftData + display
6. Track cloud_minutes_used
7. Over limit → message + fallback to local
8. Upload failure → fallback to local

Show upload progress. Settings toggle: "Use cloud transcription when available"
```

### Prompt 4.2 — AI summaries

```
Read DESIGN_SYSTEM.md for SummaryView styling.

SummarisationService: call summarise Edge Function, poll for result, save to SwiftData.

SummaryView (below transcript in content area):
- Overview paragraph (textPrimary, 14px)
- "Key Decisions" with bullet points
- "Action Items" with checkboxes + owner + due date
- "Follow-ups" bullets
- "Parking Lot" (collapsible)
- Copy section buttons, Copy All, Regenerate button, Export dropdown (Markdown, PDF, Clipboard)
- Free user → PaywallView with Pro pitch

Style: section headers in uppercase tracked style, content in body font.
```

### Prompt 4.3 — Cloud sync

```
Build SyncService for bidirectional sync (Pro users):
- On launch + every 5 minutes: compare local vs cloud, sync differences
- Manual "Sync Now" in Settings
- Conflict: cloud wins (most recent write)
- Offline: queue and retry
- Cloud recordings show cloud icon badge in list
- Show last synced time + sync spinner

Commit: "Phase 4 complete — Pro features" and push.
```

---

## 💳 Phase 5: Payments (Stripe)

### Prompt 5.1 — Stripe integration

```
Build SubscriptionService:
- Check profiles.tier from Supabase on launch, cache locally for offline
- Upgrade flow: PaywallView → create-checkout Edge Function → open Stripe Checkout in browser
  → webhook updates tier → app detects change → "Welcome to Pro! 🎉"
- "Manage Subscription" in Settings → opens Stripe Customer Portal in browser
- Cancellation: tier reverts to free at billing period end

PaywallView pricing:
- Monthly: $12/month
- Annual: $99/year (save 31%) — highlight this option
- Both options visible, annual savings emphasised
```

---

## ⚡ Phase 6: Power Features

### Prompt 6.1 — System audio capture (Pro)

```
Add ScreenCaptureKit system audio capture (macOS 13+, Pro only):
- Capture loopback audio (meeting audio from speakers)
- Mix with microphone into single stream
- Request screen recording permission with explanation
- Fallback to mic-only if denied

Settings > Audio: source picker — "Microphone only" (default) or "System + Mic" (Pro)
Free users tapping system audio → PaywallView
```

### Prompt 6.2 — Full Settings view

```
Read DESIGN_SYSTEM.md. Style Settings with the dark palette.

Tabs:
1. General: start at login, floating panel toggle, auto-transcribe, auto-summarise (Pro), retention
2. Audio: input source picker, quality (Low/Med/High), test level meter
3. Transcription: WhisperKit model status, cloud toggle (Pro), language
4. Account: email, tier badge, usage bar (X/Y cloud minutes), Manage Subscription, Sign Out
5. Shortcuts: global hotkey config (KeyboardShortcuts)
6. About: version, "Made by Luis Villamizar", GitHub link, check updates (Sparkle)
```

---

## 🎨 Phase 7: Polish & Distribution

### Prompt 7.1 — Onboarding

```
First-launch onboarding sheet (5 steps, swipeable, skippable):
1. "Meet Caspr 👻" — friendly ghost, "Your invisible meeting recorder"
2. Microphone — "Allow Microphone" button triggers system permission
3. Ghost Mode — visual explanation of how invisibility works
4. Free vs Pro — "Free: record + transcribe forever. Pro: cloud, AI, sync."
5. Ready — "Look for 👻 in your menu bar. Press ⌥⌘R to record."

Track completion in UserDefaults. Show once only. Dark styling per DESIGN_SYSTEM.md.
```

### Prompt 7.2 — Landing page

```
Create /website/index.html — single-page marketing site.

Style references: glazeapp.com, tryalcove.com, tryklack.com
Dark, native-feeling, interactive hero, minimal copy, bold feature grid.

Structure:
1. Hero: Interactive ghost that fades/disappears on hover. "Your friendly invisible recorder."
   Download CTA button.
2. Feature grid: 8 bold headlines, no descriptions — "Ghost Mode", "Local Transcription",
   "AI Summaries", "One-Click Recording", "Cloud Sync", "Speaker Labels",
   "Menu Bar Native", "Blazing Fast"
3. Free vs Pro: two-column comparison (not a big table)
4. Download: "Download for Mac" + "Go Pro" buttons
5. Footer: one line, clean

Tailwind CSS via CDN. Responsive. Dark palette matching DESIGN_SYSTEM.md colours.
```

### Prompt 7.3 — DMG packaging

```
Create scripts/build-release.sh:
1. Build Release configuration (xcodebuild)
2. Sign with Developer ID (placeholder identity)
3. Notarise (notarytool, placeholder credentials)
4. Create DMG (hdiutil): ghost-themed background, app left, Applications right
5. Sign DMG

Also create Makefile: make build, make release, make clean.
Document release process in CLAUDE.md.
```

---

## 📋 Useful Ongoing Prompts

```
# Start of session
Read CLAUDE.md and DESIGN_SYSTEM.md. What's built? What's next?

# Bug fix
I'm getting this error: [paste]. It happens when [scenario]. Fix it.

# New feature
Add [description]. Follow existing patterns and DESIGN_SYSTEM.md.

# Commit
Commit all changes with "[message]" and push to origin main.

# Code review
Review [file]. Check for bugs, performance, Swift best practices, and design system compliance.

# Ghost mode test
Walk me through testing that Caspr is invisible during a Zoom screen share.
```
