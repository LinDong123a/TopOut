import SwiftUI
import SwiftData

// MARK: - Mock Data

private struct NearbyGymInfo: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let isOpen: Bool
    let openHours: String
    let routeCount: Int
    let newRoutes: Int
    let address: String
}

private struct FeaturedContent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: String
    let color: Color
    let icon: String
}

private let mockNearbyGyms: [NearbyGymInfo] = [
    .init(name: "岩时攀岩馆（望京店）", distance: "800m", isOpen: true, openHours: "10:00-22:00", routeCount: 86, newRoutes: 12, address: "朝阳区望京SOHO T2"),
    .init(name: "岩舞空间（三里屯）", distance: "2.3km", isOpen: true, openHours: "10:00-23:00", routeCount: 65, newRoutes: 8, address: "朝阳区三里屯太古里北区"),
    .init(name: "石刻攀岩（朝阳大悦城）", distance: "4.1km", isOpen: false, openHours: "10:00-21:30", routeCount: 52, newRoutes: 5, address: "朝阳区朝阳北路101号"),
]

private let mockFeatured: [FeaturedContent] = [
    .init(title: "新手入门：抱石 V0-V2 技巧全解", subtitle: "从零开始的攀岩之旅", category: "教程", color: .blue.opacity(0.3), icon: "book.fill"),
    .init(title: "2026 北京岩馆大盘点", subtitle: "15 家岩馆横向评测", category: "评测", color: .orange.opacity(0.3), icon: "star.fill"),
    .init(title: "脚法训练指南：提升你的 Footwork", subtitle: "职业定线员分享", category: "技巧", color: .green.opacity(0.3), icon: "figure.climbing"),
    .init(title: "攀岩损伤预防与恢复", subtitle: "指皮保护 & 拉伤处理", category: "健康", color: .red.opacity(0.3), icon: "cross.case.fill"),
    .init(title: "户外攀岩第一次：白河攻略", subtitle: "装备清单+线路推荐", category: "户外", color: .purple.opacity(0.3), icon: "mountain.2.fill"),
]

// MARK: - HomeView

struct HomeView: View {
    @State private var appeared = [false, false, false]
    @State private var showGymSelector = false
    
    var body: some View {
        ZStack {
            TopOutTheme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Nearby gyms
                    nearbyGymsSection
                        .offset(y: appeared[0] ? 0 : 30)
                        .opacity(appeared[0] ? 1 : 0)
                    
                    // Weekly report / goals
                    weeklySection
                        .offset(y: appeared[1] ? 0 : 30)
                        .opacity(appeared[1] ? 1 : 0)
                    
                    // Featured content
                    featuredSection
                        .offset(y: appeared[2] ? 0 : 30)
                        .opacity(appeared[2] ? 1 : 0)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .onAppear {
            for i in appeared.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.1)) {
                    appeared[i] = true
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2.bold())
                    .foregroundStyle(TopOutTheme.textPrimary)
                Text("今天想去哪里攀岩？")
                    .font(.subheadline)
                    .foregroundStyle(TopOutTheme.textSecondary)
            }
            Spacer()
            // Location indicator
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text("北京")
                    .font(.caption)
            }
            .foregroundStyle(TopOutTheme.accentGreen)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "夜深了 🌙" }
        if hour < 12 { return "早上好 ☀️" }
        if hour < 18 { return "下午好 🧗" }
        return "晚上好 🌆"
    }
    
    // MARK: - Nearby Gyms
    
    private var nearbyGymsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("📍 附近岩馆")
                    .font(.title3.bold())
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("查看全部 →")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }
            
            ForEach(mockNearbyGyms) { gym in
                gymCard(gym)
            }
        }
    }
    
    private func gymCard(_ gym: NearbyGymInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(gym.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TopOutTheme.textPrimary)
                            .lineLimit(1)
                    }
                    Text(gym.address)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(gym.distance)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(TopOutTheme.accentGreen)
                    
                    HStack(spacing: 3) {
                        Circle()
                            .fill(gym.isOpen ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                            .frame(width: 6, height: 6)
                        Text(gym.isOpen ? "营业中" : "已关门")
                            .font(.system(size: 11))
                            .foregroundStyle(gym.isOpen ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 10))
                    Text("\(gym.routeCount) 条线路")
                        .font(.system(size: 12))
                }
                .foregroundStyle(TopOutTheme.textSecondary)
                
                if gym.newRoutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("+\(gym.newRoutes) 新线")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(TopOutTheme.streakOrange)
                }
                
                Spacer()
                
                Text(gym.openHours)
                    .font(.system(size: 11))
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .topOutCard()
    }
    
    // MARK: - Weekly Section
    
    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("📊 本周攀爬")
                .font(.title3.bold())
                .foregroundStyle(TopOutTheme.textPrimary)
            
            // Check if user has records — show goal setter if none
            weeklyContent
        }
    }
    
    @ViewBuilder
    private var weeklyContent: some View {
        // For now show mock stats; when empty will show goal prompt
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                weekStat(value: "12", label: "完成条数", icon: "figure.climbing", color: TopOutTheme.accentGreen)
                weekStat(value: "3h", label: "攀爬时长", icon: "clock", color: TopOutTheme.rockBrown)
                weekStat(value: "V5", label: "最高难度", icon: "arrow.up.circle", color: TopOutTheme.streakOrange)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("本周目标：20 条")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textSecondary)
                    Spacer()
                    Text("12/20")
                        .font(.caption.bold())
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(TopOutTheme.backgroundCard)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(TopOutTheme.accentGreen)
                            .frame(width: geo.size.width * 0.6, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Set goal button when no goal
            Button {
                // TODO: goal setting
            } label: {
                Text("调整目标")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TopOutTheme.accentGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
            }
        }
        .topOutCard()
    }
    
    private func weekStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(TopOutTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(TopOutTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Featured Content
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🎯 精选内容")
                    .font(.title3.bold())
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("更多 →")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(mockFeatured) { item in
                        featuredCard(item)
                    }
                }
            }
        }
    }
    
    private func featuredCard(_ item: FeaturedContent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cover
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color)
                .frame(width: 200, height: 120)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            // Category tag
            Text(item.category)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TopOutTheme.accentGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
            
            Text(item.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TopOutTheme.textPrimary)
                .lineLimit(2)
            
            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(width: 200)
    }
}

#Preview {
    HomeView()
}
