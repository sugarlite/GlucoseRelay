import Foundation

/// BLE 事件枚举 / BLE event enumeration
///
/// 从血糖仪接收到的各种事件，通过 AsyncStream 传递给上层。
/// Various events received from the glucometer, delivered via AsyncStream.
enum BLEEvent {
    /// 血糖测量值 / Glucose measurement
    case measurement(GlucoseReading)
    /// 测量上下文 / Measurement context
    case context(GlucoseContext)
    /// RACP 操作完成 / RACP operation completed
    case racpComplete
    /// RACP 操作错误 / RACP operation error
    case racpError(RACPResponseCode)
    /// 设备时间 / Device time
    case deviceTime(Date)
    /// 厂商名称 / Manufacturer name
    case manufacturerName(String)
}
