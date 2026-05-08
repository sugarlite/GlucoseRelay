import Foundation

/// 血糖读数模型 / Glucose reading data model
///
/// 从罗氏血糖仪 BLE 通知中解析的单个血糖测量值。
/// A single glucose measurement parsed from Roche glucometer BLE notifications.
public struct GlucoseReading: Identifiable, Sendable, Equatable {
    /// 唯一标识符 / Unique identifier
    public let id: UUID
    /// 记录序列号，用于增量同步 / Record sequence number for incremental sync
    public let sequenceNumber: Int
    /// 测量时间戳 / Measurement timestamp
    public let timestamp: Date
    /// 血糖值（mg/dL）/ Glucose value in mg/dL
    public let glucoseValue: Double
    /// 血糖值（mmol/L）/ Glucose value in mmol/L
    public let glucoseValueMMOL: Double
    /// 原始单位 / Original unit from device
    public let unit: GlucoseUnit
    /// 样本类型 / Sample type (e.g. capillary whole blood)
    public let sampleType: SampleType
    /// 采样位置 / Sample location (e.g. finger)
    public let sampleLocation: SampleLocation
    /// 是否有上下文信息跟随 / Whether context info follows this measurement
    public let hasContextInfo: Bool
    /// 用餐类型（从上下文解析）/ Meal type (parsed from context if available)
    public let mealType: MealType?
    /// 设备标识 / Device identifier
    public let deviceId: String

    public init(
        id: UUID = UUID(),
        sequenceNumber: Int,
        timestamp: Date,
        glucoseValue: Double,
        glucoseValueMMOL: Double,
        unit: GlucoseUnit,
        sampleType: SampleType,
        sampleLocation: SampleLocation,
        hasContextInfo: Bool,
        mealType: MealType?,
        deviceId: String
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
        self.glucoseValue = glucoseValue
        self.glucoseValueMMOL = glucoseValueMMOL
        self.unit = unit
        self.sampleType = sampleType
        self.sampleLocation = sampleLocation
        self.hasContextInfo = hasContextInfo
        self.mealType = mealType
        self.deviceId = deviceId
    }
}

/// 血糖单位 / Glucose measurement unit
public enum GlucoseUnit: Sendable, Equatable {
    /// 毫克每分升 / Milligrams per deciliter
    case mgPerDL
    /// 毫摩尔每升 / Millimoles per liter
    case mmolPerL
}

/// 样本类型（BLE Glucose Profile 标准）/ Sample type (BLE Glucose Profile standard)
public enum SampleType: UInt8, Sendable, Equatable {
    /// 毛细血管全血 / Capillary whole blood
    case capillaryWholeBlood = 1
    /// 毛细血管血浆 / Capillary plasma
    case capillaryPlasma = 2
    /// 静脉全血 / Venous whole blood
    case venousWholeBlood = 3
    /// 静脉血浆 / Venous plasma
    case venousPlasma = 4
    /// 动脉全血 / Arterial whole blood
    case arterialWholeBlood = 5
    /// 动脉血浆 / Arterial plasma
    case arterialPlasma = 6
    /// 未确定全血 / Undetermined whole blood
    case undeterminedWholeBlood = 7
    /// 未确定血浆 / Undetermined plasma
    case undeterminedPlasma = 8
    /// 组织间液 / Interstitial fluid
    case interstitialFluid = 9
    /// 质控液 / Control solution
    case controlSolution = 10
}

/// 采样位置（BLE Glucose Profile 标准）/ Sample location (BLE Glucose Profile standard)
public enum SampleLocation: UInt8, Sendable, Equatable {
    /// 手指 / Finger
    case finger = 1
    /// 替代部位 / Alternate site test
    case alternateSiteTest = 2
    /// 耳垂 / Earlobe
    case earlobe = 3
    /// 质控液 / Control solution
    case controlSolution = 4
    /// 皮下 / Subcutaneous
    case subcutaneous = 5
    /// 不可用 / Not available
    case notAvailable = 15
}

/// 用餐类型（从上下文特征值解析）/ Meal type (parsed from context characteristic)
public enum MealType: UInt8, Sendable, Equatable {
    /// 餐前 / Before meal
    case beforeMeal = 1
    /// 餐后 / After meal
    case afterMeal = 2
    /// 空腹 / Fasting
    case fasting = 3
    /// 睡前 / Bedtime
    case bedtime = 4
    /// 酮体 / Ketone
    case ketone = 6
}
