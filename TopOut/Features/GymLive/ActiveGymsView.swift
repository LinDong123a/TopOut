import SwiftUI

/// Remote spectating — active gyms with card-based layout
struct ActiveGymsView: View {
    @State private var activeGyms: [Gym] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var favoriteGymIds: Set<String> = {
        Set(UserDefaults.standard.stringArray(forKey: "favoriteGyms") ?? [])
    }()
    @State private var selectedGym: Gym?

    private var sortedGyms: [Gym] {
        activeGyms.sorted { g1, g2 in
            let f1 = favoriteGymIds.contains(g1.id)
            let f2 = favoriteGymIds.contains(g2.id)
            if f1 != f2 { return f1 }
            return (g1.activeClimbers ?? 0) > (g2.activeClimbers ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading && activeGyms.isEmpty {
                    loadingState
                } else if let errorMessage, activeGyms.isEmpty {
                    errorState(errorMessage)
                } else if activeGyms.isEmpty {
                    emptyState
                } else {
                    gymList
                }
            }
            .topOutBackground()
            .navigationTitle("围观")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: loadGyms) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
                }
            }
            .refreshable { await loadGymsAsync() }
            .fullScreenCover(item: $selectedGym) { gym in
                NavigationStack {
                    GymLiveScreenView(gym: gym)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("关闭") { selectedGym = nil }
                                    .foregroundStyle(TopOutTheme.textSecondary)
                            }
                        }
                }
            }
            .task { await loadGymsAsync() }
        }
    }

    // MARK: - Gym List

    private var gymList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedGyms) { gym in
                Button { selectedGym = gym } label: {
                    GymCard(
                        gym: gym,
                        isFavorite: favoriteGymIds.contains(gym.id),
                        onToggleFavorite: { toggleFavorite(gym.id) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 120)
            ProgressView()
                .tint(TopOutTheme.textTertiary)
            Text("加载中…")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 100)
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundStyle(TopOutTheme.textTertiary.opacity(0.4))
            Text("加载失败")
                .font(.title3.weight(.semibold))
                .foregroundStyle(TopOutTheme.textSecondary)
            Text(msg)
                .font(.caption)
                .foregroundStyle(TopOutTheme.textTertiary)
                .multilineTextAlignment(.center)
            Button("重试") { loadGyms() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TopOutTheme.accentGreen)
                .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 100)
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            TopOutTheme.earthBrown.opacity(0.5),
                            TopOutTheme.mossGreen.opacity(0.4)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            Text("暂无活跃场馆")
                .font(.title3.weight(.semibold))
                .foregroundStyle(TopOutTheme.textSecondary)
            Text("当前没有人在攀爬，稍后再来看看")
                .font(.subheadline)
                .foregroundStyle(TopOutTheme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func loadGyms() {
        Task { await loadGymsAsync() }
    }

    private func loadGymsAsync() async {
        isLoading = activeGyms.isEmpty
        errorMessage = nil
        do {
            activeGyms = try await APIService.shared.getActiveGyms()
        } catch {
            if activeGyms.isEmpty { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }

    private func toggleFavorite(_ id: String) {
        if favoriteGymIds.contains(id) {
            favoriteGymIds.remove(id)
        } else {
            favoriteGymIds.insert(id)
        }
        UserDefaults.standard.set(Array(favoriteGymIds), forKey: "favoriteGyms")
    }
}

// MARK: - Gym Card

private struct GymCard: View {
    let gym: Gym
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(TopOutTheme.earthBrown.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(TopOutTheme.rockBrown)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                HStack(spacing: 10) {
                    Label(gym.city, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                    Label("\(gym.activeClimbers ?? 0) 人在爬",
                          systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite
                                     ? TopOutTheme.warningAmber
                                     : TopOutTheme.textTertiary)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TopOutTheme.textTertiary)
        }
        .topOutCard()
    }
}

#Preview {
    ActiveGymsView()
}
