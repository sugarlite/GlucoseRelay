import Foundation

struct GlucoseContext: Sendable, Equatable {
    let sequenceNumber: Int
    let mealType: MealType?
    let hasCarbInfo: Bool
}
