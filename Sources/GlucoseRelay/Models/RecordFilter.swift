import Foundation

/// 记录过滤条件 / Record filter criteria
///
/// 用于 RACP 命令，指定要读取哪些血糖记录。
/// Used in RACP commands to specify which glucose records to read.
public enum RecordFilter: Sendable, Equatable {
    /// 读取所有记录 / Read all records
    case all
    /// 读取从指定序列号之后的记录 / Read records since a specific sequence number
    case sinceSequence(Int)
    /// 读取最近的 N 条记录 / Read the last N records
    case last(Int)
}
