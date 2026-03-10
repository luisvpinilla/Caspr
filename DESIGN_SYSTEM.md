# Caspr — Design System & UI Specification

> Claude Code: Read this file BEFORE building any UI component.
> The design philosophy is "Hardware Industrial" — skeuomorphic audio controls
> embedded in a sleek, modern dark interface.

## Design Philosophy

Caspr's UI blends sleek modernity with tactile nostalgia — "Skeuomorphic Minimalism."
The app should feel like a professional audio control deck, not a generic macOS utility.
Trust and precision are the emotional goals.

### Three Pillars

1. **Dual-Layered Materiality** — Digital surfaces (flat, glassmorphic, matte) for panels
   and navigation vs physical hardware controls (layered shadows, radial gradients, tactile
   depth) for audio components like knobs and meters.
2. **Functional Typography** — Text and colour as strict status indicators, mimicking
   real-world A/V equipment labelling. Monospaced data. Uppercase tracked hardware labels.
   LED status dots with glow shadows.
3. **Deliberate Density** — Tight, compact control clustering (control deck feel), especially
   in the header strip. Not airy consumer white space.

---

## Colour Palette

### Core Surfaces
```swift
// DesignTokens.swift
static let bgApp        = Color(hex: "#1A1A1E")  // Main app background — deep carbon
static let bgPanel      = Color(hex: "#222226")  // Panel/card background — slightly lifted
static let bgSurface    = Color(hex: "#2A2A2E")  // Input fields, secondary surfaces
static let bgSidebar    = Color(hex: "#1E1E22")  // Sidebar background
static let bgHeader     = Color(hex: "#1C1C20")  // Header/control strip background
static let borderSubtle = Color(hex: "#333338")  // 1px structural borders
static let borderStrong = Color(hex: "#444448")  // Active/focused borders
```

### Text Hierarchy
```swift
static let textPrimary   = Color(hex: "#E8E8EC")  // Primary text — off-white
static let textSecondary = Color(hex: "#8E8E96")  // Secondary labels, timestamps
static let textMuted     = Color(hex: "#5A5A62")  // Disabled, placeholder
static let textMono      = Color(hex: "#C8C8CC")  // Monospaced data
```

### Status LEDs
```swift
static let ledRecording = Color(hex: "#EF4444")  // Red — active recording
static let ledLive      = Color(hex: "#22C55E")  // Green — live/connected/transcribing
static let ledStandby   = Color(hex: "#A3A3A3")  // Grey — standby/idle
static let ledPro       = Color(hex: "#8B5CF6")  // Purple — pro feature indicator
static let ledWarning   = Color(hex: "#F59E0B")  // Amber — warning/limit approaching
```

### Speaker Colours (for diarisation)
```swift
static let speaker1 = Color(hex: "#EF4444")  // Red
static let speaker2 = Color(hex: "#3B82F6")  // Blue
static let speaker3 = Color(hex: "#22C55E")  // Green
static let speaker4 = Color(hex: "#F59E0B")  // Amber
static let speaker5 = Color(hex: "#8B5CF6")  // Purple
```

### Accent
```swift
static let accentPrimary = Color(hex: "#6366F1")  // Indigo — primary actions
static let accentHover   = Color(hex: "#818CF8")  // Lighter indigo on hover
```

---

## Typography

### Font Stack
```swift
// All fonts are system — no custom font files needed
static let fontBody    = Font.system(.body, design: .default)           // SF Pro Text
static let fontDisplay = Font.system(.title, design: .default)          // SF Pro Display
static let fontMono    = Font.system(.body, design: .monospaced)        // SF Mono
```

### Type Scale
| Element | Font | Size | Weight | Tracking | Style |
|---------|------|------|--------|----------|-------|
| App title (CASPR) | SF Pro Display | 12px | Semibold (600) | 0.2em | Uppercase |
| Section headers | SF Pro Text | 11px | Semibold (600) | 0.08em | Uppercase |
| Body (transcript) | SF Pro Text | 14px | Regular (400) | Default | Sentence case |
| Timestamps | SF Mono | 12px | Regular (400) | Default | — |
| Timer display | SF Mono | 28px | Light (300) | 0.05em | — |
| Hardware labels (SYS, MIC) | SF Mono | 10px | Medium (500) | 0.15em | Uppercase |
| Level values | SF Mono | 11px | Medium (500) | Default | — |
| Speaker labels | SF Mono | 11px | Semibold (600) | 0.1em | Uppercase |
| Status badges | SF Pro Text | 10px | Semibold (600) | 0.1em | Uppercase |

