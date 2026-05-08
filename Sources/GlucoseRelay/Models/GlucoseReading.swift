import Foundation

public struct GlucoseReading: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let sequenceNumber: Int
    public let timestamp: Date
    public let glucoseValue: Double
    public let glucoseValueMMOL: Double
    public let unit: GlucoseUnit
    public let sampleType: SampleType
    public let sampleLocation: SampleLocation
    public let hasContextInfo: Bool
    public let mealType: MealType?
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

public enum GlucoseUnit: Sendable, Equatable {
    case mgPerDL
    case mmolPerL
}

public enum SampleType: UInt8, Sendable, Equatable {
    case capillaryWholeBlood = 1
    case capillaryPlasma = 2
    case venousWholeBlood = 3
    case venousPlasma = 4
    case arterialWholeBlood = 5
    case arterialPlasma = 6
    case undeterminedWholeBlood = 7
    case undeterminedPlasma = 8
    case interstitialFluid = 9
    case controlSolution = 10
}

public enum SampleLocation: UInt8, Sendable, Equatable {
    case finger = 1
    case alternateSiteTest = 2
    case earlobe = 3
    case controlSolution = 4
    case subcutaneous = 5
    case notAvailable = 15
}

public enum MealType: UInt8, Sendable, Equatable {
    case beforeMeal = 1
    case afterMeal = 2
    case fasting = 3
    case bedtime = 4
    case ketone = 6
}
