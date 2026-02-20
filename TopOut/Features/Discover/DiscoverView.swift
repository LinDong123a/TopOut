import SwiftUI

// MARK: - Mock Data Models

struct HotRoute: Identifiable {
    let id = UUID()
    let difficulty: String
    let gymName: String
    let rating: Double
    let completions: Int
}

struct OutdoorCrag: Identifiable {
    let id = UUID()
    let name: String
    let city: String
    let routeCount: Int
    let currentPeople: Int
}

struct ClassicRoute: Identifiable {
    let id = UUID()
    let name: String
    let difficulty: String
    let cragName: String
    let rating: Double
}

// MARK: - Mock Data

private let mockHotRoutes: [HotRoute] = [
    HotRoute(difficulty: "V4", gymName: "岩时攀岩馆", rating: 4.8, completions: 32),
    HotRoute(difficulty: "V5", gymName: "岩舞空间（三里屯）", rating: 4.6, completions: 28),
    HotRoute(difficulty: "V3", gymName: "奥攀攀岩馆", rating: 4.9, completions: 45),
    HotRoute(difficulty: "V6", gymName: "岩时攀岩馆", rating: 4.5, completions: 18),
    HotRoute(difficulty: "5.11a", gymName: "首攀攀岩（朝阳大悦城）", rating: 4.7, completions: 22),
    HotRoute(difficulty: "V4", gymName: "岩舞空间（三里屯）", rating: 4.4, completions: 35),
    HotRoute(difficulty: "5.10c", gymName: "奥攀攀岩馆", rating: 4.8, completions: 41),
    HotRoute(difficulty: "V7", gymName: "岩时攀岩馆", rating: 4.3, completions: 12),
    HotRoute(difficulty: "V5", gymName: "首攀攀岩（朝阳大悦城）", rating: 4.6, completions: 26),
    HotRoute(difficulty: "5.12a", gymName: "岩舞空间（三里屯）", rating: 4.9, completions: 8),
]

private let mockOutdoorCrags: [OutdoorCrag] = [
    OutdoorCrag(name: "阳朔", city: "广西", routeCount: 320, currentPeople: 45),
    OutdoorCrag(name: "白河", city: "北京", routeCount: 180, currentPeople: 23),
    OutdoorCrag(name: "昆明西山", city: "云南", routeCount: 95, currentPeople: 12),
    OutdoorCrag(name: "黔江小南海", city: "重庆", routeCount: 68, currentPeople: 8),
    OutdoorCrag(name: "仙人洞", city: "贵州", routeCount: 120, currentPeople: 15),
]

private let mockClassicRoutes: [ClassicRoute] = [
    ClassicRoute(name: "中国攀", difficulty: "5.14a", cragName: "阳朔", rating: 4.9),
    ClassicRoute(name: "白河之巅", difficulty: "5.12b", cragName: "白河", rating: 4.8),
    ClassicRoute(name: "金猫洞裂缝", difficulty: "5.11c", cragName: "阳朔", rating: 4.7),
    ClassicRoute(name: "西山经典", difficulty: "5.10d", cragName: "昆明西山", rating: 4.6),
    ClassicRoute(name: "猴子捞月", difficulty: "V8", cragName: "白河", rating: 4.8),
    ClassicRoute(name: "飞瀑直上", difficulty: "5.13a", cragName: "仙人洞", rating: 4.5),
    ClassicRoute(name: "月亮山裂缝", difficulty: "5.11a", cragName: "阳朔", rating: 4.7),
    ClassicRoute(name: "小南海之路", difficulty: "5.10b", cragName: "黔江小南海", rating: 4.4),
]

// MARK: - Reuse FollowedClimber

struct DiscoverClimber: Identifiable {
    let id = UUID()
    let nickname: String
    let avatarSymbol: String
    let grade: String
    let isLive: Bool
    let locationName: String?
    let heartRate: Int?
    var isFollowed: Bool = true
}

private func mockDiscoverClimbers(outdoor: Bool) -> [DiscoverClimber] {
    if outdoor {
        return [
            DiscoverClimber(nickname: "阿飞", avatarSymbol: "flame.fill", grade: "5.13a", isLive: true, locationName: "阳朔", heartRate: 158),
            DiscoverClimber(nickname: "大壁", avatarSymbol: "person.circle.fill", grade: "5.11b", isLive: true, locationName: "白河", heartRate: 145),
            DiscoverClimber(nickname: "猴子", avatarSymbol: "hare.fill", grade: "V7", isLive: false, locationName: nil, heartRate: nil),
            DiscoverClimber(nickname: "岩壁精灵", avatarSymbol: "leaf.circle.fill", grade: "5.12a", isLive: false, locationName: nil, heartRate: nil),
        ]
    } else {
        return [
            DiscoverClimber(nickname: "小岩", avatarSymbol: "figure.climbing", grade: "V6", isLive: true, locationName: "岩时攀岩馆", heartRate: 156),
            DiscoverClimber(nickname: "Luna", avatarSymbol: "star.circle.fill", grade: "V5", isLive: true, locationName: "奥攀攀岩馆", heartRate: 148),
            DiscoverClimber(nickname: "阿飞", avatarSymbol: "flame.fill", grade: "V8", isLive: true, locationName: "岩舞空间（三里屯）", heartRate: 162),
            DiscoverClimber(nickname: "石头", avatarSymbol: "mountain.2.fill", grade: "V4", isLive: false, locationName: nil, heartRate: nil),
            DiscoverClimber(nickname: "攀登者K", avatarSymbol: "bolt.circle.fill", grade: "V3", isLive: false, locationName: nil, heartRate: nil),
            DiscoverClimber(nickname: "猴子", avatarSymbol: "hare.fill", grade: "V7", isLive: false, locationName: nil, heartRate: nil),
            DiscoverClimber(nickname: "大壁", avatarSymbol: "person.circle.fill", grade: "V2", isLive: false, locationName: nil, heartRate: nil),
            DiscoverClimber(nickname: "岩壁精灵", avatarSymbol: "leaf.circle.fill", grade: "V5", isLive: false, locationName: nil, heartRate: nil),
        ]
    }
}

