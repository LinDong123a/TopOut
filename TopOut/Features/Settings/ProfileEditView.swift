import SwiftUI

/// 用户攀岩资料（本地存储）
@MainActor
final class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var nickname: String {
        didSet { UserDefaults.standard.set(nickname, forKey: "profile.nickname") }
    }
    @Published var phone: String {
        didSet { UserDefaults.standard.set(phone, forKey: "profile.phone") }
    }
    @Published var avatarSymbol: String {
        didSet { UserDefaults.standard.set(avatarSymbol, forKey: "profile.avatarSymbol") }
    }
    @Published var boulderGrade: String {
        didSet { UserDefaults.standard.set(boulderGrade, forKey: "profile.boulderGrade") }
    }
    @Published var leadGrade: String {
        didSet { UserDefaults.standard.set(leadGrade, forKey: "profile.leadGrade") }
    }
    @Published var heightCM: Int? {
        didSet { UserDefaults.standard.set(heightCM ?? 0, forKey: "profile.heightCM") }
    }
    @Published var weightKG: Int? {
        didSet { UserDefaults.standard.set(weightKG ?? 0, forKey: "profile.weightKG") }
    }
    @Published var climbingSinceYear: Int? {
        didSet { UserDefaults.standard.set(climbingSinceYear ?? 0, forKey: "profile.climbingSince") }
    }

    var maskedPhone: String {
        guard phone.count >= 7 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    init() {
        let d = UserDefaults.standard
        nickname = d.string(forKey: "profile.nickname") ?? "岩壁行者"
        phone = d.string(forKey: "profile.phone") ?? "13812348888"
        avatarSymbol = d.string(forKey: "profile.avatarSymbol") ?? "person.circle.fill"
        boulderGrade = d.string(forKey: "profile.boulderGrade") ?? "V4"
        leadGrade = d.string(forKey: "profile.leadGrade") ?? "5.11a"
        let h = d.integer(forKey: "profile.heightCM")
        heightCM = h > 0 ? h : 175
        let w = d.integer(forKey: "profile.weightKG")
        weightKG = w > 0 ? w : 68
        let y = d.integer(forKey: "profile.climbingSince")
        climbingSinceYear = y > 0 ? y : 2023
    }
}

// MARK: - Profile Card (for SettingsView)

struct ProfileCardView: View {
    @ObservedObject var profile: UserProfile

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TopOutTheme.accentGreen.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: profile.avatarSymbol)
                    .font(.title)
                    .foregroundStyle(TopOutTheme.accentGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.nickname)
                    .font(.headline)
                    .foregroundStyle(TopOutTheme.textPrimary)
                Text(profile.maskedPhone)
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
                HStack(spacing: 8) {
                    GradeBadge(label: "抱石", grade: profile.boulderGrade)
                    GradeBadge(label: "先锋", grade: profile.leadGrade)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TopOutTheme.textTertiary)
        }
    }
}

private struct GradeBadge: View {
    let label: String
    let grade: String

    var body: some View {
        Text("\(label) \(grade)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(TopOutTheme.accentGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(TopOutTheme.accentGreen.opacity(0.12), in: Capsule())
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @ObservedObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    private static let boulderGrades = (0...16).map { "V\($0)" }
    private static let leadGrades: [String] = {
        var g: [String] = []
        for major in 5...5 {
            for minor in 5...15 {
                if minor <= 9 {
                    g.append("5.\(minor)")
                } else {
                    for sub in ["a", "b", "c", "d"] {
                        g.append("5.\(minor)\(sub)")
                    }
                }
            }
        }
        return g
    }()

    private static let avatarSymbols = [
        "person.circle.fill", "figure.climbing", "mountain.2.fill",
        "flame.fill", "bolt.circle.fill", "leaf.circle.fill",
        "star.circle.fill", "heart.circle.fill",
    ]

    var body: some View {
        Form {
            // Avatar
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TopOutTheme.accentGreen.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: profile.avatarSymbol)
                            .font(.system(size: 36))
                            .foregroundStyle(TopOutTheme.accentGreen)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Self.avatarSymbols, id: \.self) { symbol in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        profile.avatarSymbol = symbol
                                    }
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.title3)
                                        .foregroundStyle(symbol == profile.avatarSymbol
                                                        ? TopOutTheme.accentGreen
                                                        : TopOutTheme.textTertiary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(symbol == profile.avatarSymbol
                                                      ? TopOutTheme.accentGreen.opacity(0.15)
                                                      : TopOutTheme.backgroundCard)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(symbol == profile.avatarSymbol
                                                       ? TopOutTheme.accentGreen
                                                       : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("头像")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            // Basic info
            Section {
                HStack {
                    Text("昵称")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    TextField("昵称", text: $profile.nickname)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(TopOutTheme.textPrimary)
                }
                .listRowBackground(TopOutTheme.backgroundCard)

                HStack {
                    Text("手机号")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Text(profile.phone)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("基本信息")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            // Climbing grades
            Section {
                Picker("抱石等级", selection: $profile.boulderGrade) {
                    ForEach(Self.boulderGrades, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                .foregroundStyle(TopOutTheme.textPrimary)
                .listRowBackground(TopOutTheme.backgroundCard)

                Picker("先锋等级", selection: $profile.leadGrade) {
                    ForEach(Self.leadGrades, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                .foregroundStyle(TopOutTheme.textPrimary)
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("攀岩等级")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }

            // Body measurements
            Section {
                HStack {
                    Text("身高")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    TextField("cm", value: $profile.heightCM, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("cm")
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                .listRowBackground(TopOutTheme.backgroundCard)

                HStack {
                    Text("体重")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    TextField("kg", value: $profile.weightKG, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("kg")
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                .listRowBackground(TopOutTheme.backgroundCard)

                HStack {
                    Text("攀龄")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    TextField("年份", value: $profile.climbingSinceYear, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text("年开始")
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("身体数据")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(profile: .shared)
    }
}
