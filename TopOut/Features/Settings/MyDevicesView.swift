import SwiftUI

/// 我的设备 — 设备管理页面
struct MyDevicesView: View {
    @StateObject private var bleManager = BLEDeviceManager.shared
    @State private var showAddSheet = false

    var body: some View {
        List {
            // Paired devices
            if !bleManager.pairedDevices.isEmpty {
                Section {
                    ForEach(bleManager.pairedDevices) { device in
                        DeviceCard(device: device)
                            .listRowBackground(TopOutTheme.backgroundCard)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            bleManager.removeDevice(bleManager.pairedDevices[i])
                        }
                    }
                } header: {
                    Text("已配对设备")
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
            }

            // Add device
            Section {
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TopOutTheme.accentGreen)
                        Text("添加设备")
                            .foregroundStyle(TopOutTheme.textPrimary)
                    }
                }
                .listRowBackground(TopOutTheme.backgroundCard)
            } header: {
                Text("添加")
                    .foregroundStyle(TopOutTheme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .topOutBackground()
        .navigationTitle("我的设备")
        .sheet(isPresented: $showAddSheet) {
            AddDeviceView(bleManager: bleManager)
        }
        .onAppear {
            bleManager.setup()
        }
    }
}

// MARK: - Device Card

private struct DeviceCard: View {
    let device: PairedDevice

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(device.connectionState == .connected
                          ? TopOutTheme.accentGreen.opacity(0.15)
                          : TopOutTheme.textTertiary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: device.type.icon)
                    .font(.title3)
                    .foregroundStyle(device.connectionState == .connected
                                    ? TopOutTheme.accentGreen
                                    : TopOutTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundStyle(TopOutTheme.textPrimary)
                    Text(device.connectionState.dot)
                        .font(.caption2)
                }

                HStack(spacing: 10) {
                    Text(device.connectionState.label)
                        .font(.caption)
                        .foregroundStyle(device.connectionState == .connected
                                        ? TopOutTheme.accentGreen
                                        : TopOutTheme.textTertiary)

                    if let battery = device.batteryLevel {
                        Label("\(battery)%", systemImage: batteryIcon(battery))
                            .font(.caption)
                            .foregroundStyle(TopOutTheme.textSecondary)
                    }
                }

                if let fw = device.firmwareVersion {
                    Text("固件 v\(fw)")
                        .font(.caption2)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }

                if let sync = device.lastSyncTime {
                    Text("上次同步 \(sync.relativeString)")
                        .font(.caption2)
                        .foregroundStyle(TopOutTheme.textTertiary)
                }
            }

            Spacer()
        }
    }

    private func batteryIcon(_ level: Int) -> String {
        switch level {
        case 0..<20: return "battery.0percent"
        case 20..<50: return "battery.25percent"
        case 50..<75: return "battery.50percent"
        case 75..<100: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// MARK: - Add Device Sheet

private struct AddDeviceView: View {
    @ObservedObject var bleManager: BLEDeviceManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Apple Watch
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "applewatch")
                            .font(.title2)
                            .foregroundStyle(TopOutTheme.accentGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Watch")
                                .font(.headline)
                                .foregroundStyle(TopOutTheme.textPrimary)
                            Text("请在系统设置中配对 Apple Watch")
                                .font(.caption)
                                .foregroundStyle(TopOutTheme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(TopOutTheme.textTertiary)
                    }
                    .listRowBackground(TopOutTheme.backgroundCard)
                    .onTapGesture {
                        if let url = URL(string: "App-prefs:WATCH") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // Mi Band scan
                Section {
                    Button {
                        bleManager.startScan()
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(TopOutTheme.accentGreen)
                            Text(bleManager.isScanning ? "扫描中..." : "扫描小米手环")
                                .foregroundStyle(TopOutTheme.textPrimary)
                            Spacer()
                            if bleManager.isScanning {
                                ProgressView()
                                    .tint(TopOutTheme.accentGreen)
                            }
                        }
                    }
                    .disabled(bleManager.isScanning)
                    .listRowBackground(TopOutTheme.backgroundCard)

                    ForEach(bleManager.discoveredDevices) { device in
                        HStack(spacing: 14) {
                            Image(systemName: "watchface.applewatch.case")
                                .font(.title3)
                                .foregroundStyle(TopOutTheme.sageGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(TopOutTheme.textPrimary)
                                Text("点击配对")
                                    .font(.caption)
                                    .foregroundStyle(TopOutTheme.textTertiary)
                            }
                            Spacer()
                            Button("配对") {
                                bleManager.pairDevice(device)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TopOutTheme.accentGreen)
                        }
                        .listRowBackground(TopOutTheme.backgroundCard)
                    }
                } header: {
                    Text("小米手环")
                        .foregroundStyle(TopOutTheme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .topOutBackground()
            .navigationTitle("添加设备")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(TopOutTheme.accentGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Date helper

private extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        MyDevicesView()
    }
}
