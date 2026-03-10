import SwiftUI
import SwiftData

struct RecordingListView: View {
    @Query(sort: \Recording.createdAt, order: .reverse) private var recordings: [Recording]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedRecording: Recording?

    private var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return recordings
        }
        return recordings.filter { recording in
            recording.title.localizedCaseInsensitiveContains(searchText) ||
            (recording.transcript?.fullText.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        if let recording = selectedRecording {
            // Show transcript view for selected recording
            VStack(spacing: 0) {
                // Back bar
                HStack {
                    Button(action: { selectedRecording = nil }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Recordings")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(DesignTokens.accentPrimary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(recording.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Duration
                    Text(formatDuration(recording.duration))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(DesignTokens.bgHeader)

                TranscriptView(recording: recording)
            }
        } else {
            // Show recordings list
            recordingsList
        }
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack {
                Text("RECORDINGS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text("\(recordings.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(DesignTokens.bgSurface)
                    .clipShape(Capsule())

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

            Divider().background(DesignTokens.borderSubtle)

            // List
            if filteredRecordings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredRecordings) { recording in
                            recordingRow(recording)
                                .onTapGesture {
                                    selectedRecording = recording
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider().background(DesignTokens.borderSubtle)

            // Footer
            footerBar
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("\u{1F47B}")
                .font(.system(size: 40))
            Text("No recordings yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("Hit record to get started.")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func recordingRow(_ recording: Recording) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(recording.createdAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(DesignTokens.textSecondary)

                    Text(formatDuration(recording.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                }
            }

            Spacer()

            // Transcription status
            if LocalTranscriptionService.shared.isTranscribing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Transcribing")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.ledLive)
                }
            } else if recording.transcript != nil {
                statusPill("Transcribed", color: DesignTokens.ledLive)
            }

            if recording.summary != nil {
                statusPill("Summarised", color: DesignTokens.accentPrimary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.textMuted)

            // Delete
            Button(action: { deleteRecording(recording) }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DesignTokens.bgApp)
        .contentShape(Rectangle())
    }

    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            footerButton("Copy", icon: "doc.on.doc", shortcut: "\u{2318}C")
            footerButton("Save", icon: "square.and.arrow.down", shortcut: "\u{2318}S")
            footerButton("Export", icon: "arrow.down.doc", shortcut: "\u{2318}E")
            Spacer()
            footerButton("Clear", icon: "trash", shortcut: nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DesignTokens.bgHeader)
    }

    private func footerButton(_ label: String, icon: String, shortcut: String?) -> some View {
        Button(action: {}) {
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes) min \(seconds)s"
    }

    private func deleteRecording(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.audioFileURL)
        modelContext.delete(recording)
    }
}
