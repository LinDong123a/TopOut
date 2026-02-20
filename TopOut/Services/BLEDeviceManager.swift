import Foundation
import CoreBluetooth
import Combine

/// Represents a paired / discovered BLE device
struct PairedDevice: Identifiable {
    let id: UUID
    var name: String
    var type: DeviceType
    var connectionState: ConnectionState
    var batteryLevel: Int?
    var firmwareVersion: String?
    var lastSyncTime: Date?

    enum DeviceType: String {
        case appleWatch = "applewatch"
        case miBand = "miband"

        var icon: String {
            switch self {
            case .appleWatch: return "applewatch"
            case .miBand: return "watchface.applewatch.case"
            }
        }

        var displayName: String {
            switch self {
            case .appleWatch: return "Apple Watch"
            case .miBand: return "小米手环"
            }
        }
    }

    enum ConnectionState: String {
        case connected, disconnected, searching

        var label: String {
            switch self {
            case .connected: return "已连接"
            case .disconnected: return "未连接"
            case .searching: return "搜索中..."
            }
        }

        var dot: String {
            switch self {
            case .connected: return "🟢"
            case .disconnected: return "🔴"
            case .searching: return "🟡"
            }
        }
    }
}

// MARK: - BLE Manager

@MainActor
final class BLEDeviceManager: NSObject, ObservableObject {
    static let shared = BLEDeviceManager()

    @Published var pairedDevices: [PairedDevice] = []
    @Published var discoveredDevices: [PairedDevice] = []
    @Published var isScanning = false
    @Published var bluetoothState: CBManagerState = .unknown

    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

    static let miBandServiceUUID = CBUUID(string: "FEE0")
    static let heartRateCharUUID = CBUUID(string: "00002a37-0000-1000-8000-00805f9b34fb")

    private var isMock: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    override init() {
        super.init()
        if isMock {
            loadMockDevices()
        }
    }

    func setup() {
        guard !isMock else { return }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard !isMock else {
            // Simulate finding a device
            isScanning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.discoveredDevices = [
                    PairedDevice(id: UUID(), name: "小米手环 8 Pro", type: .miBand,
                                 connectionState: .disconnected, batteryLevel: 85)
                ]
                self?.isScanning = false
            }
            return
        }
        guard bluetoothState == .poweredOn else { return }
        isScanning = true
        discoveredDevices = []
        centralManager?.scanForPeripherals(
            withServices: [Self.miBandServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        // Auto-stop after 15s
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.stopScan()
        }
    }

    func stopScan() {
        centralManager?.stopScan()
        isScanning = false
    }

    func pairDevice(_ device: PairedDevice) {
        guard !isMock else {
            var d = device
            d.connectionState = .connected
            d.batteryLevel = d.batteryLevel ?? 72
            d.firmwareVersion = "1.2.3.4"
            d.lastSyncTime = Date()
            pairedDevices.append(d)
            discoveredDevices.removeAll { $0.id == device.id }
            return
        }
        if let peripheral = discoveredPeripherals[device.id] {
            centralManager?.connect(peripheral, options: nil)
        }
    }

    func removeDevice(_ device: PairedDevice) {
        pairedDevices.removeAll { $0.id == device.id }
    }

    private func loadMockDevices() {
        pairedDevices = [
            PairedDevice(id: UUID(), name: "Apple Watch", type: .appleWatch,
                         connectionState: .connected, batteryLevel: 56,
                         firmwareVersion: "11.2", lastSyncTime: Date().addingTimeInterval(-300)),
            PairedDevice(id: UUID(), name: "小米手环 8", type: .miBand,
                         connectionState: .connected, batteryLevel: 72,
                         firmwareVersion: "1.8.2.6", lastSyncTime: Date().addingTimeInterval(-1800)),
        ]
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEDeviceManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothState = central.state
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        Task { @MainActor in
            let id = peripheral.identifier
            guard discoveredPeripherals[id] == nil else { return }
            discoveredPeripherals[id] = peripheral
            let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "未知设备"
            discoveredDevices.append(
                PairedDevice(id: id, name: name, type: .miBand,
                             connectionState: .disconnected)
            )
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            if let idx = discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                var d = discoveredDevices.remove(at: idx)
                d.connectionState = .connected
                d.lastSyncTime = Date()
                pairedDevices.append(d)
            }
        }
    }
}
