import XCTest
@testable import GlucoseRelay

final class DeviceInfoTests: XCTestCase {
    func testGlucoseReadingEquatable() {
        let testId = UUID()
        let reading1 = GlucoseReading(
            id: testId,
            sequenceNumber: 1,
            timestamp: Date(timeIntervalSince1970: 1000),
            glucoseValue: 100.0,
            glucoseValueMMOL: 5.55,
            unit: .mgPerDL,
            sampleType: .capillaryWholeBlood,
            sampleLocation: .finger,
            hasContextInfo: false,
            mealType: nil,
            deviceId: "test-device"
        )

        let reading2 = GlucoseReading(
            id: testId,
            sequenceNumber: 1,
            timestamp: Date(timeIntervalSince1970: 1000),
            glucoseValue: 100.0,
            glucoseValueMMOL: 5.55,
            unit: .mgPerDL,
            sampleType: .capillaryWholeBlood,
            sampleLocation: .finger,
            hasContextInfo: false,
            mealType: nil,
            deviceId: "test-device"
        )

        let reading3 = GlucoseReading(
            id: UUID(),
            sequenceNumber: 2,
            timestamp: Date(timeIntervalSince1970: 1000),
            glucoseValue: 120.0,
            glucoseValueMMOL: 6.66,
            unit: .mgPerDL,
            sampleType: .capillaryWholeBlood,
            sampleLocation: .finger,
            hasContextInfo: false,
            mealType: nil,
            deviceId: "test-device"
        )

        XCTAssertEqual(reading1, reading2)
        XCTAssertNotEqual(reading1, reading3)
    }

    func testConnectionStateIsConnected() {
        XCTAssertFalse(ConnectionState.disconnected.isConnected)
        XCTAssertFalse(ConnectionState.connecting.isConnected)
        XCTAssertFalse(ConnectionState.discoveringServices.isConnected)
        XCTAssertFalse(ConnectionState.pairing.isConnected)
        XCTAssertTrue(ConnectionState.ready.isConnected)
        XCTAssertTrue(ConnectionState.readingData.isConnected)
        XCTAssertFalse(ConnectionState.disconnecting.isConnected)
    }

    func testDiscoveredDeviceEquatable() {
        let device1 = DiscoveredDevice(
            id: "uuid-1",
            name: "Accu-Chek Guide",
            rssi: -60,
            isPaired: true
        )

        let device2 = DiscoveredDevice(
            id: "uuid-1",
            name: "Accu-Chek Guide",
            rssi: -60,
            isPaired: true
        )

        let device3 = DiscoveredDevice(
            id: "uuid-2",
            name: "Accu-Chek Instant",
            rssi: -70,
            isPaired: false
        )

        XCTAssertEqual(device1, device2)
        XCTAssertNotEqual(device1, device3)
    }

    func testGlucoseMeterErrorEquatable() {
        XCTAssertEqual(GlucoseMeterError.bluetoothUnavailable, GlucoseMeterError.bluetoothUnavailable)
        XCTAssertNotEqual(GlucoseMeterError.bluetoothUnavailable, GlucoseMeterError.deviceNotFound)

        let error1 = GlucoseMeterError.racpError(.noRecordsFound)
        let error2 = GlucoseMeterError.racpError(.noRecordsFound)
        let error3 = GlucoseMeterError.racpError(.success)

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testRACPResponseCodeRawValues() {
        XCTAssertEqual(RACPResponseCode.success.rawValue, 0x01)
        XCTAssertEqual(RACPResponseCode.opCodeNotSupported.rawValue, 0x02)
        XCTAssertEqual(RACPResponseCode.invalidOperator.rawValue, 0x03)
        XCTAssertEqual(RACPResponseCode.operatorNotSupported.rawValue, 0x04)
        XCTAssertEqual(RACPResponseCode.invalidOperand.rawValue, 0x05)
        XCTAssertEqual(RACPResponseCode.noRecordsFound.rawValue, 0x06)
        XCTAssertEqual(RACPResponseCode.abortUnsuccessful.rawValue, 0x07)
        XCTAssertEqual(RACPResponseCode.procedureNotCompleted.rawValue, 0x08)
        XCTAssertEqual(RACPResponseCode.operandNotSupported.rawValue, 0x09)
    }

    func testSampleTypeRawValues() {
        XCTAssertEqual(SampleType.capillaryWholeBlood.rawValue, 1)
        XCTAssertEqual(SampleType.capillaryPlasma.rawValue, 2)
        XCTAssertEqual(SampleType.controlSolution.rawValue, 10)
    }

    func testSampleLocationRawValues() {
        XCTAssertEqual(SampleLocation.finger.rawValue, 1)
        XCTAssertEqual(SampleLocation.alternateSiteTest.rawValue, 2)
        XCTAssertEqual(SampleLocation.notAvailable.rawValue, 15)
    }

    func testMealTypeRawValues() {
        XCTAssertEqual(MealType.beforeMeal.rawValue, 1)
        XCTAssertEqual(MealType.afterMeal.rawValue, 2)
        XCTAssertEqual(MealType.fasting.rawValue, 3)
        XCTAssertEqual(MealType.bedtime.rawValue, 4)
        XCTAssertEqual(MealType.ketone.rawValue, 6)
    }

    func testDeviceInfoCreation() {
        let info = DeviceInfo(
            manufacturer: "Roche",
            model: "Accu-Chek Guide",
            serialNumber: "SN12345",
            firmwareVersion: "1.0.0",
            macAddress: "AA:BB:CC:DD:EE:FF",
            hasContextCharacteristic: true
        )

        XCTAssertEqual(info.manufacturer, "Roche")
        XCTAssertEqual(info.model, "Accu-Chek Guide")
        XCTAssertEqual(info.serialNumber, "SN12345")
        XCTAssertEqual(info.firmwareVersion, "1.0.0")
        XCTAssertEqual(info.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertTrue(info.hasContextCharacteristic)
    }
}
