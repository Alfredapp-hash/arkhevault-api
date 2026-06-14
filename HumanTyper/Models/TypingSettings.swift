import Foundation

enum TypingRunScope: String, CaseIterable, Codable, Identifiable {
    case fullText
    case selection
    case fromCursor
    case queued

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullText: return "All"
        case .selection: return "Selection"
        case .fromCursor: return "From Cursor"
        case .queued: return "Queue"
        }
    }

    var icon: String {
        switch self {
        case .fullText: return "doc.text"
        case .selection: return "selection.pin.in.out"
        case .fromCursor: return "text.cursor"
        case .queued: return "list.number"
        }
    }
}

struct TypingQueueItem: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let label: String

    init(id: UUID = UUID(), text: String, label: String) {
        self.id = id
        self.text = text
        self.label = label
    }
}

struct TypingSettings: Equatable {
    var wordsPerMinute: Double = 65
    var errorRate: Double = 0.02
    var countdownSeconds: Int = 5
    var runScope: TypingRunScope = .fullText
    var documentMode: TypingDocumentMode = .essay
    var targetBundleID: String?

    static let wpmRange: ClosedRange<Double> = 40...120
    static let errorRateRange: ClosedRange<Double> = 0...0.10
    static let countdownRange: ClosedRange<Int> = 3...10

    func estimatedDuration(forCharacterCount count: Int) -> TimeInterval {
        estimatedDuration(forText: String(repeating: "x", count: count))
    }

    func estimatedDuration(forText text: String) -> TimeInterval {
        var duration = WritingCadenceEstimator.estimatedDuration(
            text: text,
            wordsPerMinute: wordsPerMinute,
            errorRate: errorRate * documentMode.errorMultiplier
        )
        duration *= documentMode.pauseMultiplier
        return duration
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
    case stopping
    case completed(summary: RunSummary)
    case cancelled
    case failed(String)
}

enum TextRunResolver {
    static func resolveText(
        fullText: String,
        scope: TypingRunScope,
        selection: TextSelectionState,
        queue: [TypingQueueItem]
    ) -> String? {
        switch scope {
        case .fullText:
            return fullText.isEmpty ? nil : fullText
        case .selection:
            return selection.selectedText(in: fullText)
        case .fromCursor:
            return textFromCursor(fullText: fullText, selection: selection)
        case .queued:
            let combined = queue.map(\.text).joined()
            return combined.isEmpty ? nil : combined
        }
    }

    static func textFromCursor(fullText: String, selection: TextSelectionState) -> String? {
        let nsText = fullText as NSString
        guard selection.range.location != NSNotFound else { return nil }

        let start = selection.range.location
        guard start < nsText.length else { return nil }

        let end = selection.hasSelection ? NSMaxRange(selection.range) : nsText.length
        let substring = nsText.substring(with: NSRange(location: start, length: end - start))
        return substring.isEmpty ? nil : substring
    }
}
