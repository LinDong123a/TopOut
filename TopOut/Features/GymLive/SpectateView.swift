import SwiftUI

/// Mock data for spectate view demo
struct SpectateClimber: Identifiable {
    let id = UUID().uuidString
    let nickname: String
    let isAnonymous: Bool
    let heartRate: Int
    let duration: TimeInterval // seconds
    let state: ClimbState
    
    var displayName: String {
        isAnonymous ? "攀岩者 #\(id.prefix(4).uppercased())" : nickname
    }
}

struct SpectateGym: Identifiable {
    let id = UUID().uuidString
    let name: String
    let climbers: [SpectateClimber]
}

// MARK: - Mock Data

private let mockCurrentGymClimbers: [SpectateClimber] = [
    .init(nickname: "小岩", isAnonymous: false, heartRate: 156, duration: 1320, state: .climbing),
    .init(nickname: "", isAnonymous: true, heartRate: 142, duration: 780, state: .climbing),
    .init(nickname: "阿飞", isAnonymous: false, heartRate: 134, duration: 2100, state: .resting),
    .init(nickname: "Luna", isAnonymous: false, heartRate: 165, duration: 420, state: .climbing),
    .init(nickname: "", isAnonymous: true, heartRate: 128, duration: 1560, state: .resting),
]

private let mockOtherGyms: [SpectateGym] = [
    SpectateGym(name: "奥岩攀岩馆（望京店）", climbers: [
        .init(nickname: "石头", isAnonymous: false, heartRate: 148, duration: 960, state: .climbing),
        .init(nickname: "", isAnonymous: true, heartRate: 138, duration: 1800, state: .climbing),
        .init(nickname: "攀登者K", isAnonymous: false, heartRate: 155, duration: 300, state: .climbing),
    ]),
    SpectateGym(name: "巅峰攀岩（三里屯）", climbers: [
        .init(nickname: "", isAnonymous: true, heartRate: 161, duration: 540, state: .climbing),
        .init(nickname: "岩壁精灵", isAnonymous: false, heartRate: 133, duration: 2400, state: .resting),
    ]),
    SpectateGym(name: "首攀攀岩馆", climbers: [
        .init(nickname: "猴子", isAnonymous: false, heartRate: 170, duration: 180, state: .climbing),
        .init(nickname: "", isAnonymous: true, heartRate: 125, duration: 2700, state: .resting),
        .init(nickname: "大壁", isAnonymous: false, heartRate: 145, duration: 1080, state: .climbing),
    ]),
    SpectateGym(name: "岩舞空间（国贸）", climbers: [
        .init(nickname: "Spider", isAnonymous: false, heartRate: 152, duration: 600, state: .climbing),
    ]),
]

private var mockTotalCount: Int {
    mockCurrentGymClimbers.count + mockOtherGyms.reduce(0) { $0 + $1.climbers.count }
}

// MARK: - SpectateView

struct SpectateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(TopOutTheme.streakOrange)
                        Text("全网 \(mockTotalCount) 人正在攀岩")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Current gym section
                    currentGymSection
                    
                    // Other gyms
                    ForEach(Array(mockOtherGyms.enumerated()), id: \.element.id) { index, gym in
                        gymSection(gym: gym, index: index + 1)
                    }
                }
                .padding(.bottom, 20)
            }
            .topOutBackground()
            .navigationTitle("围观")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(TopOutTheme.textTertiary)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Current Gym
    
    private var currentGymSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(TopOutTheme.accentGreen)
                Text("岩时攀岩馆")
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                
                Text("当前场馆")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(TopOutTheme.accentGreen, in: Capsule())
                
                Spacer()
                
                Text("\(mockCurrentGymClimbers.count) 人")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }
            .padding(.horizontal)
            
            ForEach(Array(mockCurrentGymClimbers.enumerated()), id: \.element.id) { i, climber in
                climberRow(climber: climber, highlight: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.05), value: appeared)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TopOutTheme.accentGreen.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TopOutTheme.accentGreen.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Other Gym Section
    
    private func gymSection(gym: SpectateGym, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(TopOutTheme.rockBrown)
                    .font(.caption)
                Text(gym.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("\(gym.climbers.count) 人")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            .padding(.horizontal)
            
            ForEach(gym.climbers) { climber in
                climberRow(climber: climber, highlight: false)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.3), value: appeared)
    }
    
    // MARK: - Climber Row
    
    private func climberRow(climber: SpectateClimber, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(climber.state == .climbing
                          ? TopOutTheme.accentGreen.opacity(0.15)
                          : TopOutTheme.warningAmber.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: climber.isAnonymous ? "person.fill.questionmark" : "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(climber.isAnonymous ? TopOutTheme.textTertiary : TopOutTheme.sageGreen)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(climber.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TopOutTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // State
                    Text(climber.state.emoji + " " + climber.state.displayName)
                        .font(.caption2)
                        .foregroundStyle(climber.state == .climbing ? TopOutTheme.accentGreen : TopOutTheme.warningAmber)
                    
                    // Duration
                    Text(formatMinutes(climber.duration))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }
            
            Spacer()
            
            // Heart rate
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(TopOutTheme.heartRed)
                Text("\(climber.heartRate)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(TopOutTheme.heartRed)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        return "\(m) 分钟"
    }
}

// MARK: - Floating Spectate Button

struct FloatingSpectateButton: View {
    let totalCount: Int
    let action: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.body)
                Text("\(totalCount) 人正在攀岩")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TopOutTheme.textPrimary)
                Image(systemName: "chevron.up")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(TopOutTheme.backgroundPrimary)
                    .overlay(
                        Capsule()
                            .stroke(TopOutTheme.accentGreen.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: TopOutTheme.accentGreen.opacity(0.3), radius: 12, y: 4)
            )
        }
        .scaleEffect(isPulsing ? 1.03 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    SpectateView()
}
