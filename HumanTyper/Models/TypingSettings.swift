import Foundation

struct TypingSettings: Equatable {
    var wordsPerMinute: Double = 65
    var errorRate: Double = 0.02
    var countdownSeconds: Int = 5

    static let wpmRange: ClosedRange<Double> = 40...120
    static let errorRateRange: ClosedRange<Double> = 0...0.10
    static let countdownRange: ClosedRange<Int> = 3...10
}

enum TypingStatus: Equatable {
    case idle
    case countdown(remaining: Int)
    case typing
    case completed
    case cancelled
    case failed(String)
}
