import XCTest
@testable import GlucoseRelay

final class SFLOATTests: XCTestCase {
    func testParseSFLOAT_5_5() {
        // 5.5 mmol/L: mantissa=55, exponent=-1
        // b0 = 55 = 0x37, b1 = 0xF0 (exponent -1 | mantissa high 0)
        let data = Data([0x37, 0xF0])
        let sf = SFLOAT(data: data)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 5.5, accuracy: 0.01)
    }

    func testParseSFLOAT_100() {
        // 100: mantissa=100, exponent=0
        let data = Data([0x64, 0x00])
        let sf = SFLOAT(data: data)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 100.0, accuracy: 0.01)
    }

    func testParseSFLOAT_0_8() {
        // 0.8: mantissa=8, exponent=-1
        let data = Data([0x08, 0xF0])
        let sf = SFLOAT(data: data)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 0.8, accuracy: 0.01)
    }

    func testParseSFLOAT_NegativeExponent() {
        // 0.01: mantissa=1, exponent=-2
        // exponent -2 = 0xE (4-bit signed), b1 = 0xE0
        let data = Data([0x01, 0xE0])
        let sf = SFLOAT(data: data)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 0.01, accuracy: 0.001)
    }

    func testParseSFLOAT_PositiveExponent() {
        // 1000: mantissa=1, exponent=3
        // b0 = 0x01, b1 = 0x30 (exponent 3 | mantissa high 0)
        let data = Data([0x01, 0x30])
        let sf = SFLOAT(data: data)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 1000.0, accuracy: 0.01)
    }

    func testParseSFLOAT_InsufficientData() {
        let data = Data([0x01])
        let sf = SFLOAT(data: data)
        XCTAssertNil(sf)
    }

    func testParseSFLOAT_WithOffset() {
        let data = Data([0x00, 0x00, 0x37, 0xF0])
        let sf = SFLOAT(data: data, offset: 2)
        XCTAssertNotNil(sf)
        XCTAssertEqual(sf!.value, 5.5, accuracy: 0.01)
    }
}