### Rules
- ALL temporal and quantitative data uses monospace (timers, percentages, levels, timestamps)
- ALL hardware control labels use uppercase + heavy tracking (silkscreen printing aesthetic)
- Transcript body is the only element using proportional font at readable size
- Numbers must NEVER shift layout when changing — use `.monospacedDigit()`

---

## Components

### LED Status Indicator
```swift
// LEDIndicatorView.swift
Circle()
    .fill(ledColor)
    .frame(width: 6, height: 6)
    .shadow(color: ledColor.opacity(0.6), radius: 8)
    .shadow(color: ledColor.opacity(0.3), radius: 16)
```
Pulse animation when active:
```swift
@keyframes: opacity 1 → 0.5 → 1 over 2s (recording) or 3s (standby)
```

### Status Badge (STANDBY / RECORDING / LIVE)
```
Shape: Pill (Capsule)
Background: status colour at 15% opacity
Border: 1px status colour at 30% opacity
Content: LED dot (left) + label text (uppercase, tracked, 10px)
```

### Rotary Knob (SYS / MIC)
```
Size: 48–56px diameter
Outer ring: Dark inset shadow (machined bezel effect)
  - box-shadow: inset 0 2px 4px rgba(0,0,0,0.4), inset 0 -1px 2px rgba(255,255,255,0.05)
Knob body: Radial gradient (lighter centre → darker edge) for dome effect
Grip lines: 2–3 subtle notch marks for tactile reference
Pointer: Small bright line showing current rotation position
Drop shadow: Layered to lift knob off the surface
Below knob: LED source dot + "SYS"/"MIC" label + level value
Interaction: DragGesture with rotation, scroll wheel support
```

### Audio Level Meter
```
Horizontal segmented bar (8–12 segments)
Each segment: small rounded rectangle (4px wide, 12px tall, 2px gap)
Fill direction: left to right based on level (0.0 – 1.0)
Colour: green (0–0.6) → yellow (0.6–0.8) → red (0.8–1.0)
Inactive segments: bgSurface (#2A2A2E)
Active segments: solid colour with subtle glow
Label: "SYS" or "MIC" to the left in hardware label style
```

### Waveform Visualiser
```
Horizontal strip in the header area
Vertical bars: 2–3px wide, 1–2px spacing
Height: proportional to amplitude
Colour: gradient from textMuted (low) to accentPrimary (high)
Behaviour: scrolls left as new audio arrives (live recording)
When idle: flat line or very low noise floor visualisation
Implementation: Canvas or custom Shape drawing from audio buffer
```

### Transcript Segment
```
Layout: [Timestamp] [Speaker LED + Label] [Text]
Timestamp: left-aligned, SF Mono 12px, textSecondary, fixed-width column (~60px)
Speaker: LED dot (6px, speaker colour, glow) + "SPEAKER 1" (SF Mono 11px, 600, tracked, uppercase)
Text: SF Pro Text 14px, textPrimary (#E8E8EC), line-height 1.6
Active segment (during playback): subtle left border accent (2px, accentPrimary)
New segments: fade in from bottom (opacity 0→1, translateY 8→0, 0.3s ease-out)
```

### Sidebar Navigation
```
Width: ~180px
Background: bgSidebar (#1E1E22)
Items: SF Symbol icon + label, 13px, weight 500
Active item: 2px left accent border (accentPrimary) + textPrimary + subtle bg tint
Inactive: textSecondary, no background
Badge (transcript count): small pill, bgSurface, SF Mono
Bottom: Mode toggle (compact dark switch)
Separator: 1px borderSubtle between sections
```

### Recording Button (popover)
```
Size: 56px circle
Idle: bgSurface fill, borderSubtle border, grey icon (SF Symbol "mic.fill")
Recording: ledRecording fill with glow shadow, white icon
Transition: 0.3s scale + colour animation on state change
```

### Popover (menu bar)
```
Width: ~280px
Background: bgPanel at 92% opacity + backdrop blur 20px
Border: 1px borderSubtle
Border-radius: 12px
Shadow: 0 16px 48px rgba(0,0,0,0.4), 0 4px 12px rgba(0,0,0,0.2)
Noise overlay: mix-blend-mode overlay, opacity 0.03
```

---

## Main Window Layout

