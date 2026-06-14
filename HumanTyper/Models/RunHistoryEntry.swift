import Foundation

struct RunSummary: Codable, Equatable {
    let startedAt: Date
    let finishedAt: Date
    let scope: TypingRunScope
    let documentMode: TypingDocumentMode
    let characterCount: Int
    let typoCount: Int
    let revisionCount: Int
    let pauseCount: Int
    let estimatedWPM: Double
    let dryRun: Bool
    let targetAppName: String?
    let textPreview: String

    var duration: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }
}

struct RunHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let summary: RunSummary

    init(summary: RunSummary) {
        self.id = UUID()
        self.summary = summary
    }
}

@MainActor
final class RunHistoryStore: ObservableObject {
    @Published private(set) var entries: [RunHistoryEntry] = []

    private let storageKey = "humanTyper.history"
    private let limit = 20

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([RunHistoryEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded
    }

    func add(_ summary: RunSummary) {
        entries.insert(RunHistoryEntry(summary: summary), at: 0)
        if entries.count > limit {
            entries = Array(entries.prefix(limit))
        }
        save()
    }

    func clear() {
        entries = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
