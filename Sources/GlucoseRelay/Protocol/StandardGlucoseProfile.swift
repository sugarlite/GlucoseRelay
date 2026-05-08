import CoreBluetooth
import Foundation

final class StandardGlucoseProfile: GlucoseProfileProtocol {
    var supportedServices: [CBUUID] {
        [
            BLEUUID.glucoseService,
            BLEUUID.deviceInfoService,
            BLEUUID.currentTimeService,
        ]
    }

    var requiredCharacteristics: [CBUUID] {
        [
            BLEUUID.glucoseMeasurement,
            BLEUUID.recordAccessControlPoint,
            BLEUUID.manufacturerName,
        ]
    }

    private let deviceId: String = ""

    func onServicesDiscovered(peripheral: CBPeripheral) async throws -> [BLECommand] {
        guard let services = peripheral.services else {
            throw GlucoseMeterError.serviceDiscoveryFailed
        }

        var commands: [BLECommand] = []

        for service in services {
            switch service.uuid {
            case BLEUUID.deviceInfoService:
                commands.append(.read(
                    service: BLEUUID.deviceInfoService,
                    characteristic: BLEUUID.manufacturerName,
                    note: "Read manufacturer name"
                ))
            case BLEUUID.currentTimeService:
                commands.append(.read(
                    service: BLEUUID.currentTimeService,
                    characteristic: BLEUUID.currentTime,
                    note: "Read current time"
                ))
            default:
                break
            }
        }

        return commands
    }

    func onManufacturerNameRead(_ name: String) -> [BLECommand] {
        return []
    }

    func parseGlucoseMeasurement(_ data: Data) throws -> GlucoseReading {
        guard data.count >= 10 else {
            throw GlucoseMeterError.invalidDataFormat
        }

        let flags = data[0]
        let timeOffsetPresent = (flags & 0x01) > 0
        let typeAndLocationPresent = (flags & 0x02) > 0
        let concentrationUnitKgL = (flags & 0x04) == 0
        let sensorStatusPresent = (flags & 0x08) > 0
        let contextFollows = (flags & 0x10) > 0

        guard let sequence = ByteUtils.readUInt16LE(data, offset: 1) else {
            throw GlucoseMeterError.invalidDataFormat
        }
        guard let year = ByteUtils.readUInt16LE(data, offset: 3) else {
            throw GlucoseMeterError.invalidDataFormat
        }
        let month = Int(data[5])
        let day = Int(data[6])
        let hour = Int(data[7])
        let minute = Int(data[8])
        let second = Int(data[9])

        var index = 10

        if timeOffsetPresent {
            guard data.count >= index + 2 else {
                throw GlucoseMeterError.invalidDataFormat
            }
            index += 2
        }

        guard let sf = SFLOAT(data: data, offset: index) else {
            throw GlucoseMeterError.sfFloatParseError
        }

        let mgdl: Double
        let unit: GlucoseUnit
        if concentrationUnitKgL {
            mgdl = sf.value * 100000
            unit = .mgPerDL
        } else {
            mgdl = sf.value * 18.0182
            unit = .mmolPerL
        }
        index += 2

        var sampleType: SampleType = .capillaryWholeBlood
        var sampleLocation: SampleLocation = .finger
        if typeAndLocationPresent {
            guard data.count > index else {
                throw GlucoseMeterError.invalidDataFormat
            }
            let typeAndLocation = data[index]
            sampleLocation = SampleLocation(rawValue: (typeAndLocation & 0xF0) >> 4) ?? .notAvailable
            sampleType = SampleType(rawValue: typeAndLocation & 0x0F) ?? .capillaryWholeBlood
            index += 1
        }

        if sensorStatusPresent {
            index += 1
        }

        var components = DateComponents()
        components.year = Int(year)
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "UTC")

        guard let timestamp = Calendar.current.date(from: components) else {
            throw GlucoseMeterError.invalidDataFormat
        }

        return GlucoseReading(
            sequenceNumber: Int(sequence),
            timestamp: timestamp,
            glucoseValue: mgdl,
            glucoseValueMMOL: mgdl / 18.0182,
            unit: unit,
            sampleType: sampleType,
            sampleLocation: sampleLocation,
            hasContextInfo: contextFollows,
            mealType: nil,
            deviceId: deviceId
        )
    }

    func parseContextData(_ data: Data) -> GlucoseContext? {
        guard data.count >= 3 else { return nil }

        let flags = data[0]
        let hasSecondaryFlags = (flags & 0x80) > 0
        let hasMealType = (flags & 0x02) > 0
        let hasCarbInfo = (flags & 0x01) > 0

        guard let sequence = ByteUtils.readUInt16LE(data, offset: 1) else { return nil }

        var index = 3

        if hasSecondaryFlags {
            index += 1
        }

        if hasCarbInfo {
            index += 3
        }

        var mealType: MealType?
        if hasMealType, index < data.count {
            mealType = MealType(rawValue: data[index])
        }

        return GlucoseContext(
            sequenceNumber: Int(sequence),
            mealType: mealType,
            hasCarbInfo: hasCarbInfo
        )
    }

    func buildRACPCommand(filter: RecordFilter) -> Data {
        switch filter {
        case .all:
            return Data([0x01, 0x01])
        case .sinceSequence(let seq):
            var data = Data([0x01, 0x03, 0x01])
            data.append(UInt8(seq & 0xFF))
            data.append(UInt8((seq >> 8) & 0xFF))
            return data
        case .last:
            return Data([0x01, 0x01])
        }
    }

    func handleRACPResponse(_ data: Data) -> RACPResult {
        guard data.count >= 2 else { return .unknown }

        let opcode = data[0]

        switch opcode {
        case 0x05:
            guard data.count >= 4 else { return .unknown }
            let numberOfRecords = UInt16(data[2]) | (UInt16(data[3]) << 8)
            return .numberOfRecords(Int(numberOfRecords))
        case 0x06:
            return .complete
        case 0x07:
            guard data.count >= 3 else { return .unknown }
            let responseCode = RACPResponseCode(rawValue: data[2]) ?? .unknown
            return .responseCode(responseCode)
        default:
            return .unknown
        }
    }

    func parseDeviceTime(_ data: Data) -> Date? {
        guard data.count >= 7 else { return nil }

        guard let year = ByteUtils.readUInt16LE(data, offset: 0) else { return nil }
        let month = Int(data[2])
        let day = Int(data[3])
        let hour = Int(data[4])
        let minute = Int(data[5])
        let second = Int(data[6])

        var components = DateComponents()
        components.year = Int(year)
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return Calendar.current.date(from: components)
    }
}
