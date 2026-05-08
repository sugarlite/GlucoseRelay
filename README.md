# GlucoseRelay

罗氏血糖仪 iOS SDK / Roche Glucometer iOS SDK

通过蓝牙低功耗（BLE）连接罗氏 Accu-Chek 系列血糖仪，读取血糖测量数据。

Connect to Roche Accu-Chek series glucometers via Bluetooth Low Energy (BLE) to read glucose measurement data.

---

## 功能特性 / Features

- **设备扫描** / Device scanning: 使用 Glucose Service UUID (0x1808) 过滤扫描
- **自动连接** / Auto connection: 通过设备 UUID 检索并连接已配对设备
- **服务发现** / Service discovery: 自动发现 BLE 服务和特征值
- **血糖记录读取** / Glucose record reading: 支持读取所有记录或增量同步
- **实时测量监听** / Real-time measurement listening: 监听设备上的新测量
- **上下文解析** / Context parsing: 解析用餐类型等附加信息
- **协议抽象** / Protocol abstraction: 策略模式支持多厂商扩展

---

## 支持设备 / Supported Devices

| 设备型号 | 状态 |
|---------|------|
| Accu-Chek Guide | 已支持 / Supported |
| Accu-Chek Guide Me | 已支持 / Supported |
| Accu-Chek Instant | 已支持 / Supported |

> 所有设备均使用 Bluetooth SIG 标准 Glucose Profile (0x1808)。
> All devices use the Bluetooth SIG standard Glucose Profile (0x1808).

---

## 系统要求 / Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16.0+
- 蓝牙权限 / Bluetooth permissions

---

## 安装 / Installation

### Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies...**，然后输入：

In Xcode, select **File > Add Package Dependencies...**, then enter:

```
https://github.com/sugarlite/GlucoseRelay.git
```

或在 `Package.swift` 中添加：

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sugarlite/GlucoseRelay.git", from: "1.0.0")
]
```

---

## 配置权限 / Permission Configuration

在 `Info.plist` 中添加以下键值：

Add the following keys to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限连接血糖仪设备 / Bluetooth is required to connect to the glucometer</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限连接血糖仪设备 / Bluetooth is required to connect to the glucometer</string>
```

---

## 使用示例 / Usage Example

```swift
import GlucoseRelay

class GlucoseViewModel: ObservableObject {
    private let sdk = RocheGlucometerSDK.shared
    @Published var readings: [GlucoseReading] = []
    @Published var connectionState: ConnectionState = .disconnected

    /// 初始化 SDK / Initialize SDK
    func initialize() async {
        await sdk.initialize()
    }

    /// 扫描设备 / Scan for devices
    func scanDevices() async {
        for await device in await sdk.scan(duration: 10) {
            print("发现设备 / Found: \(device.name ?? "Unknown") (RSSI: \(device.rssi))")
            // 连接第一个设备 / Connect to first device
            await connect(to: device)
        }
    }

    /// 连接设备 / Connect to device
    func connect(to device: DiscoveredDevice) async {
        do {
            let connection = try await sdk.connect(to: device)
            connectionState = await connection.state

            // 读取所有记录 / Fetch all records
            let records = try await connection.fetchAllRecords()
            readings = records

            // 增量同步示例 / Incremental sync example
            // let lastSequence = readings.last?.sequenceNumber ?? 0
            // let newRecords = try await connection.fetchNewRecords(since: lastSequence)

            // 监听实时测量 / Listen to real-time measurements
            for await reading in connection.realtimeMeasurements() {
                print("新测量 / New measurement: \(reading.glucoseValue) mg/dL")
            }

            // 断开连接 / Disconnect
            await connection.disconnect()
        } catch {
            print("连接错误 / Connection error: \(error)")
        }
    }
}
```

---

## 数据模型 / Data Models

### GlucoseReading

```swift
public struct GlucoseReading: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let sequenceNumber: Int      // 记录序列号 / Record sequence number
    public let timestamp: Date          // 测量时间 / Measurement time
    public let glucoseValue: Double     // mg/dL
    public let glucoseValueMMOL: Double // mmol/L
    public let unit: GlucoseUnit        // 原始单位 / Original unit
    public let sampleType: SampleType   // 样本类型 / Sample type
    public let sampleLocation: SampleLocation // 采样位置 / Sample location
    public let hasContextInfo: Bool     // 是否有上下文 / Has context info
    public let mealType: MealType?      // 用餐类型 / Meal type
    public let deviceId: String         // 设备标识 / Device ID
}
```

