import Foundation

public final class GlucoseMeterConnection: Sendable {
    private let deviceManager: DeviceManager
    private let profile: GlucoseProfileProtocol
    private let deviceInfo: DeviceInfo
    private let eventStream: AsyncStream<BLEEvent>

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

    public func fetchAllRecords() async throws -> [GlucoseReading] {
        try await fetchRecords(filter: .all)
    }

    public func fetchNewRecords(since sequence: Int) async throws -> [GlucoseReading] {
        try await fetchRecords(filter: .sinceSequence(sequence))
    }

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

    public func disconnect() async {
        await deviceManager.disconnect()
    }

    private func fetchRecords(filter: RecordFilter) async throws -> [GlucoseReading] {
        let command = profile.buildRACPCommand(filter: filter)
        try await deviceManager.writeRACP(command)

        var readings: [GlucoseReading] = []
        var contextAwaiting: GlucoseReading?

        for await event in eventStream {
            switch event {
            case .measurement(let reading):
                if reading.hasContextInfo {
                    contextAwaiting = reading
                } else {
                    readings.append(reading)
                }

            case .context(let context):
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
                return readings

            case .racpError(let code):
                throw GlucoseMeterError.racpError(code)

            default:
                break
            }
        }

        return readings
    }
}
