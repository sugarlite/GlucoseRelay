import Foundation

enum ByteUtils {
    static func readUInt16LE(_ data: Data, offset: Int) -> UInt16? {
        guard data.count >= offset + 2 else { return nil }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    static func readInt16LE(_ data: Data, offset: Int) -> Int16? {
        guard data.count >= offset + 2 else { return nil }
        let unsigned = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        return Int16(bitPattern: unsigned)
    }

    static func readUInt8(_ data: Data, offset: Int) -> UInt8? {
        guard data.count > offset else { return nil }
        return data[offset]
    }
}
