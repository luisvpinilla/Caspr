import SwiftUI
import SwiftData

struct RecordingListView: View {
    @Query(sort: \Recording.createdAt, order: .reverse) private var recordings: [Recording]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

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
        VStack(spacing: 0) {
            // Tab bar
            HStack {
                Text("TRANSCRIPTS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(DesignTokens.textMuted)
                        .font(.system(size: 12))
                    TextField("Search ⌘F", text: $searchText)
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
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider().background(DesignTokens.borderSubtle)

            // Footer actions
            footerBar
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("👻")
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

            // Status badges
            if recording.transcript != nil {
                statusPill("Transcribed", color: DesignTokens.ledLive)
            }
            if recording.summary != nil {
                statusPill("Summarised", color: DesignTokens.accentPrimary)
            }

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
            footerButton("Copy", icon: "doc.on.doc", shortcut: "⌘C")
            footerButton("Save", icon: "square.and.arrow.down", shortcut: "⌘S")
            footerButton("Export", icon: "arrow.down.doc", shortcut: "⌘E")
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
        // Remove audio file
        try? FileManager.default.removeItem(at: recording.audioFileURL)
        modelContext.delete(recording)
    }
}
