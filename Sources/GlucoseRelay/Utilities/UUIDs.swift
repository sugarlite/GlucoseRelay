@preconcurrency import CoreBluetooth

enum BLEUUID {
    static let glucoseService = CBUUID(string: "00001808-0000-1000-8000-00805f9b34fb")
    static let glucoseMeasurement = CBUUID(string: "00002a18-0000-1000-8000-00805f9b34fb")
    static let glucoseMeasurementContext = CBUUID(string: "00002a34-0000-1000-8000-00805f9b34fb")
    static let recordAccessControlPoint = CBUUID(string: "00002a52-0000-1000-8000-00805f9b34fb")

    static let currentTimeService = CBUUID(string: "00001805-0000-1000-8000-00805f9b34fb")
    static let currentTime = CBUUID(string: "00002a2b-0000-1000-8000-00805f9b34fb")
    static let dateTime = CBUUID(string: "00002a08-0000-1000-8000-00805f9b34fb")

    static let deviceInfoService = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")
    static let manufacturerName = CBUUID(string: "00002a29-0000-1000-8000-00805f9b34fb")
    static let modelNumber = CBUUID(string: "00002a24-0000-1000-8000-00805f9b34fb")
    static let serialNumber = CBUUID(string: "00002a25-0000-1000-8000-00805f9b34fb")
    static let firmwareRevision = CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb")

    static let clientCharacteristicConfig = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
}
