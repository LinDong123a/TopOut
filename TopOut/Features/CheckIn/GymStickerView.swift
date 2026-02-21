import SwiftUI

/// Programmatically generated sticker for a gym check-in
struct GymStickerView: View {
    let gymName: String
    let date: Date
    let holiday: HolidayInfo?
    var size: CGFloat = 120
    
    private var palette: (primary: Color, secondary: Color) {
        let colors: [(Color, Color)] = [
            (TopOutTheme.accentGreen, TopOutTheme.mossGreen),
            (TopOutTheme.rockBrown, TopOutTheme.earthBrown),
            (TopOutTheme.streakOrange, TopOutTheme.rockBrown),
            (TopOutTheme.sageGreen, TopOutTheme.accentGreen),
            (TopOutTheme.heartRed, TopOutTheme.streakOrange),
            (TopOutTheme.warningAmber, TopOutTheme.earthBrown),
        ]
        let hash = abs(gymName.hashValue)
        return colors[hash % colors.count]
    }
    
    private var firstChar: String {
        String(gymName.prefix(1))
    }
    
    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M.dd"
        return fmt.string(from: date)
    }
    
    private var isHoliday: Bool { holiday != nil }
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.primary, palette.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Holiday border
            if isHoliday {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .yellow, .red],
                            center: .center
                        ),
                        lineWidth: size * 0.04
                    )
                    .frame(width: size * 0.95, height: size * 0.95)
            }
            
            // Inner content
            VStack(spacing: size * 0.02) {
                // Decoration symbol at top
                if let h = holiday {
                    Text(h.emoji)
                        .font(.system(size: size * 0.14))
                } else {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: size * 0.12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Large first character
                Text(firstChar)
                    .font(.system(size: size * 0.3, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                
                // Gym name (truncated)
                Text(gymName.prefix(8) + (gymName.count > 8 ? "…" : ""))
                    .font(.system(size: size * 0.08, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                
                // Date
                Text(dateString)
                    .font(.system(size: size * 0.07, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            // Climbing figure decoration
            Image(systemName: "figure.climbing")
                .font(.system(size: size * 0.1))
                .foregroundStyle(.white.opacity(0.2))
                .offset(x: size * 0.3, y: size * 0.3)
            
            // Holiday limited badge
            if isHoliday {
                Text("🔥限定")
                    .font(.system(size: size * 0.08, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, size * 0.06)
                    .padding(.vertical, size * 0.02)
                    .background(Capsule().fill(.red))
                    .offset(x: size * 0.28, y: -size * 0.38)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        GymStickerView(gymName: "岩时攀岩馆", date: Date(), holiday: nil)
        GymStickerView(gymName: "岩舞空间", date: Date(), holiday: HolidayInfo(name: "春节", emoji: "🧧", symbol: "lantern.fill"))
    }
    .padding()
    .background(TopOutTheme.backgroundPrimary)
}
