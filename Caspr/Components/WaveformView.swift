import SwiftUI

struct WaveformView: View {
    let level: CGFloat
    var barCount: Int = 32
    var isActive: Bool = false

    @State private var bars: [CGFloat] = []
    @State private var animationTimer: Timer?

    var body: some View {
        Canvas { context, size in
            let barWidth: CGFloat = 2.5
            let spacing: CGFloat = 1.5
            let totalWidth = CGFloat(bars.count) * (barWidth + spacing)
            let startX = (size.width - totalWidth) / 2

            for (index, amplitude) in bars.enumerated() {
                let x = startX + CGFloat(index) * (barWidth + spacing)
                let barHeight = max(2, amplitude * size.height * 0.8)
                let y = (size.height - barHeight) / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)

                let color = amplitude < 0.3
                    ? DesignTokens.textMuted
                    : DesignTokens.accentPrimary

                context.fill(
                    Path(roundedRect: rect, cornerRadius: 1),
                    with: .color(color.opacity(Double(0.4 + amplitude * 0.6)))
                )
            }
        }
        .onAppear {
            bars = Array(repeating: 0.05, count: barCount)
            startAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
        .onChange(of: isActive) { _, active in
            if !active {
                withAnimation(.easeOut(duration: 0.5)) {
                    bars = Array(repeating: 0.05, count: barCount)
                }
            }
        }
    }

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                updateBars()
            }
        }
    }

    private func updateBars() {
        guard isActive else { return }
        var newBars = bars
        // Shift left
        newBars.removeFirst()
        // Add new bar based on current level with some randomness
        let noise = CGFloat.random(in: -0.1...0.1)
        let newValue = max(0.02, min(1.0, level + noise))
        newBars.append(newValue)
        bars = newBars
    }
}
