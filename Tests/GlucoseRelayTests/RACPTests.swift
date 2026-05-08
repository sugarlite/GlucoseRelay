import XCTest
@testable import GlucoseRelay

final class RACPTests: XCTestCase {
    func testBuildRACPCommandAllRecords() {
        let profile = RocheGlucoseProfile()
        let data = profile.buildRACPCommand(filter: .all)

        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(data[0], 0x01) // Report Records
        XCTAssertEqual(data[1], 0x01) // All Records
    }

    func testBuildRACPCommandSinceSequence() {
        let profile = RocheGlucoseProfile()
        let data = profile.buildRACPCommand(filter: .sinceSequence(42))

        XCTAssertEqual(data.count, 5)
        XCTAssertEqual(data[0], 0x01) // Report Records
        XCTAssertEqual(data[1], 0x03) // Greater Than or Equal To
        XCTAssertEqual(data[2], 0x01) // Filter by Sequence
        XCTAssertEqual(data[3], 0x2A) // Sequence low byte (42)
        XCTAssertEqual(data[4], 0x00) // Sequence high byte
    }

    func testBuildRACPCommandSinceSequenceLarge() {
        let profile = RocheGlucoseProfile()
        let data = profile.buildRACPCommand(filter: .sinceSequence(1000))

        XCTAssertEqual(data.count, 5)
        XCTAssertEqual(data[3], 0xE8) // 1000 & 0xFF
        XCTAssertEqual(data[4], 0x03) // 1000 >> 8
    }

    func testHandleRACPResponseComplete() {
        let profile = RocheGlucoseProfile()
        let data = Data([0x06, 0x00])
        let result = profile.handleRACPResponse(data)

        if case .complete = result {
            // success
        } else {
            XCTFail("Expected complete response")
        }
    }

    func testHandleRACPResponseNumberOfRecords() {
        let profile = RocheGlucoseProfile()
        let data = Data([0x05, 0x00, 0x0A, 0x00])
        let result = profile.handleRACPResponse(data)

        if case .numberOfRecords(let count) = result {
            XCTAssertEqual(count, 10)
        } else {
            XCTFail("Expected number of records response")
        }
    }

    func testHandleRACPResponseError() {
        let profile = RocheGlucoseProfile()
        let data = Data([0x07, 0x00, 0x06])
        let result = profile.handleRACPResponse(data)

        if case .responseCode(let code) = result {
            XCTAssertEqual(code, .noRecordsFound)
        } else {
            XCTFail("Expected error response")
        }
    }

    func testHandleRACPResponseUnknown() {
        let profile = RocheGlucoseProfile()
        let data = Data([0xFF])
        let result = profile.handleRACPResponse(data)

        if case .unknown = result {
            // success
        } else {
            XCTFail("Expected unknown response")
        }
    }

    func testHandleRACPResponseTooShort() {
        let profile = RocheGlucoseProfile()
        let data = Data([0x06])
        let result = profile.handleRACPResponse(data)

        if case .unknown = result {
            // success
        } else {
            XCTFail("Expected unknown response for short data")
        }
    }
}
