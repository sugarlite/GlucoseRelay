import XCTest
@testable import GlucoseRelay

final class ByteUtilsTests: XCTestCase {
    func testReadUInt16LE() {
        let data = Data([0x34, 0x12])
        let value = ByteUtils.readUInt16LE(data, offset: 0)
        XCTAssertEqual(value, 0x1234)
    }

    func testReadUInt16LEAtOffset() {
        let data = Data([0x00, 0x00, 0x34, 0x12])
        let value = ByteUtils.readUInt16LE(data, offset: 2)
        XCTAssertEqual(value, 0x1234)
    }

    func testReadUInt16LEInsufficientData() {
        let data = Data([0x01])
        let value = ByteUtils.readUInt16LE(data, offset: 0)
        XCTAssertNil(value)
    }

    func testReadInt16LE() {
        let data = Data([0xFE, 0xFF])
        let value = ByteUtils.readInt16LE(data, offset: 0)
        XCTAssertEqual(value, -2)
    }

    func testReadUInt8() {
        let data = Data([0x42])
        let value = ByteUtils.readUInt8(data, offset: 0)
        XCTAssertEqual(value, 0x42)
    }

    func testReadUInt8OutOfBounds() {
        let data = Data([0x42])
        let value = ByteUtils.readUInt8(data, offset: 1)
        XCTAssertNil(value)
    }
}
