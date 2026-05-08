import Foundation

public enum GlucoseMeterError: Error, Sendable, Equatable {
    case bluetoothUnavailable
    case bluetoothUnauthorized
    case deviceNotFound
    case connectionFailed
    case pairingRequired
    case pairingFailed
    case serviceDiscoveryFailed
    case characteristicNotFound
    case writeFailed
    case readTimeout
    case invalidDataFormat
    case sfFloatParseError
    case racpError(RACPResponseCode)
    case deviceDisconnected
    case unsupportedDevice
    case unknown
}

public enum RACPResponseCode: UInt8, Sendable, Equatable {
    case success = 0x01
    case opCodeNotSupported = 0x02
    case invalidOperator = 0x03
    case operatorNotSupported = 0x04
    case invalidOperand = 0x05
    case noRecordsFound = 0x06
    case abortUnsuccessful = 0x07
    case procedureNotCompleted = 0x08
    case operandNotSupported = 0x09
    case unknown = 0xFF
}
