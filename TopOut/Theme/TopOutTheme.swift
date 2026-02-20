import SwiftUI

/// TopOut Design System — Outdoor / Rock / Forest palette
/// Inspired by Patagonia, Black Diamond, The North Face
enum TopOutTheme {
    // MARK: - Background
    /// Deep warm charcoal with brown undertone
    static let backgroundPrimary = Color(red: 0.08, green: 0.07, blue: 0.06)
    /// Slightly lighter for cards/surfaces
    static let backgroundCard = Color(red: 0.13, green: 0.11, blue: 0.10)
    /// Elevated surface (sheets, modals)
    static let backgroundElevated = Color(red: 0.16, green: 0.14, blue: 0.12)

    // MARK: - Accent — Forest Green
    static let accentGreen = Color(red: 0.30, green: 0.65, blue: 0.32)
    /// Darker moss / olive
    static let mossGreen = Color(red: 0.25, green: 0.50, blue: 0.25)
    /// Lighter sage for subtle highlights
    static let sageGreen = Color(red: 0.45, green: 0.62, blue: 0.40)

    // MARK: - Accent — Earth / Rock Brown
    static let rockBrown = Color(red: 0.60, green: 0.45, blue: 0.30)
    static let earthBrown = Color(red: 0.50, green: 0.38, blue: 0.25)
    /// Warm sand for secondary text
    static let sandBeige = Color(red: 0.75, green: 0.68, blue: 0.55)

    // MARK: - Text
    /// Primary text — warm off-white
    static let textPrimary = Color(red: 0.94, green: 0.91, blue: 0.86)
    /// Secondary text — warm gray
    static let textSecondary = Color(red: 0.60, green: 0.56, blue: 0.50)
    /// Tertiary / disabled
    static let textTertiary = Color(red: 0.40, green: 0.37, blue: 0.33)

    // MARK: - Semantic
    static let heartRed = Color(red: 0.85, green: 0.25, blue: 0.20)
    static let warningAmber = Color(red: 0.90, green: 0.65, blue: 0.20)
    static let streakOrange = Color(red: 0.88, green: 0.50, blue: 0.18)

    // MARK: - Gradients
    static let greenGradient = LinearGradient(
        colors: [accentGreen, mossGreen],
        startPoint: .leading, endPoint: .trailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.09, blue: 0.07),
            Color(red: 0.06, green: 0.05, blue: 0.04)
        ],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: - Card style helper
    static let cardRadius: CGFloat = 16
    static let cardStroke = Color.white.opacity(0.06)
}

// MARK: - Convenience modifiers

extension View {
    func topOutCard() -> some View {
        self
            .padding(16)
            .background(TopOutTheme.backgroundCard, in: RoundedRectangle(cornerRadius: TopOutTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TopOutTheme.cardRadius)
                    .stroke(TopOutTheme.cardStroke, lineWidth: 1)
            )
    }

    func topOutBackground() -> some View {
        self.background(TopOutTheme.backgroundPrimary.ignoresSafeArea())
    }
}
