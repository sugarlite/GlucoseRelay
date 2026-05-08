import Foundation
@preconcurrency import CoreBluetooth

/// Roche Glucometer SDK 主入口 / Main entry point for Roche Glucometer SDK
///
/// 提供扫描、连接、读取罗氏血糖仪数据的功能。
/// Provides scanning, connection, and glucose data reading capabilities for Roche glucometers.
///
/// 支持设备 / Supported devices:
/// - Accu-Chek Guide
/// - Accu-Chek Guide Me
/// - Accu-Chek Instant
public final class RocheGlucometerSDK: Sendable {
    /// SDK 单例 / SDK singleton instance
    public static let shared = RocheGlucometerSDK()

    /// SDK 版本号 / SDK version string
    public var version: String { "1.0.0" }

    /// 设备管理器，处理 BLE 连接生命周期 / Device manager handling BLE connection lifecycle
    private let deviceManager = DeviceManager()

    private init() {}

    /// 初始化 SDK，配置 CoreBluetooth / Initialize SDK and configure CoreBluetooth
    ///
    /// 必须在调用其他方法前执行。/ Must be called before using other methods.
    public func initialize() async {
        await deviceManager.initialize()
    }

    /// 扫描附近的罗氏血糖仪 / Scan for nearby Roche glucometers
    /// - Parameter duration: 扫描持续时间（秒）/ Scan duration in seconds
    /// - Returns: 发现的设备流 / Stream of discovered devices
    public func scan(duration: TimeInterval = 10) async -> AsyncStream<DiscoveredDevice> {
        await deviceManager.scan(duration: duration)
    }

    /// 连接指定设备 / Connect to a specific device
    /// - Parameter device: 要连接的设备 / Device to connect to
    /// - Returns: 血糖仪连接会话 / Glucose meter connection session
    /// - Throws: GlucoseMeterError 连接错误 / Connection errors
    public func connect(to device: DiscoveredDevice) async throws -> GlucoseMeterConnection {
        try await deviceManager.connect(to: device)
        try await deviceManager.discoverServices()

        let profile = RocheGlucoseProfile()
        await deviceManager.setProfile(profile)

        let commands = try await deviceManager.withConnectedPeripheral { peripheral in
            try await profile.onServicesDiscovered(peripheral: peripheral)
        }

        for command in commands {
            switch command {
            case .read(let service, let characteristic, _):
                _ = try? await deviceManager.readCharacteristic(
                    service: service,
                    characteristic: characteristic
                )
            default:
                break
            }
        }

        try await deviceManager.setupNotifications()

        let deviceInfo = DeviceInfo(
            manufacturer: "Roche",
            model: device.name,
            macAddress: device.id
        )

        return await GlucoseMeterConnection(
            deviceManager: deviceManager,
            profile: profile,
            deviceInfo: deviceInfo
        )
    }
}
