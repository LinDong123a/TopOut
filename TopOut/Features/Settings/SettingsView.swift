import SwiftUI

/// Settings — standard iOS grouped form with outdoor theme
struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var profile = UserProfile.shared
    @AppStorage("climbSensitivity") private var sensitivity: Double = 0.5
    @AppStorage("stopTimeout") private var stopTimeout: Double = 30
    @AppStorage("autoDetectEnabled") private var autoDetectEnabled = true
    @AppStorage("apiBaseURL") private var apiBaseURL = ""
    @State private var healthKitAuthorized = false

    private let healthKitService = HealthKitService()

    var body: some View {
        Form {
            profileSection
            devicesSection
            detectionSection
            dataSection
            serverSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("设置")
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            NavigationLink(destination: ProfileEditView(profile: profile)) {
                ProfileCardView(profile: profile)
            }
            .listRowBackground(TopOutTheme.backgroundCard)

            if authService.currentUser != nil {
                Button("退出登录", role: .destructive) {
                    Task { await authService.logout() }
                }
                .listRowBackground(TopOutTheme.backgroundCard)
            }
        } header: {
            Text("个人信息")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        Section {
            NavigationLink(destination: MyDevicesView()) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(TopOutTheme.rockBrown.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "applewatch.and.arrow.forward")
                            .font(.subheadline)
                            .foregroundStyle(TopOutTheme.rockBrown)
                    }
                    Text("我的设备")
                        .foregroundStyle(TopOutTheme.textPrimary)
                }
            }
            .listRowBackground(TopOutTheme.backgroundCard)
        } header: {
            Text("设备")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    // MARK: - Detection

    private var detectionSection: some View {
        Section {
            Toggle("自动检测", isOn: $autoDetectEnabled)
                .tint(TopOutTheme.accentGreen)
                .listRowBackground(TopOutTheme.backgroundCard)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("灵敏度")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Text(sensitivityLabel)
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                Slider(value: $sensitivity, in: 0...1, step: 0.1)
                    .tint(TopOutTheme.accentGreen)
            }
            .listRowBackground(TopOutTheme.backgroundCard)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("静止结束阈值")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Text("\(Int(stopTimeout))秒")
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
                Slider(value: $stopTimeout, in: 10...120, step: 5)
                    .tint(TopOutTheme.accentGreen)
            }
            .disabled(!autoDetectEnabled)
            .listRowBackground(TopOutTheme.backgroundCard)
        } header: {
            Text("攀爬检测")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            HStack {
                Text("HealthKit")
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                if healthKitAuthorized {
                    Label("已授权", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(TopOutTheme.accentGreen)
                        .font(.subheadline)
                } else {
                    Button("授权") {
                        Task {
                            healthKitAuthorized =
                                await healthKitService.requestAuthorization()
                        }
                    }
                    .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
            .listRowBackground(TopOutTheme.backgroundCard)
        } header: {
            Text("数据")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    // MARK: - Server

    private var serverSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("API 地址")
                    .font(.caption)
                    .foregroundStyle(TopOutTheme.textTertiary)
                TextField("默认: \(NetworkConfig.apiBaseURL)", text: $apiBaseURL)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(TopOutTheme.textPrimary)
            }
            .listRowBackground(TopOutTheme.backgroundCard)
        } header: {
            Text("服务器")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本")
                    .foregroundStyle(TopOutTheme.textPrimary)
                Spacer()
                Text("1.5.0")
                    .foregroundStyle(TopOutTheme.textTertiary)
            }
            .listRowBackground(TopOutTheme.backgroundCard)

            Link(destination: URL(string: "https://github.com/LinDong123a/TopOut")!) {
                HStack {
                    Text("GitHub")
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }
            .listRowBackground(TopOutTheme.backgroundCard)
        } header: {
            Text("关于")
                .foregroundStyle(TopOutTheme.textSecondary)
        }
    }

    private var sensitivityLabel: String {
        switch sensitivity {
        case 0..<0.3: return "低"
        case 0.3..<0.7: return "中"
        default: return "高"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService.shared)
    }
}
