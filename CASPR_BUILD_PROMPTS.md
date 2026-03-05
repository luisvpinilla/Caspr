# Caspr — Claude Code Build Prompts

> Paste these prompts into Claude Code sequentially. Each builds on the previous.
> Always run Claude Code from your `~/Documents/caspr` project folder.
> Before each session, ask Claude Code: "Read CLAUDE.md and tell me where we're at."

---

## 🔧 Phase 0: Project Scaffolding

### Prompt 0.1 — Create the Xcode project

```
Create a new macOS app project called "Caspr" in this directory using Swift and SwiftUI.
Set it up as a menu bar app (LSUIElement = true in Info.plist, no Dock icon).
Use SwiftData for local persistence.
Minimum deployment target: macOS 14.0.
Create the folder structure from CLAUDE.md (Models, Services, Views, Utilities, Resources, Tests).
Add a basic NSStatusItem with a ghost icon (use SF Symbol "waveform" as placeholder).
Add the entitlements file with:
  - com.apple.security.device.audio-input (microphone)
  - com.apple.security.network.client (for API calls)
Set the bundle identifier to com.luisvpinilla.caspr.
Create a .gitignore for Xcode/Swift projects.
Do NOT add any third-party packages yet — we'll do that next.
```

### Prompt 0.2 — Add Swift Package dependencies

```
Add the following Swift Package dependencies to the Xcode project:
1. WhisperKit (https://github.com/argmaxinc/WhisperKit) — for local transcription
2. KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts) — for global hotkeys
3. Supabase Swift SDK (https://github.com/supabase/supabase-swift) — for auth, database, storage
4. Sparkle (https://github.com/sparkle-project/Sparkle) — for auto-updates (configure later)

Don't integrate them into views yet — just add the packages so they resolve and compile.
```

---

## 👻 Phase 1: Ghost Shell (Free Tier MVP)

### Prompt 1.1 — Menu bar interface

```
Build the menu bar interface for Caspr.

The NSStatusItem should show:
- A small icon (SF Symbol "waveform" default, "waveform.circle.fill" when recording)
- Clicking it opens a popover (NOT a dropdown menu) with:
  - App name "Caspr" with a ghost emoji 👻
  - A large circular Record button (red when recording, grey when idle)
  - Recording duration timer (MM:SS format, visible only when recording)
  - Audio level meter (horizontal bar showing mic input level in real time)
  - A "Recordings" button that opens the main window
  - A gear icon button for Settings
  - "Quit Caspr" at the bottom

Use SwiftUI for the popover content. Roughly 280px wide, auto-height.
The popover should dismiss when clicking outside it.
```

### Prompt 1.2 — Ghost Mode panel

```
Create the GhostModeService that manages window invisibility.

Implement a RecordingPanel as an NSPanel (not NSWindow) with these properties:
- styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView]
- sharingType = .none (KEY FEATURE — excludes from screen sharing)
- level = .floating
- isMovableByWindowBackground = true
- titlebarAppearsTransparent = true
- backgroundColor = .clear
- collectionBehavior includes .canJoinAllSpaces and .fullScreenAuxiliary
- hidesOnDeactivate = false

The panel shows a minimal floating widget:
- Recording duration
- Pulsing red dot animation
- Stop button
- Drag handle area

This panel is optional — toggled in Settings. The menu bar popover is primary.
Make sure the RecordingListView window (which opens separately) does NOT use
ghost mode — it's fine if that window shows in screen shares.
```

### Prompt 1.3 — Audio capture service

```
Build the AudioCaptureService using AVFoundation's AVAudioEngine.

Requirements:
- Capture from the default input device (microphone)
- Save to a CAF file during recording (lossless)
- Convert to M4A (AAC, 128kbps) when recording stops (for storage efficiency)
- Expose a Combine publisher for real-time audio levels (RMS value, 0.0 to 1.0)
- Support start(), stop(), pause(), resume() methods
- Request microphone permission on first use with a friendly explanation
- Store recordings in: ~/Library/Application Support/Caspr/Recordings/
- File naming: caspr_YYYY-MM-DD_HH-mm-ss.m4a

Handle errors gracefully — if mic permission denied, show a clear message
explaining how to enable it in System Settings > Privacy & Security > Microphone.
```

### Prompt 1.4 — Data models

