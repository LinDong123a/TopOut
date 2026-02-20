import SwiftUI

/// P2: Settings - detection sensitivity, stop timeout, HealthKit authorization
struct SettingsView: View {
    @AppStorage("climbSensitivity") private var sensitivity: Double = 0.5
    @AppStorage("stopTimeout") private var stopTimeout: Double = 30
    @AppStorage("autoDetectEnabled") private var autoDetectEnabled = true
    @State private var healthKitAuthorized = false
    
    private let healthKitService = HealthKitService()
    
    var body: some View {
        Form {
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
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0 MVP")
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
    }
}
