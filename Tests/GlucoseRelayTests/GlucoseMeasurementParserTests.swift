import XCTest
@testable import GlucoseRelay

final class GlucoseMeasurementParserTests: XCTestCase {
    func testParseGlucoseMeasurement() throws {
        // 完整的血糖测量数据包测试
        // Flags: type present (bit1=1), kg/L unit (bit2=0), context follows (bit4=1)
        // flags = 0x02 | 0x10 = 0x12
        // 100 mg/dL = 0.001 kg/L, SFLOAT: mantissa=1, exponent=-3
        // b0=0x01, b1=0xD0 (exponent -3 = 0xD | mantissa high 0)
        let packet: [UInt8] = [
            0x12,        // Flags: type present, kg/L, context follows
            0x01, 0x00,  // Sequence: 1
            0xE4, 0x07,  // Year: 2020
            0x01,        // Month: 1
            0x01,        // Day: 1
            0x0C,        // Hour: 12
            0x00,        // Minute: 0
            0x00,        // Second: 0
            0x01, 0xD0,  // Glucose: 0.001 kg/L = 100 mg/dL (SFLOAT)
            0x11         // Type: capillary whole blood, finger
        ]

        let profile = RocheGlucoseProfile()
        let reading = try profile.parseGlucoseMeasurement(Data(packet))

        XCTAssertEqual(reading.sequenceNumber, 1)
        XCTAssertEqual(reading.glucoseValue, 100.0, accuracy: 0.1)
        XCTAssertEqual(reading.unit, .mgPerDL)
        XCTAssertEqual(reading.sampleType, .capillaryWholeBlood)
        XCTAssertEqual(reading.sampleLocation, .finger)
        XCTAssertTrue(reading.hasContextInfo)
    }

    func testParseGlucoseMeasurementMMOL() throws {
        // mmol/L 单位
        // Flags: type present (bit1=1), mol/L unit (bit2=1), context follows (bit4=1)
        // flags = 0x02 | 0x04 | 0x10 = 0x16
        // 5.5 mmol/L, SFLOAT: mantissa=55, exponent=-1
        // b0=0x37, b1=0xF0 (exponent -1 = 0xF | mantissa high 0)
        let packet: [UInt8] = [
            0x16,        // Flags: type present, mol/L, context follows
            0x02, 0x00,  // Sequence: 2
            0xE5, 0x07,  // Year: 2021
            0x06,        // Month: 6
            0x15,        // Day: 21
            0x08,        // Hour: 8
            0x30,        // Minute: 30
            0x00,        // Second: 0
            0x37, 0xF0,  // Glucose: 5.5 mmol/L (SFLOAT)
            0x11         // Type: capillary whole blood, finger
        ]

        let profile = RocheGlucoseProfile()
        let reading = try profile.parseGlucoseMeasurement(Data(packet))

        XCTAssertEqual(reading.sequenceNumber, 2)
        XCTAssertEqual(reading.unit, .mmolPerL)
        XCTAssertEqual(reading.glucoseValueMMOL, 5.5, accuracy: 0.1)
    }

    func testParseGlucoseMeasurementWithTimeOffset() throws {
        // 带 Time Offset
        // Flags: time offset (bit0=1), type present (bit1=1), mol/L (bit2=1)
        // flags = 0x01 | 0x02 | 0x04 = 0x07
        let packet: [UInt8] = [
            0x07,        // Flags: time offset present, type present, mol/L
            0x03, 0x00,  // Sequence: 3
            0xE6, 0x07,  // Year: 2022
            0x03,        // Month: 3
            0x10,        // Day: 16
            0x10,        // Hour: 16
            0x00,        // Minute: 0
            0x00,        // Second: 0
            0x3C, 0x00,  // Time offset: +60 minutes
            0x37, 0xF0,  // Glucose: 5.5 mmol/L
            0x11         // Type: capillary whole blood, finger
        ]

        let profile = RocheGlucoseProfile()
        let reading = try profile.parseGlucoseMeasurement(Data(packet))

        XCTAssertEqual(reading.sequenceNumber, 3)
        XCTAssertEqual(reading.unit, .mmolPerL)
    }

    func testParseGlucoseMeasurementInvalidData() {
        let profile = RocheGlucoseProfile()

        // 数据太短
        let shortData = Data([0x01])
        XCTAssertThrowsError(try profile.parseGlucoseMeasurement(shortData)) { error in
            XCTAssertEqual(error as? GlucoseMeterError, .invalidDataFormat)
        }
    }

    func testParseGlucoseMeasurementMinimalData() throws {
        // 最小数据包 (只有 flags, sequence, datetime, glucose)
        let packet: [UInt8] = [
            0x00,        // Flags: 无可选字段
            0x0A, 0x00,  // Sequence: 10
            0xE7, 0x07,  // Year: 2023
            0x0A,        // Month: 10
            0x01,        // Day: 1
            0x09,        // Hour: 9
            0x00,        // Minute: 0
            0x00,        // Second: 0
            0x64, 0x00   // Glucose: 100 (SFLOAT, mantissa=100, exp=0)
        ]

        let profile = RocheGlucoseProfile()
        let reading = try profile.parseGlucoseMeasurement(Data(packet))

        XCTAssertEqual(reading.sequenceNumber, 10)
        XCTAssertEqual(reading.sampleType, .capillaryWholeBlood)
        XCTAssertEqual(reading.sampleLocation, .finger)
        XCTAssertFalse(reading.hasContextInfo)
    }
}
