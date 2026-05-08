import CoreBluetooth

protocol GlucoseProfileProtocol: AnyObject, Sendable {
    var supportedServices: [CBUUID] { get }
    var requiredCharacteristics: [CBUUID] { get }

    func onServicesDiscovered(peripheral: CBPeripheral) async throws -> [BLECommand]
    func onManufacturerNameRead(_ name: String) -> [BLECommand]
    func parseGlucoseMeasurement(_ data: Data) throws -> GlucoseReading
    func parseContextData(_ data: Data) -> GlucoseContext?
    func buildRACPCommand(filter: RecordFilter) -> Data
    func handleRACPResponse(_ data: Data) -> RACPResult
    func parseDeviceTime(_ data: Data) -> Date?
}

enum RACPResult: Sendable {
    case numberOfRecords(Int)
    case responseCode(RACPResponseCode)
    case complete
    case unknown
}
