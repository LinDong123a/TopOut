import SwiftUI

/// Full-screen celebration effect when receiving a cheer
struct CelebrationView: View {
    let fromUser: String
    @Binding var isPresented: Bool
    
    @State private var bannerOffset: CGFloat = -120
    @State private var particles: [CelebrationParticle] = []
    
    private let celebrationEmojis = ["🔥", "💪", "🧗", "👏", "⭐", "🎉", "❤️", "🏔️", "💥", "✨"]
    
    var body: some View {
        ZStack {
            // Particles
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.fontSize))
                    .offset(x: p.currentX, y: p.currentY)
                    .rotationEffect(.degrees(p.rotation))
                    .opacity(p.opacity)
            }
            
            // Banner at top
            VStack {
                Text("\(fromUser) 为你加油 🔥")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(TopOutTheme.backgroundElevated)
                            .overlay(
                                Capsule()
                                    .stroke(TopOutTheme.accentGreen.opacity(0.5), lineWidth: 1.5)
                            )
                            .shadow(color: TopOutTheme.accentGreen.opacity(0.4), radius: 12, y: 4)
                    )
                    .offset(y: bannerOffset)
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .allowsHitTesting(false)
        .onAppear {
            showCelebration()
        }
    }
    
    private func showCelebration() {
        // Banner spring in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            bannerOffset = 0
        }
        
        // Spawn center particles
        let count = Int.random(in: 20...30)
        let newParticles = (0..<count).map { _ in
            CelebrationParticle(
                emoji: celebrationEmojis.randomElement()!,
                fontSize: CGFloat.random(in: 18...32),
                targetX: CGFloat.random(in: -180...180),
                targetY: CGFloat.random(in: -250...250),
                targetRotation: Double.random(in: -360...360)
            )
        }
        particles = newParticles
        
        // Animate particles outward
        for (i, p) in newParticles.enumerated() {
            let delay = Double(i) * 0.02
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 1.5)) {
                    if let idx = particles.firstIndex(where: { $0.id == p.id }) {
                        particles[idx].currentX = p.targetX
                        particles[idx].currentY = p.targetY
                        particles[idx].rotation = p.targetRotation
                        particles[idx].opacity = 0
                    }
                }
            }
        }
        
        // Banner slide out after 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                bannerOffset = -120
            }
        }
        
        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isPresented = false
            particles.removeAll()
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let fontSize: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let targetRotation: Double
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var rotation: Double = 0
    var opacity: Double = 1
}
