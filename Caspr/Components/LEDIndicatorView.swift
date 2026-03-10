import SwiftUI

struct LEDIndicatorView: View {
    let color: Color
    var size: CGFloat = 6
    var isAnimating: Bool = false
    var animationDuration: Double = 2.0

    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.6), radius: 8)
            .shadow(color: color.opacity(0.3), radius: 16)
            .opacity(opacity)
            .onChange(of: isAnimating, initial: true) { _, newValue in
                if newValue {
                    withAnimation(
                        .easeInOut(duration: animationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        opacity = 0.5
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        opacity = 1.0
                    }
                }
            }
    }
}
