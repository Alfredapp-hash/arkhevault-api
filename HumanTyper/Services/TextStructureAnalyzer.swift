import Foundation

enum TextStructureAnalyzer {
    enum SegmentKind {
        case body
        case heading
        case bullet
        case quote
        case citation
    }

    struct Segment {
        let kind: SegmentKind
        let range: Range<Int>
    }

    static func segment(at index: Int, in text: String) -> SegmentKind {
        let characters = Array(text)
        guard index < characters.count else { return .body }

        let lineStart = lineStartIndex(for: index, in: characters)
        let line = String(characters[lineStart..<min(characters.count, lineEndIndex(for: index, in: characters))])

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(">") || trimmed.hasPrefix("\"") || trimmed.hasPrefix("\u{201C}") {
            return .quote
        }
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") || trimmed.hasPrefix("* ") {
            return .bullet
        }
        if trimmed.hasPrefix("#") || (trimmed.count < 80 && trimmed == trimmed.uppercased() && trimmed.contains(where: \.isLetter)) {
            return .heading
        }
        if trimmed.contains("[") && trimmed.contains("]") {
            return .citation
        }
        return .body
    }

    static func pauseMultiplier(for kind: SegmentKind, mode: TypingDocumentMode) -> Double {
        switch (kind, mode) {
        case (.heading, _): return 1.25
        case (.quote, .essay): return 1.35
        case (.quote, _): return 1.15
        case (.bullet, _): return 0.92
        case (.citation, .essay): return 1.3
        case (.citation, _): return 1.1
        case (.body, _): return 1.0
        }
    }

    private static func lineStartIndex(for index: Int, in characters: [Character]) -> Int {
        var i = index
        while i > 0 && characters[i - 1] != "\n" { i -= 1 }
        return i
    }

    private static func lineEndIndex(for index: Int, in characters: [Character]) -> Int {
        var i = index
        while i < characters.count && characters[i] != "\n" { i += 1 }
        return i
    }
}

enum WordFrequencyService {
    private static let commonWords: Set<String> = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "i",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
        "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
        "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
        "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
        "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
        "is", "are", "was", "were", "been", "being", "had", "has", "did", "does",
        "done", "said", "each", "more", "very", "through", "where", "much", "before", "should",
        "own", "those", "while", "may", "still", "many", "such", "here", "why", "same"
    ]

    static func delayMultiplier(forWord word: String) -> Double {
        let normalized = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        guard !normalized.isEmpty else { return 1.0 }

        if normalized.count >= 12 { return 1.35 }
        if normalized.count >= 9 { return 1.18 }
        if commonWords.contains(normalized) { return 0.92 }
        return 1.12
    }
}
