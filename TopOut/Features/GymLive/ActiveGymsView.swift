import SwiftUI

/// I-8: Remote spectating - list of gyms with active climbers
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
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if let errorMessage {
                    ContentUnavailableView("加载失败", systemImage: "wifi.slash", description: Text(errorMessage))
                } else if activeGyms.isEmpty {
                    ContentUnavailableView(
                        "暂无活跃场馆",
                        systemImage: "building.2",
                        description: Text("当前没有人在攀爬")
                    )
                } else {
                    List(sortedGyms) { gym in
                        Button {
                            selectedGym = gym
                        } label: {
                            GymRowView(
                                gym: gym,
                                isFavorite: favoriteGymIds.contains(gym.id),
                                onToggleFavorite: { toggleFavorite(gym.id) }
                            )
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("围观")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: loadGyms) {
                        Image(systemName: "arrow.clockwise")
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
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
            .task { await loadGymsAsync() }
        }
    }
    
    private func loadGyms() {
        Task { await loadGymsAsync() }
    }
    
    private func loadGymsAsync() async {
        isLoading = activeGyms.isEmpty
        errorMessage = nil
        do {
            activeGyms = try await APIService.shared.getActiveGyms()
        } catch {
            if activeGyms.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
    
    private func toggleFavorite(_ gymId: String) {
        if favoriteGymIds.contains(gymId) {
            favoriteGymIds.remove(gymId)
        } else {
            favoriteGymIds.insert(gymId)
        }
        UserDefaults.standard.set(Array(favoriteGymIds), forKey: "favoriteGyms")
    }
}

// MARK: - Gym Row

struct GymRowView: View {
    let gym: Gym
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Gym icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Label(gym.city, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label("\(gym.activeClimbers ?? 0) 人", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ActiveGymsView()
}
