import SwiftUI

struct LevelMeterView: View {
    let level: CGFloat // 0.0 to 1.0
    var label: String? = nil
    var segmentCount: Int = 10
    var orientation: Orientation = .horizontal

    enum Orientation {
        case horizontal
        case vertical
    }

    var body: some View {
        VStack(spacing: 4) {
            if orientation == .horizontal {
                HStack(spacing: 0) {
                    if let label {
                        Text(label)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1.5)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(width: 30, alignment: .leading)
                    }
                    HStack(spacing: 2) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            segmentView(index: index)
                        }
                    }
                }
            } else {
                VStack(spacing: 2) {
                    ForEach((0..<segmentCount).reversed(), id: \.self) { index in
                        segmentView(index: index)
                    }
                }
                if let label {
                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func segmentView(index: Int) -> some View {
        let threshold = CGFloat(index) / CGFloat(segmentCount)
        let isActive = level > threshold
        let segmentColor = colorForSegment(index: index)

        RoundedRectangle(cornerRadius: 1)
            .fill(isActive ? segmentColor : DesignTokens.bgSurface)
            .frame(
                width: orientation == .horizontal ? 4 : 12,
                height: orientation == .horizontal ? 12 : 4
            )
            .shadow(
                color: isActive ? segmentColor.opacity(0.4) : .clear,
                radius: 2
            )
    }

    private func colorForSegment(index: Int) -> Color {
        let position = CGFloat(index) / CGFloat(segmentCount)
        if position < 0.6 {
            return DesignTokens.ledLive
        } else if position < 0.8 {
            return DesignTokens.ledWarning
        } else {
            return DesignTokens.ledRecording
        }
    }
}
