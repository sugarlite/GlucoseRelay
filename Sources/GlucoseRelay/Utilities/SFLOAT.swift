import Foundation

struct SFLOAT {
    let value: Double

    init?(data: Data, offset: Int = 0) {
        guard data.count >= offset + 2 else { return nil }

        let b0 = data[offset]
        let b1 = data[offset + 1]

        let mantissaUnsigned = UInt16(b0) | ((UInt16(b1) & 0x0F) << 8)
        let mantissa = SFLOAT.signed12(value: mantissaUnsigned)

        let exponentUnsigned = UInt8(b1 >> 4)
        let exponent = SFLOAT.signed4(value: exponentUnsigned)

        self.value = Double(mantissa) * pow(10.0, Double(exponent))
    }

    private static func signed12(value: UInt16) -> Int {
        if value & 0x0800 != 0 {
            return -1 * Int(0x0800 - (value & 0x07FF))
        }
        return Int(value)
    }

    private static func signed4(value: UInt8) -> Int {
        if value & 0x08 != 0 {
            return -1 * Int(0x08 - (value & 0x07))
        }
        return Int(value)
    }
}
