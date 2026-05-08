import Foundation

/// 血糖测量上下文 / Glucose measurement context
///
/// 从 Glucose Measurement Context 特征值解析的附加信息。
/// Additional information parsed from the Glucose Measurement Context characteristic.
struct GlucoseContext: Sendable, Equatable {
    /// 对应的测量序列号 / Corresponding measurement sequence number
    let sequenceNumber: Int
    /// 用餐类型 / Meal type (if available)
    let mealType: MealType?
    /// 是否包含碳水化合物信息 / Whether carbohydrate info is present
    let hasCarbInfo: Bool
}
