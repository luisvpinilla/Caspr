# 👻 Caspr

**Your friendly invisible recorder.**

Caspr is a native macOS menu bar app that records meeting audio, transcribes locally on-device, and generates AI-powered summaries — all while being completely invisible during screen sharing.

---

## Why Caspr?

Every meeting recorder announces itself. Bot joins the call. Notification pops up. Recording indicator appears in the shared screen. Caspr does none of that.

It sits silently in your menu bar, captures audio, and when you're done — transcript and summary are waiting. No one knows.

## Features

### Free — forever
- **Ghost Mode** — Invisible during screen shares, screen recordings, and window capture
- **One-click recording** — Start from the menu bar or global hotkey (⌥⌘R)
- **Local transcription** — On-device speech-to-text via WhisperKit. Audio never leaves your Mac.
- **No account required** — Download, install, record.

### Pro — $12/month
- **Cloud transcription** — Higher accuracy via Deepgram with speaker labels
- **AI summaries** — Key decisions, action items, and follow-ups extracted by Claude
- **Cloud storage & sync** — Access recordings from anywhere
- **Export** — Notion, Markdown, PDF

## Design

Caspr uses a **Hardware Industrial** design language — skeuomorphic audio controls (rotary knobs, segmented level meters, LED indicators) embedded in a sleek dark interface. The app feels like a professional audio control deck, not a generic macOS utility.

See [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for the full specification.

## Tech Stack

- **Swift + SwiftUI + AppKit** — Native macOS (NSPanel for ghost mode, NSStatusItem for menu bar)
- **AVFoundation / ScreenCaptureKit** — Audio capture
- **WhisperKit** — Local on-device transcription
- **Supabase** — Auth, database, storage, edge functions
- **Deepgram** — Cloud transcription with speaker diarisation
- **Claude API** — AI-powered meeting summarisation
- **Stripe** — Subscription payments

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16+
- Swift 6.0+
- Apple Silicon or Intel Mac

## Getting Started

```bash
git clone https://github.com/luisvpinilla/caspr.git
cd caspr
open Caspr.xcodeproj
# ⌘R to build and run
```

## Project Structure

```
caspr/
├── CLAUDE.md               # Project context for Claude Code
├── DESIGN_SYSTEM.md        # Hardware Industrial UI specification
├── CASPR_BUILD_PROMPTS.md  # Phased build prompts for Claude Code
├── Caspr/                  # Xcode project (macOS app)
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   ├── Components/
│   └── Utilities/
└── supabase/               # Backend (migrations, edge functions)
```

## Project Status

🚧 **In Development** — Phase 1 (Ghost Shell)

## Licence

TBD

---

*Named after Casper the Friendly Ghost. Be invisible. Be helpful.*
