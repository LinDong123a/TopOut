import SwiftUI

struct NearbyGym: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let distanceMeters: Int
}

struct GymSelectorView: View {
    @Binding var selectedGymName: String
    @Environment(\.dismiss) private var dismiss
    
    private let nearbyGyms: [NearbyGym] = [
        NearbyGym(name: "岩时攀岩馆（望京店）", distance: "120m", distanceMeters: 120),
        NearbyGym(name: "岩舞空间（三里屯）", distance: "1.8km", distanceMeters: 1800),
        NearbyGym(name: "奥攀攀岩馆", distance: "3.2km", distanceMeters: 3200),
        NearbyGym(name: "首攀攀岩（朝阳大悦城）", distance: "4.5km", distanceMeters: 4500),
        NearbyGym(name: "Rock Plus 攀岩馆", distance: "5.1km", distanceMeters: 5100),
        NearbyGym(name: "蜘蛛侠攀岩（国贸）", distance: "6.8km", distanceMeters: 6800),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                TopOutTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(TopOutTheme.accentGreen)
                            Text("附近的攀岩馆")
                                .font(.headline)
                                .foregroundStyle(TopOutTheme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // Gym list
                        ForEach(nearbyGyms) { gym in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedGymName = gym.name
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    // Gym icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(gym.name == selectedGymName ? TopOutTheme.accentGreen.opacity(0.15) : Color.white.opacity(0.05))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: "building.2.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(gym.name == selectedGymName ? TopOutTheme.accentGreen : TopOutTheme.textTertiary)
                                    }
                                    
                                    // Name + distance
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(gym.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(gym.name == selectedGymName ? TopOutTheme.accentGreen : TopOutTheme.textPrimary)
                                            .lineLimit(1)
                                        Text(gym.distance)
                                            .font(.caption)
                                            .foregroundStyle(TopOutTheme.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selected indicator
                                    if gym.name == selectedGymName {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(TopOutTheme.accentGreen)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    gym.name == selectedGymName
                                        ? TopOutTheme.accentGreen.opacity(0.06)
                                        : Color.clear
                                )
                            }
                            
                            if gym.id != nearbyGyms.last?.id {
                                Divider()
                                    .background(TopOutTheme.cardStroke)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择岩馆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
            .toolbarBackground(TopOutTheme.backgroundPrimary, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}
