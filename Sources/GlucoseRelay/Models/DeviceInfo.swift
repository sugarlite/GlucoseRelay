import Foundation

/// 设备信息 / Device information
///
/// 连接后从血糖仪读取的设备和厂商信息。
/// Device and manufacturer information read from the glucometer after connection.
public struct DeviceInfo: Sendable, Equatable {
    /// 厂商名称 / Manufacturer name (e.g. "Roche")
    public let manufacturer: String
    /// 设备型号 / Device model name
    public let model: String?
    /// 序列号 / Serial number
    public let serialNumber: String?
    /// 固件版本 / Firmware version
    public let firmwareVersion: String?
    /// MAC 地址或 UUID / MAC address or UUID
    public let macAddress: String
    /// 是否支持上下文特征值 / Whether context characteristic is supported
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

/// 扫描发现的设备 / Discovered device during scanning
///
/// 通过 BLE 扫描发现的血糖仪设备信息。
/// Information about a glucometer discovered via BLE scanning.
public struct DiscoveredDevice: Identifiable, Sendable, Equatable {
    /// 设备唯一标识（UUID）/ Device unique identifier (UUID)
    public let id: String
    /// 设备名称 / Device name advertised
    public let name: String?
    /// 信号强度（dBm）/ Signal strength in dBm
    public let rssi: Int
    /// 是否已配对 / Whether device is already paired
    public let isPaired: Bool
    /// 厂商特定广播数据 / Manufacturer-specific advertisement data
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

/// 连接状态 / Connection state
///
/// 血糖仪连接的生命周期状态。
/// Lifecycle states of the glucometer connection.
public enum ConnectionState: Sendable, Equatable {
    /// 已断开 / Disconnected
    case disconnected
    /// 正在连接 / Connecting
    case connecting
    /// 正在发现服务 / Discovering services
    case discoveringServices
    /// 正在配对 / Pairing
    case pairing
    /// 已就绪，可以通信 / Ready for communication
    case ready
    /// 正在读取数据 / Reading data
    case readingData
    /// 正在断开 / Disconnecting
    case disconnecting

    /// 是否已连接（就绪或读取中）/ Whether currently connected (ready or reading)
    public var isConnected: Bool {
        switch self {
        case .ready, .readingData:
            return true
        default:
            return false
        }
    }
}
