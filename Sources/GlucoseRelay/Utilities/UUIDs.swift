@preconcurrency import CoreBluetooth

/// BLE UUID 常量 / BLE UUID constants
///
/// 蓝牙 SIG 标准 Glucose Profile 和罗氏设备使用的服务和特征值 UUID。
/// Service and characteristic UUIDs for Bluetooth SIG Standard Glucose Profile and Roche devices.
enum BLEUUID {
    // MARK: - Glucose Service (0x1808)

    /// 血糖服务 / Glucose Service
    static let glucoseService = CBUUID(string: "00001808-0000-1000-8000-00805f9b34fb")
    /// 血糖测量值（通知）/ Glucose Measurement (notify)
    static let glucoseMeasurement = CBUUID(string: "00002a18-0000-1000-8000-00805f9b34fb")
    /// 血糖测量上下文（可选通知）/ Glucose Measurement Context (optional notify)
    static let glucoseMeasurementContext = CBUUID(string: "00002a34-0000-1000-8000-00805f9b34fb")
    /// 记录访问控制点（指示）/ Record Access Control Point (indicate)
    static let recordAccessControlPoint = CBUUID(string: "00002a52-0000-1000-8000-00805f9b34fb")

    // MARK: - Current Time Service (0x1805)

    /// 当前时间服务 / Current Time Service
    static let currentTimeService = CBUUID(string: "00001805-0000-1000-8000-00805f9b34fb")
    /// 当前时间特征值 / Current Time characteristic
    static let currentTime = CBUUID(string: "00002a2b-0000-1000-8000-00805f9b34fb")
    /// 日期时间特征值（罗氏 Aviva Connect 使用）/ Date Time characteristic (used by Roche Aviva Connect)
    static let dateTime = CBUUID(string: "00002a08-0000-1000-8000-00805f9b34fb")

    // MARK: - Device Information Service (0x180A)

    /// 设备信息服务 / Device Information Service
    static let deviceInfoService = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")
    /// 厂商名称 / Manufacturer Name
    static let manufacturerName = CBUUID(string: "00002a29-0000-1000-8000-00805f9b34fb")
    /// 型号 / Model Number
    static let modelNumber = CBUUID(string: "00002a24-0000-1000-8000-00805f9b34fb")
    /// 序列号 / Serial Number
    static let serialNumber = CBUUID(string: "00002a25-0000-1000-8000-00805f9b34fb")
    /// 固件版本 / Firmware Revision
    static let firmwareRevision = CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb")

    // MARK: - Descriptor

    /// 客户端特征值配置描述符 / Client Characteristic Configuration Descriptor
    static let clientCharacteristicConfig = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
}
