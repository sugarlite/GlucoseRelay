@preconcurrency import CoreBluetooth
import Foundation

/// 设备管理器 / Device manager
///
/// 管理 BLE 连接生命周期：扫描、连接、服务发现、通信、断开。
/// Manages BLE connection lifecycle: scan, connect, discover services, communicate, disconnect.
///
/// 实现 CBCentralManagerDelegate 和 CBPeripheralDelegate 处理 CoreBluetooth 回调。
/// Implements CBCentralManagerDelegate and CBPeripheralDelegate for CoreBluetooth callbacks.
actor DeviceManager: NSObject {
    private var centralManager: CBCentralManager?
    private var _connectedPeripheral: CBPeripheral?
    private var commandQueue = BLECommandQueue()
    private var profile: GlucoseProfileProtocol?

    // MARK: - Continuations for async/await bridging

    private var scanContinuation: AsyncStream<DiscoveredDevice>.Continuation?
    private var eventContinuation: AsyncStream<BLEEvent>.Continuation?
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var disconnectContinuation: CheckedContinuation<Void, Never>?
    private var serviceDiscoveryContinuation: CheckedContinuation<Void, Error>?
    private var readContinuation: CheckedContinuation<Data?, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var descriptorWriteContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Service discovery tracking

    private var discoveredServices = Set<CBUUID>()
    private var discoveredCharacteristics = Set<CBUUID>()
    private var serviceCharacteristicMap: [CBUUID: [CBUUID]] = [:]

    /// 当前连接状态 / Current connection state
    var state: ConnectionState = .disconnected

    /// 在已连接外设上执行操作 / Execute operation on connected peripheral
    func withConnectedPeripheral<T: Sendable>(_ operation: (CBPeripheral) async throws -> T) async throws -> T {
        guard let peripheral = _connectedPeripheral else {
            throw GlucoseMeterError.deviceDisconnected
        }
        return try await operation(peripheral)
    }

    override init() {
        super.init()
    }

    /// 初始化 CoreBluetooth / Initialize CoreBluetooth
    func initialize() {
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scanning

    /// 扫描血糖仪设备 / Scan for glucometer devices
    /// - Parameter duration: 扫描持续时间（秒）/ Scan duration in seconds
    /// - Returns: 发现的设备流 / Stream of discovered devices
    func scan(duration: TimeInterval) -> AsyncStream<DiscoveredDevice> {
        AsyncStream { continuation in
            self.scanContinuation = continuation

            guard let central = centralManager, central.state == .poweredOn else {
                continuation.finish()
                return
            }

            // 使用 Glucose Service UUID 过滤扫描 / Filter scan by Glucose Service UUID
            central.scanForPeripherals(
                withServices: [BLEUUID.glucoseService],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )

            // 定时停止扫描 / Stop scan after duration
            Task.detached { [weak central] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                central?.stopScan()
                continuation.finish()
            }
        }
    }

    // MARK: - Connection

    /// 连接指定设备 / Connect to a specific device
    /// - Parameter device: 要连接的设备 / Device to connect to
    func connect(to device: DiscoveredDevice) async throws {
        guard let central = centralManager else {
            throw GlucoseMeterError.bluetoothUnavailable
        }

        guard central.state == .poweredOn else {
            throw GlucoseMeterError.bluetoothUnavailable
        }

        guard let uuid = UUID(uuidString: device.id) else {
            throw GlucoseMeterError.deviceNotFound
        }

        let peripherals = central.retrievePeripherals(withIdentifiers: [uuid])
        guard let peripheral = peripherals.first else {
            throw GlucoseMeterError.deviceNotFound
        }

        _connectedPeripheral = peripheral
        peripheral.delegate = self

        state = .connecting

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectContinuation = continuation
            central.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            ])
        }
    }

    /// 断开当前连接 / Disconnect current connection
    func disconnect() async {
        guard let peripheral = _connectedPeripheral else { return }

        state = .disconnecting

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.disconnectContinuation = continuation
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - Service Discovery

    /// 发现 BLE 服务 / Discover BLE services
    func discoverServices() async throws {
        guard let peripheral = _connectedPeripheral else {
            throw GlucoseMeterError.deviceDisconnected
        }

        state = .discoveringServices
        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()
        serviceCharacteristicMap.removeAll()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.serviceDiscoveryContinuation = continuation
            peripheral.discoverServices(nil as [CBUUID]?)
        }
    }

    // MARK: - Notifications

    /// 设置血糖测量和 RACP 通知 / Setup glucose measurement and RACP notifications
    func setupNotifications() async throws {
        guard let peripheral = _connectedPeripheral else {
            throw GlucoseMeterError.deviceDisconnected
        }

        let commands: [BLECommand] = [
            .enableNotification(
                service: BLEUUID.glucoseService,
                characteristic: BLEUUID.glucoseMeasurement,
                note: "Glucose measurement notifications"
            ),
            .enableIndication(
                service: BLEUUID.glucoseService,
                characteristic: BLEUUID.recordAccessControlPoint,
                note: "RACP indications"
            ),
        ]

        for command in commands {
            try await executeCommand(command, peripheral: peripheral)
        }
    }

    // MARK: - RACP Operations

    /// 写入 RACP 命令 / Write RACP command
    /// - Parameter data: RACP 命令数据 / RACP command data
    func writeRACP(_ data: Data) async throws {
        guard let peripheral = _connectedPeripheral else {
            throw GlucoseMeterError.deviceDisconnected
        }

        let command = BLECommand.write(
            service: BLEUUID.glucoseService,
            characteristic: BLEUUID.recordAccessControlPoint,
            data: data,
            note: "RACP command"
        )

        try await executeCommand(command, peripheral: peripheral)
    }

    /// 读取特征值 / Read characteristic value
    func readCharacteristic(service: CBUUID, characteristic: CBUUID) async throws -> Data? {
        guard let peripheral = _connectedPeripheral else {
            throw GlucoseMeterError.deviceDisconnected
        }

        let command = BLECommand.read(
            service: service,
            characteristic: characteristic,
            note: "Read characteristic"
        )

        return try await executeReadCommand(command, peripheral: peripheral)
    }

    /// 创建事件流 / Create event stream for receiving BLE events
    func createEventStream() -> AsyncStream<BLEEvent> {
        AsyncStream { continuation in
            self.eventContinuation = continuation
        }
    }

    /// 设置协议解析器 / Set protocol parser
    func setProfile(_ profile: GlucoseProfileProtocol) {
        self.profile = profile
    }

    // MARK: - Private Command Execution

    private func executeCommand(_ command: BLECommand, peripheral: CBPeripheral) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.writeContinuation = continuation

            switch command {
            case .write(let serviceUUID, let charUUID, let data, _):
                guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
                      let characteristic = service.characteristics?.first(where: { $0.uuid == charUUID }) else {
                    continuation.resume(throwing: GlucoseMeterError.characteristicNotFound)
                    return
                }
                peripheral.writeValue(data, for: characteristic, type: .withResponse)

            case .enableNotification(let serviceUUID, let charUUID, _):
                guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
                      let characteristic = service.characteristics?.first(where: { $0.uuid == charUUID }) else {
                    continuation.resume(throwing: GlucoseMeterError.characteristicNotFound)
                    return
                }
                peripheral.setNotifyValue(true, for: characteristic)
                self.descriptorWriteContinuation = continuation

            case .enableIndication(let serviceUUID, let charUUID, _):
                guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
                      let characteristic = service.characteristics?.first(where: { $0.uuid == charUUID }) else {
                    continuation.resume(throwing: GlucoseMeterError.characteristicNotFound)
                    return
                }
                peripheral.setNotifyValue(true, for: characteristic)
                self.descriptorWriteContinuation = continuation

            case .setNotify(let serviceUUID, let charUUID, let enabled, _):
                guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
                      let characteristic = service.characteristics?.first(where: { $0.uuid == charUUID }) else {
                    continuation.resume(throwing: GlucoseMeterError.characteristicNotFound)
                    return
                }
                peripheral.setNotifyValue(enabled, for: characteristic)
                self.descriptorWriteContinuation = continuation

            case .read:
                continuation.resume(throwing: GlucoseMeterError.invalidDataFormat)
            }
        }
    }

    private func executeReadCommand(_ command: BLECommand, peripheral: CBPeripheral) async throws -> Data? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            self.readContinuation = continuation

            switch command {
            case .read(let serviceUUID, let charUUID, _):
                guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
                      let characteristic = service.characteristics?.first(where: { $0.uuid == charUUID }) else {
                    continuation.resume(throwing: GlucoseMeterError.characteristicNotFound)
                    return
                }
                peripheral.readValue(for: characteristic)

            default:
                continuation.resume(throwing: GlucoseMeterError.invalidDataFormat)
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DeviceManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task.detached { [state = central.state] in
            await self.handleCentralStateUpdate(state)
        }
    }

    private func handleCentralStateUpdate(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            break
        case .unauthorized:
            connectContinuation?.resume(throwing: GlucoseMeterError.bluetoothUnauthorized)
        case .poweredOff, .unsupported, .resetting, .unknown:
            connectContinuation?.resume(throwing: GlucoseMeterError.bluetoothUnavailable)
        @unknown default:
            connectContinuation?.resume(throwing: GlucoseMeterError.bluetoothUnavailable)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let device = DiscoveredDevice(
            id: peripheral.identifier.uuidString,
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            rssi: RSSI.intValue,
            isPaired: false,
            manufacturerData: advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        )

        Task.detached {
            await self.deliverDiscoveredDevice(device)
        }
    }

    private func deliverDiscoveredDevice(_ device: DiscoveredDevice) {
        scanContinuation?.yield(device)
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task.detached {
            await self.handleConnectionSuccess()
        }
    }

    private func handleConnectionSuccess() {
        state = .ready
        connectContinuation?.resume()
        connectContinuation = nil
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task.detached { [error] in
            await self.handleConnectionFailure(error)
        }
    }

    private func handleConnectionFailure(_ error: Error?) {
        state = .disconnected
        let error = error ?? GlucoseMeterError.connectionFailed
        connectContinuation?.resume(throwing: error)
        connectContinuation = nil
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task.detached {
            await self.handleDisconnection()
        }
    }

    private func handleDisconnection() {
        state = .disconnected
        _connectedPeripheral = nil
        disconnectContinuation?.resume()
        disconnectContinuation = nil
        eventContinuation?.finish()
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        Task.detached { [error] in
            await self.handleDescriptorWriteComplete(error: error)
        }
    }

    private func handleDescriptorWriteComplete(error: Error?) {
        if let error = error {
            descriptorWriteContinuation?.resume(throwing: error)
        } else {
            descriptorWriteContinuation?.resume()
        }
        descriptorWriteContinuation = nil
    }
}

