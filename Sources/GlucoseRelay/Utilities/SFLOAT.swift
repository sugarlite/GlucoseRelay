import Foundation

/// IEEE-11073 16-bit SFLOAT 解析器 / IEEE-11073 16-bit SFLOAT parser
///
/// 蓝牙 Glucose Profile 使用的特殊浮点格式：
/// Special floating-point format used by Bluetooth Glucose Profile:
///
///     Byte 0: [Mantissa low 8 bits]
///     Byte 1: [Exponent 4 bits | Mantissa high 4 bits]
///
/// Value = Mantissa * 10^Exponent
/// - Mantissa: 12-bit signed integer
/// - Exponent: 4-bit signed integer
struct SFLOAT {
    /// 解析后的浮点值 / Parsed floating-point value
    let value: Double

    /// 从 Data 解析 SFLOAT / Parse SFLOAT from Data
    /// - Parameters:
    ///   - data: 包含 SFLOAT 字节的 Data / Data containing SFLOAT bytes
    ///   - offset: 数据起始偏移量 / Starting offset in data
    init?(data: Data, offset: Int = 0) {
        guard data.count >= offset + 2 else { return nil }

        let b0 = data[offset]
        let b1 = data[offset + 1]

        // 提取尾数（12-bit 无符号）/ Extract mantissa (12-bit unsigned)
        let mantissaUnsigned = UInt16(b0) | ((UInt16(b1) & 0x0F) << 8)
        // 转换为 12-bit 有符号 / Convert to 12-bit signed
        let mantissa = SFLOAT.signed12(value: mantissaUnsigned)

        // 提取指数（4-bit 无符号）/ Extract exponent (4-bit unsigned)
        let exponentUnsigned = UInt8(b1 >> 4)
        // 转换为 4-bit 有符号 / Convert to 4-bit signed
        let exponent = SFLOAT.signed4(value: exponentUnsigned)

        self.value = Double(mantissa) * pow(10.0, Double(exponent))
    }

    /// 将 12-bit 无符号值转换为有符号整数 / Convert 12-bit unsigned to signed integer
    private static func signed12(value: UInt16) -> Int {
        if value & 0x0800 != 0 {
            return -1 * Int(0x0800 - (value & 0x07FF))
        }
        return Int(value)
    }

    /// 将 4-bit 无符号值转换为有符号整数 / Convert 4-bit unsigned to signed integer
    private static func signed4(value: UInt8) -> Int {
        if value & 0x08 != 0 {
            return -1 * Int(0x08 - (value & 0x07))
        }
        return Int(value)
    }
}
