import XCTest
@testable import GlucoseRelay

final class GlucoseContextParserTests: XCTestCase {
    func testParseContextWithMealType() {
        let profile = RocheGlucoseProfile()
        let packet: [UInt8] = [
            0x02,        // Flags: hasMealType
            0x01, 0x00,  // Sequence: 1
            0x01         // MealType: beforeMeal
        ]

        let context = profile.parseContextData(Data(packet))
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.sequenceNumber, 1)
        XCTAssertEqual(context?.mealType, .beforeMeal)
        XCTAssertFalse(context?.hasCarbInfo ?? true)
    }

    func testParseContextWithCarbInfo() {
        let profile = RocheGlucoseProfile()
        let packet: [UInt8] = [
            0x01,        // Flags: hasCarbInfo
            0x02, 0x00,  // Sequence: 2
            0x01,        // carbFlags
            0x32, 0x00   // carbInfo: 50
        ]

        let context = profile.parseContextData(Data(packet))
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.sequenceNumber, 2)
        XCTAssertNil(context?.mealType)
        XCTAssertTrue(context?.hasCarbInfo ?? false)
    }

    func testParseContextWithSecondaryFlags() {
        let profile = RocheGlucoseProfile()
        let packet: [UInt8] = [
            0x82,        // Flags: hasSecondaryFlags + hasMealType
            0x03, 0x00,  // Sequence: 3
            0x00,        // secondaryFlags
            0x02         // MealType: afterMeal
        ]

        let context = profile.parseContextData(Data(packet))
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.sequenceNumber, 3)
        XCTAssertEqual(context?.mealType, .afterMeal)
    }

    func testParseContextTooShort() {
        let profile = RocheGlucoseProfile()
        let data = Data([0x01])
        let context = profile.parseContextData(data)
        XCTAssertNil(context)
    }

    func testParseContextNoOptionalFields() {
        let profile = RocheGlucoseProfile()
        let packet: [UInt8] = [
            0x00,        // Flags: no optional fields
            0x04, 0x00   // Sequence: 4
        ]

        let context = profile.parseContextData(Data(packet))
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.sequenceNumber, 4)
        XCTAssertNil(context?.mealType)
        XCTAssertFalse(context?.hasCarbInfo ?? true)
    }

    func testParseContextFasting() {
        let profile = RocheGlucoseProfile()
        let packet: [UInt8] = [
            0x02,        // Flags: hasMealType
            0x05, 0x00,  // Sequence: 5
            0x03         // MealType: fasting
        ]

        let context = profile.parseContextData(Data(packet))
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.mealType, .fasting)
    }
}
