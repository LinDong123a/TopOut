import SwiftUI

/// Reusable cheer/like button with Duolingo-style emoji burst animation
struct CheerButton: View {
    @Binding var isLiked: Bool
    var emoji: String = "👍"
    var likedColor: Color = TopOutTheme.accentGreen
    
    @State private var scale: CGFloat = 1.0
    @State private var particles: [EmojiParticle] = []
    
    private let burstEmojis = ["🔥", "💪", "🧗", "👏", "⭐"]
    
    var body: some View {
        Button {
            toggle()
        } label: {
            Text(emoji)
                .font(.title3)
                .padding(8)
                .background(
                    Circle()
                        .fill(isLiked ? likedColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isLiked ? likedColor : TopOutTheme.textTertiary, lineWidth: 1.5)
                )
        }
        .scaleEffect(scale)
        .overlay {
            ZStack {
                ForEach(particles) { p in
                    Text(p.emoji)
                        .font(.body)
                        .offset(x: p.currentX, y: p.currentY)
                        .rotationEffect(.degrees(p.rotation))
                        .opacity(p.opacity)
                }
            }
            .allowsHitTesting(false)
        }
        .buttonStyle(.plain)
    }
    
    private func toggle() {
        let wasLiked = isLiked
        isLiked.toggle()
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        if !wasLiked {
            // Bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
            // Burst
            spawnParticles()
        } else {
            // Unlike: shrink
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
        }
    }
    
    private func spawnParticles() {
        let newParticles = (0..<5).map { _ in
            EmojiParticle(
                emoji: burstEmojis.randomElement()!,
                targetX: CGFloat.random(in: -40...40),
                targetY: -CGFloat.random(in: 80...120),
                targetRotation: Double.random(in: -180...180)
            )
        }
        particles.append(contentsOf: newParticles)
        
        for p in newParticles {
            withAnimation(.easeOut(duration: 0.8)) {
                if let idx = particles.firstIndex(where: { $0.id == p.id }) {
                    particles[idx].currentX = p.targetX
                    particles[idx].currentY = p.targetY
                    particles[idx].rotation = p.targetRotation
                    particles[idx].opacity = 0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll { p in newParticles.contains(where: { $0.id == p.id }) }
        }
    }
}

struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let targetX: CGFloat
    let targetY: CGFloat
    let targetRotation: Double
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var rotation: Double = 0
    var opacity: Double = 1
}

#Preview {
    struct Demo: View {
        @State private var liked = false
        var body: some View {
            CheerButton(isLiked: $liked)
                .padding(40)
                .background(TopOutTheme.backgroundPrimary)
        }
    }
    return Demo()
}
