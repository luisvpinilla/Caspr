import SwiftUI

struct RotaryKnobView: View {
    @Binding var value: CGFloat // 0.0 to 1.0
    var label: String = "SYS"
    var size: CGFloat = 48

    @State private var lastAngle: CGFloat = 0

    private var rotation: Angle {
        .degrees(Double(value) * 270 - 135) // -135 to +135 degrees
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Outer bezel
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#3A3A3E"),
                                Color(hex: "#252528")
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    )

                // Knob body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#4A4A4E"),
                                Color(hex: "#333336")
                            ],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: size * 0.35
                        )
                    )
                    .frame(width: size * 0.75, height: size * 0.75)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)

                // Pointer indicator
                Rectangle()
                    .fill(DesignTokens.textPrimary)
                    .frame(width: 2, height: size * 0.2)
                    .offset(y: -size * 0.22)
                    .rotationEffect(rotation)

                // Grip notches
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 4)
                        .offset(y: -size * 0.28)
                        .rotationEffect(.degrees(Double(i) * 90 + Double(value) * 270 - 135))
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let center = CGPoint(x: size / 2, y: size / 2)
                        let vector = CGPoint(
                            x: gesture.location.x - center.x,
                            y: gesture.location.y - center.y
                        )
                        let angle = atan2(vector.x, -vector.y)
                        let normalized = (angle + .pi) / (2 * .pi)
                        value = max(0, min(1, normalized))
                    }
            )

            // LED dot + label
            VStack(spacing: 2) {
                LEDIndicatorView(
                    color: value > 0.8 ? DesignTokens.ledRecording : DesignTokens.ledLive,
                    size: 4
                )

                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(String(format: "%.0f", value * 100))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.textMono)
                    .monospacedDigit()
            }
        }
    }
}
