import SwiftUI

/// Full-screen celebration after a successful check-in
struct CheckInSuccessView: View {
    let gymName: String
    let streakDays: Int
    let holiday: HolidayInfo?
    @Binding var isPresented: Bool
    
    @State private var stickerScale: CGFloat = 0.1
    @State private var stickerOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var particles: [CelebrationParticle] = []
    @State private var canDismiss = false
    
    private let celebrationEmojis = ["🔥", "💪", "🧗", "👏", "⭐", "🎉", "🏔️", "✨", "🪨", "🎊"]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { if canDismiss { isPresented = false } }
            
            // Particles
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.fontSize))
                    .offset(x: p.currentX, y: p.currentY)
                    .rotationEffect(.degrees(p.rotation))
                    .opacity(p.opacity)
            }
            
            // Content
            VStack(spacing: 24) {
                Text("🎉 打卡成功！")
                    .font(.title.weight(.bold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                    .opacity(textOpacity)
                
                GymStickerView(gymName: gymName, date: Date(), holiday: holiday, size: 160)
                    .scaleEffect(stickerScale)
                    .opacity(stickerOpacity)
                
                VStack(spacing: 8) {
                    if streakDays > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(TopOutTheme.streakOrange)
                            Text("连续 \(streakDays) 天到馆")
                                .font(.headline)
                                .foregroundStyle(TopOutTheme.streakOrange)
                        }
                    }
                    
                    if let h = holiday {
                        Text("获得 \(h.name) 限定贴纸！")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TopOutTheme.warningAmber)
                    }
                }
                .opacity(textOpacity)
                
                if canDismiss {
                    Button {
                        isPresented = false
                    } label: {
                        Text("太棒了！")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(TopOutTheme.accentGreen, in: Capsule())
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { playCelebration() }
    }
    
    private func playCelebration() {
        // Sticker spring in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            stickerScale = 1.0
            stickerOpacity = 1.0
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Confetti particles
        let count = Int.random(in: 25...35)
        let newParticles = (0..<count).map { _ in
            CelebrationParticle(
                emoji: celebrationEmojis.randomElement()!,
                fontSize: CGFloat.random(in: 16...30),
                targetX: CGFloat.random(in: -200...200),
                targetY: CGFloat.random(in: -300...300),
                targetRotation: Double.random(in: -360...360)
            )
        }
        particles = newParticles
        
        for (i, p) in newParticles.enumerated() {
            let delay = Double(i) * 0.02
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 1.8)) {
                    if let idx = particles.firstIndex(where: { $0.id == p.id }) {
                        particles[idx].currentX = p.targetX
                        particles[idx].currentY = p.targetY
                        particles[idx].rotation = p.targetRotation
                        particles[idx].opacity = 0
                    }
                }
            }
        }
        
        // Show dismiss button after 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                canDismiss = true
            }
        }
    }
}

#Preview {
    CheckInSuccessView(
        gymName: "岩时攀岩馆",
        streakDays: 5,
        holiday: nil,
        isPresented: .constant(true)
    )
}
