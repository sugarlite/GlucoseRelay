@preconcurrency import CoreBluetooth

enum BLECommand: Sendable {
    case read(service: CBUUID, characteristic: CBUUID, note: String)
    case write(service: CBUUID, characteristic: CBUUID, data: Data, note: String)
    case enableNotification(service: CBUUID, characteristic: CBUUID, note: String)
    case enableIndication(service: CBUUID, characteristic: CBUUID, note: String)
    case setNotify(service: CBUUID, characteristic: CBUUID, enabled: Bool, note: String)

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
