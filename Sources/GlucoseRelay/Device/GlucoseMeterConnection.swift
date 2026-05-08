import Foundation

/// 血糖仪连接会话 / Glucose meter connection session
///
/// 建立连接后用于读取血糖记录和监听实时测量。
/// Used to read glucose records and listen to real-time measurements after connection is established.
public final class GlucoseMeterConnection: Sendable {
    private let deviceManager: DeviceManager
    private let profile: GlucoseProfileProtocol
    private let deviceInfo: DeviceInfo
    private let eventStream: AsyncStream<BLEEvent>

    /// 当前连接状态 / Current connection state
    public var state: ConnectionState {
        get async {
            await deviceManager.state
        }
    }

    init(deviceManager: DeviceManager, profile: GlucoseProfileProtocol, deviceInfo: DeviceInfo) async {
        self.deviceManager = deviceManager
        self.profile = profile
        self.deviceInfo = deviceInfo
        self.eventStream = await deviceManager.createEventStream()
    }

    /// 获取所有血糖记录 / Fetch all glucose records from device
    /// - Returns: 血糖读数数组 / Array of glucose readings
    /// - Throws: GlucoseMeterError 读取错误 / Read errors
    public func fetchAllRecords() async throws -> [GlucoseReading] {
        try await fetchRecords(filter: .all)
    }

    /// 获取新记录（基于上次同步的序列号）/ Fetch new records since last sync
    /// - Parameter sequence: 上次同步的序列号 / Last synced sequence number
    /// - Returns: 新血糖读数数组 / Array of new glucose readings
    public func fetchNewRecords(since sequence: Int) async throws -> [GlucoseReading] {
        try await fetchRecords(filter: .sinceSequence(sequence))
    }

    /// 监听实时测量（当用户在设备上测量时自动接收）/ Listen to real-time measurements
    ///
    /// 当用户在血糖仪上进行新测量时，自动通过 BLE 通知接收数据。
    /// Automatically receives data via BLE notifications when user takes a new measurement on the glucometer.
    /// - Returns: 血糖读数流 / Stream of glucose readings
    public func realtimeMeasurements() -> AsyncStream<GlucoseReading> {
        AsyncStream { continuation in
            Task {
                for await event in eventStream {
                    if case .measurement(let reading) = event {
                        continuation.yield(reading)
                    }
                }
                continuation.finish()
            }
        }
    }

    /// 断开连接 / Disconnect from device
    public func disconnect() async {
        await deviceManager.disconnect()
    }

    // MARK: - Private

    /// 读取血糖记录的通用方法 / Generic method to fetch glucose records
    private func fetchRecords(filter: RecordFilter) async throws -> [GlucoseReading] {
        // 发送 RACP 命令请求记录 / Send RACP command to request records
        let command = profile.buildRACPCommand(filter: filter)
        try await deviceManager.writeRACP(command)

        var readings: [GlucoseReading] = []
        var contextAwaiting: GlucoseReading?

        // 监听 BLE 事件直到 RACP 完成 / Listen to BLE events until RACP completes
        for await event in eventStream {
            switch event {
            case .measurement(let reading):
                // 如果有上下文信息跟随，暂存等待上下文 / If context follows, store temporarily
                if reading.hasContextInfo {
                    contextAwaiting = reading
                } else {
                    readings.append(reading)
                }

            case .context(let context):
                // 将上下文与等待的测量值合并 / Merge context with awaiting measurement
                if let awaiting = contextAwaiting,
                   awaiting.sequenceNumber == context.sequenceNumber {
                    let updated = GlucoseReading(
                        sequenceNumber: awaiting.sequenceNumber,
                        timestamp: awaiting.timestamp,
                        glucoseValue: awaiting.glucoseValue,
                        glucoseValueMMOL: awaiting.glucoseValueMMOL,
                        unit: awaiting.unit,
                        sampleType: awaiting.sampleType,
                        sampleLocation: awaiting.sampleLocation,
                        hasContextInfo: true,
                        mealType: context.mealType,
                        deviceId: awaiting.deviceId
                    )
                    readings.append(updated)
                    contextAwaiting = nil
                }

            case .racpComplete:
                // RACP 操作完成，返回所有记录 / RACP operation complete, return all records
                return readings

            case .racpError(let code):
                // RACP 操作错误 / RACP operation error
                throw GlucoseMeterError.racpError(code)

            default:
                break
            }
        }

        return readings
    }
}
