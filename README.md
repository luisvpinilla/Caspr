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
- **One-click recording** — Start from the menu bar or a global hotkey (⌥⌘R)
- **Local transcription** — On-device speech-to-text via WhisperKit. Audio never leaves your Mac.
- **No account required** — Download, install, record. That's it.

### Pro — $12/month
- **Cloud transcription** — Higher accuracy via Deepgram with speaker labels
- **AI summaries** — Key decisions, action items, and follow-ups extracted by Claude
- **Cloud storage & sync** — Access recordings from anywhere
- **Export** — Notion, Markdown, PDF

## Requirements

- macOS 14.0+ (Sonoma)
- Apple Silicon or Intel Mac
- Microphone permission

## Getting Started

```bash
git clone https://github.com/luisvpinilla/caspr.git
cd caspr
open Caspr.xcodeproj
# ⌘R to build and run
```

## Tech Stack

- SwiftUI + AppKit (NSPanel for ghost mode, NSStatusItem for menu bar)
- AVFoundation / ScreenCaptureKit for audio capture
- WhisperKit for local transcription
- Supabase (auth, database, storage, edge functions)
- Deepgram for cloud transcription
- Claude API for AI summarisation
- Stripe for subscriptions

## Project Status

🚧 **In Development** — Phase 1 (Ghost Shell)

## Licence

TBD

---

*Named after Casper the Friendly Ghost. Be invisible. Be helpful.*
