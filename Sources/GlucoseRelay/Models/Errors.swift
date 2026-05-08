import Foundation

/// SDK 错误类型 / SDK error types
///
/// 使用 SDK 过程中可能遇到的各种错误。
/// Various errors that may occur when using the SDK.
public enum GlucoseMeterError: Error, Sendable, Equatable {
    /// 蓝牙不可用 / Bluetooth is unavailable
    case bluetoothUnavailable
    /// 蓝牙未授权 / Bluetooth permission not granted
    case bluetoothUnauthorized
    /// 设备未找到 / Device not found
    case deviceNotFound
    /// 连接失败 / Connection failed
    case connectionFailed
    /// 需要配对 / Pairing required
    case pairingRequired
    /// 配对失败 / Pairing failed
    case pairingFailed
    /// 服务发现失败 / Service discovery failed
    case serviceDiscoveryFailed
    /// 特征值未找到 / Characteristic not found
    case characteristicNotFound
    /// 写入失败 / Write operation failed
    case writeFailed
    /// 读取超时 / Read timeout
    case readTimeout
    /// 数据格式无效 / Invalid data format
    case invalidDataFormat
    /// SFLOAT 解析错误 / SFLOAT parse error
    case sfFloatParseError
    /// RACP 响应错误 / RACP response error
    case racpError(RACPResponseCode)
    /// 设备已断开 / Device disconnected
    case deviceDisconnected
    /// 不支持的设备 / Unsupported device
    case unsupportedDevice
    /// 未知错误 / Unknown error
    case unknown
}

/// RACP 响应代码 / RACP (Record Access Control Point) response codes
///
/// 来自血糖仪的 RACP 操作响应状态码。
/// Response status codes from the glucometer's RACP operations.
public enum RACPResponseCode: UInt8, Sendable, Equatable {
    /// 成功 / Success
    case success = 0x01
    /// 操作码不支持 / Opcode not supported
    case opCodeNotSupported = 0x02
    /// 无效操作符 / Invalid operator
    case invalidOperator = 0x03
    /// 操作符不支持 / Operator not supported
    case operatorNotSupported = 0x04
    /// 无效操作数 / Invalid operand
    case invalidOperand = 0x05
    /// 未找到记录 / No records found
    case noRecordsFound = 0x06
    /// 中止失败 / Abort unsuccessful
    case abortUnsuccessful = 0x07
    /// 过程未完成 / Procedure not completed
    case procedureNotCompleted = 0x08
    /// 操作数不支持 / Operand not supported
    case operandNotSupported = 0x09
    /// 未知 / Unknown
    case unknown = 0xFF
}
