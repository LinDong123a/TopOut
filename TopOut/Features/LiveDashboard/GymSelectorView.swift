import SwiftUI

struct NearbyLocation: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let distanceMeters: Int
    let isOutdoor: Bool
}

// Keep old name as typealias for compatibility
typealias NearbyGym = NearbyLocation
typealias LocationSelectorView = GymSelectorView

struct GymSelectorView: View {
    @Binding var selectedGymName: String
    @Environment(\.dismiss) private var dismiss
    
    private let nearbyLocations: [NearbyLocation] = [
        // Indoor gyms
        NearbyLocation(name: "岩时攀岩馆（望京店）", distance: "120m", distanceMeters: 120, isOutdoor: false),
        NearbyLocation(name: "岩舞空间（三里屯）", distance: "1.8km", distanceMeters: 1800, isOutdoor: false),
        NearbyLocation(name: "奥攀攀岩馆", distance: "3.2km", distanceMeters: 3200, isOutdoor: false),
        NearbyLocation(name: "首攀攀岩（朝阳大悦城）", distance: "4.5km", distanceMeters: 4500, isOutdoor: false),
        NearbyLocation(name: "Rock Plus 攀岩馆", distance: "5.1km", distanceMeters: 5100, isOutdoor: false),
        NearbyLocation(name: "蜘蛛侠攀岩（国贸）", distance: "6.8km", distanceMeters: 6800, isOutdoor: false),
        // Outdoor crags
        NearbyLocation(name: "白河岩场", distance: "68km", distanceMeters: 68000, isOutdoor: true),
        NearbyLocation(name: "后白河岩场", distance: "72km", distanceMeters: 72000, isOutdoor: true),
        NearbyLocation(name: "十三陵岩场", distance: "45km", distanceMeters: 45000, isOutdoor: true),
    ]
    
    private var indoorLocations: [NearbyLocation] {
        nearbyLocations.filter { !$0.isOutdoor }
    }
    
    private var outdoorLocations: [NearbyLocation] {
        nearbyLocations.filter { $0.isOutdoor }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                TopOutTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Indoor section
                        sectionHeader(icon: "building.2.fill", title: "附近的攀岩馆", color: TopOutTheme.accentGreen)
                        
                        ForEach(indoorLocations) { loc in
                            locationRow(loc, icon: "building.2.fill")
                            if loc.id != indoorLocations.last?.id {
                                Divider()
                                    .background(TopOutTheme.cardStroke)
                                    .padding(.leading, 76)
                            }
                        }
                        
                        // Outdoor section
                        sectionHeader(icon: "mountain.2.fill", title: "户外岩场", color: TopOutTheme.rockBrown)
                            .padding(.top, 16)
                        
                        ForEach(outdoorLocations) { loc in
                            locationRow(loc, icon: "mountain.2.fill")
                            if loc.id != outdoorLocations.last?.id {
                                Divider()
                                    .background(TopOutTheme.cardStroke)
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择地点")
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
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(TopOutTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private func locationRow(_ loc: NearbyLocation, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedGymName = loc.name
            }
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(loc.name == selectedGymName
                              ? (loc.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen).opacity(0.15)
                              : Color.white.opacity(0.05))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(loc.name == selectedGymName
                                         ? (loc.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                                         : TopOutTheme.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(loc.name == selectedGymName
                                         ? (loc.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                                         : TopOutTheme.textPrimary)
                        .lineLimit(1)
                    Text(loc.distance)
                        .font(.caption)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                
                Spacer()
                
                if loc.name == selectedGymName {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(loc.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                loc.name == selectedGymName
                    ? (loc.isOutdoor ? TopOutTheme.rockBrown : TopOutTheme.accentGreen).opacity(0.06)
                    : Color.clear
            )
        }
    }
}
