import AppKit
import SwiftUI

@MainActor
final class GhostModeService: ObservableObject {
    static let shared = GhostModeService()

    @Published var isPanelVisible = false

    private var panel: NSPanel?

    private init() {}

    func showPanel() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFront(nil)
        isPanelVisible = true
    }

    func hidePanel() {
        panel?.orderOut(nil)
        isPanelVisible = false
    }

    func togglePanel() {
        if isPanelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 120),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // CRITICAL — Ghost Mode
        panel.sharingType = .none

        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.titleVisibility = .hidden

        let hostingView = NSHostingView(rootView: GhostPanelView())
        panel.contentView = hostingView

        // Centre on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 110
            let y = screenFrame.maxY - 160
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
    }
}

// MARK: - Ghost Panel Content

struct GhostPanelView: View {
    @StateObject private var recorder = AudioCaptureService.shared

    var body: some View {
        HStack(spacing: 12) {
            // Pulsing LED
            LEDIndicatorView(
                color: DesignTokens.ledRecording,
                isAnimating: recorder.isRecording,
                animationDuration: 2.0
            )

            // Timer
            Text(recorder.formattedDuration)
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textPrimary)

            // Compact level meter
            LevelMeterView(level: recorder.audioLevel, segmentCount: 6)
                .frame(width: 40)

            Spacer()

            // Stop button
            Button(action: { recorder.stop() }) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(DesignTokens.ledRecording)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.bgPanel.opacity(0.92))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
