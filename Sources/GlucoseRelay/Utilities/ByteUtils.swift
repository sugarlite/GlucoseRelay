import Foundation

/// 字节操作工具 / Byte manipulation utilities
///
/// 安全地从小端序字节数组中读取数值。
/// Safely read numeric values from little-endian byte arrays.
enum ByteUtils {
    /// 读取 16-bit 无符号小端序整数 / Read 16-bit unsigned little-endian integer
    /// - Parameters:
    ///   - data: 数据源 / Source data
    ///   - offset: 起始偏移量 / Starting offset
    /// - Returns: 解析的 UInt16 值，数据不足时返回 nil / Parsed UInt16 value, nil if insufficient data
    static func readUInt16LE(_ data: Data, offset: Int) -> UInt16? {
        guard data.count >= offset + 2 else { return nil }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    /// 读取 16-bit 有符号小端序整数 / Read 16-bit signed little-endian integer
    /// - Parameters:
    ///   - data: 数据源 / Source data
    ///   - offset: 起始偏移量 / Starting offset
    /// - Returns: 解析的 Int16 值，数据不足时返回 nil / Parsed Int16 value, nil if insufficient data
    static func readInt16LE(_ data: Data, offset: Int) -> Int16? {
        guard data.count >= offset + 2 else { return nil }
        let unsigned = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        return Int16(bitPattern: unsigned)
    }

    /// 读取 8-bit 无符号整数 / Read 8-bit unsigned integer
    /// - Parameters:
    ///   - data: 数据源 / Source data
    ///   - offset: 起始偏移量 / Starting offset
    /// - Returns: 解析的 UInt8 值，数据不足时返回 nil / Parsed UInt8 value, nil if insufficient data
    static func readUInt8(_ data: Data, offset: Int) -> UInt8? {
        guard data.count > offset else { return nil }
        return data[offset]
    }
}
