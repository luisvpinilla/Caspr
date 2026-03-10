import SwiftUI
import SwiftData

enum SidebarItem: String, CaseIterable {
    case recording = "Recording"
    case transcripts = "Transcripts"
    case audio = "Audio"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .recording: "record.circle"
        case .transcripts: "doc.text"
        case .audio: "waveform"
        case .settings: "gearshape"
        }
    }
}

struct MainContentView: View {
    @StateObject private var recorder = AudioCaptureService.shared
    @State private var selectedTab: SidebarItem = .recording
    @State private var sysVolume: CGFloat = 0.7
    @State private var micVolume: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 0) {
            // HEADER STRIP
            headerStrip

            Divider().background(DesignTokens.borderSubtle)

            // SIDEBAR + CONTENT
            HStack(spacing: 0) {
                sidebar
                Divider().background(DesignTokens.borderSubtle)
                contentArea
            }
        }
        .background(DesignTokens.bgApp)
    }

    // MARK: - Header Strip

    private var headerStrip: some View {
        HStack(spacing: 16) {
            // Left: Icon + Status + Timer
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignTokens.textPrimary)

                StatusBadgeView(status: recorder.isRecording ? .recording : .standby)

                Text(recorder.formattedDuration)
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .tracking(1)
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.textPrimary)
            }

            Spacer()

            // Centre: Waveform
            WaveformView(
                level: recorder.audioLevel,
                barCount: 40,
                isActive: recorder.isRecording
            )
            .frame(width: 200, height: 40)

            Spacer()

            // Right: Level meters + Rotary knobs
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    LevelMeterView(level: recorder.audioLevel * sysVolume, label: "SYS", segmentCount: 8)
                    LevelMeterView(level: recorder.audioLevel, label: "MIC", segmentCount: 8)
                }

                HStack(spacing: 12) {
                    RotaryKnobView(value: $sysVolume, label: "SYS", size: 48)
                    RotaryKnobView(value: $micVolume, label: "MIC", size: 48)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(DesignTokens.bgHeader)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 2) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                sidebarButton(item)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .frame(width: 180)
        .background(DesignTokens.bgSidebar)
    }

    private func sidebarButton(_ item: SidebarItem) -> some View {
        let isSelected = selectedTab == item

        return Button(action: { selectedTab = item }) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                if item == .recording && recorder.isRecording {
                    StatusBadgeView(status: .live)
                        .scaleEffect(0.7)
                }
            }
            .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? DesignTokens.bgSurface.opacity(0.5) : .clear)
            .overlay(
                Rectangle()
                    .fill(isSelected ? DesignTokens.accentPrimary : .clear)
                    .frame(width: 2),
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .recording:
                RecordingContentView()
            case .transcripts:
                RecordingListView()
            case .audio, .settings:
                placeholderContent(selectedTab.rawValue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bgApp)
    }

    private func placeholderContent(_ title: String) -> some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("Coming soon")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textMuted)
            Spacer()
        }
    }
}

// MARK: - Recording Content (active recording view)

struct RecordingContentView: View {
    @StateObject private var recorder = AudioCaptureService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if recorder.isRecording {
                VStack(spacing: 16) {
                    LEDIndicatorView(
                        color: DesignTokens.ledRecording,
                        size: 12,
                        isAnimating: true
                    )

                    Text(recorder.formattedDuration)
                        .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("Recording in progress...")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)

                    Button(action: { recorder.stop() }) {
                        Text("STOP")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(DesignTokens.ledRecording)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                VStack(spacing: 12) {
                    Text("👻")
                        .font(.system(size: 48))

                    Text("Ready to record")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)

                    Text("Click the record button or press ⌥⌘R")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.textMuted)

                    Button(action: { recorder.start() }) {
                        Text("RECORD")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(DesignTokens.ledRecording)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }

            Spacer()
        }
    }
}