// MARK: - CBPeripheralDelegate

extension DeviceManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task.detached { [error] in
            await self.handleServicesDiscovered(peripheral: peripheral, error: error)
        }
    }

    private func handleServicesDiscovered(peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            serviceDiscoveryContinuation?.resume(throwing: error)
            serviceDiscoveryContinuation = nil
            return
        }

        guard let services = peripheral.services else {
            serviceDiscoveryContinuation?.resume(throwing: GlucoseMeterError.serviceDiscoveryFailed)
            serviceDiscoveryContinuation = nil
            return
        }

        // 发现每个服务的特征值 / Discover characteristics for each service
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task.detached { [error] in
            await self.handleCharacteristicsDiscovered(service: service, error: error)
        }
    }

    private func handleCharacteristicsDiscovered(service: CBService, error: Error?) {
        if let error = error {
            serviceDiscoveryContinuation?.resume(throwing: error)
            serviceDiscoveryContinuation = nil
            return
        }

        discoveredServices.insert(service.uuid)

        if let characteristics = service.characteristics {
            var charUUIDs: [CBUUID] = []
            for characteristic in characteristics {
                discoveredCharacteristics.insert(characteristic.uuid)
                charUUIDs.append(characteristic.uuid)
            }
            serviceCharacteristicMap[service.uuid] = charUUIDs
        }

        // 检查所有服务是否都已发现特征值 / Check if all services have discovered characteristics
        let allServicesDiscovered = _connectedPeripheral?.services?.allSatisfy { discoveredServices.contains($0.uuid) } ?? false

        if allServicesDiscovered {
            serviceDiscoveryContinuation?.resume()
            serviceDiscoveryContinuation = nil
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task.detached { [error] in
            await self.handleCharacteristicUpdate(characteristic: characteristic, error: error)
        }
    }

    private func handleCharacteristicUpdate(characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            readContinuation?.resume(throwing: error)
            readContinuation = nil
            return
        }

        switch characteristic.uuid {
        case BLEUUID.glucoseMeasurement:
            if let data = characteristic.value {
                do {
                    if let reading = try profile?.parseGlucoseMeasurement(data) {
                        eventContinuation?.yield(.measurement(reading))
                    }
                } catch {
                    // 静默忽略单个测量解析错误 / Silently ignore parse errors for individual measurements
                }
            }

        case BLEUUID.glucoseMeasurementContext:
            if let data = characteristic.value,
               let context = profile?.parseContextData(data) {
                eventContinuation?.yield(.context(context))
            }

        case BLEUUID.recordAccessControlPoint:
            if let data = characteristic.value,
               let result = profile?.handleRACPResponse(data) {
                switch result {
                case .complete:
                    eventContinuation?.yield(.racpComplete)
                case .responseCode(let code):
                    eventContinuation?.yield(.racpError(code))
                case .numberOfRecords:
                    break
                case .unknown:
                    break
                }
            }

        case BLEUUID.manufacturerName:
            if let data = characteristic.value,
               let name = String(data: data, encoding: .utf8) {
                eventContinuation?.yield(.manufacturerName(name))
            }
            readContinuation?.resume(returning: characteristic.value)
            readContinuation = nil

        case BLEUUID.currentTime, BLEUUID.dateTime:
            if let data = characteristic.value,
               let date = profile?.parseDeviceTime(data) {
                eventContinuation?.yield(.deviceTime(date))
            }
            readContinuation?.resume(returning: characteristic.value)
            readContinuation = nil

        default:
            readContinuation?.resume(returning: characteristic.value)
            readContinuation = nil
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task.detached { [error] in
            await self.handleWriteComplete(error: error)
        }
    }

    private func handleWriteComplete(error: Error?) {
        if let error = error {
            writeContinuation?.resume(throwing: error)
        } else {
            writeContinuation?.resume()
        }
        writeContinuation = nil
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task.detached { [error] in
            await self.handleNotificationStateUpdate(error: error)
        }
    }

    private func handleNotificationStateUpdate(error: Error?) {
        if let error = error {
            descriptorWriteContinuation?.resume(throwing: error)
        } else {
            descriptorWriteContinuation?.resume()
        }
        descriptorWriteContinuation = nil
    }
}