// MARK: - DiscoverView

struct DiscoverView: View {
    @State private var selectedMode = 0 // 0 = indoor, 1 = outdoor
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Segmented Picker
                Picker("模式", selection: $selectedMode) {
                    Text("室内").tag(0)
                    Text("户外").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                if selectedMode == 0 {
                    indoorContent
                } else {
                    outdoorContent
                }
            }
            .padding(.bottom, 20)
        }
        .topOutBackground()
        .navigationTitle("发现")
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Indoor

    private var indoorContent: some View {
        VStack(spacing: 20) {
            // Hot routes
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "🔥", title: "近期好线")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mockHotRoutes) { route in
                            hotRouteCard(route)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Who's climbing
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "👥", title: "谁在爬")
                    .padding(.horizontal, 16)

                LazyVStack(spacing: 10) {
                    ForEach(mockDiscoverClimbers(outdoor: false).sorted { a, _ in a.isLive }) { climber in
                        discoverClimberCard(climber)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Outdoor

    private var outdoorContent: some View {
        VStack(spacing: 20) {
            // Hot crags
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "🏔️", title: "热门岩场")

                LazyVStack(spacing: 10) {
                    ForEach(mockOutdoorCrags) { crag in
                        cragCard(crag)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Classic routes
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "🔥", title: "经典线路")

                LazyVStack(spacing: 8) {
                    ForEach(mockClassicRoutes) { route in
                        classicRouteRow(route)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Who's climbing outdoor
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "👥", title: "谁在爬")
                    .padding(.horizontal, 16)

                LazyVStack(spacing: 10) {
                    ForEach(mockDiscoverClimbers(outdoor: true).sorted { a, _ in a.isLive }) { climber in
                        discoverClimberCard(climber)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.title3)
            Text(title)
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func hotRouteCard(_ route: HotRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(route.difficulty)
                .font(.title2.bold())
                .foregroundStyle(TopOutTheme.accentGreen)

            Text(route.gymName)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textSecondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", route.rating))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(TopOutTheme.accentGreen)
                Text("\(route.completions)次完攀")
                    .font(.caption2)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
        }
        .frame(width: 140)
        .topOutCard()
    }

    private func cragCard(_ crag: OutdoorCrag) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(TopOutTheme.rockBrown.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "mountain.2.fill")
                    .font(.title3)
                    .foregroundStyle(TopOutTheme.rockBrown)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(crag.name)
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                Text(crag.city)
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(crag.routeCount) 条线路")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textSecondary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(TopOutTheme.accentGreen)
                        .frame(width: 6, height: 6)
                    Text("\(crag.currentPeople) 人在攀")
                        .font(.caption2)
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
        }
        .topOutCard()
    }

    private func classicRouteRow(_ route: ClassicRoute) -> some View {
        HStack(spacing: 12) {
            Text(route.difficulty)
                .font(.subheadline.bold())
                .foregroundStyle(TopOutTheme.accentGreen)
                .frame(width: 55, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(route.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TopOutTheme.textPrimary)
                Text(route.cragName)
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", route.rating))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
        }
        .topOutCard()
    }

    private func discoverClimberCard(_ climber: DiscoverClimber) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(climber.isLive
                              ? TopOutTheme.accentGreen.opacity(0.15)
                              : TopOutTheme.textTertiary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: climber.avatarSymbol)
                        .font(.title3)
                        .foregroundStyle(climber.isLive ? TopOutTheme.accentGreen : TopOutTheme.textSecondary)
                }
                if climber.isLive {
                    Circle()
                        .fill(TopOutTheme.accentGreen)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(TopOutTheme.backgroundCard, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(climber.nickname)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text(climber.grade)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TopOutTheme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
                }
                if climber.isLive, let loc = climber.locationName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(TopOutTheme.accentGreen)
                            .frame(width: 6, height: 6)
                        Text("实时攀爬中 · \(loc)")
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.accentGreen)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if climber.isLive, let hr = climber.heartRate {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(TopOutTheme.heartRed)
                    Text("\(hr)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(TopOutTheme.heartRed)
                }
            }
        }
        .topOutCard()
        .overlay(
            climber.isLive ?
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TopOutTheme.accentGreen.opacity(0.3), lineWidth: 1)
                : nil
        )
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
    }
}
