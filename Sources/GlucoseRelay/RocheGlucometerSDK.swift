import Foundation
@preconcurrency import CoreBluetooth

public final class RocheGlucometerSDK: Sendable {
    public static let shared = RocheGlucometerSDK()

    public var version: String { "1.0.0" }

    private let deviceManager = DeviceManager()

    private init() {}

    public func initialize() async {
        await deviceManager.initialize()
    }

    public func scan(duration: TimeInterval = 10) async -> AsyncStream<DiscoveredDevice> {
        await deviceManager.scan(duration: duration)
    }

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
