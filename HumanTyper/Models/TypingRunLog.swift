import Foundation

struct TypingRunEvent: Codable, Equatable {
    enum Kind: String, Codable {
        case character
        case backspace
        case pause
        case typo
        case revision
        case paste
        case note
    }

    let timestamp: Date
    let kind: Kind
    let detail: String
    let delay: TimeInterval?
}

struct TypingRunLog: Codable, Equatable {
    var events: [TypingRunEvent] = []

    mutating func append(_ kind: TypingRunEvent.Kind, detail: String, delay: TimeInterval? = nil) {
        events.append(TypingRunEvent(timestamp: Date(), kind: kind, detail: detail, delay: delay))
    }
}

enum RunLogExporter {
    static func exportJSON(_ log: TypingRunLog) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(log.events) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func exportCSV(_ log: TypingRunLog) -> String {
        var lines = ["timestamp,kind,detail,delay"]
        let formatter = ISO8601DateFormatter()
        for event in log.events {
            let delay = event.delay.map { String(format: "%.3f", $0) } ?? ""
            let detail = event.detail.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\(formatter.string(from: event.timestamp)),\(event.kind.rawValue),\"\(detail)\",\(delay)")
        }
        return lines.joined(separator: "\n")
    }
}
