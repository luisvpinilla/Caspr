import SwiftUI
import SwiftData

struct MenuBarView: View {
    @StateObject private var recorder = AudioCaptureService.shared
    @StateObject private var auth = AuthService.shared
    @StateObject private var profile = UserProfile.shared
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 16) {
            // App title + account
            HStack {
                Text("CASPR")
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textPrimary)

                Spacer()

                if auth.isSignedIn {
                    HStack(spacing: 4) {
                        LEDIndicatorView(
                            color: profile.tier == .pro ? DesignTokens.ledPro : DesignTokens.ledLive,
                            size: 5
                        )
                        Text(profile.tier.rawValue.uppercased())
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(
                                profile.tier == .pro ? DesignTokens.ledPro : DesignTokens.textMuted
                            )
                    }
                }
            }

            // Status badge
            StatusBadgeView(status: recorder.isRecording ? .recording : .standby)

            // Timer
            Text(recorder.formattedDuration)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .tracking(1)
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textPrimary)

            // Record button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording ? DesignTokens.ledRecording : DesignTokens.bgSurface)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: recorder.isRecording ? DesignTokens.ledRecording.opacity(0.5) : .clear,
                            radius: recorder.isRecording ? 16 : 0
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    recorder.isRecording ? DesignTokens.ledRecording.opacity(0.3) : DesignTokens.borderSubtle,
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(recorder.isRecording ? .white : DesignTokens.textSecondary)
                }
            }
            .buttonStyle(.plain)

            // Level meter
            LevelMeterView(level: recorder.audioLevel, label: "MIC")
                .frame(height: 16)

            Divider()
                .background(DesignTokens.borderSubtle)

            // Recordings button
            Button(action: openRecordings) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Recordings")
                    Spacer()
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            // Settings button
            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                    Spacer()
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            // Account section
            if auth.isSignedIn {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 13))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile.email ?? "Account")
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Text(profile.tier == .pro ? "Pro Plan" : "Free Plan")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                    Spacer()
                    Button("Sign Out") {
                        Task { await auth.signOut() }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.textMuted)
                    .buttonStyle(.plain)
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.vertical, 4)
            } else {
                Button(action: { MainWindowController.shared.showAuthWindow() }) {
                    HStack(spacing: 6) {
                        LEDIndicatorView(color: DesignTokens.ledPro, size: 5)
                        Text("Sign in for Pro features")
                            .font(.system(size: 12))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(DesignTokens.ledPro)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(DesignTokens.borderSubtle)

            // Quit
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Text("Quit Caspr")
                    Spacer()
                }
                .foregroundStyle(DesignTokens.textMuted)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 280)
        .background(
            ZStack {
                DesignTokens.bgPanel.opacity(0.92)
                    .background(.ultraThinMaterial)
            }
        )
        // Save recording to SwiftData when M4A conversion completes, then auto-transcribe
        .onChange(of: recorder.currentRecordingURL) { _, newURL in
            guard let url = newURL else { return }
            let recording = Recording(
                duration: recorder.duration,
                audioFileURL: url
            )
            modelContext.insert(recording)
            recorder.currentRecordingURL = nil

            // Auto-transcribe with local WhisperKit
            LocalTranscriptionService.shared.autoTranscribe(
                recording: recording,
                modelContext: modelContext
            )
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stop()
        } else {
            recorder.start()
        }
    }

    private func openRecordings() {
        MainWindowController.shared.showWindow()
    }

    private func openSettings() {
        // Placeholder — Phase 6.2
    }
}