```
┌─────────────────────────────────────────────────────────────┐
│ HEADER (~80px): [👻] [●STANDBY] [02:34] [▁▂▃▅▃▂▁] [SYS▮▮▮] [MIC▮▮▮] [(◉)(◉)] │
├──────────┬──────────────────────────────────────────────────┤
│ SIDEBAR  │ CONTENT                                          │
│ ~180px   │                                                  │
│          │ [TRANSCRIPT] [⊙ Timestamps]          [🔍 ⌘F]    │
│ ● Record │                                                  │
│   LIVE   │ 00:00  ● SPEAKER 1                               │
│          │ Yes, it can easily become chaotic.                │
│ □ Trans  │                                                  │
│   12     │ 00:03  ● SPEAKER 1                               │
│          │ We don't want that.                               │
│ ♪ Audio  │                                                  │
│          │ 00:05  ● SPEAKER 2                               │
│ ⚙ Settn  │ What's the role of literature review?            │
│          │                                                  │
│          ├──────────────────────────────────────────────────┤
│ Mode ◉   │ [📋 Copy ⌘C] [💾 Save ⌘S] [↓ Export ⌘E] [🗑 Clear] │
└──────────┴──────────────────────────────────────────────────┘
```

### Header Strip
- Height: ~80px, background: bgHeader
- Dense horizontal layout — control deck feel
- Left: Ghost app icon + status badge (LED + text) + timer (SF Mono 28px)
- Centre: Waveform visualiser (live amplitude bars)
- Right: Level meters (SYS + MIC segmented bars) + rotary knobs (SYS + MIC)

### Sidebar
- Background: bgSidebar, 1px right border
- Nav items with SF Symbol icons
- Active: Recording (with LIVE badge when recording)
- Transcripts item shows count badge
- Mode toggle at bottom

### Content Area
- Background: bgApp
- Tab bar at top: TRANSCRIPT / Timestamps toggle
- Search field top-right (⌘F)
- Scrollable transcript body
- Sticky footer bar with action buttons

---

## Animations

### Recording State Change
```
Menu bar icon: crossfade to filled variant + red tint (0.3s ease)
Status badge: morph STANDBY → RECORDING (colour + text)
LED dots: begin 2s pulse animation
Waveform: begin scrolling with live data
Timer: begin counting (monospacedDigit, no layout shift)
```

### Transcript Segment Appearance
```
New segments: opacity 0→1, translateY 8px→0, duration 0.3s ease-out
Stagger: each segment has slight cascade delay
Auto-scroll: scroll to bottom during live recording
```

### Knob Rotation
```
DragGesture controls rotation angle
Smooth movement with ease-out curve
Value label updates in real time
Subtle snap at min/max boundaries
```

### Hover States
```
Buttons: background lightens slightly (0.15s ease)
Transcript segments: very faint bgSurface highlight
Sidebar items: text shifts to textPrimary (0.1s)
Keep everything subtle and professional
```

---

## Glassmorphism & Texture

### Panel Glass
```swift
.background(.ultraThinMaterial)
// Or custom:
Color(hex: "#222226").opacity(0.92)
    .background(.ultraThinMaterial)
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
    )
```

### Noise Overlay
```swift
// Subtle matte texture on panels
Image("noise") // or procedural
    .blendMode(.overlay)
    .opacity(0.03)
    .allowsHitTesting(false)
```

### Hardware Inset Shadow (bezels)
```swift
// For knob outer rings, meter bezels
.shadow(color: .black.opacity(0.4), radius: 2, y: 2)   // outer drop
.overlay(
    Circle()
        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)  // top highlight
)
```

---

## SwiftUI Quick Reference

```swift
// LED with glow
Circle()
    .fill(Color.red)
    .frame(width: 6, height: 6)
    .shadow(color: .red.opacity(0.6), radius: 8)
    .shadow(color: .red.opacity(0.3), radius: 16)

// Hardware label
Text("SYS")
    .font(.system(size: 10, weight: .medium, design: .monospaced))
    .tracking(1.5)
    .textCase(.uppercase)
    .foregroundStyle(DesignTokens.textSecondary)

// Timer
Text("02:34")
    .font(.system(size: 28, weight: .light, design: .monospaced))
    .tracking(1)
    .monospacedDigit()
    .foregroundStyle(DesignTokens.textPrimary)

// Speaker label
HStack(spacing: 6) {
    Circle().fill(DesignTokens.speaker1).frame(width: 6, height: 6)
        .shadow(color: DesignTokens.speaker1.opacity(0.6), radius: 6)
    Text("SPEAKER 1")
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .tracking(1)
        .foregroundStyle(DesignTokens.speaker1)
}

// Status badge
HStack(spacing: 6) {
    Circle().fill(.red).frame(width: 6, height: 6)
        .shadow(color: .red.opacity(0.5), radius: 6)
    Text("RECORDING")
        .font(.system(size: 10, weight: .semibold))
        .tracking(1)
        .textCase(.uppercase)
}
.padding(.horizontal, 10)
.padding(.vertical, 5)
.background(Color.red.opacity(0.15))
.overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))
.clipShape(Capsule())
```
