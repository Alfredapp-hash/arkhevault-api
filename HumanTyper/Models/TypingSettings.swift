import Foundation

struct TypingSettings: Equatable {
    var wordsPerMinute: Double = 65
    var errorRate: Double = 0.02
    var countdownSeconds: Int = 5

    static let wpmRange: ClosedRange<Double> = 40...120
    static let errorRateRange: ClosedRange<Double> = 0...0.10
    static let countdownRange: ClosedRange<Int> = 3...10

    func estimatedDuration(forCharacterCount count: Int) -> TimeInterval {
        guard count > 0 else { return 0 }
        let basePerChar = 60.0 / (wordsPerMinute * 5.0)
        let thinkingPauses = Double(count) / 60.0 * 0.4
        let typoOverhead = Double(count) * errorRate * 0.5
        return Double(count) * basePerChar * 1.12 + thinkingPauses + typoOverhead
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "0s" }
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        }
        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return remainder > 0 ? "\(minutes)m \(remainder)s" : "\(minutes)m"
    }
}

enum TypingStatus: Equatable {
    case idle
    case countdown(remaining: Int)
    case typing
    case completed
    case cancelled
    case failed(String)
}
