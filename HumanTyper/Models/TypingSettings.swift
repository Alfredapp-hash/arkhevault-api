import Foundation

enum TypingRunScope: String, CaseIterable, Identifiable {
    case fullText
    case selection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullText: return "All"
        case .selection: return "Selection"
        }
    }

    var icon: String {
        switch self {
        case .fullText: return "doc.text"
        case .selection: return "selection.pin.in.out"
        }
    }
}

struct TypingSettings: Equatable {
    var wordsPerMinute: Double = 65
    var errorRate: Double = 0.02
    var countdownSeconds: Int = 5
    var runScope: TypingRunScope = .fullText

    static let wpmRange: ClosedRange<Double> = 40...120
    static let errorRateRange: ClosedRange<Double> = 0...0.10
    static let countdownRange: ClosedRange<Int> = 3...10

    func estimatedDuration(forCharacterCount count: Int) -> TimeInterval {
        estimatedDuration(forText: String(repeating: "x", count: count))
    }

    func estimatedDuration(forText text: String) -> TimeInterval {
        WritingCadenceEstimator.estimatedDuration(
            text: text,
            wordsPerMinute: wordsPerMinute,
            errorRate: errorRate
        )
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
    case typing(scope: TypingRunScope)
    case completed
    case cancelled
    case failed(String)
}
