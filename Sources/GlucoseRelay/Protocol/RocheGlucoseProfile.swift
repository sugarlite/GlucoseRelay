import CoreBluetooth
import Foundation

/// 罗氏血糖仪协议实现 / Roche glucometer protocol implementation
///
/// 基于标准 BLE Glucose Profile，适配罗氏 Accu-Chek 系列设备的特定处理。
/// Based on standard BLE Glucose Profile, adapted for Roche Accu-Chek series specific handling.
final class RocheGlucoseProfile: GlucoseProfileProtocol {
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

    // MARK: - Service Discovery

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
                    note: "Read device time"
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

    // MARK: - Glucose Measurement Parsing

    /// 解析血糖测量数据包 / Parse glucose measurement packet
    ///
    /// 数据包格式遵循 Bluetooth SIG Glucose Profile 规范：
    /// Packet format follows Bluetooth SIG Glucose Profile specification:
    ///
    ///     Offset 0:   Flags (1 byte)
    ///     Offset 1-2: Sequence Number (2 bytes, little-endian)
    ///     Offset 3-4: Year (2 bytes, little-endian)
    ///     Offset 5:   Month (1 byte)
    ///     Offset 6:   Day (1 byte)
    ///     Offset 7:   Hours (1 byte)
    ///     Offset 8:   Minutes (1 byte)
    ///     Offset 9:   Seconds (1 byte)
    ///     Offset 10+: Optional fields based on flags
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

        // 跳过 Time Offset（如果存在）/ Skip Time Offset if present
        if timeOffsetPresent {
            guard data.count >= index + 2 else {
                throw GlucoseMeterError.invalidDataFormat
            }
            index += 2
        }

        // 解析 SFLOAT 血糖浓度 / Parse SFLOAT glucose concentration
        guard let sf = SFLOAT(data: data, offset: index) else {
            throw GlucoseMeterError.sfFloatParseError
        }

        let mgdl: Double
        let unit: GlucoseUnit
        if concentrationUnitKgL {
            // kg/L → mg/dL: value * 100000
            mgdl = sf.value * 100000
            unit = .mgPerDL
        } else {
            // 设备发送的是 mmol/L，直接乘以转换系数
            // Device sends mmol/L directly, multiply by conversion factor
            mgdl = sf.value * 18.0182
            unit = .mmolPerL
        }
        index += 2

        // 解析样本类型和位置 / Parse sample type and location
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

        // 跳过传感器状态（如果存在）/ Skip sensor status if present
        if sensorStatusPresent {
            index += 1
        }

        // 构建时间戳 / Build timestamp
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

    // MARK: - Context Parsing

    /// 解析血糖测量上下文 / Parse glucose measurement context
    ///
    /// 上下文数据包含用餐类型等附加信息。
    /// Context data contains additional information such as meal type.
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

    // MARK: - RACP Commands

    /// 构建 RACP 命令 / Build RACP command
    ///
    /// RACP (Record Access Control Point) 用于请求血糖记录。
    /// RACP is used to request glucose records from the device.
    func buildRACPCommand(filter: RecordFilter) -> Data {
        switch filter {
        case .all:
            // Opcode 0x01 = Report Records, Operator 0x01 = All Records
            return Data([0x01, 0x01])
        case .sinceSequence(let seq):
            // Opcode 0x01 = Report Records, Operator 0x03 = Greater Than or Equal To
            // Filter Type 0x01 = Sequence Number
            var data = Data([0x01, 0x03, 0x01])
            data.append(UInt8(seq & 0xFF))
            data.append(UInt8((seq >> 8) & 0xFF))
            return data
        case .last:
            return Data([0x01, 0x01])
        }
    }

    /// 处理 RACP 响应 / Handle RACP response
    func handleRACPResponse(_ data: Data) -> RACPResult {
        guard data.count >= 2 else { return .unknown }

        let opcode = data[0]

        switch opcode {
        case 0x05:
            // Number of Records Response
            guard data.count >= 4 else { return .unknown }
            let numberOfRecords = UInt16(data[2]) | (UInt16(data[3]) << 8)
            return .numberOfRecords(Int(numberOfRecords))
        case 0x06:
            // Response Code (success indication)
            return .complete
        case 0x07:
            // Error response
            guard data.count >= 3 else { return .unknown }
            let responseCode = RACPResponseCode(rawValue: data[2]) ?? .unknown
            return .responseCode(responseCode)
        default:
            return .unknown
        }
    }

    // MARK: - Device Time Parsing

    /// 解析设备时间 / Parse device time
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
