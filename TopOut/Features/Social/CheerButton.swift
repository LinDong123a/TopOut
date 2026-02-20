import SwiftUI

struct CheerButton: View {
    @Binding var isLiked: Bool
    var emoji: String = "👍"
    var likedColor: Color = TopOutTheme.accentGreen
    
    @State private var scale: CGFloat = 1.0
    @State private var showBurst = false
    @State private var burstID = UUID()
    
    var body: some View {
        Button {
            toggle()
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(isLiked ? likedColor.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isLiked ? likedColor : TopOutTheme.textTertiary.opacity(0.3), lineWidth: 1.5)
                    )
                
                // Emoji
                Text(emoji)
                    .font(.title3)
            }
        }
        .scaleEffect(scale)
        .overlay {
            if showBurst {
                EmojiBurstView(id: burstID)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLiked)
    }
    
    private func toggle() {
        let wasLiked = isLiked
        isLiked.toggle()
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        if !wasLiked {
            // Bounce animation
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                scale = 1.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
            // Emoji burst
            burstID = UUID()
            showBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showBurst = false
            }
        } else {
            // Unlike shrink
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                scale = 0.75
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

// Separate view for burst animation — each instance animates on appear
struct EmojiBurstView: View {
    let id: UUID
    private let emojis = ["🔥", "💪", "🧗", "👏", "⭐", "🎉"]
    
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                SingleParticle(emoji: emojis[i], delay: Double(i) * 0.03, index: i)
            }
        }
    }
}

struct SingleParticle: View {
    let emoji: String
    let delay: Double
    let index: Int
    
    @State private var launched = false
    
    private var angle: Double {
        Double(index) * 60 + Double.random(in: -15...15)
    }
    
    private var distance: CGFloat {
        CGFloat.random(in: 50...90)
    }
    
    private var targetX: CGFloat {
        cos(angle * .pi / 180) * distance
    }
    
    private var targetY: CGFloat {
        sin(angle * .pi / 180) * distance - 30 // bias upward
    }
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 20))
            .offset(x: launched ? targetX : 0, y: launched ? targetY : 0)
            .scaleEffect(launched ? 0.3 : 1.2)
            .opacity(launched ? 0 : 1)
            .rotationEffect(.degrees(launched ? Double.random(in: -90...90) : 0))
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    launched = true
                }
            }
    }
}

#Preview {
    struct Demo: View {
        @State private var liked = false
        var body: some View {
            VStack(spacing: 40) {
                CheerButton(isLiked: $liked)
                Text(liked ? "已加油!" : "点击加油")
                    .foregroundStyle(.white)
            }
            .padding(60)
            .background(TopOutTheme.backgroundPrimary)
        }
    }
    return Demo()
}
