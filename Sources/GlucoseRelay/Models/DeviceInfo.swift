import Foundation

public struct DeviceInfo: Sendable, Equatable {
    public let manufacturer: String
    public let model: String?
    public let serialNumber: String?
    public let firmwareVersion: String?
    public let macAddress: String
    public let hasContextCharacteristic: Bool

    public init(
        manufacturer: String,
        model: String? = nil,
        serialNumber: String? = nil,
        firmwareVersion: String? = nil,
        macAddress: String,
        hasContextCharacteristic: Bool = false
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.serialNumber = serialNumber
        self.firmwareVersion = firmwareVersion
        self.macAddress = macAddress
        self.hasContextCharacteristic = hasContextCharacteristic
    }
}

public struct DiscoveredDevice: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let rssi: Int
    public let isPaired: Bool
    public let manufacturerData: Data?

    public init(
        id: String,
        name: String?,
        rssi: Int,
        isPaired: Bool = false,
        manufacturerData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.isPaired = isPaired
        self.manufacturerData = manufacturerData
    }
}

public enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case discoveringServices
    case pairing
    case ready
    case readingData
    case disconnecting

    public var isConnected: Bool {
        switch self {
        case .ready, .readingData:
            return true
        default:
            return false
        }
    }
}