```
Create SwiftData models for the app.

Recording:
- id: UUID
- title: String (default: "Recording — {formatted date}")
- createdAt: Date
- duration: TimeInterval
- audioFileURL: URL
- transcript: Transcript? (optional relationship)
- summary: Summary? (optional relationship)
- isCloudSynced: Bool (default false)

Transcript:
- id: UUID
- createdAt: Date
- fullText: String
- segments: [TranscriptSegment] (Codable, stored as JSON)
  - TranscriptSegment: startTime Double, endTime Double, text String, confidence Float
- source: String ("local" or "cloud")
- recording: Recording (inverse relationship)

Summary:
- id: UUID
- createdAt: Date
- overview: String
- decisions: [String]
- actionItems: [ActionItem] (Codable — text String, owner String?, dueDate String?)
- followUps: [String]
- parkingLot: [String]
- recording: Recording (inverse relationship)

UserProfile (NOT a SwiftData model — use UserDefaults/Keychain):
- isSignedIn: Bool
- email: String?
- tier: enum (free, pro, team)
- supabaseAccessToken: String? (stored in Keychain)

Set up the SwiftData container in CasprApp.swift.
```

### Prompt 1.5 — Recordings list view

```
Create a RecordingListView that opens as a standard NSWindow.

Show recordings in a list, sorted by most recent first.
Each row displays:
- Title (editable on double-click)
- Date and duration (formatted nicely: "Today at 2:30 PM · 45 min")
- Status badges: "Transcribed" (green pill) and/or "Summarised" (blue pill)
- Play button for inline audio playback
- Delete button with confirmation alert

Include a search bar at the top to filter by title or transcript text.
Use NavigationSplitView: list on left, detail on right.
Detail pane shows transcript text and summary (if available).
Empty state: ghost emoji with "No recordings yet. Hit record to get started."

Also add a TierGate utility:
- A simple helper that checks UserProfile.tier
- When a free user taps a Pro-only feature, show a PaywallView sheet
- PaywallView shows: feature name, "Upgrade to Pro", pricing, and a "Maybe later" dismiss
- For now the upgrade button just prints a log — we'll wire Stripe later
```

### Prompt 1.6 — Wire it all together

```
Connect everything for Phase 1:
- Record button in MenuBarView calls AudioCaptureService.start() / .stop()
- Audio level meter subscribes to the audio level publisher
- Timer updates every second during recording
- When recording stops, create a new Recording in SwiftData with the audio file
- Menu bar icon switches to "waveform.circle.fill" with red tint while recording
- Add global hotkey ⌥⌘R using KeyboardShortcuts to toggle recording
- "Recordings" button opens RecordingListView in a new window
- Settings button opens SettingsView (just a placeholder for now with tabs)

Test the complete flow:
1. Click menu bar icon → popover appears
2. Click Record → icon changes, timer starts, levels animate
3. Click Stop → recording saved, visible in Recordings list
4. ⌥⌘R toggles recording from anywhere
5. Ghost panel (if enabled) is invisible in a screen share test

Commit with message "Phase 1 complete — Ghost Shell MVP" and push to origin main.
```

---

## 🎙️ Phase 2: Local Transcription (Free Tier Complete)

### Prompt 2.1 — WhisperKit integration

```
Build the LocalTranscriptionService using WhisperKit.

Requirements:
- On first use, download and cache the WhisperKit "base" model
- Show download progress to the user in a sheet/overlay
- Accept an audio file URL, return a Transcript with timestamped segments
- Run transcription on a background thread — never block UI
- Show transcription progress (percentage or indeterminate spinner)
- Support cancellation
- When a recording stops, auto-transcribe it (with a toggle in Settings to disable)
- Save the Transcript to SwiftData, linked to the Recording
- Set transcript.source = "local"

Handle edge cases:
- Model not yet downloaded → prompt to download
- Transcription fails → show error, allow retry
- Very long recordings (>1 hour) → show estimated time remaining
```

### Prompt 2.2 — Transcript viewer

```
Create the TranscriptView for displaying transcripts in the detail pane.

Show:
- Full transcript text with timestamp markers every ~30 seconds
- Clicking a timestamp seeks to that point in audio playback
- Mini audio player bar at the bottom: play/pause, seek slider, current time
- Current playback position highlights the matching transcript segment
- Copy All button (copies full transcript as plain text)
- Export as Markdown button (saves .md file via NSSavePanel)
- Search within transcript (⌘F) with match highlighting
- Click-to-edit on any segment for manual corrections

When no transcript exists yet, show:
- "Transcribing..." with progress if in progress
- "Transcribe" button if not yet started
- "Upgrade to Pro for cloud transcription (better accuracy)" teaser for free users
```

### Prompt 2.3 — Commit free tier

