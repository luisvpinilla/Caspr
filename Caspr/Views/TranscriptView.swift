import SwiftUI
import SwiftData
import AVFoundation

struct TranscriptView: View {
    let recording: Recording

    @StateObject private var transcriber = LocalTranscriptionService.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showTimestamps = true
    @State private var searchText = ""
    @State private var activeSegmentIndex: Int?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackTime: TimeInterval = 0
    @State private var playbackTimer: Timer?

    private var transcript: Transcript? { recording.transcript }

    private var filteredSegments: [TranscriptSegment] {
        guard let segments = transcript?.segments else { return [] }
        if searchText.isEmpty { return segments }
        return segments.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar

            Divider().background(DesignTokens.borderSubtle)

            // Content
            if transcriber.isTranscribing {
                transcribingView
            } else if let transcript, !transcript.segments.isEmpty {
                segmentList
            } else {
                noTranscriptView
            }

            Divider().background(DesignTokens.borderSubtle)

            // Audio player
            if transcript != nil {
                miniPlayer
                Divider().background(DesignTokens.borderSubtle)
            }

            // Footer actions
            footerBar
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack {
            HStack(spacing: 0) {
                Text("TRANSCRIPT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Button(action: { showTimestamps.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("Timestamps")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(showTimestamps ? DesignTokens.textPrimary : DesignTokens.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(showTimestamps ? DesignTokens.bgSurface : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }

            Spacer()

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignTokens.textMuted)
                    .font(.system(size: 12))
                TextField("Search \u{2318}F", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .frame(width: 140)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignTokens.borderSubtle, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Transcribing Progress

    private var transcribingView: some View {
        VStack(spacing: 16) {
            Spacer()

            LEDIndicatorView(
                color: DesignTokens.ledLive,
                size: 10,
                isAnimating: true,
                animationDuration: 1.5
            )

            Text("Transcribing...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.textPrimary)

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: transcriber.progress)
                    .progressViewStyle(.linear)
                    .tint(DesignTokens.ledLive)
                    .frame(width: 200)

                Text(transcriber.progressMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.textSecondary)

                Text("\(Int(transcriber.progress * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.textMono)
            }

            Button(action: { transcriber.cancelTranscription() }) {
                Text("CANCEL")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(DesignTokens.bgSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DesignTokens.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Transcript

    private var noTranscriptView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "text.word.spacing")
                .font(.system(size: 36))
                .foregroundStyle(DesignTokens.textMuted)

            Text("No transcript yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.textSecondary)

            Button(action: { startTranscription() }) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.and.mic")
                    Text("TRANSCRIBE")
                }
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(DesignTokens.accentPrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Pro upsell
            HStack(spacing: 6) {
                LEDIndicatorView(color: DesignTokens.ledPro, size: 5)
                Text("Upgrade to Pro for cloud transcription")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.ledPro)
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Segment List

    private var segmentList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredSegments.enumerated()), id: \.offset) { index, segment in
                        TranscriptSegmentView(
                            segment: segment,
                            speakerIndex: speakerIndex(for: segment),
                            isActive: activeSegmentIndex == index,
                            showTimestamp: showTimestamps
                        )
                        .id(index)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Mini Player

    private var miniPlayer: some View {
        HStack(spacing: 12) {
            // Play/Pause
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(DesignTokens.bgSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Current time
            Text(formatTime(playbackTime))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textMono)
                .frame(width: 45, alignment: .trailing)

            // Seek slider
            Slider(value: Binding(
                get: { playbackTime },
                set: { newValue in
                    playbackTime = newValue
                    audioPlayer?.currentTime = newValue
                    updateActiveSegment()
                }
            ), in: 0...max(recording.duration, 1))
            .tint(DesignTokens.accentPrimary)

            // Total time
            Text(formatTime(recording.duration))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 45, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DesignTokens.bgHeader)
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack(spacing: 12) {
            footerButton("Copy", icon: "doc.on.doc", shortcut: "\u{2318}C") {
                copyTranscript()
            }
            footerButton("Save", icon: "square.and.arrow.down", shortcut: "\u{2318}S") {
                // Placeholder — save handled by SwiftData
            }
            footerButton("Export", icon: "arrow.down.doc", shortcut: "\u{2318}E") {
                exportTranscript()
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DesignTokens.bgHeader)
    }

    private func footerButton(_ label: String, icon: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                }
            }
            .foregroundStyle(DesignTokens.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startTranscription() {
        transcriber.autoTranscribe(recording: recording, modelContext: modelContext)
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.audioFileURL)
            audioPlayer?.currentTime = playbackTime
            audioPlayer?.play()
            isPlaying = true

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    if let player = audioPlayer {
                        playbackTime = player.currentTime
                        updateActiveSegment()
                        if !player.isPlaying {
                            stopPlayback()
                        }
                    }
                }
            }
        } catch {
            print("[Caspr] Playback error: \(error)")
        }
    }

    private func stopPlayback() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func updateActiveSegment() {
        guard let segments = transcript?.segments else { return }
        activeSegmentIndex = segments.lastIndex(where: { $0.startTime <= playbackTime })
    }

    private func copyTranscript() {
        guard let text = transcript?.fullText, !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func exportTranscript() {
        guard let transcript else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(recording.title).md"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            var markdown = "# \(recording.title)\n\n"
            markdown += "**Date:** \(recording.createdAt.formatted())\n"
            markdown += "**Duration:** \(formatTime(recording.duration))\n\n"
            markdown += "---\n\n"

            for segment in transcript.segments {
                let time = formatTime(segment.startTime)
                if let speaker = segment.speaker {
                    markdown += "**[\(time)] \(speaker):** \(segment.text)\n\n"
                } else {
                    markdown += "**[\(time)]** \(segment.text)\n\n"
                }
            }

            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func speakerIndex(for segment: TranscriptSegment) -> Int {
        guard let speaker = segment.speaker else { return 0 }
        let speakers = Array(Set(transcript?.segments.compactMap(\.speaker) ?? []))
        return speakers.firstIndex(of: speaker) ?? 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
