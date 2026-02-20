import SwiftUI

// MARK: - Mock Data

private struct LiveGym: Identifiable {
    let id = UUID()
    let name: String
    let climberCount: Int
}

private struct NewRoute: Identifiable {
    let id = UUID()
    let gymName: String
    let newCount: Int
    let difficulties: [String]
}

private struct HotVideo: Identifiable {
    let id = UUID()
    let climberName: String
    let difficulty: String
    let likes: Int
    let color: Color
}

private let mockLiveGyms: [LiveGym] = [
    .init(name: "岩时攀岩馆（望京店）", climberCount: Int.random(in: 3...15)),
    .init(name: "岩舞空间（三里屯）", climberCount: Int.random(in: 2...12)),
    .init(name: "石刻攀岩（朝阳大悦城）", climberCount: Int.random(in: 1...8)),
    .init(name: "Boulderland（国贸）", climberCount: Int.random(in: 4...10)),
    .init(name: "Beta 攀岩馆（中关村）", climberCount: Int.random(in: 2...9)),
]

private let mockNewRoutes: [NewRoute] = [
    .init(gymName: "岩时攀岩馆", newCount: 12, difficulties: ["V3", "V5", "V7"]),
    .init(gymName: "岩舞空间", newCount: 8, difficulties: ["V2", "V4", "V6"]),
    .init(gymName: "石刻攀岩", newCount: 5, difficulties: ["V4", "V5"]),
    .init(gymName: "Boulderland", newCount: 15, difficulties: ["V3", "V5", "V8", "V10"]),
]

private let mockHotVideos: [HotVideo] = [
    .init(climberName: "小岩", difficulty: "V7", likes: 234, color: .red.opacity(0.3)),
    .init(climberName: "Luna", difficulty: "V5", likes: 189, color: .blue.opacity(0.3)),
    .init(climberName: "阿飞", difficulty: "5.12a", likes: 156, color: .green.opacity(0.3)),
    .init(climberName: "攀岩小白", difficulty: "V3", likes: 312, color: .purple.opacity(0.3)),
    .init(climberName: "岩壁舞者", difficulty: "V8", likes: 445, color: .orange.opacity(0.3)),
    .init(climberName: "送分童子", difficulty: "V4", likes: 98, color: .pink.opacity(0.3)),
]

// MARK: - HomeView

struct HomeView: View {
    @State private var showSpectate = false
    @State private var liveExpanded = false
    @State private var appeared = [false, false, false, false]
    
    private var totalClimbers: Int {
        mockLiveGyms.reduce(0) { $0 + $1.climberCount }
    }
    
    var body: some View {
        ZStack {
            TopOutTheme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    liveClimbingSection
                        .offset(y: appeared[0] ? 0 : 30)
                        .opacity(appeared[0] ? 1 : 0)
                    
                    newRoutesSection
                        .offset(y: appeared[1] ? 0 : 30)
                        .opacity(appeared[1] ? 1 : 0)
                    
                    hotVideosSection
                        .offset(y: appeared[2] ? 0 : 30)
                        .opacity(appeared[2] ? 1 : 0)
                    
                    // Bottom spectate area
                    spectateBottomSection
                        .offset(y: appeared[3] ? 0 : 30)
                        .opacity(appeared[3] ? 1 : 0)
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
        .onAppear {
            for i in appeared.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.1)) {
                    appeared[i] = true
                }
            }
        }
        .sheet(isPresented: $showSpectate) {
            SpectateView()
        }
    }
    
    // MARK: - Live Climbing
    
    private var liveClimbingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    liveExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("🧗 \(totalClimbers) 人正在攀岩")
                        .font(.title2.bold())
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Image(systemName: liveExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(TopOutTheme.textTertiary)
                        .font(.caption)
                }
            }
            
            if liveExpanded {
                ForEach(mockLiveGyms) { gym in
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(TopOutTheme.sageGreen)
                            .font(.caption)
                        Text(gym.name)
                            .font(.subheadline)
                            .foregroundStyle(TopOutTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(gym.climberCount) 人")
                            .font(.subheadline.bold())
                            .foregroundStyle(TopOutTheme.accentGreen)
                    }
                    .padding(.vertical, 6)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .topOutCard()
    }
    
    // MARK: - New Routes
    
    private var newRoutesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🆕 新增好线")
                .font(.title3.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            
            ForEach(mockNewRoutes) { route in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.gymName)
                            .font(.subheadline.bold())
                            .foregroundStyle(TopOutTheme.textPrimary)
                        Text("+\(route.newCount) 条新线")
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(route.difficulties, id: \.self) { diff in
                            Text(diff)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(TopOutTheme.accentGreen.opacity(0.15), in: Capsule())
                                .foregroundStyle(TopOutTheme.accentGreen)
                        }
                    }
                }
                .padding(.vertical, 4)
                if route.id != mockNewRoutes.last?.id {
                    Divider().overlay(TopOutTheme.cardStroke)
                }
            }
        }
        .topOutCard()
    }
    
    // MARK: - Hot Videos
    
    private var hotVideosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔥 热门视频")
                .font(.title3.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(mockHotVideos) { video in
                        VStack(alignment: .leading, spacing: 8) {
                            // Thumbnail placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(video.color)
                                .frame(width: 160, height: 200)
                                .overlay {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            
                            Text(video.climberName)
                                .font(.subheadline.bold())
                                .foregroundStyle(TopOutTheme.textPrimary)
                            
                            HStack(spacing: 8) {
                                Text(video.difficulty)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(TopOutTheme.accentGreen.opacity(0.15), in: Capsule())
                                    .foregroundStyle(TopOutTheme.accentGreen)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                    Text("\(video.likes)")
                                        .font(.caption)
                                }
                                .foregroundStyle(TopOutTheme.heartRed)
                            }
                        }
                        .frame(width: 160)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Spectate
    
    private var spectateBottomSection: some View {
        Button {
            showSpectate = true
        } label: {
            HStack(spacing: 8) {
                Text("🔥")
                Text("\(totalClimbers) 人正在攀岩")
                    .font(.subheadline.bold())
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("去围观 →")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }
            .topOutCard()
        }
    }
}

#Preview {
    HomeView()
}