```
Review everything built so far. Fix any compiler warnings or issues.
Make sure the full free tier flow works end to end:

1. Open app → ghost icon appears in menu bar
2. Click record → audio captures
3. Stop recording → appears in list
4. Auto-transcribe → transcript appears with timestamps
5. Search, copy, export transcript
6. Hotkey ⌥⌘R works globally
7. Ghost panel invisible during screen share

This is the complete free tier product. It should feel polished and useful on its own.

Commit with message "Phase 2 complete — Free tier with local transcription" and push.
```

---

## ☁️ Phase 3: Supabase Backend

### Prompt 3.1 — Supabase project setup

```
Create the Supabase backend structure in a /supabase directory at the project root.

Create migration files:

supabase/migrations/001_initial_schema.sql:
- profiles table (extends auth.users): id, email, full_name, tier, stripe_customer_id,
  stripe_subscription_id, cloud_minutes_used, cloud_minutes_limit, timestamps
- recordings table: id, user_id, title, duration_seconds, audio_storage_path,
  is_cloud_synced, created_at
- transcripts table: id, recording_id, full_text, segments JSONB, source, language, created_at
- summaries table: id, recording_id, overview, decisions JSONB, action_items JSONB,
  follow_ups JSONB, parking_lot JSONB, model, created_at

supabase/migrations/002_rls_policies.sql:
- Enable RLS on all tables
- Users can only CRUD their own data
- Transcripts and summaries access gated through recording ownership

supabase/migrations/003_functions.sql:
- Trigger function: on auth.users insert → create profiles row with tier='free'
- Function: increment_cloud_minutes(user_id, minutes) for usage tracking

Also create a supabase/seed.sql with sample test data.
```

### Prompt 3.2 — Auth flow in the app

```
Build the AuthService and auth views in the macOS app.

AuthService wraps the Supabase Swift SDK:
- signUp(email, password) → creates account, triggers profile creation
- signIn(email, password) → returns session
- signInWithApple() → Apple Sign-In flow
- signOut() → clears session
- currentUser → published property with user info and tier
- Store session token in macOS Keychain (not UserDefaults)
- Auto-refresh token on app launch
- Listen for auth state changes

AuthView:
- Clean sign in / sign up form (email + password)
- "Sign in with Apple" button
- Toggle between sign in and sign up modes
- Show errors inline (wrong password, email taken, etc.)
- After successful sign in, dismiss and update the UI

Update MenuBarView:
- If signed in: show user email and tier badge (Free/Pro) at top of popover
- If not signed in: show "Sign in for Pro features" link
- Add "Account" to Settings that shows subscription status

Free users can use the app without ever signing in. Auth is only needed for Pro features.
```

### Prompt 3.3 — Edge Functions

```
Create Supabase Edge Functions in the /supabase/functions directory.

supabase/functions/transcribe/index.ts:
- Receives: { recording_id, audio_storage_path }
- Downloads the audio file from Supabase Storage
- Sends to Deepgram API for transcription (model: nova-2, language: en-AU)
  - Enable speaker diarisation
  - Enable punctuation and paragraphs
- Saves the transcript to the transcripts table
- Returns the transcript ID
- Requires auth (verify JWT from the request)

supabase/functions/summarise/index.ts:
- Receives: { recording_id }
- Fetches the transcript from the database
- Sends to Claude API (claude-sonnet-4-5-20250929) with the summarisation prompt from CLAUDE.md
- Parses structured response into overview, decisions, action_items, follow_ups, parking_lot
- Saves to summaries table
- Returns the summary ID
- Requires auth

supabase/functions/create-checkout/index.ts:
- Receives: { price_id, success_url, cancel_url }
- Creates or retrieves Stripe customer for the user
- Creates Stripe Checkout Session
- Returns the checkout URL
- Requires auth

supabase/functions/stripe-webhook/index.ts:
- Receives Stripe webhook events
- Handles: checkout.session.completed, customer.subscription.updated,
  customer.subscription.deleted
- Updates profiles.tier and profiles.stripe_subscription_id accordingly
- On cancellation: set tier back to 'free'

Use Deno for all Edge Functions (Supabase default).
Include proper error handling and logging in each function.
```

---

## ⭐ Phase 4: Pro Features

### Prompt 4.1 — Cloud transcription flow

