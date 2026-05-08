@preconcurrency import CoreBluetooth

/// BLE 命令枚举 / BLE command enumeration
///
/// 封装对 BLE 特征值的各种操作。
/// Encapsulates various operations on BLE characteristics.
enum BLECommand: Sendable {
    /// 读取特征值 / Read characteristic value
    case read(service: CBUUID, characteristic: CBUUID, note: String)
    /// 写入特征值 / Write characteristic value
    case write(service: CBUUID, characteristic: CBUUID, data: Data, note: String)
    /// 启用通知 / Enable notifications
    case enableNotification(service: CBUUID, characteristic: CBUUID, note: String)
    /// 启用指示 / Enable indications
    case enableIndication(service: CBUUID, characteristic: CBUUID, note: String)
    /// 设置通知状态 / Set notification state
    case setNotify(service: CBUUID, characteristic: CBUUID, enabled: Bool, note: String)

    /// 命令描述 / Command description for logging
    var description: String {
        switch self {
        case .read(_, _, let note):
            return "Read: \(note)"
        case .write(_, _, _, let note):
            return "Write: \(note)"
        case .enableNotification(_, _, let note):
            return "Enable Notification: \(note)"
        case .enableIndication(_, _, let note):
            return "Enable Indication: \(note)"
        case .setNotify(_, _, let enabled, let note):
            return "Set Notify (\(enabled)): \(note)"
        }
    }
}
