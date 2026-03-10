import SwiftUI

struct TranscriptSegmentView: View {
    let segment: TranscriptSegment
    var speakerIndex: Int = 0
    var isActive: Bool = false
    var showTimestamp: Bool = true

    private var speakerColor: Color {
        let colors = DesignTokens.speakerColors
        return colors[speakerIndex % colors.count]
    }

    private var formattedTime: String {
        let minutes = Int(segment.startTime) / 60
        let seconds = Int(segment.startTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            if showTimestamp {
                Text(formattedTime)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 50, alignment: .trailing)
            }

            // Speaker LED + label
            if let speaker = segment.speaker {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(speakerColor)
                            .frame(width: 6, height: 6)
                            .shadow(color: speakerColor.opacity(0.6), radius: 6)

                        Text(speaker.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(speakerColor)
                    }
                }
                .frame(width: 110, alignment: .leading)
            }

            // Transcript text
            Text(segment.text)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(DesignTokens.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            isActive
                ? DesignTokens.bgSurface.opacity(0.5)
                : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(isActive ? DesignTokens.accentPrimary : .clear)
                .frame(width: 2),
            alignment: .leading
        )
    }
}