```
Build the CloudTranscriptionService in the macOS app.

Flow when a Pro user finishes recording:
1. Upload the M4A audio file to Supabase Storage (bucket: "recordings", path: {user_id}/{recording_id}.m4a)
2. Create a recording row in the cloud database
3. Call the transcribe Edge Function with the recording_id and storage path
4. Poll or listen for the transcript to appear (use Supabase Realtime or polling every 2 seconds)
5. When transcript arrives, save it locally to SwiftData AND display it
6. Update the recording's isCloudSynced = true
7. Track usage: increment cloud_minutes_used on the profile

Show upload progress in the UI. If upload fails, fall back to local transcription.
If the user is over their cloud minutes limit, show a message and fall back to local.

Add a toggle in Settings: "Use cloud transcription when available" (default on for Pro users).
```

### Prompt 4.2 — AI summaries

```
Build the SummarisationService and SummaryView.

SummarisationService:
- Call the summarise Edge Function with the recording_id
- Poll or listen for the summary to appear
- Save the summary locally to SwiftData
- Show a loading spinner while generating

SummaryView (displayed in the detail pane below the transcript):
- Meeting overview at the top (paragraph)
- "Key Decisions" section with bullet points
- "Action Items" section with checkboxes, owner, due date
- "Follow-ups" section
- "Parking Lot" section (collapsible)
- Copy section buttons (copy just that section as Markdown)
- Copy All button (full summary as Markdown)
- Regenerate button (re-sends transcript to Claude for a fresh summary)
- Export dropdown: Markdown file, PDF, Clipboard

If the user is on the free tier and taps anything summary-related,
show the PaywallView explaining this is a Pro feature.
```

### Prompt 4.3 — Sync service

```
Build the SyncService for bidirectional cloud sync.

On app launch (if signed in as Pro):
1. Fetch cloud recordings list from Supabase
2. Compare with local SwiftData recordings
3. Download any cloud-only recordings (transcripts and summaries) to local
4. Upload any local-only recordings that haven't been synced

Sync should be:
- Automatic on launch and every 5 minutes
- Manual trigger via "Sync Now" button in Settings
- Show sync status in the UI (last synced time, sync in progress indicator)
- Conflict resolution: cloud wins (most recent write wins)
- If offline, queue operations and retry when online

Add a "Cloud Recordings" section in RecordingListView that shows cloud-synced
recordings with a cloud icon badge.
```

### Prompt 4.4 — Commit Pro features

```
Review and test the Pro features flow:

1. Sign up → account created, tier = free
2. (We'll wire Stripe later, so for testing: manually set tier to 'pro' in Supabase dashboard)
3. Record a meeting → audio uploads to Supabase Storage
4. Cloud transcription runs → transcript appears (with speaker labels if Deepgram supports it)
5. AI summary generates → structured summary appears
6. Summary is copyable, exportable
7. Recordings sync between cloud and local

Fix any issues and commit with message "Phase 4 complete — Pro features (cloud transcription + AI summaries)" and push.
```

---

## 💳 Phase 5: Payments (Stripe)

### Prompt 5.1 — Stripe integration

```
Build the SubscriptionService and payment flow.

In the macOS app:
- SubscriptionService manages subscription state
- On launch: check profiles.tier from Supabase to verify current subscription
- Cache tier locally so the app works offline (but re-verify on next connection)

Upgrade flow:
1. User taps "Upgrade to Pro" in PaywallView
2. App calls create-checkout Edge Function to get a Stripe Checkout URL
3. Open the URL in the user's default browser (NSWorkspace.shared.open)
4. After payment: Stripe webhook fires → Edge Function updates tier to 'pro'
5. App polls or listens for tier change → unlocks Pro features
6. Show a "Welcome to Pro! 🎉" confirmation

Manage subscription:
- Add "Manage Subscription" button in Settings > Account
- Opens Stripe Customer Portal in browser (for cancellation, plan changes, payment updates)
- After cancellation: tier reverts to 'free' at end of billing period
- App should check subscription status and handle expiry gracefully

Update PaywallView with real pricing:
- Pro Monthly: $12/month
- Pro Annual: $99/year (save 31%)
- Show both options with the annual savings highlighted
```

---

## ⚡ Phase 6: Power Features

### Prompt 6.1 — System audio capture

```
Add system audio capture using ScreenCaptureKit (macOS 13+).
This is a Pro-only feature.

Create a SystemAudioCaptureService:
- Capture system/loopback audio (what plays through speakers — meeting audio from Zoom/Teams/Meet)
- Mix with microphone input into a single audio stream
- Request screen recording permission (show a clear explanation of why)
- Fall back gracefully to mic-only if permission denied

In Settings > Audio, add a source picker:
- "Microphone only" (default, works for everyone)
- "System audio + Microphone" (Pro only, requires screen recording permission)
- Show a list of available input devices

When "System audio + Microphone" is selected and user is free tier, show PaywallView.
```

