import CoreBluetooth

/// 血糖协议策略接口 / Glucose profile strategy protocol
///
/// 使用策略模式封装不同设备/厂商的协议差异。
/// Uses the Strategy pattern to encapsulate protocol differences between devices/vendors.
protocol GlucoseProfileProtocol: AnyObject, Sendable {
    /// 支持的服务 UUID 列表 / List of supported service UUIDs
    var supportedServices: [CBUUID] { get }
    /// 必需的特征值 UUID 列表 / List of required characteristic UUIDs
    var requiredCharacteristics: [CBUUID] { get }

    /// 服务发现完成后的回调 / Called when service discovery is complete
    /// - Parameter peripheral: 已连接的外设 / Connected peripheral
    /// - Returns: 后续要执行的 BLE 命令 / Subsequent BLE commands to execute
    func onServicesDiscovered(peripheral: CBPeripheral) async throws -> [BLECommand]

    /// 读取厂商名称后的回调 / Called after manufacturer name is read
    /// - Parameter name: 厂商名称 / Manufacturer name
    /// - Returns: 后续要执行的 BLE 命令 / Subsequent BLE commands to execute
    func onManufacturerNameRead(_ name: String) -> [BLECommand]

    /// 解析血糖测量数据 / Parse glucose measurement data
    /// - Parameter data: 原始特征值数据 / Raw characteristic data
    /// - Returns: 解析后的血糖读数 / Parsed glucose reading
    func parseGlucoseMeasurement(_ data: Data) throws -> GlucoseReading

    /// 解析上下文数据 / Parse context data
    /// - Parameter data: 原始特征值数据 / Raw characteristic data
    /// - Returns: 解析后的上下文，如果数据无效则返回 nil / Parsed context, nil if invalid
    func parseContextData(_ data: Data) -> GlucoseContext?

    /// 构建 RACP 命令 / Build RACP command
    /// - Parameter filter: 记录过滤条件 / Record filter criteria
    /// - Returns: 要写入 RACP 特征值的原始数据 / Raw data to write to RACP characteristic
    func buildRACPCommand(filter: RecordFilter) -> Data

    /// 处理 RACP 响应 / Handle RACP response
    /// - Parameter data: RACP 特征值通知数据 / RACP characteristic notification data
    /// - Returns: 解析后的 RACP 结果 / Parsed RACP result
    func handleRACPResponse(_ data: Data) -> RACPResult

    /// 解析设备时间 / Parse device time
    /// - Parameter data: 时间特征值数据 / Time characteristic data
    /// - Returns: 解析后的日期，如果数据无效则返回 nil / Parsed date, nil if invalid
    func parseDeviceTime(_ data: Data) -> Date?
}

/// RACP 解析结果 / RACP parse result
enum RACPResult: Sendable {
    /// 记录数量响应 / Number of records response
    case numberOfRecords(Int)
    /// 响应代码 / Response code
    case responseCode(RACPResponseCode)
    /// 操作完成 / Operation complete
    case complete
    /// 未知响应 / Unknown response
    case unknown
}
