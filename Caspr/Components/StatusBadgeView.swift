import SwiftUI

enum RecordingStatus {
    case standby
    case recording
    case live
    case processing

    var label: String {
        switch self {
        case .standby: "STANDBY"
        case .recording: "RECORDING"
        case .live: "LIVE"
        case .processing: "PROCESSING"
        }
    }

    var color: Color {
        switch self {
        case .standby: DesignTokens.ledStandby
        case .recording: DesignTokens.ledRecording
        case .live: DesignTokens.ledLive
        case .processing: DesignTokens.ledWarning
        }
    }
}

struct StatusBadgeView: View {
    let status: RecordingStatus

    var body: some View {
        HStack(spacing: 6) {
            LEDIndicatorView(
                color: status.color,
                isAnimating: status == .recording || status == .live
            )

            Text(status.label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.15))
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