### Prompt 6.2 — Settings view (complete)

```
Build the full SettingsView with all tabs:

1. General:
   - Start Caspr at login (toggle, use SMAppService)
   - Show floating panel during recording (toggle)
   - Auto-transcribe after recording (toggle)
   - Auto-summarise after transcription — Pro only (toggle)
   - Recording retention: 7 / 30 / 90 days / Forever

2. Audio:
   - Input source picker (mic list + system audio option)
   - Audio quality: Low / Medium / High (maps to AAC bitrate)
   - Test audio level meter (live preview of input levels)

3. Transcription:
   - Local model: show which WhisperKit model is downloaded, button to change
   - Cloud transcription toggle (Pro only)
   - Preferred language (default: English - Australian)

4. Account:
   - If signed in: email, tier badge, usage (X of Y cloud minutes used)
   - Manage Subscription button (opens Stripe portal)
   - Sign Out button
   - If not signed in: Sign In / Sign Up buttons

5. Shortcuts:
   - Global hotkey configuration using KeyboardShortcuts
   - Default: ⌥⌘R for record toggle

6. About:
   - App version, "Made by Luis Villamizar"
   - GitHub link
   - Check for updates (Sparkle)
```

---

## 🎨 Phase 7: Polish & Distribution

### Prompt 7.1 — Onboarding flow

```
Create a first-launch onboarding flow as a sheet on first run.

Steps (one per page, swipeable):
1. Welcome — "Meet Caspr 👻" with a friendly ghost illustration (use SF Symbols or simple shapes).
   "Your invisible meeting recorder."
2. Permissions — "Caspr needs microphone access to record."
   Big "Allow Microphone" button that triggers the system permission dialog.
3. Ghost Mode — "Invisible during screen sharing."
   Visual explanation: "Caspr uses a special macOS window that's excluded from screen capture.
   Your recordings stay private."
4. Free vs Pro — "Free: Record & transcribe locally, forever.
   Pro: Cloud transcription, AI summaries, sync."
   "Start free — upgrade anytime."
5. Ready — "Look for 👻 in your menu bar. That's Caspr."
   "Press ⌥⌘R to start recording from anywhere."

Track onboarding completion in UserDefaults. Only show once.
Make it skippable with a "Skip" button in the corner.
```

### Prompt 7.2 — Landing page

```
Create a simple landing page for Caspr at /website/index.html in the repo.

Single-page marketing site:
- Hero: "Your friendly invisible recorder" with a ghost-themed hero image/animation
- Problem: "Every meeting recorder announces itself. Caspr doesn't."
- Features: Ghost Mode, Local Transcription, AI Summaries, Cloud Sync
- Pricing: Free vs Pro comparison table
- Download CTA: "Download for macOS" button (links to GitHub releases for now)
- Footer: "Made by Luis Villamizar" with GitHub link

Use Tailwind CSS via CDN. Clean, modern design. Soft colour palette.
Make it responsive (looks good on mobile too — for when people find it on their phone).
```

### Prompt 7.3 — DMG packaging

```
Create a release build script at scripts/build-release.sh:

1. Build Caspr in Release configuration via xcodebuild
2. Sign with Developer ID (placeholder identity — I'll fill in my real one)
3. Run notarytool for Apple notarisation (placeholder credentials)
4. Create a DMG using hdiutil:
   - Custom background image (ghost-themed)
   - App icon on the left
   - Applications folder shortcut on the right
   - Standard Mac DMG drag-to-install layout
5. Sign the DMG itself

Also create a Makefile with:
- make build → debug build
- make release → runs the full release script
- make clean → removes build artifacts

Document the full release process in CLAUDE.md.
```

---

## 📋 Useful Ongoing Prompts

### Start of each session
```
Read CLAUDE.md and give me a status update. What's been built? What should we work on next?
```

### Bug fixing
```
I'm getting this error: [paste error]. It happens when [describe scenario]. Fix it.
```

### Adding a feature
```
Add [description]. Follow existing patterns. Update CLAUDE.md if the architecture changes.
```

### Committing work
```
Commit all changes with the message "[descriptive message]" and push to origin main.
```

### Code review
```
Review [file or module] for bugs, performance issues, and Swift best practices.
```

### Testing ghost mode
```
Let's verify ghost mode. Walk me through exactly how to test that Caspr
is invisible during a Zoom screen share, and what to check for.
```
