import SwiftUI

/// Settings - detection sensitivity, stop timeout, HealthKit, API config, logout
struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("climbSensitivity") private var sensitivity: Double = 0.5
    @AppStorage("stopTimeout") private var stopTimeout: Double = 30
    @AppStorage("autoDetectEnabled") private var autoDetectEnabled = true
    @AppStorage("apiBaseURL") private var apiBaseURL = ""
    @State private var healthKitAuthorized = false
    
    private let healthKitService = HealthKitService()
    
    var body: some View {
        Form {
            // User info
            if let user = authService.currentUser {
                Section("用户") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(user.nickname)
                                .font(.headline)
                            Text(user.phone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button("退出登录", role: .destructive) {
                        Task { await authService.logout() }
                    }
                }
            }
            
            Section("攀爬检测") {
                Toggle("自动检测", isOn: $autoDetectEnabled)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("灵敏度")
                        Spacer()
                        Text(sensitivityLabel)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $sensitivity, in: 0...1, step: 0.1)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("静止结束阈值")
                        Spacer()
                        Text("\(Int(stopTimeout))秒")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $stopTimeout, in: 10...120, step: 5)
                }
                .disabled(!autoDetectEnabled)
            }
            
            Section("数据") {
                HStack {
                    Text("HealthKit")
                    Spacer()
                    if healthKitAuthorized {
                        Label("已授权", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                    } else {
                        Button("授权") {
                            Task {
                                healthKitAuthorized = await healthKitService.requestAuthorization()
                            }
                        }
                    }
                }
            }
            
            Section("服务器") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API 地址")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("默认: \(NetworkConfig.apiBaseURL)", text: $apiBaseURL)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.5.0")
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com/LinDong123a/TopOut")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("设置")
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
