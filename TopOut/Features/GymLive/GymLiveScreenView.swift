import SwiftUI

/// I-7: Gym real-time live screen - shows all visible climbers at a gym
struct GymLiveScreenView: View {
    let gym: Gym
    @StateObject private var wsService = WebSocketService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    if wsService.gymLiveClimbers.isEmpty {
                        emptyState
                    } else {
                        // Climber grid
                        ScrollView {
                            LazyVGrid(
                                columns: gridColumns(for: geometry.size),
                                spacing: 16
                            ) {
                                ForEach(wsService.gymLiveClimbers) { climber in
                                    ClimberCardView(climber: climber)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { wsService.subscribeToGym(gym.id) }
        .onDisappear { wsService.unsubscribeFromGym() }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("\(wsService.gymLiveClimbers.count) 人正在攀爬")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            // Live indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red.opacity(0.2), in: Capsule())
        }
        .padding()
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text("暂无攀爬者")
                .font(.title3)
                .foregroundStyle(.gray)
            Text("等待有人开始攀爬...")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.6))
            Spacer()
        }
    }
    
    private func gridColumns(for size: CGSize) -> [GridItem] {
        let isLandscape = size.width > size.height
        let count = isLandscape ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
}

// MARK: - Climber Card

struct ClimberCardView: View {
    let climber: LiveClimber
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(climber.state == .climbing ? Color.green.opacity(0.2) : Color.yellow.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                if climber.isAnonymous {
                    Image(systemName: "person.fill.questionmark")
                        .font(.title2)
                        .foregroundStyle(.gray)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
                
                // Status dot
                Circle()
                    .fill(climber.state == .climbing ? .green : .yellow)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.black, lineWidth: 2))
                    .offset(x: 20, y: 20)
            }
            
            // Name
            Text(climber.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            // Status
            Text(climber.state.displayName)
                .font(.caption)
                .foregroundStyle(climber.state == .climbing ? .green : .yellow)
            
            // Heart rate
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                Text("\(Int(climber.heartRate))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.red)
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(.red.opacity(0.7))
            }
            
            // Duration
            Text(climber.duration.formattedDuration)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    climber.state == .climbing ? Color.green.opacity(0.3) : Color.yellow.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    GymLiveScreenView(gym: Gym(
        id: "1", name: "岩时攀岩馆（朝阳店）",
        address: "朝阳区", city: "北京",
        latitude: 39.9, longitude: 116.4, activeClimbers: 5
    ))
}