### ConnectionState

```swift
public enum ConnectionState {
    case disconnected       // 已断开
    case connecting         // 正在连接
    case discoveringServices // 正在发现服务
    case pairing            // 正在配对
    case ready              // 已就绪
    case readingData        // 正在读取数据
    case disconnecting      // 正在断开
}
```

---

## 错误处理 / Error Handling

```swift
do {
    let connection = try await sdk.connect(to: device)
} catch GlucoseMeterError.bluetoothUnavailable {
    // 蓝牙不可用 / Bluetooth not available
} catch GlucoseMeterError.deviceNotFound {
    // 设备未找到 / Device not found
} catch GlucoseMeterError.pairingRequired {
    // 需要先在系统设置中配对 / Need to pair in system settings first
} catch GlucoseMeterError.racpError(let code) {
    // RACP 操作错误 / RACP operation error
}
```

---

## 架构设计 / Architecture

```
┌─────────────────────────────────────────────┐
│         RocheGlucometerSDK (Public API)      │
├─────────────────────────────────────────────┤
│  GlucoseMeterConnection                      │
│    ├─ fetchAllRecords()                      │
│    ├─ fetchNewRecords(since:)                │
│    ├─ realtimeMeasurements()                 │
│    └─ disconnect()                           │
├─────────────────────────────────────────────┤
│  DeviceManager (Actor)                       │
│    ├─ CBCentralManagerDelegate               │
│    ├─ CBPeripheralDelegate                   │
│    └─ BLECommandQueue                        │
├─────────────────────────────────────────────┤
│  GlucoseProfileProtocol (Strategy)           │
│    ├─ RocheGlucoseProfile                    │
│    └─ StandardGlucoseProfile                 │
├─────────────────────────────────────────────┤
│  Parsers                                     │
│    ├─ SFLOAT (IEEE-11073)                    │
│    ├─ GlucoseMeasurementParser               │
│    └─ GlucoseContextParser                   │
└─────────────────────────────────────────────┘
```

---

## BLE 协议 / BLE Protocol

### 使用的服务和特征值 / Services and Characteristics

| 服务 / Service | UUID | 特征值 / Characteristic |
|---------------|------|------------------------|
| Glucose Service | 0x1808 | Glucose Measurement (0x2A18) |
| | | Glucose Measurement Context (0x2A34) |
| | | Record Access Control Point (0x2A52) |
| Current Time Service | 0x1805 | Current Time (0x2A2B) |
| Device Information | 0x180A | Manufacturer Name (0x2A29) |

### 通信流程 / Communication Flow

```
[扫描 Scan] → [连接 Connect] → [发现服务 Discover Services]
                                    ↓
[接收通知 Receive Notifications] ← [写入 RACP 命令 Write RACP Command]
    ↓
[解析数据 Parse Data] → [存储/回调 Store/Callback]
```

---

## 测试 / Testing

```bash
swift test
```

包含 41 个单元测试，覆盖：
- SFLOAT 解析器 / SFLOAT parser
- 血糖数据解析 / Glucose measurement parsing
- RACP 命令构建和响应 / RACP command building and response
- 上下文数据解析 / Context data parsing
- 字节工具 / Byte utilities
- 数据模型 / Data models

---

## 注意事项 / Notes

1. **配对要求** / Pairing requirement: 罗氏设备要求先在 iOS 系统设置 → 蓝牙中完成配对，然后才能在 App 中通信。
   Roche devices require pairing in iOS Settings → Bluetooth before in-app communication.

2. **后台限制** / Background limitations: iOS 对后台 BLE 扫描和连接有严格限制，需要使用 `bluetooth-central` background mode。
   iOS has strict limitations on background BLE scanning and connection; use `bluetooth-central` background mode.

3. **数据安全** / Data security: SDK 不存储或传输敏感数据，由宿主 App 负责数据加密和合规性。
   The SDK does not store or transmit sensitive data; the host app is responsible for data encryption and compliance.

---

## 许可证 / License

MIT License

---

## 参考 / References

- [Bluetooth SIG Glucose Service Specification](https://www.bluetooth.com/specifications/specs/)
- [IEEE 11073-10417](https://standards.ieee.org/standard/11073-10417.html) - Personal Health Device Glucose Meter
- [xDrip+](https://github.com/NightscoutFoundation/xDrip) - Android glucose monitoring reference implementation
