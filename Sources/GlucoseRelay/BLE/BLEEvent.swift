import Foundation

enum BLEEvent {
    case measurement(GlucoseReading)
    case context(GlucoseContext)
    case racpComplete
    case racpError(RACPResponseCode)
    case deviceTime(Date)
    case manufacturerName(String)
}
