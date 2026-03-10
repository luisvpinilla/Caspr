import SwiftUI

struct PaywallView: View {
    let feature: ProFeature
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    LEDIndicatorView(color: DesignTokens.ledPro, size: 8)
                    Text("PRO")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(DesignTokens.ledPro)
                }

                Text("Upgrade to Pro")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DesignTokens.textPrimary)

                Text(feature.rawValue)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            // Feature description
            Text(feature.description)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Pricing
            VStack(spacing: 12) {
                pricingOption(
                    title: "Annual",
                    price: "$99/year",
                    detail: "Save 31%",
                    isHighlighted: true
                )

                pricingOption(
                    title: "Monthly",
                    price: "$12/month",
                    detail: nil,
                    isHighlighted: false
                )
            }

            // Dismiss
            Button("Maybe later") {
                dismiss()
            }
            .foregroundStyle(DesignTokens.textMuted)
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 340)
        .background(DesignTokens.bgPanel)
    }

    private func pricingOption(title: String, price: String, detail: String?, isHighlighted: Bool) -> some View {
        Button(action: {
            // Placeholder — Stripe checkout in Phase 5
            print("[Caspr] Upgrade tapped: \(title)")
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.ledLive)
                    }
                }
                Spacer()
                Text(price)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.textMono)
            }
            .padding(14)
            .background(isHighlighted ? DesignTokens.accentPrimary.opacity(0.15) : DesignTokens.bgSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isHighlighted ? DesignTokens.accentPrimary.opacity(0.4) : DesignTokens.borderSubtle,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
