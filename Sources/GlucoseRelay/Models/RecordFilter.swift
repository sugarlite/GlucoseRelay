import Foundation

public enum RecordFilter: Sendable, Equatable {
    case all
    case sinceSequence(Int)
    case last(Int)
}
